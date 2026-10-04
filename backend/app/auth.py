"""Firebase ID token verification (FastAPI dependency)."""
import logging

import firebase_admin
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth, credentials

logger = logging.getLogger("gemeye.auth")

_bearer = HTTPBearer(auto_error=False)
UNAUTHORISED = "Authentication required."


def init_firebase(credentials_path):
    """Initialise the default Firebase app once (no-op if already initialised)."""
    try:
        return firebase_admin.get_app()
    except ValueError:
        return firebase_admin.initialize_app(credentials.Certificate(credentials_path))


def current_user(creds: HTTPAuthorizationCredentials = Depends(_bearer)) -> dict:
    """Verifies "Authorization: Bearer <Firebase ID token>" (revocation checked).
    Any failure is a 401 with the same generic message."""
    if creds is None or creds.scheme.lower() != "bearer" or not creds.credentials:
        raise HTTPException(401, UNAUTHORISED)
    try:
        decoded = auth.verify_id_token(creds.credentials, check_revoked=True)
    except Exception as e:
        logger.info("Token rejected: %s", type(e).__name__)
        raise HTTPException(401, UNAUTHORISED)
    return {
        "uid": decoded["uid"],
        "email": decoded.get("email"),
        "email_verified": bool(decoded.get("email_verified", False)),
    }
