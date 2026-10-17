# GemEye Admin Dashboard

Next.js (App Router, static export) web app for administrators and gemologist reviewers.
It reads and changes data only through the GemEye API (`/admin/*`); it holds no secrets.

## Setup

```bash
cd admin
npm install
cp .env.local.example .env.local   # then fill in the values (see below)
```

`.env.local` (git-ignored):

| Variable | Value |
|---|---|
| `NEXT_PUBLIC_API_BASE_URL` | `http://localhost:8000` (local Docker API) |
| `NEXT_PUBLIC_FIREBASE_*` | Public Firebase web config of project `gemeye-app-2026` (same values as the `web` entry in `app/lib/firebase_options.dart`) |

Sign-in needs an account with the `admin` or `reviewer` custom claim, set with
`backend/scripts/set_role.py` (see `backend/README.md`).

## Run

```bash
# API first
cd backend && docker compose up -d
# Dashboard
cd admin && npm run dev        # http://localhost:3000/admin/
```

## Checks

| Command | What |
|---|---|
| `npm run lint` | ESLint |
| `npm run typecheck` | TypeScript (strict) |
| `npm test` | Vitest unit tests (`tests/`: API client errors, role guard, notifications, review form schema, agreement / confusion and monitoring helpers, config form bounds and diff, announcement status, send-notification schema, feedback trend, audit diff, bulk selection and typed-confirm rules, daily limit and profile helpers, verify page slug / state / SHA-256 compare) |
| `npm run build` | Static export to `out/` |

## Structure

