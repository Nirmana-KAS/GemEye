"""Phase 10a: admin roles and the admin read API. Run with ENV=test (see conftest.py).
Test users are temporary Firebase users; inserted data lives in gemeye_test only."""
import json
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from firebase_admin import auth as firebase_auth

from app import admin
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser

ROUTES = ["/admin/stats/summary", "/admin/stats/timeseries?metric=gradings",
          "/admin/users", "/admin/gradings", "/admin/calibrations", "/admin/feedback",
          "/admin/certificates", "/admin/audit-log", "/admin/model/monitoring"]
FORBIDDEN_KEYS = {"token", "token_sha256", "image_key", "pdf_key", "verify_url", "password",
                  "secret", "api_key"}
MARK = "adm-test-" + uuid.uuid4().hex[:8]


@pytest.fixture(autouse=True)
def _reset():
    admin.reset_rate_limit()
    yield
    admin.reset_rate_limit()


def with_role(role):
    u = FirebaseTestUser()
    firebase_auth.set_custom_user_claims(u.uid, {role: True})
    u._token = None     # sign in again to get the claim
    return u


@pytest.fixture(scope="module")
def admin_c(raw_client):
    with with_role("admin") as u:
        yield AuthedClient(raw_client, u)


@pytest.fixture(scope="module")
def reviewer_c(raw_client):
    with with_role("reviewer") as u:
        yield AuthedClient(raw_client, u)


@pytest.fixture(scope="module")
def seeded(raw_client, app_state, client):
    """Known rows for one fake user (and one real user doc), removed at the end."""
    db = app_state.db
    now = datetime.now(timezone.utc)
    uid = MARK + "-user"
    db.users.insert_one({"_id": uid, "email": f"{MARK}@example.com", "display_name": "Adm Tester",
                         "phone": "+94000000", "created_at": now, "settings": {}})
    ids = []
    for i, (grade, conf, referred, model) in enumerate(
            [(3, 0.9, False, "v3"), (4, 0.5, True, "v3"), (4, 0.7, False, "v9")]):
        gid = f"{MARK}-g{i}"
        ids.append(gid)
        db.gradings.insert_one({
            "_id": gid, "uid": uid, "stone_id": f"GE-STONE-9{i}", "created_at": now - timedelta(seconds=i),
            "status": "ok", "deleted": False, "device": f"{MARK}-phone",
            "image_key": f"gradings/{uid}/{gid}.jpg",
            "result": {"status": "ok", "grade": grade, "grade_name": "X", "confidence": conf,
                       "uncertainty": 0.1 * (i + 1), "referred": referred, "model_version": model,
                       "warnings": ["unusual_image"] if i == 1 else [],
                       "timings_ms": {"total": 100.0 * (i + 1)}}})
    db.rejections.insert_many([
        {"_id": f"{MARK}-r{i}", "uid": uid, "created_at": now, "status": s, "diagnostics": {}}
        for i, s in enumerate(["blurry", "no_stone"])])
    db.calibrations.insert_one({"_id": f"{MARK}-c", "uid": uid, "session_id": MARK, "created_at": now,
                                "device": f"{MARK}-phone", "quality": "good", "residual": 1.0})
    db.feedback.insert_one({"_id": f"{MARK}-f", "uid": uid, "created_at": now, "rating": 2,
                            "category": "app", "comment": "hello", "app_version": "1.0"})
    db.certificates.insert_one({"_id": "GE-209901-99999", "uid": uid, "grading_id": ids[0],
                                "token": "SECRETTOKEN123", "token_sha256": "abc", "status": "valid",
                                "issued_at": now, "image_key": "certs/x.jpg", "pdf_key": "certs/x.pdf",
                                "snapshot": {"grade": 3}})
    yield {"uid": uid, "ids": ids}
    for coll in ("gradings", "rejections", "calibrations", "feedback", "certificates", "users"):
        getattr(db, coll).delete_many({"_id": {"$regex": f"^({MARK}|GE-209901)"}})


def scan(obj):
    """No secret keys or values anywhere in a response."""
    text = json.dumps(obj)
    assert "SECRETTOKEN123" not in text and "certs/x.p" not in text
    stack = [obj]
    while stack:
        o = stack.pop()
        if isinstance(o, dict):
            assert not FORBIDDEN_KEYS & {k.lower() for k in o}
            stack.extend(o.values())
        elif isinstance(o, list):
            stack.extend(o)


# ---- Access control ----

@pytest.mark.parametrize("url", ROUTES)
def test_no_token_401(raw_client, url):
    r = raw_client.get(url)
    assert r.status_code == 401 and r.json()["detail"] == "Authentication required."


@pytest.mark.parametrize("url", ROUTES)
def test_normal_user_403(client, reviewer_c, url):
    r = client.get(url)
    assert r.status_code == 403 and r.json()["code"] == "forbidden"
    if not url.startswith("/admin/gradings"):
        r = reviewer_c.get(url)
        assert r.status_code == 403 and r.json()["code"] == "forbidden"


