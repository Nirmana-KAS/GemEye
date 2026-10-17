"""Phase 10b: admin write API, review queue, announcements, config editor. Run with ENV=test
(see conftest.py). Test users are temporary Firebase users; data lives in gemeye_test only."""
import csv
import hashlib
import io
import json
import uuid
from datetime import datetime, timedelta, timezone

import cv2
import numpy as np
import pytest
from firebase_admin import auth as firebase_auth

from app import admin, admin_write, certificates, gates
from app.auth import uid_hash
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser

MARK = "adw-" + uuid.uuid4().hex[:8]
GATE_DEFAULTS = {"blur_min_variance": 29.474166117400628, "no_stone_min_area": 0.5 * 0.0314306640625,
                 "no_stone_min_contrast_de00": 5.0, "hue_min": 170.0, "hue_max": 265.0,
                 "min_chroma": 0.5, "ood_warn": 20.648902893066406, "ood_reject": 25.68535614013672}
COLOUR = {"L": 1.0, "a": 1.0, "b": 1.0, "C": 1.0, "H": 1.0, "S": 1.0, "B": 1.0, "hex": "#000000",
          "ciecam02": None, "approximate": False}


@pytest.fixture(autouse=True)
def _reset():
    admin.reset_rate_limit()
    yield
    admin.reset_rate_limit()


def with_role(role):
    u = FirebaseTestUser()
    firebase_auth.set_custom_user_claims(u.uid, {role: True})
    u._token = None
    return u


@pytest.fixture(scope="module")
def admin_c(raw_client):
    with with_role("admin") as u:
        yield AuthedClient(raw_client, u)


@pytest.fixture(scope="module")
def reviewer_c(raw_client):
    with with_role("reviewer") as u:
        yield AuthedClient(raw_client, u)


def n_audit(db, action):
    return db.audit_log.count_documents({"action": action})


def audited(db, action, before_count):
    """Exactly one new audit entry with before/after, and no secrets in it."""
    assert n_audit(db, action) == before_count + 1, action
    e = db.audit_log.find_one({"action": action}, sort=[("at", -1)])
    assert len(e["uid_hash"]) == 64 and "before" in e and "after" in e
    text = json.dumps(e, default=str).lower()
    assert "oob" not in text and "token" not in text and "secret" not in text
    return e


def grading(gid, uid, grade, referred, version="v3", image=False):
    now = datetime.now(timezone.utc)
    return {"_id": gid, "uid": uid, "stone_id": "GE-STONE-" + gid[-5:], "created_at": now,
            "status": "ok", "deleted": False, "referral_threshold_used": 0.6,
            "image_key": f"gradings/{uid}/{gid}.jpg" if image else None,
            "result": {"status": "ok", "grade": grade, "grade_name": "X", "confidence": 0.55,
                       "uncertainty": 0.1, "referred": referred, "model_version": version,
                       "warnings": [], "timings_ms": {"total": 100.0}}}


def cert(cert_no, token, uid, gid):
    now = datetime.now(timezone.utc)
    return {"_id": cert_no, "uid": uid, "grading_id": gid, "token": token,
            "token_sha256": hashlib.sha256(token.encode()).hexdigest(), "status": "valid",
            "issued_at": now, "image_key": None, "pdf_key": None, "pdf_sha256": None,
            "snapshot": {"stone_id": "GE-STONE-1", "grade": 3, "grade_name": "Vivid",
                         "trade_name": "Royal Blue", "confidence": 0.9, "uncertainty": 0.1,
                         "referred": False, "colour": COLOUR, "delta_e00_to_typical": 1.0,
                         "model_version": "v3", "captured_at": now, "issued_at": now}}


@pytest.fixture(scope="module")
def fx(raw_client, app_state, client):
    db = app_state.db
    uid, own = MARK + "-user", client.user.uid
    db.users.insert_one({"_id": uid, "email": f"{MARK}@example.com", "created_at": datetime.now(timezone.utc),
                         "settings": {}})
    ids = {n: f"{MARK}-g{n}" for n in range(5)}
    docs = [grading(ids[0], uid, 4, True), grading(ids[1], uid, 5, True), grading(ids[2], uid, 3, False),
            grading(ids[3], uid, 2, True, "v9"), grading(ids[4], own, 4, True)]
    db.gradings.insert_many(docs)
    db.feedback.insert_one({"_id": MARK + "-f", "uid": uid, "created_at": datetime.now(timezone.utc),
                            "rating": 2, "category": "app", "comment": "hi", "app_version": "1"})
    certs = {n: f"GE-209902-0000{n}" for n in (1, 2, 3, 4)}
    db.certificates.insert_many([cert(c, f"tok{n}abc", uid, f"{MARK}-cg{n}") for n, c in certs.items()])
    yield {"uid": uid, "ids": ids, "certs": certs, "own": own}
    for coll in ("gradings", "feedback", "certificates", "users", "rejections", "announcements"):
        getattr(db, coll).delete_many({"_id": {"$regex": f"^({MARK}|GE-209902)"}})
    db.reviews.delete_many({"grading_id": {"$regex": f"^{MARK}"}})
    db.gradings.delete_many({"uid": own})


