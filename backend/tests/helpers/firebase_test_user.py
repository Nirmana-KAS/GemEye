"""Temporary Firebase test users for tests and the parity/gate scripts.

    with FirebaseTestUser() as u:
        headers = u.headers          # {"Authorization": "Bearer <ID token>"}

Creates a user with a random email and password (admin SDK), signs in through the
Identity Toolkit REST API (signInWithPassword, FIREBASE_WEB_API_KEY) and deletes the
user on exit. The API key is sent in a header, never in a URL, and never logged."""
import json
import secrets
import time
import urllib.request
import uuid

from firebase_admin import auth

from app.auth import init_firebase
from app.config import get_settings

SIGN_IN_URL = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
TOKEN_MAX_AGE_S = 50 * 60     # ID tokens expire after 1 hour


class FirebaseTestUser:
    def __init__(self):
        settings = get_settings()
        if not settings.firebase_web_api_key:
            raise RuntimeError("FIREBASE_WEB_API_KEY is missing")
        init_firebase(settings.firebase_credentials)
        self._api_key = settings.firebase_web_api_key.get_secret_value()
        self.email = f"gemeye-test-{uuid.uuid4().hex[:12]}@example.com"
        self._password = secrets.token_urlsafe(24)
        self.uid = auth.create_user(email=self.email, password=self._password).uid
        self._token, self._issued = None, 0.0

    def _sign_in(self):
        body = json.dumps({"email": self.email, "password": self._password,
                           "returnSecureToken": True}).encode()
        req = urllib.request.Request(SIGN_IN_URL, data=body, method="POST", headers={
            "Content-Type": "application/json", "X-Goog-Api-Key": self._api_key})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                self._token = json.loads(r.read())["idToken"]
        except Exception as e:
            raise RuntimeError(f"signInWithPassword failed ({type(e).__name__})") from None
        self._issued = time.monotonic()

    @property
    def token(self):
        if self._token is None or time.monotonic() - self._issued > TOKEN_MAX_AGE_S:
            self._sign_in()
        return self._token

    @property
    def headers(self):
        return {"Authorization": f"Bearer {self.token}"}

    def delete(self):
        try:
            auth.delete_user(self.uid)
        except auth.UserNotFoundError:
            pass

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.delete()


def purge_user_data(uid):
    """Deletes a test user's MongoDB records and S3 images in the current ENV
    (used by the parity and gate scripts, which run against the dev server)."""
    from app.db import Database
    from app.storage import Storage

    s = get_settings()
    if s.is_production:
        raise RuntimeError("refusing to purge in production")
    secret = lambda v: v.get_secret_value() if v else None  # noqa: E731
    db = Database(secret(s.mongodb_uri), s.db_name)
    try:
        n = {c: getattr(db, c).delete_many({"uid": uid}).deleted_count
             for c in ("gradings", "rejections", "calibrations")}
        n["users"] = db.users.delete_one({"_id": uid}).deleted_count
    finally:
        db.close()
    st = Storage(s.s3_bucket, s.aws_region, secret(s.aws_access_key_id),
                 secret(s.aws_secret_access_key), s.s3_prefix)
    n["s3_objects"] = st.delete_prefix(f"gradings/{uid}/")
    return n
