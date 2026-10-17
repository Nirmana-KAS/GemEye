"""Admin powers (Phase 10p): force sign-out, profile edits, notes, daily grading limits and
the activity timeline of a user; hide / restore / permanent delete / send to review /
re-grade / bulk actions on gradings; calibration invalidation and device blocking.

Same prefix, auth and rate limit as the rest of /admin (admin_only: reviewers get 403).
Every write is audited with before/after values that hold no secrets and, for permanent
deletes, no colour data. GET /me/calibration-status (the app) is here too."""
import csv
import io
import logging
import re
import time
import uuid
from datetime import datetime, timezone
from typing import Annotated, List, Literal, Optional

from botocore.exceptions import ClientError
from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response
from firebase_admin import auth as firebase_auth
from pydantic import (AfterValidator, BaseModel, ConfigDict, Field, StrictInt, StrictStr, field_validator,
                      model_validator)
from pymongo.errors import DuplicateKeyError

from app import gates
from app.admin import _bad, _decode, _emails, _encode, _page, admin_only, audit, clean, staff_emails
from app.admin_write import _fb_user, _known_user
from app.assets import MODEL_LOCK
from app.auth import current_user, uid_hash
from app.certificates import PRIVATE_FIELDS
from app.db import utcnow
from app.errors import ApiError
from app.limits import (DAILY_LIMIT_BOUNDS, DEVICE_ID_PATTERN, device_id, effective_limit,
                        gradings_today)
from app.notifications import create_notification
from app.pipeline.colour import decode_image
from app.pipeline.inference import grade as run_model
from app.pipeline.inference import model_version
from app.routers import NOT_FOUND, UNAVAILABLE, _s3_missing, _utc, get_db, get_storage, heatmap_key
from app.schemas import GradeResponse

logger = logging.getLogger("gemeye.admin")
router = APIRouter(prefix="/admin")
me_router = APIRouter()

REASON_MAX, NOTE_MAX, BULK_MAX, REGRADES_KEPT = 500, 1000, 200, 20
WITHDRAWN_BY_ADMIN = "Withdrawn by GemEye"
# Audit entries of a grading that hold grade values; scrubbed when the grading is deleted.
GRADE_AUDITS = ("review_create", "review_update", "grading_regrade")
CALIBRATION_RESET_TITLE = "Calibration reset"
CALIBRATION_RESET_MESSAGE = "Your calibration was reset by support. Please recalibrate before grading."


def _stripped(v):
    if not v.strip():
        raise ValueError("must not be blank.")
    return v.strip()


Reason = Annotated[StrictStr, Field(min_length=1, max_length=REASON_MAX), AfterValidator(_stripped)]


class ReasonIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    reason: Reason


class OptionalReasonIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    reason: Optional[Annotated[StrictStr, Field(max_length=REASON_MAX)]] = None

    @field_validator("reason")
    @classmethod
    def _clean(cls, v):
        return (v or "").strip() or None


def _conflict(code, message):
    raise ApiError(409, code, message)


# ---- Users ----

def _profile(db, uid):
    doc = db.users.find_one({"_id": uid})
    if doc is None:
        raise HTTPException(404, NOT_FOUND)
    return doc


