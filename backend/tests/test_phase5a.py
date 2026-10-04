"""Phase 5a: idempotent /grade (request_id) and the session_mapping feature flag.
Run with ENV=test (see conftest.py)."""
import json
import uuid

from tests.test_api import grade, needs_stone, s3_keys

PATCHES = [[250, 250, 250], [10, 10, 10], [118, 118, 118],
           [186, 186, 186], [5, 60, 140], [170, 55, 60]]


@needs_stone
def test_repeated_request_id_returns_original(client, client_b, app_state, user_a):
    db, st = app_state.db, app_state.storage
    rid = str(uuid.uuid4())
    before = len(s3_keys(st, user_a.uid))
    r1 = grade(client, request_id=rid)
    assert r1.status_code == 200 and r1.json()["status"] == "ok", r1.text
    r2 = grade(client, request_id=rid.upper())          # same UUID, other spelling
    assert r2.status_code == 200, r2.text
    a, b = r1.json(), r2.json()
    assert b["grading_id"] == a["grading_id"] and b["stone_id"] == a["stone_id"]
    assert b["grade"] == a["grade"] and b["probabilities"] == a["probabilities"]
    assert b["image_url"]
    assert db.gradings.count_documents({"request_id": rid}) == 1
    assert len(s3_keys(st, user_a.uid)) == before + 1
    # Another user cannot reuse it, and gets nothing of the first user's grading.
    r3 = grade(client_b, request_id=rid)
    assert r3.status_code == 409 and r3.json()["code"] == "duplicate_request"
    assert "grading_id" not in r3.json()


def test_request_id_must_be_uuid(client):
    r = grade(client, request_id="not-a-uuid")
    assert r.status_code == 400 and "request_id" in r.json()["detail"]


def test_request_id_index_is_sparse_unique(app_state):
    idx = {i["name"]: i for i in app_state.db.gradings.list_indexes()}["request_id_unique"]
    assert idx["unique"] and idx["sparse"]


@needs_stone
def test_session_mapping_flag(client, app_state):
    db = app_state.db
    assert db.get_app_config()["features"]["session_mapping"] is False
    r = grade(client, patches=json.dumps(PATCHES))
    assert r.status_code == 200 and r.json()["status"] == "ok", r.text
    assert r.json()["calibration_mode"] == "training_session"
    doc = db.gradings.find_one({"_id": r.json()["grading_id"]})
    assert doc["patches"] == PATCHES and "request_id" not in doc

    db.app_config.update_one({"_id": "global"}, {"$set": {"features.session_mapping": True}})
    db.invalidate_app_config()
    try:
        r = grade(client, patches=json.dumps(PATCHES))
        assert r.status_code == 200, r.text
        assert r.json()["calibration_mode"] == "session_patches"
        # Without patches the training session is used either way.
        assert grade(client).json()["calibration_mode"] == "training_session"
    finally:
        db.app_config.update_one({"_id": "global"}, {"$set": {"features.session_mapping": False}})
        db.invalidate_app_config()
