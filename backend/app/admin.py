"""Admin dashboard read API (Phase 10a). Roles are Firebase custom claims.

Every route needs admin_user, except gradings which also allow reviewers (no email).
Responses are scrubbed of tokens, storage keys and secrets. Reads are not audited;
admin writes (from Phase 10b) call audit()."""
import base64
import json
import re
import threading
import time
import uuid
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone
from typing import Optional
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response
from firebase_admin import auth as firebase_auth

from app.auth import admin_user, reviewer_or_admin, uid_hash
from app.db import utcnow
from app.pipeline.inference import model_version
from app.routers import NOT_FOUND, _utc, get_db, get_storage

COLOMBO = ZoneInfo("Asia/Colombo")
ADMIN_ORIGINS = ("http://localhost:3000", "https://gemeye-app-2026.web.app")
RATE_LIMIT, RATE_WINDOW_S = 120, 60
SECRET_KEYS = {"token", "token_sha256", "image_key", "pdf_key", "verify_url", "password",
               "password_hash", "passwordhash", "secret", "api_key", "access_token", "id_token"}


# ---- Rate limit (per admin uid) and response scrubbing ----

_hits, _hits_lock = defaultdict(deque), threading.Lock()


def reset_rate_limit():
    with _hits_lock:
        _hits.clear()


def _rate_limited(user):
    now = time.monotonic()
    with _hits_lock:
        q = _hits[user["uid"]]
        while q and now - q[0] > RATE_WINDOW_S:
            q.popleft()
        if len(q) >= RATE_LIMIT:
            raise HTTPException(429, "Too many requests. Please try again later.",
                                headers={"Retry-After": str(RATE_WINDOW_S)})
        q.append(now)


def admin_only(user=Depends(admin_user)):
    _rate_limited(user)
    return user


def staff(user=Depends(reviewer_or_admin)):
    _rate_limited(user)
    return user


def clean(v):
    if isinstance(v, dict):
        return {k: clean(x) for k, x in v.items() if k.lower() not in SECRET_KEYS}
    if isinstance(v, list):
        return [clean(x) for x in v]
    return v


router = APIRouter(prefix="/admin")


CORS_PUBLIC_PATHS = ("/health", "/announcements")


async def admin_cors(request: Request, call_next):
    """CORS for the dashboard origins on /admin/*, /health and /announcements
    (middleware registered in main.py)."""
    path = request.url.path
    if not (path.startswith("/admin") or path in CORS_PUBLIC_PATHS):
        return await call_next(request)
    origin = request.headers.get("origin")
    ok = origin in ADMIN_ORIGINS
    headers = {"Access-Control-Allow-Origin": origin, "Vary": "Origin"} if ok else {}
    if request.method == "OPTIONS":
        if ok:
            headers.update({"Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE",
                            "Access-Control-Allow-Headers": "Authorization, Content-Type",
                            "Access-Control-Max-Age": "600"})
        return Response(status_code=204 if ok else 403, headers=headers)
    response = await call_next(request)
    response.headers.update(headers)
    if path.startswith("/admin"):
        response.headers["Cache-Control"] = "no-store"
    return response


# ---- Audit (admin writes only; stores uid_hash, never the uid) ----

def audit(db, action, admin_uid, target, before=None, after=None, role="admin"):
    """before/after must never hold secrets (links, tokens, keys, emails)."""
    db.audit_log.insert_one({"_id": uuid.uuid4().hex, "action": action,
                             "uid_hash": uid_hash(admin_uid), "admin": True, "role": role,
                             "target": target, "before": before, "after": after, "at": utcnow()})


# ---- Helpers ----

def _bad(msg="Invalid request."):
    raise HTTPException(400, msg)


def _encode(doc, field):
    raw = json.dumps({"t": doc[field].isoformat(), "id": doc["_id"]})
    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip("=")


def _decode(cursor):
    try:
        d = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
        return _utc(datetime.fromisoformat(d["t"])), str(d["id"])
    except (ValueError, KeyError, TypeError):
        _bad("Invalid cursor.")


def _range(q, field, from_, to):
    if from_ is not None or to is not None:
        q[field] = {}
        if from_ is not None:
            q[field]["$gte"] = _utc(from_)
        if to is not None:
            q[field]["$lte"] = _utc(to)


