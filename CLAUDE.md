# GemEye — Project Instructions for Claude Code

> **This file is read automatically by Claude Code. It contains all project decisions, standards, and rules. Follow everything here strictly. Do not guess or assume anything not documented here.**

---

## PROJECT OVERVIEW

- **App Name:** GemEye
- **Purpose:** Automated colour grading of 1–5 mm cut and polished blue sapphires into 7 GEMCLOUD colour grades
- **Student:** Nirmana K.A.S. | Student No: 28973 | NSBM Green University | BSc (Hons) Computer Science
- **Internship Company:** Orava (Pvt) Ltd., Sri Lanka
- **Platform:** Flutter (Android + iOS cross-platform)
- **Total Screens:** 16
- **Development OS:** Windows 10/11

---

## COLOUR SCHEME (STRICT — NO EXCEPTIONS)

| Name | Hex | Usage |
|------|-----|-------|
| Primary (Royal Blue) | `#1B3A8C` | Headers, buttons, active states, nav, badges |
| Primary Light | `#3B5FD9` | Gradients, hover/pressed states |
| Primary Surface | `#EEF1FA` | Input backgrounds, selected chips, highlights |
| Background | `#FFFFFF` | ALL screen backgrounds — ALWAYS white |
| Card | `#FFFFFF` | All card surfaces — ALWAYS white |
| Text Primary | `#1A1D2E` | Headings, body text |
| Text Secondary | `#6B7089` | Descriptions, secondary info |
| Text Muted | `#A0A4B8` | Placeholders, timestamps, disabled |
| Border | `#E5E7F0` | Card borders, dividers, input outlines |
| Success | `#10B981` | Calibrated, high confidence, checkmarks |
| Warning | `#F59E0B` | Medium confidence, warnings |
| Error | `#EF4444` | Low confidence, errors, danger actions |

**RULES:**
- Background is ALWAYS `#FFFFFF` — never grey, never dark
- NO dark mode — light mode only. Never add dark mode code.
- Royal Blue `#1B3A8C` is the ONLY brand colour
- Cards: white background with `#E5E7F0` 1px border — never coloured backgrounds
- Use the `GemEyeColors` class from `lib/config/theme.dart` — never hardcode hex values

---

## TYPOGRAPHY (STRICT)

| Role | Font Family | Weights | Dart Constant |
|------|------------|---------|---------------|
| Headings | Poppins | SemiBold (600), Bold (700) | `GemEyeFonts.heading` |
| Body text | Inter | Regular (400), Medium (500) | `GemEyeFonts.body` |
| Colour values only | JetBrains Mono | Regular (400) | `GemEyeFonts.mono` |

**Font size scale:**
- Screen title: 20px Poppins SemiBold
- Section header: 16px Poppins SemiBold
- Body: 14px Inter Regular
- Secondary: 12px Inter Regular
- Caption: 11px Inter Regular
- Colour values: 12px JetBrains Mono Regular
- Button: 14px Poppins SemiBold
- Nav label: 11px Inter Medium

**RULES:**
- Always use `GemEyeFonts.heading`, `GemEyeFonts.body`, `GemEyeFonts.mono` — never hardcode font names
- Never use the default Flutter font
- JetBrains Mono is ONLY for numeric colour values (L*=42.3, Hue=228°, ΔE₀₀=1.2)

---

## GRADING SYSTEM (7 GEMCLOUD GRADES)

| Grade | Name | Trade Name | Hex |
|-------|------|-----------|-----|
| 1 | Dark | Midnight Blue | `#020519` |
| 2 | Deep | Twilight Blue | `#0B0F3F` |
| 3 | Vivid | Royal Blue | `#091A72` |
| 4 | Intense | Intense Cornflower | `#2A408C` |
| 5 | Medium Intense | Cornflower Blue | `#47619E` |
| 6 | Light | Pastel Blue | `#718BB7` |
| 7 | Very Light | Near-Colourless | `#ABBDD6` |

- Always 7 grades — never 10, never any other number
- Always dark to light (Grade 1 = darkest, Grade 7 = lightest)
- Always use GEMCLOUD standard names
- Grade data is stored in `assets/data/colour_grades.json`

---

## 16 SCREENS

