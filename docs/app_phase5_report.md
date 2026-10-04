# GemEye app - Phase 5 Step 0 report (read-only)

Date: 05 October 2026. Scope: `app/lib`, `pubspec.yaml`, Android/iOS config. No code was changed.
Server facts are quoted from `backend/` for comparison.

## 1. GradeResult model

Source: `app/lib/models/grade_result.dart` (163 lines)

```dart
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

class GradeResult {
  final String id;
  final String stoneId;
  final int gradeNumber;
  final String gradeName;
  final String tradeName;
  final double confidence;
  final double uncertaintyRange;
  final double labL;
  final double labA;
  final double labB;
  final double labC;
  final double hue;
  final double saturation;
  final double brightness;
  final double deltaE;
  final String capturedImagePath;
  final String? gradcamImagePath;
  String? certificateNumber;
  final DateTime capturedAt;
  final String sessionId;

  GradeResult({
    String? id,
    required this.stoneId,
    required this.gradeNumber,
    required this.gradeName,
    required this.tradeName,
    required this.confidence,
    required this.uncertaintyRange,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.labC,
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.deltaE,
    required this.capturedImagePath,
    this.gradcamImagePath,
    this.certificateNumber,
    DateTime? capturedAt,
    String? sessionId,
  })  : id = id ?? const Uuid().v4(),
        capturedAt = capturedAt ?? DateTime.now(),
        sessionId = sessionId ?? 'SESSION-${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'stoneId': stoneId,
        'gradeNumber': gradeNumber,
        'gradeName': gradeName,
        'tradeName': tradeName,
        'confidence': confidence,
        'uncertaintyRange': uncertaintyRange,
        'labL': labL,
        'labA': labA,
        'labB': labB,
        'labC': labC,
        'hue': hue,
        'saturation': saturation,
        'brightness': brightness,
        'deltaE': deltaE,
        'capturedImagePath': capturedImagePath,
        'gradcamImagePath': gradcamImagePath,
        'certificateNumber': certificateNumber,
        'capturedAt': capturedAt.toIso8601String(),
        'sessionId': sessionId,
      };

  factory GradeResult.fromJson(Map<String, dynamic> json) => GradeResult(
        id: json['id'] as String,
        stoneId: json['stoneId'] as String,
        gradeNumber: json['gradeNumber'] as int,
        gradeName: json['gradeName'] as String,
        tradeName: json['tradeName'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        uncertaintyRange: (json['uncertaintyRange'] as num).toDouble(),
        labL: (json['labL'] as num).toDouble(),
        labA: (json['labA'] as num).toDouble(),
        labB: (json['labB'] as num).toDouble(),
        labC: (json['labC'] as num).toDouble(),
        hue: (json['hue'] as num).toDouble(),
        saturation: (json['saturation'] as num).toDouble(),
        brightness: (json['brightness'] as num).toDouble(),
        deltaE: (json['deltaE'] as num).toDouble(),
        capturedImagePath: json['capturedImagePath'] as String,
        gradcamImagePath: json['gradcamImagePath'] as String?,
        certificateNumber: json['certificateNumber'] as String?,
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        sessionId: json['sessionId'] as String,
      );

  /// Copy with a new stone ID (all other values unchanged).
  GradeResult withStoneId(String newStoneId) => GradeResult(
        id: id,
        stoneId: newStoneId,
        gradeNumber: gradeNumber,
        gradeName: gradeName,
        tradeName: tradeName,
        confidence: confidence,
        uncertaintyRange: uncertaintyRange,
        labL: labL,
        labA: labA,
        labB: labB,
        labC: labC,
        hue: hue,
        saturation: saturation,
        brightness: brightness,
        deltaE: deltaE,
        capturedImagePath: capturedImagePath,
        gradcamImagePath: gradcamImagePath,
        certificateNumber: certificateNumber,
        capturedAt: capturedAt,
        sessionId: sessionId,
      );

  /// Measured colour as sRGB [r, g, b] (0-255), from CIELAB (D65).
  List<int> get measuredRgb {
    final fy = (labL + 16) / 116;
    final fx = fy + labA / 500;
    final fz = fy - labB / 200;
    double inv(double t) => t * t * t > 0.008856 ? t * t * t : (t - 16 / 116) / 7.787;
    final x = 0.95047 * inv(fx);
    final y = 1.0 * inv(fy);
    final z = 1.08883 * inv(fz);
    final lin = [
      3.2406 * x - 1.5372 * y - 0.4986 * z,
      -0.9689 * x + 1.8758 * y + 0.0415 * z,
      0.0557 * x - 0.2040 * y + 1.0570 * z,
    ];
    return lin.map((c) {
      final v = c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
      return (v * 255).round().clamp(0, 255);
    }).toList();
  }

  /// Measured colour as "#RRGGBB".
  String get measuredHex =>
      '#${measuredRgb.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';

  String get confidenceLevel {
    if (confidence >= 80) return 'HIGH';
    if (confidence >= 50) return 'MEDIUM';
    return 'LOW';
  }

  String get gradeColourHex {
    const colours = {
      1: '#091A47',
      2: '#102670',
      3: '#1B3A8C',
      4: '#2E5BB8',
      5: '#4A80D4',
      6: '#7BA7E8',
      7: '#A8C8F0',
    };
    return colours[gradeNumber] ?? '#1B3A8C';
  }
}
```

