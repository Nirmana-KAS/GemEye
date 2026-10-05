"""Phase 4a: auth, grading storage (MongoDB + S3), history, isolation, /me, calibrations.
Run with ENV=test (see conftest.py); all data is removed at the end of the session."""
import os
import re
import urllib.request
from datetime import datetime, timedelta, timezone

import cv2
import numpy as np
import pytest

from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser
from tests.test_smoke import REAL_STONE

needs_stone = pytest.mark.skipif(not os.path.exists(REAL_STONE), reason="needs the dataset mount")


def stone_bytes():
    with open(REAL_STONE, "rb") as f:
        return f.read()


def tray_jpeg():
    rng = np.random.default_rng(0)
    tray = np.clip(205 + rng.normal(0, 8, (600, 800, 3)), 0, 255).astype(np.uint8)
    ok, enc = cv2.imencode(".jpg", tray)
    assert ok
    return enc.tobytes()


def grade(c, data=None, **form):
    return c.post("/grade", files={"image": ("s.jpg", data or stone_bytes(), "image/jpeg")}, data=form)


def s3_keys(storage, uid):
    full = f"{storage.prefix}gradings/{uid}/"
    r = storage.s3.list_objects_v2(Bucket=storage.bucket, Prefix=full)
    return [o["Key"] for o in r.get("Contents", [])]


# ---- Auth ----

@pytest.mark.parametrize("method,url", [("post", "/grade"), ("get", "/me"), ("put", "/me"),
                                        ("get", "/gradings"), ("get", "/gradings/x"),
                                        ("delete", "/gradings/x"), ("get", "/calibrations"),
                                        ("post", "/calibrations")])
@pytest.mark.parametrize("headers", [None, {"Authorization": "Bearer not-a-token"},
                                     {"Authorization": "Basic abc"}, {"X-Debug-Bypass": "1"}])
def test_401(raw_client, method, url, headers):
    kw = {"headers": headers} if headers else {}
    if url == "/grade":
        kw["files"] = {"image": ("s.jpg", tray_jpeg(), "image/jpeg")}
    r = getattr(raw_client, method)(url, **kw)
    assert r.status_code == 401, r.text
    assert r.json() == {"status": "error", "detail": "Authentication required."}


def test_health_is_public(raw_client):
    assert raw_client.get("/health").status_code == 200


# ---- /grade storage ----

@needs_stone
def test_grade_ok_saved(client, app_state, user_a):
    data = stone_bytes()
    r = grade(client, data, session_id="sess-1", app_version="1.0.0+1", device="Pixel 8")
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["status"] == "ok" and 1 <= b["grade"] <= 7
    assert re.fullmatch(r"GE-STONE-\d{5}", b["stone_id"])
    assert "debug" not in b
    doc = app_state.db.gradings.find_one({"_id": b["grading_id"]})
    assert doc["uid"] == user_a.uid and doc["stone_id"] == b["stone_id"] and doc["deleted"] is False
    assert doc["calibration_session_id"] == "sess-1" and doc["device"] == "Pixel 8"
    assert doc["app_version"] == "1.0.0+1" and doc["referral_threshold_used"] == 0.60
    assert doc["result"]["grade"] == b["grade"] and "debug" not in doc["result"]
    assert doc["created_at"].tzinfo is not None
    key = doc["image_key"]
    assert key == f"test/gradings/{user_a.uid}/{b['grading_id']}.jpg"
    assert app_state.storage.exists(key)
    head = app_state.storage.s3.head_object(Bucket=app_state.storage.bucket, Key=key)
    assert head.get("ServerSideEncryption") == "AES256"
    with urllib.request.urlopen(b["image_url"], timeout=30) as resp:
        assert resp.read() == data
    # Stone ids come from one global counter.
    b2 = grade(client, data).json()
    assert int(b2["stone_id"][-5:]) > int(b["stone_id"][-5:])


