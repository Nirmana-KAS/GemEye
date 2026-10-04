"""User, grading history, calibration, feedback and remote config endpoints. All but
GET /config require a Firebase ID token. Other users' records always give 404
(never 403), so ids cannot be enumerated."""
import base64
import json
import logging
import time
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response
from firebase_admin import auth as firebase_auth

from app import gates
from app.auth import active_user, active_user_strict, current_user, current_user_strict, uid_hash
from app.db import utcnow
from app.errors import ApiError
from app.schemas import (AppConfig, CalibrationIn, CalibrationItem, CalibrationList, FeedbackIn,
                         FeedbackOut, GradingItem, GradingList, ProfileUpdate, UserResponse)

logger = logging.getLogger("gemeye.api")
router = APIRouter()

NOT_FOUND = "Not found."
UNAVAILABLE = "Service temporarily unavailable. Please try again."
REAUTH_MAX_AGE_S = 300      # DELETE /me needs a sign-in within the last 5 minutes


def get_db(request: Request):
    db = getattr(request.app.state, "db", None)
    if db is None:
        raise HTTPException(503, UNAVAILABLE)
    return db


def get_storage(request: Request):
    st = getattr(request.app.state, "storage", None)
    if st is None:
        raise HTTPException(503, UNAVAILABLE)
    return st


def _utc(dt):
    if dt is None:
        return None
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt.astimezone(timezone.utc)


# ---- Users ----

def user_response(doc, user):
    return {
        "uid": doc["_id"], "email": doc.get("email") or user["email"],
        "email_verified": user["email_verified"],
        **{k: doc.get(k) for k in ("display_name", "account_type", "role", "country", "phone",
                                   "created_at", "updated_at")},
        "company": doc.get("company") or {}, "settings": doc.get("settings") or {},
    }


@router.get("/me", response_model=UserResponse)
def get_me(user=Depends(active_user), db=Depends(get_db)):
    return user_response(db.ensure_user(user["uid"], user["email"]), user)


@router.put("/me", response_model=UserResponse)
def put_me(body: ProfileUpdate, user=Depends(active_user_strict), db=Depends(get_db)):
    db.ensure_user(user["uid"], user["email"])
    data = body.model_dump(exclude_unset=True)
    update = {k: v for k, v in data.items() if k not in ("company", "settings")}
    if body.company is not None:
        for k, v in body.company.model_dump(exclude_unset=True).items():
            update[f"company.{k}"] = v
    if body.settings is not None:
        for k, v in body.settings.model_dump(exclude_unset=True, exclude_none=True).items():
            update[f"settings.{k}"] = v
    update["updated_at"] = utcnow()
    db.users.update_one({"_id": user["uid"]}, {"$set": update})
    return user_response(db.users.find_one({"_id": user["uid"]}), user)


@router.delete("/me", status_code=204)
def delete_me(user=Depends(current_user_strict), db=Depends(get_db), storage=Depends(get_storage)):
    """Deletes the account: gradings + images, calibrations, rejections, feedback,
    certificate PDFs, the profile and the Firebase user. Certificates are kept as
    "withdrawn" with only cert_no, issued_at, status and the reason."""
    from app.certificates import PRIVATE_FIELDS, WITHDRAWN_REASON

    auth_time = user.get("auth_time")
    if not isinstance(auth_time, (int, float)) or time.time() - auth_time > REAUTH_MAX_AGE_S:
        raise ApiError(401, "reauth_required", "Please sign in again to delete your account.")
    uid = user["uid"]
    # Tombstone first, so the uid's still-valid ID tokens can no longer write or
    # re-create the user while (and after) the data is deleted. DELETE /me itself
    # does not check it, so a failed deletion can be retried.
    db.deleted_accounts.update_one({"_id": uid_hash(uid)},
                                   {"$set": {"deleted_at": utcnow()}}, upsert=True)
    try:
        firebase_auth.revoke_refresh_tokens(uid)
    except firebase_auth.UserNotFoundError:
        pass
    except Exception:
        logger.exception("Firebase token revoke failed")
        raise HTTPException(503, UNAVAILABLE)
    try:
        storage.delete_prefix(f"gradings/{uid}/")
        for c in db.certificates.find({"uid": uid}, {"pdf_key": 1, "image_key": 1}):
            for key in (c.get("pdf_key"), c.get("image_key")):
                if key:
                    storage.delete(key)
    except Exception:
        logger.exception("S3 delete failed")
        raise HTTPException(503, UNAVAILABLE)
    for coll in (db.gradings, db.calibrations, db.rejections, db.feedback):
        coll.delete_many({"uid": uid})
    now = utcnow()
    db.certificates.update_many({"uid": uid}, {
        "$set": {"status": "withdrawn", "revoked_reason": WITHDRAWN_REASON, "withdrawn_at": now},
        "$unset": {f: "" for f in PRIVATE_FIELDS}})
    db.users.delete_one({"_id": uid})
    try:
        firebase_auth.delete_user(uid)
    except firebase_auth.UserNotFoundError:
        pass
    except Exception:
        logger.exception("Firebase user delete failed")
        raise HTTPException(503, UNAVAILABLE)
    db.audit_log.insert_one({"_id": uuid.uuid4().hex, "action": "account_deleted",
                             "uid_hash": uid_hash(uid), "at": now})
    return Response(status_code=204)


# ---- Gradings ----