Notes: `confidence` is a percentage (0-100); the server returns 0-1. `uncertaintyRange`, `saturation` and `brightness` are percentages. `gradeColourHex` (lines 151-162) uses a palette that differs from the 7 GEMCLOUD hex values in CLAUDE.md. There are no fields for probabilities, second grade, CIECAM02, model version, warnings, referred, grading_id, image_url or the server stone_id.

### Created

| Where | What |
|---|---|
| `lib/services/grading_service.dart:64-81` | demo result in `GradingService.grade` (always grade 3, 92.4%) |
| `lib/screens/result_screen.dart:49-67` | `_createMockResult()` when `gradeResult` is null (placeholder stone id) |
| `lib/models/grade_result.dart:74` | `fromJson` (history reload) |
| `lib/models/grade_result.dart:98` | `withStoneId` copy |

### Consumed

| Where | Use |
|---|---|
| `lib/screens/processing_screen.dart:62-72` | collects results, opens Result or Repeatability Summary |
| `lib/screens/result_screen.dart:25,39,46,92,113,380` | display, save, certificate, Delta E row |
| `lib/screens/repeatability_summary_screen.dart:21,34,48-55,66,87` | majority grade, save, certificate |
| `lib/screens/certificate_screen.dart:19` | PDF preview, save, share |
| `lib/services/certificate_service.dart:77` | `generateCertificatePdf(result:)` |
| `lib/services/grade_record_service.dart:16-47` | `ensureStoneId`, `save`, `prepareCertificate` |
| `lib/services/storage_service.dart:11,24,34,59` | SharedPreferences persistence |
| `lib/screens/history_screen.dart:51,53,117,199,229,252,278,303,371,395,959` | list, filter, referred, delete, bulk export |
| `lib/screens/home_screen.dart:43,75-90,156` | recent list, today stats |
| `lib/screens/comparison_screen.dart:19-20,35,44,182-186,302,358,511-515,609` | picker, local ΔE₀₀ |
| `lib/services/account_service.dart:43,80` | CSV export |
| `lib/widgets/recent_grade_tile.dart:11` | Home tile |

## 2. Grading flow

