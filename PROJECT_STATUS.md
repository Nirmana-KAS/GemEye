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
