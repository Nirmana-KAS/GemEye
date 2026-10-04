"""Phase 4b: certificates, public verification, account deletion, remote config,
feedback and the concurrent /grade save. Run with ENV=test (see conftest.py)."""
import hashlib
import re
import urllib.request
import uuid
from datetime import datetime, timezone

import pytest
from firebase_admin import auth as firebase_auth

from app import certificates, routers
from app.certificates import COLOMBO, DISCLAIMER, limiter
from app.db import DEFAULT_APP_CONFIG
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser
from tests.test_api import calibration, grade, needs_stone, s3_keys, stone_bytes, tray_jpeg

PDF = b"%PDF-1.4\n% GemEye test certificate\n%%EOF\n"
CERT_NO = re.compile(r"GE-(\d{6})-(\d{5})")


@pytest.fixture(autouse=True)
def _reset_rate_limit():
    limiter.reset()
    yield
    limiter.reset()


def graded(c):
    r = grade(c, session_id="cal-cert")
    assert r.status_code == 200 and r.json()["status"] == "ok", r.text
    return r.json()


def issue(c, grading_id):
    return c.post("/certificates", json={"grading_id": grading_id})


def slug(verify_url):
    return verify_url.rsplit("/", 1)[1]


def upload_pdf(c, cert_no, data=PDF, ctype="application/pdf"):
    return c.post(f"/certificates/{cert_no}/pdf", files={"file": ("c.pdf", data, ctype)})


# ---- Auth on the new endpoints ----

@pytest.mark.parametrize("method,url", [
    ("post", "/certificates"), ("get", "/certificates"), ("get", "/certificates/GE-202601-00001"),
    ("post", "/certificates/GE-202601-00001/pdf"), ("post", "/certificates/GE-202601-00001/revoke"),
    ("delete", "/me"), ("post", "/feedback")])
def test_401_new_endpoints(raw_client, method, url):
    r = getattr(raw_client, method)(url, headers={"Authorization": "Bearer not-a-token"})
    assert r.status_code == 401 and r.json()["detail"] == "Authentication required."


# ---- Certificates ----

@needs_stone
def test_issue_idempotent_and_snapshot(client, app_state, user_a):
    client.post("/calibrations", json=calibration("cal-cert"))
    g = graded(client)
    r = issue(client, g["grading_id"])
    assert r.status_code == 201, r.text
    b = r.json()
    assert set(b) == {"cert_no", "verify_url", "issued_at"}
    month, seq = CERT_NO.fullmatch(b["cert_no"]).groups()
    assert month == datetime.now(COLOMBO).strftime("%Y%m")
    assert app_state.db.counters.find_one({"_id": f"cert-{month}"})["seq"] >= int(seq)
    token = b["verify_url"].removeprefix(f"https://gemeye-app-2026.web.app/v/{b['cert_no']}-")
    assert len(token) == 16 and token != b["verify_url"]
    # Same grading again: the same certificate, not a new number.
    r2 = issue(client, g["grading_id"])
    assert r2.status_code == 200 and r2.json() == b
    assert app_state.db.certificates.count_documents({"grading_id": g["grading_id"]}) == 1

    doc = app_state.db.certificates.find_one({"_id": b["cert_no"]})
    assert doc["uid"] == user_a.uid and doc["status"] == "valid" and doc["owner"] is None
    assert doc["token"] == token and doc["token_sha256"] == hashlib.sha256(token.encode()).hexdigest()
    s = doc["snapshot"]
    assert s["stone_id"] == g["stone_id"] and s["grade"] == g["grade"]
    assert s["colour"] == g["colour"] and "approximate" in s["colour"] and "ciecam02" in s["colour"]
    for k in ("grade_name", "trade_name", "confidence", "uncertainty", "referred",
              "delta_e00_to_typical", "model_version"):
        assert s[k] == g[k]
    assert s["calibration"] == {"session_id": "cal-cert", "residual": 1.5}
    assert s["captured_at"] and s["issued_at"]

    one = client.get(f"/certificates/{b['cert_no']}").json()
    assert one["verify_url"] == b["verify_url"] and one["grading_id"] == g["grading_id"]
    assert one["snapshot"]["grade"] == g["grade"]
    second = issue(client, graded(client)["grading_id"]).json()
    listed = [i["cert_no"] for i in client.get("/certificates").json()["items"]]
    assert listed[:2] == [second["cert_no"], b["cert_no"]]
    assert int(second["cert_no"][-5:]) > int(b["cert_no"][-5:])