def _page(coll, q, field, limit, cursor):
    if cursor:
        t, i = _decode(cursor)
        q = {"$and": [q, {"$or": [{field: {"$lt": t}}, {field: t, "_id": {"$lt": i}}]}]}
    docs = list(coll.find(q).sort([(field, -1), ("_id", -1)]).limit(limit + 1))
    more = len(docs) > limit
    docs = docs[:limit]
    return docs, (_encode(docs[-1], field) if more and docs else None)


def _contains(text):
    return {"$regex": re.escape(text.strip()), "$options": "i"}


def _emails(db, uids):
    return {u["_id"]: u.get("email") for u in db.users.find({"_id": {"$in": list(set(uids))}},
                                                              {"email": 1})}


def _presign(storage, key):
    try:
        return storage.presigned_get(key) if key else None
    except Exception:
        return None


def _day_starts(days):
    """Midnights (Asia/Colombo) of the last `days` days, oldest first."""
    today = datetime.now(COLOMBO).replace(hour=0, minute=0, second=0, microsecond=0)
    return [today - timedelta(days=i) for i in range(days - 1, -1, -1)]


def _day_expr(field):
    return {"$dateToString": {"format": "%Y-%m-%d", "date": field, "timezone": "Asia/Colombo"}}


def _mean(x):
    return None if x is None else round(x, 4)


REFERRED = {"$sum": {"$cond": [{"$eq": ["$result.referred", True]}, 1, 0]}}


# ---- Stats ----

@router.get("/stats/summary")
def stats_summary(request: Request, days: int = Query(7), user=Depends(admin_only),
                  db=Depends(get_db)):
    if days not in (1, 7, 30):
        _bad("days must be 1, 7 or 30.")
    since = utcnow() - timedelta(days=days)
    # All gradings the model produced count, including ones the user later hid.
    g = list(db.gradings.aggregate([
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {"_id": None, "n": {"$sum": 1}, "referred": REFERRED,
                    "conf": {"$avg": "$result.confidence"},
                    "unc": {"$avg": "$result.uncertainty"},
                    "lat": {"$avg": "$result.timings_ms.total"},
                    "users": {"$addToSet": "$uid"}}}]))
    g = g[0] if g else {"n": 0, "referred": 0, "conf": None, "unc": None, "lat": None, "users": []}
    dist = {str(r["_id"]): r["n"] for r in db.gradings.aggregate([
        {"$match": {"created_at": {"$gte": since}, "result.grade": {"$gte": 1, "$lte": 7}}},
        {"$group": {"_id": "$result.grade", "n": {"$sum": 1}}}])}
    rej = {r["_id"]: r["n"] for r in db.rejections.aggregate([
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {"_id": "$status", "n": {"$sum": 1}}}])}
    rej_users = db.rejections.distinct("uid", {"created_at": {"$gte": since}})
    rejected = sum(rej.values())
    attempts = g["n"] + rejected
    try:
        db.client.admin.command("ping")
        db_ok = True
    except Exception:
        db_ok = False
    assets = request.app.state.assets
    return {
        "days": days, "since": since,
        "gradings": g["n"], "unique_users": len(set(g["users"]) | set(rej_users)),
        "referred": g["referred"],
        "referral_rate": round(g["referred"] / g["n"], 4) if g["n"] else None,
        "rejections": rejected, "rejections_by_status": rej,
        "rejection_rate": round(rejected / attempts, 4) if attempts else None,
        "avg_confidence": _mean(g["conf"]), "avg_uncertainty": _mean(g["unc"]),
        "avg_latency_ms": _mean(g["lat"]),
        "grade_distribution": {str(k): dist.get(str(k), 0) for k in range(1, 8)},
        "certificates_issued": db.certificates.count_documents({"issued_at": {"$gte": since}}),
        "feedback_count": db.feedback.count_documents({"created_at": {"$gte": since}}),
        "server": {"status": "ok" if assets is not None else "degraded",
                   "models_loaded": assets is not None,
                   "model_version": model_version(assets) if assets is not None else "unknown"},
        "database": {"status": "ok" if db_ok else "down"},
    }


TS_METRICS = ("gradings", "rejections", "referral_rate", "avg_confidence")


