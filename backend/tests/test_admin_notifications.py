"""Phase 10f: admin send notifications, broadcasts, all-users notification list, and the
read filters the dashboard pages use (feedback status, certificate email, audit admin/target,
config update_message, announcement action). Run with ENV=test (see conftest.py)."""
import uuid
from datetime import datetime, timedelta, timezone

import pytest

from app import admin, notifications
from app.auth import uid_hash
from tests.conftest import AuthedClient
from tests.test_admin_writes import audited, cert, n_audit, with_role

MARK = "adn-" + uuid.uuid4().hex[:8]


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
def people(app_state):
    """Two live users and one deleted user (profile left behind, tombstone set)."""
    db, now = app_state.db, datetime.now(timezone.utc)
    live = [f"{MARK}-u{i}" for i in range(2)]
    dead = f"{MARK}-dead"
    db.users.insert_many([{"_id": u, "email": f"{u}@example.com", "created_at": now, "settings": {}}
                          for u in live + [dead]])
    db.deleted_accounts.insert_one({"_id": uid_hash(dead), "deleted_at": now})
    yield {"live": live, "dead": dead}
    db.users.delete_many({"_id": {"$regex": f"^{MARK}"}})
    db.deleted_accounts.delete_one({"_id": uid_hash(dead)})
    db.notifications.delete_many({"source": "admin"})
    db.admin_broadcasts.delete_many({})
    db.feedback.delete_many({"_id": {"$regex": f"^{MARK}"}})
    db.certificates.delete_many({"_id": {"$regex": "^GE-209903"}})


def send(c, **kw):
    return c.post("/admin/notifications/send", json={"title": f"{MARK} hello", "message": "Body", **kw})


def test_send_to_user(admin_c, people, app_state):
    db, uid = app_state.db, people["live"][0]
    n0 = n_audit(db, "notification_send")
    r = send(admin_c, target="user", uid=uid, type="warning", category="certificate",
             action="openHistory", payload="GE-STONE-00001")
    assert r.status_code == 201, r.text
    body = r.json()
    assert body["count"] == 1 and body["target"] == "user"
    doc = db.notifications.find_one({"uid": uid, "broadcast_id": body["id"]})
    assert doc["source"] == "admin" and doc["sent_by"] == admin_c.user.uid
    assert doc["type"] == "warning" and doc["action"] == "openHistory" and doc["cleared_at"] is None
    e = audited(db, "notification_send", n0)
    assert e["target"] == {"broadcast": body["id"], "uid": uid} and e["after"]["count"] == 1
    assert db.admin_broadcasts.find_one({"_id": body["id"]})["sent_by"] == admin_c.user.uid
    # Unknown or deleted users are 404 and nothing is stored.
    assert send(admin_c, target="user", uid=f"{MARK}-nobody").status_code == 404
    assert send(admin_c, target="user", uid=people["dead"]).status_code == 404
    assert n_audit(db, "notification_send") == n0 + 1

    # All-users list: filter by uid/source/status, with the user's and sender's email.
    items = admin_c.get("/admin/notifications", params={"uid": uid, "source": "admin"}).json()["items"]
    assert [i["id"] for i in items] == [doc["_id"]]
    assert items[0]["user_email"] == f"{uid}@example.com"
    assert items[0]["sent_by_email"] == admin_c.user.email
    assert admin_c.get("/admin/notifications", params={"uid": uid, "status": "read"}).json()["items"] == []
    assert len(admin_c.get("/admin/notifications", params={"uid": uid, "status": "unread"}).json()["items"]) == 1
    assert admin_c.get("/admin/notifications", params={"status": "bogus"}).status_code == 400
    hist = admin_c.get("/admin/broadcasts", params={"target": "user"}).json()["items"]
    assert hist[0]["id"] == body["id"] and hist[0]["user_email"] == f"{uid}@example.com"
    assert hist[0]["sent_by_email"] == admin_c.user.email