@router.post("/users/{uid}/revoke-sessions")
def revoke_sessions(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    """Force sign-out on every device (your own account too). Firebase refresh tokens are
    revoked and the marker makes every route answer 401 token_revoked to older tokens."""
    if _fb_user(uid) is None:
        raise HTTPException(404, NOT_FOUND)
    try:
        firebase_auth.revoke_refresh_tokens(uid)
    except firebase_auth.UserNotFoundError:
        raise HTTPException(404, NOT_FOUND)
    except Exception:
        logger.error("Firebase revoke failed")
        raise HTTPException(503, UNAVAILABLE)
    key, now = uid_hash(uid), utcnow()
    old = db.revoked_sessions.find_one({"_id": key}) or {}
    db.revoked_sessions.update_one({"_id": key}, {"$set": {"valid_after_s": int(time.time()), "at": now}},
                                   upsert=True)
    me = user["uid"] == uid
    audit(db, "user_revoke_sessions", user["uid"], {"uid": uid}, {"last_revoked_at": old.get("at")},
          {"last_revoked_at": now, "self": me})
    return {"uid": uid, "revoked_at": now, "self": me}


class AdminProfileIn(BaseModel):
    """The app's profile limits (PUT /me): name 100, phone 30, company name 200. Empty = cleared.
    Email is not editable here (extra fields are refused)."""
    model_config = ConfigDict(extra="forbid")
    display_name: Optional[Annotated[StrictStr, Field(max_length=100)]] = None
    phone: Optional[Annotated[StrictStr, Field(max_length=30)]] = None
    company: Optional[Annotated[StrictStr, Field(max_length=200)]] = None


def _profile_view(doc):
    return {"display_name": doc.get("display_name"), "phone": doc.get("phone"),
            "company": (doc.get("company") or {}).get("name")}


@router.patch("/users/{uid}/profile")
def edit_profile(uid: str, body: AdminProfileIn, user=Depends(admin_only), db=Depends(get_db)):
    sent = {k: (v or "").strip() or None for k, v in body.model_dump(exclude_unset=True).items()}
    if not sent:
        _bad("Nothing to change.")
    doc = _profile(db, uid)
    before = _profile_view(doc)
    if "display_name" in sent and sent["display_name"] != before["display_name"] and _fb_user(uid):
        # The app greets with the Firebase display name, so both are changed.
        try:
            firebase_auth.update_user(uid, display_name=sent["display_name"] or firebase_auth.DELETE_ATTRIBUTE)
        except Exception:
            logger.error("Firebase profile update failed")
            raise HTTPException(503, UNAVAILABLE)
    update = {"updated_at": utcnow()}
    for k, v in sent.items():
        if k != "company":
            update[k] = v
        elif isinstance(doc.get("company"), dict):
            update["company.name"] = v
        else:
            update["company"] = {"name": v}
    db.users.update_one({"_id": uid}, {"$set": update})
    after = _profile_view(db.users.find_one({"_id": uid}))
    audit(db, "user_profile_edit", user["uid"], {"uid": uid}, {k: before[k] for k in sent},
          {k: after[k] for k in sent})
    return {"uid": uid, **after}


class DailyLimitIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    # null = this user has no own limit (the config default, if any, applies).
    daily_grading_limit: Optional[StrictInt] = Field(..., ge=DAILY_LIMIT_BOUNDS[0], le=DAILY_LIMIT_BOUNDS[1])


def _limit_view(db, doc, uid):
    cfg = db.get_app_config()
    return {"uid": uid, "daily_grading_limit": doc.get("daily_grading_limit"),
            "default": cfg.get("daily_grading_limit_default"), "effective": effective_limit(doc, cfg),
            "today": gradings_today(db, uid)}


@router.put("/users/{uid}/daily-limit")
def set_daily_limit(uid: str, body: DailyLimitIn, user=Depends(admin_only), db=Depends(get_db)):
    doc = _profile(db, uid)
    old = doc.get("daily_grading_limit")
    db.users.update_one({"_id": uid}, {"$set": {"daily_grading_limit": body.daily_grading_limit,
                                                "updated_at": utcnow()}})
    audit(db, "user_daily_limit", user["uid"], {"uid": uid}, {"daily_grading_limit": old},
          {"daily_grading_limit": body.daily_grading_limit})
    return _limit_view(db, db.users.find_one({"_id": uid}), uid)


class NoteIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    text: Annotated[StrictStr, Field(min_length=1, max_length=NOTE_MAX), AfterValidator(_stripped)]


def _note_out(n, emails):
    return {"id": n["_id"], "text": n["text"], "at": n["at"], "author_email": emails.get(n.get("author_hash"))}


@router.get("/users/{uid}/notes")
def list_notes(uid: str, limit: int = Query(50, ge=1, le=100), cursor: Optional[str] = None,
               user=Depends(admin_only), db=Depends(get_db)):
    """Admin-only notes about a user. No /me route ever returns them."""
    docs, nxt = _page(db.admin_notes, {"uid": uid}, "at", limit, cursor)
    emails = staff_emails(db, [n.get("author_hash") for n in docs])
    return {"items": [_note_out(n, emails) for n in docs], "next_cursor": nxt}


@router.post("/users/{uid}/notes", status_code=201)
def add_note(uid: str, body: NoteIn, user=Depends(admin_only), db=Depends(get_db)):
    _known_user(db, uid)
    doc = {"_id": uuid.uuid4().hex, "uid": uid, "text": body.text, "author_hash": uid_hash(user["uid"]),
           "at": utcnow()}
    db.admin_notes.insert_one(doc)
    audit(db, "user_note_add", user["uid"], {"uid": uid, "note": doc["_id"]}, None, {"text": body.text})
    return _note_out(doc, {doc["author_hash"]: user.get("email")})


@router.delete("/users/{uid}/notes/{nid}", status_code=204)
def delete_note(uid: str, nid: str, user=Depends(admin_only), db=Depends(get_db)):
    old = db.admin_notes.find_one_and_delete({"_id": nid, "uid": uid})
    if old is None:
        raise HTTPException(404, NOT_FOUND)
    audit(db, "user_note_delete", user["uid"], {"uid": uid, "note": nid}, {"text": old["text"]}, None)
    return Response(status_code=204)


AUDIT_SUMMARY = {
    "user_disable": "Account disabled", "user_enable": "Account enabled", "user_role": "Role changed",
    "user_password_reset": "Password reset sent", "user_revoke_sessions": "Signed out by admin",
    "user_profile_edit": "Profile edited by admin", "user_daily_limit": "Daily limit changed",
    "user_note_add": "Admin note added", "user_note_delete": "Admin note deleted",
    "grading_hide": "Grading hidden", "grading_restore": "Grading restored",
    "grading_send_to_review": "Sent to review", "grading_regrade": "Re-graded",
    "calibration_invalidate": "Calibration reset", "notification_send": "Notification sent",
    "notification_restore": "Notification restored", "notification_restore_all": "Notifications restored",
}


@router.get("/users/{uid}/activity")
def user_activity(uid: str, limit: int = Query(30, ge=1, le=100), cursor: Optional[str] = None,
                  user=Depends(admin_only), db=Depends(get_db)):
    """Sign-ins and last active (Firebase), gradings, calibrations, feedback, certificates and
    admin actions on the user, merged newest first with one cursor."""
    doc = db.users.find_one({"_id": uid}, {"created_at": 1})
    fb = _fb_user(uid)
    if doc is None and fb is None:
        raise HTTPException(404, NOT_FOUND)
    before = _decode(cursor) if cursor else None
    n = limit + 1
    events = []

    def add(t, type_, ref, summary, **extra):
        if t is not None:
            events.append({"id": f"{type_}:{ref}", "type": type_, "at": _utc(t), "ref": ref,
                           "summary": summary, **extra})

    def newest(coll, q, field, proj):
        if before:
            q = {**q, field: {"$lte": before[0]}}
        return coll.find(q, proj).sort([(field, -1), ("_id", -1)]).limit(n)

    for g in newest(db.gradings, {"uid": uid}, "created_at",
                    {"stone_id": 1, "created_at": 1, "result.grade": 1, "hidden": 1, "deleted": 1}):
        flags = [w for w, on in (("hidden", g.get("hidden")), ("deleted by user", g.get("deleted"))) if on]
        add(g["created_at"], "grading", g["_id"],
            f"Graded {g.get('stone_id') or g['_id']}: grade {(g.get('result') or {}).get('grade', '-')}"
            + (f" ({', '.join(flags)})" if flags else ""))
    for c in newest(db.calibrations, {"uid": uid}, "created_at",
                    {"session_id": 1, "created_at": 1, "quality": 1, "invalidated_at": 1}):
        add(c["created_at"], "calibration", c["_id"],
            f"Calibrated {c.get('session_id')} ({c.get('quality') or '-'})"
            + (" - reset by support" if c.get("invalidated_at") else ""))
    for f in newest(db.feedback, {"uid": uid}, "created_at", {"created_at": 1, "rating": 1, "category": 1}):
        add(f["created_at"], "feedback", f["_id"], f"Feedback {f.get('rating')}/5 ({f.get('category')})")
    for c in newest(db.certificates, {"uid": uid}, "issued_at", {"issued_at": 1, "status": 1}):
        add(c["issued_at"], "certificate", c["_id"], f"Certificate {c['_id']} issued ({c.get('status')})")
    audits = list(newest(db.audit_log, {"$or": [{"target.uid": uid}, {"target.uid_hash": uid_hash(uid)}]},
                         "at", {"action": 1, "at": 1, "uid_hash": 1, "target": 1}))
    emails = staff_emails(db, [a.get("uid_hash") for a in audits])
    for a in audits:
        add(a["at"], "admin_action", a["_id"], AUDIT_SUMMARY.get(a["action"], a["action"].replace("_", " ")),
            action=a["action"], admin_email=emails.get(a.get("uid_hash")))
    if doc is not None:
        add(doc.get("created_at"), "account_created", uid, "Account created")
    if fb is not None:
        meta = fb.user_metadata
        for ms, type_, text in ((meta.last_sign_in_timestamp, "signed_in", "Last sign-in"),
                                (getattr(meta, "last_refresh_timestamp", None), "last_active", "Last active")):
            if ms:
                add(datetime.fromtimestamp(ms / 1000, timezone.utc), type_, uid, text)

    if before:
        events = [e for e in events if (e["at"], e["id"]) < before]
    events.sort(key=lambda e: (e["at"], e["id"]), reverse=True)
    page = events[:limit]
    nxt = _encode({"at": page[-1]["at"], "_id": page[-1]["id"]}, "at") if len(events) > limit else None
    return clean({"items": page, "next_cursor": nxt})


# ---- Gradings ----

def _grading(db, gid):
    g = db.gradings.find_one({"_id": gid, "deleted": False})
    if g is None:
        raise HTTPException(404, NOT_FOUND)
    return g


def _target(g, bulk=False):
    return {"grading_id": g["_id"], "uid": g["uid"], **({"bulk": True} if bulk else {})}


def _hide(db, g, reason, admin_uid, bulk=False):
    if g.get("hidden"):
        return False
    db.gradings.update_one({"_id": g["_id"]}, {"$set": {
        "hidden": True, "hidden_reason": reason, "hidden_at": utcnow(), "hidden_by_hash": uid_hash(admin_uid)}})
    audit(db, "grading_hide", admin_uid, _target(g, bulk), {"hidden": False}, {"hidden": True, "reason": reason})
    return True


def _restore(db, g, reason, admin_uid, bulk=False):
    if not g.get("hidden"):
        return False
    db.gradings.update_one({"_id": g["_id"]}, {
        "$set": {"hidden": False, "restored_at": utcnow(), "restored_by_hash": uid_hash(admin_uid)},
        "$unset": {"hidden_reason": "", "hidden_at": "", "hidden_by_hash": ""}})
    audit(db, "grading_restore", admin_uid, _target(g, bulk), {"hidden": True, "reason": g.get("hidden_reason")},
          {"hidden": False, "reason": reason})
    return True


def _send_to_review(db, g, note, admin_uid, bulk=False):
    """None when queued, else why not (already_reviewed, already_in_queue, not_gradable)."""
    if g.get("status") != "ok":
        return "not_gradable"
    if db.reviews.find_one({"grading_id": g["_id"]}, {"_id": 1}) is not None:
        return "already_reviewed"
    if g.get("review_requested"):
        return "already_in_queue"
    db.gradings.update_one({"_id": g["_id"]}, {"$set": {"review_requested": {
        "reason": "admin", "note": note, "at": utcnow(), "by_hash": uid_hash(admin_uid)}}})
    audit(db, "grading_send_to_review", admin_uid, _target(g, bulk),
          {"in_queue": bool((g.get("result") or {}).get("referred"))},
          {"in_queue": True, "reason": "admin", "note": note})
    return None


SEND_ERRORS = {"already_reviewed": "This stone has already been reviewed.",
               "already_in_queue": "This stone is already waiting in the review queue.",
               "not_gradable": "Only graded stones can be reviewed."}


@router.post("/gradings/{gid}/hide")
def hide_grading(gid: str, body: ReasonIn, user=Depends(admin_only), db=Depends(get_db)):
    if not _hide(db, _grading(db, gid), body.reason, user["uid"]):
        _conflict("already_hidden", "This grading is already hidden.")
    return {"grading_id": gid, "hidden": True}


@router.post("/gradings/{gid}/restore")
def restore_grading(gid: str, body: Optional[OptionalReasonIn] = None, user=Depends(admin_only),
                    db=Depends(get_db)):
    if not _restore(db, _grading(db, gid), body.reason if body else None, user["uid"]):
        _conflict("not_hidden", "This grading is not hidden.")
    return {"grading_id": gid, "hidden": False}


@router.post("/gradings/{gid}/send-to-review")
def send_to_review(gid: str, body: Optional[OptionalReasonIn] = None, user=Depends(admin_only),
                   db=Depends(get_db)):
    err = _send_to_review(db, _grading(db, gid), body.reason if body else None, user["uid"])
    if err:
        _conflict(err, SEND_ERRORS[err])
    return {"grading_id": gid, "in_queue": True, "reason": "admin"}


class PermanentDeleteIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    confirm_id: Annotated[StrictStr, Field(min_length=1, max_length=64)]
    reason: Reason


@router.delete("/gradings/{gid}")
def delete_grading_permanently(gid: str, body: PermanentDeleteIn, user=Depends(admin_only),
                               db=Depends(get_db), storage=Depends(get_storage)):
    """Privacy deletion: the photo, Grad-CAM and certificate files leave S3, reviews and the
    stone's notifications are deleted, certificates become withdrawn (number, date, status and
    reason only) and the grading document is removed. The audit keeps no colour data."""
    if body.confirm_id != gid:
        raise ApiError(400, "confirm_mismatch", "Type the grading id to confirm.")
    g = db.gradings.find_one({"_id": gid})
    if g is None:
        raise HTTPException(404, NOT_FOUND)
    certs = list(db.certificates.find({"grading_id": gid}, {"image_key": 1, "pdf_key": 1}))
    hm = (g.get("heatmap") or {}).get("key") or heatmap_key(storage, g)
    keys = [k for k in [g.get("image_key"), hm] + [c.get(f) for c in certs for f in ("image_key", "pdf_key")] if k]
    try:
        for key in keys:
            storage.delete(key)
    except Exception:
        logger.exception("S3 delete failed")
        raise HTTPException(503, UNAVAILABLE)
    cert_nos = [c["_id"] for c in certs]
    if cert_nos:
        db.certificates.update_many({"_id": {"$in": cert_nos}}, {
            "$set": {"status": "withdrawn", "revoked_reason": WITHDRAWN_BY_ADMIN, "withdrawn_at": utcnow()},
            "$unset": {f: "" for f in PRIVATE_FIELDS + ("superseded_by",)}})
    db.reviews.delete_many({"grading_id": gid})
    payloads = [gid] + [p for p in (g.get("stone_id"),) if p] + cert_nos
    db.notifications.delete_many({"uid": g["uid"], "payload": {"$in": payloads}})
    db.gradings.delete_one({"_id": gid})
    db.audit_log.update_many({"target.grading_id": gid, "action": {"$in": list(GRADE_AUDITS)}},
                             {"$set": {"before": None, "after": None, "scrubbed": "grading_deleted"}})
    audit(db, "grading_delete_permanent", user["uid"], {"grading_id": gid, "uid_hash": uid_hash(g["uid"])},
          {"exists": True, "certificates": cert_nos},
          {"deleted": True, "reason": body.reason, "withdrawn": cert_nos, "s3_objects": len(keys)})
    return {"grading_id": gid, "deleted": True, "withdrawn": cert_nos}


@router.post("/gradings/{gid}/regrade")
def regrade(gid: str, request: Request, user=Depends(admin_only), db=Depends(get_db),
            storage=Depends(get_storage)):
    """Runs the current model on the stored photo (current gates and session_mapping flag,
    the grading's own referral threshold). The result goes into `regrades`; the original
    result is never changed."""
    g = _grading(db, gid)
    assets = request.app.state.assets
    if assets is None:
        raise HTTPException(503, UNAVAILABLE)
    if not g.get("image_key"):
        _conflict("photo_missing", "The photo of this grading is not stored.")
    try:
        data = storage.get(g["image_key"])
    except ClientError as e:
        if _s3_missing(e):
            _conflict("photo_missing", "The photo of this grading is not stored.")
        logger.exception("S3 get failed")
        raise HTTPException(503, UNAVAILABLE)
    try:
        raw_rgb = decode_image(data)
    except ValueError:
        _conflict("photo_missing", "The stored photo cannot be read.")
    del data
    cfg = db.get_app_config()
    patches = g.get("patches") if (cfg.get("features") or {}).get("session_mapping") else None
    threshold = float(g.get("referral_threshold_used") or cfg.get("referral_threshold_default") or 0.6)
    with MODEL_LOCK:
        result = run_model(assets, raw_rgb, patches, threshold, debug=False, enforce_gates=True,
                           gate_cfg=gates.effective(cfg))
    del raw_rgb
    r = GradeResponse(**result).model_dump(mode="json", exclude_unset=True, exclude={"debug"})
    entry = {"id": uuid.uuid4().hex, "model_version": r.get("model_version") or model_version(assets),
             "status": r["status"], "message": r.get("message"),
             **{k: r.get(k) for k in ("grade", "grade_name", "probabilities", "confidence", "uncertainty",
                                      "referred", "warnings")},
             "at": utcnow(), "by_hash": uid_hash(user["uid"])}
    saved = db.gradings.update_one({"_id": gid, "deleted": False},
                                   {"$push": {"regrades": {"$each": [entry], "$slice": -REGRADES_KEPT}}})
    if saved.matched_count == 0:
        raise HTTPException(404, NOT_FOUND)
    audit(db, "grading_regrade", user["uid"], _target(g), {"regrades": len(g.get("regrades") or [])},
          {"model_version": entry["model_version"], "status": entry["status"], "grade": entry["grade"]})
    out = {k: v for k, v in entry.items() if k != "by_hash"}
    return clean({**out, "by_email": user.get("email"),
                  "original": {k: (g.get("result") or {}).get(k) for k in ("grade", "confidence", "model_version")}})


class BulkIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    action: Literal["hide", "restore", "send_to_review", "export"]
    ids: Annotated[List[Annotated[StrictStr, Field(min_length=1, max_length=64)]],
                   Field(min_length=1, max_length=BULK_MAX)]
    reason: Optional[Annotated[StrictStr, Field(max_length=REASON_MAX)]] = None

    @model_validator(mode="after")
    def _check(self):
        if len(set(self.ids)) != len(self.ids):
            raise ValueError("ids must be unique.")
        self.reason = (self.reason or "").strip() or None
        if self.action == "hide" and not self.reason:
            raise ValueError("reason is required to hide gradings.")
        return self


CSV_COLUMNS = ("grading_id", "stone_id", "created_at", "user_email", "grade", "grade_name", "confidence",
               "uncertainty", "referred", "model_version", "device", "app_version", "hidden", "warnings")


def _cell(v):
    """CSV value; text that a spreadsheet would run as a formula is prefixed with '."""
    if v is None:
        return ""
    if isinstance(v, (list, tuple)):
        v = " ".join(str(x) for x in v)
    s = v.isoformat() if hasattr(v, "isoformat") else str(v)
    return "'" + s if s[:1] in ("=", "+", "-", "@") and not re.fullmatch(r"-?\d+(\.\d+)?", s) else s


def _export(db, docs, ids, user):
    emails = _emails(db, [d["uid"] for d in docs.values()])
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(CSV_COLUMNS)
    for gid in ids:
        d = docs.get(gid)
        if d is None:
            continue
        r = d.get("result") or {}
        row = {"grading_id": d["_id"], "stone_id": d.get("stone_id"), "created_at": d.get("created_at"),
               "user_email": emails.get(d["uid"]), "device": d.get("device"), "app_version": d.get("app_version"),
               "hidden": "true" if d.get("hidden") else "false",
               **{k: r.get(k) for k in ("grade", "grade_name", "confidence", "uncertainty", "referred",
                                        "model_version", "warnings")}}
        w.writerow([_cell(row[c]) for c in CSV_COLUMNS])
    audit(db, "gradings_export", user["uid"], {"gradings": len(docs)}, None, {"count": len(docs)})
    return Response(out.getvalue(), media_type="text/csv",
                    headers={"Content-Disposition": 'attachment; filename="gemeye_gradings.csv"'})


@router.post("/gradings/bulk")
def bulk_gradings(body: BulkIn, user=Depends(admin_only), db=Depends(get_db)):
    """hide (reason required), restore, send_to_review or export (CSV) for up to 200 gradings.
    Each changed grading gets its own audit entry (target.bulk = true)."""
    docs = {d["_id"]: d for d in db.gradings.find({"_id": {"$in": body.ids}, "deleted": False})}
    if body.action == "export":
        return _export(db, docs, body.ids, user)
    done, skipped = [], []
    for gid in body.ids:
        g = docs.get(gid)
        if g is None:
            skipped.append({"id": gid, "reason": "not_found"})
            continue
        if body.action == "hide":
            err = None if _hide(db, g, body.reason, user["uid"], True) else "already_hidden"
        elif body.action == "restore":
            err = None if _restore(db, g, body.reason, user["uid"], True) else "not_hidden"
        else:
            err = _send_to_review(db, g, body.reason, user["uid"], True)
        if err:
            skipped.append({"id": gid, "reason": err})
        else:
            done.append(gid)
    return {"action": body.action, "requested": len(body.ids), "done": done, "skipped": skipped}


# ---- Calibrations ----

@router.post("/calibrations/{cid}/invalidate")
def invalidate_calibration(cid: str, body: ReasonIn, user=Depends(admin_only), db=Depends(get_db)):
    """The app checks GET /me/calibration-status and asks the user to recalibrate; the user
    gets one notification."""
    c = db.calibrations.find_one({"_id": cid})
    if c is None:
        raise HTTPException(404, NOT_FOUND)
    if c.get("invalidated_at"):
        _conflict("already_invalidated", "This calibration was already reset.")
    now = utcnow()
    db.calibrations.update_one({"_id": cid}, {"$set": {
        "invalidated_at": now, "invalidated_reason": body.reason, "invalidated_by_hash": uid_hash(user["uid"])}})
    audit(db, "calibration_invalidate", user["uid"],
          {"calibration_id": cid, "uid": c["uid"], "session_id": c.get("session_id")},
          {"invalidated": False}, {"invalidated": True, "reason": body.reason})
    create_notification(db, c["uid"], "warning", CALIBRATION_RESET_TITLE, CALIBRATION_RESET_MESSAGE,
                        category="calibration", action="openCalibration", payload=c.get("session_id"))
    return {"calibration_id": cid, "invalidated_at": now}


@me_router.get("/me/calibration-status")
def calibration_status(session_id: Optional[str] = Query(None, min_length=1, max_length=100),
                       user=Depends(current_user), db=Depends(get_db)):
    """Whether the given (or the latest) calibration session of the caller was reset by
    support. The admin's reason is not returned."""
    q = {"uid": user["uid"], **({"session_id": session_id} if session_id else {})}
    c = db.calibrations.find_one(q, sort=[("created_at", -1), ("_id", -1)])
    if c is None:
        return {"session_id": session_id, "found": False, "invalidated": False, "invalidated_at": None}
    return {"session_id": c.get("session_id"), "found": True, "invalidated": bool(c.get("invalidated_at")),
            "invalidated_at": c.get("invalidated_at")}


# ---- Devices ----

def _device_name(db, did):
    """(found, model name) for a device_id: a record with that install id, else a legacy
    record whose model name hashes to it."""
    for coll in (db.gradings, db.calibrations):
        r = coll.find_one({"device_id": did}, {"device": 1}, sort=[("created_at", -1)])
        if r is not None:
            return True, (r.get("device") or "").strip() or None
    for coll in (db.gradings, db.calibrations):
        for name in coll.distinct("device", {"device_id": None}):
            if isinstance(name, str) and name.strip() and device_id(name) == did:
                return True, name.strip()
    return False, None


def _device_path(did):
    if not re.fullmatch(DEVICE_ID_PATTERN, did):
        raise HTTPException(404, NOT_FOUND)


@router.get("/devices/blocked")
def blocked_devices(user=Depends(admin_only), db=Depends(get_db)):
    docs = list(db.blocked_devices.find().sort("blocked_at", -1).limit(500))
    emails = staff_emails(db, [d.get("blocked_by_hash") for d in docs])
    return {"items": [{"device_id": d["_id"], "short_id": d["_id"][:8], "name": d.get("device_model"),
                       "reason": d.get("reason"),
                       "blocked_at": d.get("blocked_at"), "blocked_by_email": emails.get(d.get("blocked_by_hash"))}
                      for d in docs]}


@router.post("/devices/{did}/block")
def block_device(did: str, body: ReasonIn, user=Depends(admin_only), db=Depends(get_db)):
    """POST /grade and calibration uploads from this device get 403 DEVICE_BLOCKED."""
    _device_path(did)
    if db.blocked_devices.find_one({"_id": did}, {"_id": 1}) is not None:
        _conflict("already_blocked", "This device is already blocked.")
    found, name = _device_name(db, did)
    if not found:
        raise HTTPException(404, NOT_FOUND)
    doc = {"_id": did, "device_model": name, "reason": body.reason, "blocked_at": utcnow(),
           "blocked_by_hash": uid_hash(user["uid"])}
    try:
        db.blocked_devices.insert_one(doc)
    except DuplicateKeyError:
        _conflict("already_blocked", "This device is already blocked.")
    audit(db, "device_block", user["uid"], {"device_id": did}, {"blocked": False},
          {"blocked": True, "device_model": name, "reason": body.reason})
    return {"device_id": did, "short_id": did[:8], "name": name, "blocked": True}


@router.post("/devices/{did}/unblock")
def unblock_device(did: str, body: ReasonIn, user=Depends(admin_only), db=Depends(get_db)):
    _device_path(did)
    old = db.blocked_devices.find_one_and_delete({"_id": did})
    if old is None:
        _conflict("not_blocked", "This device is not blocked.")
    audit(db, "device_unblock", user["uid"], {"device_id": did},
          {"blocked": True, "device_model": old.get("device_model"), "reason": old.get("reason")},
          {"blocked": False, "reason": body.reason})
    return {"device_id": did, "short_id": did[:8], "name": old.get("device_model"), "blocked": False}
