# GemEye project state

Snapshot of 9 October 2026. Facts come from the repo and from test runs made for this file. No secret values.

## 1. Phase status

| Phase | Scope | Status |
|---|---|---|
| 0 | Colab exports (v3 models, gate stats, OOD stats, grade profiles) | Done |
| 1 to 1.1 | Inference server (FastAPI, Docker), MC Dropout speed-up | Done |
| 2 to 2.1 | Parity test against the v3 Colab results | Done |
| 3 to 3.2 | Quality gates, tray white balance | Done (thresholds provisional) |
| 4a, 4b, 4c | Firebase auth, MongoDB, S3, certificates, remote config, feedback, deleted-account tokens | Done, re-verified 9 October 2026 (MongoDB reachable, full suite passes) |
| 5a, 5b, 5c | Idempotent /grade, blur threshold in /config, app wired to server | Done (manual device test passed, EDIT history) |
| 6 | Downscale parity, calibration/cert fixes, device E2E | Done |
| 7 | Threshold tuning on real data | Not done (gates.py says "tune in Phase 7") |
| 8, 8.1 | Grad-CAM endpoint and Result screen | Done (device test passed) |
| 9L | Local server over Wi-Fi / adb for the demo | Done |
| 9 (production) | Hosted API, HTTPS, production URL | Not done (`PROD_URL` is a placeholder) |
| 10 | Admin (revoke by admin, editable thresholds) | Not done |

Test suites run on 9 October 2026:

| Suite | Passed | Failed |
|---|---|---|
| Backend (`pytest tests`, ENV=test, in the container) | 86 | 0 |
| Flutter (`flutter test`) | 80 | 0 |

The first run the same day had 43 failures because MongoDB was unreachable (Atlas IP allowlist); after the IP was added the full suite passed.

## 2. Backend

Version 1.2.0 (FastAPI). 19 operations: 3 public, 16 authenticated (Firebase bearer token).

| Method | Path | Auth |
|---|---|---|
| GET | /health | public |
| GET | /config | public |
| GET | /public/v/{slug} | public (30/min per IP) |
| POST | /grade | bearer |
| GET, PUT, DELETE | /me | bearer (PUT, DELETE use revocation check) |
| GET | /gradings, /gradings/{id} | bearer |
| DELETE | /gradings/{id} | bearer |
| POST | /gradings/{id}/heatmap | bearer |
| POST, GET | /calibrations | bearer |
| POST | /feedback | bearer |
| POST, GET | /certificates | bearer |
| GET | /certificates/{cert_no} | bearer |
| POST | /certificates/{cert_no}/pdf | bearer |
| POST | /certificates/{cert_no}/revoke | bearer |

MongoDB collections (created at startup): users, gradings, rejections, calibrations, counters, certificates, feedback, app_config, audit_log, deleted_accounts (TTL index, 2 h).

S3 (bucket in ap-south-1) prefixes per environment: `dev/`, `test/`, and the root for production. Under each: `gradings/{uid}/`, `certificates/`. Today the bucket holds only `dev/` (49 objects).

Environments:

| ENV | MongoDB database | S3 prefix |
|---|---|---|
| development | gemeye_dev | dev/ |
| test | gemeye_test | test/ |
| production | gemeye | (none) |

Thresholds (backend/app/gates.py, all provisional):

| Gate | Value |
|---|---|
| invalid_image | shorter side below 300 px |
| blurry | Laplacian variance below 29.47 |
| no_stone | area below 0.0157 or contrast below 5.0 dE00 (below 10.0 if centre fallback) |
| not_blue | hue outside 170 to 265 deg or chroma below 0.5 |
| not_recognised (OOD) | Mahalanobis warn 20.65, reject 25.69 |
| referral default | 0.60 (user range 0.40 to 0.90) |

Gate order in `inference.grade`: invalid_image, no_stone, blurry, not_blue (only when segmentation is reliable), not_recognised. Gates and debug fields can be bypassed only outside production.

Grad-CAM: implemented (CNN branch, `POST /gradings/{id}/heatmap`, feature flag `gradcam` on), device-tested.

## 3. App

