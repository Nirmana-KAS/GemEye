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
- Token times (`iat`, `exp`) allow 5 s of clock skew, so a token used right after
  sign-in is not rejected as "used too early" when the server clock lags slightly.
- `PUT /me`, `DELETE /me`, `POST /certificates`, `POST /certificates/{no}/revoke`
  and `POST /certificates/{no}/pdf`: `check_revoked=True` (one call to Firebase).
- `DELETE /me` also needs a recent sign-in: the token's `auth_time` must be within
  the last 5 minutes, else 401 `{status: "error", code: "reauth_required", ...}`.
- Deleted accounts: `DELETE /me` revokes the user's refresh tokens and writes
  `deleted_accounts {_id: sha256(uid), deleted_at}` (TTL index, expires after 2 hours,
  well beyond the 1-hour ID token life). Every write or user-creating request
  (`/grade`, `GET`/`PUT /me`, `POST /calibrations`, `POST /feedback`, `POST /certificates`,
  PDF upload, revoke) checks it first, so a deleted user's still-valid token gets 401
  `{status: "error", code: "account_deleted", ...}` and can never re-create the user.
  Other reads still accept such a token until it expires (at most 1 hour); the
  user's data is already gone.

The user record is created on the first `/grade`, `/me` or `/calibrations` request.

## Endpoints

`GET /health` (public) - `{status, model_version, models_loaded, versions, ciecam02_display_available}`.
`versions` are the versions installed in the container.

`POST /grade` (multipart/form-data)

| Field | Required | Notes |
|-------|----------|-------|
| `image` | yes | JPEG or PNG, at most 15 MB |
| `patches` | no | JSON 6x3, 0-255, order: white, black, grey_18, grey_50, blue, red. Always stored with the grading; used for the model path only when `features.session_mapping` is true |
| `referral_threshold` | no | 0.40-0.90; default is the user's `settings.referral_threshold` (0.60) |
| `session_id` | no | calibration session id, stored as `calibration_session_id` |
| `app_version`, `device` | no | stored with the grading or rejection |
| `request_id` | no | UUID chosen by the app per grading attempt. A repeated `request_id` from the same user returns the original grading (same `grading_id`, `stone_id`, fresh `image_url`) without grading or storing again; from another user, or for a deleted grading, 409 `{code: "duplicate_request"}`; not a UUID, 400. Unique sparse index `gradings.request_id`; a concurrent duplicate also returns the original |
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
| DELETE | `/gradings/{id}` | deletes the S3 image and Grad-CAM PNG, sets `deleted: true`; 204 |
| POST | `/gradings/{id}/heatmap` | Grad-CAM of the CNN branch (Phase 8): `{url (presigned 10 min), method: "gradcam_cnn_branch", target_grade, stone_mask_heat_fraction}`; own grading only, else 404; 404 if the photo is gone; 503 `maintenance` |
| POST | `/calibrations` | `{session_id, valid_until?, device?, ccm 3x3, residual?, quality?, measured_patches 6x3}`; 201 |
| GET | `/calibrations` | newest first, at most 50 |
| DELETE | `/me` | deletes the account (recent sign-in required, see Auth and below); 204 |
| POST | `/feedback` | `{rating 1-5, category accuracy/app/calibration/other, comment? <= 500, app_version? <= 50}`; 201 `{feedback_id, created_at}` |
| POST | `/certificates` | `{grading_id}` (own, not deleted, status ok); 201 `{cert_no, verify_url, issued_at}`, or 200 with the existing valid certificate |
| GET | `/certificates` | own certificates, newest first (`limit` 1-100, default 50) |
| GET | `/certificates/{cert_no}` | own certificate with `verify_url`, snapshot, owner, PDF hash, revocation |
| POST | `/certificates/{cert_no}/pdf` | multipart `file`, `application/pdf`, at most 5 MB; once only (409 afterwards); 201 |
| POST | `/certificates/{cert_no}/revoke` | `{reason}` (1-500 chars), owner only (admins: `/admin/certificates/{cert_no}/revoke`); 409 if not valid |

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
   `https://gemeye-app-2026.web.app`, `http://localhost:3000` and the origin of the
   configured `verify_base_url` (e.g. `http://192.168.1.20:3000` for a phone on the
   same Wi-Fi), also on 404/429 and preflight. The rate limit
   (slowapi, in memory, per process) keys on the client address; behind a proxy it
   must be configured to use the forwarded address.