@router.get("/stats/timeseries")
def stats_timeseries(metric: str = Query(...), days: int = Query(30, ge=1, le=90),
                     bucket: str = Query("day"), user=Depends(admin_only), db=Depends(get_db)):
    if metric not in TS_METRICS or bucket != "day":
        _bad("Unknown metric or bucket.")
    starts = _day_starts(days)
    since = starts[0].astimezone(timezone.utc)
    if metric == "rejections":
        rows = db.rejections.aggregate([
            {"$match": {"created_at": {"$gte": since}}},
            {"$group": {"_id": _day_expr("$created_at"), "n": {"$sum": 1}}}])
        vals = {r["_id"]: r["n"] for r in rows}
        zero = 0
    else:
        rows = db.gradings.aggregate([
            {"$match": {"created_at": {"$gte": since}}},
            {"$group": {"_id": _day_expr("$created_at"), "n": {"$sum": 1}, "referred": REFERRED,
                        "conf": {"$avg": "$result.confidence"}}}])
        vals = {}
        for r in rows:
            vals[r["_id"]] = {"gradings": r["n"],
                              "referral_rate": round(r["referred"] / r["n"], 4),
                              "avg_confidence": _mean(r["conf"])}[metric]
        zero = 0 if metric == "gradings" else None
    return {"metric": metric, "bucket": "day", "timezone": "Asia/Colombo",
            "points": [{"day": d.strftime("%Y-%m-%d"), "value": vals.get(d.strftime("%Y-%m-%d"), zero)}
                       for d in starts]}


# ---- Users ----

def _firebase_flags(db, uids):
    """{uid: (role, disabled)} from Firebase (role "admin" | "reviewer" | "none").
    If Firebase is unreachable, role is None and disabled comes from the marker."""
    out = {}
    try:
        for i in range(0, len(uids), 100):
            res = firebase_auth.get_users([firebase_auth.UidIdentifier(u) for u in uids[i:i + 100]])
            for fb in res.users:
                c = fb.custom_claims or {}
                role = "admin" if c.get("admin") is True else (
                    "reviewer" if c.get("reviewer") is True else "none")
                out[fb.uid] = (role, bool(fb.disabled))
        return out
    except Exception:
        marked = {m["_id"] for m in db.disabled_accounts.find(
            {"_id": {"$in": [uid_hash(u) for u in uids]}}, {"_id": 1})}
        return {u: (None, uid_hash(u) in marked) for u in uids}


@router.get("/users")
def list_users(q: Optional[str] = Query(None, max_length=100), sort: str = Query("created"),
               limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
               role: Optional[str] = Query(None), disabled: Optional[bool] = None,
               user=Depends(admin_only), db=Depends(get_db)):
    if sort not in ("created", "last_active"):
        _bad("sort must be created or last_active.")
    if role is not None and role not in ("admin", "reviewer", "none"):
        _bad("role must be admin, reviewer or none.")
    try:
        offset = int(cursor) if cursor else 0
        if offset < 0:
            raise ValueError
    except ValueError:
        _bad("Invalid cursor.")
    query = {"$or": [{"email": _contains(q)}, {"display_name": _contains(q)}]} if q and q.strip() else {}
    docs = list(db.users.find(query).limit(5000))
    last = {}
    for coll in (db.gradings, db.calibrations):
        for r in coll.aggregate([{"$group": {"_id": "$uid", "t": {"$max": "$created_at"}}}]):
            if r["t"] and (r["_id"] not in last or r["t"] > last[r["_id"]]):
                last[r["_id"]] = r["t"]
    floor = datetime.min.replace(tzinfo=timezone.utc)

    def key(d):
        if sort == "last_active":
            t = last.get(d["_id"]) or d.get("created_at")
        else:
            t = d.get("created_at")
        return (_utc(t) or floor, d["_id"])

    docs.sort(key=key, reverse=True)
    filtered = role is not None or disabled is not None
    flags = _firebase_flags(db, [d["_id"] for d in docs]) if filtered else {}
    if filtered:
        docs = [d for d in docs if (role is None or flags.get(d["_id"], (None, None))[0] == role)
                and (disabled is None or flags.get(d["_id"], (None, None))[1] == disabled)]
    page = docs[offset:offset + limit]
    if not filtered:
        flags = _firebase_flags(db, [d["_id"] for d in page])
    items = [{"uid": d["_id"], "email": d.get("email"), "display_name": d.get("display_name"),
              "account_type": d.get("account_type"), "country": d.get("country"),
              "created_at": d.get("created_at"), "last_active": last.get(d["_id"]) or d.get("created_at"),
              "role": flags.get(d["_id"], (None, None))[0],
              "disabled": flags.get(d["_id"], (None, None))[1]}
             for d in page]
    return clean({"items": items,
                  "next_cursor": str(offset + limit) if offset + limit < len(docs) else None})