# ---- 0. Fixes from 10a ----

def test_list_users_sort_created_uses_created_at_only(admin_c, app_state):
    db, now = app_state.db, datetime.now(timezone.utc)
    a, b = MARK + "-sa", MARK + "-sb"
    db.users.insert_many([
        {"_id": a, "email": f"{MARK}-s-a@example.com", "created_at": now - timedelta(days=2)},
        {"_id": b, "email": f"{MARK}-s-b@example.com", "created_at": now - timedelta(days=1)}])
    db.gradings.insert_one(grading(MARK + "-sg", a, 3, False))   # a is the most recently active
    try:
        q = f"/admin/users?q={MARK}-s-"
        assert [u["uid"] for u in admin_c.get(q + "&sort=created").json()["items"]] == [b, a]
        assert [u["uid"] for u in admin_c.get(q + "&sort=last_active").json()["items"]] == [a, b]
    finally:
        db.users.delete_many({"_id": {"$in": [a, b]}})
        db.gradings.delete_one({"_id": MARK + "-sg"})


def test_model_version_real_and_rejections_store_it(admin_c, client, app_state, monkeypatch):
    assets = app_state.assets
    assert admin_c.get("/admin/stats/summary").json()["server"]["model_version"] == \
        assets.manifest["model_version"]
    monkeypatch.setitem(assets.manifest, "model_version", "v77")
    assert admin_c.get("/admin/stats/summary").json()["server"]["model_version"] == "v77"
    monkeypatch.undo()
    ok, jpg = cv2.imencode(".jpg", np.full((20, 20, 3), 200, np.uint8))
    r = client.post("/grade", files={"image": ("a.jpg", jpg.tobytes(), "image/jpeg")})
    assert r.status_code == 200 and r.json()["status"] == "invalid_image"
    rej = app_state.db.rejections.find_one({"uid": client.user.uid}, sort=[("created_at", -1)])
    assert rej["model_version"] == assets.manifest["model_version"]
    app_state.db.rejections.insert_one({"_id": MARK + "-old", "uid": MARK, "status": "blurry",
                                        "created_at": datetime.now(timezone.utc), "diagnostics": {}})
    rows = admin_c.get("/admin/model/monitoring?days=2").json()["rejections_by_gate"]
    versions = {x["model_version"] for x in rows}
    assert assets.manifest["model_version"] in versions and "unknown" in versions


# ---- Permissions ----

def test_permissions(client, reviewer_c, admin_c, fx):
    u, cn = fx["uid"], fx["certs"][1]
    admin_only = [
        ("post", f"/admin/users/{u}/disable", None), ("post", f"/admin/users/{u}/enable", None),
        ("post", f"/admin/users/{u}/role", {"role": "none"}),
        ("post", f"/admin/users/{u}/password-reset", None), ("delete", f"/admin/users/{u}", None),
        ("get", "/admin/config", None), ("put", "/admin/config", {"min_app_version": "1.0.0"}),
        ("post", "/admin/config/reset-gates", None),
        ("get", "/admin/announcements", None),
        ("post", "/admin/announcements", {"title": "t", "message": "m", "ends_at": "2099-01-01T00:00:00Z"}),
        ("put", "/admin/announcements/x", {"title": "t", "message": "m", "ends_at": "2099-01-01T00:00:00Z"}),
        ("delete", "/admin/announcements/x", None),
        ("get", "/admin/reviews/stats", None), ("get", "/admin/reviews/export", None),
        ("post", f"/admin/feedback/{MARK}-f/status", {"status": "resolved"}),
        ("get", f"/admin/certificates/{cn}", None),
        ("post", f"/admin/certificates/{cn}/revoke", {"reason": "x"}),
        ("post", f"/admin/certificates/{cn}/supersede", {"new_cert_no": fx["certs"][3], "reason": "x"}),
    ]
    review_routes = [("get", "/admin/review-queue", None),
                     ("post", "/admin/reviews", {"grading_id": "nope", "gemologist_grade": 3}),
                     ("put", f"/admin/reviews/{fx['ids'][0]}", {"gemologist_grade": 3})]
    for who in (client, reviewer_c):
        for method, url, body in admin_only:
            r = getattr(who, method)(url, **({"json": body} if body is not None else {}))
            assert r.status_code == 403 and r.json()["code"] == "forbidden", (url, r.status_code)
    for method, url, body in review_routes:
        r = getattr(client, method)(url, **({"json": body} if body is not None else {}))
        assert r.status_code == 403, url
    assert reviewer_c.get("/admin/review-queue").status_code == 200
    assert reviewer_c.post("/admin/reviews", json={"grading_id": "nope", "gemologist_grade": 3}).status_code == 404
    assert admin_c.get("/admin/review-queue").status_code == 200


# ---- 2. Remote config ----