@needs_stone
def test_monthly_prefix_uses_colombo_time(client, app_state, monkeypatch):
    """2026-01-31 19:00 UTC is 2026-02-01 00:30 in Colombo: February counter."""
    fixed = datetime(2026, 1, 31, 19, 0, tzinfo=timezone.utc)
    doc = app_state.db.gradings.find_one({"_id": graded(client)["grading_id"]})
    doc.update(_id=uuid.uuid4().hex, created_at=fixed)
    app_state.db.gradings.insert_one(doc)
    monkeypatch.setattr(certificates, "utcnow", lambda: fixed)
    r = issue(client, doc["_id"])
    assert r.status_code == 201, r.text
    cert_no = r.json()["cert_no"]
    assert cert_no.startswith("GE-202602-") and CERT_NO.fullmatch(cert_no)
    assert app_state.db.counters.find_one({"_id": "cert-202602"})["seq"] == int(cert_no[-5:])


@needs_stone
def test_pdf_upload_once(client, app_state):
    cert = issue(client, graded(client)["grading_id"]).json()
    no = cert["cert_no"]
    assert upload_pdf(client, no, b"not a pdf", "application/pdf").status_code == 400
    assert upload_pdf(client, no, PDF, "image/png").status_code == 400
    assert upload_pdf(client, no, b"%PDF-" + b"0" * (5 * 1024 * 1024)).status_code == 413
    r = upload_pdf(client, no)
    assert r.status_code == 201, r.text
    sha = hashlib.sha256(PDF).hexdigest()
    assert r.json()["pdf_sha256"] == sha
    doc = app_state.db.certificates.find_one({"_id": no})
    assert doc["pdf_sha256"] == sha and doc["pdf_key"] == f"test/certificates/{no}.pdf"
    assert app_state.storage.get(doc["pdf_key"]) == PDF
    second = upload_pdf(client, no, PDF + b"x")
    assert second.status_code == 409
    assert app_state.storage.get(doc["pdf_key"]) == PDF
    # Public page links the PDF and its hash.
    p = client.raw.get(f"/public/v/{slug(cert['verify_url'])}").json()
    assert p["pdf_sha256"] == sha
    with urllib.request.urlopen(p["pdf_url"], timeout=30) as resp:
        assert resp.read() == PDF


# ---- Public verification ----

@needs_stone
def test_public_valid_and_not_found(raw_client, client, user_a):
    g = graded(client)
    cert = issue(client, g["grading_id"]).json()
    url = f"/public/v/{slug(cert['verify_url'])}"
    r = raw_client.get(url, headers={"Origin": "https://gemeye-app-2026.web.app"})
    assert r.status_code == 200, r.text
    assert r.headers["cache-control"] == "no-store"
    assert r.headers["access-control-allow-origin"] == "https://gemeye-app-2026.web.app"
    b = r.json()
    assert b["status"] == "valid" and b["cert_no"] == cert["cert_no"]
    assert b["snapshot"]["grade"] == g["grade"] and b["owner"] is None
    assert b["disclaimer"] == DISCLAIMER and b["pdf_url"] is None
    assert f"/certificates/{cert['cert_no']}.jpg?" in b["image_url"]
    with urllib.request.urlopen(b["image_url"], timeout=30) as resp:
        assert resp.read() == stone_bytes()
    assert user_a.uid not in r.text and user_a.email not in r.text
    assert "grading_id" not in b and "uid" not in b
    # CORS only for the allowed origins.
    r = raw_client.get(url, headers={"Origin": "https://evil.example"})
    assert r.status_code == 200 and "access-control-allow-origin" not in r.headers
    assert raw_client.get(url, headers={"Origin": "http://localhost:3000"}).headers[
        "access-control-allow-origin"] == "http://localhost:3000"

    month, seq = CERT_NO.fullmatch(cert["cert_no"]).groups()
    wrong_token = raw_client.get(f"/public/v/{cert['cert_no']}-AAAAAAAAAAAAAAAA")
    unknown = raw_client.get(f"/public/v/GE-{month}-99998-{slug(cert['verify_url']).split('-', 3)[3]}")
    malformed = raw_client.get("/public/v/nonsense")
    for r in (wrong_token, unknown, malformed):
        assert r.status_code == 404
        assert r.content == wrong_token.content
        assert r.headers["cache-control"] == "no-store"
    assert wrong_token.json() == {"status": "error", "detail": "Not found."}


