# GemEye App - Backend Integration Report

Read-only snapshot of the Flutter app (branch `ui-redesign`, 03 October 2026) for designing the backend API. Paths are relative to `app/`.

## 1. GradeResult (`lib/models/grade_result.dart`, full source)

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

Notes:
- `gradeColourHex` uses an old palette that does not match the GEMCLOUD hex values in `AppConstants.gradeColors` / CLAUDE.md.
- No per-grade probabilities, CIECAM02 values, model version or calibration session reference yet (TODO(backend) at `result_screen.dart:72`, `comparison_screen.dart:376`, `certificate_service.dart:169`).
- `sessionId` defaults to `SESSION-<epoch ms>`; it is a grading session, not the calibration session id (`S-YYYY-MM-DD-NN`).

## 2. Public service signatures

### StorageService (`lib/services/storage_service.dart`)
SharedPreferences: key `grade_history` (list of JSON strings), `stone_counter`.
```dart
static Future<void> saveGradeResult(GradeResult result)          // upsert by id
static Future<List<GradeResult>> getGradeHistory()               // newest first
static Future<void> deleteGradeResult(String id)
static Future<void> clearHistory({bool deletePhotos = false})
static Future<GradeResult?> getGradeResultById(String id)
static Future<String> getNextStoneId()
static Future<int> getGradeCount()
static Future<int> getTodayCount()
```

### CalibrationService (`lib/services/calibration_service.dart`)
```dart
static final ValueNotifier<CalibrationSession?> session
static bool get isValidNow
static Future<void> init()
static Future<CalibrationSession?> current()
static Future<void> clearAll()
static Future<bool> isValid()
static Future<List<CalibrationSession>> history()               // newest first
static Future<void> save(CalibrationSession s)
static Future<CalibrationSession> buildSession(List<PatchMeasurement> patches)
static Future<void> remindIfExpired()
static Future<String> deviceModel()
static Future<PatchMeasurement> measurePatch(File file)
static List<int> applyCcm(List<double> ccm, num r, num g, num b)
static CcmResult computeCcm(List<List<double>> measured, List<List<double>> reference)
```

### NotificationService (`lib/services/notification_service.dart`)
```dart
static final ValueNotifier<int> unreadCount
static Future<void> init()
static Future<List<AppNotification>> list()
static Future<void> add({required AppNotificationType type, required String title,
    required String message, AppNotificationAction action = AppNotificationAction.none,
    String? payload, NotificationCategory? category})
static Future<void> markRead(String id)
static Future<void> markAllRead()
static Future<void> delete(String id)
static Future<void> clearAll()
```

### AuthService (`lib/services/auth_service.dart`) - Firebase Auth + Google Sign-In
```dart
User? get currentUser
bool get isLoggedIn
Stream<User?> get authStateChanges
bool get hasPassword
bool get isGoogleOnly
Future<UserCredential?> signInWithGoogle()
Future<UserCredential> registerWithEmail(String email, String password)
Future<UserCredential> signInWithEmail(String email, String password)
Future<void> updateDisplayName(String name)
Future<void> signOut()
Future<void> reauthenticateWithPassword(String password)
Future<bool> reauthenticateWithGoogle()
Future<void> resetPassword(String email)
String getFirstName()
static Future<bool> endSession({Future<void> Function()? beforeSignOut})
static bool isSessionError(Object e)
static bool handleSessionError(Object e)
static Future<void> showSessionExpired()
static Future<void> verifySession()
```

### CertificateService (`lib/services/certificate_service.dart`)
```dart
static Future<String> generateCertificateNumber()               // local counter, GE-YYYYMM-NNNNN
static Future<Uint8List> generateCertificatePdf({required GradeResult result,
    required Uint8List stoneImage, Uint8List? gradcamImage})
```

## 3. Where the demo grading result is created

| Location | What |
|----------|------|
| `lib/services/grading_service.dart:64` | `GradingService.grade({imagePath, stoneId, sessionId})` returns a hard-coded Grade 3 / Vivid / Royal Blue, 92.4%, L* 42.3, a* 8.9, b* -27.0, C 28.4, hue 228, deltaE 1.2. TODO(backend) at line 57 describes the POST and exception mapping. |
| `lib/screens/result_screen.dart:50` | `_createMockResult()` - same values, used when `ResultScreen` opens without a `gradeResult`. |

Grading exceptions already defined in `grading_service.dart`: `GradingNoConnectionException`, `GradingTimeoutException`, `GradingException(message)`, `GradingRejectedException(reason, {measuredHue})` with `RejectionReason` statuses `no_stone`, `not_blue`, `not_recognised`.

## 4. Every consumer of GradeResult

| File:line | Use |
|-----------|-----|
| `lib/screens/processing_screen.dart:61-99` | Gets stone id, calls `GradingService.grade` per photo, handles rejection / no connection / timeout |
| `lib/screens/repeatability_summary_screen.dart:21,34` | Takes `List<GradeResult>`, picks the final result |
| `lib/screens/result_screen.dart:25,39,49` | Displays the result; probabilities TODO at :72 |
| `lib/screens/certificate_screen.dart:19` | Certificate preview and export |
| `lib/screens/history_screen.dart:51-395,959` | Load, filter, delete, undo, open, list item |
| `lib/screens/home_screen.dart:43,75,156` | Recent grades, open result |
| `lib/screens/comparison_screen.dart:19-609` | Stone A/B picker, comparison table (CIECAM02 TODO at :376) |
| `lib/widgets/recent_grade_tile.dart:11` | Home recent tile |
| `lib/services/grade_record_service.dart:14,21,40` | `ensureStoneId`, `save`, `prepareCertificate` (assigns the certificate number once) |
| `lib/services/storage_service.dart` | Local persistence (section 2) |
| `lib/services/certificate_service.dart:77,169` | PDF generation |
| `lib/services/account_service.dart:43,80` | CSV export of history |