BAD_CONFIGS = [
    {}, {"unknown": 1}, {"referral_threshold_default": 0.39}, {"referral_threshold_default": 0.91},
    {"referral_threshold_default": "0.5"}, {"calibration_validity_hours": 0},
    {"calibration_validity_hours": 73}, {"calibration_validity_hours": True},
    {"calibration_validity_hours": 24.5}, {"min_app_version": "1.0"},
    {"min_app_version": "1.0.0-beta"}, {"min_app_version": 1},
    {"maintenance": {"enabled": True, "message": "x" * 201}}, {"maintenance": {"enabled": "yes"}},
    {"maintenance": {"nope": 1}}, {"features": {"nope": True}}, {"features": {"gradcam": "true"}},
    {"verify_base_url": "http://x.example"}, {"verify_base_url": "https://x.example/?a=b"},
    {"verify_base_url": "javascript:alert(1)"}, {"verify_base_url": "https://"},
    {"verify_base_url": "http://8.8.8.8:3000"}, {"verify_base_url": "http://192.168.1.5:3000/v"},
    {"verify_base_url": "http://172.32.0.1:3000"},
    {"gates": {"nope": 1}}, {"gates": {"blur_min_variance": 4.9}},
    {"gates": {"blur_min_variance": 200.1}}, {"gates": {"no_stone_min_area": 0.001}},
    {"gates": {"no_stone_min_contrast_de00": 16}}, {"gates": {"hue_min": 99}},
    {"gates": {"hue_max": 321}}, {"gates": {"min_chroma": -0.1}}, {"gates": {"ood_warn": 61}},
    {"gates": {"ood_reject": 9}}, {"gates": {"ood_reject": True}},
    {"gates": {"ood_warn": 40, "ood_reject": 30}}, {"gates": {"ood_warn": 26.0}},   # above the stored ood_reject (25.69)
]


def test_gate_defaults_unchanged(admin_c, raw_client):
    assert gates.DEFAULTS == GATE_DEFAULTS and gates.effective({}) == GATE_DEFAULTS
    assert gates.BLUR_MIN_VARIANCE == GATE_DEFAULTS["blur_min_variance"]
    cfg = admin_c.get("/admin/config").json()
    assert cfg["gates"] == GATE_DEFAULTS and cfg["gate_defaults"] == GATE_DEFAULTS
    assert cfg["referral_threshold_default"] == 0.6 and cfg["calibration_validity_hours"] == 24
    assert cfg["verify_base_url"] == "https://gemeye-app-2026.web.app"
    pub = raw_client.get("/config").json()
    assert pub["gates"] == GATE_DEFAULTS and pub["blur_min_variance"] == GATE_DEFAULTS["blur_min_variance"]
    assert "verify_base_url" not in pub and "announcements" in pub and "features" in pub
    # A bad stored value falls back to the default instead of breaking grading.
    assert gates.effective({"gates": {"blur_min_variance": 9999, "hue_min": 180.0}}) == \
        {**GATE_DEFAULTS, "hue_min": 180.0}


def test_config_bounds_rejected(admin_c, app_state):
    db = app_state.db
    before, n0 = admin_c.get("/admin/config").json(), n_audit(db, "config_update")
    for body in BAD_CONFIGS:
        r = admin_c.put("/admin/config", json=body)
        assert r.status_code == 400, body
    assert admin_c.get("/admin/config").json() == before and n_audit(db, "config_update") == n0


def test_config_update_audited_and_reset_gates(admin_c, raw_client, app_state):
    db = app_state.db
    n0 = n_audit(db, "config_update")
    r = admin_c.put("/admin/config", json={
        "referral_threshold_default": 0.5, "calibration_validity_hours": 12, "min_app_version": "1.2.3",
        "features": {"gradcam": False}, "gates": {"blur_min_variance": 40, "ood_warn": 21},
        "verify_base_url": "https://example.org/"})
    assert r.status_code == 200, r.text
    c = r.json()
    assert c["gates"]["blur_min_variance"] == 40 and c["gates"]["hue_min"] == 170.0
    assert c["features"]["gradcam"] is False and c["features"]["repeatability_mode"] is True
    assert c["verify_base_url"] == "https://example.org"
    e = audited(db, "config_update", n0)
    assert e["before"]["gates"]["blur_min_variance"] == GATE_DEFAULTS["blur_min_variance"]
    assert e["after"]["gates"]["blur_min_variance"] == 40
    pub = raw_client.get("/config").json()
    assert pub["blur_min_variance"] == 40 and pub["gates"]["ood_warn"] == 21
    assert pub["min_app_version"] == "1.2.3"
    # reset-gates restores only the gates.
    n1 = n_audit(db, "config_reset_gates")
    r = admin_c.post("/admin/config/reset-gates")
    assert r.status_code == 200 and r.json()["gates"] == GATE_DEFAULTS
    assert r.json()["min_app_version"] == "1.2.3"
    audited(db, "config_reset_gates", n1)
    assert raw_client.get("/config").json()["gates"] == GATE_DEFAULTS
    assert admin_c.put("/admin/config", json={
        "referral_threshold_default": 0.6, "calibration_validity_hours": 24, "min_app_version": "1.0.0",
        "features": {"gradcam": True}, "verify_base_url": "https://gemeye-app-2026.web.app"}).status_code == 200