7. The response: `cert_no, status` (valid/revoked/withdrawn), `issued_at, snapshot,
   owner` (only if allowed), `revoked_reason, revoked_at, superseded_by,
   superseded_by_url` (the replacement's verify link, only when it is a valid
   certificate of the same owner), `review` (`{gemologist_grade, reviewed_at}`,
   unusable reviews left out), `image_url, pdf_url, pdf_sha256, disclaimer`. It never contains the uid or email. Presigned URLs last
   10 minutes. The grading photo's S3 key contains the uid, so at issue time the
   photo is copied (server side) to `certificates/{cert_no}.jpg` and the public
   page links the copy.
8. Deleting a grading deletes its photo and these copies; its certificates stay,
   and the public page shows no photo.

## Account deletion (DELETE /me)

Deletes the user's gradings and their S3 images, calibrations, rejections,
feedback, notifications, certificate PDFs and photo copies, the `users` document and the
Firebase user (admin SDK). Certificates become `status: "withdrawn"`,
`revoked_reason: "Owner account deleted"`; the snapshot, owner, uid, grading id
and token are removed. Only `cert_no, issued_at, status`, the reason,
`withdrawn_at` and the token's SHA-256 remain, so old verify links show
"withdrawn" instead of a 404. An `audit_log` entry
`{action: "account_deleted", uid_hash: sha256(uid), at}` is written. Before any data
is deleted, a `deleted_accounts` tombstone is written and the user's refresh tokens
are revoked (see Auth). Returns 204.

## Remote config

`app_config/"global"` is created with these defaults at startup if missing; fields
missing from the stored document fall back to the defaults:

```
referral_threshold_default: 0.60, calibration_validity_hours: 24, min_app_version: "1.0.0",
update_message: "", maintenance: {enabled: false, message: ""},
features: {repeatability_mode: true, gradcam: true, public_verification: true,
           session_mapping: false}
```

`GET /config` also returns `blur_min_variance` (the `blurry` gate threshold from
`app/gates.py`, not stored in MongoDB) so the app's Photo Check uses the same value.

`features.session_mapping`: when false (default), `/grade` ignores `patches` for the
model path and uses the training session (`calibration_mode: "training_session"`);
the patches are still stored with the grading. When true, sent patches give
`calibration_mode: "session_patches"`.

Edit the document in MongoDB to change it; each process picks it up within 60 s.

## Data model (MongoDB, all timestamps UTC)

