# GemEye Backend

Python REST API for the GemEye app: the inference server (FastAPI + Docker,
Phases 1-3); from Phase 4a, Firebase authentication, MongoDB Atlas storage
of users, gradings, rejections and calibrations, and private S3 image storage;
from Phase 4b, certificates with public verification, account deletion, remote
config and feedback. The Flutter app talks to this API over HTTPS
only; it never connects to MongoDB directly.

## Folders

| Folder | Purpose |
|--------|---------|
| `app/` | API source code (`main.py`, `routers.py`, `certificates.py`, `auth.py`, `errors.py`, `db.py`, `storage.py`, `config.py`, `assets.py`, `schemas.py`, `pipeline/`) |
| `models/` | v3 model files: `efficientnet_v3.keras`, `rf_model_v3.pkl`, `scaler_v3.pkl`, `config_v3.json` (local only) |
| `export/` | Phase 0 training exports: manifest, extra, gate/OOD stats, grade profiles |
| `secrets/` | Service account files (local only) |
| `tests/` | pytest suite, Firebase test-user helper, parity and gate scripts |

## Run

```
cp .env.example .env      # fill in values; never commit .env
docker compose up --build -d
curl http://localhost:8000/health
docker compose exec -e ENV=test api python -m pytest -q tests
```

Tests must run with `ENV=test`; they create temporary Firebase users and remove
all `gemeye_test` data and `test/` S3 objects at the end.

The compose file is for development: `./app` is mounted with `uvicorn --reload`;
`models/`, `export/` and `secrets/` are mounted read-only. Models load once at
startup (about 20-30 s).

## Environment

Pinned to the v3 training environment (`export/export_manifest.json`): Python
3.13 (`python:3.13-slim`), tensorflow-cpu 2.20.0, keras 3.13.2, numpy 2.1.3,
scikit-learn 1.6.1, joblib 1.6.0, colour-science 0.4.7. OpenCV: training used
4.14.0; the image installs `opencv-python-headless` 4.14.0.94 (same OpenCV
4.14.0 library, headless build). No other deviations.

## Environments

`ENV` selects the database and the S3 key prefix:

| ENV | MongoDB database | S3 prefix | debug / gates=false |
|-----|------------------|-----------|---------------------|
| `development` | `gemeye_dev` | `dev/` | allowed (with auth) |
| `test` | `gemeye_test` | `test/` | allowed (with auth) |
| `production` | `gemeye` | (none) | ignored |

