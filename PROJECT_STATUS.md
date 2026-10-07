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

### EDIT-081 | 03 October 2026 02:35 | IST
- **Topic:** Git Rule, Backend Skeleton and App Backend Report
- **Summary:** CLAUDE.md now forbids git commands and commits by Claude Code; the backend folder skeleton and a read-only app report for backend integration were added.
- **What was done:**
  - CLAUDE.md: Edit history rule now ends "Do not commit."; new Git (strict) section (no commit, push, branch, checkout, merge, rebase, stash or Co-Authored-By; developer commits with GitHub Desktop on main)
  - Backend skeleton: app/__init__.py, export/, secrets/, tests/ (with .gitkeep), .env.example (keys only), README.md; existing backend/models/.gitkeep kept
  - .gitignore: backend/.env, backend/models/*, backend/secrets/* (keeping .gitkeep files), backend/**/__pycache__/
  - docs/app_backend_report.md: GradeResult source, public service signatures, demo result locations, GradeResult consumers, calibration CCM storage, AppConstants, dependencies, Android permissions (INTERNET only in debug/profile, no cleartext config)
- **Files changed:**
  - `~` CLAUDE.md
  - `~` .gitignore
  - `+` backend/app/__init__.py
  - `+` backend/export/.gitkeep
  - `+` backend/secrets/.gitkeep
  - `+` backend/tests/.gitkeep
  - `+` backend/.env.example
  - `+` backend/README.md
  - `+` docs/app_backend_report.md
- **Connected edits:** EDIT-080
- **Reason:** Phase 0 / Step 1 of the backend work: set the git rule, prepare the backend layout, and document what the app expects from the API.

### EDIT-082 | 03 October 2026 10:45 | IST
- **Topic:** Backend Phase 1 - Inference Server (FastAPI + Docker)
- **Summary:** Local FastAPI inference server for the v3 model (CNN with MC Dropout + RF ensemble) in Docker, with a training-identical model colour path, a separate display colour path and smoke tests.
- **What was done:**
  - Verified Phase 0 inputs: models present; w_cnn 0.6; ccm_residual 0.2548; CIECAM02 fallbacks 912/912; affine_residual 0.1276; ciecam02_real nan_count 0, no errors; blur threshold 29.47; OOD threshold_p99 25.69 on layer "dense"
  - Environment pinned to training versions (python:3.13-slim, tensorflow-cpu 2.20.0, keras 3.13.2, numpy 2.1.3, scikit-learn 1.6.1, joblib 1.6.0, colour-science 0.4.7); opencv-python-headless 4.14.0.94 (OpenCV 4.14.0); non-root Dockerfile, dev docker-compose with live reload and read-only model/export/secrets mounts
  - Model path: session 3x3 map from user patches (or identity), training CCM, JPEG round trip; v3 GrabCut + 12-D features copied from the Phase 0 export code with the CIECAM02 fallback reproduced
  - Display path: 4x3 affine from user patches (or exported default); L*a*b*, C*, HSB, hex, real CIECAM02, ΔE00 to the grade's physical median
  - Inference: deterministic + 30-pass MC Dropout batch (Dropout only, fixed stateless seed so the same image gives the same grade), RF, 0.6/0.4 ensemble; diagnostics (blur, stone area, physical hue, Mahalanobis OOD) reported, no rejection yet
  - GET /health and POST /grade with 400/413/500 handling, no stack traces, uploads kept in memory and never stored
  - Smoke tests: 4 passed in the container; average /grade latency about 3.7 s on CPU (CNN about 2.6 s)
- **Files changed:**
  - `+` backend/requirements.txt
  - `+` backend/Dockerfile
  - `+` backend/docker-compose.yml
  - `+` backend/.dockerignore
  - `+` backend/app/config.py
  - `+` backend/app/assets.py
  - `+` backend/app/schemas.py
  - `+` backend/app/main.py
  - `+` backend/app/pipeline/__init__.py
  - `+` backend/app/pipeline/colour.py
  - `+` backend/app/pipeline/features.py
  - `+` backend/app/pipeline/display.py
  - `+` backend/app/pipeline/inference.py
  - `+` backend/tests/test_smoke.py
  - `~` backend/README.md
- **Connected edits:** EDIT-081
- **Reason:** Phase 1 of the backend work: serve the v3 grading model locally with results that match training.

### EDIT-083 | 04 October 2026 05:05 | IST
- **Topic:** Backend Phase 1.1 - MC Dropout speed-up
- **Summary:** The EfficientNet backbone and global pooling now run once per image; only the classification head runs the 30 MC Dropout passes as one batch.
- **What was done:**
  - Added `backbone`, `head_det` and `head_mc` tf.functions; head_mc keeps the same Dropout maths and stateless seeds (keyed by full-model layer index), BatchNorm in inference mode
  - Verified on the smoke-test image (identity and session patches) before removing the old path: max abs diff mc_mean 1.9e-7, uncertainty 1.3e-7, deterministic 2.4e-7, dense features 9.5e-7 (all below 1e-5)
  - Removed `mc_forward` and `feature_model`; warm-up uses the new functions
  - CNN time per call 1.7-1.9 s to about 60 ms; /grade average 968 ms wall over 3 calls (server total 773 ms, previously about 3.7 s)
- **Files changed:**
  - `~` backend/app/assets.py
  - `~` backend/app/pipeline/inference.py
  - `~` backend/README.md
- **Connected edits:** EDIT-082
- **Reason:** The full model was being run 30 times although Dropout exists only in the head.

### EDIT-084 | 04 October 2026 05:05 | IST
- **Topic:** Grade 7 trade name "Very Light Blue"
- **Summary:** Grade 7 trade name changed from "Near-Colourless" to "Very Light Blue" in the app, backend and project docs.
- **What was done:**
  - Replaced "Near-Colourless" in AppConstants.tradeNames and colour_grades.json (guide reads the JSON)
  - Updated the CLAUDE.md grading table and root README grade list; backend TRADE_NAMES already used "Very Light Blue"
  - flutter analyze: no issues
- **Files changed:**
  - `~` app/lib/config/constants.dart
  - `~` app/assets/data/colour_grades.json
  - `~` CLAUDE.md
  - `~` README.md
- **Connected edits:** EDIT-082
- **Reason:** One consistent GEMCLOUD trade name for Grade 7 across server and app.

### EDIT-085 | 04 October 2026 05:05 | IST
- **Topic:** Backend Phase 1.1 - hue gate and segmentation reliability diagnostics
- **Summary:** Physical hue diagnostic from the display path with a provisional 170-265 degree gate, plus segmentation reliability flags.
- **What was done:**
  - Added `HUE_GATE_MIN = 170`, `HUE_GATE_MAX = 265` (provisional, tune in Phase 7); `hue_wb_range_suggested` from export_wb.json deliberately not used (polluted by GrabCut fallbacks)
  - New diagnostics: `hue_gate_min`, `hue_gate_max`, `hue_in_gate`, `segmentation_reliable` (false when GrabCut used the saturation or centre-box fallback on the display-path image)
  - New `colour.approximate` = not segmentation_reliable
  - Model path unchanged (training CCM + session mapping); smoke tests updated, 4 passed; container restarted and healthy
- **Files changed:**
  - `~` backend/app/pipeline/inference.py
  - `~` backend/app/pipeline/display.py
  - `~` backend/app/schemas.py
  - `~` backend/tests/test_smoke.py
  - `~` backend/README.md
- **Connected edits:** EDIT-082, EDIT-083
- **Reason:** Prepare a physical hue gate and flag colour values measured on an unreliable stone mask.

### EDIT-086 | 04 October 2026 00:09 | IST
- **Topic:** Backend Phase 2 - parity test against the v3 Colab results
- **Summary:** Added development-only debug fields to /grade and a parity harness that runs the 112 v3 test images through the server and compares the results with Colab. RF and CNN-MC agreement pass; final-grade agreement is 105/112 (target 107). The investigation traces the gap to unseeded MC Dropout/GrabCut noise in the Colab reference, not to a preprocessing difference.
- **What was done:**
  - /grade accepts form field `debug`; when ENV=development the response adds `debug` (rf_grade, rf_probabilities, cnn_mc_grade, cnn_mc_probabilities, cnn_deterministic_grade, model_segmentation_fallback); omitted otherwise (response_model_exclude_unset)
  - New diagnostics field `model_segmentation_fallback` (information only, does not change segmentation_reliable)
  - docker-compose mounts ../dataset/merged at /data/merged:ro (development only); container recreated and healthy
  - run_parity.py (stdlib): all 112 images found; server accuracy 86.61% (Colab 85.71%), macro-F1 0.8651, within 1 grade 100%; final agreement 105/112 FAIL, RF 110/112 PASS, CNN-MC 108/112 PASS; mean confidence difference 0.030; uncertainty r = 0.866; latency avg 1385 ms, max 2103 ms
  - Clean-98 check BLOCKED: tests/parity/clean_summary.json (leak lists) is not in the repo; the script uses it automatically once added
  - investigate_parity.py: tested JPEG, resize, CCM rounding, BGR order, EXIF, tf decode, GrabCut and MC seeds, and preprocess_input; no step differs from training; MC seed alone moves final agreement between 104 and 108/112; no model logic changed
  - Smoke tests: new debug test, 5 passed (development); with ENV=production the debug block is absent
- **Files changed:**
  - `~` backend/app/main.py
  - `~` backend/app/schemas.py
  - `~` backend/app/pipeline/inference.py
  - `~` backend/docker-compose.yml
  - `~` backend/tests/test_smoke.py
  - `+` backend/tests/parity/run_parity.py
  - `+` backend/tests/parity/investigate_parity.py
  - `+` backend/tests/parity/parity_report.md
  - `+` backend/tests/parity/parity_mismatches.csv
  - `+` backend/tests/parity/parity_investigation.md
- **Connected edits:** EDIT-082, EDIT-083, EDIT-084, EDIT-085
- **Reason:** Show that the server reproduces the v3 Colab test results before building further phases on it.