| Step | Screen / function | Moves on via | Data passed |
|---|---|---|---|
| Capture | `capture_screen.dart:56` `_capture(source)`; enabled only when online + calibration valid + checklist ticked (`:78-81`) | `PhotoCheckScreen.captureFrom` | `ImageSource` |
| Pick + crop | `stone_capture_service.dart:15` `pickAndCrop`: `ImagePicker.pickImage(maxWidth 2048, maxHeight 2048, imageQuality 95)`, then `ImageCropper.cropImage` (free aspect) | returns `CapturedStone(path, cropFailed)`; on a cropper error the uncropped path is used | file path (JPEG, at most 2048 px) |
| Photo Check | `photo_check_screen.dart:38` `captureFrom` pushes `PhotoCheckScreen(imagePath, previousPaths, repeatability)`; `_analyse` (`:87`) runs `PhotoCheckService.analyse(File)`; Grade button enabled when sharp + stone in frame + calibrated (`:139`) | `_accept()` (`:120`) | `[...previousPaths, imagePath]` |
| Processing | `ProcessingScreen(imagePaths)`, `_run()` (`processing_screen.dart:48`): demo step timer (6 x 400 ms + 500 ms), `sessionId = CalibrationService.session.value?.id`, `stoneId = StorageService.getNextStoneId()` (local, kept across retries), then `GradingService.grade(imagePath, stoneId, sessionId)` per path | `_open()` (`:127`, `pushAndRemoveUntil` back to Capture) | `List<GradeResult>` |
| Result | 1 result: `ResultScreen(imagePath, gradeResult)` | `_saveAndGradeNext` (`result_screen.dart:89`) or `_exportCertificate` (`:110`) | `GradeResult`; the certificate gets image bytes read from `imagePath` |
| Not accepted | `GradingRejectedException` → `NotAcceptedScreen(reason, imagePath: last path, sessionId, measuredHue)` (`processing_screen.dart:73-82`) | Retake | path only |
| Errors | `GradingNoConnectionException` → Retry dialog; `GradingTimeoutException` → alert + retry; anything else → alert + pop (`:83-123`) | - | - |
| Save | `GradeRecordService.save` (`grade_record_service.dart:18`) → `StorageService.saveGradeResult`; referral notification when `confidence < referThreshold` | pops to the first route | - |

Only file paths move between screens; no bytes or sizes. The photo is never sent: `GradingService.grade` ignores the file.

Demo/mock results: `lib/services/grading_service.dart:64-81` (used by the real flow) and `lib/screens/result_screen.dart:49-67` (fallback when no result is passed).

## 3. Repeatability mode

- Toggle on Capture (`capture_screen.dart:144-147`). `kRepeatabilityCaptures = 3` (`photo_check_screen.dart:18`).
- Capture 1: Capture → crop → Photo Check. `_accept` (`photo_check_screen.dart:120-131`) pushes `RepeatabilityCaptureScreen(acceptedPaths)` for captures 2 and 3 (`repeatability_capture_screen.dart:30-36`, thumbnails of accepted photos). Each capture goes through crop + Photo Check again.
- After the 3rd accepted photo: `ProcessingScreen(imagePaths: [p1, p2, p3])` grades them one after another (same stone id and session id) and opens `RepeatabilitySummaryScreen(results)`.
- Summary (`repeatability_summary_screen.dart:38-56`, TODO(backend) at `:41`): the final grade is the majority grade; the saved record is the most confident capture with that grade (also the tie-break). `_consistent` = all 3 agree; `_referred` = not consistent or confidence < threshold. The "max ΔE₀₀" row shows "-" (`:177`). Only the chosen record is saved (`_save` `:63`); the other two are discarded.
- With the demo service, all 3 results are identical.

## 4. CalibrationService (`lib/services/calibration_service.dart`)

- Patches in capture order (`:37-44`, "MUST match the training code"): White (255,255,255), Black (0,0,0), 18% Grey (117,117,117), 50% Grey (186,186,186), Blue (0,63,135), Red (175,54,60). Same order as the server's `patches` (white, black, grey_18, grey_50, blue, red).
- Measurement (`_measureBytes` `:397`): decode, EXIF-orient, central 50% crop, per-channel mean and std (0-255). A patch is uniform if every std ≤ 0.06·255.
- CCM (`computeCcm` `:329`): least squares on values /255, no offset. `ccm` = 9 doubles, **row-major 3x3 M, applied as corrected = rgb · M** (0-1 units). `residual` = RMS of the per-patch Euclidean error (normalised RGB). Quality: Excellent ≤ 0.30, Acceptable ≤ 0.45, else Poor.
- Stored session (`CalibrationSession.toJson` `:128`): `id`, `createdAt`, `validUntil` (ISO strings), `deviceModel`, `ccm` [9], `residual`, `quality` (enum name), `measured` [6][3] mean RGB 0-255 in capture order, `perPatchError` [6].
- Session id: `S-YYYY-MM-DD-NN`, where NN = number of same-day sessions in history + 1 (`:262`). Local device time.
- Expiry: `validUntil = createdAt + 8 h` (`kCalibrationValidity` `:23`); `isValid = now < validUntil`. `remindIfExpired` adds one "Recalibrate" notification per expired session.
- Storage: `flutter_secure_storage` (Android encryptedSharedPreferences), keys `calibration_current`, `calibration_history` (max 50, newest first), `calibration_reminded_id`. Live `ValueNotifier session`.
- Never sent to the server. The server's `POST /calibrations` wants `session_id`, `valid_until`, `device`, `ccm` as a **3x3 nested list**, `residual`, `quality`, `measured_patches` 6x3. `/grade` wants `patches` (the 6x3 measured means as a JSON string) plus `session_id`.

