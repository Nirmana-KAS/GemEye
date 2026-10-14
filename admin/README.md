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
| `npm test` | Vitest unit tests (`tests/`: API client errors, role guard) |
| `npm run build` | Static export to `out/` |

## Structure

- `app/admin/login/` - Google and email sign-in; only `admin` / `reviewer` claims get in
- `app/admin/(dash)/` - pages behind `RoleGuard` (Overview, Users, Gradings, Calibrations; other sections are placeholders for later phases)
- Detail pages use query strings (`/admin/users/detail/?uid=...`, `/admin/gradings/detail/?id=...`) because a static export has no runtime dynamic routes
- `lib/api.ts` - typed fetch client (Bearer token, one retry with a fresh token on 401, `{code, message}` errors as toasts, cursor paging)
- `lib/roles.ts` - claims to role, menu per role, guard decision
- `lib/types.ts` - API response types (`docs/GemEye_API_Reference.md`)

Roles: admins see everything; reviewers see Gradings (no user emails) and the Review queue.
A 401 signs the user out; a 403 shows "No access".

## Deploy

Planned for Phase 10g: Firebase Hosting (`https://gemeye-app-2026.web.app/admin`), public
directory `admin/out`, after the API is deployed on AWS (an HTTPS page cannot call the local
HTTP API). Set `NEXT_PUBLIC_API_BASE_URL` to the API Gateway URL before `npm run build`.