| Collection | Fields | Indexes |
|------------|--------|---------|
| `users` | `_id` (Firebase uid), `email, display_name, account_type, role` ("user", server-set), `country, phone, company{name, reg_no, industry, address, logo_key}, settings{show_name_on_certificates: false, referral_threshold: 0.60}, created_at, updated_at`, `daily_grading_limit` (admin-set, 1-500 or null) | `_id` |
| `gradings` | `_id, uid, stone_id, created_at, status: "ok", result` (grade response without debug), `image_key, calibration_session_id, patches` (6x3 or null), `request_id` (only if sent), `app_version, device, referral_threshold_used, deleted` (+ `deleted_at`); Phase 10p: `hidden` (+ `hidden_reason, hidden_at, hidden_by_hash`), `review_requested {reason: "admin", note, at, by_hash}`, `regrades[]` (last 20) | `(uid, created_at desc)`, unique sparse `request_id`, `(hidden, created_at desc)` |
| `rejections` | `_id, uid, created_at, status, message, diagnostics, app_version, device` (no image, privacy decision option 1) | `created_at` |
| `calibrations` | `_id, uid, session_id, created_at, valid_until, device, ccm, residual, quality, measured_patches` (+ `invalidated_at, invalidated_reason, invalidated_by_hash` when support reset it) | `(uid, created_at desc)` |
| `counters` | `_id` (counter name: `stone`, `cert-YYYYMM`), `seq`; atomic `find_one_and_update($inc, upsert)` | `_id` |
| `certificates` | `_id` (cert_no), `uid, grading_id, token, token_sha256, status` (valid/revoked/withdrawn), `issued_at, snapshot, owner, image_key, pdf_key, pdf_sha256, pdf_uploaded_at, revoked_reason, revoked_at` (+ `withdrawn_at`) | `(uid, issued_at desc)`, unique `grading_id` where `status: "valid"` |
| `feedback` | `_id, uid, created_at, rating, category, comment, app_version` | `(uid, created_at desc)` |
| `app_config` | `_id: "global"`, remote config (above) | `_id` |
| `audit_log` | `_id, action, uid_hash, at` | - |
| `deleted_accounts` | `_id` (sha256(uid)), `deleted_at` | TTL on `deleted_at`, 2 hours |
| `notifications` | `_id` (app or server uuid), `uid, type, category, title, message, action, payload, source` (app/server/admin), `created_at, read_at, cleared_at, restored_at, restored_by`; admin sends add `sent_by` (admin uid) and `broadcast_id` | `(uid, created_at desc)`, `(uid, cleared_at)`, `(created_at desc, _id desc)`, `(source, created_at desc)` |
| `admin_broadcasts` | `_id, target` (user/all), `uid` (target user), `count, title, type, category, action, sent_by` (admin uid), `at` | `(at desc, _id desc)`, `(target, at desc)` |
| `admin_directory` | `_id` (sha256 of a dashboard user's uid), `email, role, seen_at`; written on their first `/admin/*` call per process so the audit log can show who acted | `_id` |
| `admin_notes` | `_id, uid, text` (<= 1000), `author_hash, at`; admin only, never in a `/me` route; deleted with the account | `(uid, at desc)` |
| `blocked_devices` | `_id` (device_id: sha256 of the X-Device-Id install UUID, or of the model name for old builds; 24 hex), `device_model, reason, blocked_at, blocked_by_hash` | `_id` |
| `revoked_sessions` | `_id` (sha256(uid)), `valid_after_s, at`: tokens with an older `auth_time` get 401 `token_revoked` | `_id` |

S3 (private bucket, SSE-S3): `<prefix>gradings/{uid}/{grading_id}.jpg` (`.png`
for PNG uploads). Only the original upload of a graded stone is stored.
`<prefix>certificates/{cert_no}.pdf` is the certificate PDF and
`<prefix>certificates/{cert_no}.jpg` the photo copy for the public page.

## The two colour paths

1. **Model path** (must equal training). If `patches` are sent, a 3x3 session map
   `A = lstsq(P_user/255, P_train/255)` (no offset) maps this session to the
   training session (`calibration_mode: "session_patches"`, only while
   `features.session_mapping` is true); otherwise A is the
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

## Grad-CAM heatmap (Phase 8)

`app/pipeline/gradcam.py`. Explanation aid only; it never changes a grade.

- The stored original is loaded from S3 and the CNN input is rebuilt exactly as `/grade` built it,
  with the grading's own `result.calibration_mode` (`session_patches` replays the stored patches;
  the current `features.session_mapping` flag is never used).
- Grad-CAM on `top_activation` (last conv activation of the nested EfficientNet-B0), deterministic
  model (Dropout off, BatchNorm inference), gradient of the target class logit; target class = the
  grading's final grade. A `None` gradient raises.
- The map is normalised to [0, 1], upsampled to the display image (longer side at most 640 px) and
  overlaid with jet at alpha 0.4 on the tray-balanced image (gain from `tray_balanced_measure`).
- `stone_mask_heat_fraction`: share of the total heat inside the GrabCut stone mask (256 px, seed 42).
- The PNG is stored at `gradings/{uid}/{id}_cam.png` and reused (`gradings.heatmap`); it is deleted
  with the grading and with the account (`DELETE /me` deletes `gradings/{uid}/`).
- Stats over the 112 test images: `docker compose exec api python tests/parity/run_gradcam_stats.py`
  (writes `tests/parity/gradcam_stats_report.md`: stone area, heat share and heat/area, overall
  and per grade, with an interpretation note).

## CIECAM02 note

The v3 training code called a CIECAM02 function that does not exist in
colour-science 0.4.7, so every training image used the fallback
J=L, M=C, h=H, s=S, C_cam=C (912/912 fallbacks). The RF learned on those
values, so the model path reproduces the fallback. Real CIECAM02
(`colour.XYZ_to_CIECAM02`, XYZ 0-100, L_A=64, Y_b=20, Average surround) is used
only for the display values. If the export reports NaNs, the API returns
`ciecam02: null`.

## QA token for /docs

`scripts/get_token.py` prints a Firebase ID token for a QA account (local
development only; refuses `ENV=production`). The password is prompted without
echo. Paste the token into Authorize on http://localhost:8000/docs; it lasts 1 hour.