def test_maintenance_blocks_grade(admin_c, client, raw_client, app_state):
    db = app_state.db
    n0 = n_audit(db, "config_update")
    assert admin_c.put("/admin/config", json={"maintenance": {"enabled": True, "message": "Back soon"}}).status_code == 200
    audited(db, "config_update", n0)
    try:
        r = client.post("/grade", files={"image": ("a.jpg", b"x", "image/jpeg")})
        assert r.status_code == 503 and r.json()["code"] == "maintenance" and "Back soon" in r.json()["message"]
        assert raw_client.get("/config").json()["maintenance"]["enabled"] is True
    finally:
        admin_c.put("/admin/config", json={"maintenance": {"enabled": False, "message": ""}})
    ok, jpg = cv2.imencode(".jpg", np.full((20, 20, 3), 200, np.uint8))
    assert client.post("/grade", files={"image": ("a.jpg", jpg.tobytes(), "image/jpeg")}).status_code == 200


def test_verify_base_url_only_for_new_certificates(admin_c, client, fx, app_state):
    db = app_state.db
    old = {"_id": "GE-209902-00009", "token": "T"}
    assert certificates.verify_url(old) == "https://gemeye-app-2026.web.app/v/GE-209902-00009-T"
    assert certificates.verify_url({**old, "verify_base": "https://example.org"}) == \
        "https://example.org/v/GE-209902-00009-T"
    admin_c.put("/admin/config", json={"verify_base_url": "https://example.org"})
    try:
        r = client.post("/certificates", json={"grading_id": fx["ids"][4]})
        assert r.status_code == 201 and r.json()["verify_url"].startswith("https://example.org/v/GE-")
        again = client.post("/certificates", json={"grading_id": fx["ids"][4]})
        assert again.json()["verify_url"] == r.json()["verify_url"]
    finally:
        admin_c.put("/admin/config", json={"verify_base_url": "https://gemeye-app-2026.web.app"})
        db.certificates.delete_many({"uid": fx["own"]})


def test_public_verify_review(raw_client, fx, app_state):
    """The public page shows a gemologist grade (no reviewer identity), never an unusable review."""
    db, gid, url = app_state.db, f"{MARK}-cg4", f"/public/v/{fx['certs'][4]}-tok4abc"
    assert raw_client.get(url).json()["review"] is None
    db.reviews.insert_one({"_id": MARK + "-rv4", "grading_id": gid, "gemologist_grade": None, "unusable": True,
                           "reviewer_uid_hash": "h", "notes": "n", "created_at": datetime.now(timezone.utc)})
    try:
        assert raw_client.get(url).json()["review"] is None
        db.reviews.update_one({"_id": MARK + "-rv4"}, {"$set": {"gemologist_grade": 3, "unusable": False}})
        r = raw_client.get(url).json()["review"]
        assert r["gemologist_grade"] == 3 and r["reviewed_at"] and set(r) == {"gemologist_grade", "reviewed_at"}
    finally:
        db.reviews.delete_one({"_id": MARK + "-rv4"})


def test_public_verify_cors_lan_origin(admin_c, raw_client, fx):
    """A LAN verify base (phone on the same Wi-Fi) is accepted and its origin gets CORS on
    /public/v/ (also on 404 and preflight); other origins do not."""
    lan, slug_ok = "http://192.168.1.50:3000", f"{fx['certs'][4]}-tok4abc"
    acao = lambda r: r.headers.get("access-control-allow-origin")  # noqa: E731
    assert acao(raw_client.get(f"/public/v/{slug_ok}", headers={"Origin": "http://localhost:3000"})) ==         "http://localhost:3000"
    assert acao(raw_client.get(f"/public/v/{slug_ok}", headers={"Origin": lan})) is None
    r = admin_c.put("/admin/config", json={"verify_base_url": lan + "/"})
    assert r.status_code == 200 and r.json()["verify_base_url"] == lan
    try:
        ok = raw_client.get(f"/public/v/{slug_ok}", headers={"Origin": lan})
        assert ok.status_code == 200 and acao(ok) == lan
        bad = raw_client.get(f"/public/v/{fx['certs'][4]}-wrong", headers={"Origin": lan})
        assert bad.status_code == 404 and acao(bad) == lan
        pre = raw_client.options(f"/public/v/{slug_ok}", headers={"Origin": lan})
        assert pre.status_code == 204 and acao(pre) == lan
        assert acao(raw_client.get(f"/public/v/{slug_ok}", headers={"Origin": "http://192.168.1.51:3000"})) is None
        assert admin_c.put("/admin/config", json={"verify_base_url": "http://localhost:3000"}).status_code == 200
    finally:
        admin_c.put("/admin/config", json={"verify_base_url": "https://gemeye-app-2026.web.app"})


# ---- 3. Announcements ----

