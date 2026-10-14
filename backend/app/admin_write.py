"""Admin dashboard write API (Phase 10b): users, remote config, announcements, review
queue, feedback status and certificates. Same router prefix, auth and rate limit as the
read API (admin.py). Every write calls audit() with before/after values that never hold
secrets (no links, tokens, storage keys or emails)."""
import csv
import io
import json
import logging
import re
import urllib.request
import uuid
from datetime import datetime
from typing import Annotated, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from firebase_admin import auth as firebase_auth
from pydantic import BaseModel, ConfigDict, Field, StrictBool, StrictInt, StrictStr, field_validator
from pymongo.errors import DuplicateKeyError

from app import gates
from app.admin import _bad, _page, _presign, _range, _grading_row, admin_only, audit, clean, review_rows, staff
from app.auth import uid_hash
from app.config import get_settings
from app.db import utcnow
from app.errors import ApiError
from app.routers import NOT_FOUND, UNAVAILABLE, _utc, delete_account, get_db, get_storage
from app.schemas import RevokeIn

logger = logging.getLogger("gemeye.admin")
router = APIRouter(prefix="/admin")

SEND_OOB_URL = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode"
SEMVER = re.compile(r"^(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})$")
VERIFY_URL = re.compile(r"^https://[A-Za-z0-9]([A-Za-z0-9.-]{0,120}[A-Za-z0-9])?(:\d{2,5})?(/[A-Za-z0-9._~/-]{0,100})?$")
CERT_NO = re.compile(r"^GE-\d{6}-\d{5}$")


def _self(user, uid):
    if user["uid"] == uid:
        raise ApiError(400, "self_action", "You cannot do this to your own account.")


def _fb_user(uid):
    try:
        return firebase_auth.get_user(uid)
    except firebase_auth.UserNotFoundError:
        return None
    except Exception:
        logger.error("Firebase lookup failed")
        raise HTTPException(503, UNAVAILABLE)


def _known_user(db, uid):
    """(firebase user or None); 404 if neither Firebase nor MongoDB knows the uid."""
    fb = _fb_user(uid)
    if fb is None and db.users.find_one({"_id": uid}, {"_id": 1}) is None:
        raise HTTPException(404, NOT_FOUND)
    return fb


def _role_of(claims):
    claims = claims or {}
    return "admin" if claims.get("admin") is True else "reviewer" if claims.get("reviewer") is True else "none"


# ---- Users ----

