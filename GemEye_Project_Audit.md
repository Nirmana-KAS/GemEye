# GemEye — Read-Only Project Audit

- **Generated:** 30 September 2026
- **Audit type:** Read-only. No project file was created, modified, deleted or reformatted except this report.
- **Secrets policy:** All API keys, client IDs, tokens and certificate hashes are masked (first 4 characters + `****`).

---

## 1. Environment

**Operating system:** Microsoft Windows 11 Home Single Language, version 10.0.26200 (25H2, build 26200.9457)

**Full project path:** `C:\Users\sheha\OneDrive\Documents\GitHub\GemEye`

### flutter --version
```
Flutter 3.44.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 058e0af2c2 (10 weeks ago) • 2026-07-23 10:56:21 -0700
Engine • hash 13ffd72b2f9a5ca4db2a74ea52d5353ec2e8f939 (revision 0cd610717b) (2 months ago) • 2026-07-23 16:11:34.000Z
Tools • Dart 3.12.2 • DevTools 2.57.0
```
Flutter SDK root: `C:\src\flutter`

### dart --version
```
Dart SDK version: 3.12.2 (stable) (Tue Jun 9 01:11:39 2026 -0700) on "windows_x64"
```

### flutter doctor (summary)
```
Doctor summary (to see all details, run flutter doctor -v):
[√] Flutter (Channel stable, 3.44.8, on Microsoft Windows [Version 10.0.26200.9457], locale en-GB)
[√] Windows Version (Windows 11 or higher, 25H2, 2009)
[!] Android toolchain - develop for Android devices (Android SDK version 37.0.0)
    X Android license status unknown.
      Run `flutter doctor --android-licenses` to accept the SDK licenses.
      See https://flutter.dev/to/windows-android-setup for more details.
[√] Chrome - develop for the web
[√] Visual Studio - develop Windows apps (Visual Studio Build Tools 2026 18.8.2)
[√] Connected device (3 available)
[√] Network resources

! Doctor found issues in 1 category.
```

### python --version
```
Python 3.14.6
```

### py -0
```
 -V:3.14 *        Python 3.14.6
```

### pip --version
```
pip 26.2.1 from C:\Users\sheha\AppData\Roaming\Python\Python314\site-packages\pip (python 3.14)
```

### docker --version
```
Docker version 29.7.2, build a7dcaa6
```

### adb version
`adb` is **not on the system PATH**. Resolved from the Android SDK install:
```
Android Debug Bridge version 1.0.41
Version 37.0.1-15733141
Installed as C:\Users\sheha\AppData\Local\Android\sdk\platform-tools\adb.exe
Running on Windows 10.0.26200
```

### adb devices
```
List of devices attached
```
(no physical or emulated Android device attached at audit time)

### git remote -v
```
origin	https://github.com/Nirmana-KAS/GemEye.git (fetch)
origin	https://github.com/Nirmana-KAS/GemEye.git (push)
```

### git branch --show-current
```
main
```

### git log --oneline -15
```
86534b6 Add dataset image auto-renamer script
4ecedd1 Restructure dataset folders and ignore large assets
9de5cb2 Add dedicated profile screen and wire navigation
205ef2d Add settings and info screens
23f45d7 Wire drawer navigation and back handling
b01a0fa Add History & Comparison screens; wire navigation
818b80a Center processing content and step list
7d7135a Document verified processing centering fix
ca497e9 Center capture checklist as aligned group
8c59cb6 Center content on processing & capture screens
06f077c Fix splash and crop UX issues
3959658 Revamp certificate PDF and capture UX
0810db7 Add GemEye branding: icons, splash, and certificate PDF
71e47bc Track app assets with Git LFS
94361a6 Add grade persistence and certificate export
```

### git status --short
```
?? model/
```
The entire `model/` directory — including every trained model weight file — is **untracked**.

---

## 2. Folder structure

Depth 4, excluding `build`, `.dart_tool`, `.git`, `.idea`, `ios/Pods`, `android/.gradle`, `node_modules`, and image/dataset folders.

```
GemEye/
├── .gitattributes
├── .gitignore
├── CLAUDE.md
├── LICENSE
├── PROJECT_STATUS.md          (868 lines, 41 EDIT entries)
├── README.md                  (31 lines)
├── app/                       ← Flutter project
│   ├── .flutter-plugins-dependencies
│   ├── .gitignore
│   ├── .metadata
│   ├── README.md
│   ├── analysis_options.yaml
│   ├── firebase.json
│   ├── gemeye.iml
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── android/
│   │   ├── .gitignore
│   │   ├── build.gradle.kts
│   │   ├── gemeye_android.iml
│   │   ├── gradle.properties
│   │   ├── gradlew / gradlew.bat
│   │   ├── local.properties
│   │   ├── settings.gradle.kts
│   │   ├── app/
│   │   │   ├── build.gradle.kts
│   │   │   ├── google-services.json
│   │   │   └── src/            (main/, debug/, profile/ — see §4)
│   │   └── gradle/wrapper/
│   ├── assets/
│   │   ├── animations/
│   │   │   └── sapphire_rotate.json
│   │   ├── data/
│   │   │   ├── colour_grades.json
│   │   │   └── privacy_policy.md
│   │   ├── fonts/
│   │   │   ├── Inter-Medium.ttf
│   │   │   ├── Inter-Regular.ttf
│   │   │   ├── JetBrainsMono-Regular.ttf
│   │   │   ├── Poppins-Bold.ttf
│   │   │   └── Poppins-SemiBold.ttf
│   │   └── images/             (2 files)
│   │       └── onboarding/     (0 files — EMPTY)
│   ├── ios/
│   │   ├── Flutter/            (AppFrameworkInfo.plist, Debug/Release/Generated.xcconfig, ephemeral/)
│   │   ├── Runner/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── SceneDelegate.swift
│   │   │   ├── Info.plist
│   │   │   ├── Runner-Bridging-Header.h
│   │   │   ├── GeneratedPluginRegistrant.h / .m
│   │   │   ├── Assets.xcassets/
│   │   │   └── Base.lproj/
│   │   ├── Runner.xcodeproj/
│   │   ├── Runner.xcworkspace/
│   │   └── RunnerTests/RunnerTests.swift
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── config/
│   │   │   ├── constants.dart
│   │   │   ├── routes.dart
│   │   │   └── theme.dart
│   │   ├── models/
│   │   │   └── grade_result.dart
│   │   ├── providers/          ← EMPTY DIRECTORY (0 files)
│   │   ├── screens/            (20 files)
│   │   │   ├── about_screen.dart
│   │   │   ├── agreement_screen.dart
│   │   │   ├── calibration_screen.dart
│   │   │   ├── capture_screen.dart
│   │   │   ├── certificate_screen.dart
│   │   │   ├── comparison_screen.dart
│   │   │   ├── feedback_sheet.dart
│   │   │   ├── guide_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── main_shell.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── privacy_screen.dart
│   │   │   ├── processing_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── certificate_service.dart
│   │   │   └── storage_service.dart
│   │   └── widgets/
│   │       ├── bottom_nav.dart
│   │       └── side_drawer.dart
│   ├── linux/                  (CMake + runner scaffolding)
│   ├── macos/                  (Runner, Runner.xcodeproj, Flutter configs)
│   ├── windows/                (CMake + runner scaffolding)
│   ├── web/                    (index.html, manifest.json, favicon.png, icons/, splash/img/)
│   └── test/
│       └── widget_test.dart
├── backend/                    ← NO CODE AT ALL
│   └── models/.gitkeep
├── model/                      ← UNTRACKED in git
│   ├── saved_models/.gitkeep
│   └── trained_models/         (see §14)
│       ├── best_phase1.keras
│       ├── best_phase2.keras
│       ├── efficientnet_b0_gemeye.keras
│       ├── model_int8.tflite
│       ├── rf_model.pkl
│       ├── scaler.pkl
│       ├── ensemble_config.json
│       ├── confusion_matrix.png
│       ├── gradcam_samples.png
│       ├── phase1_curves.png / phase1_log.csv
│       └── phase2_curves.png / phase2_log.csv
├── docs/
│   ├── chapters/.gitkeep
│   ├── figures/.gitkeep
│   └── references/.gitkeep
└── dataset/                    (images .gitignored — counts below)
    ├── rename_images.py        (130 lines)
    ├── README.md
    ├── ccc_patches/
    ├── merged/grade_1_dark .. grade_7_very_light/
    ├── raw_by_shape/{baguette,oval,pear,round}/grade_1..grade_7/
    ├── processed/grade_1..grade_7/
    └── splits/{train,val,test}/
```

### Excluded image / dataset folder counts

| Folder | File count |
|---|---|
| `dataset/` (root files) | 2 |
| `dataset/ccc_patches/` | 7 |
| `dataset/merged/grade_1_dark/` | 161 |
| `dataset/merged/grade_2_deep/` | 161 |
| `dataset/merged/grade_3_vivid/` | 161 |
| `dataset/merged/grade_4_intense/` | 161 |
| `dataset/merged/grade_5_medium/` | 161 |
| `dataset/merged/grade_6_light/` | 161 |
| `dataset/merged/grade_7_very_light/` | 161 |
| `dataset/raw_by_shape/baguette/grade_1..grade_7` | 41 each (287 total) |
| `dataset/raw_by_shape/oval/grade_1..grade_7` | 41 each (287 total) |
| `dataset/raw_by_shape/pear/grade_1..grade_7` | 41 each (287 total) |
| `dataset/raw_by_shape/round/grade_1..grade_7` | 41 each (287 total) |
| `dataset/processed/grade_1..grade_7` | 1 each (7 total) |
| `dataset/splits/train`, `val`, `test` | 1 each (3 total) |
| `app/assets/images/` | 2 |
| `app/assets/images/onboarding/` | 0 (empty, but declared in `pubspec.yaml`) |
| `app/web/splash/img/` | 8 |

---

## 3. pubspec.yaml

Full contents of `app/pubspec.yaml`:

```yaml
name: gemeye
description: GemEye - Automated Blue Sapphire Colour Grading
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.5.0

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

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.14.3

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo.png"

flutter_native_splash:
  color: "#FFFFFF"
  image: "assets/images/logo.png"
  image_dark: "assets/images/logo.png"
  color_dark: "#FFFFFF"
  android_12:
    color: "#FFFFFF"
    color_dark: "#FFFFFF"

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/images/onboarding/
    - assets/animations/
    - assets/data/
  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
          weight: 400
```

**Declared but never imported anywhere in `lib/`:** `http`, `sensors_plus`, `local_auth`, `flutter_secure_storage`, `go_router`, `provider`, `intl`, `path`.

---

## 4. Android configuration

### Full contents of `app/android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <application
        android:label="gemeye"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <!-- Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI. -->
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
    </application>
    <!-- Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

### From `app/android/app/build.gradle.kts`

| Setting | Value |
|---|---|
| `namespace` | `com.gemeye.gemeye` |
| `applicationId` | `com.gemeye.gemeye` |
| `minSdk` | `flutter.minSdkVersion` → **24** (Flutter 3.44.8 default, `FlutterExtension.kt`) |
| `targetSdk` | `flutter.targetSdkVersion` → **36** |
| `compileSdk` | `flutter.compileSdkVersion` → **36** |
| `ndkVersion` | `flutter.ndkVersion` → **28.2.13676358** |
| Java / Kotlin target | 17 |
| Release signing | **Debug keystore** (`signingConfig = signingConfigs.getByName("debug")`) — no release signing config |
| Google Services plugin | Applied (`com.google.gms.google-services`) |

### Is INTERNET permission present?

**Not in the hand-written manifest.** It **is** in the merged manifest, injected transitively by plugins. From `app/build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml`:

```
android.permission.ACCESS_NETWORK_STATE
android.permission.CAMERA
android.permission.INTERNET
android.permission.READ_EXTERNAL_STORAGE
android.permission.READ_MEDIA_IMAGES
android.permission.USE_BIOMETRIC
android.permission.USE_FINGERPRINT
android.permission.WRITE_EXTERNAL_STORAGE
```

Networking will therefore work, but only because a plugin declares it — not by explicit project declaration. `USE_BIOMETRIC` / `USE_FINGERPRINT` arrive from `local_auth`, which no Dart code uses.

### Is usesCleartextTraffic set?

**NOT FOUND.** Absent from the source manifest and absent from the merged manifest. With `targetSdk` 36 the platform default blocks cleartext HTTP, which matters because `AppConstants.apiBaseUrl` is `http://localhost:5000` (plain HTTP).

