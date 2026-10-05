"""Phase 8: Grad-CAM heatmap of the CNN branch (POST /gradings/{id}/heatmap).
Run with ENV=test (see conftest.py)."""
import json
import urllib.request

import cv2
import numpy as np
import pytest

from app import routers
from app.pipeline import gradcam
from app.pipeline.colour import decode_image, model_path_image, session_matrix
from app.pipeline.inference import predict_cnn
from tests.conftest import AuthedClient
from tests.helpers.firebase_test_user import FirebaseTestUser
from tests.test_api import grade, needs_stone, s3_keys, stone_bytes



def graded(c, **form):
    r = grade(c, **form)
    assert r.status_code == 200 and r.json()["status"] == "ok", r.text
    return r.json()


def heatmap(c, grading_id):
    return c.post(f"/gradings/{grading_id}/heatmap")


def set_session_mapping(db, on):
    db.app_config.update_one({"_id": "global"}, {"$set": {"features.session_mapping": on}})
    db.invalidate_app_config()


@needs_stone
def test_cam_shape_range_and_deterministic(app_state):
    assets = app_state.assets
    raw = decode_image(stone_bytes())
    cam1, probs1 = gradcam.compute(assets, raw, None, 6)
    cam2, probs2 = gradcam.compute(assets, raw, None, 6)
    assert cam1.shape == (7, 7)
    assert cam1.min() >= 0.0 and cam1.max() <= 1.0 and cam1.max() == pytest.approx(1.0)
    assert np.array_equal(cam1, cam2) and np.array_equal(probs1, probs2)
    # The rebuilt input and the gradient path give the grading's deterministic CNN output.
    _, jpeg = model_path_image(raw, assets.ccm_training, session_matrix(None, None))
    np.testing.assert_allclose(probs1, predict_cnn(assets, jpeg)["deterministic"], atol=1e-5)

    png, fraction, cam = gradcam.heatmap(assets, raw, None, 6)
    assert np.array_equal(cam, cam1) and 0.0 <= fraction <= 1.0
    img = cv2.imdecode(np.frombuffer(png, np.uint8), cv2.IMREAD_COLOR)
    h, w = raw.shape[:2]
    k = min(1.0, gradcam.DISPLAY_MAX_SIDE / max(h, w))
    assert img.shape == (round(h * k), round(w * k), 3)
    assert gradcam.heatmap(assets, raw, None, 6)[0] == png


@needs_stone
def test_heatmap_endpoint_and_cache(client, app_state, monkeypatch):
    g = graded(client)
    r = heatmap(client, g["grading_id"])
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["method"] == "gradcam_cnn_branch" and b["target_grade"] == g["grade"]
    assert 0.0 <= b["stone_mask_heat_fraction"] <= 1.0
    doc = app_state.db.gradings.find_one({"_id": g["grading_id"]})
    st = app_state.storage
    assert doc["heatmap"]["key"] == st.grading_key(client.user.uid, f"{g['grading_id']}_cam", "png")
    assert doc["heatmap"]["stone_mask_heat_fraction"] == b["stone_mask_heat_fraction"]
    assert doc["heatmap"]["calibration_mode"] == "training_session"
    with urllib.request.urlopen(b["url"], timeout=30) as resp:
        assert resp.read(8) == b"\x89PNG\r\n\x1a\n"

    # Cache hit: the stored PNG is reused, nothing is recomputed.
    def fail(*a, **k):
        raise AssertionError("recomputed")
    monkeypatch.setattr(routers.gradcam, "heatmap", fail)
    r2 = heatmap(client, g["grading_id"])
    assert r2.status_code == 200, r2.text
    assert {k: v for k, v in r2.json().items() if k != "url"} == \
        {k: v for k, v in b.items() if k != "url"}


@needs_stone
def test_heatmap_other_user_and_missing(client, client_b, app_state):
    g = graded(client)
    assert heatmap(client_b, g["grading_id"]).status_code == 404
    assert heatmap(client, "nope").status_code == 404
    # The original photo is gone from S3: 404.
    app_state.storage.delete(app_state.db.gradings.find_one({"_id": g["grading_id"]})["image_key"])
    assert heatmap(client, g["grading_id"]).status_code == 404


@needs_stone
def test_heatmap_deleted_with_grading(client, app_state):
    st = app_state.storage
    g = graded(client)
    assert heatmap(client, g["grading_id"]).status_code == 200
    key = st.grading_key(client.user.uid, f"{g['grading_id']}_cam", "png")
    assert st.exists(key)
    assert client.delete(f"/gradings/{g['grading_id']}").status_code == 204
    assert not st.exists(key)
    assert "heatmap" not in app_state.db.gradings.find_one({"_id": g["grading_id"]})
    assert heatmap(client, g["grading_id"]).status_code == 404


@needs_stone
def test_heatmap_deleted_with_account(raw_client, app_state):
    st = app_state.storage
    with FirebaseTestUser() as u:
        c = AuthedClient(raw_client, u)
        g = graded(c)
        assert heatmap(c, g["grading_id"]).status_code == 200
        assert any(k.endswith("_cam.png") for k in s3_keys(st, u.uid))
        assert c.delete("/me").status_code == 204
        assert s3_keys(st, u.uid) == []


@needs_stone
def test_calibration_mode_replayed(client, app_state, monkeypatch):
    db, assets = app_state.db, app_state.assets
    patches = (assets.train_patches * 0.97).round(1).tolist()
    seen = []
    real = gradcam.model_cnn_input

    def spy(a, raw, p):
        seen.append(p)
        return real(a, raw, p)
    monkeypatch.setattr(gradcam, "model_cnn_input", spy)
    try:
        set_session_mapping(db, True)
        mapped = graded(client, patches=json.dumps(patches))
        plain_flag_on = graded(client)                 # no patches: training session
        assert mapped["calibration_mode"] == "session_patches"
        assert plain_flag_on["calibration_mode"] == "training_session"
        set_session_mapping(db, False)                 # current flag must not matter
        assert heatmap(client, mapped["grading_id"]).status_code == 200
        set_session_mapping(db, True)
        assert heatmap(client, plain_flag_on["grading_id"]).status_code == 200
    finally:
        set_session_mapping(db, False)
    assert seen == [db.gradings.find_one({"_id": mapped["grading_id"]})["patches"], None]


def test_config_gradcam_default_true_on_fresh_db(raw_client, app_state):
    from app.db import DEFAULT_APP_CONFIG
    db = app_state.db
    assert DEFAULT_APP_CONFIG["features"]["gradcam"] is True
    # The test database is dropped after every session and seeded at startup.
    assert db.app_config.find_one({"_id": "global"})["features"]["gradcam"] is True
    db.invalidate_app_config()
    assert raw_client.get("/config").json()["features"]["gradcam"] is True
