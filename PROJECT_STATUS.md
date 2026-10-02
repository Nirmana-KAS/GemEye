# GemEye — Project Development Log

## Project Info
- **Start Date:** 17 August 2026
- **Target End Date:** 31 August 2026
- **Student:** Nirmana K.A.S. | 28973
- **University:** NSBM Green University
- **Internship:** Orava (Pvt) Ltd.
- **Repository:** https://github.com/Nirmana-KAS/GemEye
- **Development Tool:** VS Code + Claude Code (Opus 4.6)

---

## Edit Log

### EDIT-001 | 17 August 2026 | IST
- **Topic:** Project Initialisation — Repository, Flutter, Assets, Config
- **Summary:** Created GitHub repository, Flutter project, folder structure, all configuration files, static data files, and placeholder splash screen.
- **What was done:**
  - Created folder structure (backend, model, docs, dataset with 7 grade folders)
  - Created .gitignore with Flutter + Python + dataset exclusions
  - Created Flutter project `gemeye` in app/ folder
  - Created placeholder Lottie animation file
  - Created colour_grades.json with 7 GEMCLOUD grades
  - Created privacy_policy.md
  - Created config/theme.dart with GemEye colours and fonts
  - Created config/constants.dart with all app constants
  - Updated main.dart with GemEyeApp entry point
  - Created screens/splash_screen.dart with Lottie animation and fallback
  - Updated pubspec.yaml with all dependencies and asset declarations
  - Updated README.md with project information
  - Created PROJECT_STATUS.md
  - Created CLAUDE.md project instructions
- **Files changed:**
  - `+` .gitignore
  - `+` CLAUDE.md
  - `+` PROJECT_STATUS.md
  - `~` README.md (updated)
  - `+` backend/ (folder structure)
  - `+` model/ (folder structure)
  - `+` docs/ (folder structure)
  - `+` dataset/ (7 grade folders + calibration + repeatability)
  - `+` app/ (Flutter project)
  - `+` app/lib/config/theme.dart
  - `+` app/lib/config/constants.dart
  - `~` app/lib/main.dart (replaced)
  - `+` app/lib/screens/splash_screen.dart
  - `+` app/assets/animations/sapphire_rotate.json
  - `+` app/assets/data/colour_grades.json
  - `+` app/assets/data/privacy_policy.md
  - `~` app/pubspec.yaml (replaced)
- **Connected edits:** None (first edit)
- **Reason:** Project initialisation — Phase A

---