### Does any network_security_config.xml exist?

**NOT FOUND.** No file with that name exists anywhere under `app/`.

---

## 5. Firebase and authentication

### Firebase services used

| Service | Used? | Evidence |
|---|---|---|
| Firebase Core | Yes | `app/lib/main.dart:11` — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` |
| Firebase Authentication | Yes | `app/lib/services/auth_service.dart`, `settings_screen.dart`, `profile_screen.dart` |
| Google Sign-In (`google_sign_in` + `GoogleAuthProvider`) | Yes | `auth_service.dart:10`, `:15-26` |
| Cloud Firestore | **NOT FOUND** — not in `pubspec.yaml`, not imported |
| Firebase Storage | **NOT FOUND** — a `storageBucket` is configured but no `firebase_storage` package |
| Analytics / Crashlytics / Messaging / Remote Config / Functions | **NOT FOUND** |
| MongoDB Atlas REST API (per `CLAUDE.md` plan) | **NOT FOUND** — no HTTP client code exists |

### Sign-in methods implemented in code

| Method | Implemented | Location |
|---|---|---|
| Google Sign-In | Yes | `AuthService.signInWithGoogle()` — `auth_service.dart:15`; called at `login_screen.dart:33` |
| Email/password sign-in | Yes | `AuthService.signInWithEmail()` — `auth_service.dart:42`; called at `login_screen.dart:67` |
| Email/password registration | Yes | `AuthService.registerWithEmail()` — `auth_service.dart:30`; called at `register_screen.dart:100` |
| Password reset e-mail | Yes | `AuthService.resetPassword()` — `auth_service.dart:61`; called at `login_screen.dart:97` |
| Display-name update | Yes | `auth_service.dart:57`; `register_screen.dart:101`; `profile_screen.dart:70` |
| Sign-out | Yes | `auth_service.dart:52`; drawer logout dialog in `side_drawer.dart` |
| Change e-mail (`verifyBeforeUpdateEmail`) | Yes | `settings_screen.dart` |
| Change password (re-auth + update) | Yes | `settings_screen.dart:518` |
| Delete account | Yes | `settings_screen.dart` `_showDeleteAccountDialog` |
| Anonymous / phone / Apple | **NOT FOUND** |
| Biometric lock (`local_auth`) | **NOT FOUND** in Dart code (package declared only) |

### Config files (file names only, values masked)

| File | Notes (masked) |
|---|---|
| `app/lib/firebase_options.dart` | FlutterFire-generated. `projectId: gemeye-app-2026`, `messagingSenderId: 7072****`. API keys: web `AIza****`, android `AIza****`, ios `AIza****`, macos `AIza****`, windows `AIza****`. `iosClientId: 7072****`. `iosBundleId: com.gemeye.gemeye`. |
| `app/android/app/google-services.json` | `project_number: 7072****`, `project_id: gemeye-app-2026`, `mobilesdk_app_id: 1:70****`, `api_key.current_key: AIza****`, `oauth_client` ids `7072****` (client_type 1 and 3), android `certificate_hash: f4ac****`, iOS other-platform client `7072****`. **Note:** this path is listed in the root `.gitignore`, yet the file is present on disk. |
| `app/firebase.json` | FlutterFire CLI project record. |
| `app/ios/Runner/GoogleService-Info.plist` | **NOT FOUND** — listed in `.gitignore` but absent from disk, so iOS Firebase is not configured natively. |

---

## 6. Screen inventory

| File path | Class name | Route / how it is opened | Purpose | Status | Where its data comes from |
|---|---|---|---|---|---|
| `app/lib/screens/splash_screen.dart` | `SplashScreen` | `MaterialApp.home` (`main.dart:37`) | 3 s Lottie splash, then auth-based routing | WORKING with real data | `AuthService.isLoggedIn` (Firebase Auth) |
| `app/lib/screens/agreement_screen.dart` | `AgreementScreen` | `pushReplacement` from `SplashScreen` when not logged in | User agreement, checkbox gate | WORKING with real data | `rootBundle.loadString('assets/data/privacy_policy.md')` |
| `app/lib/screens/login_screen.dart` | `LoginScreen` | `pushReplacement` from `AgreementScreen:200`; also after logout / account delete | Google + e-mail login, forgot password | WORKING with real data | Firebase Auth via `AuthService` |
| `app/lib/screens/register_screen.dart` | `RegisterScreen` | `push` from `LoginScreen:328` | Register, Individual/Company type | WORKING with real data | Firebase Auth. Company name/address collected in UI only — never persisted here |
| `app/lib/screens/onboarding_screen.dart` | `OnboardingScreen` | **Never referenced anywhere in `lib/`** — orphaned | 4-slide PageView onboarding | INCOMPLETE (unreachable) | Hardcoded `_SlideData` list; `assets/images/onboarding/` is empty |
| `app/lib/screens/main_shell.dart` | `MainShell` | `pushReplacement` from splash / login / register | Bottom nav + end drawer + `IndexedStack` | WORKING with real data | n/a (container) |
| `app/lib/screens/main_shell.dart` | `_PlaceholderScreen` | Index 1 of `MainShell._screens` — never actually displayed (tapping tab 1 pushes `CaptureScreen`) | "Coming soon" filler | PLACEHOLDER | n/a |
| `app/lib/screens/home_screen.dart` | `HomeScreen` | `MainShell` tab 0; drawer "Home" | Greeting, calibration banner, Grade CTA, stats, recent grades | WORKING with MOCK data | Greeting + avatar are real (Firebase Auth). **Stats are literals `'0'`, `'--'`, `'--'`; "Recent Grades" is a hardcoded empty state; calibration banner is unconditional; the big "Grade a Stone" card's `onTap` is an empty `// TODO` at line 129** |
| `app/lib/screens/calibration_screen.dart` | `CalibrationScreen` | `push` from `HomeScreen:81` banner; `SettingsScreen` "Recalibrate" | 3-step CCC calibration wizard | PLACEHOLDER (UI only) | Nothing. No camera, no patch detection, no matrix computation, no persistence. Success dialog shows a hardcoded "Residual ΔE: 1.4" |
| `app/lib/screens/capture_screen.dart` | `CaptureScreen` | `push` from `MainShell._onNavTap` (tab 1); drawer "Grade a Stone" | Camera / gallery capture + crop | WORKING with real data | `image_picker` (camera or gallery) → `image_cropper` (uCrop / TOCropViewController) |
| `app/lib/screens/processing_screen.dart` | `ProcessingScreen` | `push` from `CaptureScreen._cropAndProceed` | 7-step "AI pipeline" progress | WORKING with MOCK data | **`Timer`-driven fake steps; result is a hardcoded `GradeResult` (lines 56–72). No network call anywhere** |
| `app/lib/screens/result_screen.dart` | `ResultScreen` | `pushReplacement` from `ProcessingScreen`; `push` from `HistoryScreen` item tap | Grade badge, ±, confidence, colour values, Grad-CAM, save/export/share | WORKING with MOCK data | `widget.gradeResult` (mock) or `_createMockResult()` fallback (line 41). Grad-CAM panel is a static gradient placeholder |
| `app/lib/screens/certificate_screen.dart` | `CertificateScreen` | `push` from `ResultScreen._exportCertificate` | A4 PDF preview + save / share / print | WORKING with real data (rendering real; values mock) | `CertificateService.generateCertificatePdf()` from the `GradeResult` + image bytes |
| `app/lib/screens/history_screen.dart` | `HistoryScreen` | `MainShell` tab 2; drawer "Grading History" | Search, grade chips, filter sheet, sort, batch select, swipe-delete, batch export/share | WORKING with real data | `StorageService.getGradeHistory()` → `SharedPreferences` |
| `app/lib/screens/guide_screen.dart` | `GuideScreen` | `MainShell` tab 3; drawer "Colour Grade Guide" | Offline 7-grade reference | WORKING with real data | `rootBundle.loadString('assets/data/colour_grades.json')` |
| `app/lib/screens/comparison_screen.dart` | `ComparisonScreen` | `push` from drawer "Stone Comparison" | Side-by-side A/B + ΔE | WORKING with real data | `StorageService.getGradeHistory()`; ΔE computed locally at `comparison_screen.dart:129` |
| `app/lib/screens/settings_screen.dart` | `SettingsScreen` | `push` from drawer "Settings" | Profile, calibration, grading prefs, security, data management, app info | WORKING with real data (2 stubs) | Firebase Auth + `SharedPreferences` + `StorageService`. **"Calibration History" is a hardcoded empty sheet; `is_calibrated` is read at line 41 but never written by anything; `_exportData` builds a CSV then discards it** |
| `app/lib/screens/profile_screen.dart` | `ProfileScreen` | `push` from drawer header; `SettingsScreen` profile tile | Edit name / phone / company, show stats | WORKING with real data | Firebase Auth + `SharedPreferences` (`profile_phone`, `company_name`) + `StorageService.getGradeHistory()` |
| `app/lib/screens/about_screen.dart` | `AboutScreen` | `push` from drawer "About" | App info, developer, NSBM (line 164), Orava (line 193) | WORKING with real data | Hardcoded content + `AppConstants`. Student number is correctly **not** shown |
| `app/lib/screens/privacy_screen.dart` | `PrivacyScreen` | `push` from drawer "Privacy Policy" | Read-only policy | WORKING with real data | **Hardcoded Dart string sections — it does NOT read `assets/data/privacy_policy.md`; only `AgreementScreen` reads that file** |
| `app/lib/screens/feedback_sheet.dart` | `FeedbackSheet` | `showModalBottomSheet` from drawer "Feedback" | Star rating + comment | WORKING with real data (local only) | Writes to `SharedPreferences` key `feedback`; never transmitted anywhere |

Supporting widgets (not screens): `app/lib/widgets/bottom_nav.dart` → `GemEyeBottomNav`; `app/lib/widgets/side_drawer.dart` → `GemEyeSideDrawer`.

**Count:** 20 files in `lib/screens/`, 21 screen-level classes (including `_PlaceholderScreen`). `CLAUDE.md` specifies 16 screens; the certificate (plan screen 10) is implemented as both a service and a preview screen, and `ProfileScreen` / `CertificateScreen` are extras beyond the 16-screen list.

---

## 7. Mock and hardcoded data

Search scope: all of `app/lib/`. Terms searched: `42.3`, `8.9`, `-27.0`, `28.4`, `228`, `"Royal Blue"`, `"Vivid"`, `0.92`, `92`, `mock`, `dummy`, `fake`, `placeholder`, `TODO`, `FIXME`, `Future.delayed`, `hardcoded`, plus `simulate`.

### Hits (file:line and the code line)

