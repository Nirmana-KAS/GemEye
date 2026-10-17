"""Phase 10p: admin powers over users, gradings, calibrations and devices. Run with ENV=test
(see conftest.py). Every route: happy path, reviewer/user 403, validation and the audit entry."""
import csv
import io
import json
import time
import uuid
from datetime import datetime, timedelta, timezone

import cv2
import numpy as np
import pytest
from firebase_admin import auth as firebase_auth

from app import admin, limits, notifications
from app.auth import uid_hash
from app.limits import COLOMBO, device_id
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser
from tests.test_admin_writes import audited, cert, grading, n_audit, with_role
from tests.test_api import calibration, grade, needs_stone

MARK = "adp-" + uuid.uuid4().hex[:8]


@pytest.fixture(autouse=True)
def _reset():
    admin.reset_rate_limit()
    notifications.reset_rate_limit()
    yield
    admin.reset_rate_limit()
    notifications.reset_rate_limit()


@pytest.fixture(scope="module")
def admin_c(raw_client):
    with with_role("admin") as u:
        yield AuthedClient(raw_client, u)


@pytest.fixture(scope="module")
def reviewer_c(raw_client):
    with with_role("reviewer") as u:
        yield AuthedClient(raw_client, u)


@pytest.fixture(scope="module")
def app_c(raw_client, app_state):
    """A plain app user of its own (its sessions get revoked and limits set)."""
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        assert c.get("/me").status_code == 200
        yield c
        db = app_state.db
        for coll in ("gradings", "calibrations", "notifications", "admin_notes", "feedback"):
            getattr(db, coll).delete_many({"uid": u.uid})
        db.revoked_sessions.delete_one({"_id": uid_hash(u.uid)})


@pytest.fixture(scope="module", autouse=True)
def _cleanup(app_state):
    yield
    db = app_state.db
    db.gradings.delete_many({"_id": {"$regex": f"^{MARK}"}})
    db.certificates.delete_many({"_id": {"$regex": "^GE-209910"}})
    db.reviews.delete_many({"grading_id": {"$regex": f"^{MARK}"}})
    db.blocked_devices.delete_many({"device_model": {"$regex": f"^{MARK}"}})
    db.app_config.update_one({"_id": "global"}, {"$set": {"daily_grading_limit_default": None}})
    db.invalidate_app_config()


def add_grading(db, uid, n, **extra):
    doc = {**grading(f"{MARK}-g{n}", uid, 4, False), **extra}
    db.gradings.insert_one(doc)
    return doc["_id"]


def last_audit(db, action):
    return db.audit_log.find_one({"action": action}, sort=[("at", -1)])


def tiny_jpeg():
    ok, enc = cv2.imencode(".jpg", np.full((20, 20, 3), 200, np.uint8))
    return enc.tobytes()


def delete_with_body(c, url, body):
    return c.raw.request("DELETE", url, headers=c.user.headers, json=body)


# ---- Roles ----

ROUTES = [
    ("post", "/admin/users/{uid}/revoke-sessions", None),
    ("patch", "/admin/users/{uid}/profile", {"phone": "1"}),
    ("put", "/admin/users/{uid}/daily-limit", {"daily_grading_limit": 5}),
    ("get", "/admin/users/{uid}/notes", None),
    ("post", "/admin/users/{uid}/notes", {"text": "x"}),
    ("delete", "/admin/users/{uid}/notes/n1", None),
    ("get", "/admin/users/{uid}/activity", None),
    ("post", "/admin/gradings/g1/hide", {"reason": "r"}),
    ("post", "/admin/gradings/g1/restore", None),
    ("post", "/admin/gradings/g1/send-to-review", None),
    ("post", "/admin/gradings/g1/regrade", None),
    ("delete", "/admin/gradings/g1", {"confirm_id": "g1", "reason": "r"}),
    ("post", "/admin/gradings/bulk", {"action": "export", "ids": ["g1"]}),
    ("post", "/admin/calibrations/c1/invalidate", {"reason": "r"}),
    ("get", "/admin/devices/blocked", None),
    ("post", "/admin/devices/" + "a" * 24 + "/block", {"reason": "r"}),
    ("post", "/admin/devices/" + "a" * 24 + "/unblock", {"reason": "r"}),
]


