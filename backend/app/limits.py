"""Daily grading limit and blocked devices (Phase 10p), checked by POST /grade and
POST /calibrations.

The daily limit counts a user's saved gradings (status ok, including ones they deleted or
an admin hid) since midnight Asia/Colombo. A user's own `daily_grading_limit` wins; when it
is null the config `daily_grading_limit_default` applies, and null there means no limit.
Devices (Phase 10p-fix): the app sends a random per-install UUID in X-Device-Id;
device_id is a short hash of it. Old app builds without the header fall back to a hash
of the reported phone model. Blocking applies to one device_id only."""
import hashlib
import uuid
from datetime import timezone
from zoneinfo import ZoneInfo

from app.db import utcnow
from app.errors import ApiError

COLOMBO = ZoneInfo("Asia/Colombo")
DAILY_LIMIT_BOUNDS = (1, 500)
DAILY_LIMIT_MESSAGE = "Daily grading limit reached. Try again tomorrow or contact support."
DEVICE_BLOCKED_MESSAGE = "This device is blocked. Contact support."
DEVICE_ID_PATTERN = r"^[0-9a-f]{24}$"
DEVICE_HEADER = "X-Device-Id"


def _now():
    return utcnow()


def device_id(name):
    """Legacy id: hash of the phone model name (records and app builds without X-Device-Id)."""
    return hashlib.sha256(name.strip().encode()).hexdigest()[:24]


def install_device_id(raw):
    """Hash of a valid X-Device-Id UUID, else None."""
    try:
        u = uuid.UUID((raw or "").strip())
    except ValueError:
        return None
    return hashlib.sha256(f"install:{u}".encode()).hexdigest()[:24]


def request_device_id(header, model):
    """device_id of a request: the install id, or the model hash when the header is missing."""
    did = install_device_id(header)
    if did:
        return did
    model = (model or "").strip()
    return device_id(model) if model else None


def record_device_id(doc):
    """device_id of a stored grading or calibration (older ones have only the model name)."""
    if doc.get("device_id"):
        return doc["device_id"]
    model = (doc.get("device") or "").strip()
    return device_id(model) if model else None


def colombo_day_start(now):
    """UTC instant of the last midnight in Asia/Colombo at `now`."""
    local = now.astimezone(COLOMBO).replace(hour=0, minute=0, second=0, microsecond=0)
    return local.astimezone(timezone.utc)


def effective_limit(profile, config):
    v = (profile or {}).get("daily_grading_limit")
    if v is None:
        v = (config or {}).get("daily_grading_limit_default")
    return v if isinstance(v, int) and not isinstance(v, bool) and v > 0 else None


def gradings_today(db, uid, now=None):
    start = colombo_day_start(now or _now())
    return db.gradings.count_documents({"uid": uid, "status": "ok", "created_at": {"$gte": start}})


def check_daily_limit(db, uid, profile, config):
    limit = effective_limit(profile, config)
    if limit is not None and gradings_today(db, uid) >= limit:
        raise ApiError(429, "DAILY_LIMIT_REACHED", DAILY_LIMIT_MESSAGE)


def check_device(db, did):
    if did and db.blocked_devices.find_one({"_id": did}, {"_id": 1}) is not None:
        raise ApiError(403, "DEVICE_BLOCKED", DEVICE_BLOCKED_MESSAGE)
