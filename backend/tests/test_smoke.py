"""Smoke tests (authenticated as a temporary Firebase user, see conftest.py).
Run inside the container: `docker compose exec -e ENV=test api python -m pytest -q tests`."""
import json
import os

import cv2
import numpy as np
import pytest


# A real test-set stone (development dataset mount). The synthetic disc is rejected
# by the not_recognised gate, so tests that need a grade skip without the dataset.
REAL_STONE = "/data/merged/grade_6_light/g6_010.jpg"


def blue_disc_jpeg():
    """Synthetic stone: a blue disc on a light grey background."""
    img = np.full((600, 800, 3), 205, np.uint8)
    cv2.circle(img, (400, 300), 120, (160, 70, 30), -1)     # BGR
    cv2.circle(img, (370, 270), 30, (200, 120, 70), -1)      # facet highlight
    ok, enc = cv2.imencode(".jpg", img)
    assert ok
    return enc.tobytes()


def stone_jpeg():
    if os.path.exists(REAL_STONE):
        with open(REAL_STONE, "rb") as f:
            return f.read()
    return blue_disc_jpeg()


def post_grade(client, **form):
    files = {"image": ("stone.jpg", stone_jpeg(), "image/jpeg")}
    return client.post("/grade", files=files, data=form)


def require_ok(r):
    if r.json().get("status") != "ok" and not os.path.exists(REAL_STONE):
        pytest.skip("needs the dataset mount for an image that passes the gates")


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["models_loaded"] is True
    assert body["model_version"] == "v3"


def test_grade_schema_and_repeatability(client):
    r1 = post_grade(client)
    assert r1.status_code == 200, r1.text
    require_ok(r1)
    b = r1.json()
    assert b["status"] == "ok", b
    assert isinstance(b["warnings"], list)
    assert "message" not in b
    assert 1 <= b["grade"] <= 7 and 1 <= b["second_grade"] <= 7
    assert b["grade"] != b["second_grade"]
    assert len(b["probabilities"]) == 7
    assert abs(sum(b["probabilities"]) - 1.0) <= 1e-4
    assert b["uncertainty"] > 0
    assert b["calibration_mode"] == "training_session"
    assert b["colour"]["hex"].startswith("#") and len(b["colour"]["hex"]) == 7
    for k in ("short_side_px", "blur_variance", "blur_min_variance", "gate_stone_area",
              "stone_tray_contrast_de00", "gate_centre_fallback", "stone_area_fraction",
              "hue_wb", "hue_gate_min", "hue_gate_max", "hue_in_gate", "chroma_wb",
              "min_chroma", "segmentation_reliable", "hue_gate_skipped",
              "model_segmentation_fallback", "ood_distance", "ood_warn", "ood_threshold"):
        assert k in b["diagnostics"]
    assert "debug" not in b
    assert b["colour"]["approximate"] is (not b["diagnostics"]["segmentation_reliable"])

    r2 = post_grade(client)
    assert r2.status_code == 200
    assert r2.json()["grade"] == b["grade"]


def test_debug_block(client):
    from app.config import get_settings
    r = post_grade(client, debug="true")
    assert r.status_code == 200
    require_ok(r)
    b = r.json()
    if not get_settings().is_production:
        d = b["debug"]
        assert 1 <= d["rf_grade"] <= 7 and 1 <= d["cnn_mc_grade"] <= 7
        assert len(d["rf_probabilities"]) == 7 and len(d["cnn_mc_probabilities"]) == 7
        assert d["model_segmentation_fallback"] == b["diagnostics"]["model_segmentation_fallback"]
    else:
        assert "debug" not in b


def test_grade_with_patches(client):
    patches = [[250, 250, 250], [10, 10, 10], [118, 118, 118],
               [186, 186, 186], [5, 60, 140], [170, 55, 60]]
    r = post_grade(client, patches=json.dumps(patches), referral_threshold="0.5")
    assert r.status_code == 200, r.text
    require_ok(r)
    # features.session_mapping is off by default: patches are stored, not used.
    assert r.json()["calibration_mode"] == "training_session"


def test_bad_inputs(client):
    r = client.post("/grade", files={"image": ("x.jpg", b"not an image", "image/jpeg")})
    assert r.status_code == 400
    # Rejected uploads (HTTP 400/413) never carry a grade.
    assert "grade" not in r.json()
    r = post_grade(client, patches="[[1,2,3]]")
    assert r.status_code == 400
    r = post_grade(client, referral_threshold="0.95")
    assert r.status_code == 400
    big = b"\xff\xd8\xff" + b"\0" * (15 * 1024 * 1024 + 10)
    r = client.post("/grade", files={"image": ("big.jpg", big, "image/jpeg")})
    assert r.status_code == 413


def post_image(client, bgr):
    ok, enc = cv2.imencode(".jpg", bgr)
    assert ok
    return client.post("/grade", files={"image": ("x.jpg", enc.tobytes(), "image/jpeg")})


def assert_rejected(r, code):
    assert r.status_code == 200, r.text
    b = r.json()
    assert b["status"] == code, b
    assert isinstance(b["message"], str) and b["message"]
    assert "diagnostics" in b
    for k in ("grade", "probabilities", "confidence", "warnings"):
        assert k not in b


def test_gate_invalid_image(client):
    # Valid JPEG signature but truncated data.
    r = client.post("/grade", files={"image": ("x.jpg", b"\xff\xd8\xff" + b"\0" * 100, "image/jpeg")})
    assert_rejected(r, "invalid_image")
    r = post_image(client, np.full((200, 200, 3), 200, np.uint8))
    assert_rejected(r, "invalid_image")
    assert r.json()["diagnostics"]["short_side_px"] == 200


def test_gate_blurry(client):
    # no_stone runs first; a heavily blurred stone may fail either gate.
    r = post_image(client, cv2.GaussianBlur(cv2.imdecode(np.frombuffer(stone_jpeg(), np.uint8),
                                                          cv2.IMREAD_COLOR), (0, 0), 8))
    assert r.json()["status"] in ("blurry", "no_stone")
    assert_rejected(r, r.json()["status"])


def test_gate_no_stone(client):
    rng = np.random.default_rng(0)
    tray = np.clip(205 + rng.normal(0, 8, (600, 800, 3)), 0, 255).astype(np.uint8)
    r = post_image(client, tray)
    assert_rejected(r, "no_stone")
    assert "stone_tray_contrast_de00" in r.json()["diagnostics"]


def test_gate_not_blue(client):
    img = np.full((600, 800, 3), 205, np.uint8)
    cv2.circle(img, (400, 300), 120, (30, 40, 170), -1)      # red disc (BGR)
    cv2.circle(img, (370, 270), 30, (70, 90, 210), -1)
    r = post_image(client, img)
    d = r.json()["diagnostics"]
    if d.get("hue_gate_skipped"):
        pytest.skip("segmentation unreliable on this synthetic image")
    assert_rejected(r, "not_blue")


def test_gate_bypass_development_only(client):
    from app.config import get_settings
    rng = np.random.default_rng(0)
    tray = np.clip(205 + rng.normal(0, 8, (600, 800, 3)), 0, 255).astype(np.uint8)
    ok, enc = cv2.imencode(".jpg", tray)
    r = client.post("/grade", files={"image": ("x.jpg", enc.tobytes(), "image/jpeg")},
                    data={"gates": "false", "debug": "true"})
    assert r.status_code == 200
    b = r.json()
    if not get_settings().is_production:
        assert b["status"] == "ok"
        assert "no_stone" in b["debug"]["gates_bypassed"]
    else:
        assert b["status"] == "no_stone"