| # | Screen | File Name | Notes |
|---|--------|-----------|-------|
| 1 | Splash | splash_screen.dart | Lottie animation, 3s timer, no university name |
| 2 | User Agreement | agreement_screen.dart | Must accept to proceed, checkbox + button |
| 3 | Login/Register | login_screen.dart, register_screen.dart | Google Sign-In + Email, Individual + Company types |
| 4 | Onboarding | onboarding_screen.dart | 4 slides, PageView, first login only |
| 5 | Home Dashboard | home_screen.dart | Greeting, calibration banner, quick grade, stats, recent |
| 6 | Calibration Wizard | calibration_screen.dart | 3-step wizard, CCC card detection |
| 7 | Capture | capture_screen.dart | Camera, blur check, light level, crop after capture |
| 8 | Processing | processing_screen.dart | Lottie animation, 7-step progress |
| 9 | Grade Result | result_screen.dart | Grade badge, confidence, Grad-CAM, colour values |
| 10 | Certificate PDF | (generated via pdf package) | A4, unique GE-YYYYMM-NNNNN number |
| 11 | Grading History | history_screen.dart | Search, filter, sort, certificate tracking |
| 12 | Colour Guide | guide_screen.dart | 7 grades reference, offline |
| 13 | Stone Comparison | comparison_screen.dart | Side-by-side, ΔE₀₀ |
| 14 | Settings | settings_screen.dart | 14 settings items |
| 15 | About | about_screen.dart | App, developer, NSBM (3), Orava (6) |
| 16 | Privacy Policy | privacy_screen.dart | Read-only, from markdown file |

---

## NAVIGATION

**Bottom Navigation Bar (4 tabs):**
1. Home (`Icons.home_rounded`) → home_screen.dart
2. Grade (`Icons.camera_alt_rounded`) → capture_screen.dart
3. History (`Icons.history_rounded`) → history_screen.dart
4. Guide (`Icons.palette_rounded`) → guide_screen.dart

- NO Settings tab in bottom nav — Settings is in side drawer only
- Active tab: Royal Blue icon + label, scale animation (1.0→1.15)
- Inactive: grey icon + label
- Page transition: FadeTransition

**Right Side Drawer (11 items):**
1. Profile section (photo + name + email)
2. Home
3. Grade a Stone
4. Grading History
5. Colour Grade Guide
6. Stone Comparison
7. Settings
8. Feedback
9. Privacy Policy
10. About
11. Logout

---

## BACKEND ARCHITECTURE

| Service | Purpose | Connection |
|---------|---------|-----------|
| Firebase Auth | User login (Google + Email) | `firebase_auth` + `google_sign_in` packages |
| MongoDB Atlas M0 | User data, grades, certificates, feedback | Via HTTP API (REST) — NOT direct mongo_dart driver |
| AWS Lambda | ML inference pipeline | HTTPS POST via `http` package |
| AWS API Gateway | REST endpoint for Lambda | Base URL in `AppConstants.apiBaseUrl` |
| AWS S3 | User stone images, model files | Via presigned URLs or `http` package |

**IMPORTANT:** Do NOT use `mongo_dart` package directly from Flutter. Instead, create a simple REST API (Node.js or Python Flask on Lambda or EC2) that Flutter calls via HTTP. This is more secure and avoids exposing MongoDB connection strings in the app.

---

## CERTIFICATE SYSTEM

- Pattern: `[PREFIX]-[YYYYMM]-[NNNNN]`
- Default prefix: `GE`
- Example: `GE-202608-00042`
- Each stone gets a certificate number on FIRST export only
- Re-export reuses the SAME certificate number — never generates a new one
- Certificate number stored in MongoDB `grades` collection
- Exported stones show badge "📄 GE-202608-00042" in history

---

## CODING STANDARDS

### Dart/Flutter:
- Use `UpperCamelCase` for classes, enums, typedefs
- Use `lowerCamelCase` for variables, functions, parameters
- Use `snake_case` for file names
- Use `UPPER_SNAKE_CASE` for constants
- Always use `const` constructors where possible
- Always add `const` to widget constructors: `const MyWidget({super.key})`
- Use `StatelessWidget` by default. Use `StatefulWidget` only when state is needed.
- Use `provider` for state management
- Every screen widget goes in `lib/screens/`
- Every reusable widget goes in `lib/widgets/`
- Every data model goes in `lib/models/`
- Every service (API, auth, storage) goes in `lib/services/`
- Every provider goes in `lib/providers/`
- Config files go in `lib/config/`