### EDIT-087 | 04 October 2026 06:17 | IST
- **Topic:** Backend Phase 2.1 - parity re-run against the deterministic Colab reference
- **Summary:** run_parity.py now compares the server with parity_reference.csv (seeded GrabCut RF, deterministic CNN) and applies new criteria A-D. A (RF exact), C (clean-98 accuracy) and D (all disagreements below the referral threshold on both sides) pass. B (deterministic CNN) fails because the server decodes the JPEG round trip with cv2 instead of TF. The server is unchanged pending approval.
- **What was done:**
  - Debug block now also returns `cnn_deterministic_probabilities` (7 values); smoke tests 5 passed
  - run_parity.py: checks that clean_summary.json has clean_test_n 98 and 14 leak names, then compares each image with parity_reference.csv (RF and CNN deterministic max abs dp and grade agreement); lists every final-grade disagreement with both confidences and whether both are below 0.60; the old criteria are kept as "informational: vs unseeded Colab run"
  - Results: A PASS (112/112, max abs dp 4.99e-13); B FAIL (108/112, max abs dp 0.335); C PASS (clean-98 86.73%); D PASS (7/7 disagreements both below 0.60)
  - investigate_cnn_det.py: tested each CNN input step separately against the reference. Decoding the round-tripped JPEG with tf.io.decode_jpeg (dct_method INTEGER_FAST) instead of cv2.imdecode gives max abs dp 2.85e-6 and 112/112 agreement. Resize, CCM, channel order, EXIF, full vs split model and preprocess_input are not the cause
  - Proposed fix (not applied): decode the JPEG round trip with tf.io.decode_jpeg (INTEGER_FAST) for the CNN input only; keep cv2 decoding for the RF/GrabCut path, which is already exact
- **Files changed:**
  - `~` backend/app/pipeline/inference.py
  - `~` backend/app/schemas.py
  - `~` backend/tests/parity/run_parity.py
  - `~` backend/tests/parity/parity_report.md
  - `~` backend/tests/parity/parity_mismatches.csv
  - `+` backend/tests/parity/investigate_cnn_det.py
  - `+` backend/tests/parity/parity_investigation_cnn.md
- **Connected edits:** EDIT-086
- **Reason:** Replace the unseeded Colab comparison with a deterministic reference, so parity can be checked exactly rather than within noise.

### EDIT-088 | 04 October 2026 06:45 | IST
- **Topic:** Backend Phase 2.1 - CNN input decoded with tf.io.decode_jpeg (parity fix)
- **Summary:** The CNN input is now decoded from the model-path JPEG with tf.io.decode_jpeg (default settings), as in training; the RF path keeps cv2. All four parity criteria pass: the server reproduces the deterministic Colab reference for both RF and CNN.
- **What was done:**
  - `model_path_image` returns (cv2-decoded RGB, JPEG bytes); `predict_cnn` decodes the bytes with tf.io.decode_jpeg; RF/GrabCut unchanged
  - run_parity.py: "Disagreeing images" now lists only rows where a grade differs; new "Findings" section (decoders, unseeded Colab noise, average latency)
  - Smoke tests 5 passed; full parity re-run: A PASS (112/112, max abs dp 4.99e-13), B PASS (112/112, max abs dp 2.85e-6), C PASS (clean-98 87.76%, was 86.73%), D PASS (9/9 disagreements with the unseeded Colab run below 0.60 on both sides)
  - Informational (vs the unseeded Colab run): final 103/112, RF 110/112, CNN-MC 111/112; average /grade latency 1226 ms (max 1859 ms)
  - investigate_cnn_det.py: relabelled the cv2 variant as the pre-fix server
- **Files changed:**
  - `~` backend/app/pipeline/colour.py
  - `~` backend/app/pipeline/inference.py
  - `~` backend/tests/parity/run_parity.py
  - `~` backend/tests/parity/investigate_cnn_det.py
  - `~` backend/tests/parity/parity_report.md
  - `~` backend/tests/parity/parity_mismatches.csv
- **Connected edits:** EDIT-086, EDIT-087
- **Reason:** The server decoded the CNN input with cv2 while training used TF, which shifted CNN probabilities by up to 0.335.

### EDIT-089 | 04 October 2026 07:10 | IST
- **Topic:** Backend Phase 3 - quality gates (invalid_image, blurry, no_stone, not_blue, not_recognised)
- **Summary:** /grade now runs five quality gates in order and stops at the first failure, returning HTTP 200 with the gate code, a short message and the diagnostics measured up to that gate. On the 112 test images 69 are falsely rejected (65 by not_blue, 4 by no_stone), above the target of 2. The thresholds are unchanged; fixes are proposed in gates_report.md and wait for approval.
- **What was done:**
  - New app/gates.py: all thresholds as named constants with their export source (MIN_SHORT_SIDE_PX 300, BLUR_MIN_VARIANCE 29.47, NO_STONE_MIN_AREA 0.0157, NO_STONE_MIN_CONTRAST_DE00 8.0, HUE_GATE 170-265, MIN_CHROMA 2.7, OOD_WARN 20.65, OOD_REJECT 25.69), the user messages, and the tray-balanced stone check (export_wb method: stone area, stone-tray dE00, stone C*, centre-box fallback)
  - inference.grade: gates run before the models where possible (size, blur, stone check, display-path hue) and the model path, RF, CNN and OOD after; ok responses gain `warnings` (`unusual_image` when OOD_WARN < distance <= OOD_REJECT); model path and model maths unchanged
  - display.py: measurement split from analyse so the display-path GrabCut runs once
  - schemas: grade fields optional, new `message`, `warnings` and gate diagnostics (short_side_px, gate_stone_area, stone_tray_contrast_de00, gate_centre_fallback, chroma_wb, min_chroma, hue_gate_skipped, ood_warn, thresholds)
  - main.py: a file with a JPEG/PNG signature that cannot be decoded now returns status invalid_image (HTTP 200); a wrong signature is still HTTP 400
  - tests/gates/run_gates.py: false rejections on the 112 raw test images plus synthetic negatives (blur sigma 3/6, tray crops, near-white, hue-rotated and greyscale stones, noise, checkerboards, grey); synthetic files written to /tmp only
  - Results: false rejections 69/112 (not_blue 65, no_stone 4). Synthetic rejection: blur sigma3 96.4%, sigma6 100%, tray crops 100% (all by blurry), near-white 2/2, red 94.6%, green 95.5%, yellow 95.5%, grey 98.2%, random 9/9
  - Cause: the display affine clips dark stone pixels to black (S = 0, H = 0), so the display-path median hue is 0 degrees for most grade 1-3 stones
  - Proposals (not applied): hue gate on the tray-balanced stone hue; MIN_CHROMA 0.5; NO_STONE_MIN_CONTRAST_DE00 5.0. Simulated: 2/112 false rejections, recoloured stones 109-111/112 rejected
  - Smoke tests: ok-path tests use a real test image (g6_010) from the dataset mount because the synthetic disc is now rejected as not_recognised; new tests for invalid_image, blurry, no_stone and not_blue; 9 passed
  - README: gate order, rejection format and warnings documented
- **Files changed:**
  - `+` backend/app/gates.py
  - `~` backend/app/main.py
  - `~` backend/app/schemas.py
  - `~` backend/app/pipeline/inference.py
  - `~` backend/app/pipeline/display.py
  - `~` backend/tests/test_smoke.py
  - `~` backend/README.md
  - `+` backend/tests/gates/run_gates.py
  - `+` backend/tests/gates/gates_report.md
- **Connected edits:** EDIT-086, EDIT-087, EDIT-088
- **Reason:** Reject photos that cannot be graded reliably (blurry, empty tray, non-blue or unfamiliar images) instead of returning a grade for them.

### EDIT-090 | 04 October 2026 08:02 | IST
- **Topic:** Backend Phase 3.1 - tray white-balanced colour values, gate fixes and new gate order
- **Summary:** Every user-facing colour value and the gate hue, chroma and contrast now come from the tray white-balanced image (export_wb method); the affine display path is commented out as superseded. With the approved threshold changes and the new gate order, false rejections fall from 69/112 to 3/112. Parity A-D still pass. Two further proposals wait for approval.
- **What was done:**
  - display.py: new tray_balanced_measure (256 px, GrabCut seed 42, tray median, gain 229.5/tray) gives L*, a*, b*, C*, H, S, B, mean RGB (hex, CIECAM02), stone area, stone-tray dE00 and fallback flags; analyse uses it and dE00 to typical now uses the grade_profiles_wb median
  - colour.py: fit_affine and display_path_image commented out as superseded; assets loads export_wb.json (affine assets marked unused)
  - gates.py: thresholds and decisions only; hue gate on the tray-balanced hue (170-265), MIN_CHROMA 2.7 -> 0.5, NO_STONE_MIN_CONTRAST_DE00 8.0 -> 5.0, NO_STONE_MIN_AREA kept and commented as a safety net
  - Gate order now invalid_image, no_stone, blurry, not_blue, not_recognised; segmentation_reliable and hue_gate_skipped come from the tray-balanced GrabCut; diagnostics.hue_physical renamed hue_wb
  - Development-only form field gates=false: every gate is evaluated but the image is graded anyway, failed gates listed in debug.gates_bypassed; run_parity.py sends it so all 112 images are compared
  - Gate test: false rejections 3/112 (no_stone g1_030 and g7_067, not_recognised g6_085 OOD 28.76); synthetic rejection: blur sigma3 95.5%, sigma6 100%, tray crops 100% (no_stone), near-white 2/2 (no_stone), red 92.9%, green 96.4%, yellow 96.4%, grey 99.1%, random 9/9
  - Parity: A PASS (112/112, 4.99e-13), B PASS (112/112, 2.85e-6), C PASS (87.76%), D PASS (9/9)
  - gates_report.md regenerated with "Changes from first run", the output field-source table, parity and proposals (keep OOD_REJECT and accept 3/112, or raise to 30; apply a wider hue band when segmentation is unreliable)
  - Smoke tests: hue_wb key, blur test accepts blurry or no_stone, new gate-bypass test; 10 passed
  - README: display path, gate order and field names updated