def test_reviewer_and_user_forbidden(reviewer_c, client, app_c):
    for c in (reviewer_c, client):
        for method, path, body in ROUTES:
            url = path.format(uid=app_c.user.uid)
            r = c.raw.request(method.upper(), url, headers=c.user.headers, json=body)
            assert r.status_code == 403 and r.json()["code"] == "forbidden", (method, url, r.text)


# ---- A. Users ----

def test_revoke_sessions(admin_c, raw_client, app_state):
    db = app_state.db
    with FirebaseTestUser() as u:
        h = u.headers
        assert raw_client.get("/me", headers=h).status_code == 200
        n0 = n_audit(db, "user_revoke_sessions")
        r = admin_c.post(f"/admin/users/{u.uid}/revoke-sessions")
        assert r.status_code == 200 and r.json()["self"] is False
        e = audited(db, "user_revoke_sessions", n0)
        assert e["target"] == {"uid": u.uid} and e["after"]["self"] is False
        # The old token is refused everywhere (reads, writes, revocation-checked routes).
        for call in (lambda: raw_client.get("/me", headers=h),
                     lambda: raw_client.get("/gradings", headers=h),
                     lambda: raw_client.get("/me/notifications", headers=h),
                     lambda: raw_client.put("/me", headers=h, json={"country": "LK"})):
            r = call()
            assert r.status_code == 401 and r.json()["code"] == "token_revoked", r.text
            assert r.json()["message"] == "You were signed out. Please sign in again."
        time.sleep(1.5)
        u._token = None     # signs in again
        assert raw_client.get("/me", headers=u.headers).status_code == 200
    assert admin_c.post(f"/admin/users/{MARK}-nobody/revoke-sessions").status_code == 404

    # Self is allowed; the admin's own token stops working too.
    assert admin_c.post(f"/admin/users/{admin_c.user.uid}/revoke-sessions").json()["self"] is True
    r = admin_c.get("/admin/devices/blocked")
    assert r.status_code == 401 and r.json()["code"] == "token_revoked"
    time.sleep(1.5)
    admin_c.user._token = None
    assert admin_c.get("/admin/devices/blocked").status_code == 200
    db.revoked_sessions.delete_one({"_id": uid_hash(admin_c.user.uid)})


