"""Smoke tests: run inside the container with `python -m pytest -q tests`."""
import json

import cv2
import numpy as np
import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def blue_disc_jpeg():
    """Synthetic stone: a blue disc on a light grey background."""
    img = np.full((600, 800, 3), 205, np.uint8)
    cv2.circle(img, (400, 300), 120, (160, 70, 30), -1)     # BGR
    cv2.circle(img, (370, 270), 30, (200, 120, 70), -1)      # facet highlight
    ok, enc = cv2.imencode(".jpg", img)
    assert ok
    return enc.tobytes()


def post_grade(client, **form):
    files = {"image": ("stone.jpg", blue_disc_jpeg(), "image/jpeg")}
    return client.post("/grade", files=files, data=form)


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
    b = r1.json()
    assert b["status"] == "ok"
    assert 1 <= b["grade"] <= 7 and 1 <= b["second_grade"] <= 7
    assert b["grade"] != b["second_grade"]
    assert len(b["probabilities"]) == 7
    assert abs(sum(b["probabilities"]) - 1.0) <= 1e-4
    assert b["uncertainty"] > 0
    assert b["calibration_mode"] == "training_session"
    assert b["colour"]["hex"].startswith("#") and len(b["colour"]["hex"]) == 7
    for k in ("blur_variance", "stone_area_fraction", "hue_physical", "ood_distance", "ood_threshold"):
        assert k in b["diagnostics"]

    r2 = post_grade(client)
    assert r2.status_code == 200
    assert r2.json()["grade"] == b["grade"]


def test_grade_with_patches(client):
    patches = [[250, 250, 250], [10, 10, 10], [118, 118, 118],
               [186, 186, 186], [5, 60, 140], [170, 55, 60]]
    r = post_grade(client, patches=json.dumps(patches), referral_threshold="0.5")
    assert r.status_code == 200, r.text
    assert r.json()["calibration_mode"] == "session_patches"


def test_bad_inputs(client):
    r = client.post("/grade", files={"image": ("x.jpg", b"not an image", "image/jpeg")})
    assert r.status_code == 400
    r = post_grade(client, patches="[[1,2,3]]")
    assert r.status_code == 400
    r = post_grade(client, referral_threshold="0.95")
    assert r.status_code == 400
    big = b"\xff\xd8\xff" + b"\0" * (15 * 1024 * 1024 + 10)
    r = client.post("/grade", files={"image": ("big.jpg", big, "image/jpeg")})
    assert r.status_code == 413