- Version 1.0.0+1.
- API base URL order: address saved in Settings, then `--dart-define=API_BASE_URL=...`, then `API_ENV` (dev default `http://127.0.0.1:8000` via `adb reverse`; prod placeholder `https://api.gemeye.invalid`).
- Cleartext HTTP is allowed for all hosts on Android (`network_security_config.xml`, `base-config cleartextTrafficPermitted="true"`). This must be tightened before any release.
- Screens implemented (lib/screens): about, agreement, calibration, calibration_patch, calibration_result, capture, certificate, change_email, change_password, comparison, feedback_sheet, guide, history, home, login, main_shell, not_accepted, notifications, onboarding, photo_check, privacy, processing, profile, register, repeatability_capture, repeatability_summary, result, settings, splash.
- Screens still using demo data: none found by searching for demo/sample/mock/dummy/fake. The only matches are the onboarding slide-4 sample report illustration (`onboarding_screen.dart:510`) and a comment in `settings_screen.dart:80`. I did not read every screen end to end.
- Remaining TODOs:
  - lib/screens/comparison_screen.dart:375 TODO(backend): J and M rows
  - lib/screens/guide_screen.dart:276 TODO(dataset): L* and C* tiles
  - lib/screens/profile_screen.dart:136 TODO(F2): sync profile with backend
  - lib/screens/register_screen.dart:278 TODO(F2): send profile at registration
  - lib/services/certificate_service.dart:185 TODO(backend): model version
  - lib/services/certificate_service.dart:565 TODO(backend): server dE00 to grade colour
  - lib/services/profile_service.dart:12 TODO(F2): sync profile
  - lib/widgets/side_drawer.dart:275 TODO(F2): role and company line
- Google Sign-In: implemented in `auth_service.dart` (`signInWithGoogle`). I found no entry in the status log recording a device test of it, so treat it as unverified.

## 4. Last 10 PROJECT_STATUS entries (titles)

- EDIT-112 Phase 9L - run the app against a local server over Wi-Fi
- EDIT-113 Final year presentation guide (Markdown)
- EDIT-114 API reference (Markdown)
- EDIT-115 Run-on-phone command sheet (Markdown)
- EDIT-116 Cold-start run guide and demo check script for the viva
- EDIT-117 Quick run sheet
- EDIT-118 Demo launcher, adb tunnel over Wi-Fi and in-app server address
- EDIT-119 Verified app test images (2 per grade)
- EDIT-120 CIECAM02 values on the certificate
- EDIT-121 New visual README

This task adds EDIT-122.

## 5. Working tree (read-only git status, before this task's PROJECT_STATUS edit)

Untracked: backend/scripts/self_check.py, docs/connectivity_check.md, docs/PROJECT_STATE.md. No modified tracked files.

## 6. Open problems and known gaps

1. MongoDB Atlas works now. It depends on the PC's public IP being in the Atlas access list, so it will break again when the IP changes (launcher button "Fix Database").
2. The AWS key lacks s3:GetBucketPublicAccessBlock, GetEncryptionConfiguration, GetBucketVersioning and GetBucketPolicy. Bucket hardening could not be confirmed from the app key; check it in the AWS console or with an admin key.
3. Thresholds are provisional; Phase 7 tuning has not been done.
4. No production deployment: HTTPS host is a placeholder and Android allows cleartext everywhere.
5. Profile and company details are not synced to the backend (F2 TODOs).
6. Google Sign-In has no recorded device verification.

## 7. Commands

Backend (from the repo root):

```powershell
cd backend
docker compose up -d
docker compose ps
curl http://localhost:8000/health
```

Run the tests: `docker compose exec -T -e ENV=test api python -m pytest -q tests`. Run the connectivity check: see the header of `backend/scripts/self_check.py`.

Laptop IP (for the Settings > API base URL backup):

```powershell
ipconfig | findstr IPv4
```

The launcher also shows it on its bottom line.

Phone over adb (one APK works on any network; USB cable once to switch to Wi-Fi):

```powershell
adb shell ip -f inet addr show wlan0
adb tcpip 5555
adb connect PHONE_IP:5555
adb reverse tcp:8000 tcp:8000
```

Build and install the APK (the APK is `app\build\gemeye.apk` per docs/RUN_ON_PHONE.md; see that file for the exact build step the repo uses):

```powershell
cd app
flutter build apk --release --dart-define=API_BASE_URL=http://PC_IP:8000
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

The `--dart-define` is optional when using `adb reverse`; without it the app uses `http://127.0.0.1:8000`. The easiest path is `Start GemEye Demo.bat` and the START EVERYTHING button (docs/RUN_QUICK.md).