```
docker compose exec api python scripts/get_token.py --email qa@example.com
```

## Blur reference values (development)

`scripts/blur_variance.py <files>` prints the server blur variance of images,
decoded exactly as `/grade` decodes uploads. It produced the reference values in
`app/test/photo_check_test.dart` (fixtures in `app/test/fixtures/blur/`).

## Never commit

- `.env`
- anything in `models/` (except `.gitkeep`)
- anything in `secrets/` (except `.gitkeep`)

## Admin roles and admin read API (Phase 10a)

Two Firebase custom claims: `admin` (every `/admin/*` route) and `reviewer` (only
`GET /admin/gradings`, `/admin/gradings/{id}`, the review queue, `POST /admin/reviews` and `PUT` of their own review,
without user email or phone). Tokens
are checked with `check_revoked=True` and the deleted-account tombstone; a missing claim
is 403 `{code: "forbidden"}`. Rate limit 120 requests/min per uid (429). CORS is open only
to `http://localhost:3000` and `https://gemeye-app-2026.web.app`, and only on `/admin/*`, `/health` and `/announcements` (for the dashboard).
Responses never contain tokens, certificate tokens, verify URLs, storage keys or secrets.

Make the first admin (works in development and production, refuses `ENV=test`; the user
must sign in again to get the claim; use `--role none` to remove a role). The scripts in
`scripts/` add the backend root to `sys.path`, so no `PYTHONPATH` is needed:

```
docker compose exec api python scripts/set_role.py --email gemeyeapp@gmail.com --role admin
```

| Method | Path | Notes |
|--------|------|-------|
| GET | `/admin/stats/summary?days=1\|7\|30` | gradings, unique users, referral and rejection rates, rejections per status, `grade_distribution` (1-7), mean confidence / uncertainty / latency, certificates, feedback, server + DB status |
| GET | `/admin/stats/timeseries?metric=gradings\|rejections\|referral_rate\|avg_confidence&days=30&bucket=day` | Asia/Colombo days, gaps filled |
| GET | `/admin/users`, `/admin/users/{uid}` | `q` (email/name), `sort=created\|last_active`, `role=admin\|reviewer\|none`, `disabled=true\|false`, `limit`, `cursor`; rows have Firebase `role` and `disabled`; detail adds counts, last 10 gradings, calibrations, devices, `role`, `disabled` |
| GET | `/admin/gradings`, `/admin/gradings/{id}` | `from, to, grade, referred, model_version, uid, device, status`, cursor paging, fresh image URL; detail adds the full result, heatmap URL if cached, certificate and `review` (admin and reviewer) |
| GET | `/admin/calibrations`, `/admin/feedback`, `/admin/certificates`, `/admin/audit-log` | filters, cursor paging. Feedback: `status=open\|resolved`, rows with `user_email`. Certificates: number prefix (`q`), owner email contains (`email`), `status=valid\|revoked\|superseded\|withdrawn` (superseded = revoked with `superseded_by`), rows with `user_email`. Audit log: `action`, `admin` (email contains, or a uid_hash), `target` (any target id), rows with `admin_email` from `admin_directory` |
| GET | `/admin/model/monitoring?days=30&model_version=` | per model version: `summary` (gradings, avg confidence / uncertainty, referral rate, unusual images, rejections and rate per gate, avg and p95 latency, review agreement exact / within one / n) and every day of the range with the same values; rejections per day, gate and model version. `days` 1-90 (dashboard: 7, 30, 90) |

Admin writes (Phase 10b, below) call `audit(db, action, admin_uid, target, before, after)`,
which stores only the admin's `uid_hash` in `audit_log`; reads are not logged.

### Admin write API (Phase 10b)

Writes are admin-only unless marked `staff` (reviewer or admin). Every write calls
`audit()` with before/after values (never links, tokens, keys or emails). Unknown body
fields are rejected (400). An admin cannot disable, delete or demote their own account
(400 `self_action`). Disabled accounts get 401 `{code: "account_disabled"}` in the app.