def test_edit_profile(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    p = f"/admin/users/{uid}/profile"
    for bad in ({}, {"email": "x@example.com"}, {"display_name": "n" * 101}, {"phone": "1" * 31},
                {"company": "c" * 201}, {"phone": 123}, {"role": "admin"}):
        r = admin_c.raw.request("PATCH", p, headers=admin_c.user.headers, json=bad)
        assert r.status_code == 400, bad
    n0 = n_audit(db, "user_profile_edit")
    r = admin_c.raw.request("PATCH", p, headers=admin_c.user.headers,
                            json={"display_name": "  Nimal Perera ", "phone": "+94 77 123 4567", "company": "Orava"})
    assert r.status_code == 200, r.text
    assert r.json() == {"uid": uid, "display_name": "Nimal Perera", "phone": "+94 77 123 4567", "company": "Orava"}
    e = audited(db, "user_profile_edit", n0)
    assert e["after"] == {"display_name": "Nimal Perera", "phone": "+94 77 123 4567", "company": "Orava"}
    doc = db.users.find_one({"_id": uid})
    assert doc["company"]["name"] == "Orava" and doc["email"] == app_c.user.email
    assert firebase_auth.get_user(uid).display_name == "Nimal Perera"
    assert app_c.get("/me").json()["phone"] == "+94 77 123 4567"
    # Empty clears a field; unknown users are 404.
    r = admin_c.raw.request("PATCH", p, headers=admin_c.user.headers, json={"phone": ""})
    assert r.json()["phone"] is None
    r = admin_c.raw.request("PATCH", f"/admin/users/{MARK}-nobody/profile", headers=admin_c.user.headers,
                            json={"phone": "1"})
    assert r.status_code == 404


def test_admin_notes(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    p = f"/admin/users/{uid}/notes"
    for bad in ({}, {"text": ""}, {"text": "   "}, {"text": "t" * 1001}, {"text": "ok", "x": 1}):
        assert admin_c.post(p, json=bad).status_code == 400, bad
    n0 = n_audit(db, "user_note_add")
    text = f"{MARK} called about a refund"
    r = admin_c.post(p, json={"text": text})
    assert r.status_code == 201, r.text
    note = r.json()
    assert note["text"] == text and note["author_email"] == admin_c.user.email
    assert audited(db, "user_note_add", n0)["after"] == {"text": text}
    assert admin_c.post(p, json={"text": "t" * 1000}).status_code == 201
    items = admin_c.get(p).json()["items"]
    assert items[1]["id"] == note["id"] and items[1]["author_email"] == admin_c.user.email
    # Never returned by any /me route.
    for path in ("/me", "/gradings", "/calibrations", "/me/notifications"):
        assert "called about a refund" not in app_c.get(path).text
    n1 = n_audit(db, "user_note_delete")
    assert admin_c.delete(f"{p}/{note['id']}").status_code == 204
    assert audited(db, "user_note_delete", n1)["before"] == {"text": text}
    assert admin_c.delete(f"{p}/{note['id']}").status_code == 404
    assert admin_c.post(f"/admin/users/{MARK}-nobody/notes", json={"text": "x"}).status_code == 404


def test_daily_limit_colombo_midnight(admin_c, app_c, app_state, monkeypatch):
    db, uid = app_state.db, app_c.user.uid
    p = f"/admin/users/{uid}/daily-limit"
    for bad in ({}, {"daily_grading_limit": 0}, {"daily_grading_limit": 501}, {"daily_grading_limit": "5"},
                {"daily_grading_limit": 2.5}, {"daily_grading_limit": 5, "x": 1}):
        assert admin_c.put(p, json=bad).status_code == 400, bad
    n0 = n_audit(db, "user_daily_limit")
    r = admin_c.put(p, json={"daily_grading_limit": 1})
    assert r.status_code == 200 and r.json()["effective"] == 1
    e = audited(db, "user_daily_limit", n0)
    assert e["before"] == {"daily_grading_limit": None} and e["after"] == {"daily_grading_limit": 1}

    # 00:00:30 on 17 Oct 2099 in Colombo (18:30:30 UTC the day before).
    now = datetime(2099, 10, 17, 0, 0, 30, tzinfo=COLOMBO).astimezone(timezone.utc)
    monkeypatch.setattr(limits, "_now", lambda: now)
    db.gradings.delete_many({"uid": uid})
    add_grading(db, uid, "late", created_at=now - timedelta(seconds=40))   # 23:59:50 the day before
    post = lambda: grade(app_c, data=tiny_jpeg())  # noqa: E731
    r = post()
    assert r.status_code == 200 and r.json()["status"] == "invalid_image", r.text
    add_grading(db, uid, "early", created_at=now - timedelta(seconds=25))  # 00:00:05 today
    r = post()
    assert r.status_code == 429 and r.json()["code"] == "DAILY_LIMIT_REACHED"
    assert r.json()["message"] == "Daily grading limit reached. Try again tomorrow or contact support."
    # The next Colombo day is free again.
    monkeypatch.setattr(limits, "_now", lambda: now + timedelta(days=1))
    assert post().status_code == 200

    # User null -> the config default applies (bounds 1-500, null = no limit).
    monkeypatch.setattr(limits, "_now", lambda: now)
    assert admin_c.put(p, json={"daily_grading_limit": None}).json()["effective"] is None
    assert post().status_code == 200
    for bad in (0, 501, "3"):
        assert admin_c.put("/admin/config", json={"daily_grading_limit_default": bad}).status_code == 400
    n1 = n_audit(db, "config_update")
    r = admin_c.put("/admin/config", json={"daily_grading_limit_default": 1})
    assert r.status_code == 200 and r.json()["daily_grading_limit_default"] == 1
    assert r.json()["bounds"]["daily_grading_limit_default"] == {"min": 1, "max": 500}
    assert audited(db, "config_update", n1)["after"] == {"daily_grading_limit_default": 1}
    assert post().status_code == 429
    detail = admin_c.get(f"/admin/users/{uid}").json()["daily_limit"]
    assert detail["user"] is None and detail["default"] == 1 and detail["effective"] == 1
    assert admin_c.put("/admin/config", json={"daily_grading_limit_default": None}).status_code == 200
    assert post().status_code == 200
    db.gradings.delete_many({"uid": uid})


def test_activity_timeline(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    base = datetime.now(timezone.utc) - timedelta(days=3)
    add_grading(db, uid, "act", created_at=base + timedelta(minutes=1))
    db.calibrations.insert_one({**calibration(f"{MARK}-act"), "_id": f"{MARK}-cal-act", "uid": uid,
                                "created_at": base + timedelta(minutes=2)})
    db.feedback.insert_one({"_id": f"{MARK}-fb-act", "uid": uid, "created_at": base + timedelta(minutes=3),
                            "rating": 5, "category": "app"})
    admin_c.post(f"/admin/users/{uid}/notes", json={"text": "activity"})
    seen, cursor = [], None
    while True:
        r = admin_c.get(f"/admin/users/{uid}/activity", params={"limit": 2, **({"cursor": cursor} if cursor else {})})
        assert r.status_code == 200, r.text
        body = r.json()
        assert len(body["items"]) <= 2
        seen += body["items"]
        cursor = body["next_cursor"]
        if not cursor:
            break
    times = [datetime.fromisoformat(e["at"]) for e in seen]
    assert times == sorted(times, reverse=True) and len({e["id"] for e in seen}) == len(seen)
    types = {e["type"] for e in seen}
    assert {"grading", "calibration", "feedback", "admin_action", "account_created", "signed_in"} <= types
    note = [e for e in seen if e["type"] == "admin_action" and e["action"] == "user_note_add"]
    assert note and note[0]["admin_email"] == admin_c.user.email
    assert admin_c.get(f"/admin/users/{uid}/activity", params={"cursor": "bad"}).status_code == 400
    assert admin_c.get(f"/admin/users/{MARK}-nobody/activity").status_code == 404
    db.calibrations.delete_one({"_id": f"{MARK}-cal-act"})


# ---- B. Gradings ----

def test_hide_restore_excluded_from_me(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    gid = add_grading(db, uid, "hide")
    mine = lambda: [i["grading_id"] for i in app_c.get("/gradings").json()["items"]]  # noqa: E731
    assert gid in mine()
    for bad in ({}, {"reason": ""}, {"reason": "  "}, {"reason": "r" * 501}):
        assert admin_c.post(f"/admin/gradings/{gid}/hide", json=bad).status_code == 400, bad
    n0 = n_audit(db, "grading_hide")
    assert admin_c.post(f"/admin/gradings/{gid}/hide", json={"reason": "Test photo"}).status_code == 200
    e = audited(db, "grading_hide", n0)
    assert e["target"] == {"grading_id": gid, "uid": uid} and e["after"] == {"hidden": True, "reason": "Test photo"}
    # Gone for the owner: history, detail, heatmap, certificate; still in the database.
    assert gid not in mine()
    assert app_c.get(f"/gradings/{gid}").status_code == 404
    assert app_c.post(f"/gradings/{gid}/heatmap").status_code == 404
    assert app_c.post("/certificates", json={"grading_id": gid}).status_code == 404
    assert db.gradings.find_one({"_id": gid})["hidden"] is True
    rows = admin_c.get("/admin/gradings", params={"uid": uid, "hidden": "true"}).json()["items"]
    assert [x["grading_id"] for x in rows] == [gid] and rows[0]["hidden"] is True
    assert gid not in [x["grading_id"] for x in admin_c.get("/admin/gradings", params={"uid": uid, "hidden": "false"}).json()["items"]]
    detail = admin_c.get(f"/admin/gradings/{gid}").json()
    assert detail["hidden_info"]["reason"] == "Test photo" and detail["hidden_info"]["by_email"] == admin_c.user.email
    assert admin_c.post(f"/admin/gradings/{gid}/hide", json={"reason": "again"}).json()["code"] == "already_hidden"

    n1 = n_audit(db, "grading_restore")
    assert admin_c.post(f"/admin/gradings/{gid}/restore").status_code == 200
    assert audited(db, "grading_restore", n1)["before"] == {"hidden": True, "reason": "Test photo"}
    assert gid in mine()
    r = admin_c.post(f"/admin/gradings/{gid}/restore", json={"reason": "x"})
    assert r.status_code == 409 and r.json()["code"] == "not_hidden"
    assert admin_c.post(f"/admin/gradings/{MARK}-none/hide", json={"reason": "x"}).status_code == 404


def test_send_to_review(admin_c, reviewer_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    gid = add_grading(db, uid, "rev")          # not referred
    queue = lambda: {i["grading_id"]: i for i in reviewer_c.get("/admin/review-queue?limit=100").json()["items"]}  # noqa: E731
    assert gid not in queue()
    n0 = n_audit(db, "grading_send_to_review")
    r = admin_c.post(f"/admin/gradings/{gid}/send-to-review", json={"reason": "Customer asked"})
    assert r.status_code == 200 and r.json()["reason"] == "admin"
    e = audited(db, "grading_send_to_review", n0)
    assert e["before"] == {"in_queue": False} and e["after"]["reason"] == "admin"
    item = queue()[gid]
    assert item["referred_reasons"] == ["admin"]
    assert admin_c.get(f"/admin/gradings/{gid}").json()["review_request"]["reason"] == "admin"
    r = admin_c.post(f"/admin/gradings/{gid}/send-to-review")
    assert r.status_code == 409 and r.json()["code"] == "already_in_queue"
    assert reviewer_c.post("/admin/reviews", json={"grading_id": gid, "gemologist_grade": 4}).status_code == 201
    assert gid not in queue()
    gid2 = add_grading(db, uid, "rev2")
    db.reviews.insert_one({"_id": f"{MARK}-rv2", "grading_id": gid2, "gemologist_grade": 4,
                           "created_at": datetime.now(timezone.utc)})
    assert admin_c.post(f"/admin/gradings/{gid2}/send-to-review").json()["code"] == "already_reviewed"
    assert admin_c.post(f"/admin/gradings/{gid}/send-to-review", json={"reason": 5}).status_code == 400


def test_bulk_actions(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    ids = [add_grading(db, uid, f"b{i}", device="=cmd|calc") for i in range(3)]
    url = "/admin/gradings/bulk"
    for bad in ({"action": "hide", "ids": ids}, {"action": "hide", "ids": ids, "reason": " "},
                {"action": "delete", "ids": ids}, {"action": "restore", "ids": []},
                {"action": "restore", "ids": [ids[0], ids[0]]},
                {"action": "restore", "ids": [f"x{i}" for i in range(201)]},
                {"action": "restore", "ids": ids, "extra": 1}):
        assert admin_c.post(url, json=bad).status_code == 400, bad
    n0 = n_audit(db, "grading_hide")
    r = admin_c.post(url, json={"action": "hide", "ids": ids + [f"{MARK}-none"], "reason": "Spam"})
    assert r.status_code == 200, r.text
    assert r.json()["done"] == ids and r.json()["skipped"] == [{"id": f"{MARK}-none", "reason": "not_found"}]
    assert n_audit(db, "grading_hide") == n0 + 3
    assert last_audit(db, "grading_hide")["target"]["bulk"] is True
    assert db.gradings.count_documents({"_id": {"$in": ids}, "hidden": True}) == 3
    r = admin_c.post(url, json={"action": "hide", "ids": ids[:1], "reason": "Spam"})
    assert r.json()["skipped"] == [{"id": ids[0], "reason": "already_hidden"}]
    assert admin_c.post(url, json={"action": "restore", "ids": ids}).json()["done"] == ids
    assert admin_c.post(url, json={"action": "send_to_review", "ids": ids}).json()["done"] == ids
    n1 = n_audit(db, "gradings_export")
    r = admin_c.post(url, json={"action": "export", "ids": ids})
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/csv")
    rows = list(csv.reader(io.StringIO(r.text)))
    assert rows[0][:3] == ["grading_id", "stone_id", "created_at"] and [x[0] for x in rows[1:]] == ids
    assert rows[1][rows[0].index("device")] == "'=cmd|calc"     # no spreadsheet formulas
    assert rows[1][rows[0].index("user_email")] == app_c.user.email
    assert audited(db, "gradings_export", n1)["after"] == {"count": 3}


def test_permanent_delete(admin_c, app_c, raw_client, app_state, monkeypatch):
    db, uid, st = app_state.db, app_c.user.uid, app_state.storage
    gid = add_grading(db, uid, "del", image_key=st.grading_key(uid, f"{MARK}-gdel"),
                      heatmap={"key": st.grading_key(uid, f"{MARK}-gdel_cam", "png")})
    stone = db.gradings.find_one({"_id": gid})["stone_id"]
    c = cert("GE-209910-00001", "tokDel1", uid, gid)
    c.update(image_key=st.certificate_key(c["_id"], "jpg"), pdf_key=st.certificate_key(c["_id"]))
    db.certificates.insert_one(c)
    db.reviews.insert_one({"_id": f"{MARK}-rvd", "grading_id": gid, "gemologist_grade": 4,
                           "created_at": datetime.now(timezone.utc)})
    db.audit_log.insert_one({"_id": f"{MARK}-aud", "action": "review_create", "target": {"grading_id": gid},
                             "before": None, "after": {"gemologist_grade": 4}, "at": datetime.now(timezone.utc)})
    notifications.create_notification(db, uid, "info", "Referred", "x", payload=stone)
    deleted = []
    monkeypatch.setattr(st, "delete", lambda key: deleted.append(key))   # S3 mocked

    url = f"/admin/gradings/{gid}"
    for bad in ({"reason": "r"}, {"confirm_id": gid}, {"confirm_id": gid, "reason": " "}):
        assert delete_with_body(admin_c, url, bad).status_code == 400, bad
    r = delete_with_body(admin_c, url, {"confirm_id": "wrong", "reason": "Privacy request"})
    assert r.status_code == 400 and r.json()["code"] == "confirm_mismatch"
    assert db.gradings.find_one({"_id": gid}) is not None and not deleted

    n0 = n_audit(db, "grading_delete_permanent")
    r = delete_with_body(admin_c, url, {"confirm_id": gid, "reason": "Privacy request"})
    assert r.status_code == 200 and r.json()["withdrawn"] == ["GE-209910-00001"], r.text
    assert set(deleted) == {st.grading_key(uid, f"{MARK}-gdel"), st.grading_key(uid, f"{MARK}-gdel_cam", "png"),
                            st.certificate_key(c["_id"], "jpg"), st.certificate_key(c["_id"])}
    assert db.gradings.find_one({"_id": gid}) is None
    assert db.reviews.count_documents({"grading_id": gid}) == 0
    assert db.notifications.count_documents({"uid": uid, "payload": stone}) == 0
    w = db.certificates.find_one({"_id": "GE-209910-00001"})
    assert w["status"] == "withdrawn" and "snapshot" not in w and "uid" not in w and "grading_id" not in w
    pub = raw_client.get("/public/v/GE-209910-00001-tokDel1").json()
    assert pub["status"] == "withdrawn" and pub.get("snapshot") is None and pub.get("image_url") is None
    e = audited(db, "grading_delete_permanent", n0)
    assert e["target"] == {"grading_id": gid, "uid_hash": uid_hash(uid)}
    text = json.dumps(e, default=str).lower()
    for word in ("colour", "grade\"", "confidence", "probabilities", "hex"):
        assert word not in text, word
    assert db.audit_log.find_one({"_id": f"{MARK}-aud"})["after"] is None
    assert delete_with_body(admin_c, url, {"confirm_id": gid, "reason": "again"}).status_code == 404


def test_regrade_without_photo(admin_c, app_c, app_state):
    gid = add_grading(app_state.db, app_c.user.uid, "nophoto")
    r = admin_c.post(f"/admin/gradings/{gid}/regrade")
    assert r.status_code == 409 and r.json()["code"] == "photo_missing"
    assert admin_c.post(f"/admin/gradings/{MARK}-none/regrade").status_code == 404


@needs_stone
def test_regrade_keeps_original(admin_c, app_c, app_state):
    db = app_state.db
    r = grade(app_c)
    assert r.status_code == 200 and r.json()["status"] == "ok", r.text
    gid = r.json()["grading_id"]
    original = db.gradings.find_one({"_id": gid})["result"]
    # Make the stored result differ from what the model gives, to prove it is never rewritten.
    db.gradings.update_one({"_id": gid}, {"$set": {"result.grade": 7, "result.model_version": "v-old"}})
    n0 = n_audit(db, "grading_regrade")
    r = admin_c.post(f"/admin/gradings/{gid}/regrade")
    assert r.status_code == 200, r.text
    body = r.json()
    # MC dropout: the re-grade need not equal the original grade, only be a valid result.
    assert body["status"] == "ok" and 1 <= body["grade"] <= 7 and original["status"] == "ok"
    assert body["model_version"] == app_state.assets.manifest["model_version"]
    assert len(body["probabilities"]) == 7 and body["original"]["grade"] == 7
    assert body["by_email"] == admin_c.user.email and "by_hash" not in body
    doc = db.gradings.find_one({"_id": gid})
    assert doc["result"]["grade"] == 7 and doc["result"]["model_version"] == "v-old"
    assert len(doc["regrades"]) == 1 and doc["regrades"][0]["confidence"] == body["confidence"]
    e = audited(db, "grading_regrade", n0)
    assert e["target"] == {"grading_id": gid, "uid": app_c.user.uid}
    detail = admin_c.get(f"/admin/gradings/{gid}").json()
    assert detail["result"]["grade"] == 7 and detail["regrades"][0]["grade"] == body["grade"]
    assert detail["regrades"][0]["by_email"] == admin_c.user.email
    db.gradings.delete_one({"_id": gid})


# ---- C. Calibrations and devices ----

def test_invalidate_calibration(admin_c, app_c, app_state):
    db, uid = app_state.db, app_c.user.uid
    sid = f"{MARK}-cal-inv"
    assert app_c.post("/calibrations", json=calibration(sid)).status_code == 201
    cid = db.calibrations.find_one({"uid": uid, "session_id": sid})["_id"]
    status = lambda: app_c.get("/me/calibration-status", params={"session_id": sid}).json()  # noqa: E731
    assert status() == {"session_id": sid, "found": True, "invalidated": False, "invalidated_at": None}
    assert app_c.get("/me/calibration-status", params={"session_id": "none"}).json()["found"] is False
    for bad in ({}, {"reason": ""}, {"reason": "r" * 501}):
        assert admin_c.post(f"/admin/calibrations/{cid}/invalidate", json=bad).status_code == 400
    n0 = n_audit(db, "calibration_invalidate")
    r = admin_c.post(f"/admin/calibrations/{cid}/invalidate", json={"reason": "Wrong card used"})
    assert r.status_code == 200, r.text
    e = audited(db, "calibration_invalidate", n0)
    assert e["target"] == {"calibration_id": cid, "uid": uid, "session_id": sid}
    s = status()
    assert s["invalidated"] is True and s["invalidated_at"] and "reason" not in s
    notes = list(db.notifications.find({"uid": uid, "category": "calibration", "payload": sid}))
    assert len(notes) == 1 and notes[0]["message"].startswith("Your calibration was reset by support")
    assert notes[0]["action"] == "openCalibration"
    r = admin_c.post(f"/admin/calibrations/{cid}/invalidate", json={"reason": "again"})
    assert r.status_code == 409 and r.json()["code"] == "already_invalidated"
    assert db.notifications.count_documents({"uid": uid, "payload": sid}) == 1
    rows = admin_c.get("/admin/calibrations", params={"uid": uid}).json()["items"]
    assert [x for x in rows if x["calibration_id"] == cid][0]["invalidated_reason"] == "Wrong card used"
    assert admin_c.post(f"/admin/calibrations/{MARK}-none/invalidate", json={"reason": "x"}).status_code == 404


def test_block_device_legacy_model_id(admin_c, app_c, app_state):
    """Old app builds without X-Device-Id: the id falls back to the model name hash."""
    db, uid = app_state.db, app_c.user.uid
    name, other = f"{MARK} Phone X", f"{MARK} Phone Y"
    assert app_c.post("/calibrations", json={**calibration(f"{MARK}-dev1"), "device": name}).status_code == 201
    states = admin_c.get(f"/admin/users/{uid}").json()["device_states"]
    did = device_id(name)
    assert {"device_id": did, "short_id": did[:8], "name": name, "blocked": False} in states
    url = f"/admin/devices/{did}"
    assert admin_c.post(f"{url}/block", json={}).status_code == 400
    n0 = n_audit(db, "device_block")
    r = admin_c.post(f"{url}/block", json={"reason": "Abuse"})
    assert r.status_code == 200 and r.json() == {"device_id": did, "short_id": did[:8], "name": name, "blocked": True}
    assert audited(db, "device_block", n0)["after"] == {"blocked": True, "device_model": name, "reason": "Abuse"}
    assert admin_c.post(f"{url}/block", json={"reason": "Abuse"}).json()["code"] == "already_blocked"

    r = app_c.post("/calibrations", json={**calibration(f"{MARK}-dev2"), "device": name})
    assert r.status_code == 403 and r.json()["code"] == "DEVICE_BLOCKED"
    assert r.json()["message"] == "This device is blocked. Contact support."
    r = grade(app_c, data=tiny_jpeg(), device=f"  {name} ")
    assert r.status_code == 403 and r.json()["code"] == "DEVICE_BLOCKED"
    assert grade(app_c, data=tiny_jpeg(), device=other).status_code == 200
    state = [d for d in admin_c.get(f"/admin/users/{uid}").json()["device_states"] if d["device_id"] == did][0]
    assert state["blocked"] is True and state["blocked_reason"] == "Abuse"
    assert state["blocked_by_email"] == admin_c.user.email
    blocked = [d for d in admin_c.get("/admin/devices/blocked").json()["items"] if d["device_id"] == did]
    assert blocked[0]["name"] == name and blocked[0]["short_id"] == did[:8]

    n1 = n_audit(db, "device_unblock")
    assert admin_c.post(f"{url}/unblock", json={"reason": "Resolved"}).status_code == 200
    assert audited(db, "device_unblock", n1)["before"]["reason"] == "Abuse"
    assert app_c.post("/calibrations", json={**calibration(f"{MARK}-dev4"), "device": name}).status_code == 201
    assert admin_c.post(f"{url}/unblock", json={"reason": "x"}).json()["code"] == "not_blocked"
    assert admin_c.post(f"/admin/devices/{'0' * 24}/block", json={"reason": "x"}).status_code == 404
    assert admin_c.post("/admin/devices/not-an-id/block", json={"reason": "x"}).status_code == 404


def test_block_one_install_same_model(admin_c, app_c, client_b, app_state):
    """Two users on the same phone model: blocking one install leaves the other grading."""
    db = app_state.db
    model = f"{MARK} Galaxy A15"
    h1, h2 = {"X-Device-Id": str(uuid.uuid4())}, {"X-Device-Id": str(uuid.uuid4())}
    cal = lambda c, n, h: c.post("/calibrations", headers=h, json={**calibration(f"{MARK}-same{n}"), "device": model})  # noqa: E731
    assert cal(app_c, 1, h1).status_code == 201 and cal(client_b, 1, h2).status_code == 201
    d1 = limits.install_device_id(h1["X-Device-Id"])
    d2 = limits.install_device_id(h2["X-Device-Id"])
    assert d1 != d2 and d1 != device_id(model)
    stored = db.calibrations.find_one({"uid": app_c.user.uid, "session_id": f"{MARK}-same1"})
    assert stored["device_id"] == d1 and stored["device"] == model
    states = admin_c.get(f"/admin/users/{app_c.user.uid}").json()["device_states"]
    assert {"device_id": d1, "short_id": d1[:8], "name": model, "blocked": False} in states

    r = admin_c.post(f"/admin/devices/{d1}/block", json={"reason": "Abuse"})
    assert r.status_code == 200 and r.json()["name"] == model
    assert db.blocked_devices.find_one({"_id": d1})["device_model"] == model
    # The blocked install: grade and calibration refused.
    r = app_c.post("/grade", headers=h1, files={"image": ("s.jpg", tiny_jpeg(), "image/jpeg")}, data={"device": model})
    assert r.status_code == 403 and r.json()["code"] == "DEVICE_BLOCKED"
    assert cal(app_c, 2, h1).status_code == 403
    # Same model, other install (and the same user on a new install) still grade.
    r = client_b.post("/grade", headers=h2, files={"image": ("s.jpg", tiny_jpeg(), "image/jpeg")}, data={"device": model})
    assert r.status_code == 200, r.text
    assert cal(client_b, 2, h2).status_code == 201
    new = {"X-Device-Id": str(uuid.uuid4())}
    r = app_c.post("/grade", headers=new, files={"image": ("s.jpg", tiny_jpeg(), "image/jpeg")}, data={"device": model})
    assert r.status_code == 200
    # Model hash (old builds without the header) is not blocked either; a bad header falls back to it.
    assert grade(client_b, data=tiny_jpeg(), device=model).status_code == 200
    r = client_b.post("/grade", headers={"X-Device-Id": "not-a-uuid"},
                      files={"image": ("s.jpg", tiny_jpeg(), "image/jpeg")}, data={"device": model})
    assert r.status_code == 200
    assert admin_c.post(f"/admin/devices/{d1}/unblock", json={"reason": "ok"}).status_code == 200
    for u in (app_c.user.uid, client_b.user.uid):
        db.calibrations.delete_many({"uid": u, "session_id": {"$regex": f"^{MARK}"}})