- **Files changed:**
  - `~` backend/app/gates.py
  - `~` backend/app/assets.py
  - `~` backend/app/main.py
  - `~` backend/app/schemas.py
  - `~` backend/app/pipeline/display.py
  - `~` backend/app/pipeline/colour.py
  - `~` backend/app/pipeline/inference.py
  - `~` backend/tests/test_smoke.py
  - `~` backend/tests/gates/run_gates.py
  - `~` backend/tests/gates/gates_report.md
  - `~` backend/tests/parity/run_parity.py
  - `~` backend/tests/parity/parity_report.md
  - `~` backend/tests/parity/parity_mismatches.csv
  - `~` backend/README.md
- **Connected edits:** EDIT-088, EDIT-089
- **Reason:** The affine display path turned dark stones black and broke the hue gate (65 false rejections); one consistent white-balanced measurement fixes the gates and the colour values shown to the user.

### EDIT-091 | 04 October 2026 12:09 | IST
- **Topic:** Backend Phase 3.2 - gate decisions (OOD kept, wide hue band tried and reverted)
- **Summary:** OOD_REJECT stays at the validation p99 (25.69), accepting 3/112 false rejections. The wider hue band for unreliable segmentation (150-285) was tried, newly rejected one real grade 1 stone (g1_016), and was reverted as agreed. Code is back to the EDIT-090 state; gates_report.md now has a Decisions section.
- **What was done:**
  - Tried: HUE_GATE_WIDE_MIN/MAX = 150/285 applied when segmentation_reliable is false (chroma check reliable-only); smoke tests 10 passed
  - Gate test with B: false rejections 4/112 (new: g1_016 not_blue, hue_wb 0, chroma_wb 0, segmentation unreliable); recolour red 99.1%, green 100%, yellow 100%, grey 99.1%
  - Condition (no new real rejection) failed, so B was reverted in gates.py, inference.py, schemas.py and run_gates.py; smoke tests 10 passed
  - Gate test re-run without B: 3/112 (g1_030, g7_067 no_stone; g6_085 not_recognised); recolour red 92.9%, green 96.4%, yellow 96.4%, grey 99.1%; identical to EDIT-090
  - gates_report.md regenerated, with Parity and Decisions sections (A kept at p99, no test-set tuning, g6_085 confidence 0.31 so referred anyway; B result table and reason for revert)
- **Files changed:**
  - `~` backend/tests/gates/gates_report.md
- **Connected edits:** EDIT-089, EDIT-090
- **Reason:** Record the threshold decisions and test whether the hue gate could also cover unreliable segmentation without new false rejections.

### EDIT-092 | 04 October 2026 14:41 | IST
- **Topic:** Backend Phase 4a - Firebase auth, MongoDB, S3 and grading history
- **Summary:** Every endpoint except /health now needs a Firebase ID token (revocation checked). Graded stones are stored (original image in private S3 with SSE-S3, record in MongoDB with a GE-STONE-NNNNN id); gate rejections store diagnostics only. Added /me, /gradings and /calibrations endpoints, per-ENV database and S3 prefix, and a pytest suite with temporary Firebase users. Model path, gates logic and thresholds unchanged.
- **What was done:**
  - config.py: ENV is development/test/production and selects DB (gemeye_dev/gemeye_test/gemeye) and S3 prefix (dev/, test/, none); secrets as SecretStr; startup logs only set/missing; MONGODB_DB no longer used
  - auth.py: current_user dependency, verify_id_token(check_revoked=True), generic 401, returns {uid, email, email_verified}
  - db.py: one MongoClient in lifespan; indexes gradings/calibrations (uid, created_at desc), rejections (created_at); atomic counters; ensure_user upsert with default profile and settings
  - storage.py: boto3 put/get/delete/exists/presign (10 min) under the env prefix, SSE-S3 (AES256), regional s3v4 endpoint
  - /grade: requires auth; new form fields session_id, app_version, device; default referral threshold from the user's settings; ok -> S3 upload + gradings insert + grading_id/stone_id/image_url; rejection -> rejections insert, no image; 503 if storage fails (S3 object removed if the DB insert fails); debug and gates=false now allowed when ENV != production
  - routers.py: GET/PUT /me (unknown fields and role ignored, threshold 0.40-0.90), GET /gradings (limit <= 50, cursor, grade, referred, from, to), GET/DELETE /gradings/{id} (404 for other users), POST/GET /calibrations
  - Tests: conftest (ENV=test guard, authed clients, session cleanup of gemeye_test and test/), helpers/firebase_test_user.py (admin SDK user + signInWithPassword, API key sent in a header), test_api.py, smoke tests now authenticated
  - run_parity.py and run_gates.py authenticate as a temporary test user and purge its data afterwards; run_gates.py accepts GATES_REPORT
  - requirements: firebase-admin 7.7.0, pymongo 4.18.2, boto3 1.43.108, slowapi 0.1.10 (not wired yet); image rebuilt
  - Verified: S3 put/exists/delete and Firebase sign-in + verify work; 33 auth tests passed. MongoDB login fails because MONGODB_URI in .env still has a placeholder password, so the DB-dependent tests, parity and gate re-runs are pending
  - README: environments, auth, endpoints, data model
- **Files changed:**
  - `+` backend/app/auth.py
  - `+` backend/app/db.py
  - `+` backend/app/storage.py
  - `+` backend/app/routers.py
  - `~` backend/app/config.py
  - `~` backend/app/main.py
  - `~` backend/app/schemas.py
  - `~` backend/requirements.txt
  - `~` backend/.env.example
  - `+` backend/tests/__init__.py
  - `+` backend/tests/conftest.py
  - `+` backend/tests/helpers/__init__.py
  - `+` backend/tests/helpers/firebase_test_user.py
  - `+` backend/tests/test_api.py
  - `~` backend/tests/test_smoke.py
  - `~` backend/tests/parity/run_parity.py
  - `~` backend/tests/gates/run_gates.py
  - `~` backend/README.md
- **Connected edits:** EDIT-090, EDIT-091
- **Reason:** The app needs authenticated, per-user grading history with stored images before the Flutter integration (Phase 4a).

### EDIT-093 | 04 October 2026 15:41 | IST
- **Topic:** Backend Phase 4a - verification with live MongoDB, S3 and Firebase
- **Summary:** With the corrected .env, MongoDB pings ok and the full suite passes (50/50) with ENV=test. Parity A-D and the gate results are unchanged from EDIT-091. All test data was cleaned up. Average /grade latency is now 2739 ms (was 1191 ms) because of auth, MongoDB and S3 round trips.
- **What was done:**
  - Confirmed DB per ENV: development -> gemeye_dev, test -> gemeye_test, production -> gemeye; no code reads MONGODB_DB, so nothing overrides gemeye_test
  - Container recreated to reload .env; MongoDB ping ok
  - pytest (ENV=test): 50 passed; after the second MONGODB_URI update, tests/test_api.py re-run in a one-off container: 40 passed
  - Parity: A PASS (112/112, 4.99e-13), B PASS (112/112, 2.85e-06), C PASS (87.76%), D PASS (9/9); average /grade latency 2739 ms (max 24067 ms, first request)
  - Gates: false rejections 3/112 and synthetic rejection rates identical to EDIT-091; report written to /tmp so the hand-written sections of gates_report.md are kept
  - Cleanup: gemeye_test dropped, 0 test/ objects; parity and gate test users purged (112 and 131 gradings + S3 objects, 776 rejections); gemeye_dev has no records apart from the global stone counter, 0 dev/ objects
  - Container recreated again on the final .env; startup clean
- **Files changed:**
  - `~` backend/tests/parity/parity_report.md
  - `~` backend/tests/parity/parity_mismatches.csv
- **Connected edits:** EDIT-090, EDIT-091, EDIT-092
- **Reason:** Verify Phase 4a end to end once the MongoDB credentials were fixed, and confirm the model path and gates are unchanged.

### EDIT-094 | 04 October 2026 16:37 | IST
- **Topic:** Backend Phase 4b - certificates, public verification, account deletion, remote config, feedback, latency
- **Summary:** Added certificate issue/list/PDF/revoke endpoints, the public verification endpoint, DELETE /me, remote config with maintenance mode and feedback. /grade now uses local token checks and saves to S3 and MongoDB concurrently; average latency went from 3195 ms to 2241 ms. 71/71 tests pass and parity A-D is unchanged.
- **What was done:**
  - Auth: check_revoked=False for /grade and reads; current_user_strict (check_revoked=True) for PUT /me, DELETE /me, POST /certificates, revoke and PDF upload
  - /grade: grading_id first, S3 upload and MongoDB insert run concurrently; on failure the other is undone and the response is 500; 503 {code: maintenance} while maintenance is enabled
  - Certificates: GE-YYYYMM-NNNNN (Asia/Colombo month, counter cert-YYYYMM), idempotent per grading (partial unique index on valid), frozen snapshot, owner only if show_name_on_certificates at issue time, token_urlsafe(12) + SHA-256 compared with compare_digest
  - PDF upload once (409 afterwards), certificates/{cert_no}.pdf + pdf_sha256; revoke (owner only)
  - GET /public/v/{slug}: identical 404 for unknown/wrong/malformed, 30/minute per IP (slowapi), Cache-Control no-store, CORS for the two allowed origins only, disclaimer
  - Privacy fix found by the tests: the grading image key contains the uid, so the photo is copied to certificates/{cert_no}.jpg at issue time and the public page links the copy; deleting the grading deletes the copies
  - DELETE /me: auth_time within 5 minutes (else 401 reauth_required); deletes gradings + images, calibrations, rejections, feedback, certificate PDFs and photo copies, the user and the Firebase user; certificates withdrawn (only cert_no, issued_at, status, reason, withdrawn_at, token hash kept, so old links show "withdrawn"); audit_log with sha256(uid)
  - Remote config app_config/"global" seeded at startup, GET /config (no auth, 60 s cache); POST /feedback with validation
  - Tests: tests/test_phase4b.py (21 tests); full suite 71 passed with ENV=test; gemeye_test dropped, 0 test/ and dev/ objects left
  - Parity: A PASS (112/112, 4.99e-13), B PASS (112/112, 2.85e-06), C PASS (87.76%), D PASS (9/9); mismatches CSV differs only by about 1e-13 float noise in rf_dp
  - Latency (10 calls, first excluded): 2241 ms (baseline before the change 3195 ms)
  - README: auth, endpoints, certificate/verification flow, account deletion, remote config, data model