Settings (`app/config.py`, from `.env`): `MONGODB_URI`, `AWS_REGION`,
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET`, `FIREBASE_CREDENTIALS`
(service account JSON path), `FIREBASE_WEB_API_KEY` (tests only), `ENV`.
Secrets are `SecretStr`; startup logs only "set"/"missing" for each.

## Auth

Every endpoint except `GET /health`, `GET /config` and `GET /public/v/{slug}`
needs `Authorization: Bearer <Firebase ID token>`. Any failure is HTTP 401
`{status: "error", detail: "Authentication required."}`. There is no bypass.

- `/grade` and all read endpoints: `verify_id_token(check_revoked=False)`, a local
  signature check against Google's cached public certs (no network call per request).
- `PUT /me`, `DELETE /me`, `POST /certificates`, `POST /certificates/{no}/revoke`
  and `POST /certificates/{no}/pdf`: `check_revoked=True` (one call to Firebase).
- `DELETE /me` also needs a recent sign-in: the token's `auth_time` must be within
  the last 5 minutes, else 401 `{status: "error", code: "reauth_required", ...}`.
- Without the revocation check, a revoked or deleted user's token is still accepted
  by the other endpoints until it expires (at most 1 hour).

The user record is created on the first `/grade`, `/me` or `/calibrations` request.

## Endpoints

`GET /health` (public) - `{status, model_version, models_loaded, versions, ciecam02_display_available}`.
`versions` are the versions installed in the container.

`POST /grade` (multipart/form-data)

| Field | Required | Notes |
|-------|----------|-------|
| `image` | yes | JPEG or PNG, at most 15 MB |
| `patches` | no | JSON 6x3, 0-255, order: white, black, grey_18, grey_50, blue, red |
| `referral_threshold` | no | 0.40-0.90; default is the user's `settings.referral_threshold` (0.60) |
| `session_id` | no | calibration session id, stored as `calibration_session_id` |
| `app_version`, `device` | no | stored with the grading or rejection |
| `debug`, `gates` | no | development/test only (see Environments) |

On `status: "ok"` the original upload is stored in S3 and a grading is saved; the
response adds `grading_id`, `stone_id` (`GE-STONE-NNNNN`, global counter `stone`)
and `image_url` (presigned GET, 10 minutes). The S3 upload and the MongoDB insert
(stone counter + grading) run concurrently; the response is sent only when both
succeeded. If either fails, the other is undone and the response is 500. On a gate
rejection only a `rejections` record (diagnostics, no image) is written. While
`maintenance.enabled` is true in the remote config, `/grade` returns 503
`{status: "error", code: "maintenance", message}`.

Response (`status: "ok"`): `status, warnings[], grade, grade_name, trade_name, probabilities[7], confidence,
uncertainty, referred, second_grade, colour{L,a,b,C,H,S,B,hex,ciecam02,approximate}, delta_e00_to_typical,
calibration_mode, model_version, timings_ms{total,preprocess,rf,cnn}, diagnostics{...}`.
`warnings` may contain `unusual_image` (OOD distance between OOD_WARN and OOD_REJECT).

Quality gates (Phase 3, thresholds in `app/gates.py`, provisional, tune in Phase 7) run in
this order and stop at the first failure: `invalid_image` (undecodable or short side
< 300 px), `no_stone`, `blurry`, `not_blue` (skipped when segmentation is unreliable;
`diagnostics.hue_gate_skipped`), `not_recognised` (OOD). A rejection is HTTP 200 with
`status` = the code, a short `message` and the diagnostics measured up to that gate; it
has no grade or probabilities. Test results: `tests/gates/gates_report.md`
(`docker compose exec api python tests/gates/run_gates.py`).

`hue_wb` and `chroma_wb` are the tray white-balanced stone hue and C*.
`segmentation_reliable` is false when GrabCut used either fallback (saturation
mask or centre box) on the tray white-balanced image; `colour.approximate` is its negation.

Other endpoints (all authenticated, own records only):

| Method | Path | Notes |
|--------|------|-------|
| GET | `/me` | profile + settings + `email_verified` |
| PUT | `/me` | partial update of `display_name, account_type (individual/company), country, phone, company{name, reg_no, industry, address, logo_key}, settings{show_name_on_certificates, referral_threshold 0.40-0.90}`; unknown fields (including `role`, `email`) are ignored |
| GET | `/gradings` | `limit` (1-50, default 20), `cursor`, `grade` (1-7), `referred`, `from`, `to` (ISO 8601); newest first, not deleted, each with a fresh `image_url`; `{items, next_cursor}` |
| GET | `/gradings/{id}` | one grading |
| DELETE | `/gradings/{id}` | deletes the S3 image, sets `deleted: true`; 204 |
| POST | `/calibrations` | `{session_id, valid_until?, device?, ccm 3x3, residual?, quality?, measured_patches 6x3}`; 201 |
| GET | `/calibrations` | newest first, at most 50 |
| DELETE | `/me` | deletes the account (recent sign-in required, see Auth and below); 204 |
| POST | `/feedback` | `{rating 1-5, category accuracy/app/calibration/other, comment? <= 500, app_version? <= 50}`; 201 `{feedback_id, created_at}` |
| POST | `/certificates` | `{grading_id}` (own, not deleted, status ok); 201 `{cert_no, verify_url, issued_at}`, or 200 with the existing valid certificate |
| GET | `/certificates` | own certificates, newest first (`limit` 1-100, default 50) |
| GET | `/certificates/{cert_no}` | own certificate with `verify_url`, snapshot, owner, PDF hash, revocation |
| POST | `/certificates/{cert_no}/pdf` | multipart `file`, `application/pdf`, at most 5 MB; once only (409 afterwards); 201 |
| POST | `/certificates/{cert_no}/revoke` | `{reason}` (1-500 chars), owner only (admin in Phase 10); 409 if not valid |

Public endpoints (no auth):

| Method | Path | Notes |
|--------|------|-------|
| GET | `/config` | remote config (below), cached 60 s in memory |
| GET | `/public/v/{slug}` | certificate verification (below); 30 requests/minute per IP |

Another user's id always gives 404 (never 403), so ids cannot be enumerated.

Errors: 400 invalid input (not a JPEG/PNG signature, bad form fields or JSON),
401 not authenticated, 404 not found, 409 conflict (PDF already uploaded,
certificate not valid), 413 file too large, 429 rate limited, 503 storage
unavailable or maintenance, 500 generic. Error bodies are `{status: "error", detail}`
(plus `code` and `message` for `reauth_required` and `maintenance`) with no stack traces.

## Certificates and verification

1. The app grades a stone, then calls `POST /certificates {grading_id}` on the
   first export. A grading that already has a valid certificate gets the same one
   back, so re-exports reuse the number. A revoked certificate is not reused.
2. `cert_no` is `GE-YYYYMM-NNNNN`: the month is the issue time in Asia/Colombo and
   NNNNN comes from the atomic counter `cert-YYYYMM` (restarts each month).
3. The certificate stores a frozen snapshot: `stone_id, grade, grade_name,
   trade_name, confidence, uncertainty, referred, colour` (including CIECAM02 and
   `approximate`), `delta_e00_to_typical, model_version, captured_at, issued_at`
   and `calibration {session_id, residual}` when the grading had a session. The
   owner's display name and company name are included only if
   `settings.show_name_on_certificates` was true at issue time.
4. A random token (`secrets.token_urlsafe(12)`) is generated per certificate. The
   verify link is `https://gemeye-app-2026.web.app/v/{cert_no}-{token}`; only the
   owner can read the token (in `verify_url`).