## 5. Photo Check blur: app vs server

| Step | App (`lib/services/photo_check_service.dart:46-79`) | Server (`backend/app/pipeline/inference.py:19-27`) |
|---|---|---|
| Input | the **cropped** photo file | the raw upload (whatever the app sends) |
| Gray | `0.299R + 0.587G + 0.114B` as float64 (not rounded) | `cv2.cvtColor(RGB2GRAY)` (uint8, rounded) |
| Resize | only if larger: longer side → 512 with `img.copyResize` (default interpolation, not area); smaller images are not upscaled | longer side → 512 always (`s = 512/max(h,w)`, also upscales), `INTER_AREA` |
| Crop | central 50%: `x ∈ [w/4, 3w/4)`, `y ∈ [h/4, 3h/4)`, clamped to [1, w-1]; neighbour pixels come from the full image | `g[h//4:3h//4, w//4:3w//4]`; Laplacian computed on the crop (border reflected) |
| Kernel | 4-neighbour Laplacian `[0 1 0; 1 -4 1; 0 1 0]` | `cv2.Laplacian(ksize=1, CV_64F)`, the same kernel |
| Statistic | population variance `E[x²] - mean²` | `.var()`, population variance |
| Threshold | `kMinBlurVariance = 50` (TODO: calibrate) | `BLUR_MIN_VARIANCE = 29.47` (`backend/app/gates.py:15`) |

Same kernel and statistic. The differences are the input (crop vs raw), resize interpolation and no upscaling, float vs uint8 gray, border handling, and threshold 50 vs 29.47. The app is stricter, so a photo can pass on the server and fail on the phone. The framing check is app-only: the share of non-near-white pixels (any channel < 200) in the central 70% must be within 5-95%.

## 6. Local storage and history

- `StorageService` (`lib/services/storage_service.dart`): SharedPreferences key `grade_history` = string list of `jsonEncode(GradeResult.toJson())`, newest first, upserted by `id`. `stone_counter` int → `GE-STONE-NNNNN` (local, per device). Photos stay at the cropper's temp path (`capturedImagePath`); no copy is made.
- History (`history_screen.dart:104`): `getGradeHistory()`, then in-memory search, filter and sort. Filters: confidence, certificate (`certificateNumber != null`, `:159-161`), session, dates. Delete → `deleteGradeResult` (local only).
- Home (`home_screen.dart:75-90`): reads the whole history for today's count, today's average confidence, today's referred count and the 3 most recent.
- Comparison (`comparison_screen.dart:37,183`): picks 2 stones from local history; ΔE₀₀ is computed on the phone from the two stored Lab values (`ColourMath.deltaE2000`).
- "Referred" everywhere = `confidence < ConfidenceBadge.referThreshold` (`confidence_badge.dart:10` = `SettingsService.referralThreshold`, default 60, range 40-90). It is evaluated **at read time**, so changing the setting changes past results. The server stores `referred` at grading time.
- Other local stores: notifications (SharedPreferences `app_notifications`, max 100), feedback (SharedPreferences `feedback`), profile (`ProfileService`), settings (SharedPreferences), certificate counter (SharedPreferences `certificate_counter`).

## 7. CertificateService (`lib/services/certificate_service.dart`)