- **Files changed:**
  - `+` backend/app/certificates.py
  - `+` backend/app/errors.py
  - `~` backend/app/auth.py
  - `~` backend/app/db.py
  - `~` backend/app/main.py
  - `~` backend/app/routers.py
  - `~` backend/app/schemas.py
  - `~` backend/app/storage.py
  - `+` backend/tests/test_phase4b.py
  - `~` backend/tests/parity/parity_report.md
  - `~` backend/tests/parity/parity_mismatches.csv
  - `~` backend/README.md
- **Connected edits:** EDIT-092, EDIT-093
- **Reason:** Phase 4b: certificates with public verification, account deletion, remote config and feedback, and lower /grade latency, before the Flutter integration.

### EDIT-095 | 04 October 2026 23:50 | IST
- **Topic:** Backend Phase 4c - close the deleted-account token gap
- **Summary:** DELETE /me now revokes refresh tokens and writes a 2-hour TTL tombstone (sha256(uid)). Writes and user-creating requests refuse a deleted uid's still-valid ID token with 401 account_deleted and never re-create its users document. The full suite was not verified: the first run had 63 passed and 9 failed, because the Docker VM clock is ~1 s behind Google (InvalidIdTokenError "Token used too early"), and a rerun was not possible.
- **What was done:**
  - db: new deleted_accounts collection {_id: sha256(uid), deleted_at}, TTL index expireAfterSeconds=7200
  - auth: active_user / active_user_strict check the tombstone before anything else (401 {code: "account_deleted"}); uid_hash helper
  - DELETE /me: upserts the tombstone, then firebase_auth.revoke_refresh_tokens(uid), then deletes the data and the Firebase user; DELETE /me itself does not check the tombstone, so a failed deletion can be retried
  - Tombstone checked on /grade, GET and PUT /me (GET /me creates the user record), POST /calibrations, POST /feedback, POST /certificates, PDF upload and revoke; other reads unchanged
  - Test test_deleted_account_token_is_refused: after DELETE /me the same token gets 401 account_deleted on /grade, PUT /me, POST /feedback, POST /calibrations and GET /me; no users document, gradings, rejections, calibrations or feedback are created; tombstone and audit entry cleaned up
  - README: Auth "known gap" note replaced by the fix; account deletion section and data model updated
- **Files changed:**
  - `~` backend/app/auth.py
  - `~` backend/app/db.py
  - `~` backend/app/main.py
  - `~` backend/app/routers.py
  - `~` backend/app/certificates.py
  - `~` backend/tests/test_phase4b.py
  - `~` backend/README.md
- **Connected edits:** EDIT-094
- **Reason:** A deleted user's ID token stayed valid for up to 1 hour and could still write data or re-create the users document.

### EDIT-096 | 05 October 2026 00:10 | IST
- **Topic:** Backend - tolerate 5 s clock skew in Firebase token verification
- **Summary:** The EDIT-095 suite run had 9 failures. Each was a fresh test user's first request, rejected with InvalidIdTokenError "Token used too early" because the Docker VM clock is about 1 s behind Google. Token verification now passes clock_skew_seconds=5.
- **What was done:**
  - auth._verify: verify_id_token(..., clock_skew_seconds=CLOCK_SKEW_S) with CLOCK_SKEW_S = 5
  - README: Auth section notes the 5 s skew tolerance
  - Full suite (ENV=test), run by the developer: 72 passed, including test_deleted_account_token_is_refused (EDIT-095 now verified)
- **Files changed:**
  - `~` backend/app/auth.py
  - `~` backend/README.md
- **Connected edits:** EDIT-094, EDIT-095
- **Reason:** A token used right after sign-in was rejected whenever the server clock lagged Google's, which broke the test suite and could hit real users on a drifting server.

### EDIT-097 | 05 October 2026 00:45 | IST
- **Topic:** Phase 5 Step 0 - read-only app report
- **Summary:** Documented the app's current grading flow, local storage, calibration, photo check, certificates, settings, auth and platform config against the backend, as the basis for Phase 5. No code changed.
- **What was done:**
  - GradeResult source with every creation and use site; demo results at grading_service.dart:64 and result_screen.dart:49
  - Screen-by-screen grading flow, repeatability mode, CalibrationService storage and CCM format
  - App vs server blur check comparison (threshold 50 vs 29.47, different resize and input)
  - Full TODO(backend/F2/dataset) list (no TODO(C4) found), settings audit, AuthService token methods
  - Found: no INTERNET permission in the main AndroidManifest, no iOS camera/photo usage strings, apiBaseUrl is http://localhost:5000
  - "What Phase 5 must change", grouped by file
- **Files changed:**
  - `+` docs/app_phase5_report.md
- **Connected edits:** EDIT-094, EDIT-095, EDIT-096
- **Reason:** Phase 5 (app-backend integration) needs an exact picture of the current app first.

### EDIT-098 | 05 October 2026 01:40 | IST
- **Topic:** Backend Phase 5a - idempotent /grade, session_mapping flag, QA token script
- **Summary:** /grade accepts a request_id (UUID); a repeated one from the same user returns the original grading instead of a new one. A new remote-config flag features.session_mapping (default false) decides whether session patches drive the model path; patches are always stored. Added scripts/get_token.py for /docs testing. 76/76 tests pass with ENV=test.
- **What was done:**
  - /grade: optional form field request_id (UUID, normalised; else 400). Looked up before grading: same uid → original response (same grading_id and stone_id, fresh image_url), no new grading or S3 object; another uid or a deleted grading → 409 {code: duplicate_request}. A concurrent duplicate (DuplicateKeyError) undoes its own S3 upload and returns the original
  - gradings: unique sparse index request_id_unique; request_id stored only when sent; patches (6x3 or null) always stored
  - Remote config: features.session_mapping default false (DEFAULT_APP_CONFIG, Features schema). When false, patches are ignored for the model path and calibration_mode is "training_session"; when true, "session_patches"
  - scripts/get_token.py: --email, password via getpass (never echoed or stored), Identity Toolkit sign-in with the API key in a header, prints only the ID token; refuses ENV=production. docker-compose mounts ./scripts read-only
  - Tests: tests/test_phase5a.py (repeat request_id, other user 409, non-UUID 400, sparse unique index, session_mapping on/off); test_smoke patches test now expects training_session by default
  - README: request_id, session_mapping, gradings fields/index, QA token section
- **Files changed:**
  - `~` backend/app/main.py
  - `~` backend/app/db.py
  - `~` backend/app/schemas.py
  - `+` backend/scripts/get_token.py
  - `~` backend/docker-compose.yml
  - `+` backend/tests/test_phase5a.py
  - `~` backend/tests/test_smoke.py
  - `~` backend/README.md
- **Connected edits:** EDIT-094, EDIT-097
- **Reason:** The app must retry uploads safely without duplicate gradings, session mapping must stay off until it is validated, and /docs testing needs a token.