### EDIT-002 | 17 August 2026 | IST
- **Topic:** Bug Fixes — theme.dart, widget_test.dart, splash_screen.dart
- **Summary:** Fixed 3 code issues found by flutter analyze: CardTheme type error, widget test reference, and const constructor lint.
- **What was done:**
  - Changed CardTheme( to CardThemeData( in theme.dart line 76
  - Replaced widget_test.dart to reference GemEyeApp instead of MyApp
  - Added const to version Text widget in splash_screen.dart line 78
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/config/theme.dart (CardTheme → CardThemeData)
  - `~` app/test/widget_test.dart (replaced entirely)
  - `~` app/lib/screens/splash_screen.dart (added const)
  - `~` CLAUDE.md (added mandatory rules)
- **Connected edits:** EDIT-001 (fixes issues from initial setup)
- **Reason:** Fix errors detected by flutter analyze to ensure clean project state

---

### EDIT-003 | 17 August 2026 | IST
- **Topic:** Splash Screen Enhancement — Custom Gem Animation + Layout Fix
- **Summary:** Replaced placeholder Lottie hexagon with a custom-painted 3D rotating sapphire gem animation. Moved version text to bottom of screen.
- **What was done:**
  - Created gem_animation.dart with AnimatedGem widget using CustomPainter
  - Drew brilliant-cut sapphire with 8 facets in Royal Blue shades
  - Added 3D rotation effect using Matrix4 perspective transform
  - Added subtle scale pulse animation
  - Updated splash_screen.dart to use AnimatedGem instead of Lottie
  - Moved version text to bottom center of screen
  - Removed Lottie dependency from splash screen
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `+` app/lib/widgets/gem_animation.dart (new custom animation widget)
  - `~` app/lib/screens/splash_screen.dart (replaced Lottie with AnimatedGem, moved version)
- **Connected edits:** EDIT-001, EDIT-002 (splash screen improvements)
- **Reason:** Placeholder hexagon looked unprofessional; custom sapphire animation matches the app's purpose and brand

---

### EDIT-004 | 17 August 2026 | IST
- **Topic:** Splash Screen — Real Lottie Diamond Animation + Colour Fix + Layout Fix
- **Summary:** Replaced ugly custom painted gem with real Lottie diamond animation from LottieFiles. Changed diamond colours from white/grey to Royal Blue shades. Removed black background. Fixed all alignment — everything centered. Version at bottom.
- **What was done:**
  - Replaced sapphire_rotate.json with real Diamond.json Lottie animation
  - Changed all white/grey fills to Royal Blue shades (#1B3A8C, #3B5FD9, #0D1F5A)
  - Removed black background layer from Lottie file
  - Rewrote splash_screen.dart with proper centered layout
  - Deleted gem_animation.dart custom painter
  - Animation size: 160x160 for better visibility
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/assets/animations/sapphire_rotate.json (replaced with real Lottie, colours changed)
  - `~` app/lib/screens/splash_screen.dart (rewritten with proper layout)
  - `-` app/lib/widgets/gem_animation.dart (deleted)
- **Connected edits:** EDIT-003 (replaces both custom painter and placeholder)
- **Reason:** Professional animated diamond in Royal Blue with perfect centering

---

### EDIT-005 | 18 August 2026 | IST
- **Topic:** Phase B Start — Navigation Routes + Agreement Screen + Privacy Screen
- **Summary:** Built the navigation helper, privacy policy display screen, and the mandatory user agreement acceptance screen with checkbox and scrollable policy text.
- **What was done:**
  - Created routes.dart with push, pushReplacement, pop navigation helpers
  - Created privacy_screen.dart — read-only scrollable privacy policy loaded from assets
  - Created agreement_screen.dart — summary box with 4 key points, scrollable full policy, checkbox acceptance, disabled/enabled button
  - Updated splash_screen.dart to navigate to AgreementScreen after 3 seconds
  - Agreement blocks app usage until user accepts
  - All text uses approved fonts (Poppins headings, Inter body)
  - All colours from GemEyeColors class
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `+` app/lib/config/routes.dart
  - `+` app/lib/screens/agreement_screen.dart
  - `+` app/lib/screens/privacy_screen.dart
  - `~` app/lib/screens/splash_screen.dart (added navigation to agreement)
- **Connected edits:** EDIT-004 (splash screen now navigates forward)
- **Reason:** Phase B Step 1 — mandatory privacy acceptance before app usage

---

### EDIT-006 | 18 August 2026 | IST
- **Topic:** Phase B — Login + Register Screens + Firebase Auth + Auth Service
- **Summary:** Built login screen with Google Sign-In and email/password authentication, register screen with individual and company account types, Firebase initialization, and auth service wrapper. Full auth flow working: splash → agreement → login → register → home.
- **What was done:**
  - Updated main.dart with Firebase.initializeApp
  - Created auth_service.dart with Google Sign-In, email login, email register, sign out, password reset, getFirstName
  - Created login_screen.dart with Google button, email/password fields, password visibility toggle, forgot password, loading state, error handling
  - Created register_screen.dart with account type toggle (individual/company), common fields (name, email, password, phone, country, role), company-only fields (company name, business reg, industry, address) with AnimatedSize, form validation, loading state
  - Created placeholder home_screen.dart with welcome message and sign out button
  - Updated agreement_screen.dart to navigate to LoginScreen
  - Updated splash_screen.dart with auth state check (logged in → home, not logged in → agreement)
  - All error handling with user-friendly SnackBar messages
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/main.dart (added Firebase init)
  - `+` app/lib/services/auth_service.dart
  - `+` app/lib/screens/login_screen.dart
  - `+` app/lib/screens/register_screen.dart
  - `+` app/lib/screens/home_screen.dart (placeholder)
  - `~` app/lib/screens/agreement_screen.dart (navigate to login)
  - `~` app/lib/screens/splash_screen.dart (auth state check)
- **Connected edits:** EDIT-005 (agreement screen now connects to login flow)
- **Reason:** Phase B Step 2 — complete authentication flow with Firebase

---

### EDIT-007 | 18 August 2026 | IST
- **Topic:** Fix Privacy Policy Markdown Rendering + Google Logo
- **Summary:** Added flutter_markdown package to render privacy policy properly with formatted headings and paragraphs. Replaced generic Google icon with custom-painted 4-colour Google "G" logo on login screen.
- **What was done:**
  - Added flutter_markdown dependency to pubspec.yaml
  - Updated agreement_screen.dart to use MarkdownBody with styled headings and body text
  - Updated privacy_screen.dart to use MarkdownBody with same styles
  - Created GoogleLogoPainter in login_screen.dart with official Google colours (blue, red, yellow, green)
  - Replaced generic G icon with custom painted Google logo
  - Ran flutter pub get and flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/pubspec.yaml (added flutter_markdown)
  - `~` app/lib/screens/agreement_screen.dart (MarkdownBody)
  - `~` app/lib/screens/privacy_screen.dart (MarkdownBody)
  - `~` app/lib/screens/login_screen.dart (Google logo painter)
- **Connected edits:** EDIT-005, EDIT-006 (fixes visual issues from those screens)
- **Reason:** Raw markdown symbols looked unprofessional; generic Google icon not recognizable

---

### EDIT-008 | 18 August 2026 | IST
- **Topic:** Phase B3 — Google Logo Fix + Onboarding + Home Dashboard + Bottom Nav + Side Drawer
- **Summary:** Fixed Google button logo, built 4-slide onboarding screen, complete home dashboard with greeting and stats, bottom navigation with 4 tabs, right side drawer with 11 menu items, and main shell with IndexedStack page switching.
- **What was done:**
  - Fixed Google logo on login screen with clean styled "G" text
  - Created onboarding_screen.dart with 4 slides, dot indicators, Next/Get Started buttons
  - Created bottom_nav.dart with 4 tabs (Home, Grade, History, Guide) with active animations
  - Created side_drawer.dart with profile header, 11 menu items, logout, app version
  - Created main_shell.dart with IndexedStack for tab switching, endDrawer for side menu
  - Rewrote home_screen.dart with greeting (timezone-based), calibration banner, quick grade button with gradient, 3 stat cards, recent grades empty state
  - Updated splash, login, register, onboarding to navigate to MainShell
  - Placeholder screens for Grade, History, Guide tabs
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/screens/login_screen.dart (Google logo fix)
  - `+` app/lib/screens/onboarding_screen.dart
  - `+` app/lib/screens/main_shell.dart
  - `+` app/lib/widgets/bottom_nav.dart
  - `+` app/lib/widgets/side_drawer.dart
  - `~` app/lib/screens/home_screen.dart (complete rewrite)
  - `~` app/lib/screens/splash_screen.dart (navigate to MainShell)
  - `~` app/lib/screens/register_screen.dart (navigate to MainShell)
- **Connected edits:** EDIT-006, EDIT-007 (completes the auth flow with proper destination screens)
- **Reason:** Phase B Step 3 — core app navigation and home dashboard

---

### EDIT-009 | 18 August 2026 | IST
- **Topic:** Fix Google Logo — Use Real PNG Image
- **Summary:** Replaced styled text "G" with actual Google logo PNG image that was already saved in assets.
- **What was done:**
  - Changed Google button icon to Image.asset('assets/images/google_logo.png')
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/screens/login_screen.dart (Google logo image)
- **Connected edits:** EDIT-007, EDIT-008 (finally fixes the Google logo correctly)
- **Reason:** Previous attempts used custom paint and styled text — should have used the PNG from the start

---

### EDIT-010 | 18 August 2026 | IST
- **Topic:** Phase C — Calibration Wizard + Capture + Processing + Grade Result Screens
- **Summary:** Built the complete grading flow: 3-step calibration wizard with CCC card preview, capture screen with camera and gallery options plus image cropping, animated processing screen with 7-step pipeline progress, and professional grade result screen showing grade badge, colour values, Grad-CAM placeholder, and action buttons.
- **What was done:**
  - Created calibration_screen.dart — 3-step wizard (Place CCC, Mount Phone, Capture) with progress bar, CCC patch preview, viewfinder simulation, success dialog
  - Created capture_screen.dart — camera capture with image_picker, gallery import, image_cropper for crop before grading, checklist, loading state
  - Created processing_screen.dart — Lottie sapphire animation, 7-step progress with checkmarks and spinner, simulated timing, auto-navigate to result
  - Created result_screen.dart — stone image display, gradient grade badge (Grade 3 Vivid Royal Blue), confidence interval, HIGH/MED/LOW indicator, colour values grid (CIELAB + HSB + ΔE₀₀), Grad-CAM heatmap placeholder, Save & Grade Next and Export Certificate buttons
  - Updated main_shell.dart — Grade tab navigates to CaptureScreen instead of placeholder
  - Updated home_screen.dart — calibration banner navigates to CalibrationScreen
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `+` app/lib/screens/calibration_screen.dart
  - `+` app/lib/screens/capture_screen.dart
  - `+` app/lib/screens/processing_screen.dart
  - `+` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/main_shell.dart (Grade tab navigation)
  - `~` app/lib/screens/home_screen.dart (calibration banner tap)
- **Connected edits:** EDIT-008 (connects home dashboard to grading flow)
- **Reason:** Phase C — complete grading flow from capture to result

---

### EDIT-011 | 20 August 2026 | IST
- **Topic:** Fix App Crash After Camera/Gallery — image_cropper Android Configuration
- **Summary:** Fixed crash caused by missing UCropActivity declaration in AndroidManifest.xml. Added required camera and storage permissions. Added crop failure fallback to use original image.
- **What was done:**
  - Added UCropActivity declaration to AndroidManifest.xml
  - Added CAMERA, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES permissions
  - Verified styles.xml has AppCompat/MaterialComponents theme — changed NormalTheme parent to Theme.MaterialComponents.Light.NoActionBar
  - Updated capture_screen.dart with crop fallback — if crop fails, original image is sent to processing
  - Ran flutter clean + flutter pub get + flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/android/app/src/main/AndroidManifest.xml (added UCropActivity + permissions)
  - `~` app/android/app/src/main/res/values/styles.xml (changed NormalTheme parent to MaterialComponents)
  - `~` app/lib/screens/capture_screen.dart (crop fallback)
- **Connected edits:** EDIT-010 (fixes crash from Phase C capture screen)
- **Reason:** image_cropper requires UCropActivity registered in AndroidManifest — was missing from auto-generated config

---

### EDIT-012 | 23 August 2026 | IST
- **Topic:** GradeResult Data Model
- **Summary:** Created GradeResult model with full JSON serialization, confidence levels, and grade colour mapping.
- **What was done:**
  - Created GradeResult class with 20 fields (id, stoneId, gradeNumber, gradeName, tradeName, confidence, uncertaintyRange, CIELAB values, HSB values, deltaE, image paths, certificateNumber, timestamps)
  - Auto-generated UUID for id and session ID
  - Added toJson/fromJson serialization
  - Added confidenceLevel getter (HIGH/MEDIUM/LOW based on confidence %)
  - Added gradeColourHex getter for 7-grade colour mapping
  - Added uuid package dependency to pubspec.yaml
- **Files changed:**
  - `+` app/lib/models/grade_result.dart
  - `~` app/pubspec.yaml (added uuid: ^4.4.2)
- **Connected edits:** EDIT-010 (model for the grading flow)
- **Reason:** Phase C Steps 25-26 — data model needed for grade storage, certificate generation, and history

---

### EDIT-013 | 23 August 2026 | IST
- **Topic:** Storage & Certificate Services
- **Summary:** Created StorageService for local grade history persistence and CertificateService for A4 PDF certificate generation with professional layout.
- **What was done:**
  - Created StorageService with SharedPreferences-backed JSON storage: save, get, delete, clear, getById, getNextStoneId (auto-increment GE-STONE-NNNNN), getGradeCount, getTodayCount
  - Created CertificateService with generateCertificateNumber (GE-YYYYMM-NNNNN format) and generateCertificatePdf
  - PDF layout: header row (GemEye + title + cert number), Royal Blue divider, centred stone image, dark navy grade card with grade number/name/trade name/uncertainty/confidence badge, colour data table (L* a* b* C* Hue Sat Brt ΔE₀₀), optional Grad-CAM image, stone details section, GEMCLOUD standard line, disclaimer, footer
- **Files changed:**
  - `+` app/lib/services/storage_service.dart
  - `+` app/lib/services/certificate_service.dart
- **Connected edits:** EDIT-012 (services use GradeResult model)
- **Reason:** Phase C Steps 25-26 — local storage for grade history and PDF certificate generation

---

### EDIT-014 | 23 August 2026 | IST
- **Topic:** Certificate Screen + Result Screen Update
- **Summary:** Created certificate preview screen with save/share/print actions, updated result screen with full save and export functionality, updated processing screen to create GradeResult objects.
- **What was done:**
  - Created certificate_screen.dart with PdfPreview widget, bottom action bar (Save to Documents, Share via system sheet, Print via system dialog)
  - Rewrote result_screen.dart: accepts optional GradeResult parameter, RepaintBoundary for screenshot sharing, Save & Grade Next button (saves to StorageService, shows SnackBar, pops to home), Export Certificate button (generates cert number if needed, saves result, navigates to CertificateScreen with stone image bytes), Share via AppBar (captures screenshot, shares via share_plus)
  - Updated processing_screen.dart: creates GradeResult with auto-generated stoneId after processing simulation, passes it to ResultScreen
  - All error handling with user-friendly SnackBar messages
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `+` app/lib/screens/certificate_screen.dart
  - `~` app/lib/screens/result_screen.dart (complete rewrite with save/export/share)
  - `~` app/lib/screens/processing_screen.dart (creates GradeResult, passes to ResultScreen)
- **Connected edits:** EDIT-010, EDIT-012, EDIT-013 (connects grading flow to data model, storage, and certificate generation)
- **Reason:** Phase C Steps 25-26 — complete certificate PDF generation, sharing, and grade persistence flow

---

### EDIT-015 | 23 August 2026 | IST
- **Topic:** Certificate PDF Complete Rebuild
- **Summary:** Rebuilt certificate PDF with professional layout matching approved design — navy header bar with diamond logo, side-by-side stone image and grade card, full-word table headers, stone details with AI attention map, QR verification code, classification standard, and compact footer.
- **What was done:**
  - Complete rewrite of CertificateService with 6-section professional layout
  - Section 1: Navy header bar with diamond icon, centred title, certificate number
  - Section 2: Side-by-side stone image and navy grade card with grade number, name, trade name, uncertainty badge, confidence badge
  - Section 3: Colour values table with full-word headers (Lightness, Green-Red, Blue-Yellow, Chroma, Hue, Saturation, Brightness, Delta E) — Courier font for values
  - Section 4: Stone details (ID, date, session) alongside AI Attention Map (Grad-CAM image or placeholder)
  - Section 5: QR code verification (pw.BarcodeWidget with JSON data) alongside GEMCLOUD classification standard paragraph and disclaimer
  - Section 6: Light grey footer bar with version, certificate number, generation date
  - All text uses built-in PDF fonts only (Helvetica, Helvetica-Bold, Helvetica-Oblique, Courier, Courier-Bold) — no custom TTF loading
  - Zero-margin page with manual padding per section for precise control
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart (complete rewrite)
- **Connected edits:** EDIT-013, EDIT-014 (replaces previous certificate PDF layout)
- **Reason:** Previous certificate had poor alignment, broken symbols, wasted space — rebuilt to match professional design specification

---

### EDIT-016 | 23 August 2026 | IST
- **Topic:** GemEye Logo Integration — App Icon + Native Splash + Certificate Logo
- **Summary:** Replaced Flutter default app icon with GemEye logo on Royal Blue background, replaced native splash Flutter logo with branded Royal Blue splash, embedded logo image in certificate PDF header replacing diamond symbol.
- **What was done:**
  - Added flutter_launcher_icons (dev) and flutter_native_splash (runtime) packages
  - Configured flutter_launcher_icons with logo.png and adaptive icon on #1B3A8C background
  - Configured flutter_native_splash with logo.png on #1B3A8C background for normal and Android 12+
  - Generated app icons for Android and iOS via `dart run flutter_launcher_icons`
  - Generated native splash screens via `dart run flutter_native_splash:create`
  - Updated main.dart with FlutterNativeSplash.preserve() and FlutterNativeSplash.remove()
  - Updated certificate_service.dart to load logo.png from assets and display it in the PDF header bar to the left of "GemEye" text, replacing the diamond symbol
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/pubspec.yaml (added flutter_native_splash dependency, flutter_launcher_icons dev dependency, launcher icons and splash config)
  - `~` app/lib/main.dart (added FlutterNativeSplash preserve/remove)
  - `~` app/lib/services/certificate_service.dart (load logo from assets, embed in PDF header)
- **Connected edits:** EDIT-015 (certificate header now uses logo image instead of diamond symbol)
- **Reason:** Replace default Flutter branding with GemEye logo across app icon, cold-start splash, and certificate PDF

---

### EDIT-017 | 23 August 2026 | IST
- **Topic:** Certificate PDF Complete Rewrite + UI Fixes
- **Summary:** Rebuilt certificate PDF fixing broken layout (split stone image, wrapped text, broken em-dash, QR overlap, blank space). Fixed result screen labels to full words with hex colour value. Fixed crop toolbar. Updated heatmap placeholder text.
- **What was done:**
  - Complete rewrite of certificate_service.dart generateCertificatePdf method with 7 tightly-stacked children in pw.Column
  - Fixed stone image: single pw.Image widget with fixed 160x160 container instead of split pieces
  - Fixed em-dash: replaced with ASCII hyphen in "Vivid - Royal Blue" to avoid broken character in Helvetica
  - Fixed VERIFICATION section: used fixed-width pw.Container(width: 180) so text never wraps
  - Fixed blank space: only one pw.Spacer() before footer, everything else stacks tightly
  - Fixed QR code: proper pw.BarcodeWidget with JSON data, no overlap with classification text
  - Added 9th column "Hex" to colour values table showing grade hex colour
  - Used intl DateFormat for all date formatting instead of manual string building
  - Result screen: changed labels from symbols (L*, a*, b*, C*, Sat, Brt, ΔE₀₀) to full words (Lightness, Green-Red, Blue-Yellow, Chroma, Saturation, Brightness, Delta E)
  - Result screen: added Hex Value row with coloured circle (24x24) + hex string from gradeColourHex
  - Result screen: changed heatmap placeholder to "Heatmap generated after model deployment" with subtitle "Connect to cloud backend to enable"
  - Capture screen: added showCropGrid and hideBottomControls: false to AndroidUiSettings
  - Android: created UCropTheme style with GemEye brand colours in styles.xml
  - Android: updated AndroidManifest.xml UCropActivity to use UCropTheme
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart (complete rewrite)
  - `~` app/lib/screens/result_screen.dart (full words + hex value + heatmap text)
  - `~` app/lib/screens/capture_screen.dart (crop toolbar settings)
  - `~` app/android/app/src/main/res/values/styles.xml (added UCropTheme)
  - `~` app/android/app/src/main/AndroidManifest.xml (UCropActivity theme reference)
- **Connected edits:** EDIT-015, EDIT-016 (fixes all certificate PDF issues from previous builds)
- **Reason:** Certificate PDF had 5 visual bugs (split image, wrapped text, broken character, QR overlap, blank space). Result screen used cryptic symbol labels. Crop toolbar needed theme fix.

---

### EDIT-018 | 23 August 2026 | IST
- **Topic:** Certificate PDF Error Fix + Crop Screen Cleanup
- **Summary:** Fixed certificate PDF generation crash caused by invalid pw.FontStyle.italic with named font, letterSpacing usage, pw.Spacer inside Column, and non-const pw.BorderRadius.circular. Hid confusing icon-only crop toolbar.
- **What was done:**
  - Complete safe rewrite of certificate_service.dart removing all crash-causing constructs:
    - Removed pw.FontStyle.italic (used with pw.Font.helveticaBold which conflicts)
    - Removed all letterSpacing usage (not reliably supported in pdf TextStyle)
    - Replaced pw.Spacer() with pw.SizedBox(height: 20) to avoid flex-parent requirement in Column
    - Replaced pw.BorderRadius.circular() with const pw.BorderRadius.all(pw.Radius.circular())
    - Removed intl/DateFormat dependency, using manual date formatting instead
    - Added try-catch around logo loading with debugPrint fallback
  - Refactored into clean static helper methods: _buildHeader, _buildGradeSection, _buildColourTable, _buildDetailsSection, _buildVerificationSection, _buildFooter, _sectionHeader, _detailRow
  - Used PdfColors.grey300 instead of PdfColor.fromHex for label colours where possible
  - Added error logging to certificate_screen.dart catch block with debugPrint for error and stack trace
  - Changed capture_screen.dart hideBottomControls to true — removes confusing icon-only UCrop toolbar, user crops via drag frame + checkmark
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart (complete safe rewrite)
  - `~` app/lib/screens/certificate_screen.dart (added error logging)
  - `~` app/lib/screens/capture_screen.dart (hideBottomControls: true)
- **Connected edits:** EDIT-015, EDIT-016, EDIT-017 (fixes PDF generation crash from previous builds)
- **Reason:** Certificate showed "Failed to generate PDF" due to incompatible pdf widget constructs. Crop screen had confusing icon-only toolbar.

---

### EDIT-019 | 23 August 2026 | IST
- **Topic:** Logo Background Fix
- **Summary:** Changed app icon and native splash background from Royal Blue (#1B3A8C) to white (#FFFFFF) so the blue logo is visible instead of invisible blue-on-blue.
- **What was done:**
  - Changed adaptive_icon_background in flutter_launcher_icons config from #1B3A8C to #FFFFFF
  - Changed all color/color_dark values in flutter_native_splash config from #1B3A8C to #FFFFFF (normal, dark, and android_12 sections)
  - Ran flutter clean + flutter pub get
  - Ran dart run flutter_launcher_icons — regenerated all Android and iOS app icons
  - Ran dart run flutter_native_splash:create — regenerated all native splash screens
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/pubspec.yaml (changed background colours to #FFFFFF in launcher_icons and native_splash configs)
- **Connected edits:** EDIT-016 (fixes invisible logo from original blue background choice)
- **Reason:** Blue logo on blue background was invisible — white background makes the logo clearly visible on app icon and cold-start splash

---

### EDIT-020 | 23 August 2026 | IST
- **Topic:** Three Bug Fixes — Certificate + Crop + Splash
- **Summary:** Fixed certificate PDF crash (color+decoration conflict in footer Container), restored crop toolbar controls (crop/rotate/scale icons), fixed splash logo cropping on Android 12 by adding icon_background_color.
- **What was done:**
  - Fixed _buildFooter in certificate_service.dart: moved `color: PdfColor.fromHex('#F5F7FA')` inside the BoxDecoration — Container cannot have both `color:` and `decoration:` simultaneously, which caused "Cannot provide both a color and a decoration" crash
  - Changed hideBottomControls from true to false in capture_screen.dart AndroidUiSettings — restores crop, rotate, and scale toolbar icons in UCrop
  - Added `icon_background_color: "#FFFFFF"` to flutter_native_splash android_12 config in pubspec.yaml — tells Android 12+ to use white background behind the icon instead of adaptive-icon squircle cropping
  - Ran flutter analyze — confirmed 0 issues
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart (moved color into BoxDecoration in _buildFooter)
  - `~` app/lib/screens/capture_screen.dart (hideBottomControls: false)
  - `~` app/pubspec.yaml (added icon_background_color for android_12 splash)
- **Connected edits:** EDIT-018 (certificate crash fix), EDIT-011 (crop toolbar), EDIT-019 (splash logo)
- **Reason:** Three targeted fixes for certificate PDF generation crash, missing crop toolbar controls, and Android 12 splash logo squircle cropping

---

### EDIT-021 | 24 August 2026 | IST
- **Topic:** Certificate PDF v3 — Balanced Professional Layout
- **Summary:** Complete rewrite of certificate PDF with balanced left-right content (equal flex columns), print-safe 36pt margins, increased section heights to fill A4 page, larger QR code, added Grade Colour row to stone details, added QR info box to verification section, zero blank space.
- **What was done:**
  - Complete rewrite of certificate PDF layout (v3) for balanced professional appearance
  - Implemented equal-flex left-right columns for balanced content distribution
  - Set print-safe 36pt margins on all sides
  - Increased section heights to fully utilise A4 page area with zero blank space
  - Enlarged QR code for better scannability
  - Added Grade Colour row to stone details section
  - Added QR info box to verification section explaining scan purpose
  - Ensured all content fills the page proportionally without wasted space
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart (complete rewrite v3)
- **Connected edits:** EDIT-018 (certificate system), EDIT-020 (certificate crash fix)
- **Reason:** Previous certificate layout had unbalanced content distribution, small QR code, missing grade colour information, and unused blank space — rewritten for a polished, print-ready professional certificate

---

### EDIT-022 | 24 August 2026 | IST
- **Topic:** Certificate Save Location + Capture Crop Guide
- **Summary:** Changed certificate PDF save location from hidden app storage to Downloads/GemEye Certificates/ folder so users can find certificates in their file manager. Added visual crop guide overlay in capture screen showing recommended stone framing size with target circle and zoom instructions.
- **What was done:**
  - Updated _savePdf in certificate_screen.dart to save to /storage/emulated/0/Download/GemEye Certificates/ on Android (with fallback to app documents on other platforms)
  - Creates GemEye Certificates subfolder automatically if it doesn't exist
  - Updated SnackBar to show green success message with user-friendly save path
  - Added crop guide visual to capture screen instruction card: 160x160 frame with corner crop marks, green target circle (90x90), diamond icon, zoom arrows, and instructional text
  - Converted capture screen body from Column with Spacers to SingleChildScrollView to accommodate taller content
  - Fixed withOpacity deprecation warning (replaced with withValues)
- **Files changed:**
  - `~` app/lib/screens/certificate_screen.dart (save to Downloads folder)
  - `~` app/lib/screens/capture_screen.dart (crop guide visual + scrollable layout)
- **Connected edits:** EDIT-014 (certificate screen), EDIT-010 (capture screen)
- **Reason:** Certificate PDFs saved to hidden app directory were inaccessible to users. Capture screen lacked visual guidance on how to frame the stone for optimal grading.

---

### EDIT-023 | 24 August 2026 | IST
- **Topic:** Certificate Save Verified + Capture Screen Compact Layout
- **Summary:** Verified certificate auto-creates GemEye Certificates folder in Downloads (no change needed). Rebuilt capture screen layout: removed top diamond icon, shrunk crop guide to 120x120 with 75x75 target circle, removed zoom arrows, reduced all spacing and text sizes, pinned buttons at bottom outside scroll area.
- **What was done:**
  - Verified certificate_screen.dart _savePdf already has correct folder auto-creation logic and SnackBar — no changes needed
  - Removed 80x80 white circle with diamond icon from top of capture instruction card
  - Shrunk crop guide frame from 160x160 to 120x120
  - Shrunk target circle from 90x90 to 75x75, diamond icon from 28 to 20
  - Shrunk corner crop marks from 18x18 to 14x14
  - Removed arrow_forward and arrow_back zoom indicator icons
  - Reduced card padding from EdgeInsets.all(24) to symmetric(horizontal: 20, vertical: 12)
  - Shortened description text to single concise line
  - Reduced description font size from 13 to 12
  - Reduced checklist spacing from SizedBox(height: 8) to SizedBox(height: 4)
  - Restructured body layout: Expanded + SingleChildScrollView for card/checklist, buttons pinned at bottom in separate Padding widget
  - Reduced Take Photo button height from 56 to 52, Gallery button from 48 to 44, spacing between them from 12 to 8
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart (compact layout, pinned buttons, removed icon, shrunk guide)
- **Connected edits:** EDIT-022 (refines capture screen crop guide layout)
- **Reason:** Previous layout with large icon and guide required scrolling to reach buttons on smaller screens — compacted everything and pinned buttons at bottom for consistent accessibility

---

### EDIT-024 | 24 August 2026 | IST
- **Topic:** Capture Screen Layout Fix + SnackBar Theme
- **Summary:** Removed blank space on capture screen by putting all content and buttons in single scrollable column with no Expanded/Spacer. Changed certificate save SnackBar background from green to Royal Blue app theme colour.
- **What was done:**
  - Removed Expanded widget wrapping the card/checklist content area
  - Removed separate bottom-pinned buttons Padding section
  - Put card, checklist, and buttons all inside one SingleChildScrollView Column — content flows naturally top to bottom with no blank space
  - Added SizedBox(height: 20) gap between checklist and buttons
  - Changed certificate save SnackBar backgroundColor from Color(0xFF059669) (green) to Color(0xFF1B3A8C) (Royal Blue)
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart (layout restructure, no blank space)
  - `~` app/lib/screens/certificate_screen.dart (SnackBar colour to #1B3A8C)
- **Connected edits:** EDIT-023 (refines capture screen layout from previous edit)
- **Reason:** Expanded + SingleChildScrollView left blank white space between checklist and buttons when content didn't fill the expanded area. Green SnackBar was inconsistent with Royal Blue app theme.

---

### EDIT-025 | 24 August 2026 | IST
- **Topic:** Capture Screen Full-Height Card + SnackBar Theme
- **Summary:** Expanded capture instruction card to fill all available space between app bar and buttons using Expanded widget. Moved checklist inside card. Centred content vertically. Zero blank space. Certificate save SnackBar already Royal Blue from EDIT-024.
- **What was done:**
  - Wrapped card Container in Expanded so it fills all space between app bar and buttons
  - Set card Column to mainAxisAlignment: MainAxisAlignment.center for vertical centering
  - Moved checklist items inside the card (previously separate below card)
  - Increased zoom guide frame from 120x120 to 140x140, target circle from 75x75 to 85x85
  - Increased corner marks from 14x14 to 16x16, diamond icon from 20 to 22
  - Changed card background from GemEyeColors.primarySurface to Color(0xFFF5F7FA) with no border
  - Simplified _buildCheckItem helper to single-parameter version (always checked)
  - Gallery button height matched to Take Photo at 52px, font size to 16px
  - Buttons remain outside Expanded, pinned at bottom with 12px top padding
  - Verified certificate_screen.dart SnackBar already uses Color(0xFF1B3A8C) from EDIT-024
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart (full-height card layout)
- **Connected edits:** EDIT-024 (replaces flat ScrollView layout with full-height card)
- **Reason:** Previous flat SingleChildScrollView layout left the card at natural height with blank white space below — expanding the card to fill all available space eliminates the gap entirely.

---

### EDIT-026 | 24 August 2026 | IST
- **Topic:** Splash Logo Fix + Crop Edit Guide
- **Summary:** Removed Android 12 splash image to prevent squircle cropping of round logo. Added crop guide bottom sheet showing icon labels (Scale, Rotate, Aspect Ratio) before UCrop opens so users understand each control.
- **What was done:**
  - Removed image, image_dark, and icon_background_color from android_12 section in flutter_native_splash config — Android 12+ now shows plain white splash (no cropped logo), then Lottie diamond animation plays
  - Regenerated native splash screens via dart run flutter_native_splash:create
  - Added _showCropGuide bottom sheet method to capture screen — shows Scale, Rotate, Aspect Ratio icons with text labels and "Got it, Open Editor" button before opening UCrop
  - Added _guideItem helper widget for icon+label columns using GemEyeColors and GemEyeFonts
  - Updated _captureImage and _pickFromGallery to show crop guide before opening cropper instead of calling _cropAndProceed directly
  - Added statusBarLight to AndroidUiSettings (replaced deprecated statusBarColor)
  - Used GemEyeColors constants instead of hardcoded hex values in crop error SnackBar and UCrop settings
  - Created strings.xml with UCrop string resource overrides for aspect ratio labels
  - Ran flutter analyze — 0 errors, 0 warnings (15 pre-existing info-level lints in certificate_service.dart)
- **Files changed:**
  - `~` app/pubspec.yaml (removed android_12 splash image/image_dark/icon_background_color)
  - `~` app/lib/screens/capture_screen.dart (added crop guide bottom sheet, wired into capture/gallery flows)
  - `+` app/android/app/src/main/res/values/strings.xml (UCrop string resources)
- **Connected edits:** EDIT-020 (splash logo fix), EDIT-018 (crop toolbar)
- **Reason:** Android 12+ squircle cropping made circular logo look zoomed and clipped. UCrop bottom toolbar showed icon-only controls without text labels — users couldn't identify Scale/Rotate/Aspect Ratio functions.

---

### EDIT-027 | 24 August 2026 | IST
- **Topic:** UCrop Theme + Layout Override + Remove Guide Sheet
- **Summary:** Removed Image Edit Controls bottom sheet. Created custom UCrop theme with app colours (white background, Royal Blue active). Overrode UCrop layout to force all tab text labels visible (Scale, Rotate, Crop).
- **What was done:**
  - Deleted _showCropGuide method and _guideItem helper from capture_screen.dart
  - Restored direct _cropAndProceed calls in _captureImage and _pickFromGallery (no bottom sheet intermediary)
  - Updated AndroidUiSettings with statusBarColor, backgroundColor, and hardcoded hex colours per spec
  - Removed initAspectRatio and statusBarLight, added statusBarColor and backgroundColor
  - Expanded UCropTheme in styles.xml with full colour attributes: ucrop_color_toolbar_widget, ucrop_color_statusbar, ucrop_color_widget_active, ucrop_color_widget_inactive, ucrop_color_widget_background (white), ucrop_color_widget_rotate_mid_line, ucrop_color_crop_background
  - Created ucrop_controls_wrapper.xml layout override with three LinearLayout tabs (Scale, Rotate, Crop) each containing ImageView + TextView with android:visibility="visible" to force text labels
  - AndroidManifest.xml UCropActivity already had @style/UCropTheme — no change needed
  - Ran flutter analyze — 0 errors, 0 warnings (16 pre-existing info-level lints)
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart (removed _showCropGuide/_guideItem, restored direct crop calls, updated AndroidUiSettings)
  - `~` app/android/app/src/main/res/values/styles.xml (expanded UCropTheme with full colour attributes)
  - `+` app/android/app/src/main/res/layout/ucrop_controls_wrapper.xml (custom layout with visible text labels)
- **Connected edits:** EDIT-026 (removes bottom sheet added there), EDIT-020 (UCrop theme)
- **Reason:** Bottom sheet was unnecessary UX friction. UCrop bottom bar had dark/black background not matching app theme. Tab icons showed without text labels — users couldn't identify Scale/Rotate/Crop functions.

---

### EDIT-028 | 24 August 2026 | IST
- **Topic:** Fix UCrop Build Failure — Remove Unsupported Style Attributes
- **Summary:** Reverted UCropTheme to basic AppCompat attributes only. Removed custom layout override. The ucrop_color_* style attributes and ucrop_ic_* drawables are not exposed by image_cropper v8.0.2's bundled UCrop library, causing Android resource linking failure.
- **What was done:**
  - Reverted UCropTheme in styles.xml to 3 basic attributes: colorPrimary, colorPrimaryDark, colorAccent — these are standard AppCompat attributes that UCrop inherits
  - Deleted ucrop_controls_wrapper.xml layout override — the UCrop resource IDs (@drawable/ucrop_ic_scale etc.) are not accessible from the app module in this package version
  - Ran flutter clean + flutter pub get
  - Ran flutter analyze — 0 errors, 0 warnings (16 pre-existing info-level lints)
- **Files changed:**
  - `~` app/android/app/src/main/res/values/styles.xml (reverted UCropTheme to basic attrs)
  - `-` app/android/app/src/main/res/layout/ucrop_controls_wrapper.xml (deleted)
- **Connected edits:** EDIT-027 (fixes build failure from that edit's UCrop style attributes)
- **Reason:** image_cropper v8.0.2 bundles UCrop as an AAR that does not expose ucrop_color_* attrs or ucrop_ic_* drawables to the app module — referencing them causes Android resource linking failure at build time.

---

### EDIT-029 | 24 August 2026 | IST
- **Topic:** Revert UCrop Style Changes
- **Summary:** Reverted all UCrop theme and layout overrides that caused build failures. UCrop bottom toolbar uses default styling. The ucrop_color_* attributes are not accessible in image_cropper v8.1.0.
- **What was done:**
  - Reverted styles.xml to original two styles only (LaunchTheme + NormalTheme) — removed UCropTheme entirely
  - Reverted AndroidManifest.xml UCropActivity theme from @style/UCropTheme to @style/Theme.AppCompat.Light.NoActionBar
  - Removed statusBarColor and backgroundColor from AndroidUiSettings in capture_screen.dart — eliminates deprecation warning
  - Deleted layout/ directory (was already empty after EDIT-028)
  - Ran flutter clean + flutter pub get
  - Ran flutter analyze — 0 errors, 0 warnings (15 pre-existing info-level lints)
- **Files changed:**
  - `~` app/android/app/src/main/res/values/styles.xml (reverted to original LaunchTheme + NormalTheme only)
  - `~` app/android/app/src/main/AndroidManifest.xml (reverted UCropActivity theme)
  - `~` app/lib/screens/capture_screen.dart (removed statusBarColor, backgroundColor from AndroidUiSettings)
  - `-` app/android/app/src/main/res/layout/ (deleted empty directory)
- **Connected edits:** EDIT-027, EDIT-028 (completes full revert of UCrop customisation attempts)
- **Reason:** UCrop theme attributes (ucrop_color_*) and drawable resources (ucrop_ic_*) are not exposed by image_cropper v8.1.0's bundled UCrop AAR — all customisation attempts caused build failures. Default styling is the only working option with this package version.
---

### EDIT-030 | 01 September 2026 | IST
- **Topic:** Center Content on Processing + Capture Screens
- **Summary:** Vertically centered all content on the processing screen (Lottie animation + steps list). Centered checklist items horizontally within the capture instruction card to eliminate bottom empty space.
- **What was done:**
  - Processing screen: Added `mainAxisSize: MainAxisSize.min` to the main Column so the `Center` widget can properly shrink-wrap and vertically center all content (Lottie animation, title, 7-step list, remaining time)
  - Capture screen: Added `mainAxisSize: MainAxisSize.min` to the checklist Row widgets so they shrink-wrap instead of expanding to full width, allowing the parent Column's center cross-axis alignment to horizontally center them within the card
- **Files changed:**
  - `~` app/lib/screens/processing_screen.dart (added mainAxisSize.min to Column for vertical centering)
  - `~` app/lib/screens/capture_screen.dart (added mainAxisSize.min to _buildCheckItem Row for horizontal centering)
- **Connected edits:** EDIT-008 (Processing screen creation), EDIT-026 (Capture screen crop UX)
- **Reason:** Processing screen content was flush to the top with empty space below despite Center wrapper — Column defaulted to max height. Capture screen checklist items were left-aligned spanning full width instead of centered within the card.

---

### EDIT-031 | 01 September 2026 | IST
- **Topic:** Fix Checklist Alignment on Capture Screen
- **Summary:** Wrapped checklist items in Center + Column(crossAxisAlignment: start) so items are left-aligned as a group but the group is centered horizontally in the card.
- **What was done:**
  - Wrapped all four `_buildCheckItem` calls in a `Center` widget containing a `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `mainAxisSize: MainAxisSize.min`
  - This keeps all checklist text left-aligned with each other (consistent start position) while centering the group as a whole within the card
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart (checklist group alignment)
- **Connected edits:** EDIT-030 (previous capture screen centering fix)
- **Reason:** Each checklist item was individually centered by the parent Column's default crossAxisAlignment, causing each line to start at a different horizontal position depending on text length. Grouping them fixes the alignment.

---

### EDIT-032 | 02 September 2026 | IST
- **Topic:** Center Processing Screen Content (Verified)
- **Summary:** Verified that the processing screen already uses Center widget + mainAxisSize.min — no code changes needed.
- **What was done:**
  - Inspected processing_screen.dart body layout
  - Confirmed Center wrapper is already at line 90, Padding with horizontal: 32 at line 92, and Column with mainAxisSize: MainAxisSize.min at lines 93-94
  - No SingleChildScrollView present — layout is already correct
- **Files changed:**
  - (none — already implemented in EDIT-030)
- **Connected edits:** EDIT-008 (Processing screen creation), EDIT-030 (Center content on processing & capture screens)
- **Reason:** Requested centering fix was already applied in EDIT-030. No further changes required.

---

### EDIT-033 | 02 September 2026 | IST
- **Topic:** Fix Processing Screen Centering
- **Summary:** Used SizedBox.expand + MainAxisAlignment.center to force vertical centering of Lottie animation and step list on processing screen.
- **What was done:**
  - Replaced `Center` wrapper with `SizedBox.expand` to force the Column to fill the full available screen height
  - Replaced `mainAxisSize: MainAxisSize.min` with `mainAxisAlignment: MainAxisAlignment.center` so content is pushed to the vertical centre
  - Adjusted spacing: title gap 32→24, remaining time gap 24→16
  - Ran flutter analyze — zero errors (15 pre-existing info warnings in certificate_service.dart)
- **Files changed:**
  - `~` app/lib/screens/processing_screen.dart (SizedBox.expand + MainAxisAlignment.center)
- **Connected edits:** EDIT-008 (Processing screen creation), EDIT-030, EDIT-032 (previous centering attempts)
- **Reason:** Previous Center + mainAxisSize.min approach did not visually center the content — it remained pushed toward the top. SizedBox.expand forces the Column to take full height, allowing MainAxisAlignment.center to work correctly.

---

### EDIT-034 | 02 September 2026 | IST
- **Topic:** Center Step List Group Horizontally on Processing Screen
- **Summary:** Wrapped the 7 analysing steps in a Center + Column(crossAxisAlignment: start) group so the entire step list block is horizontally centered on screen while keeping text left-aligned within the group.
- **What was done:**
  - Wrapped all 7 step `Row` widgets inside a `Center` > `Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min)` structure
  - Added `mainAxisSize: MainAxisSize.min` to each step `Row` so rows shrink to content width instead of stretching full width
  - This centres the step list block as a whole while keeping all step labels left-aligned with each other
  - Ran flutter analyze — zero errors (15 pre-existing info warnings in certificate_service.dart)
- **Files changed:**
  - `~` app/lib/screens/processing_screen.dart (step list horizontal centering)
- **Connected edits:** EDIT-033 (vertical centering), EDIT-031 (same pattern used on capture screen checklist)
- **Reason:** Step list rows stretched full width by default, making the group appear left-aligned. Wrapping in Center with min-sized rows centres the block as a unit.

---

### EDIT-035 | 02 September 2026 | IST
- **Topic:** Phase D — History, Filters, Batch Actions, Comparison
- **Summary:** Implemented grading history screen with search, grade filter chips, filter bottom sheet (date/confidence/certificate/sort), swipe-to-delete, batch selection mode with export/share/delete actions, and stone comparison screen with delta-E calculation and value comparison table.
- **What was done:**
  - Created history_screen.dart with full grading history list, search by stone ID, grade filter chips (All + G1–G7 with colour circles)
  - Added filter bottom sheet with date range pickers, confidence filter (All/High/Medium/Low), certificate status (All/Exported/Not exported), sort options (6 choices)
  - Filter icon in AppBar shows badge count when filters are active
  - Each history item shows grade colour swatch, grade + trade name, stone ID + confidence + time ago, and "Exported" badge if certificate exists
  - Swipe-to-delete with red background and confirmation dialog
  - Long-press enters batch selection mode with checkboxes, select all/deselect, and cancel
  - Batch action bar with Export All (generates certificates + PDFs), Share (stone images), and Delete (with confirmation)
  - Certificate reuse: export checks for existing certificateNumber before generating new one
  - Created comparison_screen.dart with two stone selection cards, stone picker bottom sheet
  - Comparison body: side-by-side images with grade badges, delta-E card with colour-coded severity, grades apart text
  - Value comparison table (Lightness, Green-Red, Blue-Yellow, Chroma, Hue, Saturation, Brightness) with colour-coded diff column
  - Swap A↔B and Compare Another buttons
  - Connected history_screen to 3rd bottom navigation tab (replaced placeholder)
  - Connected comparison_screen to side drawer "Stone Comparison" menu item
  - Ran flutter analyze — zero errors, zero warnings (21 pre-existing info-level hints only)
- **Files changed:**
  - `+` app/lib/screens/history_screen.dart (new — full history with search, filters, batch actions)
  - `+` app/lib/screens/comparison_screen.dart (new — stone comparison with delta-E)
  - `~` app/lib/screens/main_shell.dart (replaced History placeholder with HistoryScreen)
  - `~` app/lib/widgets/side_drawer.dart (Stone Comparison navigates to ComparisonScreen)
- **Connected edits:** EDIT-019 (result screen), EDIT-020 (certificate service), EDIT-016 (storage service)
- **Reason:** Phase D implementation — grading history is the 3rd bottom nav tab, comparison is accessible from the side drawer. Both screens are core features for reviewing and comparing graded stones.

---

### EDIT-036 | 04 September 2026 | IST
- **Topic:** Fix Drawer Navigation for All Menu Items
- **Summary:** Connected all 10 side drawer menu items to their correct screens. Added onTabSwitch callback so drawer can switch bottom nav tabs. Created inline placeholder screens for Settings, Privacy Policy, About, and Feedback. Added logout confirmation dialog with Firebase sign out.
- **What was done:**
  - Added `onTabSwitch` callback parameter to `GemEyeSideDrawer` widget
  - Updated `MainShell` to pass tab-switching callback to the drawer
  - Home → closes drawer and switches to tab 0
  - Grade a Stone → closes drawer and pushes CaptureScreen
  - Grading History → closes drawer and switches to tab 2
  - Colour Grade Guide → closes drawer and switches to tab 3
  - Stone Comparison → closes drawer and pushes ComparisonScreen (already working)
  - Settings → closes drawer and pushes placeholder Settings screen
  - Feedback → closes drawer and shows "Coming Soon" bottom sheet
  - Privacy Policy → closes drawer and pushes inline Privacy Policy screen
  - About → closes drawer and pushes inline About screen (no student number per CLAUDE.md rules)
  - Logout → closes drawer, shows confirmation AlertDialog, signs out via AuthService, navigates to LoginScreen
  - All placeholder screens use GemEyeColors and GemEyeFonts (no hardcoded values)
  - Ran flutter analyze — zero errors, zero warnings
- **Files changed:**
  - `~` app/lib/widgets/side_drawer.dart (added onTabSwitch callback, wired all 10 menu items)
  - `~` app/lib/screens/main_shell.dart (passes onTabSwitch callback to drawer)
- **Connected edits:** EDIT-035 (drawer previously had Stone Comparison wired), EDIT-008 (auth flow)
- **Reason:** Most drawer menu items only closed the drawer without navigating anywhere. All 10 items now correctly navigate to their intended destinations.

---

### EDIT-037 | 04 September 2026 | IST
- **Topic:** Fix Back Button Navigation
- **Summary:** Added PopScope to MainShell so the Android back button returns to the Home tab before exiting the app. Shows an exit confirmation dialog when pressing back on the Home tab.
- **What was done:**
  - Wrapped MainShell Scaffold with PopScope (canPop: false)
  - Back button on non-Home tabs (History, Guide) switches to Home tab instead of exiting
  - Back button on Home tab shows "Exit GemEye?" confirmation dialog styled with GemEye fonts and colours
  - Drawer tab items (Home, History, Guide) already use onTabSwitch correctly — no changes needed there
  - Drawer-pushed screens (Settings, About, Privacy Policy, Stone Comparison) use Navigator.push, so their AppBar back arrow works as expected via Navigator.pop
- **Files changed:**
  - `~` app/lib/screens/main_shell.dart (added PopScope wrapper and exit confirmation dialog)
- **Connected edits:** EDIT-036 (drawer navigation), EDIT-003 (main shell creation)
- **Reason:** Pressing the Android back button on non-Home tabs or after drawer navigation was exiting the app entirely instead of returning to the Home tab first.

---

### EDIT-038 | 07 September 2026 | IST
- **Topic:** Phase E — Settings, About, Privacy, Feedback, Colour Guide
- **Summary:** Created full Settings screen with 14 items (profile, calibration, preferences, security, data management). Created About screen with 5 sections (app info, developer, academic, industry, footer). Replaced Privacy Policy screen with structured 6-section layout. Created Feedback bottom sheet with 5-star rating and comment. Created Colour Grade Guide screen with gradient strip and 7 expandable grade cards loading from colour_grades.json. Updated drawer navigation to use new screen files. Replaced Guide tab placeholder in MainShell with GuideScreen.
- **What was done:**
  - Created Settings screen with profile edit bottom sheet, calibration section, confidence threshold slider, export format dropdown, certificate prefix editor, auto-save toggle, change password/email dialogs, export data, clear history, delete account
  - Created About screen with app info, developer section with social links (url_launcher), 3 academic supervisor placeholders, 3 industry partner placeholders, footer
  - Rewrote Privacy Policy screen with 6 titled sections (Introduction, Data Collected, How Data Is Used, Data Storage, Data Deletion, Contact) replacing markdown-based implementation
  - Created Feedback bottom sheet with 5-star rating (amber), comment TextField, submit to SharedPreferences
  - Created Colour Grade Guide screen with full gradient strip (G1-G7), 7 ExpansionTile cards loading from colour_grades.json, info chips for Hue/Sat/Brt/L*/b*, source attribution
  - Updated colour_grades.json with new format (colourStart, colourEnd, tradeName, hueRange, satRange, brtRange, labL, labB)
  - Updated side drawer to import and navigate to new screen files instead of inline placeholders
  - Replaced Guide tab placeholder in MainShell with GuideScreen widget
- **Files changed:**
  - `+` app/lib/screens/settings_screen.dart (new — 14 settings items in 6 sections)
  - `+` app/lib/screens/about_screen.dart (new — 5 sections with social links)
  - `+` app/lib/screens/feedback_sheet.dart (new — star rating + comment bottom sheet)
  - `+` app/lib/screens/guide_screen.dart (new — gradient strip + 7 expandable grade cards)
  - `~` app/lib/screens/privacy_screen.dart (replaced markdown approach with 6 structured sections)
  - `~` app/assets/data/colour_grades.json (updated format with new fields)
  - `~` app/lib/widgets/side_drawer.dart (updated Settings, About, Privacy, Feedback to use new screens)
  - `~` app/lib/screens/main_shell.dart (replaced Guide placeholder with GuideScreen)
- **Connected edits:** EDIT-036 (drawer navigation), EDIT-001 (colour_grades.json creation), EDIT-003 (main shell)
- **Reason:** Phase E implementation — completing the remaining screens (Settings, About, Privacy, Feedback, Colour Guide) to replace all inline placeholders with fully functional dedicated screen files.

---

### EDIT-039 | 07 September 2026 | IST
- **Topic:** Profile Screen
- **Summary:** Created dedicated Profile screen with user photo, editable fields (name, phone, company, designation), grading statistics cards (total graded, certificates, this month), account information section, and save functionality. Connected to drawer header tap and Settings first item.
- **What was done:**
  - Created ProfileScreen with user photo + camera edit overlay, display name, email, account type badge
  - Added 4 editable fields: Full Name, Phone Number, Company (optional), Designation (optional)
  - Added Grading Statistics section with 3 stat cards (Total Graded, Certificates, This Month) loaded from StorageService
  - Added Account Information section showing email, account created date, last sign in, auth provider from Firebase metadata
  - Save button updates Firebase displayName and saves phone/company/designation to SharedPreferences
  - Made drawer header (user photo/name/email area) tappable to navigate to ProfileScreen
  - Updated Settings screen Profile ListTile to navigate to ProfileScreen instead of showing edit bottom sheet
  - Removed unused _showProfileEditSheet method from SettingsScreen
- **Files changed:**
  - `+` app/lib/screens/profile_screen.dart (new — full profile with photo, editable fields, stats, account info)
  - `~` app/lib/widgets/side_drawer.dart (added GestureDetector on header, import ProfileScreen)
  - `~` app/lib/screens/settings_screen.dart (Profile item navigates to ProfileScreen, removed old bottom sheet)
- **Connected edits:** EDIT-038 (Settings screen creation), EDIT-036 (drawer navigation)
- **Reason:** Users need a dedicated profile screen to view and edit their personal information, see grading statistics, and review account details in one place.

---

### EDIT-040 | 10 September 2026 | IST
- **Topic:** Dataset Folder Restructure
- **Summary:** Restructured dataset folder from flat grade folders to proper ML training structure with raw_by_shape (4 shapes x 7 grades), merged (7 grades, 160 images each), ccc_patches, processed, and splits directories. Added .gitignore rules to exclude image files from GitHub (too large for repo). Added .gitkeep files to preserve empty folder structure. Created comprehensive dataset README.md with capture protocol, grade definitions, and folder documentation.
- **What was done:**
  - Deleted old flat folder structure (calibration, grade_1_dark through grade_7_very_light, repeatability)
  - Created raw_by_shape/ with 4 shape subdirectories (baguette, oval, pear, round) each with grade_1 through grade_7
  - Created merged/ with 7 grade folders (grade_1_dark through grade_7_very_light)
  - Created ccc_patches/ for CCC calibration reference images
  - Created processed/ with grade_1 through grade_7
  - Created splits/ with train, val, test subdirectories
  - Added .gitkeep files in all 45 leaf folders to preserve structure in Git
  - Updated .gitignore with expanded image exclusion rules (bmp, tiff, tif, webp, HEIC, heic) and !.gitkeep exception
  - Added commented-out model weight exclusion rules (h5, pkl, pt, onnx)
  - Created dataset/README.md with overview table, folder structure diagram, 7 GEMCLOUD grades, capture protocol, device info, and important notes
- **Files changed:**
  - `-` dataset/calibration/ (deleted)
  - `-` dataset/grade_1_dark/ through grade_7_very_light/ (deleted old structure)
  - `-` dataset/repeatability/ (deleted)
  - `+` dataset/raw_by_shape/baguette/grade_1-7/ (new)
  - `+` dataset/raw_by_shape/oval/grade_1-7/ (new)
  - `+` dataset/raw_by_shape/pear/grade_1-7/ (new)
  - `+` dataset/raw_by_shape/round/grade_1-7/ (new)
  - `+` dataset/merged/grade_1_dark through grade_7_very_light/ (new)
  - `+` dataset/ccc_patches/ (new)
  - `+` dataset/processed/grade_1-7/ (new)
  - `+` dataset/splits/train/ val/ test/ (new)
  - `+` dataset/README.md (new - full documentation)
  - `~` .gitignore (added image exclusion rules)
- **Connected edits:** EDIT-001 (original dataset folder creation)
- **Reason:** Flat grade-only structure did not support multi-shape capture workflow, merged training pipeline, CCC calibration patches, processed outputs, or train/val/test splits needed for the ML training pipeline.

### EDIT-041 | 10 September 2026 | IST
- **Topic:** Dataset Image Auto-Rename Script
- **Summary:** Created Python script (`dataset/rename_images.py`) to auto-rename all dataset images from mobile camera names (e.g., `IMG_20260823_141234.jpg`) to consistent traceable format. Script uses two-pass rename (temp names first, then final names) to avoid file conflicts.
- **What was done:**
  - Created `dataset/rename_images.py` with CLI modes: `raw`, `merged`, `all`
  - **Naming convention:**
    - `raw_by_shape`: `{shape}_g{grade}_{NNN}.jpg` (e.g., `baguette_g1_001.jpg`, `oval_g3_015.jpg`)
    - `merged`: `g{grade}_{NNN}.jpg` (e.g., `g1_001.jpg`, `g3_160.jpg`)
    - `ccc_patches`: manually named (`white.jpg`, `black.jpg`, `grey_18.jpg`, `grey_50.jpg`, `blue.jpg`, `red.jpg`)
  - **Dataset mechanism:**
    - `raw_by_shape/`: preserves original shape separation (4 shapes × 7 grades × 40 images = 1,120)
    - `merged/`: all 4 shapes combined per grade (7 grades × 160 images = 1,120) — shape intentionally NOT tracked because model learns COLOUR not shape
    - `ccc_patches/`: 6 CCC calibration reference images for colour correction
    - `processed/`: auto-generated after CCC colour correction pipeline runs
    - `splits/`: auto-generated train (80%) / val (10%) / test (10%) split
  - **Manual steps required:**
    1. Paste original images into `raw_by_shape/{shape}/grade_{N}/` folders (28 folders)
    2. Copy same images merged by grade into `merged/grade_{N}_{name}/` folders (7 folders, 160 each)
    3. Paste 6 CCC patch images into `ccc_patches/` with correct names
    4. Run: `cd dataset && python rename_images.py all`
  - Image files excluded from GitHub via `.gitignore` (2–5 GB too large for repo)
  - Images stored: locally on PC + Google Drive for Colab training
  - Folder structure preserved in GitHub via `.gitkeep` files
- **Files changed:**
  - `+` dataset/rename_images.py (new — auto-rename script)
- **Connected edits:** EDIT-040 (dataset folder restructure)
- **Reason:** Dataset images from different capture sessions had inconsistent mobile camera names, making it difficult to track counts, identify duplicates, and maintain the ML training pipeline. Consistent naming enables reliable train/val/test splitting and grade verification.

### EDIT-042 | 01 October 2026 21:35 | IST
- **Topic:** UI Redesign A1 — Design Tokens and Group A Widgets
- **Summary:** Added named design tokens (AppColors, AppText, AppRadius, AppSpacing) to theme.dart and built the reusable Component Sheet widgets used by the Group A screens. Bundled Roboto Medium for the Google sign-in button.
- **What was done:**
  - Added `AppColors` (brand, neutrals, status, tints, Google branding, 7 GEMCLOUD grade colours, 6 calibration patch colours), `AppText` (font families + text style scale), `AppRadius`, `AppSpacing`, `AppSystemUi`
  - Kept `GemEyeColors` / `GemEyeFonts` as aliases of the new tokens so screens not yet redesigned still compile
  - Created widgets: PrimaryButton, TextLinkButton, GemAppBar, CardContainer, InputField (with FieldLabel / FieldErrorText), PasswordField (live rule checklist), DropdownField (MenuAnchor menu), AppCheckbox, AppSnackBar, LoadingIndicator, GoogleSignInButton, SegmentedToggle, ImagePickerField (JPG/PNG, 5 MB limit)
  - Added Roboto-Medium.ttf (from the Flutter SDK's bundled Material fonts) and registered it in pubspec.yaml
- **Files changed:**
  - `~` app/lib/config/theme.dart
  - `+` app/lib/widgets/app_buttons.dart
  - `+` app/lib/widgets/app_checkbox.dart
  - `+` app/lib/widgets/app_snack_bar.dart
  - `+` app/lib/widgets/card_container.dart
  - `+` app/lib/widgets/dropdown_field.dart
  - `+` app/lib/widgets/gem_app_bar.dart
  - `+` app/lib/widgets/google_sign_in_button.dart
  - `+` app/lib/widgets/image_picker_field.dart
  - `+` app/lib/widgets/input_field.dart
  - `+` app/lib/widgets/loading_indicator.dart
  - `+` app/lib/widgets/password_field.dart
  - `+` app/lib/widgets/segmented_toggle.dart
  - `+` app/assets/fonts/Roboto-Medium.ttf
  - `~` app/pubspec.yaml (Roboto font family)
- **Connected edits:** Claude Design Group A export (design/exports/groupA/Component Sheet.dc.html)
- **Reason:** The redesign needs one source of truth for colours, fonts, radii and spacing, and shared widgets so every screen matches the Component Sheet.

### EDIT-043 | 01 October 2026 21:35 | IST
- **Topic:** UI Redesign A2 — Splash
- **Summary:** Restyled the Splash screen per the design. The existing Lottie animation and 3 s routing were kept.
- **What was done:**
  - New centred layout: sapphire_rotate.json Lottie (120 dp), GemEye wordmark (28 Poppins Bold), tagline, version footer
  - Dark status bar icons on white background
  - Logo asset used as Lottie error fallback
- **Files changed:**
  - `~` app/lib/screens/splash_screen.dart
- **Connected edits:** EDIT-042; Claude Design Group A export (design/exports/groupA/Splash.dc.html)
- **Reason:** Apply the approved Splash design without changing the animation asset or startup routing.

### EDIT-044 | 01 October 2026 21:37 | IST
- **Topic:** UI Redesign A3 — Privacy Agreement and Shared Policy Text
- **Summary:** Rebuilt the Privacy Agreement screen per the design and replaced privacy_policy.md with the 8 design sections. Agreement and Privacy Policy screens now render the same markdown file.
- **What was done:**
  - Agreement: GemAppBar "Before you start", "Your data, in short" summary card, scrollable policy, fixed bottom AppCheckbox + PrimaryButton disabled until ticked
  - privacy_policy.md rewritten: Data Collection, Data Storage, Data Sharing, Data Retention, Data Deletion, Image Ownership, AI Processing, No Commercial Use (last updated 1 October 2026)
  - Created PolicyMarkdown widget that loads and styles the markdown
  - privacy_screen.dart: removed hardcoded strings, now uses PolicyMarkdown
- **Files changed:**
  - `~` app/assets/data/privacy_policy.md
  - `~` app/lib/screens/agreement_screen.dart
  - `~` app/lib/screens/privacy_screen.dart
  - `+` app/lib/widgets/policy_markdown.dart
- **Connected edits:** EDIT-042; Claude Design Group A export (design/exports/groupA/Privacy Agreement.dc.html)
- **Reason:** The two privacy screens showed different text; one markdown source keeps them consistent with the design.

### EDIT-045 | 01 October 2026 21:39 | IST
- **Topic:** UI Redesign A4 — Login
- **Summary:** Rebuilt the Login screen per the design with the real logo, a Google-branded sign-in button and an inline credential error. Existing auth callbacks were kept.
- **What was done:**
  - logo.png + GemEye wordmark header
  - GoogleSignInButton (white, 1 px #747775 border, Roboto Medium 14, official G logo)
  - "or" divider (new OrDivider widget)
  - Labelled email/password fields; Firebase credential errors show "Incorrect email or password" inline in red
  - Separate loading states: "Signing in…" on Google, "Logging in…" on Log In
  - Friendly AppSnackBar messages instead of raw Firebase error text
  - "Forgot password?" and "New to GemEye? Register" as TextLinkButtons
- **Files changed:**
  - `~` app/lib/screens/login_screen.dart
  - `+` app/lib/widgets/or_divider.dart
- **Connected edits:** EDIT-042; Claude Design Group A export (design/exports/groupA/Login.dc.html)
- **Reason:** Apply the approved Login design and follow Google sign-in branding rules.

### EDIT-046 | 01 October 2026 21:41 | IST
- **Topic:** UI Redesign A5 — Register
- **Summary:** Rebuilt the Register screen per the design with Individual/Company account types, full validation, image pickers and a Google profile-completion variant.
- **What was done:**
  - SegmentedToggle Individual / Company
  - Individual fields: profile photo, Full Name, Email, Password, Phone, Country, Role
  - Company fields: Company details (name, logo, business reg. no, country, industry) and Contact person (name, email, password, phone, address)
  - Validation messages: "Required", "Enter a valid email address", "Password does not meet the requirements"; password rules 8+ chars, 1 uppercase, 1 number; "N fields need attention" snackbar
  - Google "Complete your profile" variant: name and email locked with "From Google", no password field (`RegisterScreen(completeGoogleProfile: true)`)
  - Fixed bottom "Create Account" bar with loading state
  - Added `TODO(F2)`: company profile, phone, country, role, profile photo and company logo are not persisted yet
- **Files changed:**
  - `~` app/lib/screens/register_screen.dart
- **Connected edits:** EDIT-042; Claude Design Group A export (design/exports/groupA/Register.dc.html)
- **Reason:** Apply the approved Register design and support users who sign up with Google.

### EDIT-047 | 01 October 2026 21:58 | IST
- **Topic:** UI Redesign A6 — Onboarding and On-Device Fixes
- **Summary:** Rebuilt Onboarding as 4 widget-built slides per the design, initially shown once per device after registration. Fixed layout issues found while testing on a OnePlus Nord 2.
- **What was done:**
  - Slides: 7-grade ring around a sapphire, kit checklist, calibration card with patch colours White #FFFFFF, Black #000000, 18% Grey #757575, 50% Grey #BABABA, Blue #003F87, Red #AF363C, sample grade report
  - Skip (hidden on last slide), animated dots, Next / Get Started
  - Once-per-device flag `onboarding_done` in SharedPreferences (replaced in EDIT-048)
  - Slide 4 grade card uses solid Grade 3 colour instead of the design's gradient, because CLAUDE.md forbids gradient card backgrounds. No CLAUDE.md exception for a GradeBadgeCard has been added yet.
  - Added translucent-white overlay tokens to theme.dart
  - On-device fixes: Splash content centring, SegmentedToggle full 48 dp height, DropdownField 48 dp height, fixed bottom bars moved to `bottomNavigationBar` so snackbars float above them, slide 1 G1 chip clipping; dart format on Group A files
- **Files changed:**
  - `~` app/lib/config/constants.dart
  - `~` app/lib/config/theme.dart
  - `~` app/lib/screens/onboarding_screen.dart
  - `~` app/lib/screens/register_screen.dart
  - `~` app/lib/screens/splash_screen.dart
  - `~` app/lib/screens/agreement_screen.dart
  - `~` app/lib/screens/login_screen.dart
  - `~` app/lib/widgets/ (app_buttons, app_checkbox, app_snack_bar, dropdown_field, gem_app_bar, image_picker_field, input_field, password_field, policy_markdown, segmented_toggle)
- **Connected edits:** EDIT-042 to EDIT-046; Claude Design Group A export (design/exports/groupA/Onboarding.dc.html)
- **Reason:** Apply the approved Onboarding design and fix visual defects seen on a real Android device.

### EDIT-048 | 01 October 2026 22:18 | IST
- **Topic:** Auth Flow Fixes
- **Summary:** Made logout reliable through one shared helper, made the Privacy Agreement a one-time step per device, showed Onboarding after every successful sign-in, and routed new Google users to profile completion.
- **What was done:**
  - Added `AppRoutes.navigatorKey` and set it on MaterialApp
  - Added `AuthService.endSession()`: closes open dialogs/sheets, runs an optional pre-step, awaits `signOut()`, then `pushAndRemoveUntil(LoginScreen, (_) => false)`; a static guard ignores a second call while one is running
  - Side drawer Logout, new Settings "Log out" tile and Settings Delete Account all use `endSession()`
  - Agreement stores `policy_accepted` in SharedPreferences on Accept & Continue; Splash routes logged in → MainShell, not logged in + accepted → LoginScreen, otherwise → AgreementScreen
  - Email login, Google login (existing users), email registration and Google profile completion now always open OnboardingScreen, then MainShell; removed the `onboarding_done` flag
  - Login with Google: new users go to `RegisterScreen(completeGoogleProfile: true)`
  - Added "View app introduction" to Settings (new Help section) and the side drawer; opens `OnboardingScreen(replay: true)`, where Skip / Get Started just pop back
  - AndroidManifest: `android:enableOnBackInvokedCallback="true"` on `<application>`
- **Files changed:**
  - `~` app/android/app/src/main/AndroidManifest.xml
  - `~` app/lib/config/constants.dart
  - `~` app/lib/config/routes.dart
  - `~` app/lib/main.dart
  - `~` app/lib/services/auth_service.dart
  - `~` app/lib/screens/agreement_screen.dart
  - `~` app/lib/screens/login_screen.dart
  - `~` app/lib/screens/onboarding_screen.dart
  - `~` app/lib/screens/register_screen.dart
  - `~` app/lib/screens/settings_screen.dart
  - `~` app/lib/screens/splash_screen.dart
  - `~` app/lib/widgets/side_drawer.dart
- **Connected edits:** EDIT-044 (Agreement), EDIT-045 (Login), EDIT-046 (Register), EDIT-047 (Onboarding); Claude Design Group A export (design/exports/groupA)
- **Reason:** Logout ran twice and could leave stale screens, the policy was shown on every launch, and new Google users from Login skipped profile completion.

### EDIT-049 | 01 October 2026 23:26 | IST
- **Topic:** UI Redesign B1 — Status Bar Contrast
- **Summary:** Made status bar icons readable on every screen. The global default is now dark icons on a transparent bar; screens with a dark top set light icons.
- **What was done:**
  - main.dart: global `SystemUiOverlayStyle` → `AppSystemUi.darkIcons`
  - Home and Processing (white tops, no app bar): `AnnotatedRegion(AppSystemUi.darkIcons)`
  - Guide (dark gradient header under the status bar): `AnnotatedRegion(AppSystemUi.lightIcons)` so MainShell tab switching stays legible
  - Splash, Login and Onboarding already set dark icons; primary app bars keep light icons through the app bar theme
- **Files changed:**
  - `~` app/lib/main.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/processing_screen.dart
  - `~` app/lib/screens/guide_screen.dart
- **Connected edits:** EDIT-042 (AppSystemUi tokens); Claude Design Group B export (design/exports/groupB)
- **Reason:** White-top screens showed white status bar icons on a white background.

### EDIT-050 | 01 October 2026 23:28 | IST
- **Topic:** UI Redesign B2 — NotificationService
- **Summary:** Added a local in-app notification store with a live unread count, and wired the first real events.
- **What was done:**
  - `AppNotification` model: id, type (success/warning/error/info), title, message, createdAt, read, action (none/openResult/openCalibration/openCapture/openHistory/openPrivacy), payload
  - `NotificationService`: JSON in SharedPreferences, newest first, max 100; `add`, `markRead`, `markAllRead`, `delete`, `clearAll`, `list`, `ValueNotifier<int> unreadCount`; loaded at startup in main.dart
  - Events: result saved with confidence < 60 → warning "Stone referred" (openResult with stone ID); certificate PDF saved → success "Certificate saved" (openHistory); password changed → info; email change requested → info
  - TODO hooks: `TODO(C4)` calibration over 8 h, `TODO(backend)` grading failed (openCapture), `TODO` privacy policy updated
- **Files changed:**
  - `+` app/lib/models/app_notification.dart
  - `+` app/lib/services/notification_service.dart
  - `~` app/lib/main.dart
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/certificate_screen.dart
  - `~` app/lib/screens/settings_screen.dart
- **Connected edits:** Claude Design Group B export (design/exports/groupB/Notifications.dc.html)
- **Reason:** The Home bell and Notifications screen need real, persisted notifications.

### EDIT-051 | 01 October 2026 23:30 | IST
- **Topic:** UI Redesign B3 — Group B Widgets
- **Summary:** Created the reusable widgets used by Home, the Side Drawer and Notifications.
- **What was done:**
  - NotificationBell (40 px round button, red badge, "9+" above 9, hidden at 0, listens to unreadCount)
  - NotificationTile (tinted type icon, title, one-line message, relative time, unread surface background + blue dot, swipe-left Dismissible delete)
  - StatCard, StatusBanner (success/warning/error), GradeSwatch, ConfidenceBadge (High ≥ 60, Borderline 40–59, Low < 40), EmptyState (dashed border), RecentGradeTile (with "Referred" chip), QuickGradeCard (gradient, white icon frame with sapphire Lottie, logo fallback)
  - `formatRelativeTime` / `isSameDay` helpers
- **Files changed:**
  - `+` app/lib/widgets/notification_bell.dart
  - `+` app/lib/widgets/notification_tile.dart
  - `+` app/lib/widgets/stat_card.dart
  - `+` app/lib/widgets/status_banner.dart
  - `+` app/lib/widgets/grade_swatch.dart
  - `+` app/lib/widgets/confidence_badge.dart
  - `+` app/lib/widgets/empty_state.dart
  - `+` app/lib/widgets/recent_grade_tile.dart
  - `+` app/lib/widgets/quick_grade_card.dart
  - `+` app/lib/widgets/relative_time.dart
- **Connected edits:** EDIT-042 (tokens), EDIT-050 (notification model); Claude Design Group B export (design/exports/groupB)
- **Reason:** Group B screens share these components; building them once keeps the screens consistent.

### EDIT-052 | 01 October 2026 23:32 | IST
- **Topic:** UI Redesign B4 — Home Dashboard
- **Summary:** Rebuilt Home per the design using real data from StorageService and NotificationService.
- **What was done:**
  - Header: time-of-day greeting + first name, NotificationBell, avatar (photo or initials) opening the right-side drawer
  - Calibration StatusBanner: red "Not calibrated. Calibrate before grading." → CalibrationScreen (`TODO(C4)` drive from saved calibration)
  - QuickGradeCard "Grade a Stone" → CaptureScreen (replaces the empty onTap TODO; `TODO(B9)` route to Calibration when not calibrated)
  - Stats for today: count, average confidence ("—" if none), referred (< 60)
  - Recent Grades: last 5 RecentGradeTiles → ResultScreen; "See all" → History tab; EmptyState with "Grade a stone"
  - Refresh on pull, on switching back to the Home tab, and when any route above MainShell pops (`AppRoutes.routeObserver`)
  - CLAUDE.md: added the QuickGradeCard gradient (`#1B3A8C` → `#3B5FD9`) as an exception to rule 12
- **Files changed:**
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/main_shell.dart
  - `~` app/lib/config/routes.dart
  - `~` app/lib/main.dart
  - `~` CLAUDE.md
- **Connected edits:** EDIT-049, EDIT-050, EDIT-051; Claude Design Group B export (design/exports/groupB/Home Dashboard.dc.html)
- **Reason:** Home showed placeholder stats and a Grade a Stone card that did nothing.

### EDIT-053 | 01 October 2026 23:33 | IST
- **Topic:** UI Redesign B5 — Side Drawer
- **Summary:** Rebuilt the right-side drawer per the design with current-page highlighting and the shared logout helper.
- **What was done:**
  - Royal Blue header: logo.png, "GemEye", close button, avatar, name, email (tap → Profile); role/company line left as `TODO(F2)`
  - Items: Home, Grade a Stone, Calibration (new), Grading History, Colour Grade Guide, Stone Comparison, Settings, divider, Feedback, Privacy Policy, About, View app introduction; current MainShell tab highlighted
  - Footer: red Logout (confirm dialog → `AuthService.endSession()`) and "App v1.0"; server status left as TODO
  - Light status bar icons while the drawer is open
- **Files changed:**
  - `~` app/lib/widgets/side_drawer.dart
  - `~` app/lib/screens/main_shell.dart
- **Connected edits:** EDIT-048 (logout helper, View app introduction), EDIT-052; Claude Design Group B export (design/exports/groupB/Side Drawer.dc.html)
- **Reason:** Apply the approved drawer design and add the missing Calibration entry.

### EDIT-054 | 01 October 2026 23:34 | IST
- **Topic:** UI Redesign B6 — Notifications Screen
- **Summary:** Added the Notifications centre per the design, opened from the Home bell.
- **What was done:**
  - Surface GemAppBar "Notifications" with back and "Mark all as read" (disabled when nothing is unread)
  - "TODAY" / "EARLIER" sections of NotificationTiles; tap marks read and runs the action (openResult → ResultScreen for the stone ID, openCalibration, openCapture, openHistory → History tab, openPrivacy); swipe left deletes
  - EmptyState "You're all caught up"
  - Built and installed the debug APK on the OnePlus Nord 2; Home checked on device
- **Files changed:**
  - `+` app/lib/screens/notifications_screen.dart
  - `~` app/lib/screens/main_shell.dart
- **Connected edits:** EDIT-050, EDIT-051, EDIT-052; Claude Design Group B export (design/exports/groupB/Notifications.dc.html)
- **Reason:** Users need one place to see referrals, certificate saves and account updates.

### EDIT-055 | 01 October 2026 23:52 | IST
- **Topic:** Mandatory Edit History Rule
- **Summary:** Added a permanent CLAUDE.md rule that every code or asset change must get a PROJECT_STATUS.md entry, committed together with the change.
- **What was done:**
  - Added the "Edit history (mandatory)" section to CLAUDE.md after the mandatory rules
- **Files changed:**
  - `~` CLAUDE.md
- **Connected edits:** CLAUDE.md Rule 1 (always update PROJECT_STATUS.md); Claude Design Group B export (design/exports/groupB)
- **Reason:** Make sure small fixes are logged too, not only larger features.

### EDIT-056 | 01 October 2026 23:55 | IST
- **Topic:** Side Drawer Logo Visibility
- **Summary:** The dark-blue logo was hard to see on the Royal Blue drawer header; it now sits in a white rounded frame.
- **What was done:**
  - logo.png placed in a 40×40 white frame (radius AppRadius.md, padding 4, subtle shadow), logo 32×32 BoxFit.contain
  - "GemEye" text kept beside it, vertically centred
  - Corrected EDIT-055 "Connected edits" to reference CLAUDE.md Rule 1
- **Files changed:**
  - `~` app/lib/widgets/side_drawer.dart
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-053 (Side Drawer redesign); Claude Design Group B export (design/exports/groupB/Side Drawer.dc.html)
- **Reason:** Logo contrast on the primary-coloured header.

### EDIT-057 | 01 October 2026 23:58 | IST
- **Topic:** Side Drawer Back Navigation
- **Summary:** Screens opened from the drawer now return to the open drawer on back; tab items close the drawer and switch tab; back with the drawer open closes it instead of showing the exit dialog.
- **What was done:**
  - Calibration, Stone Comparison, Settings, Privacy Policy, About, View app introduction and the profile header push their screen without closing the drawer
  - Feedback bottom sheet opens over the open drawer; dismissing it leaves the drawer open
  - Grade a Stone, Grading History and Colour Grade Guide close the drawer, then go through MainShell's `_onNavTap` (Grade opens Capture, same as the bottom nav)
  - Home item just closes the drawer; Logout unchanged (`AuthService.endSession()`)
  - MainShell: added a Scaffold key; the PopScope back handler closes an open end-drawer first, then returns non-Home tabs to Home, then shows the exit dialog
  - Tested on the OnePlus Nord 2: Settings → back → drawer → back → Home; History → back → Home tab; Feedback → dismiss → drawer still open
- **Files changed:**
  - `~` app/lib/widgets/side_drawer.dart
  - `~` app/lib/screens/main_shell.dart
- **Connected edits:** EDIT-053 (Side Drawer redesign), EDIT-056 (drawer logo); Claude Design Group B export (design/exports/groupB/Side Drawer.dc.html)
- **Reason:** Back from a drawer screen used to land on Home with the drawer closed, and back with the drawer open showed the exit dialog.

### EDIT-058 | 02 October 2026 05:46 | IST
- **Topic:** Side Drawer Circular Logo Frame
- **Summary:** Changed the white logo frame in the drawer header from a rounded square to a circle.
- **What was done:**
  - Frame: 40×40 white `BoxShape.circle`, same subtle shadow, padding 4
  - Logo clipped with `ClipOval`, 32×32, BoxFit.contain so it never touches the edge
  - Checked on the OnePlus Nord 2
- **Files changed:**
  - `~` app/lib/widgets/side_drawer.dart
- **Connected edits:** EDIT-056 (white logo frame), EDIT-053 (Side Drawer redesign); Claude Design Group B export (design/exports/groupB/Side Drawer.dc.html)
- **Reason:** A circular frame matches the round logo better than a rounded square.

### EDIT-059 | 02 October 2026 07:45 | IST
- **Topic:** No Em/En Dash in User-Visible Text
- **Summary:** Added a CLAUDE.md rule banning the em dash and en dash in user-visible text and replaced the existing ones with a hyphen.
- **What was done:**
  - CLAUDE.md "Things to never do" item 16: use a hyphen (-) instead of the em/en dash in user-visible text
  - Replaced the dashes in 7 user-visible strings (crop fallback snackbar, Home average placeholder, onboarding slide text and sample grade, result save snackbar, share text, grade title)
  - Code comments left unchanged; no dashes found in assets/data/
- **Files changed:**
  - `~` CLAUDE.md
  - `~` app/lib/screens/capture_screen.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/onboarding_screen.dart
  - `~` app/lib/screens/result_screen.dart
- **Connected edits:** EDIT-055 (edit history rule); Group C task brief
- **Reason:** Consistent typography in the UI; the hyphen is the agreed separator.

### EDIT-060 | 02 October 2026 08:05 | IST
- **Topic:** Calibration Service (6-patch CCM)
- **Summary:** Added the real colour calibration engine: patch measurement, least-squares 3x3 colour correction matrix, quality verdict and session storage.
- **What was done:**
  - Added `image` (pure Dart decoding) and `device_info_plus` packages
  - Reference patches in training order: White, Black, 18% Grey (117), 50% Grey (186), Blue (0,63,135), Red (175,54,60)
  - `measurePatch(File)`: decode + EXIF orientation, central 50% region, mean RGB and per-channel std dev, run in an isolate via `compute()`; uniform when every std dev <= `kPatchMaxStd` (0.06 x 255, to be tuned)
  - `computeCcm`: normalised 0-1, normal equations M = (CᵀC)⁻¹CᵀR (same as numpy lstsq, no offset), RMS residual and per-patch Euclidean error
  - Quality: Excellent <= 0.30, Acceptable <= 0.45, Poor above (provisional; training residual 0.2548)
  - `CalibrationSession` (id S-YYYY-MM-DD-NN, 8 h validity, device model, ccm, residual, quality, measured, per-patch error) stored as JSON in flutter_secure_storage: current + history (max 50), live `ValueNotifier`
  - `applyCcm(r,g,b)` helper for grading; `remindIfExpired()` for the recalibrate notification
  - Unit tests: identity case (residual 0), uniform gain recovery, quality thresholds
- **Files changed:**
  - `+` app/lib/services/calibration_service.dart
  - `+` app/test/calibration_service_test.dart
  - `~` app/pubspec.yaml
  - `~` app/pubspec.lock
- **Connected edits:** EDIT-059; Claude Design Group C export (design/exports/groupCD)
- **Reason:** Grading must run on colour-corrected photos using the same CCM as the training pipeline.

### EDIT-061 | 02 October 2026 08:30 | IST
- **Topic:** Calibration Flow Screens
- **Summary:** Replaced the placeholder 3-step calibration wizard with the Group C flow: Start, Patch Capture (x6), Result and the History bottom sheet.
- **What was done:**
  - Calibration Start: intro card, "Before you start" checklist, 6 patches in order (swatch, number, hex), 8 h note, "Start Calibration"; history icon in the app bar opens the History sheet
  - Patch Capture: StepProgress over the 6 patches, reference swatch + instruction, phone guide illustration (dashed centre 50%, corner brackets), "Take Photo" (camera) and "Import from Gallery (Pro mode)"
  - After capture: photo thumbnail with the measured square, reference vs measured swatches, "Measured RGB r, g, b" in JetBrains Mono, Retake / Next patch (Finish on patch 6)
  - Non-uniform patch: error state, AppSnackBar "Patch not uniform - shadow or edge detected. Retake." with Retake action, Next disabled
  - Back with progress: AppDialog "Cancel calibration? Progress will be lost."
  - Result: residual + verdict chip + note, 6 tiles (reference vs corrected = measured · M, per-patch error), device / session / valid until; Excellent/Acceptable save and open Capture with "Calibrated - residual 0.xx"; Poor disables save (Recalibrate only)
  - History sheet: newest first, "Current" tag on the valid session, expired sessions muted, EmptyState with "Start Calibration"
  - New reusable widgets: AppDialog, StepProgress, SecondaryButton, QualityChip
- **Files changed:**
  - `~` app/lib/screens/calibration_screen.dart
  - `+` app/lib/screens/calibration_patch_screen.dart
  - `+` app/lib/screens/calibration_result_screen.dart
  - `+` app/lib/widgets/calibration_history_sheet.dart
  - `+` app/lib/widgets/app_dialog.dart
  - `+` app/lib/widgets/step_progress.dart
  - `~` app/lib/widgets/app_buttons.dart
  - `~` app/macos/Flutter/GeneratedPluginRegistrant.swift
- **Connected edits:** EDIT-060 (calibration service); Claude Design Group C export (design/exports/groupCD/Calibration Start, Patch Capture, Result, History)
- **Reason:** Real 6-patch calibration replaces the mock CCC-card wizard.

### EDIT-062 | 02 October 2026 08:55 | IST
- **Topic:** Calibration State Wired Through the App
- **Summary:** Home banner, grade entry points, Settings and notifications now use the saved calibration session (resolves C4, C6, B9).
- **What was done:**
  - Home StatusBanner listens to `CalibrationService.session`: green "Calibrated · <device> · Session N · today HH:mm", amber "Calibration is over 8 hours old. Recalibrate for best accuracy.", red when none; removed TODO(C4)
  - Home QuickGradeCard, empty-state action, bottom-nav Grade tab and drawer "Grade a Stone" go through `CalibrationScreen.openGrading`: Capture when the calibration is valid, otherwise Calibration Start with an info snackbar; removed TODO(B9)
  - Calibration session loaded at app start (`main.dart`); Home load sends one "Recalibrate - Your calibration is over 8 hours old." warning notification per expired session (action openCalibration); removed the TODO(C4) note in NotificationService
  - Settings: calibration status from the saved session; Calibration History opens the shared History sheet
  - Debug APK built and installed on the OnePlus Nord 2 (installed from a copy outside OneDrive; the in-place install failed with a signature digest error)
  - Note: test/widget_test.dart was already failing before this task (Firebase not initialised in tests); calibration unit tests pass
- **Files changed:**
  - `~` app/lib/main.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/main_shell.dart
  - `~` app/lib/screens/settings_screen.dart
  - `~` app/lib/services/notification_service.dart
- **Connected edits:** EDIT-060 (calibration service), EDIT-061 (calibration screens); Claude Design Group C export (design/exports/groupCD)
- **Reason:** Grading must not start without a valid calibration, and users need to see calibration status at a glance.

### EDIT-063 | 02 October 2026 10:15 | IST
- **Topic:** Grade Capture Redesign
- **Summary:** Rebuilt Capture per the Group D design with calibration gating, the Pro mode guide, a 4-item checklist and the Repeatability toggle; the image_cropper step is unchanged.
- **What was done:**
  - App bar chip "Calibrated" (green) / "Not calibrated" (red, opens Calibration Start); red StatusBanner when not calibrated (live from `CalibrationService.session`)
  - "Recommended (most accurate)" card with "How to set up Pro mode" (new Pro Mode Guide bottom sheet, 5 steps, "Got it") and "Import from Gallery"; "Quick capture" card with "Take Photo" and "Less colour-consistent"
  - Framing card (dashed circle), "Before you capture" checklist (4 AppCheckbox items, "n of 4"); both capture buttons disabled until calibrated and all 4 ticked, with "Tick N more checks below to capture"
  - ToggleRow "Repeatability mode"
  - Picker + cropper moved to `StoneCaptureService` with identical crop/rotate/zoom settings (colours from AppColors); friendly snackbars replace raw error text
  - Capture is now a named route (`CaptureScreen.route()`, `popTo`); Calibration Start opened from Capture returns to it (`popOnSave`)
  - New widgets: ToggleRow, DashedBorderPainter, ProModeGuideSheet
- **Files changed:**
  - `~` app/lib/screens/capture_screen.dart
  - `~` app/lib/screens/calibration_screen.dart
  - `~` app/lib/screens/notifications_screen.dart
  - `+` app/lib/services/stone_capture_service.dart
  - `+` app/lib/widgets/toggle_row.dart
  - `+` app/lib/widgets/dashed_border.dart
  - `+` app/lib/widgets/pro_mode_guide_sheet.dart
- **Connected edits:** EDIT-060, EDIT-061, EDIT-062; Claude Design Group D export (Grade Capture, Pro Mode Guide)
- **Reason:** Grading must only start from a calibrated session with the capture setup confirmed.

### EDIT-064 | 02 October 2026 10:22 | IST
- **Topic:** Photo Check Screen
- **Summary:** New screen after the cropper that blocks grading on a blurry photo, a missing stone or a missing/expired calibration.
- **What was done:**
  - `PhotoCheckService` (isolate via `compute()`): downscale to 512 px, Laplacian variance of the central 50% (grayscale), blurry below `kMinBlurVariance` = 50 (TODO calibrate on dataset); stone in frame when the non-near-white share (all channels >= 200) of the central 70% is between 5% and 95%
  - Preview card + 3 check rows (pending / pass / fail); blurry shows "Refocus and recapture" and AppSnackBar "Image is blurry - please recapture" with Retake; stone fail "Stone not found - recentre"; calibration row shows the session ID or fails when none/expired
  - "Grade This Stone" enabled only when all checks pass, "Retake" returns to Capture
- **Files changed:**
  - `+` app/lib/screens/photo_check_screen.dart
  - `+` app/lib/services/photo_check_service.dart
- **Connected edits:** EDIT-063; Claude Design Group D export (Photo Check)
- **Reason:** Catch unusable photos on the device before they reach the grading server.

### EDIT-065 | 02 October 2026 10:30 | IST
- **Topic:** Processing Screen Redesign and Grading Errors
- **Summary:** Processing now shows the sapphire Lottie in a white circle, a vertical 6-step progress and AppDialogs for connection, timeout and generic errors.
- **What was done:**
  - White 80 px circle frame with subtle shadow around `sapphire_rotate.json` (errorBuilder → logo.png), title "Grading your stone", "Usually 2-5 seconds"
  - New `VerticalStepProgress` widget with the 6 design steps; demo timing kept (400 ms per step + 500 ms)
  - `GradingService.grade()` returns the existing demo result (TODO(backend) HTTP call); exceptions `GradingNoConnectionException`, `GradingTimeoutException`, `GradingRejectedException(RejectionReason)`, `GradingException`
  - Dialogs: "No connection" (Cancel / Retry), "Server is taking too long" (Retry), "Something went wrong" (OK); `AppDialog.alert()` and a custom `icon` added to AppDialog
  - Success opens Grade Result (or Repeatability Summary); rejection opens Not Accepted; Photo Check and Processing are removed from the stack; stone ID kept across retries
- **Files changed:**
  - `~` app/lib/screens/processing_screen.dart
  - `~` app/lib/widgets/step_progress.dart
  - `~` app/lib/widgets/app_dialog.dart
  - `+` app/lib/services/grading_service.dart
- **Connected edits:** EDIT-064; Claude Design Group D export (Processing)
- **Reason:** Clear progress and recoverable error states for the upcoming grading backend.

### EDIT-066 | 02 October 2026 10:36 | IST
- **Topic:** Not Accepted Screen
- **Summary:** New result template for rejected photos with the no_stone, not_blue and not_recognised variants.
- **What was done:**
  - Warning icon, title and explanation per variant; "Your photo" card with the real photo and session ID; not_blue shows a measured hue swatch and value when the server sends it
  - "Why was this rejected?" AppDialog explaining the 3 checks; "Retake" back to Capture; footer disclaimer
  - Reachable via `RejectionReason` / `RejectionReason.fromStatus()`; TODO(backend) to route from the server response
- **Files changed:**
  - `+` app/lib/screens/not_accepted_screen.dart
- **Connected edits:** EDIT-065; Claude Design Group D export (Not Accepted)
- **Reason:** Rejected photos must explain why no grade was given.

### EDIT-067 | 02 October 2026 10:44 | IST
- **Topic:** Grade Result Redesign
- **Summary:** Result screen follows the Group D layout while keeping the existing Colour values and Grad-CAM sections unchanged.
- **What was done:**
  - App bar "Colour Grading Report" with share; borderline banner (confidence < 60) "Borderline - gemologist review recommended" (second grade named only when probabilities exist)
  - Stone photo card with a measured-colour chip (sRGB from the stored CIELAB values)
  - New GradeBadgeCard (gradient), UncertaintyPill and on-dark ConfidenceBadge
  - New ProbabilityBarCard, hidden until GradeResult carries probabilities (TODO(backend))
  - Colour values and Grad-CAM heatmap kept exactly, Grad-CAM directly after colour values; TODO(backend) for CIECAM02 tiles
  - Buttons: "Save & Grade Next" / "Export Certificate", or "Save as Referred" / "Retake" when borderline; footer with stone, session and date (model version TODO(backend))
  - Save/export logic moved to `GradeRecordService` (same behaviour, certificate number reused on re-export); `GradeResult.withStoneId`, `measuredRgb`, `measuredHex` helpers
- **Files changed:**
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/models/grade_result.dart
  - `~` app/lib/widgets/confidence_badge.dart
  - `+` app/lib/services/grade_record_service.dart
  - `+` app/lib/widgets/grade_badge_card.dart
  - `+` app/lib/widgets/probability_bar.dart
- **Connected edits:** EDIT-065; Claude Design Group D export (Grade Result)
- **Reason:** Result screen must match the approved design and flag borderline stones for review.

### EDIT-068 | 02 October 2026 10:51 | IST
- **Topic:** Repeatability Mode
- **Summary:** With the toggle on, the stone is captured 3 times (each through crop and Photo Check) and graded into a summary.
- **What was done:**
  - Repeatability capture screen for captures 2 and 3: progress dots, "Capture n of 3", thumbnails (done / now / pending), "Lift and replace the stone" card, Import from Gallery / Take Photo
  - Photo Check labels the intermediate button "Use This Photo" and "Grade This Stone" on capture 3
  - Summary: inconsistent banner, 3 capture tiles (odd one amber), Agreement n/3, ΔE₀₀ row ("-", TODO(backend)), final grade card with "Agreed / Majority n of 3" and confidence; buttons "Save & Grade Next" / "Export Certificate" or "Save as Referred" / "Retake all 3"
  - Final grade = majority (TODO(backend) from server); with demo data all captures agree, so only the UI is shown
  - Debug APK built and installed on the OnePlus Nord 2 (copy re-signed outside OneDrive, same digest issue as EDIT-062)
- **Files changed:**
  - `+` app/lib/screens/repeatability_capture_screen.dart
  - `+` app/lib/screens/repeatability_summary_screen.dart
- **Connected edits:** EDIT-063, EDIT-064, EDIT-065, EDIT-067; Claude Design Group D export (Repeatability Mode)
- **Reason:** Repeat captures show whether a grade is stable before it is saved.

### EDIT-069 | 02 October 2026 13:00 | IST
- **Topic:** CIEDE2000 Colour Difference
- **Summary:** Added a standard CIEDE2000 (ΔE₀₀) implementation with unit tests against published reference pairs.
- **What was done:**
  - `ColourMath.deltaE2000(Lab, Lab)` with kL = kC = kH = 1 (Sharma, Wu and Dalal 2005), `Lab` value class, shared label "Delta E (ΔE₀₀)"
  - Unit test with Sharma et al. (2005) pairs 1 (2.0425) and 17 (27.1492), plus identical colours = 0; all pass
- **Files changed:**
  - `+` app/lib/utils/colour_math.dart
  - `+` app/test/colour_math_test.dart
- **Connected edits:** EDIT-067
- **Reason:** Stone Comparison and the certificate need a standard perceptual colour difference.

### EDIT-070 | 02 October 2026 13:05 | IST
- **Topic:** Certificate PDF Redesign
- **Summary:** Certificate PDF follows the Group E design with embedded app fonts and theme colours.
- **What was done:**
  - Royal Blue header with logo.png on a white rounded frame, "Colour Grading Certificate", certificate number
  - Stone photo card + gradient grade block (Grade N, GEMCLOUD name, trade name, grade swatch + hex, confidence and uncertainty pills)
  - Colour data in 3 columns: CIELAB, HSB, CIECAM02 ("-", TODO(backend)); Delta E (ΔE₀₀) to typical grade and measured hex below
  - Details grid: stone ID, capture date/time, session, device + calibration residual (from CalibrationService history when the session matches, else "-"), model version ("-", TODO(backend)), issued to (display name), company (only when set in Profile)
  - QR content unchanged, caption "Scan to view certificate data" (TODO(backend) verification URL); statement, disclaimer, footer
  - Amber "Borderline - reviewed by gemologist: ______" block when confidence is below the referral threshold
  - Numbering, prefix setting and Downloads saving unchanged; Grad-CAM panel removed from the PDF (not in the design; still on Grade Result)
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart
- **Connected edits:** EDIT-067, EDIT-069; Claude Design Group EF export (Certificate PDF)
- **Reason:** The exported certificate must match the approved design.

### EDIT-071 | 02 October 2026 13:09 | IST
- **Topic:** Certificate Preview Redesign
- **Summary:** Certificate screen shows the file name, a scaled A4 page with pinch to zoom, and Save to Downloads / Share / Print.
- **What was done:**
  - GemAppBar "Certificate"; header row with the PDF file name (mono) and "A4 · 1 page"
  - Page rasterised once with `Printing.raster` and shown in an InteractiveViewer (1x to 5x) inside a bordered A4 frame; PdfPreview fallback
  - Bottom bar: "Save to Downloads" (primary), "Share" (outlined), Print icon button (printing package)
  - Success snackbar "Saved to Downloads"; save notification, save path and share/print behaviour unchanged; errors via AppSnackBar
- **Files changed:**
  - `~` app/lib/screens/certificate_screen.dart
- **Connected edits:** EDIT-070; Claude Design Group EF export (Certificate Preview)
- **Reason:** The preview must match the approved design.

### EDIT-072 | 02 October 2026 13:09 | IST
- **Topic:** Grading History Redesign
- **Summary:** History follows the Group E design with all existing features kept and a separate sort sheet.
- **What was done:**
  - GemAppBar with menu (opens the shell drawer), sort and filter actions (red count badge)
  - Search, chips All / G1-G7 (grade swatches) / Referred (confidence below the referral threshold)
  - Count row ("N stones · All time" or date range) and current sort
  - Rows: grade swatch, stone ID, Referred pill, "Grade N · Name", confidence level + time, certificate pill
  - Swipe left to delete with AppDialog confirm; long press selection with checkboxes, "N selected", All / None, bottom bar Export Batch / Share / Delete
  - Filter sheet: date range, Confidence (All / High only / Borderline only), Certificate, Session dropdown, Reset, Cancel / "Show N stones" (live count)
  - Sort sheet grouped Date / Grade / Confidence with the selected option ticked
  - Two EmptyStates: "No stones graded yet" (Grade a stone) and "No matching stones" (Clear filters)
- **Files changed:**
  - `~` app/lib/screens/history_screen.dart
- **Connected edits:** EDIT-070; Claude Design Group EF export (Grading History)
- **Reason:** History must match the approved design and flag referred stones.

### EDIT-073 | 02 October 2026 13:14 | IST
- **Topic:** Stone Comparison Redesign
- **Summary:** Comparison follows the Group E design and uses CIEDE2000 instead of the old CIE76 distance.
- **What was done:**
  - Stone A / Stone B pickers with a swap button; history bottom sheet with search, the other stone disabled and tagged, current stone ticked
  - Photo cards with A/B tags, capture date and a grade chip (swatch, G code, GEMCLOUD name)
  - Result card: "ΔE₀₀ = x.x" from `ColourMath.deltaE2000`; < 2 green "Visually very similar", 2-5 amber "Noticeable difference", > 5 red "Clearly different"; grade difference
  - Table L*, a*, b*, C*, Hue (circular difference), Saturation, Brightness with coloured difference text only (green < 1, amber 1-3, red > 3); J and M rows TODO(backend)
  - "Compare another" reopens the Stone B picker; EmptyState until both stones are chosen
- **Files changed:**
  - `~` app/lib/screens/comparison_screen.dart
- **Connected edits:** EDIT-069; Claude Design Group EF export (Stone Comparison)
- **Reason:** Comparison must match the approved design and use a standard perceptual colour difference.

### EDIT-074 | 02 October 2026 13:14 | IST
- **Topic:** Colour Grade Guide Redesign
- **Summary:** Guide follows the Group E design with a 7-colour strip and expandable grade cards; grade data aligned with the GEMCLOUD standard.
- **What was done:**
  - GemAppBar with menu (opens the shell drawer); 7-segment strip (tap opens and scrolls to the card), "Darkest" / "Lightest"
  - Expandable cards (G3 open by default): swatch, "Grade N · Name", trade name, description, Tone and Saturation tiles, tip box; footer "Based on the GEMCLOUD 7-Grade Standard · GRS · Bellerophon. Works offline."
  - "Lightness L*" and "Chroma C*" tiles not shown (TODO(dataset): real per-grade median L* and C* from the training set)
  - colour_grades.json rewritten with the CLAUDE.md names, trade names and hex values plus the design copy (description, tone, saturation, tip); legacy colour ranges removed; swatches use AppColors.grades
- **Files changed:**
  - `~` app/lib/screens/guide_screen.dart
  - `~` app/assets/data/colour_grades.json
- **Connected edits:** Claude Design Group EF export (Colour Grade Guide)
- **Reason:** The guide must match the approved design and the 7 GEMCLOUD grades.
- **Notes:** flutter analyze: 0 errors (11 existing infos in settings_screen.dart); colour_math_test passes; widget_test.dart already failed before Group E. Debug APK built; not installed because the OnePlus Nord 2 was not connected (only an emulator was attached).

### EDIT-075 | 02 October 2026 16:05 | IST
- **Topic:** Status Text Tokens and System State Components
- **Summary:** Added darker status text tokens and aligned AppSnackBar, AppDialog, EmptyState and StatusBanner with the System States page.
- **What was done:**
  - `AppColors.successText` #059669, `warningText` #B45309, `errorText` #DC2626 for text and icons on light tints; `scrimBlocking` for blocking dialogs; main status colours unchanged
  - AppSnackBar: status icons use the text tokens, compact padding, 48 dp action
  - AppDialog: filled confirm button (Royal Blue, or #DC2626 for danger), text cancel, 296 dp width, new `blocking` option (darker scrim, no tap-outside or back dismiss)
  - EmptyState icon 32; StatusBanner gains an optional icon and text action; new `OfflineBanner` and `SkeletonBox` / `SkeletonRow`
- **Files changed:**
  - `~` app/lib/config/theme.dart
  - `~` app/lib/widgets/app_snack_bar.dart
  - `~` app/lib/widgets/app_dialog.dart
  - `~` app/lib/widgets/empty_state.dart
  - `~` app/lib/widgets/status_banner.dart
  - `+` app/lib/widgets/skeleton.dart
- **Connected edits:** EDIT-065; Claude Design Group EF export (System States)
- **Reason:** Status text on tints must pass contrast, and shared components must match the approved states.

### EDIT-076 | 02 October 2026 16:10 | IST
- **Topic:** Settings Redesign and Single Referral Threshold
- **Summary:** Settings follows the Group F design with every row wired, and the referral threshold is now one saved setting used everywhere.
- **What was done:**
  - New `SettingsService` (SharedPreferences, loaded at startup): referral threshold 40-90 (default 60), export format, certificate prefix, auto-save, 3 notification toggles
  - `ConfidenceBadge.referThreshold` now reads the setting, so Home "Referred", Result borderline, History chips (live), certificates, repeatability and referral notifications all follow it
  - CertificateService uses the saved prefix for new numbers; existing numbers unchanged
  - NotificationService skips categories switched off (calibration reminders, referral alerts, certificate updates)
  - Sections: Profile card, Calibration status (green / amber under 30 min / red) + Recalibrate + History sheet, Grading (slider, PDF / Image / Both, prefix dialog, auto-save TODO), Security (biometric first; Change Password hidden for Google-only accounts with a note), Notifications, Help (app introduction, Colour Grade Guide, feedback), Connection ("Server status: Not connected", TODO(backend) health check), Data, Account
  - Export all data: CSV of every stone saved to Downloads/GemEye and opened in the share sheet (fixes F7)
  - Clear history: danger dialog, deletes records and photos
  - Delete account: danger dialog, re-authenticate (password prompt or Google), delete the Firebase user, wipe all local data (history, photos, calibration, notifications, profile, prefs), Login; TODO(backend) server data
  - All use_build_context_synchronously infos fixed (analyzer now reports no issues)
  - GuideScreen gets a back-arrow mode for opening from Settings
- **Files changed:**
  - `+` app/lib/services/settings_service.dart
  - `+` app/lib/services/account_service.dart
  - `~` app/lib/screens/settings_screen.dart
  - `~` app/lib/screens/guide_screen.dart
  - `~` app/lib/widgets/confidence_badge.dart
  - `~` app/lib/services/notification_service.dart
  - `~` app/lib/services/calibration_service.dart
  - `~` app/lib/services/grade_record_service.dart
  - `~` app/lib/services/certificate_service.dart
  - `~` app/lib/services/storage_service.dart
  - `~` app/lib/screens/certificate_screen.dart
  - `~` app/lib/screens/history_screen.dart
  - `~` app/lib/main.dart
- **Connected edits:** EDIT-062, EDIT-067, EDIT-070, EDIT-072; Claude Design Group EF export (Settings)
- **Reason:** Settings must work end to end, and one threshold must decide what is referred.

### EDIT-077 | 02 October 2026 16:12 | IST
- **Topic:** Profile Redesign and Local Profile Store
- **Summary:** Profile follows the Group F design with real stats; profile details are kept on the device in secure storage.
- **What was done:**
  - New `ProfileService` (flutter_secure_storage): account type, phone, role, country, company name, contact person, industry, photo and logo paths; migrates the old SharedPreferences keys
  - Registration now saves these details locally (TODO(F2) backend sync; business reg. no and address still not stored)
  - Profile: 96 dp avatar (photo, Google photo or initials; tap to pick), name, type pill, stats Total graded / Referred / Certificates from StorageService
  - Individual: full name, email locked + Change, phone, role, country; Company: logo (ImagePickerField), company name, contact person, email, phone, industry, country
  - "Save changes" enabled only after an edit; "Profile saved" snackbar; certificates read the company name from the profile
  - `ImagePickerField.pickImage` made reusable
- **Files changed:**
  - `+` app/lib/services/profile_service.dart
  - `~` app/lib/screens/profile_screen.dart
  - `~` app/lib/screens/register_screen.dart
  - `~` app/lib/widgets/image_picker_field.dart
  - `~` app/lib/services/certificate_service.dart
- **Connected edits:** EDIT-076; Claude Design Group EF export (Profile)
- **Reason:** Profile must match the design and show real data without exposing personal data in plain prefs.

### EDIT-078 | 02 October 2026 16:15 | IST
- **Topic:** Security Flows and Blocking Dialogs
- **Summary:** Added the biometric check, Change Password and Change Email screens, and the Session expired and Privacy policy updated dialogs.
- **What was done:**
  - `BiometricSheet` (local_auth): fingerprint / face first, "Use PIN instead" uses the device credential; verified / not recognised states; devices without a screen lock pass through
  - MainActivity switched to FlutterFragmentActivity (required by local_auth); NSFaceIDUsageDescription added for iOS
  - Change Password: re-authenticate with the current password, 4-rule list, updatePassword, "Forgot current password?" reset link
  - Change Email: current email locked, verifyBeforeUpdateEmail, info text; both send an info notification on success
  - AuthService: hasPassword / isGoogleOnly, re-authentication helpers, blocking "Session expired" dialog then logout on user-token-expired / user-disabled (checked at startup and in auth calls)
  - Privacy policy version (`AppConstants.privacyPolicyVersion`); acceptance stores the version; a newer version shows the blocking dialog (Log out / Review) and the Privacy Agreement in re-accept mode
- **Files changed:**
  - `+` app/lib/widgets/biometric_sheet.dart
  - `+` app/lib/screens/change_password_screen.dart
  - `+` app/lib/screens/change_email_screen.dart
  - `+` app/lib/services/policy_service.dart
  - `~` app/lib/services/auth_service.dart
  - `~` app/lib/screens/agreement_screen.dart
  - `~` app/lib/screens/main_shell.dart
  - `~` app/lib/config/constants.dart
  - `~` app/android/app/src/main/kotlin/com/gemeye/gemeye/MainActivity.kt
  - `~` app/ios/Runner/Info.plist
- **Connected edits:** EDIT-075, EDIT-076; Claude Design Group EF export (Security Dialogs)
- **Reason:** Sensitive changes need a device check and re-authentication, and expired sessions or policy updates must block the app.

### EDIT-079 | 02 October 2026 16:18 | IST
- **Topic:** About and Feedback Redesign
- **Summary:** About and the Feedback sheet follow the Group F design; Privacy Policy keeps PolicyMarkdown.
- **What was done:**
  - About: logo on a white frame, GemEye, tagline, version pill; Developer card (assets/images/about/developer.jpg or "NK"), link buttons only for non-empty AppConstants links; Special thanks cards for NSBM Green University and Orava (Pvt) Ltd. (logos from assets/images/about/ when present, no team member placeholders); feedback and privacy rows; "Made in Sri Lanka · © 2026"
  - assets/images/about/ folder registered (empty until the photos and logos are added)
  - Feedback sheet: 5-star rating with label, category chips (Accuracy, App, Calibration, Other), comment with 500 limit and counter, Send enabled after rating; stored locally; success snackbar; TODO(backend) send; one `FeedbackSheet.show` used by the drawer, About and Settings
- **Files changed:**
  - `~` app/lib/screens/about_screen.dart
  - `~` app/lib/screens/feedback_sheet.dart
  - `~` app/lib/widgets/side_drawer.dart
  - `~` app/pubspec.yaml
  - `+` app/assets/images/about/.gitkeep
- **Connected edits:** EDIT-075; Claude Design Group EF export (About Privacy Feedback)
- **Reason:** About and Feedback must match the approved design without placeholder names.

### EDIT-080 | 02 October 2026 16:22 | IST
- **Topic:** Offline Banner and Loading Skeletons
- **Summary:** Home and Grade a Stone show an offline banner with Retry and disable capture while offline; Home and History show loading skeletons.
- **What was done:**
  - Added connectivity_plus; `ConnectivityService` keeps a live online flag (Retry re-checks)
  - "You're offline - grading needs a connection" banner on Home and Grade a Stone; QuickGradeCard and the Import / Take Photo buttons disabled while offline
  - Home and History skeletons in Primary Surface replace the content until data loads
  - flutter analyze: no issues; unit tests pass (widget_test.dart already failing before Group E); debug APK built, not installed because the OnePlus Nord 2 was not connected
- **Files changed:**
  - `+` app/lib/services/connectivity_service.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/capture_screen.dart
  - `~` app/lib/screens/history_screen.dart
  - `~` app/lib/widgets/quick_grade_card.dart
  - `~` app/lib/main.dart
  - `~` app/pubspec.yaml, app/pubspec.lock (+ generated plugin registrants)
- **Connected edits:** EDIT-075; Claude Design Group EF export (System States)
- **Reason:** Grading needs a connection, and loading should not show empty screens.