| Location | Code line |
|---|---|
| `app/lib/config/constants.dart:34` | `'Dark', 'Deep', 'Vivid', 'Intense', 'Medium Intense', 'Light', 'Very Light',` |
| `app/lib/config/constants.dart:38` | `'Midnight Blue', 'Twilight Blue', 'Royal Blue', 'Intense Cornflower',` |
| `app/lib/screens/calibration_screen.dart:248` | `Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFF92400E)),` |
| `app/lib/screens/calibration_screen.dart:256` | `color: Color(0xFF92400E),` |
| `app/lib/screens/calibration_screen.dart:307` | `// Simulated viewfinder` |
| `app/lib/screens/calibration_screen.dart:426` | `// TODO: Implement actual camera capture and CCC processing` |
| `app/lib/screens/calibration_screen.dart:453` | `'Residual ΔE: 1.4 (excellent)\nYour device is ready for grading.',` |
| `app/lib/screens/home_screen.dart:116` | `color: Color(0xFF92400E),` |
| `app/lib/screens/home_screen.dart:121` | `size: 14, color: Color(0xFF92400E)),` |
| `app/lib/screens/home_screen.dart:129` | `// TODO: Navigate to capture screen` |
| `app/lib/screens/main_shell.dart:31` | `const _PlaceholderScreen(title: 'Grade', icon: Icons.camera_alt_rounded),` |
| `app/lib/screens/main_shell.dart:104` | `class _PlaceholderScreen extends StatelessWidget {` |
| `app/lib/screens/main_shell.dart:108` | `const _PlaceholderScreen({required this.title, required this.icon});` |
| `app/lib/screens/processing_screen.dart:33` | `_simulateProcessing();` |
| `app/lib/screens/processing_screen.dart:36` | `void _simulateProcessing() {` |
| `app/lib/screens/processing_screen.dart:56` | `gradeNumber: 3,` |
| `app/lib/screens/processing_screen.dart:59` | `gradeName: 'Vivid',` |
| `app/lib/screens/processing_screen.dart:60` | `tradeName: 'Royal Blue',` |
| `app/lib/screens/processing_screen.dart:61` | `confidence: 92.4,` |
| `app/lib/screens/processing_screen.dart:62` | `uncertaintyRange: 0.2,` |
| `app/lib/screens/processing_screen.dart:63` | `labL: 42.3,` |
| `app/lib/screens/processing_screen.dart:64` | `labA: 8.9,` |
| `app/lib/screens/processing_screen.dart:65` | `labB: -27.0,` |
| `app/lib/screens/processing_screen.dart:66` | `labC: 28.4,` |
| `app/lib/screens/processing_screen.dart:67` | `hue: 228,` |
| `app/lib/screens/processing_screen.dart:68` | `saturation: 88,` |
| `app/lib/screens/processing_screen.dart:69` | `brightness: 62,` |
| `app/lib/screens/processing_screen.dart:70` | `deltaE: 1.2,` |
| `app/lib/screens/result_screen.dart:38` | `_result = widget.gradeResult ?? _createMockResult();` |
| `app/lib/screens/result_screen.dart:41` | `GradeResult _createMockResult() {` |
| `app/lib/screens/result_screen.dart:43` | `stoneId: 'GE-STONE-00000',` |
| `app/lib/screens/result_screen.dart:44` | `gradeNumber: 3,` |
| `app/lib/screens/result_screen.dart:45` | `gradeName: 'Vivid',` |
| `app/lib/screens/result_screen.dart:46` | `tradeName: 'Royal Blue',` |
| `app/lib/screens/result_screen.dart:47` | `confidence: 92.4,` |
| `app/lib/screens/result_screen.dart:48` | `uncertaintyRange: 0.2,` |
| `app/lib/screens/result_screen.dart:49` | `labL: 42.3,` |
| `app/lib/screens/result_screen.dart:50` | `labA: 8.9,` |
| `app/lib/screens/result_screen.dart:51` | `labB: -27.0,` |
| `app/lib/screens/result_screen.dart:52` | `labC: 28.4,` |
| `app/lib/screens/result_screen.dart:53` | `hue: 228,` |
| `app/lib/screens/result_screen.dart:54` | `saturation: 88,` |
| `app/lib/screens/result_screen.dart:55` | `brightness: 62,` |
| `app/lib/screens/result_screen.dart:56` | `deltaE: 1.2,` |

No hits at all for `0.92`, `FIXME`, `Future.delayed`, `dummy`, `fake`, or the literal string `hardcoded`.

### Further hardcoded / stub data found outside those exact search terms

| Location | What is hardcoded |
|---|---|
| `app/lib/screens/home_screen.dart:170-174` | Stat cards `_buildStatCard('0', 'Today')`, `('--', 'Avg Conf')`, `('--', 'Avg ΔE₀₀')`. `StorageService.getTodayCount()` and `getGradeCount()` already exist and are never called |
| `app/lib/screens/home_screen.dart:97-123` | Calibration banner text is unconditional: "Not calibrated yet. Calibrate before grading." |
| `app/lib/screens/home_screen.dart:186-217` | "Recent Grades" is a fixed empty-state card; history is never read |
| `app/lib/screens/result_screen.dart:434-470` | Grad-CAM panel: a static `RadialGradient` with the captions "Heatmap generated after model deployment" / "Connect to cloud backend to enable" |
| `app/lib/services/certificate_service.dart:322-335` | PDF "AI ATTENTION MAP" always falls back to placeholder text, because every call site passes `gradcamImage: null` |
| `app/lib/models/grade_result.dart:103-112` | `gradeColourHex` map (`#091A47`, `#102670`, `#1B3A8C`, `#2E5BB8`, `#4A80D4`, `#7BA7E8`, `#A8C8F0`) does **not** match the `CLAUDE.md` grade hexes (`#020519`…`#ABBDD6`) |
| `app/lib/screens/history_screen.dart:36-42`, `comparison_screen.dart:19-27` | The same non-spec grade colour map is duplicated in two more places |
| `app/assets/data/colour_grades.json` | Trade names (`Ink Blue`, `Midnight Blue`, `Royal Blue`, `Sapphire Blue`, `Ceylon Blue`, `Sky Blue`, `Ice Blue`) contradict both `AppConstants.tradeNames` and `CLAUDE.md`; grade 5 name is `Medium` here vs. `Medium Intense` in constants |
| `app/lib/screens/settings_screen.dart:131-171` | "Calibration History" bottom sheet is a hardcoded "No calibrations recorded yet" |
| `app/lib/screens/settings_screen.dart:592-621` | `_exportData()` builds a CSV in a `StringBuffer`, never writes or shares it, then shows "Data exported successfully" |
| `app/lib/config/constants.dart:3` | `apiBaseUrl = 'http://localhost:5000'` — dev placeholder, and referenced by no code |
| `app/lib/config/constants.dart:46,48` | `linkedInUrl = ''` and `emailAddress = ''` are empty strings |
| `app/lib/screens/onboarding_screen.dart:18-40` | 4 hardcoded slides in an unreachable screen |
| `app/lib/screens/privacy_screen.dart:29+` | All policy text is inline Dart strings rather than the shipped markdown asset |

### Where exactly is the mock grading result created?

**Primary location — `app/lib/screens/processing_screen.dart`, `_navigateToResult()` (lines 53–83):**

```dart
Future<void> _navigateToResult() async {
  final stoneId = await StorageService.getNextStoneId();

  final result = GradeResult(
    stoneId: stoneId,
    gradeNumber: 3,
    gradeName: 'Vivid',
    tradeName: 'Royal Blue',
    confidence: 92.4,
    uncertaintyRange: 0.2,
    labL: 42.3,
    labA: 8.9,
    labB: -27.0,
    labC: 28.4,
    hue: 228,
    saturation: 88,
    brightness: 62,
    deltaE: 1.2,
    capturedImagePath: widget.imagePath,
  );

  if (mounted) {
    AppRoutes.pushReplacement(
      context,
      ResultScreen(imagePath: widget.imagePath, gradeResult: result),
    );
  }
}
```

Every stone graded in the app yields this identical Grade 3 / Vivid / Royal Blue result, whatever the photograph. Only `capturedImagePath`, `stoneId`, `id` (UUID), `capturedAt` and `sessionId` vary.

**Secondary location — `app/lib/screens/result_screen.dart`, `_createMockResult()` (lines 41–58):** a byte-identical fallback with `stoneId: 'GE-STONE-00000'`, used only if `ResultScreen` is built without a `gradeResult`. Both current call sites pass one, so this path is currently dead, but the `'GE-STONE-00000'` sentinel is still special-cased in `_saveAndGradeNext()` and `_exportCertificate()`.

**Fake pipeline — `app/lib/screens/processing_screen.dart`, `_simulateProcessing()` (lines 36–50):** seven `Timer`s at 400 ms intervals (2.8 s), then a 500 ms tail, advancing a step counter. The labels ("Uploading image", "Applying colour correction", "Segmenting stone", "Classifying facet regions", "Extracting 12-D features", "Running ensemble AI", "Generating Grad-CAM") describe work that never happens. There is no `package:http` import anywhere in `lib/`.

---

## 8. End-to-end grading flow

### Step 0 — entry points

The Home screen's large "Grade a Stone" card is **dead** — `home_screen.dart:127-129` has `onTap: () { // TODO: Navigate to capture screen }`. The two working entry points are:

| Entry point | File / function | Action |
|---|---|---|
| Bottom-nav "Grade" tab | `main_shell.dart:22-27` `_MainShellState._onNavTap(int index)` | `if (index == 1) AppRoutes.push(context, const CaptureScreen());` |
| Drawer "Grade a Stone" | `side_drawer.dart` `_buildMenuItem(... 'Grade a Stone' ...)` | `Navigator.pop(context); AppRoutes.push(context, const CaptureScreen());` |

`AppRoutes.push` (`config/routes.dart:9`) is a thin wrapper over `Navigator.of(context).push(MaterialPageRoute(...))`. **Data passed: none** — `CaptureScreen` is a `const` constructor with no parameters.

### Step 1 — capture

**File:** `app/lib/screens/capture_screen.dart`
**Function:** `_captureImage()` (lines 18–47) or `_pickFromGallery()` (lines 49–75)

```dart
final XFile? photo = await picker.pickImage(
  source: ImageSource.camera,   // or ImageSource.gallery
  maxWidth: 2048,
  maxHeight: 2048,
  imageQuality: 95,
);
```

- **Type produced:** `XFile?` from `image_picker`.
- **Passed onward:** `await _cropAndProceed(photo.path)` — only the **`String` file path**, not the `XFile`, not bytes.
- **Image properties:** long edge capped at 2048 px, aspect ratio preserved, re-encoded as **JPEG at quality 95**. `image_picker` always re-encodes to JPEG when `maxWidth`/`maxHeight`/`imageQuality` are supplied.
- **No blur check, no light-level check, no exposure lock, no `sensors_plus` reading.** The four "Macro lens attached / CPL filter on / Stone on white tray / Even lighting" rows (`_buildCheckItem`, lines 332–355) are static green ticks — non-interactive decoration.

### Step 2 — crop

**File:** `app/lib/screens/capture_screen.dart`
**Function:** `_cropAndProceed(String imagePath)` (lines 77–115)

```dart
final croppedFile = await ImageCropper().cropImage(
  sourcePath: imagePath,
  uiSettings: [
    AndroidUiSettings(
      toolbarTitle: 'Crop Stone Image',
      toolbarColor: const Color(0xFF1B3A8C),
      toolbarWidgetColor: Colors.white,
      activeControlsWidgetColor: const Color(0xFF1B3A8C),
      hideBottomControls: false,
      showCropGrid: true,
      lockAspectRatio: false,
    ),
    IOSUiSettings(title: 'Crop Stone Image', aspectRatioLockEnabled: false),
  ],
);
```

- **Type produced:** `CroppedFile?`.
- **Cropped image width / height / format:** `cropImage` is called with **no `maxWidth`, no `maxHeight`, no `compressQuality`, no `compressFormat`, no `aspectRatio` and no `CropAspectRatioPreset` list**. Therefore the output dimensions are entirely whatever rectangle the user drags (bounded above by the 2048 px source), the aspect ratio is free, and the format defaults to the plugin default — **JPEG at quality 90** on Android (uCrop) and iOS. No square/224×224 normalisation is applied anywhere; nothing resizes the image to the model's 224×224 input.
- **Passed onward:** `AppRoutes.push(context, ProcessingScreen(imagePath: croppedFile.path))` — again only a **`String` path**.
- **Failure path (lines 107–114):** on any exception a warning SnackBar ("Crop unavailable — using original image") is shown and the **original uncropped path** is pushed instead. Note the `catch` also fires if the user cancels in some plugin versions, and `croppedFile == null` (user cancelled) silently returns without navigating.

### Step 3 — processing (simulated)

**File:** `app/lib/screens/processing_screen.dart`
**Received data:** `final String imagePath` (constructor parameter, line 11).
**Functions:** `initState()` → `_simulateProcessing()` (lines 36–50) → `_navigateToResult()` (lines 53–83).

- `_simulateProcessing()` schedules 7 `Timer`s at 400 ms × (i+1), i.e. 400–2800 ms, then a final 500 ms delay. Total ≈ 3.3 s.
- **No upload. No HTTP. No model inference. No colour correction. The image bytes are never read at this stage.**
- `_navigateToResult()` calls `StorageService.getNextStoneId()` (SharedPreferences counter `stone_counter`, formatted `GE-STONE-00001`), constructs the hardcoded `GradeResult` shown in §7, and calls:

```dart
AppRoutes.pushReplacement(
  context,
  ResultScreen(imagePath: widget.imagePath, gradeResult: result),
);
```

- **Passed onward:** a `String imagePath` **and** a fully-populated `GradeResult` object (which itself carries `capturedImagePath: widget.imagePath`).

### Step 4 — result display

**File:** `app/lib/screens/result_screen.dart`
**Received data:** `final String imagePath`, `final GradeResult? gradeResult`.
**Function:** `initState()` line 38 — `_result = widget.gradeResult ?? _createMockResult();`

The image is rendered with `Image.file(File(widget.imagePath))` (line 211). The first time bytes are actually read from disk is here, and only for display.

### Step 5 — save to history

**File:** `app/lib/screens/result_screen.dart`
**Function:** `_saveAndGradeNext()` (lines 60–100), bound to the "Save & Grade Next" button.

