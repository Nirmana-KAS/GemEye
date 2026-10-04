# GemEye Backend

Python REST API for the GemEye app. Phase 1 is the inference server (FastAPI +
Docker, local). Later phases add storage of users, grades, certificates and
feedback (MongoDB Atlas, AWS S3). The Flutter app talks to this API over HTTPS
only; it never connects to MongoDB directly.

## Folders

| Folder | Purpose |
|--------|---------|
| `app/` | API source code (`main.py`, `config.py`, `assets.py`, `schemas.py`, `pipeline/`) |
| `models/` | v3 model files: `efficientnet_v3.keras`, `rf_model_v3.pkl`, `scaler_v3.pkl`, `config_v3.json` (local only) |
| `export/` | Phase 0 training exports: manifest, extra, gate/OOD stats, grade profiles |
| `secrets/` | Service account files (local only) |
| `tests/` | Smoke tests |

## Run

```
cp .env.example .env      # fill in values; never commit .env
docker compose up --build -d
curl http://localhost:8000/health
docker compose exec api python -m pytest -q tests
```

The compose file is for development: `./app` is mounted with `uvicorn --reload`;
`models/`, `export/` and `secrets/` are mounted read-only. Models load once at
startup (about 20-30 s).

## Environment

Pinned to the v3 training environment (`export/export_manifest.json`): Python
3.13 (`python:3.13-slim`), tensorflow-cpu 2.20.0, keras 3.13.2, numpy 2.1.3,
scikit-learn 1.6.1, joblib 1.6.0, colour-science 0.4.7. OpenCV: training used
4.14.0; the image installs `opencv-python-headless` 4.14.0.94 (same OpenCV
4.14.0 library, headless build). No other deviations.

## Endpoints

`GET /health` - `{status, model_version, models_loaded, versions, ciecam02_display_available}`.
`versions` are the versions installed in the container.

`POST /grade` (multipart/form-data)

| Field | Required | Notes |
|-------|----------|-------|
| `image` | yes | JPEG or PNG, at most 15 MB |
| `patches` | no | JSON 6x3, 0-255, order: white, black, grey_18, grey_50, blue, red |
| `referral_threshold` | no | 0.40-0.90, default 0.60 |

Response: `status, grade, grade_name, trade_name, probabilities[7], confidence,
uncertainty, referred, second_grade, colour{L,a,b,C,H,S,B,hex,ciecam02,approximate}, delta_e00_to_typical,
calibration_mode, model_version, timings_ms{total,preprocess,rf,cnn},
diagnostics{blur_variance, stone_area_fraction, hue_physical, hue_gate_min,
hue_gate_max, hue_in_gate, segmentation_reliable, ood_distance, ood_threshold}`.

`hue_physical` is the display-path hue. The hue gate (`HUE_GATE_MIN/MAX` = 170-265 degrees
in `pipeline/inference.py`) is provisional and will be tuned in Phase 7.
`segmentation_reliable` is false when GrabCut used either fallback (saturation
mask or centre box) on the display-path image; `colour.approximate` is its negation.

Errors: 400 invalid input, 413 image too large, 500 generic. Error bodies are
`{status: "error", detail}` with no stack traces. Images are never stored
(uploads stay in memory).

Diagnostics are reported only; nothing is rejected yet (Phase 3).

## The two colour paths

1. **Model path** (must equal training). If `patches` are sent, a 3x3 session map
   `A = lstsq(P_user/255, P_train/255)` (no offset) maps this session to the
   training session (`calibration_mode: "session_patches"`); otherwise A is the
   identity (`"training_session"`). Then the training CCM is applied exactly as
   in training, `clip(rgb/255 @ CCM, 0, 1)*255 -> uint8`, followed by the same
   JPEG round trip (`cv2.imencode('.jpg')` at default quality, then decode).
   The RF features (v3 GrabCut + 12-D) and the CNN input both come from this image.
2. **Display path** (physical colour). A 4x3 affine correction with offset is
   fitted from the user's patches to the CCC reference RGB (or the exported
   `ccm_affine_4x3` if no patches). L*, a*, b*, C*, H, S, B, hex, CIECAM02 and
   ΔE00 to the predicted grade's typical colour come from this image.

## Inference

- CNN: 224x224 `tf.image.resize`, EfficientNet `preprocess_input`.
- MC Dropout: Dropout exists only in the classification head, so the EfficientNet
  backbone + global pooling run once (inference mode) and only the head runs 30
  times as one batch; only the Dropout layers are active, BatchNorm stays in
  inference mode. Dropout masks use a fixed
  stateless seed, so the same image always gives the same result. Uncertainty
  is the std across the 30 passes of the expected grade sum(k * p_k).
- RF: `scaler.transform` -> `predict_proba`.
- Ensemble: `w_cnn * MC mean + (1 - w_cnn) * RF`, `w_cnn = 0.6` from `config_v3.json`.
- OOD: Mahalanobis distance of the 256-D `dense` features (deterministic pass)
  against `ood_stats.npz`; threshold is the validation p99.

## CIECAM02 note

The v3 training code called a CIECAM02 function that does not exist in
colour-science 0.4.7, so every training image used the fallback
J=L, M=C, h=H, s=S, C_cam=C (912/912 fallbacks). The RF learned on those
values, so the model path reproduces the fallback. Real CIECAM02
(`colour.XYZ_to_CIECAM02`, XYZ 0-100, L_A=64, Y_b=20, Average surround) is used
only for the display values. If the export reports NaNs, the API returns
`ciecam02: null`.

## Never commit

- `.env`
- anything in `models/` (except `.gitkeep`)
- anything in `secrets/` (except `.gitkeep`)
