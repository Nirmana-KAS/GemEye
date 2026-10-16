"""In-app notifications (Phase N1), MongoDB collection `notifications`.

Users never delete: clear sets cleared_at and hides the item from GET /me/notifications.
Admins see every notification of a user (cleared ones included) and can restore them
(cleared_at=None, restored_at, restored_by). The only deletion is delete_account.
Notifications the phone cannot know about (certificate revoked/superseded by an admin,
role changed) are created here with source="server" via create_notification().
Phase 10f: admins send notifications to one user or all users (source="admin",
sent_by = admin uid); each send is recorded in admin_broadcasts and audited."""
import logging
import threading
import time
import uuid
from collections import defaultdict, deque
from datetime import datetime, timedelta
from typing import Annotated, List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from firebase_admin import auth as firebase_auth
from pydantic import BaseModel, ConfigDict, Field, StrictBool, StrictStr, model_validator
from pymongo.errors import DuplicateKeyError

from app.admin import _emails, _page, _range, admin_only, audit
from app.auth import active_user, current_user, uid_hash
from app.db import utcnow
from app.errors import ApiError
from app.routers import NOT_FOUND, _utc, get_db

logger = logging.getLogger("gemeye.notifications")
router = APIRouter()

TYPES = ("success", "warning", "error", "info")
CATEGORIES = ("calibration", "referral", "certificate")
RATE_LIMIT, RATE_WINDOW_S = 120, 60
SYNC_MAX = 50
ID_PATTERN = r"^[A-Za-z0-9-]{8,64}$"
ACTION_PATTERN = r"^[A-Za-z]{1,40}$"
# App screens an admin notification or announcement can open (AppNotificationAction).
ADMIN_ACTIONS = ("none", "openResult", "openCalibration", "openCapture", "openHistory", "openPrivacy")
SOURCES = ("app", "server", "admin")
BROADCAST_ALL_PER_HOUR = 5
INSERT_BATCH = 500


# ---- Rate limit (per uid, /me/notifications only) ----

_hits, _hits_lock = defaultdict(deque), threading.Lock()


def reset_rate_limit():
    with _hits_lock:
        _hits.clear()


def _limited(user):
    now = time.monotonic()
    with _hits_lock:
        q = _hits[user["uid"]]
        while q and now - q[0] > RATE_WINDOW_S:
            q.popleft()
        if len(q) >= RATE_LIMIT:
            raise HTTPException(429, "Too many requests. Please try again later.",
                                headers={"Retry-After": str(RATE_WINDOW_S)})
        q.append(now)


def reader(user=Depends(current_user)):
    _limited(user)
    return user


def writer(user=Depends(active_user)):
    _limited(user)
    return user


# ---- Creation ----

def _doc(uid, nid, type_, title, message, category, action, payload, source, created_at):
    return {"_id": nid, "uid": uid, "type": type_, "category": category, "title": title,
            "message": message, "action": action or "none", "payload": payload, "source": source,
            "created_at": created_at, "read_at": None, "cleared_at": None, "restored_at": None,
            "restored_by": None}


def _server_doc(uid, type_, title, message, category, action, payload, source, sent_by, now, extra=None):
    doc = _doc(uid, str(uuid.uuid4()), type_, title[:120], message[:1000], category, action,
               payload[:200] if payload else None, source, now)
    if sent_by:
        doc["sent_by"] = sent_by
    return {**doc, **(extra or {})}


def create_notification(db, uid, type_, title, message, category=None, action="none",
                        payload=None, source="server", sent_by=None):
    """Server-side notification (source "server", or "admin" with sent_by = admin uid).
    Never raises: a failure is logged and the action that triggered it still succeeds."""
    if not uid:
        return None
    try:
        doc = _server_doc(uid, type_, title, message, category, action, payload, source, sent_by, utcnow())
        db.notifications.insert_one(doc)
        return doc["_id"]
    except Exception:
        logger.exception("Could not create notification")
        return None


# ---- User routes ----

def user_item(d):
    return {"id": d["_id"], **{k: d.get(k) for k in ("type", "category", "title", "message",
                                                      "action", "payload", "source", "created_at")},
            "read": d.get("read_at") is not None}