5. The app renders the PDF and uploads it once with `POST /certificates/{no}/pdf`;
   the API stores `certificates/{cert_no}.pdf` and its SHA-256.
6. The verification page calls `GET /public/v/{cert_no}-{token}`. The slug must
   match `^(GE-\d{6}-\d{5})-(.+)$`; the token is checked with
   `secrets.compare_digest` (on SHA-256 digests). An unknown number, a wrong token
   or a malformed slug all give the same 404 body. Responses have
   `Cache-Control: no-store`; CORS is allowed for this route only, from
   `https://gemeye-app-2026.web.app` and `http://localhost:3000`. The rate limit
   (slowapi, in memory, per process) keys on the client address; behind a proxy it
   must be configured to use the forwarded address.
7. The response: `cert_no, status` (valid/revoked/withdrawn), `issued_at, snapshot,
   owner` (only if allowed), `revoked_reason, revoked_at, image_url, pdf_url,
   pdf_sha256, disclaimer`. It never contains the uid or email. Presigned URLs last
   10 minutes. The grading photo's S3 key contains the uid, so at issue time the
   photo is copied (server side) to `certificates/{cert_no}.jpg` and the public
   page links the copy.
8. Deleting a grading deletes its photo and these copies; its certificates stay,
   and the public page shows no photo.

## Account deletion (DELETE /me)

Deletes the user's gradings and their S3 images, calibrations, rejections,
feedback, certificate PDFs and photo copies, the `users` document and the
Firebase user (admin SDK). Certificates become `status: "withdrawn"`,
`revoked_reason: "Owner account deleted"`; the snapshot, owner, uid, grading id
and token are removed. Only `cert_no, issued_at, status`, the reason,
`withdrawn_at` and the token's SHA-256 remain, so old verify links show
"withdrawn" instead of a 404. An `audit_log` entry
`{action: "account_deleted", uid_hash: sha256(uid), at}` is written. Returns 204.

