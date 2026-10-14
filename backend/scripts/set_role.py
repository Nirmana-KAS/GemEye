"""Sets the Firebase custom claim for an admin-dashboard role.

    docker compose exec api python scripts/set_role.py --email <email> --role admin|reviewer|none

Works in development and production; refuses ENV=test so test and real accounts never
mix. Prints only the result. The user must sign in again (or refresh the ID token) for
the new claim to appear."""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from firebase_admin import auth  # noqa: E402

from app.auth import init_firebase  # noqa: E402
from app.config import get_settings  # noqa: E402

ROLES = ("admin", "reviewer", "none")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--email", required=True)
    p.add_argument("--role", required=True, choices=ROLES)
    a = p.parse_args()
    s = get_settings()
    if s.env == "test":
        print("Refused: ENV=test must not be used to set roles on real accounts.")
        return 2
    init_firebase(s.firebase_credentials)
    try:
        user = auth.get_user_by_email(a.email)
    except auth.UserNotFoundError:
        print("No Firebase user with that email.")
        return 1
    claims = {k: v for k, v in (user.custom_claims or {}).items() if k not in ("admin", "reviewer")}
    if a.role != "none":
        claims[a.role] = True
    auth.set_custom_user_claims(user.uid, claims or None)
    auth.revoke_refresh_tokens(user.uid)
    print(f"ENV={s.env}: role for {a.email} set to {a.role}. Sign in again to apply.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