### File naming:
- Screens: `[name]_screen.dart`
- Widgets: `[name]_widget.dart` or descriptive name like `grade_badge.dart`
- Models: `[name]_model.dart`
- Services: `[name]_service.dart`
- Providers: `[name]_provider.dart`

### Error handling:
- Always wrap API calls in try-catch
- Show user-friendly error messages via SnackBar or AlertDialog
- Never show raw error messages to user
- Log errors to console in debug mode

### Responsive design:
- Use `MediaQuery` and `LayoutBuilder` for adaptive sizing
- Test width range: 360px to 428px
- Bottom nav must be safe-area aware
- Use `SafeArea` widget on all main screens

---

## NOTIFICATION IDs

When implementing notifications, use these exact IDs:
- Authentication: A1–A10
- Profile: P1–P5
- Calibration: C1–C5
- Grading: G1–G9
- Certificate: X1–X6
- Data Management: D1–D4
- Privacy: R1–R2

Refer to the full notification table in the development plan for exact messages.

---

## GREETING MESSAGE RULES

- Top of Home Dashboard
- Format: "Good Morning, Nirmana" (every word capitalised)
- Time rules (user's local timezone):
  - 00:00–11:59 → "Good Morning"
  - 12:00–16:59 → "Good Afternoon"
  - 17:00–23:59 → "Good Evening"
- First name from Firebase Auth displayName or registration

---

## THINGS TO NEVER DO

1. Never use dark mode or dark backgrounds
2. Never use more than 7 grades
3. Never hardcode colours — always use GemEyeColors class
4. Never hardcode fonts — always use GemEyeFonts class
5. Never put Settings in the bottom navigation bar (it goes in the side drawer only)
6. Never use `mongo_dart` directly from Flutter — use HTTP API
7. Never show student number on the About screen
8. Never show university name on the Splash screen
9. Never generate a new certificate number for a previously exported stone
10. Never use localStorage or SharedPreferences for sensitive data — use flutter_secure_storage
11. Never allow the app to proceed without privacy policy acceptance
12. Never use glossy/gradient backgrounds on cards
13. Never use emojis in code comments (use them only in UI where specified)
14. Never skip error handling on API calls
15. Never use `print()` for logging — use `debugPrint()` in debug mode

---

## PROJECT FILE STRUCTURE

```
GemEye/
├── CLAUDE.md              ← THIS FILE (project instructions)
├── PROJECT_STATUS.md      ← Development log
├── README.md
├── .gitignore
├── app/                   ← Flutter project
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/        ← theme.dart, constants.dart, routes.dart
│   │   ├── models/        ← data models
│   │   ├── providers/     ← state management
│   │   ├── services/      ← API, auth, storage services
│   │   ├── screens/       ← all 16 screens
│   │   └── widgets/       ← reusable widgets
│   ├── assets/
│   │   ├── images/
│   │   ├── animations/    ← Lottie JSON files
│   │   ├── fonts/         ← 5 font files
│   │   └── data/          ← colour_grades.json, privacy_policy.md
│   └── pubspec.yaml
├── backend/               ← Python Lambda code
│   ├── handler.py
│   ├── preprocessing.py
│   ├── inference.py
│   ├── gradcam.py
│   ├── Dockerfile
│   └── models/
├── model/                 ← Training notebooks
├── docs/                  ← Dissertation
└── dataset/               ← .gitignored (images)
```

---

## MANDATORY RULES FOR EVERY TASK

### Rule 1 — Always update PROJECT_STATUS.md
After completing ANY task (creating files, fixing bugs, adding features, editing code), you MUST append a new EDIT entry to PROJECT_STATUS.md with:
- Sequential EDIT number (EDIT-002, EDIT-003, etc.)
- Current date and time
- Topic (short title)
- Summary (1-2 sentences)
- What was done (bullet list)
- Files changed (marked with + new, ~ modified, - deleted)
- Connected edits (reference previous related EDITs)
- Reason (why this edit was needed)
Never skip this. Never forget this. Do it as the LAST step of every task.

### Rule 2 — Always run flutter analyze after code changes
After modifying ANY Dart file, always run "flutter analyze" from the app/ directory and confirm zero issues before reporting completion. If issues are found, fix them before reporting.

---

## WHEN IN DOUBT

- Check this file first
- Check `lib/config/theme.dart` for colours
- Check `lib/config/constants.dart` for values
- Check `assets/data/colour_grades.json` for grade data
- If something is not documented here, ASK — do not guess