- `app/admin/login/` - Google and email sign-in; only `admin` / `reviewer` claims get in
- `app/admin/(dash)/` - pages behind `RoleGuard`: Overview, Users, Gradings, Review queue, Model monitoring, Calibrations, App control, Announcements, Notifications, Feedback, Certificates, Audit log (all built; only Gradings and Review queue are open to reviewers, the rest show "No access")
- Review queue (admin and reviewer): table of referred stones (filter pending / reviewed by me / all reviewed, model version, dates; cursor paging). Clicking a row opens the review panel: zoomable photo, Grad-CAM, model grade, probabilities and colour values, and a react-hook-form + zod form (true grade 1-7 as GEMCLOUD colour chips, reviewer confidence, "not a blue sapphire / unusable photo", notes up to 500). Keys `1`-`7` pick the grade and `Enter` saves (`Ctrl+Enter` from the notes box); "Save and next" opens the next pending stone. Reviewers edit only their own reviews. Admins also see the statistics card (agreement and the model vs gemologist confusion heatmap) and "Export reviewed as training labels" (CSV)
- Model monitoring (admin): 7 / 30 / 90 days and a model version selector; KPI cards per version, charts for confidence and uncertainty, referral rate, rejections per gate, latency (avg and p95) and review agreement, and a side-by-side table when two versions (v3 and v5) have gradings
- App control (Phase 10f): sections Grading, Calibration, App version (minimum version + update message), Feature switches, Gate thresholds (value, server bounds, default, "changed" badge) and Maintenance. react-hook-form + zod built from the bounds `GET /admin/config` returns, so out-of-bounds values cannot be saved; server field errors (`fields`, `invalid_gates`) are shown on the field. Save opens an old -> new diff dialog and sends only the changed fields; turning maintenance on needs typed `MAINTENANCE`; "Reset gates to defaults" asks first
- Announcements: table (title, status active / scheduled / expired / draft, start, end, link, created by), create / edit dialog (title <= 80, message <= 500, level, start, end, in-app action link, save as draft, "Also send as notification to all users") with a preview of the app Home banner; delete asks first
- Notifications: "Send" (one user by email search, or all users; the confirm shows the recipient count), "Sent history" (broadcasts) and "All notifications" (filters status / source / user / dates; a row opens the user's Notifications tab). User detail has a "Send notification" button with the user preselected
- Feedback: filters (status, category, rating, dates), weekly count + average rating chart, resolve / reopen with an optional note (<= 300), CSV export
- Certificates: search by number prefix or user email, status filter (valid / revoked / superseded / withdrawn); detail with snapshot, photo, colour values, PDF link + SHA-256 and the verify URL with the token masked; Revoke (reason + typed certificate number) and Supersede (reason + new number)
- Audit log (read only): filters action, admin email, target id, dates; click a row for the before / after field diff; CSV export
- Admin powers (Phase 10p):
  - User detail: "Admin actions" menu with Force sign-out (typed `SIGN OUT` on your own account, which also signs you out of the dashboard), Edit profile (name, phone, company; app limits; email not editable) and Daily limit (1-500 or empty); tabs Activity (timeline with "Load more") and Notes (admin only, add / delete); Devices list with Blocked chip and Block (reason + typed `BLOCK`) / Unblock (reason)
  - Gradings: row checkboxes (header = this page, max 200 across pages) and a bulk bar: Hide (reason + typed `HIDE n`), Restore, Send to review, Export CSV (server CSV of the selected rows); "Visibility" filter (all / visible in app / hidden) and a "Hidden" chip
  - Grading detail: Hide / Restore, Send to review (note optional), Re-grade (original vs re-grade table with probabilities), Certificate menu (Revoke / Supersede, the same dialogs as the Certificates page, `components/certificate-actions.tsx`) and Delete permanently (reason + typed grading id); hidden banner with reason and admin
  - Calibrations: "Invalidate" per session (reason + typed session id); reset sessions show a "Reset" chip
  - App control: "Daily grading limit" default (empty = no limit)
- `lib/admin-powers.ts` - selection, confirm, bulk summary, daily limit and profile helpers (pure, unit tested in `tests/admin-powers.test.ts`)
- `lib/config.ts`, `lib/announcements.ts`, `lib/send-notification.ts`, `lib/feedback.ts`, `lib/audit.ts` - form schemas and helpers (pure, unit tested)
- `lib/reviews.ts` (review form schema, agreement and confusion helpers) and `lib/monitoring.ts` (chart shaping) are pure and unit tested
- Detail pages use query strings (`/admin/users/detail/?uid=...&tab=notifications`, `/admin/gradings/detail/?id=...`, `/admin/certificates/detail/?no=...`) because a static export has no runtime dynamic routes
- `lib/api.ts` - typed fetch client (Bearer token, one retry with a fresh token on 401, `{code, message}` errors as toasts, cursor paging)
- `lib/roles.ts` - claims to role, menu per role, guard decision
- `lib/types.ts` - API response types (`docs/GemEye_API_Reference.md`)

Roles: admins see everything; reviewers see Gradings (no user emails) and the Review queue.
A 401 signs the user out; a 403 shows "No access".

## Public verify page (Phase 10g)

`/v/?c={cert}-{token}` (also `/v/{cert}-{token}`) is the QR target: no login, no sidebar, no
Firebase code (the auth providers are in `app/admin/layout.tsx` only), mobile first. It calls
`GET /public/v/{slug}` and shows Valid (green), Revoked (red, reason + date), Superseded (amber,
"Replaced by" with a link when the server returns `superseded_by_url`), Withdrawn (grey),
Not found (unknown number or wrong token) or "Cannot reach GemEye" with Try again (also for 429).
Valid shows the number, issue date, GEMCLOUD grade chip and description, stone photo, colour
values, model version, "Reviewed by gemologist: Grade N" when reviewed, the PDF link with its
SHA-256 and "Check file" (hashes the PDF in the browser; if the storage link refuses a browser
read, "Check a downloaded file" hashes a file the user picks) and the certificate disclaimer.
It never shows the owner's email or uid.

- `/v/{slug}` works through the Firebase rewrite `/v/** -> /v/index.html` (`firebase.json`); without
  it (`npm run dev`, or a host without rewrites) `app/not-found.tsx` sends `/v/{slug}` to `/v/?c={slug}`
- Helpers in `lib/verify.ts` (slug parsing, state mapping, SHA-256 compare), tested in `tests/verify.test.ts`

### Test with a phone on the same Wi-Fi

New certificates put `verify_base_url` (remote config) in the QR link; existing ones keep theirs.

1. Find the laptop's LAN IP: `ipconfig` -> "IPv4 Address", e.g. `192.168.1.20`
2. `admin/.env.local`: `NEXT_PUBLIC_API_BASE_URL=http://192.168.1.20:8000` (the phone cannot reach `localhost`)
3. Run the dashboard on all interfaces: `npm run dev -- -H 0.0.0.0` (LAN origins `192.168.*.*` and
   `10.*.*.*` are allowed in `next.config.ts`). Allow Node.js through the Windows firewall (private network)
4. App control -> Certificate verification -> Verify page base URL = `http://192.168.1.20:3000` -> Save.
   The server accepts http only for localhost and private LAN IPs, and then also allows that origin
   (CORS) on `/public/v/`
5. Issue a new certificate in the app and scan its QR code with the phone
6. Afterwards set it back to `https://gemeye-app-2026.web.app`

## Deploy (after AWS)

Not possible yet for live data: an HTTPS page cannot call the local HTTP API (mixed content).
Hosting files are ready: `firebase.json` (public `out`, rewrites `/admin/** -> /admin/index.html`
and `/v/** -> /v/index.html`, `_next/static` cached for a year, HTML `no-cache`, nosniff /
no-referrer / DENY framing headers) and `.firebaserc` (project `gemeye-app-2026`).

After the API is deployed on AWS:

1. `admin/.env.local`: `NEXT_PUBLIC_API_BASE_URL=https://<api-id>.execute-api.ap-south-1.amazonaws.com`
2. App control: Verify page base URL = `https://gemeye-app-2026.web.app`
3. Backend: the public origins already include `https://gemeye-app-2026.web.app`
4. `npm i -g firebase-tools` and `firebase login` (gemeyeapp@gmail.com), once
5. `cd admin && npm run build` (static export to `out/`)
6. `firebase deploy --only hosting` -> https://gemeye-app-2026.web.app/admin/ and `/v/...`