def test_announcements(admin_c, raw_client, app_state):
    db, now = app_state.db, datetime.now(timezone.utc)
    iso = lambda d: (now + d).isoformat()  # noqa: E731
    body = lambda t, s, e, **k: {"title": f"{MARK} {t}", "message": "Hello", "starts_at": iso(s),  # noqa: E731
                                 "ends_at": iso(e), **k}
    made = {}
    n0 = n_audit(db, "announcement_create")
    for name, b in {"live": body("live", timedelta(hours=-1), timedelta(hours=1)),
                    "future": body("future", timedelta(hours=1), timedelta(hours=2)),
                    "expired": body("expired", timedelta(hours=-2), timedelta(hours=-1)),
                    "off": body("off", timedelta(hours=-1), timedelta(hours=1), active=False,
                                level="warning")}.items():
        r = admin_c.post("/admin/announcements", json=b)
        assert r.status_code == 201, r.text
        made[name] = r.json()
    assert n_audit(db, "announcement_create") == n0 + 4
    assert [made[k]["state"] for k in ("live", "future", "expired", "off")] == \
        ["live", "scheduled", "expired", "disabled"]
    assert len(made["live"]["created_by_hash"]) == 64
    public = [a["title"] for a in raw_client.get("/announcements").json()["items"] if MARK in a["title"]]
    assert public == [f"{MARK} live"]
    assert [a["title"] for a in raw_client.get("/config").json()["announcements"] if MARK in a["title"]] == public
    assert "created_by_hash" not in raw_client.get("/announcements").json()["items"][0]
    listed = admin_c.get("/admin/announcements?limit=100").json()["items"]
    assert {a["id"] for a in listed} >= {m["id"] for m in made.values()}
    # Validation.
    for bad in (body("x" * 81, timedelta(), timedelta(hours=1)) | {"title": "x" * 81},
                body("t", timedelta(), timedelta(hours=1), level="error"),
                body("t", timedelta(hours=1), timedelta(hours=-1)),
                body("t", timedelta(), timedelta(hours=1)) | {"message": "m" * 501},
                body("t", timedelta(), timedelta(hours=1)) | {"extra": 1}):
        assert admin_c.post("/admin/announcements", json=bad).status_code == 400
    # Update (re-enable "off" and move "live" into the past) and delete.
    n1, n2 = n_audit(db, "announcement_update"), n_audit(db, "announcement_delete")
    r = admin_c.put(f"/admin/announcements/{made['off']['id']}",
                    json=body("off", timedelta(hours=-1), timedelta(hours=1)))
    assert r.status_code == 200 and r.json()["state"] == "live"
    r = admin_c.put(f"/admin/announcements/{made['live']['id']}",
                    json=body("live", timedelta(hours=-3), timedelta(hours=-2)))
    assert r.json()["state"] == "expired"
    audited(db, "announcement_update", n1 + 1)
    public = [a["title"] for a in raw_client.get("/announcements").json()["items"] if MARK in a["title"]]
    assert public == [f"{MARK} off"]
    for m in made.values():
        assert admin_c.delete(f"/admin/announcements/{m['id']}").status_code == 204
    audited(db, "announcement_delete", n2 + 3)
    assert admin_c.delete(f"/admin/announcements/{made['live']['id']}").status_code == 404
    assert admin_c.put("/admin/announcements/nope", json=body("t", timedelta(), timedelta(hours=1))).status_code == 404


# ---- 4. Review queue ----