def test_normal_user_cannot_read_grading_detail(client, seeded):
    assert client.get(f"/admin/gradings/{seeded['ids'][0]}").status_code == 403


def test_admin_reads_every_route(admin_c, seeded):
    for url in ROUTES + [f"/admin/users/{seeded['uid']}", f"/admin/gradings/{seeded['ids'][0]}"]:
        r = admin_c.get(url)
        assert r.status_code == 200, (url, r.text)
        scan(r.json())


def test_reviewer_limited_fields(admin_c, reviewer_c, seeded):
    q = f"?uid={seeded['uid']}"
    a = admin_c.get("/admin/gradings" + q).json()["items"]
    r = reviewer_c.get("/admin/gradings" + q)
    assert r.status_code == 200
    items = r.json()["items"]
    assert len(items) == 3 and all("user_email" not in i for i in items)
    assert all(i["user_email"] == f"{MARK}@example.com" for i in a)
    d = reviewer_c.get(f"/admin/gradings/{seeded['ids'][0]}").json()
    assert "user_email" not in d and "+94000000" not in json.dumps(d) and "@" not in json.dumps(d)
    assert d["certificate"]["cert_no"] == "GE-209901-99999"
    scan(d)


# ---- Data ----

def test_summary_matches_inserted_data(admin_c, seeded, app_state):
    s = admin_c.get("/admin/stats/summary?days=1").json()
    db = app_state.db
    since = datetime.now(timezone.utc) - timedelta(days=1)
    gr = list(db.gradings.find({"created_at": {"$gte": since}}))
    rj = db.rejections.count_documents({"created_at": {"$gte": since}})
    assert s["gradings"] == len(gr) and s["rejections"] == rj
    assert s["referred"] == sum(1 for g in gr if g["result"]["referred"])
    assert s["rejections_by_status"]["blurry"] >= 1 and s["rejections_by_status"]["no_stone"] >= 1
    conf = sum(g["result"]["confidence"] for g in gr) / len(gr)
    assert s["avg_confidence"] == pytest.approx(conf, abs=1e-3)
    lat = sum(g["result"]["timings_ms"]["total"] for g in gr if "timings_ms" in g["result"])
    n_lat = sum(1 for g in gr if "timings_ms" in g["result"])
    assert s["avg_latency_ms"] == pytest.approx(lat / n_lat, abs=1e-2)
    assert s["unique_users"] >= 1 and s["certificates_issued"] >= 1 and s["feedback_count"] >= 1
    assert s["database"]["status"] == "ok" and s["server"]["models_loaded"] is True
    assert admin_c.get("/admin/stats/summary?days=5").status_code == 400


def test_timeseries(admin_c, seeded):
    r = admin_c.get("/admin/stats/timeseries?metric=gradings&days=7").json()
    assert len(r["points"]) == 7 and r["points"][-1]["value"] >= 3
    for m in ("rejections", "referral_rate", "avg_confidence"):
        assert len(admin_c.get(f"/admin/stats/timeseries?metric={m}&days=3").json()["points"]) == 3
    assert admin_c.get("/admin/stats/timeseries?metric=nope").status_code == 400


def test_gradings_filters_and_paging(admin_c, seeded):
    base = f"/admin/gradings?uid={seeded['uid']}"
    assert len(admin_c.get(base + "&grade=4").json()["items"]) == 2
    assert len(admin_c.get(base + "&referred=true").json()["items"]) == 1
    assert len(admin_c.get(base + "&model_version=v9").json()["items"]) == 1
    assert len(admin_c.get(base + f"&device={MARK}-PHONE").json()["items"]) == 3
    assert len(admin_c.get(base + "&status=ok").json()["items"]) == 3
    assert admin_c.get(base + "&status=zzz").json()["items"] == []
    future = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat().replace("+00:00", "Z")
    assert admin_c.get(base + f"&from={future}").json()["items"] == []
    seen, cursor = [], None
    while True:
        r = admin_c.get(base + "&limit=2" + (f"&cursor={cursor}" if cursor else "")).json()
        seen += [i["grading_id"] for i in r["items"]]
        cursor = r["next_cursor"]
        if not cursor:
            break
    assert seen == seeded["ids"]
    assert admin_c.get(base + "&cursor=@@").status_code == 400


def test_users(admin_c, seeded):
    r = admin_c.get(f"/admin/users?q={MARK.upper()}").json()
    assert [u["uid"] for u in r["items"]] == [seeded["uid"]]
    assert len(admin_c.get("/admin/users?limit=1&sort=last_active").json()["items"]) == 1
    d = admin_c.get(f"/admin/users/{seeded['uid']}").json()
    assert d["counts"]["gradings"] == 3 and d["counts"]["rejections"] == 2
    assert len(d["last_gradings"]) == 3 and d["devices"] == [f"{MARK}-phone"]
    assert d["disabled"] is None and d["profile"]["phone"] == "+94000000"
    assert admin_c.get("/admin/users/nope-" + MARK).status_code == 404


