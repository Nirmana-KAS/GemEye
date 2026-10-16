"""Phase 10e: model monitoring per version and the review queue panel fields. Run with ENV=test
(see conftest.py). Versions are unique per run so data from other test modules never mixes in."""
import uuid
from datetime import datetime, timezone

import pytest
from firebase_admin import auth as firebase_auth

from app import admin
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser

MARK = "mon-" + uuid.uuid4().hex[:8]
V3, V5 = MARK + "-v3", MARK + "-v5"
COLOUR = {"L": 30.1, "a": 5.2, "b": -40.3, "C": 40.6, "H": 277.4, "S": 0.6, "B": 0.4, "hex": "#1B2A6B",
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


@pytest.fixture(scope="module")
def reviewer2_c(raw_client):
    with with_role("reviewer") as u:
        yield AuthedClient(raw_client, u)


def grading(gid, version, grade, conf, latency, referred=True, warnings=()):
    return {"_id": gid, "uid": MARK + "-user", "stone_id": "GE-STONE-" + gid[-5:],
            "created_at": datetime.now(timezone.utc), "status": "ok", "deleted": False,
            "referral_threshold_used": 0.6, "image_key": None, "device": "Pixel 8",
            "result": {"status": "ok", "grade": grade, "grade_name": "X", "confidence": conf,
                       "uncertainty": 0.2, "referred": referred, "model_version": version,
                       "probabilities": [0.0, 0.1, 0.5, 0.2, 0.1, 0.1, 0.0], "colour": COLOUR,
                       "warnings": list(warnings), "timings_ms": {"total": latency}}}


@pytest.fixture(scope="module")
def fx(raw_client, app_state):
    db = app_state.db
    db.users.insert_one({"_id": MARK + "-user", "email": f"{MARK}@example.com", "phone": "+94770000000",
                         "created_at": datetime.now(timezone.utc)})
    v5 = [f"{MARK}-g5{n}" for n in range(4)]
    db.gradings.insert_many([
        grading(MARK + "-g30", V3, 3, 0.9, 100.0, referred=False),
        grading(MARK + "-g31", V3, 4, 0.5, 300.0, warnings=["unusual_image"]),
        # v5: latencies 100..2000 (p95 nearest rank of 20 values is the 19th = 1900)
        *[grading(v5[n], V5, (3, 4, 5, 2)[n], 0.4 + 0.1 * n, 100.0 * (n + 1)) for n in range(4)],
        *[grading(f"{MARK}-l{n}", V5, 3, 0.8, 100.0 * (n + 5), referred=False) for n in range(16)]])
    now = datetime.now(timezone.utc)
    db.rejections.insert_many([
        {"_id": f"{MARK}-r{n}", "uid": MARK + "-user", "created_at": now, "status": s,
         "model_version": V5, "diagnostics": {}} for n, s in enumerate(("blurry", "blurry", "not_blue"))])
    yield {"v5": v5}
    db.gradings.delete_many({"_id": {"$regex": f"^{MARK}"}})
    db.rejections.delete_many({"_id": {"$regex": f"^{MARK}"}})
    db.reviews.delete_many({"grading_id": {"$regex": f"^{MARK}"}})
    db.users.delete_many({"_id": {"$regex": f"^{MARK}"}})


def mon(who, q):
    r = who.get("/admin/model/monitoring?" + q)
    assert r.status_code == 200, r.text
    return r.json()


def test_p95_nearest_rank():
    assert admin._p95([]) is None
    assert admin._p95([5]) == 5
    assert admin._p95(range(1, 21)) == 19
    assert admin._p95(list(range(1, 101)) + [None]) == 95


def test_empty(admin_c):
    for days in (7, 30, 90):
        m = mon(admin_c, f"days={days}&model_version={MARK}-none")
        assert m["versions"] == [] and m["rejections_by_gate"] == [] and len(m["day_keys"]) == days


def test_two_versions(admin_c, fx):
    m = mon(admin_c, "days=7")
    by_v = {v["model_version"]: v for v in m["versions"]}
    assert {V3, V5} <= set(by_v)
    s3, s5 = by_v[V3]["summary"], by_v[V5]["summary"]
    assert s3["gradings"] == 2 and s3["referral_rate"] == 0.5 and s3["avg_confidence"] == 0.7
    assert s3["unusual_image"] == 1 and s3["rejections"] == 0 and s3["rejection_rate"] == 0
    assert s3["avg_latency_ms"] == 200.0 and s3["p95_latency_ms"] == 300.0
    assert s5["gradings"] == 20 and s5["referral_rate"] == 0.2
    assert s5["rejections"] == 3 and s5["rejections_by_gate"] == {"blurry": 2, "not_blue": 1}
    assert s5["rejection_rate"] == round(3 / 23, 4)
    assert s5["p95_latency_ms"] == 1900.0 and s5["avg_latency_ms"] == 1050.0
    assert s5["avg_uncertainty"] == 0.2
    # Dense days, oldest first; today carries the counts.
    days5 = by_v[V5]["days"]
    assert [d["day"] for d in days5] == m["day_keys"] and len(days5) == 7
    today = days5[-1]
    assert today["count"] == 20 and today["rejections"] == 3 and today["p95_latency_ms"] == 1900.0
    assert today["rejections_by_gate"] == {"blurry": 2, "not_blue": 1}
    assert all(d["count"] == 0 and d["mean_confidence"] is None for d in days5[:-1])
    # Filter to one version.
    only = mon(admin_c, f"days=30&model_version={V5}")
    assert [v["model_version"] for v in only["versions"]] == [V5]
    assert {g["model_version"] for g in only["rejections_by_gate"]} == {V5}


def test_agreement_maths(admin_c, reviewer_c, fx):
    g = fx["v5"]   # model grades 3, 4, 5, 2
    for gid, body in ((g[0], {"gemologist_grade": 3, "reviewer_confidence": "high"}),   # exact
                      (g[1], {"gemologist_grade": 5}),                                  # within one
                      (g[2], {"gemologist_grade": 7, "reviewer_confidence": "low"}),    # two off
                      (g[3], {"unusable": True, "notes": "not a sapphire"})):            # excluded
        r = reviewer_c.post("/admin/reviews", json={"grading_id": gid, **body})
        assert r.status_code == 201, r.text
    assert r.json()["agrees"] is None and r.json()["gemologist_grade"] is None
    rv = {v["model_version"]: v for v in mon(admin_c, "days=7")["versions"]}[V5]
    want = {"reviewed": 3, "agreed": 1, "within_one": 2, "agreement_rate": 0.3333, "within_one_rate": 0.6667}
    assert rv["summary"]["reviews"] == want
    assert {k: rv["review_agreement"][-1][k] for k in want} == want
    v3 = {v["model_version"]: v for v in mon(admin_c, "days=7")["versions"]}[V3]
    assert v3["summary"]["reviews"]["reviewed"] == 0 and v3["summary"]["reviews"]["agreement_rate"] is None
    stats = admin_c.get("/admin/reviews/stats").json()
    assert stats["unusable"] >= 1


def test_review_validation(reviewer_c, fx):
    gid = MARK + "-g31"
    for bad in ({"grading_id": gid}, {"grading_id": gid, "unusable": True, "gemologist_grade": 3},
                {"grading_id": gid, "gemologist_grade": 3, "reviewer_confidence": "sure"},
                {"grading_id": gid, "unusable": "yes"}):
        assert reviewer_c.post("/admin/reviews", json=bad).status_code == 400


def test_queue_panel_fields_and_filters(admin_c, reviewer_c, reviewer2_c, fx):
    pending = reviewer_c.get(f"/admin/review-queue?limit=100&model_version={V3}").json()["items"]
    assert [i["grading_id"] for i in pending] == [MARK + "-g31"]
    item = pending[0]
    for k in ("uid", "user_email", "email", "phone", "image_key"):
        assert k not in item
    assert "image_url" in item and item["grade"] == 4 and item["confidence"] == 0.5
    assert item["probabilities"] == [0.0, 0.1, 0.5, 0.2, 0.1, 0.1, 0.0] and item["colour"]["hex"] == "#1B2A6B"
    assert item["referred_reasons"] == ["low_confidence", "unusual_image"] and item["device"] == "Pixel 8"
    assert MARK + "-user" not in str(pending) and "@" not in str(pending)

    gid = MARK + "-g31"
    assert reviewer_c.post("/admin/reviews", json={"grading_id": gid, "gemologist_grade": 4}).status_code == 201
    mine = reviewer_c.get(f"/admin/review-queue?status=mine&model_version={V3}").json()["items"]
    assert [i["grading_id"] for i in mine] == [gid] and mine[0]["review"]["mine"] is True
    assert "reviewer_uid_hash" not in str(mine)
    assert reviewer2_c.get(f"/admin/review-queue?status=mine&model_version={V3}").json()["items"] == []
    other = reviewer2_c.get(f"/admin/review-queue?status=reviewed&model_version={V3}").json()["items"]
    assert [i["grading_id"] for i in other] == [gid] and other[0]["review"]["mine"] is False
    assert reviewer_c.get("/admin/review-queue?status=nope").status_code == 400

    # A reviewer edits only their own review; admin edits any.
    r = reviewer_c.put(f"/admin/reviews/{gid}", json={"gemologist_grade": 3, "reviewer_confidence": "medium"})
    assert r.status_code == 200 and r.json()["agrees"] is False and r.json()["reviewer_confidence"] == "medium"
    assert reviewer2_c.put(f"/admin/reviews/{gid}", json={"gemologist_grade": 4}).status_code == 403
    assert admin_c.put(f"/admin/reviews/{gid}", json={"gemologist_grade": 4}).status_code == 200


def test_reviewer_forbidden(reviewer_c, client):
    for who in (reviewer_c, client):
        r = who.get("/admin/model/monitoring?days=7")
        assert r.status_code == 403 and r.json()["code"] == "forbidden"