## Remote config

`app_config/"global"` is created with these defaults at startup if missing; fields
missing from the stored document fall back to the defaults:

```
referral_threshold_default: 0.60, calibration_validity_hours: 8, min_app_version: "1.0.0",
maintenance: {enabled: false, message: ""},
features: {repeatability_mode: true, gradcam: false, public_verification: true}
```

Edit the document in MongoDB to change it; each process picks it up within 60 s.

## Data model (MongoDB, all timestamps UTC)

| Collection | Fields | Indexes |
|------------|--------|---------|
| `users` | `_id` (Firebase uid), `email, display_name, account_type, role` ("user", server-set), `country, phone, company{name, reg_no, industry, address, logo_key}, settings{show_name_on_certificates: false, referral_threshold: 0.60}, created_at, updated_at` | `_id` |
| `gradings` | `_id, uid, stone_id, created_at, status: "ok", result` (grade response without debug), `image_key, calibration_session_id, app_version, device, referral_threshold_used, deleted` (+ `deleted_at`) | `(uid, created_at desc)` |
| `rejections` | `_id, uid, created_at, status, message, diagnostics, app_version, device` (no image, privacy decision option 1) | `created_at` |
| `calibrations` | `_id, uid, session_id, created_at, valid_until, device, ccm, residual, quality, measured_patches` | `(uid, created_at desc)` |
| `counters` | `_id` (counter name: `stone`, `cert-YYYYMM`), `seq`; atomic `find_one_and_update($inc, upsert)` | `_id` |
| `certificates` | `_id` (cert_no), `uid, grading_id, token, token_sha256, status` (valid/revoked/withdrawn), `issued_at, snapshot, owner, image_key, pdf_key, pdf_sha256, pdf_uploaded_at, revoked_reason, revoked_at` (+ `withdrawn_at`) | `(uid, issued_at desc)`, unique `grading_id` where `status: "valid"` |
| `feedback` | `_id, uid, created_at, rating, category, comment, app_version` | `(uid, created_at desc)` |
| `app_config` | `_id: "global"`, remote config (above) | `_id` |
| `audit_log` | `_id, action, uid_hash, at` | - |

S3 (private bucket, SSE-S3): `<prefix>gradings/{uid}/{grading_id}.jpg` (`.png`
for PNG uploads). Only the original upload of a graded stone is stored.
`<prefix>certificates/{cert_no}.pdf` is the certificate PDF and
`<prefix>certificates/{cert_no}.jpg` the photo copy for the public page.

## The two colour paths

1. **Model path** (must equal training). If `patches` are sent, a 3x3 session map
   `A = lstsq(P_user/255, P_train/255)` (no offset) maps this session to the
   training session (`calibration_mode: "session_patches"`); otherwise A is the
   identity (`"training_session"`). Then the training CCM is applied exactly as
   in training, `clip(rgb/255 @ CCM, 0, 1)*255 -> uint8`, followed by the same
   JPEG round trip (`cv2.imencode('.jpg')` at default quality, then decode).
   The RF features (v3 GrabCut + 12-D) and the CNN input both come from this image.
2. **Display path** (tray white balance, `export_wb.json` method,
   `pipeline/display.py tray_balanced_measure`). The raw upload is resized to 256 px,
   GrabCut (seed 42) finds the stone, the tray is the non-stone pixels at least 8 px
   from the stone in the brightest 50% V, and each channel is scaled so the tray
   median becomes 229.5. L*, a*, b*, C*, H, S, B, hex, CIECAM02, ΔE00 to the predicted
   grade's typical colour (`grade_profiles_wb` median) and the gate hue, chroma and
   stone-tray contrast all come from this image. Patches do not change it. The
   earlier affine display path is superseded (commented out in `pipeline/colour.py`).

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