| Method | Path | Notes |
|--------|------|-------|
| POST | `/admin/users/{uid}/disable`, `/enable` | Firebase `disabled` flag + token revoke; app calls get 401 `account_disabled` |
| POST | `/admin/users/{uid}/role` | `{role: admin\|reviewer\|none}`; tokens revoked when a role is removed or changed |
| POST | `/admin/users/{uid}/password-reset` | Firebase email template -> `{status: "sent"}`; if sending fails `{status: "link", link}` (admin only, never logged or audited) |
| DELETE | `/admin/users/{uid}` | same logic as `DELETE /me` (data, S3, certificates withdrawn, tombstone, Firebase user) |
| GET, PUT | `/admin/config` | partial update, strict bounds: `referral_threshold_default` 0.40-0.90, `calibration_validity_hours` 1-72, `min_app_version` semver, `maintenance {enabled, message<=200}`, `features {repeatability_mode, gradcam, public_verification, session_mapping}`, `verify_base_url` (https; http only for localhost or a private LAN IP, for phone tests; new certificates only), `update_message<=200` (shown with the update prompt), `gates` (below). GET also returns `gate_defaults`, `gate_bounds` and `bounds` (the other limits, for the dashboard form). Inconsistent gates: 400 `invalid_gates` |
| POST | `/admin/config/reset-gates` | restores the default gates |
| GET, POST | `/admin/announcements` | `{title<=80, message<=500, level info\|warning, starts_at?, ends_at, active, action?}` (`action` = app screen opened from the banner, default `none`); GET rows add `created_by_email` |
| PUT, DELETE | `/admin/announcements/{id}` | PUT replaces the editable fields |
| GET | `/admin/review-queue` (staff) | `status=pending` (referred, not yet reviewed) \| `mine` \| `reviewed`; `from, to, grade, model_version`, cursor paging; no user identity; photo and Grad-CAM URLs, probabilities, colour values, `referred_reasons`, `review` |
| POST | `/admin/reviews` (staff) | `{grading_id, gemologist_grade 1-7, reviewer_confidence?, unusable?, notes<=500}` (unusable = no grade, left out of agreement); 409 `already_reviewed` |
| PUT | `/admin/reviews/{grading_id}` (staff) | admin corrects any review, a reviewer only their own |
| GET | `/admin/reviews/stats` | agreement overall, per model grade, per model version, 7x7 confusion matrix (rows model, columns gemologist), pending |
| GET | `/admin/reviews/export` | CSV (grading_id, image_ref, model_grade, gemologist_grade, confidence, model_version, created_at, reviewer_confidence, unusable); no emails or uids |
| POST | `/admin/feedback/{id}/status` | `{status: open\|resolved, note<=300}` |
| GET | `/admin/certificates/{cert_no}` | detail with presigned PDF and photo URLs, `user_email` and `verify_url_masked` (the token is never returned) |
| POST | `/admin/certificates/{cert_no}/revoke` | `{reason}`; 409 if not valid |
| POST | `/admin/certificates/{cert_no}/supersede` | `{new_cert_no, reason}`; revokes and records the replacement, the public page shows "Replaced by <new_cert_no>" |

Editable gates (`app_config.gates`, cached 60 s; defaults are the original constants in
`app/gates.py`, so parity is unchanged): `blur_min_variance` 29.474 (5-200),
`no_stone_min_area` 0.01572 (0.002-0.05), `no_stone_min_contrast_de00` 5.0 (1-15),
`hue_min` 170 (100-200), `hue_max` 265 (230-320), `min_chroma` 0.5 (0-5), `ood_warn` 20.649
(5-60), `ood_reject` 25.685 (10-80); `hue_min < hue_max` and `ood_warn < ood_reject`.

Public: `GET /announcements` (active, inside the time window) and `GET /config`, which keeps
its fields and adds `gates` (effective values, read-only) and `announcements`. The owner's
`GET /gradings` and `/gradings/{id}` include `review {gemologist_grade, reviewed_at}` when
reviewed (no reviewer identity). Rejection records now store `model_version`;
`/admin/model/monitoring` groups rejections by version ("unknown" for old records) and adds
`review_agreement` per version and day.

## Notifications (Phase N1)