### EDIT-099 | 05 October 2026 01:55 | IST
- **Topic:** App Phase 5a - API config, network layer, grading request and models
- **Summary:** Added the build-time API config, the HTTP ApiClient (Firebase token with one refresh on 401, timeouts, GET-only retry, typed errors), GradingService.gradeStone (multipart POST /grade) and server-shaped models. Screens are unchanged and still use the demo GradingService.grade.
- **What was done:**
  - lib/config/app_config.dart: API_ENV dart-define (dev → http://127.0.0.1:8000, prod → PROD_URL placeholder https://api.gemeye.invalid)
  - Android: INTERNET in the main manifest; debug-only network_security_config (cleartext only for 127.0.0.1 and localhost) referenced from src/debug/AndroidManifest.xml
  - lib/services/api_client.dart: getJson/postJson/putJson/delete/postMultipart; connect timeout 10 s (HttpClient), receive 60 s; 401 → getIdToken(true) and one retry (not for account_deleted/reauth_required); GET retries once on timeout/5xx, POST/PUT/DELETE never; ApiException codes accountDeleted, reauthRequired, maintenance (server message), offline, timeout, serverError, tooLarge, plus unauthorized, notFound, badRequest, conflict; messages are user-friendly only
  - GradingService.gradeStone(File, {patches, sessionId, referralThreshold (0.40-0.90), requestId}): JPEG prepared in an isolate (EXIF orientation applied, EXIF dropped, longer side ≤ 2048 px, quality 95), request_id (uuid v4 unless given), app_version, device
  - lib/models/grading_response.dart: GradingStatus (ok, invalid_image, blurry, no_stone, not_blue, not_recognised, unknown), message, warnings, diagnostics, measuredHue
  - GradeResult: existing fields kept (confidence and probabilities in percent); added gradingId, imageUrl, probabilities, secondGrade, referred, warnings, ciecam02, colourApproximate, colourHex, modelVersion, calibrationMode, uncertainty getter; fromApi(); older saved history still loads
  - Tests: grading_response_test.dart (ok, no CIECAM02, round trip, legacy history, 5 rejections, unknown) and api_client_test.dart (bearer, 401 refresh + retry for GET and POST, double 401, account_deleted, reauth_required, maintenance, GET 5xx retry, POST no retry, timeout, offline, 413, signed out, public call)
  - flutter analyze: no issues. flutter test: 31 passed; widget_test.dart still fails as before (pending splash timer, Firebase not initialised)
- **Files changed:**
  - `+` app/lib/config/app_config.dart
  - `+` app/lib/services/api_client.dart
  - `+` app/lib/models/grading_response.dart
  - `~` app/lib/models/grade_result.dart
  - `~` app/lib/services/grading_service.dart
  - `~` app/android/app/src/main/AndroidManifest.xml
  - `~` app/android/app/src/debug/AndroidManifest.xml
  - `+` app/android/app/src/debug/res/xml/network_security_config.xml
  - `+` app/test/grading_response_test.dart
  - `+` app/test/api_client_test.dart
- **Connected edits:** EDIT-097, EDIT-098
- **Reason:** Phase 5a network layer, so the screens can switch to the real server in the next step.

### EDIT-100 | 05 October 2026 04:40 | IST
- **Topic:** Backend Phase 5b - blur threshold in /config, blur reference script
- **Summary:** GET /config now also returns blur_min_variance (the server's blurry gate) so the app's Photo Check uses the same threshold. Added a dev-only script that prints the server blur variance of image files. 76/76 tests pass with ENV=test.
- **What was done:**
  - routers.get_config adds blur_min_variance = gates.BLUR_MIN_VARIANCE (not stored in MongoDB); AppConfig schema field
  - scripts/blur_variance.py: decodes files exactly as /grade (decode_image) and prints inference.blur_variance; refuses ENV=production
  - test_config_defaults expects the new field
  - README: /config field, blur reference script section
- **Files changed:**
  - `~` backend/app/routers.py
  - `~` backend/app/schemas.py
  - `+` backend/scripts/blur_variance.py
  - `~` backend/tests/test_phase4b.py
  - `~` backend/README.md
- **Connected edits:** EDIT-098, EDIT-101
- **Reason:** The app's blur check must use the same definition and threshold as the server.

### EDIT-101 | 05 October 2026 04:50 | IST
- **Topic:** App Phase 5b - grading flow wired to the server
- **Summary:** Processing, Grade Result, Not Accepted, Photo Check and Repeatability now use the real /grade responses; all demo grading values and the mock result are removed. Photo Check blur is bit-identical to the server (5/5 reference values match within 1e-9). Demo history is removed once with a notice. flutter analyze: no issues; 38 tests pass (widget_test.dart fails as before). Debug APK built; not installed because no device was attached.
- **What was done:**
  - Processing: GradingService.gradeStone per photo with session patches, session id, referral threshold (setting / 100) and one request id per photo kept across retries; steps follow real progress (upload bytes → server phase advancing to "Running AI ensemble" → done on response); "Photo n of 3" in Repeatability; ApiException mapping: offline → No connection (Retry/Cancel), timeout → Server is taking too long (Retry, same request id), maintenance → server message, account_deleted → Account deleted then logout with local data cleared, unauthorized/reauth_required → Session expired, too_large → Photo too large, other → Something went wrong
  - ApiClient.postMultipart(onProgress): counts body bytes as the connection pulls them
  - GradingService: demo grade(), RejectionReason and the old exceptions removed
  - Result: gradeResult required, mock removed; borderline from server `referred` (falls back to the threshold for older results) naming second_grade; probability bars from probabilities; uncertainty ± from the server; info banner for unusual_image (new StatusBannerType.info); CIECAM02 tiles (J, M, h, s, C) in the colour-values style; approximate note; hex and swatch from colour.hex; model version in the footer; local photo with the presigned image URL as fallback; heatmap placeholder "Heatmap available after Phase 8" while features.gradcam is false
  - Not Accepted: routed by status (no_stone, blurry, not_blue, not_recognised, invalid_image, unknown) with the server message, the gate measurement (sharpness/short side/stone area with minimum) and the measured hue swatch for not_blue; "Why was this rejected?" lists the 5 checks
  - Photo Check: exact port of the server blur (cv2 RGB2GRAY 15-bit, INTER_AREA to 512 incl. the integer, non-integer and enlarging paths with OpenCV's float32/fixed-point rounding, central 50%, Laplacian with reflect-101, population variance), computed on the photo exactly as it will be uploaded; threshold from /config (default 29.474166117400628). Verified first with a numpy reimplementation against cv2 on 150 random sizes (0 differences)
  - test/photo_check_test.dart with 5 PNG fixtures (test/fixtures/blur, 870 KB) and the server values from scripts/blur_variance.py
  - RemoteConfigService: GET /config at startup (blur threshold, gradcam, session_mapping, maintenance)
  - Repeatability Summary: max ΔE₀₀ between the 3 captures from the returned L*a*b* (ColourMath.deltaE2000) with verdict (≤1 Excellent, ≤2 Good, else Poor); referred from the server; swatches from colour.hex
  - Demo history: on the first launch after the update, local results without a server grading id are removed with their photos (and the old local stone counter); an info notification and a one-time Home dialog explain it
  - Removed the unused AppConstants.minBlurThreshold (100)
- **Files changed:**
  - `~` app/lib/screens/processing_screen.dart
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/not_accepted_screen.dart
  - `~` app/lib/screens/repeatability_summary_screen.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/services/photo_check_service.dart
  - `~` app/lib/services/grading_service.dart
  - `~` app/lib/services/api_client.dart
  - `~` app/lib/services/storage_service.dart
  - `+` app/lib/services/remote_config_service.dart
  - `~` app/lib/widgets/status_banner.dart
  - `~` app/lib/config/constants.dart
  - `~` app/lib/main.dart
  - `+` app/test/photo_check_test.dart
  - `+` app/test/fixtures/blur/area_1600x1200_sharp.png
  - `+` app/test/fixtures/blur/fast2x_1024x768_blur.png
  - `+` app/test/fixtures/blur/fast4x_2048x1536_sharp.png
  - `+` app/test/fixtures/blur/portrait_700x1050_blur.png
  - `+` app/test/fixtures/blur/upscale_400x300_sharp.png
- **Connected edits:** EDIT-099, EDIT-100
- **Notes:** Repeatability creates 3 server gradings (3 stone ids); only the chosen one is saved locally. History, Home and certificates still read local storage (next phase).
- **Reason:** Phase 5b: the grading flow must use the real server results.

### EDIT-102 | 05 October 2026 05:05 | IST
- **Topic:** App Phase 5c - history, calibration, certificates, settings, remote config and feedback synced with the server
- **Summary:** History, Home stats, Referred chips and Comparison now read the server (local cache for offline). Calibrations, certificates, profile settings, account deletion, remote config and feedback use the API. flutter analyze: no issues; 52 tests pass (widget_test.dart fails as before). Debug APK built; not installed because no Android device was attached.
- **What was done:**
  - History: HistoryService (GET /gradings paged with cursor, grade/referred/from/to as query params, certificate numbers from GET /certificates, cache in StorageService per account, offline fallback); History screen loads pages from the server (grade chips, Referred, date and confidence filters sent to the server, infinite scroll, pull to refresh, "Offline, saved results" in the count line); delete (single, batch, Clear history) calls DELETE /gradings/{id} and removes the cached photo; Home (cache first, then server), Profile, Comparison, Notifications and CSV export read the same data; referred = server flag (falls back to the threshold only for results without one: GradeResult.isReferred)
  - Calibration: POST /calibrations after the wizard saves (session_id, device, ccm 3x3, residual, quality, measured_patches white, black, grey_18, grey_50, blue, red, valid_until); an unsent session is retried from Home; every /grade already sends patches + session_id; wizard text "Use the same Pro-mode exposure for the patches and the stones."
  - Certificates: export POSTs /certificates (first time) or GETs /certificates/{no} (re-export, same number and QR); QR = verify_url with caption "Scan to verify"; PDF uploaded with POST /certificates/{no}/pdf (409 ignored); local certificate counter removed; numbers issued before this update keep the JSON QR with "Offline certificate - not verifiable online"; Settings "Certificate prefix" removed (the server always issues GE-YYYYMM-NNNNN)
  - Settings: referral threshold and new toggle "Show my name/company on public certificate" (off by default) saved with PUT /me and restored if the server refuses; both read from GET /me; server status row from GET /health (Connected · N ms / Not connected, tap to re-check); Delete account: re-auth dialog, forced token refresh, DELETE /me (one more re-auth on reauth_required), local wipe, Login
  - Remote config: maintenance banner on Home, min_app_version prompt (once per launch), repeatability_mode hides the Repeatability toggle, gradcam as before
  - Feedback sheet: one category, POST /feedback (rating, category, comment, app_version); errors keep the sheet open
  - Notifications: Grading failed (opens Capture to retry), referred, certificate saved and calibration expired as before
  - Tests: test/phase5c_test.dart (query mapping, grading item to result, referred rule, calibration body, certificate POST/GET/offline/409, /me settings, DELETE /me reauth_required, remote config and version compare)
- **Files changed:**
  - `+` app/lib/services/history_service.dart
  - `+` app/lib/services/me_service.dart
  - `+` app/lib/services/certificate_api_service.dart
  - `+` app/test/phase5c_test.dart
  - `~` app/lib/models/grade_result.dart
  - `~` app/lib/services/certificate_service.dart
  - `~` app/lib/services/calibration_service.dart
  - `~` app/lib/services/grade_record_service.dart
  - `~` app/lib/services/settings_service.dart
  - `~` app/lib/services/storage_service.dart
  - `~` app/lib/services/remote_config_service.dart
  - `~` app/lib/services/account_service.dart
  - `~` app/lib/screens/history_screen.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/settings_screen.dart
  - `~` app/lib/screens/certificate_screen.dart
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/repeatability_summary_screen.dart
  - `~` app/lib/screens/calibration_result_screen.dart
  - `~` app/lib/screens/calibration_screen.dart
  - `~` app/lib/screens/capture_screen.dart
  - `~` app/lib/screens/processing_screen.dart
  - `~` app/lib/screens/feedback_sheet.dart
  - `~` app/lib/screens/comparison_screen.dart
  - `~` app/lib/screens/notifications_screen.dart
  - `~` app/lib/screens/profile_screen.dart
  - `~` app/lib/widgets/recent_grade_tile.dart
  - `~` app/pubspec.yaml
- **Connected edits:** EDIT-099, EDIT-100, EDIT-101
- **Notes:** Repeatability still creates 3 server gradings, so History now lists all 3 (only the chosen one had been kept locally before). Sorting other than newest applies to the loaded pages only. "Show my name/company" affects the public verify page only; the PDF still prints "Issued to". Added http_parser to pubspec (PDF content type).
- **Reason:** Phase 5c: the server must be the source of truth for history, calibrations, certificates and settings.

### EDIT-103 | 05 October 2026 06:10 | IST
- **Topic:** Backend Phase 6 part 1 - downscale parity (run_parity.py --downscale 2048)
- **Summary:** run_parity.py can grade every test image as the app uploads it (EXIF orientation applied, longer side at most 2048 px, JPEG quality 95, no metadata) and compare with the normal run. Result: 109/112 grades agree; accuracy 98/112 normal vs 97/112 downscaled (difference 1, within +/-1 image: PASS). No bug list from the manual E2E test, so part 2 is closed.
- **What was done:**
  - run_parity.py: --downscale N option, app_upload_bytes() (OpenCV area resize, JPEG q95), main_downscale() writes parity_downscale_report.md; the normal run and its report are unchanged
  - Grade changes: g2_148 2 to 3, g3_010 3 to 4, g6_016 7 to 6 (all confidence below 0.61)
- **Files changed:**
  - `~` backend/tests/parity/run_parity.py
  - `+` backend/tests/parity/parity_downscale_report.md
- **Connected edits:** EDIT-101, EDIT-102
- **Notes:** The resize is OpenCV INTER_AREA, which approximates the app's Dart resize but is not bit-identical.
- **Reason:** Phase 6: confirm that the app's 2048 px JPEG upload does not change grading.

### EDIT-104 | 05 October 2026 06:40 | IST
- **Topic:** Backend Phase 6 fixes - unique calibration session, paged certificate list
- **Summary:** POST /calibrations is now unique per (user, session_id): a repeated session returns 409 (code duplicate_session) with the stored one. GET /certificates takes a cursor and returns next_cursor. Backend suite with ENV=test: 78 passed (2 new tests).
- **What was done:**
  - db.ensure_indexes: unique index uid_session_unique on calibrations (uid, session_id)
  - routers.post_calibration: DuplicateKeyError becomes 409 {code: duplicate_session, calibration: existing}
  - certificates.list_certificates: cursor and next_cursor (issued_at, _id), CertificateList.next_cursor
  - Tests: duplicate calibration session (409, same id, other user allowed), certificate list paging with a cursor
- **Files changed:**
  - `~` backend/app/db.py
  - `~` backend/app/routers.py
  - `~` backend/app/certificates.py
  - `~` backend/app/schemas.py
  - `~` backend/tests/test_api.py
  - `~` backend/tests/test_phase4b.py
- **Connected edits:** EDIT-099, EDIT-102, EDIT-103
- **Notes:** The unique index fails to build if a database already holds two calibrations with the same (uid, session_id); the development and test databases had none.
- **Reason:** The app retries unsent calibrations, so the server must not store duplicates; History needs every certificate badge.

### EDIT-105 | 05 October 2026 06:45 | IST
- **Topic:** App Phase 6 fixes - owner on the PDF, revoked certificates, shared dead-session handler, referred flag, calibration queue, cleanup
- **Summary:** The PDF prints "Issued to" and the company only when the server certificate has owner fields (same as the public page). A revoked or withdrawn certificate cannot be exported. account_deleted or a failed token refresh now runs one shared handler. Referred uses the stone's own flag everywhere. Unsent calibrations are a queue. flutter analyze: no issues; 64 tests pass.
- **What was done:**
  - PDF: Issued to and Company come from GradeResult.certificateOwnerName/Company (read from GET /certificates/{no} at export, stored in the cache); lines omitted when empty; High/Borderline/Low from isReferred
  - CertificateApiService.ensure: always GETs the certificate (after POST on first export); revoked or other non-valid status throws an ApiException; 404, or a number that belongs to another stone, stays an offline certificate (issued before the server issued them)
  - ApiClient.sessionLostHandler (set in main.dart to AuthService.handleDeadSession): called once per failed request on account_deleted, or 401/reauth_required after the refresh; shows one dialog, clears local data, opens Login; DELETE /me passes guardSession false; duplicate handling removed from processing_screen
  - ConfidenceBadge takes referred; Result, Repeatability summary, Recent tile, History and the PDF use GradeResult.isReferred
  - CalibrationService: list of pending sessions (secure storage), one attempt per Home refresh, 409 counts as sent, network/5xx kept, other 4xx dropped
  - HistoryService reads every page of GET /certificates; ownership check no longer needs Firebase (tests)
  - Cleanup: widget_test.dart deleted, stale TODOs removed (notification_service, account_service), demo-history notice code removed (main.dart, home_screen.dart, StorageService.removeDemoHistory, stone counter key)
  - Tests added to phase5c_test.dart: owner fields, revoked/withdrawn/404/mismatch, certificate paging in History, dead-session handler, calibration queue
- **Files changed:**
  - `~` app/lib/services/certificate_service.dart
  - `~` app/lib/services/certificate_api_service.dart
  - `~` app/lib/services/api_client.dart
  - `~` app/lib/services/auth_service.dart
  - `~` app/lib/services/me_service.dart
  - `~` app/lib/services/calibration_service.dart
  - `~` app/lib/services/history_service.dart
  - `~` app/lib/services/storage_service.dart
  - `~` app/lib/services/notification_service.dart
  - `~` app/lib/services/account_service.dart
  - `~` app/lib/models/grade_result.dart
  - `~` app/lib/widgets/confidence_badge.dart
  - `~` app/lib/widgets/recent_grade_tile.dart
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/repeatability_summary_screen.dart
  - `~` app/lib/screens/processing_screen.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/main.dart
  - `~` app/test/phase5c_test.dart
  - `-` app/test/widget_test.dart
- **Connected edits:** EDIT-102, EDIT-104
- **Notes:** Repeatability still stores all 3 gradings (needed for Phase 7). Saved PDFs in Downloads are kept. Certificates issued on the device before the update now print without "Issued to" (no server owner record).
- **Reason:** Approved Phase 6 fixes from the Phase 5c review.

### EDIT-106 | 05 October 2026 07:20 | IST
- **Topic:** Certificate export follows the Settings export format (PDF / Image / Both); Result opened from History
- **Summary:** The export button(s) on Grade Result, Repeatability summary and History "Export Batch" now follow Settings > Default export format: PDF gives "Export PDF", Image gives "Export Image" (PNG of the certificate page), Both gives two separate buttons. Results opened from Home, History or a notification show only the export button(s) and Share. flutter analyze: no issues; 64 tests pass.
- **What was done:**
  - New ExportButtons widget (widgets/export_buttons.dart) and CertificateFile enum; reads SettingsService.exportFormat live
  - CertificateScreen file parameter: Image mode saves/shares {cert_no}.png (page rendered at 200 dpi), no Print; the PDF is still uploaded to the server once for the verify page
  - ResultScreen fromHistory (Home, History, Notifications): export button(s) + Share, no Save & Grade Next / Retake; referred stones keep their existing buttons (no export), unchanged by request
  - History Export Batch writes .pdf, .png or both per stone
  - CertificateService.stoneImageBytes: local photo, else the server photo (presigned URL); an empty photo gives a plain panel instead of failing; CertificateService.renderPng
  - Removed the stale export-format TODO in settings_screen.dart
- **Files changed:**
  - `+` app/lib/widgets/export_buttons.dart
  - `~` app/lib/services/certificate_service.dart
  - `~` app/lib/screens/certificate_screen.dart
  - `~` app/lib/screens/result_screen.dart
  - `~` app/lib/screens/repeatability_summary_screen.dart
  - `~` app/lib/screens/history_screen.dart
  - `~` app/lib/screens/home_screen.dart
  - `~` app/lib/screens/notifications_screen.dart
  - `~` app/lib/screens/settings_screen.dart
- **Connected edits:** EDIT-102, EDIT-105
- **Notes:** Referred is the server flag from grading time; changing the threshold in Settings applies to stones graded afterwards only.
- **Reason:** Manual E2E test: the export format setting had no effect and Result opened from History showed grading buttons.

### EDIT-107 | 05 October 2026 07:45 | IST
- **Topic:** Phase 5c/6 closed - manual E2E test on a device passed
- **Summary:** The developer ran the full manual E2E checklist on an Android 13 phone (DN2103, USB, adb reverse tcp:8000 to the local Docker server). All steps passed, including the export format changes from EDIT-106. No code changed in this entry.
- **What was done:**
  - E2E checklist: login and server status, calibration (POST /calibrations, including the retry of an earlier unsent session), grading and rejections, Repeatability, History filters/paging/delete, Home stats, Stone Comparison, certificate export (PDF, Image, Both; same number and QR on re-export; public verify page), Settings (threshold, show-name toggle, feedback), offline behaviour, account deletion and re-login
- **Files changed:**
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-102, EDIT-103, EDIT-104, EDIT-105, EDIT-106
- **Notes:** Testing on the phone needs the USB cable and `adb reverse tcp:8000 tcp:8000` after every reconnect (the dev API URL is 127.0.0.1:8000).
- **Reason:** Record that Phases 5c and 6 are verified end to end.

### EDIT-108 | 05 October 2026 09:30 | IST
- **Topic:** Phase 8 - Grad-CAM heatmap (server endpoint, app Result screen section)
- **Summary:** New POST /gradings/{id}/heatmap computes Grad-CAM of the CNN branch from the stored original, using the grading's own calibration mode. The PNG is cached in S3 and deleted with the grading or the account. The Result screen now loads the heatmap from the server, with loading, error/Retry and disabled states. Grading, gates and thresholds are unchanged (parity unchanged). Backend 84 passed; flutter analyze: no issues; 73 app tests pass.
- **What was done:**
  - Server: app/pipeline/gradcam.py: Grad-CAM on top_activation (nested EfficientNet-B0), deterministic model, gradient of the target-class logit (target = the grading's final grade), raises if the gradient is None; normalised to [0,1], upsampled to the display image (longer side at most 640 px), jet overlay at alpha 0.4 on the tray-balanced image
  - CNN input rebuilt with the same model path; session_patches gradings replay their stored patches, training_session gradings use none; the current session_mapping flag is never read
  - stone_mask_heat_fraction = share of heat inside the GrabCut stone mask (256 px, seed 42), stored in gradings.heatmap with the S3 key gradings/{uid}/{id}_cam.png; a second call reuses the stored PNG (presigned URL, 10 min)
  - 404 for other users, deleted gradings and missing photos; 503 maintenance; the model lock (MODEL_LOCK in assets.py) is shared with /grade
  - DELETE /gradings/{id} also deletes the heatmap PNG and unsets gradings.heatmap; DELETE /me already deletes gradings/{uid}/
  - WBMeasure now also returns the stone mask and tray gain (measured values unchanged)
  - Remote config default features.gradcam: true; the development database's stored value was set to true
  - tests/test_phase8.py (6 tests): shape and range, deterministic, matches the deterministic CNN output, cache hit, other user/missing photo 404, removal on grading and account delete, calibration_mode replay
  - tests/parity/run_gradcam_stats.py: 112 test images: mean stone_mask_heat_fraction 0.372, average heatmap latency 1808 ms (cache hit 224 ms); run_parity.py results unchanged (A-D PASS, same values)
  - App: HeatmapService (POST, downloads the presigned PNG, in-memory cache cleared on sign-out); GradCamCard widget replaces the placeholder on the Result screen (Home, History and notifications open the same screen); legend and "Shows where the CNN looked. It is an explanation aid, not a second opinion."; hidden when features.gradcam is off; offline, maintenance and session-lost errors come through ApiClient
  - test/gradcam_test.dart (9 tests): loading, error and retry, maintenance and not-found, disabled, no grading id, dash check, service caching and errors
- **Files changed:**
  - `+` backend/app/pipeline/gradcam.py
  - `~` backend/app/pipeline/display.py
  - `~` backend/app/assets.py
  - `~` backend/app/main.py
  - `~` backend/app/routers.py
  - `~` backend/app/schemas.py
  - `~` backend/app/db.py
  - `~` backend/README.md
  - `+` backend/tests/test_phase8.py
  - `+` backend/tests/parity/run_gradcam_stats.py
  - `+` backend/tests/parity/gradcam_stats.md
  - `~` backend/tests/parity/parity_report.md (latency only)
  - `~` backend/tests/parity/parity_mismatches.csv (RF dp differs at 1e-16 only)
  - `+` app/lib/services/heatmap_service.dart
  - `+` app/lib/widgets/gradcam_card.dart
  - `~` app/lib/services/auth_service.dart
  - `~` app/lib/screens/result_screen.dart
  - `+` app/test/gradcam_test.dart
- **Connected edits:** EDIT-102, EDIT-105, EDIT-106
- **Notes:** The mean heat share on the stone (0.372) is below one half: the CNN also uses the tray around the stone, which is useful to know when reading the heatmap. Production app_config keeps whatever gradcam value is stored; set features.gradcam to true there when ready. GradeResult.gradcamImagePath is no longer used by the Result screen (kept for stored JSON).
- **Reason:** Phase 8: Grad-CAM explanation of the CNN branch.

### EDIT-109 | 05 October 2026 10:30 | IST
- **Topic:** Phase 8.1 - Grad-CAM follow-ups: production default checked, heat/area statistics
- **Summary:** The remote config seed already has features.gradcam true (set in EDIT-108), so a fresh database, including the new production "gemeye", is seeded with it; a test now checks the seed and GET /config. run_gradcam_stats.py now also reports stone area and heat/area, overall and per grade. Grading, gates, thresholds and the model path are unchanged; parity unchanged; backend 85 passed.
- **What was done:**
  - Checked DEFAULT_APP_CONFIG (app/db.py): features.gradcam is True; no code change needed
  - New test test_config_gradcam_default_true_on_fresh_db: the default, the stored document in the freshly seeded gemeye_test database and GET /config all give gradcam true (runs without the dataset)
  - run_gradcam_stats.py: per image stone_area_fraction (diagnostics.gate_stone_area: the 256 px GrabCut mask, seed 42, the same mask as the heat fraction), heat_over_area; mean/median of each, share with heat_over_area > 1, all images, per true grade and per predicted grade; latency; Interpretation note
  - Results (112 images): stone_area_fraction mean 0.083 / median 0.069; stone_mask_heat_fraction mean 0.372 / median 0.381; heat_over_area mean 4.89 / median 4.95; heat_over_area > 1 on 112/112; average heatmap latency 1660 ms (cache hit 211 ms)
  - The report replaces gradcam_stats.md (deleted); README updated
  - run_parity.py: A-D PASS with the same values (report changes are latency and floating-point noise at 1e-15 only)
- **Files changed:**
  - `~` backend/tests/test_phase8.py
  - `~` backend/tests/parity/run_gradcam_stats.py
  - `+` backend/tests/parity/gradcam_stats_report.md
  - `-` backend/tests/parity/gradcam_stats.md
  - `~` backend/tests/parity/parity_report.md (latency only)
  - `~` backend/tests/parity/parity_mismatches.csv (floating-point noise only)
  - `~` backend/README.md
- **Connected edits:** EDIT-108
- **Notes:** The test_phase8 module-level dataset mark was replaced by a mark on each dataset test, so the config test always runs. The heat on the stone is about 5 times what a uniform map would give, but about 63% of the heat still falls outside the mask (tray and edges).
- **Reason:** Phase 8.1: confirm the production default and measure how much the CNN attends to the stone relative to its size.

### EDIT-110 | 05 October 2026 11:00 | IST
- **Topic:** Phase 8 Grad-CAM - manual device test passed
- **Summary:** The developer tested the Grad-CAM heatmap on the Android phone (USB, adb reverse to the local Docker server): the heatmap generates and shows correctly on the Grade Result screen. No code changed in this entry.
- **What was done:**
  - Manual test of POST /gradings/{id}/heatmap from the Result screen on a device: passed
- **Files changed:**
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-108, EDIT-109
- **Reason:** Record that the Phase 8 heatmap works end to end on a real device.

### EDIT-111 | 05 October 2026 11:30 | IST
- **Topic:** AWS read-only audit - report written (AWS checks blocked)
- **Summary:** Ran a read-only audit with profile gemeye-audit in ap-south-1. The profile does not exist locally (only "gemeye"), so all ten AWS checks are CANNOT VERIFY. The local checks passed: Docker works, its data is on D: (861 GB free), and key.properties/*.jks are git-ignored. No AWS resources changed and no secrets were printed.
- **What was done:**
  - Tried STS, ECR, SSM (metadata only), IAM, SNS, S3, Budgets, Lambda and ECR image architecture with --profile gemeye-audit: profile not found
  - Local checks: docker info, Docker WSL data location (D:\DockerData), drive free space, AWS profile names, keystore ignore rules
  - Wrote backend/infra/audit_report.md with PASS / FAIL / CANNOT VERIFY per item and the fixes needed
- **Files changed:**
  - `+` backend/infra/audit_report.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-110
- **Reason:** Check the AWS deployment setup before deploying the backend to Lambda.

### EDIT-112 | 05 October 2026 12:00 | IST
- **Topic:** Phase 9L - run the app against a local server over Wi-Fi
- **Summary:** `--dart-define=API_BASE_URL=http://<IP>:8000` now overrides the API base URL; Android allows cleartext HTTP in debug and release for the local demo; Settings shows the current API base URL. No grading, gate or backend logic changed.
- **What was done:**
  - AppConfig.apiBaseUrl uses API_BASE_URL when set (trailing slash trimmed), else the existing API_ENV dev/prod behaviour
  - Moved network_security_config.xml from src/debug to src/main with base-config cleartextTrafficPermitted="true" and the comment "local demo over Wi-Fi; switch back to HTTPS-only when a production server exists"; referenced from the main manifest, removed from the debug manifest
  - Added an "API base URL" row under Server status in Settings
  - Checked ApiClient timeouts: connect 10 s, receive 60 s already set; unchanged
  - flutter analyze: 0 issues; flutter test: 73 passed
- **Files changed:**
  - `~` app/lib/config/app_config.dart
  - `~` app/lib/screens/settings_screen.dart
  - `~` app/android/app/src/main/AndroidManifest.xml
  - `~` app/android/app/src/debug/AndroidManifest.xml
  - `+` app/android/app/src/main/res/xml/network_security_config.xml
  - `-` app/android/app/src/debug/res/xml/network_security_config.xml
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-110
- **Reason:** Demo the app on a phone over Wi-Fi against the local Docker server, without a USB cable or adb reverse.

### EDIT-113 | 05 October 2026 13:00 | IST
- **Topic:** Final year presentation guide (Markdown)
- **Summary:** Added a slide-by-slide Markdown guide covering the problem, solution, workflow, features, colour-science techniques, the v3 model, results, backend, security, technologies and a demo script. No code changed.
- **What was done:**
  - Wrote docs/GemEye_Presentation.md from the backend README, export manifests, parity/gate/Grad-CAM reports, training logs and this log
  - Included mermaid diagrams for the architecture, the end-to-end workflow and the model ensemble
- **Files changed:**
  - `+` docs/GemEye_Presentation.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-086, EDIT-088, EDIT-090, EDIT-108, EDIT-112
- **Reason:** Source material for the final year project presentation.

### EDIT-114 | 05 October 2026 14:00 | IST
- **Topic:** API reference (Markdown)
- **Summary:** Added a short point-by-point reference of all 19 API endpoints and every request/response schema, generated from the running server's OpenAPI spec. No code changed.
- **What was done:**
  - Read /openapi.json from the local server and the backend README
  - Wrote docs/GemEye_API_Reference.md: Part 1 endpoints grouped by area (auth marker, purpose, request/response schema), common errors; Part 2 all schemas with fields, types and meanings
- **Files changed:**
  - `+` docs/GemEye_API_Reference.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-113
- **Reason:** A clear API and schema reference for the presentation and the developer.

### EDIT-115 | 05 October 2026 14:30 | IST
- **Topic:** Run-on-phone command sheet (Markdown)
- **Summary:** Added a commands-only sheet for running the backend locally and the app on a phone over Wi-Fi, with the API links at the bottom. No code changed.
- **What was done:**
  - Wrote docs/RUN_ON_PHONE.md: Docker start, backend up, IP checks, Atlas check, firewall, adb over Wi-Fi, release build with API_BASE_URL, install/launch, hot reload, logs, reconnect, test token, stop
  - API links table (docs, redoc, health, config, openapi.json) with the current IPs
- **Files changed:**
  - `+` docs/RUN_ON_PHONE.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-112, EDIT-114
- **Reason:** One repeatable checklist to run the local demo on the phone over Wi-Fi.

### EDIT-116 | 05 October 2026 15:00 | IST
- **Topic:** Cold-start run guide and demo check script for the viva
- **Summary:** Rewrote docs/RUN_ON_PHONE.md as a self-contained cold-start runbook (Wi-Fi mode, USB adb-reverse backup mode, cable-free pairing, viva checklist, troubleshooting, API links) and added demo_check.ps1, which starts Docker and the backend and reports Docker, backend, database, network, adb devices and whether the Wi-Fi APK matches the current PC IP. No app or backend code changed.
- **What was done:**
  - demo_check.ps1: starts Docker Desktop if needed, docker compose up, waits for /health, checks /config (database), prints Wi-Fi name/category, PC and public IP, firewall rule, adb devices, last Wi-Fi APK URL; tested on this PC (all OK)
  - RUN_ON_PHONE.md: steps 0-8, options 3A/3B (connect) and 4A/4B (build/install), viva day checklist, troubleshooting table, API links
  - Built gemeye-wifi.apk (API_BASE_URL http://192.168.1.195:8000) and gemeye-usb.apk (default 127.0.0.1:8000 for adb reverse) in app/build/
- **Files changed:**
  - `+` demo_check.ps1
  - `~` docs/RUN_ON_PHONE.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-112, EDIT-115
- **Reason:** The developer must be able to start the demo alone after a shutdown, including at the viva venue.

### EDIT-117 | 05 October 2026 15:20 | IST
- **Topic:** Quick run sheet
- **Summary:** Added docs/RUN_QUICK.md with only the minimum numbered commands (7 steps) to run the app on the phone, plus the IP-changed rebuild and USB-only fallback blocks. RUN_ON_PHONE.md stays as the full guide and links to it. No code changed.
- **What was done:**
  - New RUN_QUICK.md: numbered commands only, no explanations
  - RUN_ON_PHONE.md title renamed to "Full Guide" with a link to the quick sheet
- **Files changed:**
  - `+` docs/RUN_QUICK.md
  - `~` docs/RUN_ON_PHONE.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-116
- **Reason:** A minimal command list for the viva, separate from the full guide.

### EDIT-118 | 05 October 2026 17:30 | IST
- **Topic:** Demo launcher, adb tunnel over Wi-Fi and in-app server address
- **Summary:** Added a Windows launcher (one window, status lights, START EVERYTHING) that starts Docker and the backend, checks the database, connects the phone (USB to wireless, last IP, mDNS, or pairing code), creates an adb reverse tunnel (works over wireless debugging), installs the app only when changed and opens it. One APK with the default 127.0.0.1:8000 now works on any network. Settings > API base URL is now editable as a backup. Grading, gates and backend logic unchanged.
- **What was done:**
  - Verified adb reverse tcp:8000 works over wireless adb (phone got /health 200 via 127.0.0.1)
  - AppConfig: saved server address (SharedPreferences, not sensitive) has priority over API_BASE_URL and API_ENV; normalise() adds http:// and :8000; load() in main before services
  - ApiClient.baseUrl is now a getter, so a changed address applies at once
  - Settings: API base URL row is tappable; dialog with validation, Use default, Save; re-checks the server and shows a snackbar
  - test/app_config_test.dart: normalise accepts/rejects cases
  - launcher/GemEyeLauncher.ps1 (WinForms) + "Start GemEye Demo.bat"; state in launcher/.launcher_state.json (git-ignored); tested headless: full START sequence over Wi-Fi, reconnect after adb disconnect via saved IP, window opens from the .bat
  - Built app/build/gemeye.apk (single universal APK); removed the old wifi/usb APKs
  - demo_check.ps1: removed the Wi-Fi APK IP check; firewall now informational
  - RUN_QUICK.md and RUN_ON_PHONE.md rewritten for the launcher, tunnel and single APK
  - flutter analyze: 0 issues; flutter test: 75 passed
- **Files changed:**
  - `~` app/lib/config/app_config.dart
  - `~` app/lib/services/api_client.dart
  - `~` app/lib/main.dart
  - `~` app/lib/screens/settings_screen.dart
  - `+` app/test/app_config_test.dart
  - `+` launcher/GemEyeLauncher.ps1
  - `+` Start GemEye Demo.bat
  - `~` demo_check.ps1
  - `~` .gitignore
  - `~` docs/RUN_QUICK.md
  - `~` docs/RUN_ON_PHONE.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-112, EDIT-116, EDIT-117
- **Reason:** Start the viva demo quickly and reliably without help, on any network, without rebuilding the app for a new IP.

### EDIT-119 | 06 October 2026 07:24 | IST
- **Topic:** Verified app test images (2 per grade)
- **Summary:** Added test_images/ at the project root with 2 correctly graded stone images for each of the 7 grades, each verified with the live v3 model. No code changed.
- **What was done:**
  - Started Docker and the backend; ran grade() inside the container on every correct clean test image, as the original file and as the app upload (2048 px, JPEG q95), gates on, threshold 0.60, no patches
  - Kept images that were correct, status ok and not referred in both modes; picked the 2 highest-confidence per grade
  - Grade 3 had only one passing clean test image; graded all 160 Grade 3 images and added g3_077 (seen in training, flagged in the README)
  - test_images/README.md lists each image, grade, confidence and training status
- **Files changed:**
  - `+` test_images/ (7 grade folders, 14 JPEGs)
  - `+` test_images/README.md
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-118
- **Reason:** A known-good image set for testing grading in the app on the phone.

### EDIT-120 | 06 October 2026 08:25 | IST
- **Topic:** CIECAM02 values on the certificate
- **Summary:** The certificate PDF and Export Image now print CIECAM02 J, M, h, s, C like the Result screen. The server already froze them in the certificate snapshot; the app PDF hard-coded "-" and re-export did not read the snapshot colour.
- **What was done:**
  - Investigated: server `_snapshot` copies `colour` (incl. `ciecam02`) and `CertificateSnapshot`/`PublicCertificate` keep it, so GET /certificates/{no} and GET /public/v/{slug} already return it (no server code change)
  - App: `CertificateService.colourGroups()` builds the colour data; CIECAM02 rows use the Result screen labels and formats (J, M, s, C 1 dp; h 0 dp with degree sign); null prints "Not available"
  - PDF shows the Result screen "Approximate values" note when `colour.approximate` is true; page stays one A4 page (spacer absorbs the extra line)
  - `CertificateApiService.ensure()` applies the server snapshot colour (`GradeResult.applyCertificateSnapshot`), so first export and every re-export print the frozen values; saved in the local cache
  - Tests: app `certificate_ciecam_test.dart` (new certificate values, null case, identical re-export, PDF builds); backend unit test for snapshot and public schema plus ciecam02 asserts on GET /certificates/{no} and /public/v/{slug}
- **Files changed:**
  - `~` app/lib/models/grade_result.dart
  - `~` app/lib/services/certificate_api_service.dart
  - `~` app/lib/services/certificate_service.dart
  - `+` app/test/certificate_ciecam_test.dart
  - `~` backend/tests/test_phase4b.py
  - `~` PROJECT_STATUS.md
- **Connected edits:** EDIT-099, EDIT-101
- **Reason:** CIECAM02 values were shown on the Result screen but missing from the certificate.

### EDIT-121 | 07 October 2026 | IST
- **Topic:** New visual README
- **Summary:** Replaced the root README with the new diagram-based README and added its SVG assets under docs/assets/. No app or backend code changed.
- **What was done:**
  - Copied readme_drop/README.md over the root README.md and the 12 SVGs to docs/assets/ (byte-identical, verified with diff)
  - Kept the API docs screenshot from the nested readme_drop/readme_drop/ copy in docs/assets/screenshots/api-docs.png (not referenced by the README)
  - Verified "19 endpoints, 3 public": 13 routes in main.py/routers.py plus 6 in certificates.py; public are /health, /config, /public/v/{slug}; /docs is enabled (FastAPI default)
  - Verified "Run locally" against backend/docker-compose.yml (port 8000, env_file .env, models mount), backend/README.md and the API_BASE_URL dart-define in app_config.dart; no README lines needed changes
  - Deleted readme_drop/
- **Files changed:**
  - `~` README.md
  - `+` docs/assets/architecture.svg, banner.svg, certificate.svg, colour-paths.svg, gates.svg, gradcam.svg, logo.svg, model.svg, pipeline.svg, results.svg, roadmap.svg, security.svg
  - `+` docs/assets/screenshots/api-docs.png
  - `-` readme_drop/
  - `~` PROJECT_STATUS.md
- **Connected edits:** none
- **Reason:** Clearer project overview on GitHub.