@router.get("/users/{uid}")
def get_user(uid: str, user=Depends(admin_only), db=Depends(get_db)):
    doc = db.users.find_one({"_id": uid})
    if doc is None:
        raise HTTPException(404, NOT_FOUND)
    disabled = last_sign_in = role = None
    try:
        fb = firebase_auth.get_user(uid)
        disabled = fb.disabled
        c = fb.custom_claims or {}
        role = "admin" if c.get("admin") is True else ("reviewer" if c.get("reviewer") is True else "none")
        ms = fb.user_metadata.last_sign_in_timestamp
        last_sign_in = datetime.fromtimestamp(ms / 1000, timezone.utc) if ms else None
    except Exception:
        pass
    counts = {n: getattr(db, n).count_documents({"uid": uid})
              for n in ("gradings", "rejections", "calibrations", "certificates", "feedback")}
    grad = db.gradings.find({"uid": uid, "deleted": False}).sort("created_at", -1).limit(10)
    cals = db.calibrations.find({"uid": uid}).sort("created_at", -1).limit(10)
    devices = sorted({d for c in (db.gradings, db.calibrations)
                      for d in c.distinct("device", {"uid": uid}) if d})
    profile = {k: doc.get(k) for k in ("email", "display_name", "account_type", "role", "country",
                                       "phone", "company", "created_at", "updated_at")}
    profile["uid"] = uid
    return clean({"profile": profile, "settings": doc.get("settings") or {}, "counts": counts,
                  "last_gradings": [_grading_row(g, None, None) for g in grad],
                  "calibrations": [_calibration_row(c) for c in cals],
                  "devices": devices, "disabled": disabled, "last_sign_in": last_sign_in,
                  "role": role})


# ---- Gradings (reviewers allowed; no email for them) ----

def _grading_row(d, storage, emails):
    r = d.get("result") or {}
    row = {"grading_id": d["_id"], "stone_id": d.get("stone_id"), "uid": d["uid"],
           "created_at": d["created_at"], "status": d.get("status"),
           "grade": r.get("grade"), "grade_name": r.get("grade_name"),
           "confidence": r.get("confidence"), "uncertainty": r.get("uncertainty"),
           "referred": r.get("referred"), "model_version": r.get("model_version"),
           "warnings": r.get("warnings") or [], "device": d.get("device"),
           "app_version": d.get("app_version")}
    if storage is not None:
        row["image_url"] = _presign(storage, d.get("image_key"))
    if emails is not None:
        row["user_email"] = emails.get(d["uid"])
    return row


@router.get("/gradings")
def list_gradings(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
    grade: Optional[int] = Query(None, ge=1, le=7), referred: Optional[bool] = None,
    model_version: Optional[str] = Query(None, max_length=50),
    uid: Optional[str] = Query(None, max_length=128),
    device: Optional[str] = Query(None, max_length=200),
    status: Optional[str] = Query(None, max_length=30),
    user=Depends(staff), db=Depends(get_db), storage=Depends(get_storage),
):
    q = {"deleted": False}
    _range(q, "created_at", from_, to)
    for field, val in (("result.grade", grade), ("result.referred", referred),
                       ("result.model_version", model_version), ("uid", uid), ("status", status)):
        if val is not None:
            q[field] = val
    if device:
        q["device"] = _contains(device)
    docs, nxt = _page(db.gradings, q, "created_at", limit, cursor)
    emails = _emails(db, [d["uid"] for d in docs]) if user["role"] == "admin" else None
    return clean({"items": [_grading_row(d, storage, emails) for d in docs], "next_cursor": nxt})