@router.post("/users/{uid}/disable")
def disable_user(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    _self(user, uid)
    fb = _known_user(db, uid)
    try:
        if fb is not None:
            firebase_auth.update_user(uid, disabled=True)
            firebase_auth.revoke_refresh_tokens(uid)
    except Exception:
        logger.error("Firebase disable failed")
        raise HTTPException(503, UNAVAILABLE)
    db.disabled_accounts.update_one({"_id": uid_hash(uid)}, {"$set": {"disabled_at": utcnow()}},
                                    upsert=True)
    audit(db, "user_disable", user["uid"], {"uid": uid}, {"disabled": bool(fb and fb.disabled)},
          {"disabled": True})
    return {"uid": uid, "disabled": True}


@router.post("/users/{uid}/enable")
def enable_user(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    fb = _known_user(db, uid)
    try:
        if fb is not None:
            firebase_auth.update_user(uid, disabled=False)
    except Exception:
        logger.error("Firebase enable failed")
        raise HTTPException(503, UNAVAILABLE)
    db.disabled_accounts.delete_one({"_id": uid_hash(uid)})
    audit(db, "user_enable", user["uid"], {"uid": uid}, {"disabled": True}, {"disabled": False})
    return {"uid": uid, "disabled": False}


class RoleIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    role: Literal["admin", "reviewer", "none"]


@router.post("/users/{uid}/role")
def set_user_role(uid: str, body: RoleIn, user=Depends(admin_only), db=Depends(get_db)):
    if user["uid"] == uid and body.role != "admin":
        raise ApiError(400, "self_action", "You cannot remove your own admin role.")
    fb = _fb_user(uid)
    if fb is None:
        raise HTTPException(404, NOT_FOUND)
    old = _role_of(fb.custom_claims)
    claims = {k: v for k, v in (fb.custom_claims or {}).items() if k not in ("admin", "reviewer")}
    if body.role != "none":
        claims[body.role] = True
    try:
        firebase_auth.set_custom_user_claims(uid, claims or None)
        if old != "none" and old != body.role:
            # An old token must not keep the old role (admin routes check revocation).
            firebase_auth.revoke_refresh_tokens(uid)
    except Exception:
        logger.error("Firebase role update failed")
        raise HTTPException(503, UNAVAILABLE)
    audit(db, "user_role", user["uid"], {"uid": uid}, {"role": old}, {"role": body.role})
    return {"uid": uid, "role": body.role}


def send_reset_email(email):
    """Sends Firebase's own password-reset email (web API key). True if sent."""
    key = get_settings().firebase_web_api_key
    if not key:
        return False
    req = urllib.request.Request(
        SEND_OOB_URL, method="POST",
        data=json.dumps({"requestType": "PASSWORD_RESET", "email": email}).encode(),
        headers={"Content-Type": "application/json", "X-Goog-Api-Key": key.get_secret_value()})
    try:
        with urllib.request.urlopen(req, timeout=20):
            return True
    except Exception as e:
        logger.warning("Password reset email not sent (%s)", type(e).__name__)
        return False


def reset_link(email):
    try:
        return firebase_auth.generate_password_reset_link(email)
    except Exception as e:
        logger.warning("Password reset link failed (%s)", type(e).__name__)
        return None


@router.post("/users/{uid}/password-reset")
def password_reset(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    fb = _fb_user(uid)
    if fb is None:
        raise HTTPException(404, NOT_FOUND)
    if not fb.email:
        raise HTTPException(400, "This user has no email address.")
    if send_reset_email(fb.email):
        out, how = {"status": "sent"}, "email"
    else:
        link = reset_link(fb.email)
        if link is None:
            raise HTTPException(503, UNAVAILABLE)
        # Returned to this admin only; never logged or audited.
        out, how = {"status": "link", "link": link}, "link"
    audit(db, "user_password_reset", user["uid"], {"uid": uid}, None, {"delivery": how})
    return out


@router.delete("/users/{uid}", status_code=204)
def delete_user(uid: str, user=Depends(admin_only), db=Depends(get_db), storage=Depends(get_storage)):
    _self(user, uid)
    _known_user(db, uid)
    delete_account(uid, db, storage)
    audit(db, "user_delete", user["uid"], {"uid_hash": uid_hash(uid)}, {"exists": True}, None)
    return Response(status_code=204)


# ---- Remote config ----

Bool = StrictBool


def _g(name):
    lo, hi = gates.BOUNDS[name]
    return Field(None, strict=True, allow_inf_nan=False, ge=lo, le=hi)


class MaintenanceIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: Optional[Bool] = None
    message: Optional[Annotated[StrictStr, Field(max_length=200)]] = None


class FeaturesIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    repeatability_mode: Optional[Bool] = None
    gradcam: Optional[Bool] = None
    public_verification: Optional[Bool] = None
    session_mapping: Optional[Bool] = None


class GatesIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    blur_min_variance: Optional[float] = _g("blur_min_variance")
    no_stone_min_area: Optional[float] = _g("no_stone_min_area")
    no_stone_min_contrast_de00: Optional[float] = _g("no_stone_min_contrast_de00")
    hue_min: Optional[float] = _g("hue_min")
    hue_max: Optional[float] = _g("hue_max")
    min_chroma: Optional[float] = _g("min_chroma")
    ood_warn: Optional[float] = _g("ood_warn")
    ood_reject: Optional[float] = _g("ood_reject")


class ConfigIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    referral_threshold_default: Optional[float] = Field(None, strict=True, allow_inf_nan=False,
                                                        ge=0.40, le=0.90)
    calibration_validity_hours: Optional[StrictInt] = Field(None, ge=1, le=72)
    min_app_version: Optional[StrictStr] = None
    maintenance: Optional[MaintenanceIn] = None
    features: Optional[FeaturesIn] = None
    verify_base_url: Optional[StrictStr] = None
    gates: Optional[GatesIn] = None

    @field_validator("min_app_version")
    @classmethod
    def _semver(cls, v):
        if v is not None and not SEMVER.match(v):
            raise ValueError("min_app_version must be MAJOR.MINOR.PATCH")
        return v

    @field_validator("verify_base_url")
    @classmethod
    def _https(cls, v):
        if v is not None:
            v = v.strip().rstrip("/")
            if len(v) > 200 or not VERIFY_URL.match(v):
                raise ValueError("verify_base_url must be an https URL")
        return v


def _config_view(db):
    cfg = db.get_app_config()
    return {**{k: cfg[k] for k in ("referral_threshold_default", "calibration_validity_hours",
                                   "min_app_version", "maintenance", "features", "verify_base_url")},
            "gates": gates.effective(cfg), "gate_defaults": gates.DEFAULTS,
            "gate_bounds": {k: {"min": lo, "max": hi} for k, (lo, hi) in gates.BOUNDS.items()}}


@router.get("/config")
def get_config(user=Depends(admin_only), db=Depends(get_db)):
    return _config_view(db)


@router.put("/config")
def put_config(body: ConfigIn, user=Depends(admin_only), db=Depends(get_db)):
    sent = body.model_dump(exclude_unset=True)
    if not sent:
        _bad("Nothing to change.")
    current = _config_view(db)
    update = {}
    for k, v in sent.items():
        if isinstance(v, dict):
            v = {a: b for a, b in v.items() if b is not None}
            if not v:
                continue
            v = {**current[k], **v}
            if k == "gates" and not gates.valid(v):
                _bad("Gate values are inconsistent (hue_min < hue_max and ood_warn < ood_reject).")
        elif v is None:
            continue
        update[k] = v
    if not update:
        _bad("Nothing to change.")
    before = {k: current[k] for k in update}
    db.app_config.update_one({"_id": "global"}, {"$set": update}, upsert=True)
    db.invalidate_app_config()
    audit(db, "config_update", user["uid"], {"config": "global"}, before, update)
    return _config_view(db)


@router.post("/config/reset-gates")
def reset_gates(user=Depends(admin_only), db=Depends(get_db)):
    before = gates.effective(db.get_app_config())
    db.app_config.update_one({"_id": "global"}, {"$set": {"gates": dict(gates.DEFAULTS)}}, upsert=True)
    db.invalidate_app_config()
    audit(db, "config_reset_gates", user["uid"], {"config": "global"}, {"gates": before},
          {"gates": dict(gates.DEFAULTS)})
    return _config_view(db)


# ---- Announcements ----

class AnnouncementIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: Annotated[StrictStr, Field(min_length=1, max_length=80)]
    message: Annotated[StrictStr, Field(min_length=1, max_length=500)]
    level: Literal["info", "warning"] = "info"
    starts_at: Optional[datetime] = None
    ends_at: datetime
    active: Bool = True


def _announcement_row(a, now=None):
    now = now or utcnow()
    s, e = _utc(a["starts_at"]), _utc(a["ends_at"])
    state = "disabled" if not a.get("active") else "scheduled" if s > now else "expired" if e < now else "live"
    return {"id": a["_id"], "state": state,
            **{k: a.get(k) for k in ("title", "message", "level", "starts_at", "ends_at", "active",
                                     "created_by_hash", "created_at")}}


def _announcement_doc(body):
    start = _utc(body.starts_at) if body.starts_at else utcnow()
    end = _utc(body.ends_at)
    if end <= start:
        _bad("ends_at must be after starts_at.")
    return {"title": body.title.strip(), "message": body.message.strip(), "level": body.level,
            "starts_at": start, "ends_at": end, "active": body.active}


def _audit_view(a):
    return {k: a.get(k) for k in ("title", "message", "level", "starts_at", "ends_at", "active")}


@router.get("/announcements")
def list_announcements(limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
                       user=Depends(admin_only), db=Depends(get_db)):
    docs, nxt = _page(db.announcements, {}, "created_at", limit, cursor)
    now = utcnow()
    return {"items": [_announcement_row(a, now) for a in docs], "next_cursor": nxt}


@router.post("/announcements", status_code=201)
def create_announcement(body: AnnouncementIn, user=Depends(admin_only), db=Depends(get_db)):
    doc = {"_id": uuid.uuid4().hex, **_announcement_doc(body),
           "created_by_hash": uid_hash(user["uid"]), "created_at": utcnow()}
    db.announcements.insert_one(doc)
    audit(db, "announcement_create", user["uid"], {"announcement": doc["_id"]}, None, _audit_view(doc))
    return _announcement_row(doc)


@router.put("/announcements/{aid}")
def update_announcement(aid: str, body: AnnouncementIn, user=Depends(admin_only), db=Depends(get_db)):
    old = db.announcements.find_one({"_id": aid})
    if old is None:
        raise HTTPException(404, NOT_FOUND)
    new = _announcement_doc(body)
    db.announcements.update_one({"_id": aid}, {"$set": new})
    audit(db, "announcement_update", user["uid"], {"announcement": aid}, _audit_view(old), _audit_view(new))
    return _announcement_row(db.announcements.find_one({"_id": aid}))


@router.delete("/announcements/{aid}", status_code=204)
def delete_announcement(aid: str, user=Depends(admin_only), db=Depends(get_db)):
    old = db.announcements.find_one_and_delete({"_id": aid})
    if old is None:
        raise HTTPException(404, NOT_FOUND)
    audit(db, "announcement_delete", user["uid"], {"announcement": aid}, _audit_view(old), None)
    return Response(status_code=204)


# ---- Review queue (reviewer or admin) ----

class ReviewIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    grading_id: Annotated[StrictStr, Field(min_length=1, max_length=64)]
    gemologist_grade: StrictInt = Field(ge=1, le=7)
    notes: Optional[Annotated[StrictStr, Field(max_length=500)]] = None


class ReviewUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    gemologist_grade: StrictInt = Field(ge=1, le=7)
    notes: Optional[Annotated[StrictStr, Field(max_length=500)]] = None


def _review_view(r):
    return {k: r.get(k) for k in ("grading_id", "gemologist_grade", "notes", "agrees")}


@router.get("/review-queue")
def review_queue(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
    grade: Optional[int] = Query(None, ge=1, le=7),
    model_version: Optional[str] = Query(None, max_length=50),
    user=Depends(staff), db=Depends(get_db), storage=Depends(get_storage),
):
    reviewed = [r["grading_id"] for r in db.reviews.find({}, {"grading_id": 1})]
    q = {"deleted": False, "status": "ok", "result.referred": True, "_id": {"$nin": reviewed}}
    _range(q, "created_at", from_, to)
    if grade is not None:
        q["result.grade"] = grade
    if model_version:
        q["result.model_version"] = model_version
    docs, nxt = _page(db.gradings, q, "created_at", limit, cursor)
    return clean({"items": [_grading_row(d, storage, None) for d in docs], "next_cursor": nxt})


@router.post("/reviews", status_code=201)
def create_review(body: ReviewIn, user=Depends(staff), db=Depends(get_db)):
    g = db.gradings.find_one({"_id": body.grading_id, "deleted": False, "status": "ok"})
    if g is None:
        raise HTTPException(404, NOT_FOUND)
    if db.reviews.find_one({"grading_id": g["_id"]}, {"_id": 1}) is not None:
        raise ApiError(409, "already_reviewed", "This stone has already been reviewed.")
    doc = {"_id": uuid.uuid4().hex, "grading_id": g["_id"], "reviewer_uid_hash": uid_hash(user["uid"]),
           "gemologist_grade": body.gemologist_grade,
           "notes": (body.notes or "").strip() or None,
           "agrees": body.gemologist_grade == (g.get("result") or {}).get("grade"),
           "created_at": utcnow()}
    try:
        db.reviews.insert_one(doc)
    except DuplicateKeyError:
        raise ApiError(409, "already_reviewed", "This stone has already been reviewed.")
    audit(db, "review_create", user["uid"], {"grading_id": g["_id"]}, None, _review_view(doc),
          role=user["role"])
    return clean({**_review_view(doc), "review_id": doc["_id"], "created_at": doc["created_at"]})


@router.put("/reviews/{grading_id}")
def correct_review(grading_id: str, body: ReviewUpdate, user=Depends(admin_only), db=Depends(get_db)):
    old = db.reviews.find_one({"grading_id": grading_id})
    g = db.gradings.find_one({"_id": grading_id}, {"result.grade": 1})
    if old is None or g is None:
        raise HTTPException(404, NOT_FOUND)
    new = {"gemologist_grade": body.gemologist_grade, "notes": (body.notes or "").strip() or None,
           "agrees": body.gemologist_grade == (g.get("result") or {}).get("grade"),
           "updated_at": utcnow(), "updated_by_hash": uid_hash(user["uid"])}
    db.reviews.update_one({"_id": old["_id"]}, {"$set": new})
    audit(db, "review_update", user["uid"], {"grading_id": grading_id}, _review_view(old),
          _review_view({**new, "grading_id": grading_id}))
    return {"grading_id": grading_id, **_review_view(new)}


def _rate(n, k):
    return round(k / n, 4) if n else None


@router.get("/reviews/stats")
def review_stats(user=Depends(admin_only), db=Depends(get_db)):
    rows = review_rows(db)
    matrix = [[0] * 7 for _ in range(7)]
    by_grade, by_version = {}, {}
    agreed = within1 = 0
    for _t, version, mg, gg, same in rows:
        agreed += 1 if same else 0
        within1 += 1 if mg is not None and abs(mg - gg) <= 1 else 0
        if mg is not None and 1 <= mg <= 7:
            matrix[mg - 1][gg - 1] += 1
        for table, key in ((by_grade, mg), (by_version, version or "unknown")):
            cell = table.setdefault(key, [0, 0])
            cell[0] += 1
            cell[1] += 1 if same else 0
    n = len(rows)
    pending = db.gradings.count_documents({
        "deleted": False, "status": "ok", "result.referred": True,
        "_id": {"$nin": [r["grading_id"] for r in db.reviews.find({}, {"grading_id": 1})]}})
    return {"reviewed": n, "agreed": agreed, "agreement_rate": _rate(n, agreed),
            "within_one_grade_rate": _rate(n, within1),
            "pending": pending,
            "per_grade": [{"model_grade": g, "reviewed": c[0], "agreed": c[1], "agreement_rate": _rate(*c)}
                          for g, c in sorted(by_grade.items(), key=lambda x: (x[0] is None, x[0]))],
            "per_model_version": [{"model_version": v, "reviewed": c[0], "agreed": c[1],
                                   "agreement_rate": _rate(*c)} for v, c in sorted(by_version.items())],
            "confusion_matrix": {"rows": "model_grade 1-7", "columns": "gemologist_grade 1-7",
                                 "counts": matrix}}


@router.get("/reviews/export")
def review_export(user=Depends(admin_only), db=Depends(get_db)):
    """CSV of reviewed stones as training labels. No emails, uids or storage keys."""
    reviews = {r["grading_id"]: r for r in db.reviews.find().sort("created_at", 1).limit(50000)}
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(["grading_id", "image_ref", "model_grade", "gemologist_grade", "confidence",
                "model_version", "created_at"])
    for g in db.gradings.find({"_id": {"$in": list(reviews)}},
                              {"result.grade": 1, "result.confidence": 1, "result.model_version": 1,
                               "image_key": 1}):
        r, res = reviews[g["_id"]], g.get("result") or {}
        w.writerow([g["_id"], g["_id"] if g.get("image_key") else "", res.get("grade"),
                    r["gemologist_grade"], res.get("confidence"), res.get("model_version"),
                    r["created_at"].isoformat()])
    audit(db, "review_export", user["uid"], {"reviews": len(reviews)})
    return Response(out.getvalue(), media_type="text/csv",
                    headers={"Content-Disposition": 'attachment; filename="gemeye_reviews.csv"'})


# ---- Feedback status ----

class FeedbackStatusIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["open", "resolved"]
    note: Optional[Annotated[StrictStr, Field(max_length=300)]] = None


@router.post("/feedback/{fid}/status")
def feedback_status(fid: str, body: FeedbackStatusIn, user=Depends(admin_only), db=Depends(get_db)):
    old = db.feedback.find_one({"_id": fid})
    if old is None:
        raise HTTPException(404, NOT_FOUND)
    new = {"status": body.status, "status_note": (body.note or "").strip() or None,
           "status_at": utcnow(), "status_by_hash": uid_hash(user["uid"])}
    db.feedback.update_one({"_id": fid}, {"$set": new})
    audit(db, "feedback_status", user["uid"], {"feedback": fid},
          {"status": old.get("status") or "open", "note": old.get("status_note")},
          {"status": new["status"], "note": new["status_note"]})
    return {"feedback_id": fid, "status": new["status"], "note": new["status_note"]}


# ---- Certificates ----

def _cert(db, cert_no):
    doc = db.certificates.find_one({"_id": cert_no})
    if doc is None:
        raise HTTPException(404, NOT_FOUND)
    return doc


def _revoke(db, doc, reason, extra=None):
    now = utcnow()
    res = db.certificates.update_one(
        {"_id": doc["_id"], "status": "valid"},
        {"$set": {"status": "revoked", "revoked_reason": reason.strip(), "revoked_at": now,
                  **(extra or {})}})
    if res.modified_count == 0:
        raise HTTPException(409, "Certificate is not valid.")


def _cert_state(doc):
    return {"status": doc.get("status"), "reason": doc.get("revoked_reason"),
            "superseded_by": doc.get("superseded_by")}


@router.get("/certificates/{cert_no}")
def certificate_detail(cert_no: str, user=Depends(admin_only), db=Depends(get_db),
                       storage=Depends(get_storage)):
    c = _cert(db, cert_no)
    out = {"cert_no": c["_id"], "uid": c.get("uid"), "grading_id": c.get("grading_id"),
           **{k: c.get(k) for k in ("status", "issued_at", "snapshot", "owner", "pdf_sha256",
                                    "pdf_uploaded_at", "revoked_reason", "revoked_at", "withdrawn_at",
                                    "superseded_by")},
           "pdf_url": _presign(storage, c.get("pdf_key")),
           "image_url": _presign(storage, c.get("image_key"))}
    return clean(out)


@router.post("/certificates/{cert_no}/revoke")
def revoke(cert_no: str, body: RevokeIn, user=Depends(admin_only), db=Depends(get_db)):
    doc = _cert(db, cert_no)
    before = _cert_state(doc)
    _revoke(db, doc, body.reason)
    audit(db, "certificate_revoke", user["uid"], {"cert_no": cert_no}, before,
          {"status": "revoked", "reason": body.reason.strip()})
    return {"cert_no": cert_no, "status": "revoked"}


class SupersedeIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    new_cert_no: Annotated[StrictStr, Field(pattern=CERT_NO.pattern)]
    reason: Annotated[StrictStr, Field(min_length=1, max_length=500)]


@router.post("/certificates/{cert_no}/supersede")
def supersede(cert_no: str, body: SupersedeIn, user=Depends(admin_only), db=Depends(get_db)):
    doc = _cert(db, cert_no)
    if body.new_cert_no == cert_no:
        _bad("The replacement must be a different certificate.")
    new = _cert(db, body.new_cert_no)
    if new.get("status") != "valid":
        raise HTTPException(409, "The replacement certificate is not valid.")
    before = _cert_state(doc)
    _revoke(db, doc, body.reason, {"superseded_by": new["_id"]})
    audit(db, "certificate_supersede", user["uid"], {"cert_no": cert_no}, before,
          {"status": "revoked", "reason": body.reason.strip(), "superseded_by": new["_id"]})
    return {"cert_no": cert_no, "status": "revoked", "superseded_by": new["_id"]}