def grading_item(doc, storage):
    url = None
    if doc.get("image_key"):
        try:
            url = storage.presigned_get(doc["image_key"])
        except Exception:
            logger.exception("Presign failed")
    return {
        "grading_id": doc["_id"], "stone_id": doc["stone_id"], "created_at": doc["created_at"],
        "status": doc["status"], "result": doc["result"], "image_url": url,
        **{k: doc.get(k) for k in ("calibration_session_id", "app_version", "device",
                                   "referral_threshold_used")},
    }


def _encode_cursor(doc):
    raw = json.dumps({"t": doc["created_at"].isoformat(), "id": doc["_id"]})
    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip("=")


def _decode_cursor(cursor):
    try:
        raw = base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4))
        d = json.loads(raw)
        return _utc(datetime.fromisoformat(d["t"])), str(d["id"])
    except (ValueError, KeyError, TypeError):
        raise HTTPException(400, "Invalid cursor.")


@router.get("/gradings", response_model=GradingList)
def list_gradings(
    limit: int = Query(20, ge=1, le=50),
    cursor: Optional[str] = None,
    grade: Optional[int] = Query(None, ge=1, le=7),
    referred: Optional[bool] = None,
    from_: Optional[datetime] = Query(None, alias="from"),
    to: Optional[datetime] = None,
    user=Depends(current_user), db=Depends(get_db), storage=Depends(get_storage),
):
    q = {"uid": user["uid"], "deleted": False}
    if grade is not None:
        q["result.grade"] = grade
    if referred is not None:
        q["result.referred"] = referred
    if from_ is not None or to is not None:
        q["created_at"] = {}
        if from_ is not None:
            q["created_at"]["$gte"] = _utc(from_)
        if to is not None:
            q["created_at"]["$lte"] = _utc(to)
    if cursor:
        t, gid = _decode_cursor(cursor)
        q = {"$and": [q, {"$or": [{"created_at": {"$lt": t}}, {"created_at": t, "_id": {"$lt": gid}}]}]}
    docs = list(db.gradings.find(q).sort([("created_at", -1), ("_id", -1)]).limit(limit + 1))
    more = len(docs) > limit
    docs = docs[:limit]
    return {"items": [grading_item(d, storage) for d in docs],
            "next_cursor": _encode_cursor(docs[-1]) if more else None}


def _own_grading(db, uid, grading_id):
    doc = db.gradings.find_one({"_id": grading_id, "uid": uid, "deleted": False})
    if doc is None:
        raise HTTPException(404, NOT_FOUND)
    return doc


@router.get("/gradings/{grading_id}", response_model=GradingItem)
def get_grading(grading_id: str, user=Depends(current_user), db=Depends(get_db),
                storage=Depends(get_storage)):
    return grading_item(_own_grading(db, user["uid"], grading_id), storage)


@router.delete("/gradings/{grading_id}", status_code=204)
def delete_grading(grading_id: str, user=Depends(current_user), db=Depends(get_db),
                   storage=Depends(get_storage)):
    doc = _own_grading(db, user["uid"], grading_id)
    # The photo goes, including the copies its certificates link (they stay, without photo).
    certs = list(db.certificates.find({"grading_id": doc["_id"], "image_key": {"$ne": None}},
                                      {"image_key": 1}))
    try:
        for key in [doc.get("image_key")] + [c["image_key"] for c in certs]:
            if key:
                storage.delete(key)
    except Exception:
        logger.exception("S3 delete failed")
        raise HTTPException(503, UNAVAILABLE)
    if certs:
        db.certificates.update_many({"_id": {"$in": [c["_id"] for c in certs]}},
                                    {"$set": {"image_key": None}})
    db.gradings.update_one({"_id": doc["_id"]},
                           {"$set": {"deleted": True, "deleted_at": utcnow(), "image_key": None}})
    return Response(status_code=204)


# ---- Calibrations ----

def calibration_item(doc):
    return {"calibration_id": doc["_id"],
            **{k: doc.get(k) for k in ("session_id", "created_at", "valid_until", "device", "ccm",
                                       "residual", "quality", "measured_patches")}}


@router.post("/calibrations", response_model=CalibrationItem, status_code=201)
def post_calibration(body: CalibrationIn, user=Depends(active_user), db=Depends(get_db)):
    db.ensure_user(user["uid"], user["email"])
    doc = {"_id": uuid.uuid4().hex, "uid": user["uid"], "created_at": utcnow(),
           **body.model_dump()}
    doc["valid_until"] = _utc(doc["valid_until"])
    db.calibrations.insert_one(doc)
    return calibration_item(doc)


@router.get("/calibrations", response_model=CalibrationList)
def list_calibrations(user=Depends(current_user), db=Depends(get_db)):
    docs = db.calibrations.find({"uid": user["uid"]}).sort([("created_at", -1), ("_id", -1)]).limit(50)
    return {"items": [calibration_item(d) for d in docs]}


# ---- Feedback ----

@router.post("/feedback", response_model=FeedbackOut, status_code=201)
def post_feedback(body: FeedbackIn, user=Depends(active_user), db=Depends(get_db)):
    doc = {"_id": uuid.uuid4().hex, "uid": user["uid"], "created_at": utcnow(),
           **body.model_dump()}
    if doc["comment"] is not None:
        doc["comment"] = doc["comment"].strip() or None
    db.feedback.insert_one(doc)
    return {"feedback_id": doc["_id"], "created_at": doc["created_at"]}


# ---- Remote config (public) ----

@router.get("/config", response_model=AppConfig)
def get_config(db=Depends(get_db)):
    # blur_min_variance is the server's blurry gate, so the app's Photo Check uses
    # the same threshold; it is not part of the stored document.
    return {**db.get_app_config(), "blur_min_variance": gates.BLUR_MIN_VARIANCE}