- Number (`generateCertificateNumber` `:50-61`): local SharedPreferences counter `certificate_counter` (per device, never resets by month), format `{prefix}-{YYYYMM local}-{NNNNN}`, prefix from Settings (default `GE`). Assigned only when `certificateNumber == null`, in `GradeRecordService.prepareCertificate` (`grade_record_service.dart:41-47`) and History bulk export (`history_screen.dart:300-303`).
- QR (`:105-111`, TODO(backend)): JSON `{"cert", "grade", "stone", "date"}`, not a URL.
- PDF: built with the `pdf` package. Stone image = bytes of the local photo (empty if missing). Calibration details are looked up in local history by `sessionId`. "Issued to" = Firebase displayName; company from `ProfileService`. Model version is hard-coded `-` (`:191-192`).
- Save/share (`certificate_screen.dart:78-130`): Android → `/storage/emulated/0/Download/GemEye Certificates/{cert}.pdf`, iOS → app documents. Share via `Printing.sharePdf`, print via `Printing.layoutPdf`. History bulk export writes to app documents `GemEye Certificates/`. Nothing is uploaded.
- CIECAM02 (`:169-189`): all five rows are hard-coded `-`.
- "Delta E": `result.deltaE` (demo value 1.2) on the PDF (`:565-569`) and the Result screen (`result_screen.dart:380`). Comparison ΔE₀₀ is computed locally from Lab.

## 8. Notifications and TODOs

`NotificationService` (`lib/services/notification_service.dart`): local only, SharedPreferences, max 100 items, unread-count `ValueNotifier`. Events raised:

| Where | Title |
|---|---|
| `certificate_screen.dart:97` | Certificate saved |
| `change_email_screen.dart:66` | Email change requested |
| `change_password_screen.dart:85` | Password changed |
| `calibration_service.dart:280` | Recalibrate |
| `grade_record_service.dart:25` | Stone referred |

Planned in comments: `notification_service.dart:11` TODO(backend) error "Grading failed" (action openCapture); `:13` TODO info "Privacy policy updated" (action openPrivacy).

TODO(backend):
- `comparison_screen.dart:375` add J (Lightness, CAM) and M (Colourfulness) rows once GradeResult carries CIECAM02 values.
- `feedback_sheet.dart:11` send feedback to the server (MongoDB feedback collection).
- `not_accepted_screen.dart:13` opened from ProcessingScreen when the server response carries a rejection status (see RejectionReason.fromStatus).
- `processing_screen.dart:51` advance the steps from server progress instead of the demo timing below.
- `processing_screen.dart:74` thrown by GradingService when the server returns a rejection status (no_stone, not_blue, not_recognised).
- `processing_screen.dart:84` thrown by GradingService on SocketException.
- `processing_screen.dart:99` thrown by GradingService on TimeoutException.
- `processing_screen.dart:112` GradingException and any unexpected error land here.
- `repeatability_summary_screen.dart:41` take the final grade and its confidence from the server. Until then: majority grade, and the most confident capture with that grade is the record that is saved.
- `repeatability_summary_screen.dart:177` max ΔE₀₀ between the 3 captures with its verdict (e.g. "max 0.9 - Excellent").
- `result_screen.dart:72` return the ensemble probabilities once GradeResult carries them; the "How sure is the model" card and the second grade in the borderline banner stay hidden until then.
- `result_screen.dart:279` add the model version from the response.
- `result_screen.dart:350` add CIECAM02 tiles (J, M, h, s, C) in the same style.
- `settings_screen.dart:124` delete the user's grades on the server.
- `settings_screen.dart:187` delete server data (grades, certificates, feedback, S3 images) before removing the Firebase user.
- `settings_screen.dart:524` Image / Both exports; certificate export currently always produces the PDF.
- `settings_screen.dart:620` call the API health endpoint and show Connected + latency when the grading server is deployed.
- `account_service.dart:18` delete the user's server data (grades, certificates, feedback, S3 images) before the Firebase user is deleted.
- `certificate_service.dart:106` encode a verification URL once the verify endpoint exists.
- `certificate_service.dart:169` CIECAM02 values are not in GradeResult yet.
- `certificate_service.dart:191` model version from the grading response.
- `certificate_service.dart:568` server ΔE₀₀ to the grade's typical colour.
- `grading_service.dart:57` POST the photo and the session CCM to AppConstants.apiBaseUrl + gradeEndpoint with the http package. Throw GradingNoConnectionException on SocketException, GradingTimeoutException on TimeoutException, GradingRejectedException with RejectionReason.fromStatus(status) on a rejection status, and GradingException on any other error. Until then this returns the existing demo result.
- `notification_service.dart:11` error "Grading failed" when the grading request fails (action openCapture).

