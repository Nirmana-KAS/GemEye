"""Phase N1: server-backed notifications, user clear and admin restore. Run with ENV=test
(see conftest.py). Test users are temporary Firebase users; data lives in gemeye_test only."""
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from firebase_admin import auth as firebase_auth

from app import admin, notifications
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser
from tests.test_admin_writes import audited, cert, n_audit, with_role


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


@pytest.fixture()
def fresh(raw_client):
    """A new user per test, so lists start empty."""
    with FirebaseTestUser() as u:
        yield AuthedClient(raw_client, u)


def item(i=None, minutes_ago=0, **kw):
    t = datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)
    return {"id": i or str(uuid.uuid4()), "type": "info", "category": "referral", "title": "T",
            "message": "M", "action": "openResult", "payload": "GE-STONE-00001",
            "created_at": t.isoformat(), **kw}


def ids(c, **params):
    r = c.get("/me/notifications", params=params)
    assert r.status_code == 200
    return [x["id"] for x in r.json()["items"]]


def test_sync_idempotent_and_validated(fresh, app_state):
    db = app_state.db
    a, b = item(minutes_ago=2), item(minutes_ago=1, read=True)
    r = fresh.post("/me/notifications/sync", json={"items": [a, b]})
    assert r.status_code == 200 and r.json()["accepted"] == [a["id"], b["id"]]
    assert fresh.post("/me/notifications/sync", json={"items": [{**a, "title": "Changed"}]}).json()[
        "accepted"] == [a["id"]]
    assert db.notifications.count_documents({"uid": fresh.user.uid}) == 2
    doc = db.notifications.find_one({"_id": a["id"]})
    assert doc["title"] == "T" and doc["source"] == "app" and doc["cleared_at"] is None
    body = fresh.get("/me/notifications").json()
    assert [x["id"] for x in body["items"]] == [b["id"], a["id"]] and body["unread_count"] == 1
    assert body["items"][0]["read"] is True and body["items"][1]["category"] == "referral"

    # A re-sync of a cleared item does not bring it back.
    assert fresh.post(f"/me/notifications/{a['id']}/clear").status_code == 200
    fresh.post("/me/notifications/sync", json={"items": [a]})
    assert db.notifications.find_one({"_id": a["id"]})["cleared_at"] is not None
    assert ids(fresh) == [b["id"]]

    for bad in ({**a, "title": "x" * 121}, {**a, "message": "x" * 1001}, {**a, "payload": "x" * 201},
                {**a, "type": "fatal"}, {**a, "category": "other"}, {**a, "id": "bad id!"}):
        assert fresh.post("/me/notifications/sync", json={"items": [bad]}).status_code == 400
    assert fresh.post("/me/notifications/sync",
                      json={"items": [item() for _ in range(51)]}).status_code == 400
    assert fresh.post("/me/notifications/sync", json={"items": []}).status_code == 400


def test_clear_read_and_paging(fresh, app_state):
    items = [item(minutes_ago=10 - n) for n in range(5)]
    fresh.post("/me/notifications/sync", json={"items": items})
    newest = [i["id"] for i in reversed(items)]
    page = fresh.get("/me/notifications", params={"limit": 2}).json()
    assert [x["id"] for x in page["items"]] == newest[:2] and page["next_cursor"]
    page2 = fresh.get("/me/notifications", params={"limit": 2, "cursor": page["next_cursor"]}).json()
    assert [x["id"] for x in page2["items"]] == newest[2:4]
    assert fresh.get("/me/notifications", params={"cursor": "!!"}).status_code == 400

    assert fresh.post(f"/me/notifications/{newest[0]}/read").status_code == 200
    assert fresh.get("/me/notifications").json()["unread_count"] == 4
    assert fresh.post(f"/me/notifications/{newest[0]}/clear").json() == {"id": newest[0], "cleared": True}
    assert fresh.post(f"/me/notifications/{newest[0]}/clear").status_code == 200   # idempotent
    assert ids(fresh) == newest[1:]
    assert app_state.db.notifications.find_one({"_id": newest[0]}) is not None  # never deleted

    # read-all/clear-all with `before` leave newer notifications alone.
    cut = (datetime.now(timezone.utc) - timedelta(minutes=7, seconds=30)).isoformat()
    assert fresh.post("/me/notifications/read-all", params={"before": cut}).json()["updated"] == 3
    assert fresh.post("/me/notifications/clear-all", params={"before": cut}).json()["cleared"] == 3
    assert ids(fresh) == [newest[1]]
    assert fresh.post("/me/notifications/clear-all").json()["cleared"] == 1
    body = fresh.get("/me/notifications").json()
    assert body["items"] == [] and body["unread_count"] == 0
    assert app_state.db.notifications.count_documents({"uid": fresh.user.uid}) == 5


def test_other_users_id_is_404(fresh, client_b, app_state):
    a = item()
    fresh.post("/me/notifications/sync", json={"items": [a]})
    for path in (f"/me/notifications/{a['id']}/read", f"/me/notifications/{a['id']}/clear"):
        assert client_b.post(path).status_code == 404
    # Another user cannot claim the same id through sync either.
    assert client_b.post("/me/notifications/sync", json={"items": [a]}).json()["accepted"] == []
    assert a["id"] not in ids(client_b)
    d = app_state.db.notifications.find_one({"_id": a["id"]})
    assert d["uid"] == fresh.user.uid and d["read_at"] is None and d["cleared_at"] is None