def test_other_lists(admin_c, seeded):
    u = seeded["uid"]
    assert len(admin_c.get(f"/admin/calibrations?uid={u}&quality=good").json()["items"]) == 1
    assert admin_c.get(f"/admin/calibrations?uid={u}&quality=bad").json()["items"] == []
    assert len(admin_c.get(f"/admin/feedback?rating=2&uid={u}").json()["items"]) == 1
    assert admin_c.get(f"/admin/feedback?rating=3&uid={u}").json()["items"] == []
    assert [c["cert_no"] for c in admin_c.get("/admin/certificates?q=ge-209901").json()["items"]] \
        == ["GE-209901-99999"]
    assert admin_c.get("/admin/certificates?status=revoked&q=GE-209901").json()["items"] == []


def test_audit_log(admin_c, app_state):
    admin.audit(app_state.db, "test_action", "some-admin-uid", {"id": MARK}, {"a": 1}, {"a": 2})
    items = admin_c.get("/admin/audit-log?action=test_action").json()["items"]
    assert items and items[0]["target"] == {"id": MARK}
    assert "some-admin-uid" not in json.dumps(items) and len(items[0]["uid_hash"]) == 64
    app_state.db.audit_log.delete_many({"action": "test_action"})


def test_monitoring(admin_c, seeded):
    m = admin_c.get("/admin/model/monitoring?days=7").json()
    by_v = {v["model_version"]: v["days"] for v in m["versions"]}
    assert {"v3", "v9"} <= set(by_v)
    today = by_v["v9"][-1]
    assert today["count"] >= 1 and today["mean_latency_ms"] is not None
    assert sum(d["unusual_image"] for d in by_v["v3"]) >= 1
    gates = {g["gate"] for g in m["rejections_by_gate"]}
    assert {"blurry", "no_stone"} <= gates


def test_cors_admin_only(raw_client):
    ok = raw_client.options("/admin/users", headers={
        "Origin": "http://localhost:3000", "Access-Control-Request-Method": "GET"})
    assert ok.status_code == 204 and ok.headers["access-control-allow-origin"] == "http://localhost:3000"
    bad = raw_client.options("/admin/users", headers={"Origin": "https://evil.example"})
    assert bad.status_code == 403 and "access-control-allow-origin" not in bad.headers
    other = raw_client.get("/config", headers={"Origin": "http://localhost:3000"})
    assert "access-control-allow-origin" not in other.headers


@pytest.mark.parametrize("path", ["/health", "/announcements"])
def test_cors_dashboard_public_paths(raw_client, path):
    origin = "http://localhost:3000"
    pre = raw_client.options(path, headers={"Origin": origin, "Access-Control-Request-Method": "GET"})
    assert pre.status_code == 204 and pre.headers["access-control-allow-origin"] == origin
    got = raw_client.get(path, headers={"Origin": origin})
    assert got.status_code == 200 and got.headers["access-control-allow-origin"] == origin
    assert "no-store" not in got.headers.get("cache-control", "")
    evil = raw_client.get(path, headers={"Origin": "https://evil.example"})
    assert "access-control-allow-origin" not in evil.headers


def test_summary_grade_distribution(admin_c, seeded):
    dist = admin_c.get("/admin/stats/summary?days=1").json()["grade_distribution"]
    assert list(dist) == [str(g) for g in range(1, 8)]
    assert dist["3"] >= 1 and dist["4"] >= 2


def test_users_role_and_disabled(admin_c, seeded):
    assert admin_c.get("/me").status_code == 200     # creates the admin's users doc
    rows = admin_c.get("/admin/users?limit=100").json()["items"]
    assert all("role" in r and "disabled" in r for r in rows)
    admins = admin_c.get("/admin/users?role=admin&limit=100").json()["items"]
    assert admins and all(r["role"] == "admin" for r in admins)
    enabled = admin_c.get("/admin/users?disabled=false&limit=100").json()["items"]
    assert all(r["disabled"] is False for r in enabled)
    assert admin_c.get("/admin/users?role=owner").status_code == 400


def test_rate_limit(admin_c, monkeypatch):
    monkeypatch.setattr(admin, "RATE_LIMIT", 3)
    codes = [admin_c.get("/admin/audit-log").status_code for _ in range(5)]
    assert codes == [200, 200, 200, 429, 429]


def test_detail_role_and_review_fields(admin_c, seeded):
    me = admin_c.get("/me").json()["uid"]
    assert admin_c.get(f"/admin/users/{me}").json()["role"] == "admin"
    g = admin_c.get(f"/admin/gradings/{seeded['ids'][0]}").json()
    assert "review" in g and g["review"] is None