@router.get("/gradings/{grading_id}")
def get_grading(grading_id: str, user=Depends(staff), db=Depends(get_db),
                storage=Depends(get_storage)):
    d = db.gradings.find_one({"_id": grading_id, "deleted": False})
    if d is None:
        raise HTTPException(404, NOT_FOUND)
    emails = _emails(db, [d["uid"]]) if user["role"] == "admin" else None
    out = _grading_row(d, storage, emails)
    out.update(result=d.get("result"), calibration_session_id=d.get("calibration_session_id"),
               referral_threshold_used=d.get("referral_threshold_used"), heatmap_url=None)
    hm = d.get("heatmap")
    if hm:
        try:
            if storage.exists(hm["key"]):
                out["heatmap_url"] = storage.presigned_get(hm["key"])
        except Exception:
            pass
    cert = db.certificates.find_one({"grading_id": d["_id"]}, sort=[("issued_at", -1)])
    rv = db.reviews.find_one({"grading_id": d["_id"]})
    out["review"] = None if rv is None else {
        "gemologist_grade": rv.get("gemologist_grade"), "agrees": rv.get("agrees"),
        "notes": rv.get("notes"), "reviewed_at": rv.get("updated_at") or rv.get("created_at")}
    out["certificate"] = None if cert is None else {
        "cert_no": cert["_id"], "status": cert.get("status"), "issued_at": cert.get("issued_at")}
    return clean(out)


# ---- Calibrations, feedback, certificates, audit log ----

def _calibration_row(c):
    return {"calibration_id": c["_id"], "uid": c["uid"], "session_id": c.get("session_id"),
            "created_at": c.get("created_at"), "valid_until": c.get("valid_until"),
            "device": c.get("device"), "residual": c.get("residual"), "quality": c.get("quality")}


@router.get("/calibrations")
def list_calibrations(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
    uid: Optional[str] = Query(None, max_length=128),
    device: Optional[str] = Query(None, max_length=200),
    quality: Optional[str] = Query(None, max_length=50),
    user=Depends(admin_only), db=Depends(get_db),
):
    q = {}
    _range(q, "created_at", from_, to)
    if uid:
        q["uid"] = uid
    if device:
        q["device"] = _contains(device)
    if quality:
        q["quality"] = quality
    docs, nxt = _page(db.calibrations, q, "created_at", limit, cursor)
    return clean({"items": [_calibration_row(c) for c in docs], "next_cursor": nxt})


@router.get("/feedback")
def list_feedback(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
    rating: Optional[int] = Query(None, ge=1, le=5),
    category: Optional[str] = Query(None, max_length=30),
    uid: Optional[str] = Query(None, max_length=128),
    user=Depends(admin_only), db=Depends(get_db),
):
    q = {}
    _range(q, "created_at", from_, to)
    for field, val in (("rating", rating), ("category", category), ("uid", uid)):
        if val is not None:
            q[field] = val
    docs, nxt = _page(db.feedback, q, "created_at", limit, cursor)
    items = [{"feedback_id": f["_id"], "uid": f["uid"],
              **{k: f.get(k) for k in ("created_at", "rating", "category", "comment", "app_version",
                                       "status_note", "status_at")},
              "status": f.get("status") or "open"}
             for f in docs]
    return clean({"items": items, "next_cursor": nxt})


@router.get("/certificates")
def list_certificates(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    q: Optional[str] = Query(None, max_length=40),
    status: Optional[str] = Query(None, max_length=20),
    user=Depends(admin_only), db=Depends(get_db),
):
    query = {}
    if q and q.strip():
        query["_id"] = {"$regex": "^" + re.escape(q.strip().upper())}
    if status:
        query["status"] = status
    docs, nxt = _page(db.certificates, query, "issued_at", limit, cursor)
    items = [{"cert_no": c["_id"], "uid": c.get("uid"), "grading_id": c.get("grading_id"),
              **{k: c.get(k) for k in ("status", "issued_at", "snapshot", "owner", "pdf_sha256",
                                       "pdf_uploaded_at", "revoked_reason", "revoked_at",
                                       "withdrawn_at", "superseded_by")}} for c in docs]
    return clean({"items": items, "next_cursor": nxt})