TODO(F2):
- `profile_screen.dart:137` sync the profile and company details with the backend.
- `register_screen.dart:278` send the profile (incl. business reg. no and address) to the backend; those two fields are not stored locally.
- `profile_service.dart:12` sync the profile (and company details) with the backend.
- `side_drawer.dart:275` show "Role · Company" once the profile is persisted.

TODO(dataset):
- `guide_screen.dart:276` add "Lightness L*" and "Chroma C*" tiles with the real per-grade median L* and C* from the training set.

TODO(C4): none in `lib/`.

Untagged TODOs: `calibration_service.dart:14` (tune kPatchMaxStd), `photo_check_service.dart:7` (calibrate kMinBlurVariance), `settings_screen.dart:547` (auto-save photos to gallery is saved but not acted on), `side_drawer.dart:396` (server status in the drawer footer), `notification_service.dart:13` (privacy policy updated).

## 9. Settings (`lib/screens/settings_screen.dart`, `lib/services/settings_service.dart`)

| Item | State |
|---|---|
| Referral threshold | exists: slider 40-90%, step 1 (`:457-500`), SharedPreferences `referral_threshold`, default 60. Local only (the server keeps 0.40-0.90 in `users.settings`) |
| Show name on certificate | **does not exist**; the PDF always shows the Firebase displayName |
| Export | "Export all data (CSV)" (`:79`) → `AccountService.exportCsv` (Android Downloads/GemEye, iOS documents) + share sheet. The export format segment (PDF / Image / Both) is saved, but only PDF is produced (`:524`) |
| Clear history | `:109` → `StorageService.clearHistory` (local); TODO(backend) `:124` |
| Delete account | `:140`: confirm → re-auth (password dialog or Google) → `AuthService.endSession(beforeSignOut: currentUser.delete(); AccountService.clearLocalData())`. No server call (`:187`) |
| Server status | static row "Server status: Not connected" (`:620-638`) |
| Others | certificate prefix, auto-save photos (not acted on), notification toggles (calibration, referral, certificate), recalibrate, calibration history, change password/email, log out, intro, guide, feedback |

## 10. AuthService (`lib/services/auth_service.dart`)

There is no ID-token helper. The `currentUser` getter (`:13`) returns the Firebase `User?`. A token is available via `FirebaseAuth.instance.currentUser?.getIdToken()` (`getIdToken(true)` forces a refresh) or `getIdTokenResult()` (includes `authTime`). `getIdToken` is not called anywhere in `lib/`. Re-auth helpers: `reauthenticateWithPassword` (`:108`), `reauthenticateWithGoogle` (`:119`). Also `endSession` (`:72`), `handleSessionError` (`:147`), `verifySession` (`:176`).

## 11. Config, dependencies, platform

- `lib/config/constants.dart`: `apiBaseUrl = 'http://localhost:5000'`, which is wrong for a phone or emulator (the Docker server listens on 8000). `gradeEndpoint = '/grade'`, `calibrateEndpoint = '/calibrate'` (the server has `/calibrations`). `minBlurThreshold = 100.0` is unused (Photo Check uses 50). `cnnWeight 0.65`, `rfWeight 0.35`, `mcDropoutPasses 10` are unused.
- pubspec: `http ^1.2.2` is present but unused; no `dio`. Also `connectivity_plus`, `flutter_secure_storage`, `shared_preferences`, `image`, `image_picker`, `image_cropper`, `pdf`, `printing`, `share_plus`, `path_provider`, `device_info_plus`, `uuid`, `provider`, `go_router`, `firebase_core`, `firebase_auth`, `google_sign_in`, `local_auth`, `url_launcher`.
- `android/app/src/main/AndroidManifest.xml`: CAMERA, READ/WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES. **No INTERNET permission** in the main manifest (only in the debug/profile manifests), so release builds cannot reach the API. No `usesCleartextTraffic`, no `networkSecurityConfig`, no `res/xml/`. Cleartext HTTP is blocked by default on API 28+.
- iOS `Info.plist`: no `NSAppTransportSecurity` (HTTP blocked) and no `NSCameraUsageDescription` or `NSPhotoLibraryUsageDescription`.