def test_rejection_recorded_without_image(raw_client, app_state):
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        r = grade(c, tray_jpeg(), app_version="1.0.0", device="test")
        assert r.status_code == 200
        b = r.json()
        assert b["status"] == "no_stone" and "grading_id" not in b and "image_url" not in b
        rej = list(app_state.db.rejections.find({"uid": u.uid}))
        assert len(rej) == 1
        assert rej[0]["status"] == "no_stone" and rej[0]["diagnostics"] and rej[0]["message"]
        assert rej[0]["app_version"] == "1.0.0"
        assert not any(k in rej[0] for k in ("image", "image_key"))
        assert app_state.db.gradings.count_documents({"uid": u.uid}) == 0
        assert s3_keys(app_state.storage, u.uid) == []
        # The user record is created on the first request.
        assert app_state.db.users.find_one({"_id": u.uid})["email"] == u.email


# ---- History ----

@needs_stone
def test_history_list_filter_pagination(raw_client):
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        ids = [grade(c).json()["grading_id"] for _ in range(3)]
        first = c.get("/gradings?limit=2").json()
        assert [i["grading_id"] for i in first["items"]] == ids[::-1][:2]
        assert first["next_cursor"]
        second = c.get(f"/gradings?limit=2&cursor={first['next_cursor']}").json()
        assert [i["grading_id"] for i in second["items"]] == [ids[0]]
        assert second["next_cursor"] is None
        item = first["items"][0]
        assert item["image_url"].startswith("https://") and item["result"]["grade"]
        g = item["result"]["grade"]
        assert len(c.get(f"/gradings?grade={g}").json()["items"]) == 3
        assert c.get(f"/gradings?grade={g % 7 + 1}").json()["items"] == []
        referred = item["result"]["referred"]
        assert len(c.get(f"/gradings?referred={str(referred).lower()}").json()["items"]) == 3
        assert c.get(f"/gradings?referred={str(not referred).lower()}").json()["items"] == []
        now = datetime.now(timezone.utc)
        fmt = lambda d: d.strftime("%Y-%m-%dT%H:%M:%SZ")  # noqa: E731
        assert c.get(f"/gradings?from={fmt(now + timedelta(hours=1))}").json()["items"] == []
        assert c.get(f"/gradings?to={fmt(now - timedelta(hours=1))}").json()["items"] == []
        assert len(c.get(f"/gradings?from={fmt(now - timedelta(hours=1))}&to={fmt(now + timedelta(minutes=5))}")
                   .json()["items"]) == 3
        assert c.get("/gradings?limit=51").status_code == 400
        assert c.get("/gradings?cursor=@@@").status_code == 400
        r = c.get(f"/gradings/{ids[1]}")
        assert r.status_code == 200 and r.json()["grading_id"] == ids[1]


# ---- Isolation and delete ----

@needs_stone
def test_other_user_gets_404(client, client_b, app_state):
    b = grade(client).json()
    gid = b["grading_id"]
    assert client_b.get(f"/gradings/{gid}").status_code == 404
    assert client_b.delete(f"/gradings/{gid}").status_code == 404
    assert gid not in [i["grading_id"] for i in client_b.get("/gradings?limit=50").json()["items"]]
    assert client_b.get("/gradings/does-not-exist").status_code == 404
    doc = app_state.db.gradings.find_one({"_id": gid})
    assert doc["deleted"] is False and app_state.storage.exists(doc["image_key"])
    assert client.get(f"/gradings/{gid}").status_code == 200


@needs_stone
def test_delete_removes_image(client, app_state):
    gid = grade(client).json()["grading_id"]
    key = app_state.db.gradings.find_one({"_id": gid})["image_key"]
    assert app_state.storage.exists(key)
    assert client.delete(f"/gradings/{gid}").status_code == 204
    assert not app_state.storage.exists(key)
    assert app_state.db.gradings.find_one({"_id": gid})["deleted"] is True
    assert client.get(f"/gradings/{gid}").status_code == 404
    assert client.delete(f"/gradings/{gid}").status_code == 404
    assert gid not in [i["grading_id"] for i in client.get("/gradings?limit=50").json()["items"]]


# ---- /me ----