@needs_stone
def test_owner_shown_only_when_enabled_at_issue(raw_client):
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        c.put("/me", json={"display_name": "Kamal Perera", "account_type": "company",
                           "company": {"name": "Orava (Pvt) Ltd"}})
        hidden = issue(c, graded(c)["grading_id"]).json()
        c.put("/me", json={"settings": {"show_name_on_certificates": True}})
        shown = issue(c, graded(c)["grading_id"]).json()
        # Turning the setting off later does not change an issued certificate.
        c.put("/me", json={"settings": {"show_name_on_certificates": False}})
        h = raw_client.get(f"/public/v/{slug(hidden['verify_url'])}").json()
        s = raw_client.get(f"/public/v/{slug(shown['verify_url'])}").json()
        assert h["owner"] is None and "Kamal" not in str(h)
        assert s["owner"] == {"display_name": "Kamal Perera", "company": "Orava (Pvt) Ltd"}
        assert u.email not in str(s) and u.uid not in str(s)


def test_rate_limit(raw_client):
    codes = [raw_client.get("/public/v/GE-202601-00000-x").status_code for _ in range(31)]
    assert codes[:30] == [404] * 30 and codes[30] == 429
    r = raw_client.get("/public/v/GE-202601-00000-x")
    assert r.status_code == 429 and r.headers["cache-control"] == "no-store"


@needs_stone
def test_revoke_and_deleted_grading(raw_client, client, client_b, app_state):
    g = graded(client)
    cert = issue(client, g["grading_id"]).json()
    no = cert["cert_no"]
    assert client.post(f"/certificates/{no}/revoke", json={"reason": ""}).status_code == 400
    r = client.post(f"/certificates/{no}/revoke", json={"reason": "Stone re-cut"})
    assert r.status_code == 200 and r.json()["status"] == "revoked"
    assert client.post(f"/certificates/{no}/revoke", json={"reason": "again"}).status_code == 409
    assert upload_pdf(client, no).status_code == 409
    p = raw_client.get(f"/public/v/{slug(cert['verify_url'])}").json()
    assert p["status"] == "revoked" and p["revoked_reason"] == "Stone re-cut" and p["revoked_at"]
    # A revoked certificate is not returned again; the grading can get a new one.
    new = issue(client, g["grading_id"])
    assert new.status_code == 201 and new.json()["cert_no"] != no

    # Deleting the grading keeps its certificate, without the photo.
    assert client.delete(f"/gradings/{g['grading_id']}").status_code == 204
    p = raw_client.get(f"/public/v/{slug(new.json()['verify_url'])}").json()
    assert p["status"] == "valid" and p["image_url"] is None and p["snapshot"]["grade"] == g["grade"]
    for no_ in (no, new.json()["cert_no"]):
        assert not app_state.storage.exists(app_state.storage.certificate_key(no_, "jpg"))
    assert issue(client, g["grading_id"]).status_code == 404


@needs_stone
def test_other_users_get_404(client, client_b):
    g = graded(client)
    no = issue(client, g["grading_id"]).json()["cert_no"]
    assert issue(client_b, g["grading_id"]).status_code == 404
    assert client_b.get(f"/certificates/{no}").status_code == 404
    assert upload_pdf(client_b, no).status_code == 404
    assert client_b.post(f"/certificates/{no}/revoke", json={"reason": "x"}).status_code == 404
    assert no not in [i["cert_no"] for i in client_b.get("/certificates").json()["items"]]
    assert client.get(f"/certificates/{no}").json()["status"] == "valid"
    assert issue(client, "does-not-exist").status_code == 404


# ---- DELETE /me ----

def test_delete_me_requires_recent_auth(raw_client, monkeypatch):
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        monkeypatch.setattr(routers, "REAUTH_MAX_AGE_S", -1)    # every sign-in counts as old
        r = c.delete("/me")
        assert r.status_code == 401 and r.json()["code"] == "reauth_required"
        assert firebase_auth.get_user(u.uid).uid == u.uid