def test_send_to_all_skips_deleted(admin_c, people, app_state):
    db = app_state.db
    db.admin_broadcasts.delete_many({"target": "all"})
    audience = admin_c.get("/admin/notifications/audience").json()["users"]
    expected = len(notifications.recipients(db))
    assert audience == expected and audience >= 2
    r = send(admin_c, target="all", type="info")
    assert r.status_code == 201, r.text
    bid, count = r.json()["id"], r.json()["count"]
    assert count == expected == db.notifications.count_documents({"broadcast_id": bid})
    for uid in people["live"]:
        assert db.notifications.count_documents({"uid": uid, "broadcast_id": bid}) == 1
    assert db.notifications.count_documents({"uid": people["dead"], "broadcast_id": bid}) == 0
    assert db.admin_broadcasts.find_one({"_id": bid})["count"] == count


def test_send_validation(admin_c, people, app_state):
    db, uid = app_state.db, people["live"][1]
    n0 = n_audit(db, "notification_send")
    for bad in ({"target": "user"}, {"target": "all", "uid": uid}, {"target": "everyone"},
                {"target": "user", "uid": uid, "title": "x" * 121},
                {"target": "user", "uid": uid, "title": "   "},
                {"target": "user", "uid": uid, "message": "m" * 1001},
                {"target": "user", "uid": uid, "message": ""},
                {"target": "user", "uid": uid, "type": "fatal"},
                {"target": "user", "uid": uid, "category": "other"},
                {"target": "user", "uid": uid, "action": "openSettings"},
                {"target": "user", "uid": uid, "payload": "p" * 201},
                {"target": "user", "uid": uid, "extra": 1}):
        assert send(admin_c, **bad).status_code == 400, bad
    assert n_audit(db, "notification_send") == n0
    # /admin/* validation errors name the field (never the submitted value).
    r = send(admin_c, target="user", uid=uid, title="x" * 121)
    assert [f["field"] for f in r.json()["fields"]] == ["title"] and "xxxx" not in r.text
    r = admin_c.put("/admin/config", json={"gates": {"hue_min": 300}})
    assert r.status_code == 400 and r.json()["fields"][0]["field"] == "gates.hue_min"
    r = admin_c.put("/admin/config", json={"gates": {"ood_warn": 50, "ood_reject": 40}})
    assert r.status_code == 400 and r.json()["code"] == "invalid_gates"


def test_send_all_rate_limit(admin_c, people, app_state):
    db = app_state.db
    db.admin_broadcasts.delete_many({"target": "all"})
    for _ in range(notifications.BROADCAST_ALL_PER_HOUR):
        assert send(admin_c, target="all").status_code == 201
    r = send(admin_c, target="all")
    assert r.status_code == 429 and r.json()["code"] == "rate_limited"
    # Sends to one user are not limited by it; older sends no longer count.
    assert send(admin_c, target="user", uid=people["live"][0]).status_code == 201
    db.admin_broadcasts.update_many({"target": "all"},
                                    {"$set": {"at": datetime.now(timezone.utc) - timedelta(hours=2)}})
    assert send(admin_c, target="all").status_code == 201


def test_reviewer_forbidden(reviewer_c, client, people):
    for c in (reviewer_c, client):
        assert send(c, target="user", uid=people["live"][0]).status_code == 403
        for path in ("/admin/notifications", "/admin/broadcasts", "/admin/notifications/audience"):
            assert c.get(path).status_code == 403


