# GemEye Admin Dashboard - Full Plan

Status: approved to start 13 October 2026, before v5 model training. The dashboard is model-independent: it reads data through the API and every grading carries `model_version` (v3 now, v5 later).

## 1. Goals

- One web dashboard to control and analyse the whole GemEye system.
- Only administrators (and gemologist reviewers) can sign in.
- Every change made from the dashboard is validated by the server and written to an audit log.
- The same Firebase Hosting site also serves the public certificate verification page (the QR target).

## 2. Technologies

| Layer | Choice | Why |
|---|---|---|
| Web framework | Next.js (App Router), TypeScript, static export (`output: "export"`) | Static files only, so it hosts free on Firebase Hosting; no server needed |
| UI | Tailwind CSS + shadcn/ui, GemEye Royal Blue theme | Clean admin components (tables, dialogs, forms) |
| Charts | Recharts | Simple React charts for the analytics pages |
| Tables | TanStack Table | Sorting, filtering, paging for users/gradings |
| Data fetching | TanStack Query | Caching, refresh, loading/error states |
| Forms / validation | react-hook-form + zod | Same limits as the server |
| Auth | Firebase Authentication (existing project gemeye-app-2026) + custom claims `admin` / `reviewer` | Same accounts system as the app; claims checked by the server on every request |
| Backend | Existing FastAPI server: new `/admin/*` routers | All data stays behind the API (MongoDB + S3) |
| Database | Existing MongoDB Atlas (new collections: reviews, announcements; audit_log extended) | - |
| Hosting | Firebase Hosting (free): `https://gemeye-app-2026.web.app` | Admin under `/admin`, public verify page under `/v/{cert}-{token}` |
| Push (optional, later) | Firebase Cloud Messaging | Announcements as phone notifications |
| Tests | pytest (server), Vitest/Playwright smoke tests (dashboard) | - |

Folder: `GemEye/admin/` (new folder in the same repository).

## 3. Roles and security

- Roles: `admin` (everything) and `reviewer` (gemologist: review queue and read-only gradings).
- Roles are Firebase custom claims, set only by `backend/scripts/set_role.py` (Admin SDK) - never from the app or dashboard UI without an existing admin.
- Every `/admin/*` request: verified ID token with `check_revoked=True`, claim check, rate limit, request-size limits.
- Ownership/visibility: admins see all data; reviewer sees only what the review queue needs (no emails or phone numbers).
- Every write: `audit_log` entry {action, target, before, after, admin_uid_hash, at}.
- CORS: dashboard origins only (`https://gemeye-app-2026.web.app`, `http://localhost:3000`).
- No secrets in the dashboard; it only holds the public Firebase web config.

## 4. Dashboard sections

| # | Section | What it shows / does | Server endpoints |
|---|---|---|---|
| 1 | Overview | Today and 7/30 days: gradings, active users, referral rate, rejection rate, average confidence, average latency, server/DB status; charts: gradings per day, grade distribution, confidence histogram, rejection reasons | `GET /admin/stats/summary`, `GET /admin/stats/timeseries` |
| 2 | Users | Search/filter, user detail (gradings, calibrations, last active, devices), disable/enable, set role, send password-reset email, delete user and data, CSV export | `GET /admin/users`, `GET /admin/users/{uid}`, `POST /admin/users/{uid}/disable|enable|role`, `DELETE /admin/users/{uid}` |
| 3 | Gradings | Table with filters (date, grade, referred, model version, user, device), detail with photo, all colour values, probabilities, Grad-CAM, certificate; CSV export | `GET /admin/gradings`, `GET /admin/gradings/{id}` |
| 4 | Review queue | Referred stones waiting for a gemologist; reviewer enters the true grade + notes; agreement statistics; export reviewed stones as new training labels | `GET /admin/review-queue`, `POST /admin/reviews`, `GET /admin/reviews/stats`, `GET /admin/reviews/export` |
| 5 | Model monitoring | Per model version: confidence and uncertainty over time, referral rate, rejection rate per gate, unusual-image warnings, agreement with reviews, latency; v3 vs v5 comparison | `GET /admin/model/monitoring` |
| 6 | App control | Edit remote config: referral threshold default, calibration validity hours, min app version, feature switches (repeatability, Grad-CAM, session mapping, public verification), gate thresholds within safe bounds, maintenance on/off + message | `GET /admin/config`, `PUT /admin/config` |
| 7 | Announcements | Create/schedule/expire messages shown in the app (Home banner + notification list); optional push later | `GET/POST/DELETE /admin/announcements`, public `GET /announcements` |
| 8 | Feedback inbox | Ratings, categories, comments; mark open/resolved; trends | `GET /admin/feedback`, `POST /admin/feedback/{id}/status` |
| 9 | Certificates | Search by number, view snapshot, revoke with reason, supersede (revoke + note new number) | `GET /admin/certificates`, `POST /admin/certificates/{no}/revoke` |
| 10 | Audit log | Every admin action, filter by action/date | `GET /admin/audit-log` |
| 11 | Calibrations | Calibration sessions, quality trend, devices | `GET /admin/calibrations` |
| P | Public verify page | `/v/{cert}-{token}`: Valid/Revoked/Withdrawn/Not found, snapshot, photo, PDF + SHA-256, disclaimer (no login) | existing `GET /public/v/{slug}` |