@router.get("/me/notifications")
def list_mine(limit: int = Query(30, ge=1, le=100), cursor: Optional[str] = None,
              user=Depends(reader), db=Depends(get_db)):
    """Newest first; cleared notifications are never returned."""
    q = {"uid": user["uid"], "cleared_at": None}
    docs, nxt = _page(db.notifications, q, "created_at", limit, cursor)
    unread = db.notifications.count_documents({**q, "read_at": None})
    return {"items": [user_item(d) for d in docs], "next_cursor": nxt, "unread_count": unread}


class NotificationIn(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: Annotated[StrictStr, Field(pattern=ID_PATTERN)]
    type: Literal[TYPES]
    category: Optional[Literal[CATEGORIES]] = None
    title: Annotated[StrictStr, Field(min_length=1, max_length=120)]
    message: Annotated[StrictStr, Field(max_length=1000)]
    action: Annotated[StrictStr, Field(pattern=ACTION_PATTERN)] = "none"
    payload: Optional[Annotated[StrictStr, Field(max_length=200)]] = None
    created_at: datetime
    read: StrictBool = False


class SyncIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    items: Annotated[List[NotificationIn], Field(min_length=1, max_length=SYNC_MAX)]


@router.post("/me/notifications/sync")
def sync_mine(body: SyncIn, user=Depends(writer), db=Depends(get_db)):
    """Stores app-created notifications. Idempotent on id; an existing notification is
    never changed (cleared_at/restored_at stay as they are), except that read_at is set
    once if the app reports it read. Ids owned by another user are not accepted."""
    uid, now, accepted = user["uid"], utcnow(), []
    for it in body.items:
        created = min(_utc(it.created_at), now)
        doc = _doc(uid, it.id, it.type, it.title.strip(), it.message.strip(), it.category,
                   it.action, it.payload, "app", created)
        if it.read:
            doc["read_at"] = now
        del doc["_id"], doc["uid"]
        try:
            db.notifications.update_one({"_id": it.id, "uid": uid}, {"$setOnInsert": doc},
                                        upsert=True)
        except DuplicateKeyError:
            continue        # id belongs to another user
        if it.read:
            db.notifications.update_one({"_id": it.id, "uid": uid, "read_at": None},
                                        {"$set": {"read_at": now}})
        accepted.append(it.id)
    return {"accepted": accepted}


def _own(db, uid, nid):
    if db.notifications.find_one({"_id": nid, "uid": uid}, {"_id": 1}) is None:
        raise HTTPException(404, NOT_FOUND)


@router.post("/me/notifications/read-all")
def read_all(before: Optional[datetime] = None, user=Depends(writer), db=Depends(get_db)):
    """Marks every visible notification read (only those created up to `before` if given,
    so a queued offline action does not touch newer ones)."""
    q = {"uid": user["uid"], "cleared_at": None, "read_at": None}
    if before is not None:
        q["created_at"] = {"$lte": _utc(before)}
    res = db.notifications.update_many(q, {"$set": {"read_at": utcnow()}})
    return {"updated": res.modified_count}


@router.post("/me/notifications/clear-all")
def clear_all(before: Optional[datetime] = None, user=Depends(writer), db=Depends(get_db)):
    """Hides every visible notification (see read-all for `before`). Nothing is deleted."""
    q = {"uid": user["uid"], "cleared_at": None}
    if before is not None:
        q["created_at"] = {"$lte": _utc(before)}
    res = db.notifications.update_many(q, {"$set": {"cleared_at": utcnow()}})
    return {"cleared": res.modified_count}


@router.post("/me/notifications/{nid}/read")
def read_one(nid: str, user=Depends(writer), db=Depends(get_db)):
    _own(db, user["uid"], nid)
    db.notifications.update_one({"_id": nid, "uid": user["uid"], "read_at": None},
                                {"$set": {"read_at": utcnow()}})
    return {"id": nid, "read": True}


@router.post("/me/notifications/{nid}/clear")
def clear_one(nid: str, user=Depends(writer), db=Depends(get_db)):
    """Hides one notification for the user (idempotent). Nothing is deleted."""
    _own(db, user["uid"], nid)
    db.notifications.update_one({"_id": nid, "uid": user["uid"], "cleared_at": None},
                                {"$set": {"cleared_at": utcnow()}})
    return {"id": nid, "cleared": True}


# ---- Admin routes (admin only; writes are audited) ----

STATUS_QUERY = {"all": {}, "visible": {"cleared_at": None}, "cleared": {"cleared_at": {"$ne": None}}}


def admin_item(d, emails):
    return {"id": d["_id"], **{k: d.get(k) for k in ("type", "category", "title", "message",
                                                      "action", "payload", "source", "created_at",
                                                      "read_at", "cleared_at", "restored_at")},
            "restored_by_email": emails.get(d.get("restored_by")) if d.get("restored_by") else None}


def _admin_emails(db, uids):
    """Emails of the restoring admins: profile first, then Firebase (admins often have no
    profile). Unknown ones stay None."""
    emails = _emails(db, uids)
    for u in uids:
        if not emails.get(u):
            try:
                emails[u] = firebase_auth.get_user(u).email
            except Exception:
                emails[u] = None
    return emails


@router.get("/admin/users/{uid}/notifications")
def admin_list(uid: str, status: Literal["all", "visible", "cleared"] = "all",
               limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
               user=Depends(admin_only), db=Depends(get_db)):
    q = {"uid": uid, **STATUS_QUERY[status]}
    docs, nxt = _page(db.notifications, q, "created_at", limit, cursor)
    emails = _admin_emails(db, {d["restored_by"] for d in docs if d.get("restored_by")})
    counts = {s: db.notifications.count_documents({"uid": uid, **STATUS_QUERY[s]})
              for s in ("visible", "cleared")}
    return {"items": [admin_item(d, emails) for d in docs], "next_cursor": nxt, "counts": counts}


@router.post("/admin/users/{uid}/notifications/restore-all")
def admin_restore_all(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    now = utcnow()
    res = db.notifications.update_many(
        {"uid": uid, "cleared_at": {"$ne": None}},
        {"$set": {"cleared_at": None, "restored_at": now, "restored_by": user["uid"]}})
    audit(db, "notification_restore_all", user["uid"], {"uid": uid}, None,
          {"restored": res.modified_count})
    return {"restored": res.modified_count}


@router.post("/admin/users/{uid}/notifications/{nid}/restore")
def admin_restore(uid: str, nid: str, user=Depends(admin_only), db=Depends(get_db)):
    old = db.notifications.find_one({"_id": nid, "uid": uid}, {"cleared_at": 1})
    if old is None:
        raise HTTPException(404, NOT_FOUND)
    now = utcnow()
    res = db.notifications.update_one(
        {"_id": nid, "uid": uid, "cleared_at": {"$ne": None}},
        {"$set": {"cleared_at": None, "restored_at": now, "restored_by": user["uid"]}})
    if res.modified_count == 0:
        raise HTTPException(409, "This notification is not cleared.")
    audit(db, "notification_restore", user["uid"], {"uid": uid, "notification": nid},
          {"cleared_at": old["cleared_at"]}, {"cleared_at": None})
    return {"id": nid, "restored_at": now}


# ---- Admin send (Phase 10f) ----

class SendIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    target: Literal["user", "all"]
    uid: Optional[Annotated[StrictStr, Field(min_length=1, max_length=128)]] = None
    type: Literal[TYPES] = "info"
    category: Optional[Literal[CATEGORIES]] = None
    title: Annotated[StrictStr, Field(min_length=1, max_length=120)]
    message: Annotated[StrictStr, Field(min_length=1, max_length=1000)]
    action: Literal[ADMIN_ACTIONS] = "none"
    payload: Optional[Annotated[StrictStr, Field(max_length=200)]] = None

    @model_validator(mode="after")
    def _target(self):
        if self.target == "user" and not self.uid:
            raise ValueError("uid is required when target is user.")
        if self.target == "all" and self.uid:
            raise ValueError("uid must not be sent when target is all.")
        if not self.title.strip() or not self.message.strip():
            raise ValueError("title and message must not be blank.")
        return self


def recipients(db):
    """uids of every user that has a profile and is not deleted (tombstone)."""
    gone = {d["_id"] for d in db.deleted_accounts.find({}, {"_id": 1})}
    return [u["_id"] for u in db.users.find({}, {"_id": 1}) if uid_hash(u["_id"]) not in gone]


def _known_recipient(db, uid):
    if db.users.find_one({"_id": uid}, {"_id": 1}) is None or \
            db.deleted_accounts.find_one({"_id": uid_hash(uid)}, {"_id": 1}) is not None:
        raise HTTPException(404, NOT_FOUND)


@router.get("/admin/notifications/audience")
def admin_audience(user=Depends(admin_only), db=Depends(get_db)):
    """How many users a send to all would reach (for the confirm dialog)."""
    return {"users": len(recipients(db))}


@router.post("/admin/notifications/send", status_code=201)
def admin_send(body: SendIn, user=Depends(admin_only), db=Depends(get_db)):
    """One document per recipient (source=admin, sent_by=admin uid); "all" inserts in
    batches. At most BROADCAST_ALL_PER_HOUR sends to all per hour (all admins together)."""
    now = utcnow()
    if body.target == "all":
        recent = db.admin_broadcasts.count_documents({"target": "all", "at": {"$gte": now - timedelta(hours=1)}})
        if recent >= BROADCAST_ALL_PER_HOUR:
            raise ApiError(429, "rate_limited",
                           f"At most {BROADCAST_ALL_PER_HOUR} notifications to all users per hour.")
        uids = recipients(db)
    else:
        _known_recipient(db, body.uid)
        uids = [body.uid]
    bid = uuid.uuid4().hex
    title, message = body.title.strip(), body.message.strip()
    payload = body.payload.strip() if body.payload and body.payload.strip() else None
    count = 0
    for i in range(0, len(uids), INSERT_BATCH):
        docs = [_server_doc(u, body.type, title, message, body.category, body.action, payload,
                            "admin", user["uid"], now, {"broadcast_id": bid})
                for u in uids[i:i + INSERT_BATCH]]
        db.notifications.insert_many(docs, ordered=False)
        count += len(docs)
    record = {"_id": bid, "target": body.target, "uid": body.uid, "count": count, "title": title,
              "type": body.type, "category": body.category, "action": body.action,
              "sent_by": user["uid"], "at": now}
    db.admin_broadcasts.insert_one(record)
    audit(db, "notification_send", user["uid"], {"broadcast": bid, **({"uid": body.uid} if body.uid else {})},
          None, {"target": body.target, "count": count, "title": title, "type": body.type})
    return {"id": bid, "target": body.target, "count": count, "at": now}


@router.get("/admin/broadcasts")
def admin_broadcasts(limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
                     target: Optional[Literal["user", "all"]] = None,
                     user=Depends(admin_only), db=Depends(get_db)):
    q = {"target": target} if target else {}
    docs, nxt = _page(db.admin_broadcasts, q, "at", limit, cursor)
    emails = _admin_emails(db, {d["sent_by"] for d in docs if d.get("sent_by")} |
                           {d["uid"] for d in docs if d.get("uid")})
    return {"items": [{"id": d["_id"], **{k: d.get(k) for k in ("target", "uid", "count", "title", "type",
                                                               "category", "action", "at")},
                       "user_email": emails.get(d.get("uid")) if d.get("uid") else None,
                       "sent_by_email": emails.get(d.get("sent_by"))} for d in docs],
            "next_cursor": nxt}


ALL_STATUS_QUERY = {**STATUS_QUERY, "read": {"read_at": {"$ne": None}}, "unread": {"read_at": None}}


@router.get("/admin/notifications")
def admin_list_all(uid: Optional[str] = Query(None, max_length=128),
                   status: Literal["all", "visible", "cleared", "read", "unread"] = "all",
                   source: Optional[Literal[SOURCES]] = None,
                   from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
                   limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
                   user=Depends(admin_only), db=Depends(get_db)):
    """Every user's notifications, newest first, with the user's email."""
    q = dict(ALL_STATUS_QUERY[status])
    if uid:
        q["uid"] = uid
    if source:
        q["source"] = source
    _range(q, "created_at", from_, to)
    docs, nxt = _page(db.notifications, q, "created_at", limit, cursor)
    users = _emails(db, [d["uid"] for d in docs])
    staff_ = _admin_emails(db, {d[k] for d in docs for k in ("restored_by", "sent_by") if d.get(k)})
    return {"items": [{**admin_item(d, staff_), "uid": d["uid"], "user_email": users.get(d["uid"]),
                       "sent_by_email": staff_.get(d.get("sent_by")) if d.get("sent_by") else None}
                      for d in docs],
            "next_cursor": nxt}