@router.get("/audit-log")
def list_audit_log(
    limit: int = Query(25, ge=1, le=100), cursor: Optional[str] = None,
    from_: Optional[datetime] = Query(None, alias="from"), to: Optional[datetime] = None,
    action: Optional[str] = Query(None, max_length=60),
    user=Depends(admin_only), db=Depends(get_db),
):
    q = {}
    _range(q, "at", from_, to)
    if action:
        q["action"] = action
    docs, nxt = _page(db.audit_log, q, "at", limit, cursor)
    items = [{"audit_id": a["_id"],
              **{k: a.get(k) for k in ("action", "uid_hash", "admin", "target", "before", "after", "at")}}
             for a in docs]
    return clean({"items": items, "next_cursor": nxt})


# ---- Model monitoring ----

@router.get("/model/monitoring")
def model_monitoring(days: int = Query(30, ge=1, le=90), user=Depends(admin_only),
                     db=Depends(get_db)):
    since = _day_starts(days)[0].astimezone(timezone.utc)
    unusual = {"$in": ["unusual_image", {"$ifNull": ["$result.warnings", []]}]}
    rows = db.gradings.aggregate([
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {"_id": {"v": "$result.model_version", "day": _day_expr("$created_at")},
                    "n": {"$sum": 1}, "referred": REFERRED,
                    "conf": {"$avg": "$result.confidence"}, "unc": {"$avg": "$result.uncertainty"},
                    "unusual": {"$sum": {"$cond": [unusual, 1, 0]}},
                    "lat": {"$avg": "$result.timings_ms.total"}}}])
    versions = defaultdict(list)
    for r in rows:
        versions[r["_id"]["v"] or "unknown"].append({
            "day": r["_id"]["day"], "count": r["n"], "mean_confidence": _mean(r["conf"]),
            "mean_uncertainty": _mean(r["unc"]), "referral_rate": round(r["referred"] / r["n"], 4),
            "unusual_image": r["unusual"], "mean_latency_ms": _mean(r["lat"])})
    # Rejections store model_version from Phase 10b on; older records are "unknown".
    gates = [{"day": r["_id"]["day"], "gate": r["_id"]["s"],
              "model_version": r["_id"].get("v") or "unknown", "count": r["n"]} for r in
             db.rejections.aggregate([
                 {"$match": {"created_at": {"$gte": since}}},
                 {"$group": {"_id": {"day": _day_expr("$created_at"), "s": "$status",
                                     "v": "$model_version"}, "n": {"$sum": 1}}}])]
    # Review agreement per version and grading day (reviews joined to their gradings).
    agree = defaultdict(lambda: defaultdict(lambda: [0, 0]))
    for g_created, version, _model, _gem, same in review_rows(db, since):
        cell = agree[version or "unknown"][g_created.astimezone(COLOMBO).strftime("%Y-%m-%d")]
        cell[0] += 1
        cell[1] += 1 if same else 0
    out = []
    for v, d in sorted(versions.items()):
        out.append({"model_version": v, "days": sorted(d, key=lambda x: x["day"]),
                    "review_agreement": [
                        {"day": day, "reviewed": n, "agreed": k, "agreement_rate": round(k / n, 4)}
                        for day, (n, k) in sorted(agree.get(v, {}).items())]})
    return {"days": days, "timezone": "Asia/Colombo", "versions": out,
            "rejections_by_gate": sorted(gates, key=lambda x: (x["day"], x["gate"], x["model_version"]))}


def review_rows(db, since=None):
    """(grading created_at, model_version, model_grade, gemologist_grade, agrees) for every
    review whose grading still exists, optionally only gradings created since `since`."""
    reviews = {r["grading_id"]: r for r in db.reviews.find().limit(50000)}
    q = {"_id": {"$in": list(reviews)}}
    if since is not None:
        q["created_at"] = {"$gte": since}
    rows = []
    for g in db.gradings.find(q, {"created_at": 1, "result.grade": 1, "result.model_version": 1}):
        r = reviews[g["_id"]]
        mg = (g.get("result") or {}).get("grade")
        rows.append((g["created_at"], (g.get("result") or {}).get("model_version"), mg,
                     r["gemologist_grade"], mg == r["gemologist_grade"]))
    return rows
