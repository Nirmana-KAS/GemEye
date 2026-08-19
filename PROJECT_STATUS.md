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