def test_review_flow(admin_c, reviewer_c, client, raw_client, fx, app_state):
    db, ids = app_state.db, fx["ids"]
    queue = lambda who, q="": [i["grading_id"] for i in who.get("/admin/review-queue?limit=100" + q).json()["items"]]  # noqa: E731
    q = queue(reviewer_c)
    assert ids[0] in q and ids[1] in q and ids[3] in q and ids[2] not in q    # g2 not referred
    assert ids[0] in queue(reviewer_c, "&grade=4") and ids[1] not in queue(reviewer_c, "&grade=4")
    assert ids[3] in queue(reviewer_c, "&model_version=v9") and ids[0] not in queue(reviewer_c, "&model_version=v9")
    assert all("user_email" not in i for i in reviewer_c.get("/admin/review-queue").json()["items"])
    future = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat().replace("+00:00", "Z")
    assert queue(reviewer_c, f"&from={future}") == []

    n0 = n_audit(db, "review_create")
    r = reviewer_c.post("/admin/reviews", json={"grading_id": ids[0], "gemologist_grade": 4, "notes": " ok "})
    assert r.status_code == 201 and r.json()["agrees"] is True and r.json()["notes"] == "ok"
    audited(db, "review_create", n0)
    again = reviewer_c.post("/admin/reviews", json={"grading_id": ids[0], "gemologist_grade": 3})
    assert again.status_code == 409 and again.json()["code"] == "already_reviewed"
    assert admin_c.post("/admin/reviews", json={"grading_id": ids[0], "gemologist_grade": 3}).status_code == 409
    assert n_audit(db, "review_create") == n0 + 1
    for bad in ({"grading_id": ids[1], "gemologist_grade": 8}, {"grading_id": ids[1], "gemologist_grade": 0},
                {"grading_id": ids[1], "gemologist_grade": "3"},
                {"grading_id": ids[1], "gemologist_grade": 3, "notes": "n" * 501},
                {"grading_id": ids[1], "gemologist_grade": 3, "x": 1}):
        assert reviewer_c.post("/admin/reviews", json=bad).status_code == 400
    assert reviewer_c.post("/admin/reviews", json={"grading_id": "nope", "gemologist_grade": 3}).status_code == 404
    assert ids[0] not in queue(reviewer_c) and ids[1] in queue(reviewer_c)

    # Admin corrects (audited); a reviewer edits only their own reviews (see test_model_monitoring).
    n1 = n_audit(db, "review_update")
    r = admin_c.put(f"/admin/reviews/{ids[0]}", json={"gemologist_grade": 5})
    assert r.status_code == 200 and r.json()["agrees"] is False
    e = audited(db, "review_update", n1)
    assert e["before"]["gemologist_grade"] == 4 and e["after"]["gemologist_grade"] == 5
    assert admin_c.put(f"/admin/reviews/{ids[1]}", json={"gemologist_grade": 5}).status_code == 404

    assert admin_c.post("/admin/reviews", json={"grading_id": ids[1], "gemologist_grade": 6}).status_code == 201
    assert reviewer_c.put(f"/admin/reviews/{ids[1]}", json={"gemologist_grade": 5}).status_code == 403
    assert reviewer_c.post("/admin/reviews", json={"grading_id": ids[3], "gemologist_grade": 2}).status_code == 201
    assert admin_c.post("/admin/reviews", json={"grading_id": ids[4], "gemologist_grade": 3}).status_code == 201

    s = admin_c.get("/admin/reviews/stats").json()
    assert (s["reviewed"], s["agreed"]) == (4, 1) and s["agreement_rate"] == 0.25
    assert s["within_one_grade_rate"] == 1.0         # all four are within one grade
    m = s["confusion_matrix"]["counts"]
    assert m[3][4] == 1 and m[4][5] == 1 and m[1][1] == 1 and m[3][2] == 1 and sum(map(sum, m)) == 4
    per_v = {v["model_version"]: v for v in s["per_model_version"]}
    assert (per_v["v3"]["reviewed"], per_v["v3"]["agreed"]) == (3, 0)
    assert (per_v["v9"]["reviewed"], per_v["v9"]["agreed"]) == (1, 1)
    per_g = {g["model_grade"]: g for g in s["per_grade"]}
    assert per_g[4]["reviewed"] == 2 and per_g[4]["agreed"] == 0 and per_g[2]["agreement_rate"] == 1.0
    assert reviewer_c.get("/admin/reviews/stats").status_code == 403

    # Model monitoring shows review agreement per version and day.
    mon = {v["model_version"]: v for v in admin_c.get("/admin/model/monitoring?days=2").json()["versions"]}
    today = mon["v9"]["review_agreement"][-1]
    assert today["reviewed"] == 1 and today["agreed"] == 1 and today["agreement_rate"] == 1.0
    assert mon["v3"]["review_agreement"][-1]["reviewed"] == 3

    # Export: admin only, no uids, emails or storage keys.
    assert reviewer_c.get("/admin/reviews/export").status_code == 403
    n2 = n_audit(db, "review_export")
    r = admin_c.get("/admin/reviews/export")
    assert r.status_code == 200 and r.headers["content-type"].startswith("text/csv")
    rows = list(csv.reader(io.StringIO(r.text)))
    assert rows[0] == ["grading_id", "image_ref", "model_grade", "gemologist_grade", "confidence",
                       "model_version", "created_at", "reviewer_confidence", "unusable"]
    assert len(rows) == 5
    for secret in (fx["uid"], fx["own"], "@", "gradings/", ".jpg"):
        assert secret not in r.text
    audited(db, "review_export", n2)

    # The owner sees the review on their own grading, without the reviewer identity.
    one = client.get(f"/gradings/{ids[4]}").json()
    assert one["review"]["gemologist_grade"] == 3 and set(one["review"]) == {"gemologist_grade", "reviewed_at"}
    listed = {i["grading_id"]: i for i in client.get("/gradings").json()["items"]}
    assert listed[ids[4]]["review"]["gemologist_grade"] == 3
    assert "reviewer" not in json.dumps(one).lower()
    assert client.get("/gradings").json()["items"] and all(
        i["review"] is None for i in listed.values() if i["grading_id"] != ids[4])


# ---- 5. Feedback ----

def test_feedback_status(admin_c, client, fx, app_state):
    db, fid = app_state.db, MARK + "-f"
    assert admin_c.get(f"/admin/feedback?uid={fx['uid']}").json()["items"][0]["status"] == "open"
    n0 = n_audit(db, "feedback_status")
    r = admin_c.post(f"/admin/feedback/{fid}/status", json={"status": "resolved", "note": "Fixed in 1.1"})
    assert r.status_code == 200 and r.json()["status"] == "resolved"
    e = audited(db, "feedback_status", n0)
    assert e["before"]["status"] == "open" and e["after"] == {"status": "resolved", "note": "Fixed in 1.1"}
    item = admin_c.get(f"/admin/feedback?uid={fx['uid']}").json()["items"][0]
    assert item["status"] == "resolved" and item["status_note"] == "Fixed in 1.1"
    for bad in ({"status": "closed"}, {"status": "open", "note": "n" * 301}, {}):
        assert admin_c.post(f"/admin/feedback/{fid}/status", json=bad).status_code == 400
    assert admin_c.post("/admin/feedback/nope/status", json={"status": "open"}).status_code == 404
    assert admin_c.post(f"/admin/feedback/{fid}/status", json={"status": "open"}).status_code == 200