Gate thresholds: moved from constants in `gates.py` to `app_config.gates` with the current values as defaults and hard min/max bounds in code. Defaults keep parity results unchanged; any change is audited.

## 5. App changes connected to the dashboard

- Show active announcements (Home banner + Notifications).
- Show "Reviewed by gemologist: Grade N" on a stone after review (result screen and history).
- Disabled users get a clear "Account disabled" message.
- Remote config already read at start; add `announcements` and gate values (read-only in app).

## 6. Deployment

Local first (now), hosted later:

| Stage | Dashboard | API |
|---|---|---|
| Now (local) | `npm run dev` -> http://localhost:3000/admin | Local Docker http://localhost:8000 |
| Hosted, before AWS | Not possible for live data: a HTTPS page cannot call a local HTTP API (mixed content). Public verify page can be deployed but shows data only once the API is public |
| After AWS deployment | `npm run build` (static export) -> `firebase deploy --only hosting` -> https://gemeye-app-2026.web.app/admin | `https://<api-id>.execute-api.ap-south-1.amazonaws.com` |

Firebase Hosting setup (one time): `npm i -g firebase-tools`, `firebase login` (gemeyeapp@gmail.com), `firebase init hosting` (public dir `admin/out`, single-page rewrites for `/admin/**`, `/v/**`), `firebase deploy --only hosting`.

Environment: `admin/.env.local` -> `NEXT_PUBLIC_API_BASE_URL`, `NEXT_PUBLIC_FIREBASE_*` (public web config). Git-ignored.

## 7. Phases (Claude Code prompts)

| Phase | Work | Rough time |
|---|---|---|
| 10a | Server: roles + set_role script, `/admin/*` read endpoints (stats, users, gradings, calibrations, feedback, certificates, audit), audit logging, tests | 1 day |
| 10b | Server: admin writes (user disable/enable/role/delete, config editor with bounds incl. gates, maintenance, announcements, review endpoints + reviews collection, feedback status, certificate revoke), tests | 1 day |
| 10c | Dashboard shell: Next.js project, theme, Firebase login, role guard, layout (sidebar, top bar), API client, Overview page | 1 day |
| 10d | Users, Gradings (detail with photo + Grad-CAM), Calibrations | 1 day |
| 10e | Review queue + Model monitoring | 1 day |
| 10f | App control (config + maintenance), Announcements, Feedback, Certificates, Audit log | 1 day |
| 10g | Public verify page + Firebase Hosting setup; app changes (announcements, reviewed grade, disabled account) | 1 day |
| 10h | End-to-end test checklist, screenshots for thesis | 0.5 day |

Optional before 10c: design the screens with Claude Design (1440 px desktop, Royal Blue, sidebar) and give the export to Claude Code, as was done for the app.

## 8. Rules

- Claude Code never runs git; developer commits with GitHub Desktop.
- Every change -> PROJECT_STATUS.md entry.
- Never print secrets; admin claims only via the script.
- Model path, parity and default gate values must stay unchanged.