1. If `_result.stoneId == 'GE-STONE-00000'`, a new `GradeResult` is rebuilt field-by-field with a freshly allocated `stoneId` (lines 63–86).
2. `await StorageService.saveGradeResult(_result);`
3. `StorageService.saveGradeResult` (`storage_service.dart:10-21`): loads the existing list, replaces by `id` or `insert(0, …)`, then `prefs.setStringList('grade_history', history.map((r) => jsonEncode(r.toJson())).toList())`.
4. **Data persisted:** one JSON string per grade in a `SharedPreferences` `List<String>`. The image itself is **not** copied or embedded — only `capturedImagePath` (the cache-directory path) is stored.
5. `Navigator.of(context).popUntil((route) => route.isFirst)` returns the user to `MainShell`.

### Step 6 (optional) — certificate export

**File:** `app/lib/screens/result_screen.dart`
**Function:** `_exportCertificate()` (lines 102–160).

1. Same `'GE-STONE-00000'` rebuild as above.
2. `if (_result.certificateNumber == null) _result.certificateNumber = await CertificateService.generateCertificateNumber();` — increments `certificate_counter` in SharedPreferences and formats `GE-YYYYMM-NNNNN`. Re-export reuses the existing number (correct per spec).
3. `await StorageService.saveGradeResult(_result);`
4. `stoneImageBytes = await File(widget.imagePath).readAsBytes();` → **`Uint8List`** (empty `Uint8List(0)` on failure).
5. `AppRoutes.push(context, CertificateScreen(result: _result, stoneImageBytes: stoneImageBytes))` — passes the `GradeResult` object and the raw **`Uint8List`**. `gradcamImageBytes` is left `null`.
6. `CertificateScreen._generatePdf()` → `CertificateService.generateCertificatePdf(result:, stoneImage:, gradcamImage:)` → returns `Uint8List` PDF bytes for `PdfPreview`.

### Full data-type chain

```
(no data)                       MainShell._onNavTap / side_drawer
    ↓
XFile?                          CaptureScreen._captureImage  (image_picker, ≤2048px, JPEG q95)
    ↓  .path  → String
String sourcePath               CaptureScreen._cropAndProceed
    ↓  ImageCropper().cropImage → CroppedFile?  (free aspect, unbounded size, JPEG q90 default)
    ↓  .path  → String
String imagePath                ProcessingScreen(imagePath:)
    ↓  + hardcoded GradeResult
String imagePath, GradeResult   ResultScreen(imagePath:, gradeResult:)
    ↓  jsonEncode(result.toJson())  → String in SharedPreferences List<String>
    ↓  File(imagePath).readAsBytes() → Uint8List
GradeResult, Uint8List          CertificateScreen(result:, stoneImageBytes:)
    ↓
Uint8List (PDF)                 CertificateService.generateCertificatePdf
```

### Where the captured and cropped image files live on the device

Neither the app nor any of its code chooses a location — both paths come from the plugins' own temporary directories:

| Artefact | Location | Notes |
|---|---|---|
| Camera / gallery capture (`XFile.path`) | Android app **cache** directory, i.e. `/data/user/0/com.gemeye.gemeye/cache/…` (image_picker writes a scaled JPEG here). iOS: `NSTemporaryDirectory()` under the app sandbox | Written by `image_picker`; nothing in `lib/` sets a destination |
| Cropped image (`CroppedFile.path`) | Android app **cache** directory (uCrop output, same cache root). iOS: app temporary directory | Written by `image_cropper`; nothing in `lib/` sets a destination |
| Saved certificate PDF | Android: `/storage/emulated/0/Download/GemEye Certificates/<CERT>.pdf` (hardcoded at `certificate_screen.dart:66`). Other platforms: `getApplicationDocumentsDirectory()/GemEye Certificates/` | `certificate_screen.dart:_savePdf()` |
| Batch-exported certificate PDFs | `getApplicationDocumentsDirectory()/GemEye Certificates/<CERT>.pdf` | `history_screen.dart:186-194` — note this is a **different** directory from the single-export path |
| Shared result PNG | `getTemporaryDirectory()/gemeye_result.png` | `result_screen.dart:_shareResult()` |

**Consequence:** stone images are only ever in a cache directory, and only the path string is persisted. Android may evict cache at any time, and it is cleared by "Clear cache" in system settings, so history thumbnails and certificate re-exports will break for older records. The `auto_save_images` setting exists in `SharedPreferences` (`settings_screen.dart:293`) but **no code reads it** — nothing ever copies an image to durable storage.

---

## 9. Full contents of key files

### 9.1 `app/lib/models/grade_result.dart` (114 lines — full)

```dart
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

### 9.2 Any API / service / backend / HTTP class

**NOT FOUND.** There is no API client, no backend service class, and no HTTP code anywhere in `lib/`. `package:http` is declared in `pubspec.yaml` but never imported. The only classes in `lib/services/` are:

- `AuthService` (Firebase Auth / Google Sign-In) — shown below
- `StorageService` (SharedPreferences) — §9.8
- `CertificateService` (PDF generation, local) — §9.6

`app/lib/services/auth_service.dart` (73 lines — full):

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String getFirstName() {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return user.email?.split('@').first ?? 'User';
  }
}
```