def test_auth_required(raw_client):
    assert raw_client.get("/me/notifications").status_code == 401
    assert raw_client.post("/me/notifications/clear-all").status_code == 401


def test_admin_sees_cleared_and_restores(fresh, admin_c, app_state):
    db, uid = app_state.db, fresh.user.uid
    items = [item(minutes_ago=5 - n) for n in range(4)]
    fresh.post("/me/notifications/sync", json={"items": items})
    a, b, c, d = (i["id"] for i in items)
    fresh.post(f"/me/notifications/{a}/clear")
    fresh.post(f"/me/notifications/{b}/clear")

    base = f"/admin/users/{uid}/notifications"
    body = admin_c.get(base).json()
    assert {x["id"] for x in body["items"]} == {a, b, c, d}
    assert body["counts"] == {"visible": 2, "cleared": 2}
    cleared = admin_c.get(base, params={"status": "cleared"}).json()["items"]
    assert {x["id"] for x in cleared} == {a, b} and all(x["cleared_at"] for x in cleared)
    assert {x["id"] for x in admin_c.get(base, params={"status": "visible"}).json()["items"]} == {c, d}
    assert admin_c.get(base, params={"status": "gone"}).status_code == 400

    n0 = n_audit(db, "notification_restore")
    r = admin_c.post(f"{base}/{a}/restore")
    assert r.status_code == 200
    e = audited(db, "notification_restore", n0)
    assert e["target"] == {"uid": uid, "notification": a} and e["after"] == {"cleared_at": None}
    assert a in ids(fresh)
    row = [x for x in admin_c.get(base).json()["items"] if x["id"] == a][0]
    assert row["restored_at"] and row["cleared_at"] is None
    assert row["restored_by_email"] == firebase_auth.get_user(admin_c.user.uid).email
    assert admin_c.post(f"{base}/{a}/restore").status_code == 409
    assert admin_c.post(f"{base}/no-such-id-123/restore").status_code == 404
    assert admin_c.post(f"/admin/users/someone-else/notifications/{b}/restore").status_code == 404

    fresh.post("/me/notifications/clear-all")
    n1 = n_audit(db, "notification_restore_all")
    r = admin_c.post(f"{base}/restore-all")
    assert r.status_code == 200 and r.json() == {"restored": 4}
    e = audited(db, "notification_restore_all", n1)
    assert e["after"] == {"restored": 4}
    assert set(ids(fresh)) == {a, b, c, d}


def test_reviewer_and_user_get_403(fresh, reviewer_c, client):
    base = f"/admin/users/{fresh.user.uid}/notifications"
    for c in (reviewer_c, client):
        assert c.get(base).status_code == 403
        assert c.post(f"{base}/restore-all").status_code == 403
        assert c.post(f"{base}/x-12345678/restore").status_code == 403


def test_server_notifications(admin_c, app_state):
    db = app_state.db
    with FirebaseTestUser() as u:
        uc = AuthedClient(admin_c.raw, u)
        certs = ["GE-209903-00001", "GE-209903-00002"]
        db.certificates.insert_many([cert(c, f"tokn{n}", u.uid, f"n1-g{n}") for n, c in enumerate(certs)])
        try:
            assert admin_c.post(f"/admin/users/{u.uid}/role", json={"role": "reviewer"}).status_code == 200
            assert admin_c.post(f"/admin/certificates/{certs[0]}/supersede",
                                json={"new_cert_no": certs[1], "reason": "Re-graded"}).status_code == 200
            assert admin_c.post(f"/admin/certificates/{certs[1]}/revoke",
                                json={"reason": "Wrong stone"}).status_code == 200
        finally:
            db.certificates.delete_many({"_id": {"$in": certs}})
        docs = list(db.notifications.find({"uid": u.uid}).sort("created_at", 1))
        assert [d["title"] for d in docs] == ["Account role updated", "Certificate replaced",
                                              "Certificate revoked"]
        assert all(d["source"] == "server" for d in docs)
        assert docs[1]["category"] == docs[2]["category"] == "certificate"
        assert "Wrong stone" in docs[2]["message"] and docs[2]["payload"] == certs[1]
        assert len(ids(uc)) == 3
        firebase_auth.set_custom_user_claims(u.uid, None)


def test_delete_account_removes_notifications(admin_c, app_state):
    db = app_state.db
    with FirebaseTestUser() as u:
        uc = AuthedClient(admin_c.raw, u)
        a = item()
        uc.post("/me/notifications/sync", json={"items": [a, item()]})
        uc.post(f"/me/notifications/{a['id']}/clear")
        assert db.notifications.count_documents({"uid": u.uid}) == 2
        assert admin_c.delete(f"/admin/users/{u.uid}").status_code == 204
        assert db.notifications.count_documents({"uid": u.uid}) == 0
