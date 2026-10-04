"""Firebase ID token verification (FastAPI dependencies).

current_user: local signature check only (Google certs are cached), for reads.
current_user_strict: also checks revocation with Firebase.
active_user / active_user_strict: the same, for writes and user-creating requests, and
they also refuse uids of accounts deleted in the last 2 hours (401 account_deleted)."""
import hashlib
import logging

import firebase_admin
from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth, credentials

from app.errors import ApiError

logger = logging.getLogger("gemeye.auth")

_bearer = HTTPBearer(auto_error=False)
UNAUTHORISED = "Authentication required."
CLOCK_SKEW_S = 5    # tolerated difference between this server's clock and Google's


def init_firebase(credentials_path):
    """Initialise the default Firebase app once (no-op if already initialised)."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        return firebase_admin.initialize_app(credentials.Certificate(credentials_path))


def _verify(creds, check_revoked):
    """Any failure is a 401 with the same generic message."""
    if creds is None or creds.scheme.lower() != "bearer" or not creds.credentials:
        raise HTTPException(401, UNAUTHORISED)
    try:
        decoded = auth.verify_id_token(creds.credentials, check_revoked=check_revoked,
                                       clock_skew_seconds=CLOCK_SKEW_S)
    except Exception as e:
        logger.info("Token rejected: %s", type(e).__name__)
        raise HTTPException(401, UNAUTHORISED)
    return {
        "uid": decoded["uid"],
        "email": decoded.get("email"),
        "email_verified": bool(decoded.get("email_verified", False)),
        "auth_time": decoded.get("auth_time"),
    }


def current_user(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    return _verify(creds, check_revoked=False)


def current_user_strict(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    return _verify(creds, check_revoked=True)


def uid_hash(uid):
    return hashlib.sha256(uid.encode()).hexdigest()


def _refuse_deleted(request, user):
    db = getattr(request.app.state, "db", None)
    if db is not None and db.deleted_accounts.find_one({"_id": uid_hash(user["uid"])}, {"_id": 1}):
        raise ApiError(401, "account_deleted", "This account has been deleted.")


def active_user(request: Request, creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    user = _verify(creds, check_revoked=False)
    _refuse_deleted(request, user)
    return user


def active_user_strict(request: Request,
                       creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    # The deleted-account check runs first: for a deleted user the revocation check
    # fails too, but with the generic message.
    user = _verify(creds, check_revoked=False)
    _refuse_deleted(request, user)
    return _verify(creds, check_revoked=True)