## 5. CCM and measured patch storage (CalibrationService)

- Storage: `flutter_secure_storage` (Android `encryptedSharedPreferences: true`). Keys: `calibration_current` (one session JSON), `calibration_history` (JSON list, max 50, newest first), `calibration_reminded_id`.
- Session JSON (`CalibrationSession.toJson`):
  ```json
  {"id": "S-2026-10-03-01", "createdAt": "ISO-8601", "validUntil": "ISO-8601 (+8 h)",
   "deviceModel": "OnePlus Nord 2", "ccm": [9 doubles],
   "residual": 0.25, "quality": "excellent|acceptable|poor",
   "measured": [[r, g, b] x 6], "perPatchError": [6 doubles]}
  ```
- `ccm`: row-major 3x3 in 0-1 units, applied as `corrected = rgb . M` (`out[j] = r*M[j] + g*M[3+j] + b*M[6+j]`), least squares with no offset (matches `numpy.linalg.lstsq` in training).
- `measured`: mean RGB (0-255) of the central 50% of each patch photo, in capture order: White [255,255,255], Black [0,0,0], 18% Grey [117,117,117], 50% Grey [186,186,186], Blue [0,63,135], Red [175,54,60].
- Residual thresholds: excellent <= 0.30, acceptable <= 0.45 (normalised RGB, provisional). A patch is rejected if any channel std > 0.06 x 255.

## 6. AppConstants (`lib/config/constants.dart`)

```dart
class AppConstants {
  // API
  static const String apiBaseUrl = 'http://localhost:5000';
  static const String gradeEndpoint = '/grade';
  static const String calibrateEndpoint = '/calibrate';

  // App Info
  static const String appName = 'GemEye';
  static const String appTagline = 'Automated Blue Sapphire Colour Grading';
  static const String appVersion = '1.0';
  static const String appYear = '2026';
  static const String developerName = 'Nirmana K.A.S.';
  static const String studentNo = '28973';

  // Preferences
  static const String policyAcceptedKey = 'policy_accepted';

  /// Bump when assets/data/privacy_policy.md changes; signed-in users
  /// who accepted an older version must review and accept again.
  static const int privacyPolicyVersion = 1;

  // Certificate
  static const String defaultCertificatePrefix = 'GE';

  // Calibration
  static const int requiredPatches = 6;
  static const double maxAcceptableDeltaE = 2.0;

  // Capture
  static const double minBlurThreshold = 100.0;
  static const int minLuxGood = 300;
  static const int minLuxLow = 100;

  // ML
  static const double cnnWeight = 0.65;
  static const double rfWeight = 0.35;
  static const int mcDropoutPasses = 10;

  // Grade names
  static const List<String> gradeNames = [
    'Dark', 'Deep', 'Vivid', 'Intense', 'Medium Intense', 'Light', 'Very Light',
  ];

  static const List<String> tradeNames = [
    'Midnight Blue', 'Twilight Blue', 'Royal Blue', 'Intense Cornflower',
    'Cornflower Blue', 'Pastel Blue', 'Near-Colourless',
  ];

  static const List<String> gradeColors = [
    '#020519', '#0B0F3F', '#091A72', '#2A408C', '#47619E', '#718BB7', '#ABBDD6',
  ];

  // Links
  static const String linkedInUrl = '';
  static const String githubUrl = 'https://github.com/Nirmana-KAS';
  static const String emailAddress = '';
}
```

Note: `apiBaseUrl` is `http://localhost:5000` (plain HTTP, not reachable from a phone).

## 7. pubspec dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  lottie: ^3.1.2
  provider: ^6.1.2
  go_router: ^14.2.7
  firebase_core: ^3.4.1
  firebase_auth: ^5.3.1
  google_sign_in: ^6.2.1
  http: ^1.2.2
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
  image_picker: ^1.1.2
  image_cropper: ^8.0.2
  sensors_plus: ^6.0.1
  pdf: ^3.11.1
  printing: ^5.13.2
  local_auth: ^2.3.0
  path_provider: ^2.1.4
  path: ^1.9.0
  share_plus: ^10.0.2
  flutter_native_splash: ^2.4.4
  url_launcher: ^6.3.0
  intl: ^0.19.0
  uuid: ^4.4.2
  flutter_markdown: ^0.7.4+3
  image: ^4.10.1
  device_info_plus: ^12.4.0
  connectivity_plus: ^7.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

`http` is present but not yet used for grading. No `mongo_dart`.

## 8. AndroidManifest permissions and network settings

- `src/main/AndroidManifest.xml`: `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`.
- **`INTERNET` is only in the `src/debug` and `src/profile` manifests; release builds have no INTERNET permission.**
- No `android:usesCleartextTraffic`, no `networkSecurityConfig`, no `res/xml/` folder. Android 9+ blocks cleartext HTTP by default, so an `http://` API URL fails on device; use HTTPS (API Gateway) or a debug-only network security config.
- `<queries>` contains only the Flutter `PROCESS_TEXT` intent.