`app/notifications.py`. The app records every notification locally and syncs it with
`POST /me/notifications/sync` (idempotent on the app's uuid); `GET /me/notifications`
returns the visible ones (newest first, `unread_count`). Clearing (`/{id}/clear`,
`/clear-all`) only sets `cleared_at`: nothing is deleted except by `delete_account`.
`read-all` and `clear-all` take an optional `before` so a queued offline action does not
touch newer items. 120 requests/min per user; title <= 120, message <= 1000,
payload <= 200; another user's id is a 404.

Admins (not reviewers) list a user's notifications with
`GET /admin/users/{uid}/notifications?status=all|visible|cleared` and restore one
(`/{id}/restore`) or all (`/restore-all`); both are audited and the restored items show
again on the phone at its next refresh. `create_notification(db, uid, ...)` adds
`source: "server"` notifications for events the phone cannot know: admin certificate
revoke / supersede and role changes. Tests: `tests/test_notifications.py`.

### Admin send (Phase 10f)

| Method | Path | Notes |
|---|---|---|
| POST | `/admin/notifications/send` | `{target: user\|all, uid?, type, category?, title<=120, message<=1000, action?, payload<=200}` -> 201 `{id, target, count, at}`. `source: "admin"`, `sent_by` = admin uid. `all` = one document per user with a profile and no deletion tombstone, inserted in batches of 500. At most 5 sends to all per hour (all admins together, 429 `rate_limited`). Unknown or deleted uid: 404. Recorded in `admin_broadcasts`, audited `notification_send` |
| GET | `/admin/notifications/audience` | `{users}`: how many users a send to all reaches |
| GET | `/admin/notifications` | every user's notifications: `uid, status=all\|visible\|cleared\|read\|unread, source=app\|server\|admin, from, to, limit, cursor`; rows add `uid, user_email, sent_by_email` |
| GET | `/admin/broadcasts` | sent history (`target=user\|all`, cursor paging) with `user_email` and `sent_by_email` |

Validation errors (400) on `/admin/*` also return `fields: [{field, message}]` (the field path,
never the submitted value) so the dashboard can show them on the form field. Tests:
`tests/test_admin_notifications.py`.

## Admin powers (Phase 10p)

`app/admin_powers.py` (routes) and `app/limits.py` (checks used by `/grade` and
`/calibrations`). Admin only (reviewer 403), validated, rate-limited, audited with
before/after. Full table: `docs/GemEye_API_Reference.md`, "Admin powers".

| Area | Routes | Effect in the app |
|---|---|---|
| Force sign-out | `POST /admin/users/{uid}/revoke-sessions` (self allowed) | Every route answers older tokens with 401 `token_revoked`; the app signs out with "You were signed out. Please sign in again." |
| Profile | `PATCH /admin/users/{uid}/profile` (name, phone, company; not email) | Same limits as the app's profile; Firebase display name updated too |
| Notes | `GET/POST/DELETE /admin/users/{uid}/notes` | Never returned by `/me` routes |
| Daily limit | `PUT /admin/users/{uid}/daily-limit`, config `daily_grading_limit_default` | `POST /grade` 429 `DAILY_LIMIT_REACHED` once the user's gradings since Colombo midnight reach the limit |
| Activity | `GET /admin/users/{uid}/activity?cursor=` | - |
| Hide / restore | `POST /admin/gradings/{id}/hide` (reason) and `/restore` | Hidden gradings 404 for the owner and drop out of History and stats |
| Permanent delete | `DELETE /admin/gradings/{id}` `{confirm_id, reason}` | S3 photo, Grad-CAM and certificate files deleted, reviews and notifications deleted, certificate withdrawn, minimal audit |
| Review | `POST /admin/gradings/{id}/send-to-review` | Review queue reason `admin` |
| Re-grade | `POST /admin/gradings/{id}/regrade` | Current model on the stored photo -> `regrades[]`; the original result is never changed |
| Bulk | `POST /admin/gradings/bulk {action, ids <= 200, reason}` | hide / restore / send_to_review / export (CSV) |
| Calibration | `POST /admin/calibrations/{id}/invalidate` (reason), app `GET /me/calibration-status` | The app expires the session and asks to recalibrate; one notification |
| Devices | `POST /admin/devices/{device_id}/block` / `unblock` (reason), `GET /admin/devices/blocked` | `POST /grade` and `POST /calibrations` from the device: 403 `DEVICE_BLOCKED` |

Device ids (Phase 10p-fix) are a hash of the app's per-install `X-Device-Id` UUID, so a block
applies to one install only; old app builds without the header fall back to a hash of the
phone model name. Gradings and calibrations store `device_id` next to `device` (model). Tests:
`tests/test_admin_powers.py` (S3 is mocked for the permanent delete; the re-grade test needs
the dataset mount).