def test_me_round_trip(raw_client, app_state):
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        me = c.get("/me").json()
        assert me["uid"] == u.uid and me["email"] == u.email and me["role"] == "user"
        assert me["settings"] == {"show_name_on_certificates": False, "referral_threshold": 0.60}
        body = {"display_name": "Test User", "account_type": "company", "country": "LK",
                "phone": "+94770000000", "role": "admin", "uid": "someone-else", "unknown": 1,
                "company": {"name": "Orava", "reg_no": "PV1", "industry": "Gems", "extra": "x"},
                "settings": {"referral_threshold": 0.7, "show_name_on_certificates": True}}
        r = c.put("/me", json=body)
        assert r.status_code == 200, r.text
        me = c.get("/me").json()
        assert me["uid"] == u.uid and me["role"] == "user"
        assert me["display_name"] == "Test User" and me["account_type"] == "company"
        assert me["company"]["name"] == "Orava" and me["company"]["address"] is None
        assert "extra" not in me["company"] and "unknown" not in me
        assert me["settings"] == {"show_name_on_certificates": True, "referral_threshold": 0.7}
        # Partial update keeps the other fields.
        c.put("/me", json={"settings": {"show_name_on_certificates": False}})
        me = c.get("/me").json()
        assert me["settings"] == {"show_name_on_certificates": False, "referral_threshold": 0.7}
        assert me["display_name"] == "Test User"
        for bad in (0.39, 0.95):
            assert c.put("/me", json={"settings": {"referral_threshold": bad}}).status_code == 400
        assert c.put("/me", json={"account_type": "other"}).status_code == 400
        if os.path.exists(REAL_STONE):
            gid = grade(c).json()["grading_id"]
            assert app_state.db.gradings.find_one({"_id": gid})["referral_threshold_used"] == 0.7


# ---- Calibrations ----

def calibration(session_id):
    return {"session_id": session_id, "device": "Pixel 8",
            "valid_until": "2030-01-01T00:00:00Z",
            "ccm": [[1, 0, 0], [0, 1, 0], [0, 0, 1]], "residual": 1.5, "quality": "good",
            "measured_patches": [[250, 250, 250], [10, 10, 10], [118, 118, 118],
                                 [186, 186, 186], [5, 60, 140], [170, 55, 60]],
            "unknown": "ignored"}


def test_calibrations_round_trip(client, client_b):
    r1 = client.post("/calibrations", json=calibration("cal-1"))
    assert r1.status_code == 201, r1.text
    r2 = client.post("/calibrations", json=calibration("cal-2"))
    items = client.get("/calibrations").json()["items"]
    assert [i["session_id"] for i in items[:2]] == ["cal-2", "cal-1"]
    assert items[0]["calibration_id"] == r2.json()["calibration_id"]
    assert items[0]["ccm"][0] == [1, 0, 0] and items[0]["quality"] == "good"
    assert items[0]["valid_until"].startswith("2030-01-01")
    assert "cal-1" not in [i["session_id"] for i in client_b.get("/calibrations").json()["items"]]
    bad = calibration("x")
    bad["ccm"] = [[1, 0], [0, 1]]
    assert client.post("/calibrations", json=bad).status_code == 400
    bad = calibration("x")
    bad["measured_patches"][0] = [300, 0, 0]
    assert client.post("/calibrations", json=bad).status_code == 400


def test_duplicate_calibration_session_returns_409_with_the_existing_one(client, client_b):
    first = client.post("/calibrations", json=calibration("cal-dup"))
    assert first.status_code == 201
    again = client.post("/calibrations", json=calibration("cal-dup"))
    assert again.status_code == 409
    body = again.json()
    assert body["code"] == "duplicate_session"
    assert body["calibration"]["calibration_id"] == first.json()["calibration_id"]
    assert body["calibration"]["session_id"] == "cal-dup"
    assert [i["session_id"] for i in client.get("/calibrations").json()["items"]].count("cal-dup") == 1
    # Another user may use the same session id.
    assert client_b.post("/calibrations", json=calibration("cal-dup")).status_code == 201