def test_page_filters(admin_c, raw_client, people, app_state):
    db, uid, now = app_state.db, people["live"][0], datetime.now(timezone.utc)
    # Feedback: status filter (missing status = open) and user email.
    db.feedback.insert_many([
        {"_id": f"{MARK}-f1", "uid": uid, "created_at": now, "rating": 4, "category": "app"},
        {"_id": f"{MARK}-f2", "uid": uid, "created_at": now, "rating": 1, "category": "app",
         "status": "resolved"}])
    rows = admin_c.get("/admin/feedback", params={"uid": uid, "status": "open"}).json()["items"]
    assert [r["feedback_id"] for r in rows] == [f"{MARK}-f1"] and rows[0]["user_email"] == f"{uid}@example.com"
    rows = admin_c.get("/admin/feedback", params={"uid": uid, "status": "resolved"}).json()["items"]
    assert [r["feedback_id"] for r in rows] == [f"{MARK}-f2"]
    assert admin_c.get("/admin/feedback", params={"status": "closed"}).status_code == 400

    # Certificates: owner email search, superseded vs revoked, masked verify link.
    db.certificates.insert_many([cert("GE-209903-00001", "tokA1", uid, f"{MARK}-g1"),
                                 cert("GE-209903-00002", "tokB2", uid, f"{MARK}-g2")])
    r = admin_c.post("/admin/certificates/GE-209903-00001/supersede",
                     json={"new_cert_no": "GE-209903-00002", "reason": "Re-graded"})
    assert r.status_code == 200
    by_email = admin_c.get("/admin/certificates", params={"email": f"{MARK}-u0@"}).json()["items"]
    assert {c["cert_no"] for c in by_email} == {"GE-209903-00001", "GE-209903-00002"}
    assert all(c["user_email"] == f"{uid}@example.com" for c in by_email)
    sup = admin_c.get("/admin/certificates", params={"q": "GE-209903", "status": "superseded"}).json()["items"]
    assert [c["cert_no"] for c in sup] == ["GE-209903-00001"]
    assert admin_c.get("/admin/certificates", params={"q": "GE-209903", "status": "revoked"}).json()["items"] == []
    detail = admin_c.get("/admin/certificates/GE-209903-00002").json()
    assert detail["verify_url_masked"].endswith("/v/GE-209903-00002-...") and "tokB2" not in str(detail)
    assert detail["user_email"] == f"{uid}@example.com"

    # Audit log: admin email and target filters.
    rows = admin_c.get("/admin/audit-log", params={"target": "GE-209903-00001"}).json()["items"]
    assert [r["action"] for r in rows] == ["certificate_supersede"]
    assert rows[0]["admin_email"] == admin_c.user.email
    mine = admin_c.get("/admin/audit-log", params={"admin": admin_c.user.email, "limit": 100}).json()["items"]
    assert mine and all(r["uid_hash"] == uid_hash(admin_c.user.uid) for r in mine)

    # Config: update_message is bounded and public; announcements keep their action.
    old = admin_c.get("/admin/config").json()
    assert old["bounds"]["calibration_validity_hours"] == {"min": 1, "max": 72}
    assert admin_c.put("/admin/config", json={"update_message": "u" * 201}).status_code == 400
    assert admin_c.put("/admin/config", json={"update_message": "Please update"}).status_code == 200
    db.invalidate_app_config()
    assert raw_client.get("/config").json()["update_message"] == "Please update"
    admin_c.put("/admin/config", json={"update_message": old["update_message"]})
    a = admin_c.post("/admin/announcements", json={
        "title": f"{MARK} a", "message": "m", "ends_at": (now + timedelta(hours=1)).isoformat(),
        "action": "openCapture"}).json()
    assert a["action"] == "openCapture"
    listed = [x for x in admin_c.get("/admin/announcements?limit=100").json()["items"] if x["id"] == a["id"]]
    assert listed[0]["created_by_email"] == admin_c.user.email
    pub = [x for x in raw_client.get("/announcements").json()["items"] if x["id"] == a["id"]]
    assert pub[0]["action"] == "openCapture"
    assert admin_c.post("/admin/announcements", json={
        "title": "t", "message": "m", "ends_at": (now + timedelta(hours=1)).isoformat(),
        "action": "openSettings"}).status_code == 400
    assert admin_c.delete(f"/admin/announcements/{a['id']}").status_code == 204