# ---- 6. Certificates ----

def test_certificate_revoke_and_supersede(admin_c, raw_client, fx, app_state):
    db, c = app_state.db, fx["certs"]
    page = lambda n: raw_client.get(f"/public/v/{c[n]}-tok{n}abc")  # noqa: E731
    assert page(1).json()["status"] == "valid"

    d = admin_c.get(f"/admin/certificates/{c[1]}").json()
    assert d["cert_no"] == c[1] and d["status"] == "valid" and d["pdf_url"] is None
    assert "token" not in json.dumps(d).lower() and admin_c.get("/admin/certificates/GE-000000-00000").status_code == 404

    n0 = n_audit(db, "certificate_revoke")
    assert admin_c.post(f"/admin/certificates/{c[1]}/revoke", json={}).status_code == 400
    r = admin_c.post(f"/admin/certificates/{c[1]}/revoke", json={"reason": " Wrong stone "})
    assert r.status_code == 200
    e = audited(db, "certificate_revoke", n0)
    assert e["before"]["status"] == "valid" and e["after"]["reason"] == "Wrong stone"
    p = page(1).json()
    assert p["status"] == "revoked" and p["revoked_reason"] == "Wrong stone" and p["superseded_by"] is None
    assert admin_c.post(f"/admin/certificates/{c[1]}/revoke", json={"reason": "again"}).status_code == 409
    assert admin_c.post("/admin/certificates/GE-000000-00000/revoke", json={"reason": "x"}).status_code == 404

    n1 = n_audit(db, "certificate_supersede")
    body = {"new_cert_no": c[3], "reason": "Re-graded"}
    assert admin_c.post(f"/admin/certificates/{c[2]}/supersede", json={**body, "new_cert_no": c[2]}).status_code == 400
    assert admin_c.post(f"/admin/certificates/{c[2]}/supersede", json={**body, "new_cert_no": "bad"}).status_code == 400
    assert admin_c.post(f"/admin/certificates/{c[2]}/supersede", json={**body, "new_cert_no": c[1]}).status_code == 409
    assert admin_c.post(f"/admin/certificates/{c[2]}/supersede", json={**body, "new_cert_no": "GE-209902-77777"}).status_code == 404
    r = admin_c.post(f"/admin/certificates/{c[2]}/supersede", json=body)
    assert r.status_code == 200 and r.json()["superseded_by"] == c[3]
    e = audited(db, "certificate_supersede", n1)
    assert e["after"]["superseded_by"] == c[3]
    p = page(2).json()
    assert p["status"] == "revoked" and p["superseded_by"] == c[3] and p["revoked_reason"] == "Re-graded"
    # Same owner and valid: the replacement's own verify link is public.
    assert p["superseded_by_url"] == f"https://gemeye-app-2026.web.app/v/{c[3]}-tok3abc"
    db.certificates.update_one({"_id": c[3]}, {"$set": {"uid": "someone-else"}})
    try:
        p = page(2).json()
        assert p["superseded_by"] == c[3] and p["superseded_by_url"] is None
    finally:
        db.certificates.update_one({"_id": c[3]}, {"$set": {"uid": fx["uid"]}})
    assert page(3).json()["status"] == "valid"
    row = [x for x in admin_c.get(f"/admin/certificates?q={c[2]}").json()["items"]][0]
    assert row["superseded_by"] == c[3]
    assert admin_c.post(f"/admin/certificates/{c[2]}/supersede", json=body).status_code == 409


# ---- 1. Users ----

def test_disable_enable_blocks_app(admin_c, raw_client, app_state):
    db = app_state.db
    with FirebaseTestUser() as u:
        h = u.headers
        assert raw_client.get("/me", headers=h).status_code == 200
        n0, n1 = n_audit(db, "user_disable"), n_audit(db, "user_enable")
        assert admin_c.post(f"/admin/users/{u.uid}/disable").status_code == 200
        audited(db, "user_disable", n0)
        assert firebase_auth.get_user(u.uid).disabled is True
        for call in (lambda: raw_client.get("/me", headers=h),
                     lambda: raw_client.put("/me", headers=h, json={"country": "LK"}),
                     lambda: raw_client.post("/feedback", headers=h, json={"rating": 3, "category": "app"})):
            r = call()
            assert r.status_code == 401 and r.json()["code"] == "account_disabled"
            assert "disabled" in r.json()["message"].lower()
        assert admin_c.post(f"/admin/users/{u.uid}/enable").status_code == 200
        audited(db, "user_enable", n1)
        assert firebase_auth.get_user(u.uid).disabled is False
        assert raw_client.get("/me", headers=h).status_code == 200
    me = admin_c.user.uid
    assert admin_c.post(f"/admin/users/{me}/disable").status_code == 400
    assert admin_c.post("/admin/users/no-such-uid-" + MARK + "/disable").status_code == 404
    assert admin_c.post("/admin/users/no-such-uid-" + MARK + "/enable").status_code == 404


