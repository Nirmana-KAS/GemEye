"""Prints a Firebase ID token for a QA account, for testing the API from /docs
(Authorize → paste the token). Local development only; never use it in production.

    docker compose exec api python scripts/get_token.py --email qa@example.com

The password is prompted without echo and is never printed or stored. The token
is valid for 1 hour."""
import argparse
import getpass
import json
import sys
import urllib.error
import urllib.request

sys.path.insert(0, ".")
from app.config import get_settings  # noqa: E402

SIGN_IN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"


def main():
    parser = argparse.ArgumentParser(description="Print a Firebase ID token for a QA account.")
    parser.add_argument("--email", required=True)
    args = parser.parse_args()
    settings = get_settings()
    if settings.is_production:
        sys.exit("Refusing to run with ENV=production.")
    if not settings.firebase_web_api_key:
        sys.exit("FIREBASE_WEB_API_KEY is missing.")
    password = getpass.getpass("Password: ")
    body = json.dumps({"email": args.email, "password": password,
                       "returnSecureToken": True}).encode()
    req = urllib.request.Request(SIGN_IN_URL, data=body, method="POST", headers={
        "Content-Type": "application/json",
        "X-Goog-Api-Key": settings.firebase_web_api_key.get_secret_value()})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            token = json.loads(r.read())["idToken"]
    except urllib.error.HTTPError as e:
        try:
            reason = json.loads(e.read())["error"]["message"]
        except Exception:
            reason = f"HTTP {e.code}"
        sys.exit(f"Sign-in failed: {reason}")
    except Exception as e:
        sys.exit(f"Sign-in failed ({type(e).__name__})")
    print(token)


if __name__ == "__main__":
    main()