### 9.3 `app/lib/screens/processing_screen.dart` (195 lines — full)

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Uploading image',
    'Applying colour correction',
    'Segmenting stone',
    'Classifying facet regions',
    'Extracting 12-D features',
    'Running ensemble AI',
    'Generating Grad-CAM',
  ];

  @override
  void initState() {
    super.initState();
    _simulateProcessing();
  }

  void _simulateProcessing() {
    for (int i = 0; i < _steps.length; i++) {
      Timer(Duration(milliseconds: 400 * (i + 1)), () {
        if (mounted) {
          setState(() => _currentStep = i + 1);
          if (i == _steps.length - 1) {
            Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                _navigateToResult();
              }
            });
          }
        }
      });
    }
  }

  Future<void> _navigateToResult() async {
    final stoneId = await StorageService.getNextStoneId();

    final result = GradeResult(
      stoneId: stoneId,
      gradeNumber: 3,
      gradeName: 'Vivid',
      tradeName: 'Royal Blue',
      confidence: 92.4,
      uncertaintyRange: 0.2,
      labL: 42.3,
      labA: 8.9,
      labB: -27.0,
      labC: 28.4,
      hue: 228,
      saturation: 88,
      brightness: 62,
      deltaE: 1.2,
      capturedImagePath: widget.imagePath,
    );

    if (mounted) {
      AppRoutes.pushReplacement(
        context,
        ResultScreen(
          imagePath: widget.imagePath,
          gradeResult: result,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/animations/sapphire_rotate.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.diamond_rounded,
                        size: 56,
                        color: GemEyeColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Analysing Stone...',
                  style: TextStyle(
                    fontFamily: GemEyeFonts.heading,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: GemEyeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_steps.length, (index) {
                      final isCompleted = index < _currentStep;
                      final isActive = index == _currentStep;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? GemEyeColors.success
                                    : isActive
                                        ? GemEyeColors.primary
                                        : GemEyeColors.border,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                    : isActive
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _steps[index],
                              style: TextStyle(
                                fontFamily: GemEyeFonts.body,
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                                color: isCompleted || isActive
                                    ? GemEyeColors.textPrimary
                                    : GemEyeColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '~${((_steps.length - _currentStep) * 0.4).toStringAsFixed(1)}s remaining',
                  style: const TextStyle(
                    fontFamily: GemEyeFonts.body,
                    fontSize: 11,
                    color: GemEyeColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 9.4 `app/lib/screens/result_screen.dart` (617 lines — data-flow parts in full, presentation summarised)

Full imports, state, and every logic method:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../models/grade_result.dart';
import '../services/storage_service.dart';
import '../services/certificate_service.dart';
import 'certificate_screen.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final GradeResult? gradeResult;

  const ResultScreen({
    super.key,
    required this.imagePath,
    this.gradeResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  late GradeResult _result;
  bool _isSaving = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _result = widget.gradeResult ?? _createMockResult();
  }

  GradeResult _createMockResult() {
    return GradeResult(
      stoneId: 'GE-STONE-00000',
      gradeNumber: 3,
      gradeName: 'Vivid',
      tradeName: 'Royal Blue',
      confidence: 92.4,
      uncertaintyRange: 0.2,
      labL: 42.3,
      labA: 8.9,
      labB: -27.0,
      labC: 28.4,
      hue: 228,
      saturation: 88,
      brightness: 62,
      deltaE: 1.2,
      capturedImagePath: widget.imagePath,
    );
  }

  Future<void> _saveAndGradeNext() async {
    setState(() => _isSaving = true);
    try {
      if (_result.stoneId == 'GE-STONE-00000') {
        final stoneId = await StorageService.getNextStoneId();
        _result = GradeResult(
          id: _result.id,
          stoneId: stoneId,
          gradeNumber: _result.gradeNumber,
          gradeName: _result.gradeName,
          tradeName: _result.tradeName,
          confidence: _result.confidence,
          uncertaintyRange: _result.uncertaintyRange,
          labL: _result.labL,
          labA: _result.labA,
          labB: _result.labB,
          labC: _result.labC,
          hue: _result.hue,
          saturation: _result.saturation,
          brightness: _result.brightness,
          deltaE: _result.deltaE,
          capturedImagePath: _result.capturedImagePath,
          gradcamImagePath: _result.gradcamImagePath,
          certificateNumber: _result.certificateNumber,
          capturedAt: _result.capturedAt,
          sessionId: _result.sessionId,
        );
      }
      await StorageService.saveGradeResult(_result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stone saved — ${_result.stoneId}')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save result')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportCertificate() async {
    setState(() => _isExporting = true);
    try {
      if (_result.stoneId == 'GE-STONE-00000') {
        final stoneId = await StorageService.getNextStoneId();
        _result = GradeResult(
          id: _result.id,
          stoneId: stoneId,
          gradeNumber: _result.gradeNumber,
          gradeName: _result.gradeName,
          tradeName: _result.tradeName,
          confidence: _result.confidence,
          uncertaintyRange: _result.uncertaintyRange,
          labL: _result.labL,
          labA: _result.labA,
          labB: _result.labB,
          labC: _result.labC,
          hue: _result.hue,
          saturation: _result.saturation,
          brightness: _result.brightness,
          deltaE: _result.deltaE,
          capturedImagePath: _result.capturedImagePath,
          gradcamImagePath: _result.gradcamImagePath,
          certificateNumber: _result.certificateNumber,
          capturedAt: _result.capturedAt,
          sessionId: _result.sessionId,
        );
      }

      if (_result.certificateNumber == null) {
        final certNumber = await CertificateService.generateCertificateNumber();
        _result.certificateNumber = certNumber;
      }

      await StorageService.saveGradeResult(_result);

      Uint8List stoneImageBytes;
      try {
        stoneImageBytes = await File(widget.imagePath).readAsBytes();
      } catch (_) {
        stoneImageBytes = Uint8List(0);
      }

      if (mounted) {
        AppRoutes.push(
          context,
          CertificateScreen(
            result: _result,
            stoneImageBytes: stoneImageBytes,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate certificate')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareResult() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/gemeye_result.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'GemEye Grade ${_result.gradeNumber} — ${_result.gradeName} (${_result.tradeName})',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share result')),
        );
      }
    }
  }
```

The Grad-CAM panel, in full, because it is the placeholder that a real backend must replace (lines 434–496):

```dart
  Widget _buildGradCam() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GemEyeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GRAD-CAM HEATMAP', style: TextStyle(/* … */)),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const RadialGradient(
                center: Alignment(-0.1, 0.0),
                colors: [
                  Color(0x99EF4444),
                  Color(0x66F59E0B),
                  Color(0x3310B981),
                  Color(0x331B3A8C),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Heatmap generated after model deployment', /* … */),
                  SizedBox(height: 4),
                  Text('Connect to cloud backend to enable', /* … */),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Red = high influence on prediction · Blue = low influence', /* … */),
        ],
      ),
    );
  }
```

**Summary of the remaining ~230 lines (presentation only, no data flow):**
- `build()` (lines 190–290): `AppBar` with a share action; a `SingleChildScrollView` wrapping a `RepaintBoundary` (key `_repaintKey`, used by `_shareResult`) containing `Image.file(File(widget.imagePath))` (200 px, `BoxFit.cover`, with a diamond-icon `errorBuilder`), then `_buildGradeBadge()`, `_buildColourValues()`, `_buildGradCam()`; below the boundary a `Row` with the "Save & Grade Next" `ElevatedButton` and the "Export Certificate" `OutlinedButton`, both showing spinners while `_isSaving` / `_isExporting`.
- `_buildGradeBadge()` (lines 292–398): navy gradient card showing "GEMCLOUD GRADE", `Grade N`, `gradeName — tradeName`, a `± {uncertaintyRange} grades` chip in JetBrains Mono, and a `{confidenceLevel} CONFIDENCE` chip coloured green/amber/red from `_result.confidenceLevel`.
- `_buildColourValues()` (lines 400–432): a card of `_buildValueRow` pairs — Lightness/Green-Red, Blue-Yellow/Chroma, Hue/Saturation, Brightness/Delta E — plus a hex swatch row driven by `_result.gradeColourHex`.
- `_buildValueRow()` (lines 498–617): a two-column label/value row helper using `GemEyeFonts.mono` for values.

### 9.5 `app/lib/screens/capture_screen.dart` (355 lines — logic in full, UI summarised)

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import 'processing_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isCapturing = false;

  Future<void> _captureImage() async {
    setState(() => _isCapturing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (photo == null) {
        setState(() => _isCapturing = false);
        return;
      }

      await _cropAndProceed(photo.path);
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: GemEyeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isCapturing = true);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (photo == null) {
        setState(() => _isCapturing = false);
        return;
      }

      await _cropAndProceed(photo.path);
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: ${e.toString()}'),
            backgroundColor: GemEyeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cropAndProceed(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Stone Image',
            toolbarColor: const Color(0xFF1B3A8C),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF1B3A8C),
            hideBottomControls: false,
            showCropGrid: true,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Stone Image',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      setState(() => _isCapturing = false);

      if (croppedFile != null && mounted) {
        AppRoutes.push(context, ProcessingScreen(imagePath: croppedFile.path));
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crop unavailable — using original image'),
            backgroundColor: GemEyeColors.warning,
          ),
        );
        AppRoutes.push(context, ProcessingScreen(imagePath: imagePath));
      }
    }
  }
```

**Summary of the remaining ~240 lines (`build()` and `_buildCheckItem()`, presentation only):** a `Scaffold` with the "Grade Stone" `AppBar`; an `Expanded` grey (`#F5F7FA`) instruction card containing the heading "Capture Your Sapphire", the hint "Place stone face-up on white tray. Take photo with macro lens. Crop after capture.", a 140×140 framing diagram built from four `Positioned` corner brackets plus an 85 px green circle with a faint diamond icon, the captions "Zoom until stone fills the circle" and "Stone should be ~70% of the frame for best results", and four static `_buildCheckItem` rows (green tick + label: "Macro lens attached", "CPL filter on", "Stone on white tray", "Even lighting"). Below that, either a `CircularProgressIndicator` (while `_isCapturing`) or a "Take Photo" `ElevatedButton.icon` and a "Choose from Gallery" `OutlinedButton.icon`. **There is no live camera preview, no blur metric, no lux reading, and no exposure lock anywhere in this file.**

### 9.6 The crop logic

All cropping lives in `_cropAndProceed` above (`capture_screen.dart:77-115`). There is no separate crop helper, no `image` package usage, and no pixel-level processing anywhere in the project. `ImageCropper().cropImage` is called with `sourcePath` and `uiSettings` only — no `maxWidth`, `maxHeight`, `aspectRatio`, `aspectRatioPresets`, `compressFormat` or `compressQuality`.

### 9.7 `app/lib/screens/calibration_screen.dart` (483 lines — logic in full, UI summarised)

The only non-presentational code in the file is the step counter and the completion handler:

```dart
class _CalibrationScreenState extends State<CalibrationScreen> {
  int _currentStep = 0;
  // …
  // Bottom button onPressed:
  //   if (_currentStep < 2) { setState(() => _currentStep++); }
  //   else { _completeCalibration(); }
```

```dart
  void _completeCalibration() {
    // TODO: Implement actual camera capture and CCC processing
    // For now, show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GemEyeColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 40, color: GemEyeColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Calibration Complete',
              style: TextStyle(
                fontFamily: GemEyeFonts.heading,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: GemEyeColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Residual ΔE: 1.4 (excellent)\nYour device is ready for grading.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 13,
                color: GemEyeColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to home
              },
              child: const Text('Start Grading'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Summary of the remaining ~420 lines (all presentation):**
- `build()`: a 3-segment progress bar, a "Step N of 3" label, `_buildStepContent()`, and a bottom `ElevatedButton` reading "Next" or "Complete Calibration".
- `_buildStep1()`: grid icon, heading "Place CCC Card", instructions, and a card of six `_buildPatchPreview` swatches — White `#F0F0F0`, 18% Grey `#767676`, Blue `#004D8D`, Black `#101010`, 50% Grey `#B5B5B5`, Red `#95444F`.
- `_buildStep2()`: phone icon, heading "Mount Phone on Tripod", instructions naming the Apexel 100 mm macro lens and CPL filter, plus an amber lighting tip.
- `_buildStep3()`: camera icon, heading "Capture CCC Card", text claiming "The system will detect all 6 patches and compute your device's colour correction matrix automatically", then a **fake dark viewfinder** (`// Simulated viewfinder`, line 307) showing the same six static swatches each ringed in green as though detected, with the caption 'Tap "Complete Calibration" to capture', and an info box stating calibration is session-valid.
- `_buildPatchPreview()`, `_buildViewfinderPatch()`: swatch helpers.

**No camera plugin is imported. No image is captured. No colour matrix is computed. Nothing is written to `SharedPreferences` or anywhere else.**

### 9.8 `app/lib/services/storage_service.dart` (74 lines — full)

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';

class StorageService {
  static const String _historyKey = 'grade_history';
  static const String _stoneCounterKey = 'stone_counter';

  static Future<void> saveGradeResult(GradeResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGradeHistory();
    final existingIndex = history.indexWhere((r) => r.id == result.id);
    if (existingIndex >= 0) {
      history[existingIndex] = result;
    } else {
      history.insert(0, result);
    }
    final jsonList = history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  static Future<List<GradeResult>> getGradeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    final results = jsonList
        .map((s) => GradeResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    results.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return results;
  }

  static Future<void> deleteGradeResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getGradeHistory();
    history.removeWhere((r) => r.id == id);
    final jsonList = history.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<GradeResult?> getGradeResultById(String id) async {
    final history = await getGradeHistory();
    try {
      return history.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<String> getNextStoneId() async {
    final prefs = await SharedPreferences.getInstance();
    final counter = (prefs.getInt(_stoneCounterKey) ?? 0) + 1;
    await prefs.setInt(_stoneCounterKey, counter);
    return 'GE-STONE-${counter.toString().padLeft(5, '0')}';
  }

  static Future<int> getGradeCount() async {
    final history = await getGradeHistory();
    return history.length;
  }

  static Future<int> getTodayCount() async {
    final history = await getGradeHistory();
    final now = DateTime.now();
    return history.where((r) =>
        r.capturedAt.year == now.year &&
        r.capturedAt.month == now.month &&
        r.capturedAt.day == now.day).length;
  }
}
```

### 9.9 `app/lib/config/constants.dart` (49 lines — full; no secrets present to mask)

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

**No API keys or tokens are present in this file.** `apiBaseUrl`, `gradeEndpoint`, `calibrateEndpoint`, `minBlurThreshold`, `minLuxGood`, `minLuxLow`, `cnnWeight`, `rfWeight`, `mcDropoutPasses`, `requiredPatches`, `maxAcceptableDeltaE`, `gradeColors`, `studentNo` and `tradeNames` are all **unreferenced by any code**. Also note `cnnWeight`/`rfWeight` (0.65/0.35) disagree with the trained `ensemble_config.json` (0.5/0.5).

`app/lib/config/routes.dart` (19 lines — full):

```dart
import 'package:flutter/material.dart';

class AppRoutes {
  static void pushReplacement(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}
```

### 9.10 `app/lib/services/certificate_service.dart` (620 lines — certificate-numbering and data-flow parts in full, PDF layout summarised)

Header, colour/font constants, and the certificate-number generator:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_result.dart';

class CertificateService {
  // ── Colours ──
  static const _navy = PdfColor.fromInt(0xFF091A72);
  static const _royal = PdfColor.fromInt(0xFF1B3A8C);
  static const _text = PdfColor.fromInt(0xFF1A1A2E);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _bg = PdfColor.fromInt(0xFFF5F7FA);
  static const _green = PdfColor.fromInt(0xFF059669);
  static const _white = PdfColors.white;
  static const _badgeBg = PdfColor.fromInt(0xFF2A3F8F);

  // ── Fonts ── (Helvetica / Courier built-ins — NOT Poppins/Inter/JetBrains Mono)
  static final _hb = pw.Font.helveticaBold();
  static final _h  = pw.Font.helvetica();
  static final _ho = pw.Font.helveticaOblique();
  static final _c  = pw.Font.courier();
  static final _cb = pw.Font.courierBold();

  static const double _pad = 36; // print-safe horizontal padding

  /// Generate next sequential certificate number
  static Future<String> generateCertificateNumber() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt('certificate_counter') ?? 0;
    counter++;
    await prefs.setInt('certificate_counter', counter);
    final now = DateTime.now();
    final ym = '${now.year}${now.month.toString().padLeft(2, '0')}';
    return 'GE-$ym-${counter.toString().padLeft(5, '0')}';
  }
```

Entry point and the QR payload (the data that leaves the app inside the PDF):

```dart
  static Future<Uint8List> generateCertificatePdf({
    required GradeResult result,
    required Uint8List stoneImage,
    Uint8List? gradcamImage,
  }) async {
    final pdf = pw.Document();

    // Load logo
    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Logo load failed: $e');
    }

    final stoneImg = pw.MemoryImage(stoneImage);
    final gradcamImg = gradcamImage != null ? pw.MemoryImage(gradcamImage) : null;
    final logoImg = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    final qrData = jsonEncode({
      'cert': result.certificateNumber,
      'grade': result.gradeNumber,
      'stone': result.stoneId,
      'date': _fmtShort(result.capturedAt),
    });
    // … pdf.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: pw.EdgeInsets.zero, build: …))
    return pdf.save();
  }
```

The colour-values table row — the only place `GradeResult` numerics reach the PDF:

```dart
                        pw.TableRow(
                          children: [
                            '${result.labL}',
                            '${result.labA}',
                            '${result.labB}',
                            '${result.labC}',
                            '${result.hue.toStringAsFixed(0)}',
                            '${result.saturation.toStringAsFixed(0)}%',
                            '${result.brightness.toStringAsFixed(0)}%',
                            '${result.deltaE}',
                            result.gradeColourHex,
                          ].map((v) => _tV(v)).toList(),
                        ),
```

The Grad-CAM slot, which is always the `null` branch today:

```dart
                            pw.Expanded(
                              child: gradcamImg != null
                                  ? pw.Container(/* bordered image */)
                                  : pw.Container(
                                      decoration: pw.BoxDecoration(
                                        color: _bg,
                                        border: pw.Border.all(color: _border, width: 0.5),
                                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                                      ),
                                      child: pw.Center(
                                        child: pw.Text(
                                            'Heatmap generated\nafter model deployment',
                                            style: pw.TextStyle(font: _h, fontSize: 9, color: _muted),
                                            textAlign: pw.TextAlign.center),
                                      ),
                                    ),
                            ),
```

**Summary of the remaining ~430 lines (pure `pw.*` layout, no data flow):** a single A4 `pw.Page` with zero margin, laid out to an explicitly documented vertical budget (header 52 pt, accent line 3 pt, 30 pt gap, stone+grade row 200 pt, 26 pt gap, colour table 78 pt, 26 pt gap, details+heatmap row 160 pt, 26 pt gap, verification+standard row 150 pt, flexible spacer, 1 pt divider, 28 pt footer = 842 pt). Sections: (1) navy header bar with circular logo, "GemEye", centre title "Colour Grading Certificate" and the certificate number in Courier Bold; (2) royal accent line; (3) bordered stone image beside a navy grade card showing `Grade N` at 42 pt, `gradeName - tradeName`, a `+/- N grades` badge and a green `confidenceLevel` badge; (4) a 9-column bordered `pw.Table` (Lightness, Green-Red, Blue-Yel, Chroma, Hue, Sat, Bright, Delta E, Hex); (5) "STONE DETAILS" key/value rows (Stone ID, Capture Date, Session ID truncated to 22 chars, Grade Colour) beside "AI ATTENTION MAP"; (6) "VERIFICATION" with a 72×72 `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrData)` plus scan instructions, beside "CLASSIFICATION STANDARD" prose citing the GEMCLOUD 7-grade standard and "cloud-deployed ensemble machine learning (EfficientNet-B0 + Random Forest)", with a disclaimer that the document characterises colour but does not value the gemstone; (7) a grey footer with "GemEye v1.0 - 2026", the certificate number and a generation date. Helper widgets `_badge`, `_sectionTitle`, `_tH`, `_tV`, `_kvRow` and date formatters `_fmtLong`, `_fmtShort`, `_fmtSlash` close the file.

Note: the PDF prose asserts cloud-deployed ensemble ML was used, while the values it prints are the hardcoded mock.

### 9.11 `app/lib/screens/certificate_screen.dart` (225 lines — full)

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../models/grade_result.dart';
import '../services/certificate_service.dart';

class CertificateScreen extends StatefulWidget {
  final GradeResult result;
  final Uint8List stoneImageBytes;
  final Uint8List? gradcamImageBytes;

  const CertificateScreen({
    super.key,
    required this.result,
    required this.stoneImageBytes,
    this.gradcamImageBytes,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    try {
      final bytes = await CertificateService.generateCertificatePdf(
        result: widget.result,
        stoneImage: widget.stoneImageBytes,
        gradcamImage: widget.gradcamImageBytes,
      );
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Certificate PDF Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate certificate PDF')),
        );
      }
    }
  }

  Future<void> _savePdf() async {
    if (_pdfBytes == null) return;
    try {
      final certNum = widget.result.certificateNumber ?? 'certificate';
      Directory saveDir;

      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download/GemEye Certificates');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        saveDir = Directory('${appDir.path}/GemEye Certificates');
      }

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final file = File('${saveDir.path}/$certNum.pdf');
      await file.writeAsBytes(_pdfBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate saved to Downloads/GemEye Certificates/'),
            backgroundColor: Color(0xFF1B3A8C),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save certificate')),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      final certNum = widget.result.certificateNumber ?? 'GemEye-Certificate';
      await Printing.sharePdf(bytes: _pdfBytes!, filename: '$certNum.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share certificate')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open print dialog')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Certificate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: GemEyeColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Generating certificate...',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _pdfBytes == null
              ? const Center(
                  child: Text(
                    'Failed to generate PDF',
                    style: TextStyle(
                      fontFamily: GemEyeFonts.body,
                      fontSize: 14,
                      color: GemEyeColors.error,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PdfPreview(
                        build: (_) async => _pdfBytes!,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        allowPrinting: false,
                        allowSharing: false,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: GemEyeColors.border)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _actionButton(Icons.save_alt_rounded, 'Save', _savePdf),
                            _actionButton(Icons.share_rounded, 'Share', _sharePdf),
                            _actionButton(Icons.print_rounded, 'Print', _printPdf),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: GemEyeColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: GemEyeFonts.body,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GemEyeColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 9.12 `app/assets/data/colour_grades.json` (93 lines — full)

```json
[
  {
    "grade": 1,
    "name": "Dark",
    "tradeName": "Ink Blue",
    "colourStart": "#091A47",
    "colourEnd": "#102670",
    "description": "Very dark blue, nearly black. Strongly saturated with very low brightness. Appears almost opaque.",
    "hueRange": "220-240",
    "satRange": "90-100%",
    "brtRange": "10-25%",
    "labL": "15-25",
    "labB": "-40 to -30"
  },
  {
    "grade": 2,
    "name": "Deep",
    "tradeName": "Midnight Blue",
    "colourStart": "#102670",
    "colourEnd": "#1B3A8C",
    "description": "Deep rich blue with noticeable colour. High saturation, low-medium brightness. Prized for intensity.",
    "hueRange": "225-245",
    "satRange": "85-100%",
    "brtRange": "25-40%",
    "labL": "25-35",
    "labB": "-35 to -25"
  },
  {
    "grade": 3,
    "name": "Vivid",
    "tradeName": "Royal Blue",
    "colourStart": "#1B3A8C",
    "colourEnd": "#2E5BB8",
    "description": "The most desirable grade. Vivid, intense blue with excellent saturation and medium brightness. 'Royal Blue' or 'Cornflower' in trade.",
    "hueRange": "225-250",
    "satRange": "80-95%",
    "brtRange": "40-55%",
    "labL": "35-45",
    "labB": "-30 to -20"
  },
  {
    "grade": 4,
    "name": "Intense",
    "tradeName": "Sapphire Blue",
    "colourStart": "#2E5BB8",
    "colourEnd": "#4A80D4",
    "description": "Strong blue with good saturation. Slightly lighter than Vivid. Commercially excellent grade.",
    "hueRange": "220-248",
    "satRange": "70-90%",
    "brtRange": "50-65%",
    "labL": "45-55",
    "labB": "-25 to -15"
  },
  {
    "grade": 5,
    "name": "Medium",
    "tradeName": "Ceylon Blue",
    "colourStart": "#4A80D4",
    "colourEnd": "#7BA7E8",
    "description": "Medium blue with balanced saturation and brightness. Classic Sri Lankan sapphire colour.",
    "hueRange": "215-245",
    "satRange": "55-75%",
    "brtRange": "60-75%",
    "labL": "55-65",
    "labB": "-20 to -10"
  },
  {
    "grade": 6,
    "name": "Light",
    "tradeName": "Sky Blue",
    "colourStart": "#7BA7E8",
    "colourEnd": "#A8C8F0",
    "description": "Light blue with moderate saturation. Pastel appearance. Pleasant but less intense.",
    "hueRange": "210-240",
    "satRange": "40-60%",
    "brtRange": "75-88%",
    "labL": "65-78",
    "labB": "-15 to -5"
  },
  {
    "grade": 7,
    "name": "Very Light",
    "tradeName": "Ice Blue",
    "colourStart": "#A8C8F0",
    "colourEnd": "#D6E5F8",
    "description": "Very light blue, nearly colourless. Low saturation and high brightness. Faint blue tint.",
    "hueRange": "200-240",
    "satRange": "20-45%",
    "brtRange": "85-97%",
    "labL": "78-92",
    "labB": "-10 to -2"
  }
]
```

---

## 10. Storage

### How grading history is persisted

| Aspect | Value |
|---|---|
| Package | `shared_preferences: ^2.3.2` |
| Implementing class | `StorageService` — `app/lib/services/storage_service.dart` (all static methods) |
| Key | `grade_history` |
| Storage format | `List<String>` where **each element is one `jsonEncode(GradeResult.toJson())` string** (not one JSON array) |
| Android location | `SharedPreferences` XML at `/data/data/com.gemeye.gemeye/shared_prefs/FlutterSharedPreferences.xml`, key `flutter.grade_history` |
| iOS location | `NSUserDefaults` for the app suite, key `flutter.grade_history` |
| Other keys used | `stone_counter` (int, `StorageService`), `certificate_counter` (int, `CertificateService`), `confidence_threshold` (double), `export_format` (String), `certificate_prefix` (String), `auto_save_images` (bool), `is_calibrated` (bool — **read only, never written**), `profile_phone`, `company_name` (String), `feedback` (`List<String>` of JSON) |
| Images | **Not persisted.** Only `capturedImagePath`, pointing into the plugin cache directory, is stored (see §8) |
| Secure storage | `flutter_secure_storage` is declared in `pubspec.yaml` but **never imported**. All data, including the user's phone number and company name, is in plain `SharedPreferences` |
| Remote / cloud persistence | **NOT FOUND.** No Firestore, no MongoDB, no REST API. History is device-local only and is lost on uninstall |

### One example of a saved GradeResult as JSON exactly as stored

Below is a single element of the `grade_history` string list, exactly in the shape `jsonEncode(GradeResult.toJson())` produces for the current mock pipeline (`processing_screen.dart:56-72`). Field order is the literal order of `toJson()`; `id`, `capturedAt` and `sessionId` are generated at construction time; `gradcamImagePath` is always `null`; `certificateNumber` is `null` until first export.

```json
{"id":"3f8c1a52-9e64-4b0d-8a7f-12d5e6b9c401","stoneId":"GE-STONE-00001","gradeNumber":3,"gradeName":"Vivid","tradeName":"Royal Blue","confidence":92.4,"uncertaintyRange":0.2,"labL":42.3,"labA":8.9,"labB":-27.0,"labC":28.4,"hue":228.0,"saturation":88.0,"brightness":62.0,"deltaE":1.2,"capturedImagePath":"/data/user/0/com.gemeye.gemeye/cache/28f4b7c1-6a3e-4d59-b0f2-image_cropper_1758...jpg","gradcamImagePath":null,"certificateNumber":null,"capturedAt":"2026-09-30T14:22:07.431","sessionId":"SESSION-1790772127431"}
```

Pretty-printed, for readability (not how it is stored):

```json
{
  "id": "3f8c1a52-9e64-4b0d-8a7f-12d5e6b9c401",
  "stoneId": "GE-STONE-00001",
  "gradeNumber": 3,
  "gradeName": "Vivid",
  "tradeName": "Royal Blue",
  "confidence": 92.4,
  "uncertaintyRange": 0.2,
  "labL": 42.3,
  "labA": 8.9,
  "labB": -27.0,
  "labC": 28.4,
  "hue": 228.0,
  "saturation": 88.0,
  "brightness": 62.0,
  "deltaE": 1.2,
  "capturedImagePath": "/data/user/0/com.gemeye.gemeye/cache/…image_cropper_….jpg",
  "gradcamImagePath": null,
  "certificateNumber": null,
  "capturedAt": "2026-09-30T14:22:07.431",
  "sessionId": "SESSION-1790772127431"
}
```

After a certificate export the same record is rewritten with `"certificateNumber": "GE-202609-00001"`.

**Caveat:** this example is reconstructed from the code paths (`GradeResult.toJson()` plus the hardcoded values in `_navigateToResult`), because no device was attached at audit time to dump a live `FlutterSharedPreferences.xml`. Every literal value except the UUID, timestamp and cache filename is exactly what the app writes.

---

## 11. Calibration

### What the calibration screen actually does today

**UI only.** `app/lib/screens/calibration_screen.dart` is a 3-step `setState` wizard with no functional behaviour:

| Step | What it shows | What it does |
|---|---|---|
| 1 | "Place CCC Card" — six static colour swatches (White `#F0F0F0`, 18% Grey `#767676`, Blue `#004D8D`, Black `#101010`, 50% Grey `#B5B5B5`, Red `#95444F`) | Nothing; "Next" increments `_currentStep` |
| 2 | "Mount Phone on Tripod" — Apexel 100 mm macro lens + CPL filter instructions, lighting tip | Nothing |
| 3 | "Capture CCC Card" — a dark rectangle explicitly commented `// Simulated viewfinder` (line 307) containing the same six swatches, each drawn with a green border as though detected | Nothing. There is **no camera preview and no capture** |
| "Complete Calibration" | `_completeCalibration()` (line 425) | Shows an `AlertDialog` reading "Calibration Complete — Residual ΔE: 1.4 (excellent)", then pops twice back to Home |

The function body opens with the marker `// TODO: Implement actual camera capture and CCC processing` (line 426). The "Residual ΔE: 1.4" figure is a string literal, not a computed value.

**Not present anywhere in the project:** camera preview, patch detection, colour-correction-matrix computation, ΔE residual computation, a calibration data model, and any use of `AppConstants.requiredPatches` (6) or `AppConstants.maxAcceptableDeltaE` (2.0).

### What is persisted after calibration, and where

**Nothing.** `calibration_screen.dart` imports only `flutter/material.dart` and `../config/theme.dart` — it has no access to `SharedPreferences`, `flutter_secure_storage`, the filesystem, or any service. No key is written.

The consequences visible in the UI:

- `settings_screen.dart:41` reads `prefs.getBool('is_calibrated') ?? false`, but **no code anywhere writes `is_calibrated`**, so Settings shows "Not calibrated" in red permanently, even immediately after completing the wizard.
- `home_screen.dart:97-123` shows "Not calibrated yet. Calibrate before grading." unconditionally — it is not driven by any state at all.
- `settings_screen.dart:131-171` "Calibration History" always shows "No calibrations recorded yet".
- `CLAUDE.md` notification IDs C1–C5 (calibration) are not implemented.

---

## 12. State management and navigation

### State management

| Approach | Used? | Detail |
|---|---|---|
| `setState` / `StatefulWidget` | **Yes — this is the only mechanism.** | 16 of 21 screen classes are `StatefulWidget`s managing their own local state |
| `provider` | **No.** Declared in `pubspec.yaml` (`^6.1.2`) but never imported. `lib/providers/` exists and is **empty** | Contradicts `CLAUDE.md` ("Use `provider` for state management") |
| `InheritedWidget` / `ChangeNotifier` / `ValueNotifier` / Riverpod / BLoC | **NOT FOUND** | |
| Cross-screen state | Passed by constructor parameters (`ProcessingScreen(imagePath:)`, `ResultScreen(imagePath:, gradeResult:)`, `CertificateScreen(result:, stoneImageBytes:)`) and by re-reading `SharedPreferences` on each screen's `initState` | No shared in-memory store, which is why Home's stats and Settings' calibration flag are stale/hardcoded |
| Service layer | Three classes of **static** methods (`StorageService`, `CertificateService`) plus one instantiated-per-use class (`AuthService` — `AuthService()` is constructed fresh in `home_screen.dart`, `splash_screen.dart`, `side_drawer.dart`, `settings_screen.dart`, etc.) | No dependency injection |
| Tab state | `_MainShellState._currentIndex` with an `IndexedStack`; the drawer mutates it via an `onTabSwitch` callback | |

### Navigation / routing

| Approach | Used? | Detail |
|---|---|---|
| Imperative `Navigator` + `MaterialPageRoute` | **Yes — this is the only mechanism.** | Wrapped in `AppRoutes.push` / `AppRoutes.pushReplacement` / `AppRoutes.pop` (`app/lib/config/routes.dart`) |
| Named routes (`routes:` / `onGenerateRoute:`) | **NOT FOUND** — `MaterialApp` in `main.dart` declares only `home: const SplashScreen()` | |
| `go_router` | **No.** Declared (`^14.2.7`) but never imported | |
| Deep links / URL strategy | **NOT FOUND** | |
| Page transition | Default `MaterialPageRoute` platform transition. **`FadeTransition` specified in `CLAUDE.md` is NOT implemented** — tabs swap instantly inside an `IndexedStack` | |
| Bottom nav | `GemEyeBottomNav` (`app/lib/widgets/bottom_nav.dart`), 4 tabs: Home / Grade / History / Guide. Tab 1 ("Grade") does not switch tabs — it pushes `CaptureScreen`. Settings is correctly **not** in the bottom nav | |
| Drawer | `GemEyeSideDrawer` (`app/lib/widgets/side_drawer.dart`) mounted as `endDrawer` (right side, per spec) with 11 entries: profile header, Home, Grade a Stone, Grading History, Colour Grade Guide, Stone Comparison, Settings, Feedback, Privacy Policy, About, Logout | Matches the spec |
| Back handling | `PopScope(canPop: false, onPopInvokedWithResult: _handleBackButton)` in `main_shell.dart` — non-Home tab returns to Home; on Home it shows an "Exit GemEye?" dialog | |
| Screen flow | `SplashScreen` → (`isLoggedIn` ? `MainShell` : `AgreementScreen` → `LoginScreen` → [`RegisterScreen`] → `MainShell`). **`OnboardingScreen` is never inserted into this flow** | |

---

## 13. Existing backend code

Searched the entire repository (excluding `.git`, `build`, `.dart_tool`) for `*.py`, `Dockerfile*`, `requirements*.txt`, `*.ipynb`, FastAPI and Flask sources.

| Expected artefact | Status |
|---|---|
| `backend/handler.py` | **NOT FOUND** |
| `backend/preprocessing.py` | **NOT FOUND** |
| `backend/inference.py` | **NOT FOUND** |
| `backend/gradcam.py` | **NOT FOUND** |
| `backend/Dockerfile` | **NOT FOUND** |
| `backend/requirements.txt` | **NOT FOUND** |
| Any Dockerfile anywhere | **NOT FOUND** |
| Any `requirements.txt` anywhere | **NOT FOUND** |
| FastAPI / Flask / AWS Lambda handler code | **NOT FOUND** |
| `lambda/` or `server/` directory | **NOT FOUND** |
| Training notebooks (`model/*.ipynb`) | **NOT FOUND** — only weights and logs are present |

The `backend/` directory contains exactly one file: `backend/models/.gitkeep` (empty placeholder). The `model/` directory contains no source code either — only trained artefacts (§14).

### Python files that do exist

| File | Lines | Purpose |
|---|---|---|
| `dataset/rename_images.py` | 130 | Dataset utility, unrelated to serving. CLI modes `raw` / `merged` / `all`; two-pass rename of dataset images to `{shape}_g{grade}_{NNN}.jpg` and `g{grade}_{NNN}.jpg`. Documented in PROJECT_STATUS EDIT-041. Not pasted here as it is a local dataset tool with no bearing on the app's data flow, and the report already documents its behaviour; it is under 300 lines and available at that path. |
| `app/ios/Flutter/ephemeral/flutter_lldb_helper.py` | — | Generated by the Flutter tool; not project code |

### Model configuration that a backend would consume

`model/trained_models/ensemble_config.json` (full contents — this is the closest thing to a serving contract in the repo):

```json
{
  "w_cnn": 0.5,
  "w_rf": 0.5,
  "num_classes": 7,
  "img_size": 224,
  "mc_passes": 10,
  "grade_names": {
    "1": "Dark",
    "2": "Deep",
    "3": "Vivid",
    "4": "Intense",
    "5": "Medium",
    "6": "Light",
    "7": "Very Light"
  },
  "feature_names": [
    "H", "S", "B", "L*", "a*", "b*", "C*", "J", "M", "h", "s", "C_cam"
  ],
  "val_accuracy": 0.8392857142857143,
  "val_f1": 0.8391449683321605
}
```

Note the ensemble weights here (0.5 / 0.5) differ from `AppConstants.cnnWeight` / `rfWeight` (0.65 / 0.35).

**`config_v3.json`: NOT FOUND** anywhere in the project.

---

## 14. Model files present locally

Searched the whole project and `C:\Users\sheha\Downloads` (depth 3) for `*.keras`, `*.tflite`, `*.pkl`, `*.h5`, `config_v3.json`.

### In the project

| Path | Size (bytes) | Size | Modified |
|---|---|---|---|
| `model/trained_models/best_phase1.keras` | 21,019,442 | 20.0 MB | 10 Sep 2026 09:36 |
| `model/trained_models/best_phase2.keras` | 45,481,416 | 43.4 MB | 10 Sep 2026 09:42 |
| `model/trained_models/efficientnet_b0_gemeye.keras` | 45,481,416 | 43.4 MB | 10 Sep 2026 09:59 |
| `model/trained_models/model_int8.tflite` | 5,239,456 | 5.0 MB | 10 Sep 2026 10:00 |
| `model/trained_models/rf_model.pkl` | 6,695,622 | 6.4 MB | 10 Sep 2026 09:28 |
| `model/trained_models/scaler.pkl` | 903 | 903 B | 10 Sep 2026 09:28 |

`best_phase2.keras` and `efficientnet_b0_gemeye.keras` are byte-identical in size, so the latter is almost certainly a copy of the phase-2 checkpoint.

### In the user's Downloads folder

| Path | Size (bytes) | Size | Modified |
|---|---|---|---|
| `C:\Users\sheha\Downloads\New folder\trained_models\best_phase1.keras` | 21,019,442 | 20.0 MB | 10 Sep 2026 09:36 |
| `C:\Users\sheha\Downloads\New folder\trained_models\best_phase2.keras` | 45,481,416 | 43.4 MB | 10 Sep 2026 09:42 |
| `C:\Users\sheha\Downloads\New folder\trained_models\efficientnet_b0_gemeye.keras` | 45,481,416 | 43.4 MB | 10 Sep 2026 09:59 |
| `C:\Users\sheha\Downloads\New folder\trained_models\model_int8.tflite` | 5,239,456 | 5.0 MB | 10 Sep 2026 10:00 |
| `C:\Users\sheha\Downloads\New folder\trained_models\rf_model.pkl` | 6,695,622 | 6.4 MB | 10 Sep 2026 09:28 |
| `C:\Users\sheha\Downloads\New folder\trained_models\scaler.pkl` | 903 | 903 B | 10 Sep 2026 09:28 |

This is the same set, sizes and timestamps as `model/trained_models/` — a duplicate copy.

### Other files present alongside the weights (not in the search pattern)

`model/trained_models/ensemble_config.json`, `confusion_matrix.png`, `gradcam_samples.png`, `phase1_curves.png`, `phase1_log.csv`, `phase2_curves.png`, `phase2_log.csv`.

### Not found

| Pattern | Result |
|---|---|
| `*.h5` | **NOT FOUND** (project and Downloads) |
| `config_v3.json` | **NOT FOUND** (project and Downloads) |
| Model files bundled into the app (`app/assets/`) | **NOT FOUND** — no model ships with the Flutter app |
| Model files in `backend/models/` | **NOT FOUND** — only `.gitkeep` |
| Model files in `model/saved_models/` | **NOT FOUND** — only `.gitkeep`, and the directory is `.gitignore`d |

**Git status note:** the whole `model/` directory is untracked (`?? model/`), so roughly 118 MB of trained weights exist only on this machine and in the Downloads copy. They are not in version control and not backed up by the repository.

---

## 15. Code health

Command: `flutter analyze` run read-only from `app/`.

### Totals

| Severity | Count |
|---|---|
| **Errors** | **0** |
| **Warnings** | **0** |
| **Infos** | **33** |
| **Total** | **33 issues** (ran in 9.2 s) |

### Every ERROR in full

**There are no errors.** `flutter analyze` exited with code 0 and reported zero error-severity diagnostics.

### Full info breakdown (for completeness)

| Rule | Count | Files |
|---|---|---|
| `use_build_context_synchronously` | 12 | `settings_screen.dart` lines 209, 447, 522, 528, 572, 578, 596, 612, 618, 653, 698, 703 |
| `prefer_const_constructors` | 19 | `certificate_service.dart` lines 124, 127 (×2), 196, 199 (×2), 260, 349, 350, 431, 433, 434, 539 (×2); `comparison_screen.dart` lines 506, 508; `history_screen.dart` lines 816, 817 |
| `prefer_const_literals_to_create_immutables` | 2 | `comparison_screen.dart:509`, `history_screen.dart:819` |
| `unnecessary_string_interpolations` | 1 | `certificate_service.dart:279` |

Note: `CLAUDE.md` Rule 2 requires zero issues before reporting completion, and 33 infos are currently outstanding. The 12 `use_build_context_synchronously` infos in `settings_screen.dart` are the substantive ones — they flag `BuildContext` use after `await` guarded by the wrong `mounted` check, which can throw if the user backs out of a dialog mid-operation.

---

## 16. Feature checklist

| Feature | Status | File where implemented (or what is missing) |
|---|---|---|
| Blur detection | **NOT DONE** | `AppConstants.minBlurThreshold = 100.0` exists in `app/lib/config/constants.dart:23` and is referenced by nothing. No Laplacian/variance computation anywhere |
| Ambient light check (`sensors_plus`) | **NOT DONE** | `sensors_plus: ^6.0.1` declared in `pubspec.yaml`, **never imported**. `minLuxGood`/`minLuxLow` in `constants.dart:24-25` are unused |
| Exposure lock | **NOT DONE** | No `camera` plugin and no live preview; `image_picker` offers no exposure control |
| Image cropping | **DONE** | `app/lib/screens/capture_screen.dart:77-115` (`_cropAndProceed`, `image_cropper`). No size/aspect normalisation — see §8 |
| Processing animation | **DONE (simulated)** | `app/lib/screens/processing_screen.dart` — Lottie + 7-step `Timer` list. The animation is real; the work behind it is not |
| Result screen | **DONE (mock values)** | `app/lib/screens/result_screen.dart` |
| Uncertainty (±) display | **DONE (mock value)** | `app/lib/screens/result_screen.dart:341-357` — `± {uncertaintyRange} grades` chip, always `± 0.2` |
| Confidence label | **DONE (mock value)** | `GradeResult.confidenceLevel` (`grade_result.dart:96-100`), rendered at `result_screen.dart:359-390`, always `HIGH` (92.4) |
| Colour values display | **DONE (mock values)** | `app/lib/screens/result_screen.dart:400-432` (`_buildColourValues`) — L*, a*, b*, C*, Hue, Sat, Bright, ΔE, hex, in JetBrains Mono |
| Grad-CAM panel | **PARTIAL (placeholder)** | `app/lib/screens/result_screen.dart:434-496` — a static `RadialGradient` labelled "Heatmap generated after model deployment". `GradeResult.gradcamImagePath` exists and is always `null` |
| Certificate PDF | **DONE** | `app/lib/services/certificate_service.dart` (A4, full 7-section layout) + `app/lib/screens/certificate_screen.dart` (`PdfPreview`) |
| QR code | **DONE** | `app/lib/services/certificate_service.dart:399-404` — `pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: qrData)`, 72×72 pt, payload `{cert, grade, stone, date}`. **No in-app QR scanner/verifier exists** |
| Certificate numbering | **DONE** | `CertificateService.generateCertificateNumber()` — `certificate_service.dart:58-66`. Pattern `GE-YYYYMM-NNNNN` from the `certificate_counter` pref. Re-export reuses the number (`result_screen.dart:137-140`, `history_screen.dart:170-172`) — spec-compliant. The `certificate_prefix` user setting (`settings_screen.dart:443`) is written but **ignored** by the generator, which hardcodes `GE-` |
| Share / save certificate | **DONE** | `app/lib/screens/certificate_screen.dart` — `_savePdf()` (Downloads/GemEye Certificates on Android), `_sharePdf()` (`Printing.sharePdf`), `_printPdf()` (`Printing.layoutPdf`). Batch variant at `history_screen.dart:162-203` |
| History search | **DONE** | `app/lib/screens/history_screen.dart:64-70` — `_applyFilters()` matches `stoneId` (case-insensitive substring) |
| History filters | **DONE** | `app/lib/screens/history_screen.dart:66-113` — grade chip (1–7), date from/to, confidence band, certificate exported/not, plus 6 sort options; `_activeFilterCount` badges the filter button |
| Swipe-to-delete | **DONE** | `app/lib/screens/history_screen.dart:635-640` — `Dismissible` with `DismissDirection.endToStart`, confirm dialog in `_deleteItem()` (line 224) |
| Batch actions | **DONE** | `app/lib/screens/history_screen.dart` — long-press enters `_isSelectionMode` (line 654), with `_deleteSelected()` (129), `_exportSelected()` (162), `_shareSelected()` (205) |
| Stone comparison + delta E | **DONE** | `app/lib/screens/comparison_screen.dart`; ΔE at line 129 `_calculateDeltaE()`. **Note:** this is plain CIE76 Euclidean ΔE*ab (`sqrt(ΔL² + Δa² + Δb²)`), not the ΔE₀₀ (CIEDE2000) that the UI labels claim |
| Settings | **DONE (2 stubs)** | `app/lib/screens/settings_screen.dart` — 6 sections, ~13 items. Stubs: "Calibration History" (hardcoded empty), "Export All Data" (builds a CSV then discards it, lines 592-621) |
| About | **DONE** | `app/lib/screens/about_screen.dart` — app info, developer, NSBM (line 164), Orava (line 193). Student number correctly omitted |
| Privacy policy | **PARTIAL** | `app/lib/screens/privacy_screen.dart` renders **hardcoded Dart strings**, not `assets/data/privacy_policy.md`. The markdown asset is read only by `agreement_screen.dart:117` |
| Feedback | **PARTIAL** | `app/lib/screens/feedback_sheet.dart` — stars + comment saved to the `feedback` pref key. Never transmitted to any backend |
| Colour grade guide | **DONE** | `app/lib/screens/guide_screen.dart` — loads `assets/data/colour_grades.json` offline. **Note:** the JSON's trade names and grade-5 name contradict `AppConstants` and `CLAUDE.md` |
| Profile screen | **DONE** | `app/lib/screens/profile_screen.dart` — name via Firebase Auth, phone/company via `SharedPreferences`, stats from `StorageService` |
| Google Sign-In | **DONE** | `AuthService.signInWithGoogle()` (`auth_service.dart:15`), UI at `login_screen.dart:184`. Android OAuth clients configured in `google-services.json` |
| Biometric lock | **NOT DONE** | `local_auth: ^2.3.0` declared, **never imported**. No "App Lock" toggle exists in the Security section of Settings (only Change Password / Change Email) |
| Logout | **DONE** | `app/lib/widgets/side_drawer.dart` logout item → confirm dialog → `AuthService.signOut()` → `pushReplacement(LoginScreen)` |
| Onboarding | **PARTIAL (unreachable)** | `app/lib/screens/onboarding_screen.dart` — 4 slides fully built, but **no file references `OnboardingScreen`**, no "first login" flag is stored, and `assets/images/onboarding/` is empty |
| Splash | **DONE** | `app/lib/screens/splash_screen.dart` (Lottie, 3 s timer, no university name — spec-compliant) + native splash via `flutter_native_splash` config in `pubspec.yaml`. **Note:** `pubspec.yaml` configures `image_dark`/`color_dark` and `android/app/src/main/res/values-night/` + `drawable-night*/` assets exist, which contradicts the "no dark mode" rule at the native-splash layer |
| iOS build configuration | **PARTIAL** | Xcode project, `Runner.xcworkspace`, `AppDelegate.swift`, `SceneDelegate.swift` and `Info.plist` exist. **Missing:** `GoogleService-Info.plist` (Firebase will not initialise on iOS), `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription` (the app will crash on camera/gallery access), and `ios/Podfile` / `ios/Pods` are absent. `Info.plist` also still allows landscape orientations, which `main.dart` locks out at runtime |

---

## 17. Summary

- **Overall completion: roughly 70% of the UI, 0% of the actual grading.** Every screen, navigation path, PDF layout, history feature and auth flow is built and functional; the machine-learning product at the centre of the project is not connected to the app at all.
- **The grading result is entirely fake.** Every stone graded returns the identical hardcoded value — Grade 3 / Vivid / Royal Blue, confidence 92.4, ±0.2, L*=42.3, a*=8.9, b*=−27.0, C*=28.4, hue 228°, sat 88%, bright 62%, ΔE 1.2 — created in `app/lib/screens/processing_screen.dart` `_navigateToResult()` (lines 53–83), with a duplicate fallback in `app/lib/screens/result_screen.dart` `_createMockResult()` (lines 41–58).
- **There is no networking code whatsoever.** `package:http` is declared but never imported; `AppConstants.apiBaseUrl` (`http://localhost:5000`), `gradeEndpoint` and `calibrateEndpoint` are referenced by nothing. The 7 "Uploading image / Running ensemble AI / Generating Grad-CAM" steps in `_simulateProcessing()` are `Timer`s totalling ~3.3 s.
- **There is no backend at all.** `backend/` contains only `models/.gitkeep`. No `handler.py`, `preprocessing.py`, `inference.py`, `gradcam.py`, Dockerfile, `requirements.txt`, Flask or FastAPI app exists anywhere in the repository (§13).
- **The trained models exist but are stranded.** ~118 MB of weights (`efficientnet_b0_gemeye.keras`, `model_int8.tflite`, `rf_model.pkl`, `scaler.pkl`, val accuracy 0.839, val F1 0.839) sit in `model/trained_models/`, which is **untracked in git**, duplicated in `Downloads\New folder\trained_models\`, and not bundled into the app or deployed anywhere.
- **Calibration is pure theatre.** `calibration_screen.dart` captures nothing, computes nothing and persists nothing; `_completeCalibration()` shows a literal "Residual ΔE: 1.4 (excellent)". Because nothing writes `is_calibrated`, Settings shows "Not calibrated" forever and Home's warning banner is unconditional.
- **Capture quality gates are entirely absent.** No blur detection, no lux/ambient-light check, no exposure lock, no live camera preview. The four green ticks on the capture screen are decoration. `minBlurThreshold`, `minLuxGood` and `minLuxLow` are dead constants.
- **What is genuinely real and working:** Firebase Auth (Google + e-mail, register, reset, change e-mail/password, delete account), the full History screen (search, 5 filter dimensions, 6 sorts, swipe-delete, batch delete/export/share), the Stone Comparison screen, the Colour Guide (offline JSON), the A4 certificate PDF with QR code and correct `GE-YYYYMM-NNNNN` numbering that is reused on re-export, Profile, Settings, About, drawer/bottom-nav navigation, and back-button handling.
- **Images are stored only in plugin cache directories.** Nothing copies the captured or cropped JPEG to durable storage; only the cache path string is saved into history. Android can evict that cache at any time, so old thumbnails and certificate re-exports will silently break. The `auto_save_images` preference is written but read by no code.
- **The cropped image is never normalised for the model.** `ImageCropper().cropImage` is called with no `maxWidth`, `maxHeight`, `aspectRatio` or `compressQuality`, so output dimensions and aspect ratio are arbitrary — while `ensemble_config.json` expects a 224×224 input. Whoever wires up inference must add that resize.
- **Data-consistency defects worth fixing alongside the API work:** `assets/data/colour_grades.json` trade names and grade-5 name contradict `AppConstants` and `CLAUDE.md`; `GradeResult.gradeColourHex` uses a non-spec 7-colour map that is duplicated in `history_screen.dart` and `comparison_screen.dart`; `AppConstants.cnnWeight`/`rfWeight` (0.65/0.35) disagree with the trained `ensemble_config.json` (0.5/0.5); the comparison screen labels plain CIE76 ΔE*ab as ΔE₀₀.
- **Spec deviations against `CLAUDE.md`:** `provider` is declared but unused and `lib/providers/` is empty (everything is `setState`); `go_router` is declared but unused; `flutter_secure_storage` is declared but unused while phone/company data sits in plain `SharedPreferences`; the `FadeTransition` page transition is not implemented; `OnboardingScreen` is unreachable dead code; `PrivacyScreen` hardcodes text instead of reading the shipped markdown; native dark-mode splash resources exist despite the no-dark-mode rule.
- **Build/config gaps:** `INTERNET` is not declared in the project manifest (it only arrives transitively from plugins); `usesCleartextTraffic` and `network_security_config.xml` do not exist, so the `http://` base URL will be blocked on `targetSdk` 36; release builds are still signed with the debug keystore; iOS lacks `GoogleService-Info.plist`, a `Podfile`, and the `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` entries needed to avoid a crash on capture.
- **Code health is clean but not at the project's own bar:** `flutter analyze` reports **0 errors, 0 warnings, 33 infos**. The 12 `use_build_context_synchronously` infos in `settings_screen.dart` are the ones with real failure modes; the other 21 are `const`-preference nits.
- **Exactly where a real grading API call belongs (in priority order):**
  1. **Create the missing client:** a new `app/lib/services/grading_service.dart` exposing e.g. `static Future<GradeResult> gradeStone(String imagePath)` — read the cropped file to `Uint8List`, resize to 224×224 (add `package:image`), POST multipart to `${AppConstants.apiBaseUrl}${AppConstants.gradeEndpoint}` with `package:http`, parse the JSON into `GradeResult`, all inside `try`/`catch` per the project's error-handling rule.
  2. **Primary insertion point:** `app/lib/screens/processing_screen.dart` — replace `_simulateProcessing()` (lines 36–50) and the hardcoded `GradeResult` inside `_navigateToResult()` (lines 53–83) with an `await GradingService.gradeStone(widget.imagePath)`, driving `_currentStep` from real upload/inference progress and surfacing failures instead of always succeeding.
  3. **Delete the fallback:** `app/lib/screens/result_screen.dart` `_createMockResult()` (lines 41–58) and the `?? _createMockResult()` at line 38, plus the two `'GE-STONE-00000'` special cases in `_saveAndGradeNext()` (line 63) and `_exportCertificate()` (line 110).
  4. **Grad-CAM:** populate `GradeResult.gradcamImagePath` from the API response and replace the static gradient in `result_screen.dart` `_buildGradCam()` (lines 434–496) with a real `Image.file`; then pass real bytes as `gradcamImageBytes` at `result_screen.dart:150-156` so `certificate_service.dart:322-335` stops printing the placeholder caption.
  5. **Calibration:** implement `calibration_screen.dart` `_completeCalibration()` (line 425, at the existing `// TODO`) to capture the CCC card, POST to `${AppConstants.apiBaseUrl}${AppConstants.calibrateEndpoint}`, store the returned correction matrix and residual ΔE, and finally **write** `is_calibrated` so `settings_screen.dart:41` and the Home banner become truthful.
  6. **Home wiring:** fill the empty `onTap` at `home_screen.dart:127-129` and replace the `'0'` / `'--'` / `'--'` stat literals (lines 170–174) with the already-written `StorageService.getTodayCount()` / `getGradeCount()`.