def test_role_changes(admin_c, app_state):
    db = app_state.db
    with FirebaseTestUser() as u:
        for role in ("reviewer", "admin", "none"):
            n0 = n_audit(db, "user_role")
            r = admin_c.post(f"/admin/users/{u.uid}/role", json={"role": role})
            assert r.status_code == 200 and r.json()["role"] == role
            e = audited(db, "user_role", n0)
            assert e["after"] == {"role": role}
            claims = firebase_auth.get_user(u.uid).custom_claims or {}
            assert claims.get("admin") is (True if role == "admin" else None)
            assert claims.get("reviewer") is (True if role == "reviewer" else None)
        assert admin_c.post(f"/admin/users/{u.uid}/role", json={"role": "root"}).status_code == 400
        assert admin_c.post(f"/admin/users/{u.uid}/role", json={}).status_code == 400
    assert admin_c.post("/admin/users/no-such-uid/role", json={"role": "none"}).status_code == 404
    me = admin_c.user.uid
    n0 = n_audit(db, "user_role")
    for role in ("reviewer", "none"):
        r = admin_c.post(f"/admin/users/{me}/role", json={"role": role})
        assert r.status_code == 400 and r.json()["code"] == "self_action"
    assert n_audit(db, "user_role") == n0
    assert firebase_auth.get_user(me).custom_claims.get("admin") is True
    assert admin_c.post(f"/admin/users/{me}/role", json={"role": "admin"}).status_code == 200


def test_password_reset_never_logs_link(admin_c, app_state, monkeypatch, caplog):
    db, link = app_state.db, "https://example.com/reset?oobCode=SECRETOOB"
    with FirebaseTestUser() as u:
        n0 = n_audit(db, "user_password_reset")
        monkeypatch.setattr(admin_write, "send_reset_email", lambda email: email == u.email)
        r = admin_c.post(f"/admin/users/{u.uid}/password-reset")
        assert r.status_code == 200 and r.json() == {"status": "sent"}
        audited(db, "user_password_reset", n0)
        monkeypatch.setattr(admin_write, "send_reset_email", lambda email: False)
        monkeypatch.setattr(admin_write, "reset_link", lambda email: link)
        with caplog.at_level("DEBUG"):
            r = admin_c.post(f"/admin/users/{u.uid}/password-reset")
        assert r.json() == {"status": "link", "link": link}
        assert "SECRETOOB" not in caplog.text
        e = db.audit_log.find_one({"action": "user_password_reset"}, sort=[("at", -1)])
        assert "SECRETOOB" not in json.dumps(e, default=str) and e["after"] == {"delivery": "link"}
    assert admin_c.post("/admin/users/no-such-uid/password-reset").status_code == 404


def test_delete_user(admin_c, app_state, fx, monkeypatch):
    db = app_state.db
    me = admin_c.user.uid
    assert admin_c.delete(f"/admin/users/{me}").status_code == 400
    assert firebase_auth.get_user(me)
    assert admin_c.delete("/admin/users/no-such-uid-" + MARK).status_code == 404
    with FirebaseTestUser() as u:
        gid, cn = MARK + "-del-g", "GE-209902-00008"
        db.users.insert_one({"_id": u.uid, "email": u.email, "created_at": datetime.now(timezone.utc)})
        db.gradings.insert_one(grading(gid, u.uid, 4, True))
        db.reviews.insert_one({"_id": MARK + "-del-r", "grading_id": gid, "gemologist_grade": 4,
                               "agrees": True, "created_at": datetime.now(timezone.utc)})
        db.calibrations.insert_one({"_id": MARK + "-del-c", "uid": u.uid, "session_id": MARK, "created_at": datetime.now(timezone.utc)})
        db.certificates.insert_one(cert(cn, "tokdel", u.uid, gid))
        n0 = n_audit(db, "user_delete")
        assert admin_c.delete(f"/admin/users/{u.uid}").status_code == 204
        assert db.users.find_one({"_id": u.uid}) is None and db.gradings.find_one({"_id": gid}) is None
        assert db.reviews.find_one({"grading_id": gid}) is None
        assert db.calibrations.find_one({"uid": u.uid}) is None
        c = db.certificates.find_one({"_id": cn})
        assert c["status"] == "withdrawn" and "uid" not in c and "snapshot" not in c
        assert db.deleted_accounts.find_one({"_id": uid_hash(u.uid)}) is not None
        with pytest.raises(firebase_auth.UserNotFoundError):
            firebase_auth.get_user(u.uid)
        e = audited(db, "user_delete", n0)
        assert e["target"] == {"uid_hash": uid_hash(u.uid)} and u.uid not in json.dumps(e, default=str)
        assert db.audit_log.find_one({"action": "account_deleted", "uid_hash": uid_hash(u.uid)})
    db.certificates.delete_one({"_id": cn})