## 12. What Phase 5 must change

**config/constants.dart** - real HTTPS base URL per build (dev/prod); endpoint names matching the server (`/grade`, `/calibrations`, `/gradings`, `/me`, `/certificates`, `/feedback`, `/config`, `/health`); timeouts; remove the unused ML constants.

**New services/api_client.dart** - `http` wrapper that adds `Authorization: Bearer <getIdToken()>` and retries once with `getIdToken(true)` on 401. Maps 401 `account_deleted` / `reauth_required`, 503 `maintenance`, SocketException and TimeoutException to user-friendly errors.

**models/grade_result.dart** - add `gradingId`, server `stoneId`, `probabilities[7]`, `secondGrade`, `referred`, `uncertainty`, CIECAM02 (J, M, h, s, C) + `approximate`, `deltaE00ToTypical`, `modelVersion`, `warnings`, `imageUrl`, `calibrationMode`. Add `fromApi()` converting confidence 0-1 → %. Fix `gradeColourHex` to the GEMCLOUD palette.

**services/grading_service.dart** - real multipart `POST /grade` (image bytes, `patches` = session measured 6x3 JSON, `session_id`, `referral_threshold`, `app_version`, `device`). Map `blurry`, `no_stone`, `not_blue`, `not_recognised`, `invalid_image`; `RejectionReason` has no `blurry` or `invalid_image` yet.

**screens/processing_screen.dart** - stop allocating a local stone id and use the server `stone_id`; remove the demo timing; handle `blurry`, `invalid_image` and maintenance.

**screens/result_screen.dart** - remove `_createMockResult`; add the probabilities card, second grade, CIECAM02 tiles, model version and warnings.

**screens/repeatability_summary_screen.dart** - each capture is its own server grading. Decide which record represents the stone (the server has no repeatability endpoint). Show max ΔE₀₀ between captures (computable on the phone from Lab).

**services/calibration_service.dart** - `POST /calibrations` on save (`ccm` as a 3x3 nested list, `measured_patches`, `valid_until`, `device`, `residual`, `quality`); keep the local copy for gating.

**services/photo_check_service.dart** - align blur with the server (always resize the longer side to 512 with area averaging, uint8 gray, Laplacian on the cropped centre, threshold 29.47), or keep the app stricter on purpose and document why. Decide whether the server receives the cropped or the uncropped photo (the server gates were measured on raw uploads).

**services/storage_service.dart and the history, home and comparison screens** - load history from `GET /gradings` (cursor pagination, filters) with a local cache; delete via `DELETE /gradings/{id}`; take `referred` from the server record instead of re-evaluating it against the current threshold.

**services/certificate_service.dart, grade_record_service.dart, certificate_screen.dart, history_screen.dart (bulk export)** - certificate number from `POST /certificates` (remove the local counter; the prefix setting becomes display-only or goes); QR = `verify_url`; upload the PDF to `POST /certificates/{no}/pdf`; add a revoke action; real CIECAM02, ΔE and model version.

**screens/settings_screen.dart + services/settings_service.dart** - sync the referral threshold (40-90 ↔ 0.40-0.90) via `PUT /me`; add "Show my name on certificates"; Clear history → server delete; Delete account → re-auth, then `DELETE /me` (needs `auth_time` ≤ 5 min, handle `reauth_required`), then local clear. The server deletes the Firebase user, so remove `currentUser.delete()`. Server status row from `GET /health`.

**services/account_service.dart** - server-backed delete and export.

**screens/feedback_sheet.dart** - `POST /feedback`. The app collects `categories` (a list); the server takes one `category` plus `app_version`.

**services/profile_service.dart, profile_screen.dart, register_screen.dart, side_drawer.dart** - `GET` / `PUT /me` for profile and company (TODO F2).

**Remote config** - read `GET /config` at startup (maintenance banner, `min_app_version`, `calibration_validity_hours`, feature flags).

**android/app/src/main/AndroidManifest.xml** - add INTERNET; a network security config only if a dev HTTP server is used (debug-only cleartext for the dev host).

**ios/Runner/Info.plist** - camera and photo library usage strings; an ATS exception only for a dev HTTP host.