@needs_stone
def test_delete_me_removes_everything(raw_client, app_state):
    db, st = app_state.db, app_state.storage
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        c.post("/calibrations", json=calibration("cal-cert"))
        g = graded(c)
        grade(c, tray_jpeg())
        c.post("/feedback", json={"rating": 4, "category": "app"})
        cert = issue(c, g["grading_id"]).json()
        assert upload_pdf(c, cert["cert_no"]).status_code == 201
        pdf_key = st.certificate_key(cert["cert_no"])
        for coll in ("gradings", "calibrations", "rejections", "feedback", "certificates"):
            assert getattr(db, coll).count_documents({"uid": u.uid}) >= 1, coll
        assert s3_keys(st, u.uid) and st.exists(pdf_key)

        r = c.delete("/me")
        assert r.status_code == 204, r.text
        for coll in ("gradings", "calibrations", "rejections", "feedback", "certificates"):
            assert getattr(db, coll).count_documents({"uid": u.uid}) == 0, coll
        assert db.users.find_one({"_id": u.uid}) is None
        assert s3_keys(st, u.uid) == [] and not st.exists(pdf_key)
        assert not st.exists(st.certificate_key(cert["cert_no"], "jpg"))
        doc = db.certificates.find_one({"_id": cert["cert_no"]})
        assert doc["status"] == "withdrawn" and doc["revoked_reason"] == "Owner account deleted"
        assert set(doc) <= {"_id", "issued_at", "status", "revoked_reason", "withdrawn_at",
                            "token_sha256"}
        p = raw_client.get(f"/public/v/{slug(cert['verify_url'])}")
        assert p.status_code == 200 and p.json()["status"] == "withdrawn"
        assert p.json()["snapshot"] is None and p.json()["image_url"] is None
        with pytest.raises(firebase_auth.UserNotFoundError):
            firebase_auth.get_user(u.uid)
        uid_hash = hashlib.sha256(u.uid.encode()).hexdigest()
        log = db.audit_log.find_one({"uid_hash": uid_hash})
        assert log["action"] == "account_deleted" and log["at"]
        assert u.uid not in str(log)


# ---- Remote config, maintenance, feedback ----

def test_config_defaults(raw_client, app_state):
    app_state.db.invalidate_app_config()
    r = raw_client.get("/config")
    assert r.status_code == 200 and r.json() == DEFAULT_APP_CONFIG


def test_maintenance_blocks_grade(client, app_state):
    db = app_state.db
    db.app_config.update_one({"_id": "global"}, {"$set": {
        "maintenance": {"enabled": True, "message": "Back at 10:00"}}})
    db.invalidate_app_config()
    try:
        r = grade(client, tray_jpeg())
        assert r.status_code == 503
        assert r.json()["code"] == "maintenance" and r.json()["message"] == "Back at 10:00"
        assert client.raw.get("/config").json()["maintenance"]["enabled"] is True
    finally:
        db.app_config.update_one({"_id": "global"}, {"$set": {
            "maintenance": DEFAULT_APP_CONFIG["maintenance"]}})
        db.invalidate_app_config()
    assert grade(client, tray_jpeg()).status_code == 200


def test_feedback_validation(client, app_state, user_a):
    ok = {"rating": 5, "category": "accuracy", "comment": " Great ", "app_version": "1.0.0+1"}
    r = client.post("/feedback", json=ok)
    assert r.status_code == 201, r.text
    doc = app_state.db.feedback.find_one({"_id": r.json()["feedback_id"]})
    assert doc["uid"] == user_a.uid and doc["rating"] == 5 and doc["comment"] == "Great"
    assert client.post("/feedback", json={"rating": 3, "category": "other"}).status_code == 201
    for bad in ({**ok, "rating": 0}, {**ok, "rating": 6}, {**ok, "category": "billing"},
                {**ok, "comment": "x" * 501}, {**ok, "app_version": "x" * 51},
                {"category": "app"}):
        assert client.post("/feedback", json=bad).status_code == 400, bad


# ---- Concurrent save failures ----

@needs_stone
def test_grade_save_failure_cleans_up(client, app_state, monkeypatch):
    db, st = app_state.db, app_state.storage
    before = set(s3_keys(st, client.user.uid))
    n = db.gradings.count_documents({"uid": client.user.uid})

    def boom(*a, **k):
        raise RuntimeError("simulated")

    monkeypatch.setattr(db, "next_seq", boom)           # MongoDB side fails
    r = grade(client)
    assert r.status_code == 500 and "grading_id" not in r.json()
    monkeypatch.undo()
    assert set(s3_keys(st, client.user.uid)) == before
    monkeypatch.setattr(st, "put", boom)                 # S3 side fails
    assert grade(client).status_code == 500
    monkeypatch.undo()
    assert db.gradings.count_documents({"uid": client.user.uid}) == n
