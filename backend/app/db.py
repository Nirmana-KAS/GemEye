"""MongoDB access. One MongoClient per process, created in the app lifespan.
All timestamps are timezone-aware UTC."""
import copy
import threading
import time
from datetime import datetime, timezone

from pymongo import ASCENDING, DESCENDING, MongoClient, ReturnDocument

from app import gates

DEFAULT_USER_SETTINGS = {"show_name_on_certificates": False, "referral_threshold": 0.60}

# Remote config (app_config/"global"), seeded at startup if missing. Fields missing
# from the stored document fall back to these defaults.
DEFAULT_APP_CONFIG = {
    "referral_threshold_default": 0.60,
    "calibration_validity_hours": 24,
    "min_app_version": "1.0.0",
    # Shown by the app when its version is below min_app_version (empty = app default text).
    "update_message": "",
    "maintenance": {"enabled": False, "message": ""},
    "features": {"repeatability_mode": True, "gradcam": True, "public_verification": True,
                 "session_mapping": False},
    # Editable gate thresholds; the defaults are the original gates.py constants.
    "gates": dict(gates.DEFAULTS),
    # Base of the verify links of NEW certificates (existing ones keep theirs).
    "verify_base_url": "https://gemeye-app-2026.web.app",
}
CONFIG_CACHE_SECONDS = 60
DELETED_ACCOUNT_TTL_S = 2 * 3600    # ID tokens live at most 1 hour


def utcnow():
    return datetime.now(timezone.utc)


class Database:
    def __init__(self, uri, name):
        self.client = MongoClient(uri, tz_aware=True, serverSelectionTimeoutMS=10000,
                                  appname="gemeye-api")
        self.db = self.client[name]
        self.users = self.db["users"]
        self.gradings = self.db["gradings"]
        self.rejections = self.db["rejections"]
        self.calibrations = self.db["calibrations"]
        self.counters = self.db["counters"]
        self.certificates = self.db["certificates"]
        self.feedback = self.db["feedback"]
        self.app_config = self.db["app_config"]
        self.audit_log = self.db["audit_log"]
        self.deleted_accounts = self.db["deleted_accounts"]
        self.disabled_accounts = self.db["disabled_accounts"]
        self.announcements = self.db["announcements"]
        self.reviews = self.db["reviews"]
        self.notifications = self.db["notifications"]
        self.admin_broadcasts = self.db["admin_broadcasts"]
        self.admin_directory = self.db["admin_directory"]
        self._config, self._config_at = None, 0.0
        self._config_lock = threading.Lock()

    def ensure_indexes(self):
        self.gradings.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        # Idempotent /grade retries; only gradings sent with a request_id have the field.
        self.gradings.create_index([("request_id", ASCENDING)], unique=True, sparse=True,
                                   name="request_id_unique")
        self.rejections.create_index([("created_at", ASCENDING)])
        self.calibrations.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        # One calibration per (user, session): the app retries unsent sessions.
        self.calibrations.create_index([("uid", ASCENDING), ("session_id", ASCENDING)],
                                       unique=True, name="uid_session_unique")
        self.certificates.create_index([("uid", ASCENDING), ("issued_at", DESCENDING)])
        # At most one valid certificate per grading (idempotent issue).
        self.certificates.create_index([("grading_id", ASCENDING)], unique=True,
                                       partialFilterExpression={"status": "valid"},
                                       name="one_valid_per_grading")
        self.feedback.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        # Tombstones of deleted accounts outlive any ID token issued before the deletion.
        self.deleted_accounts.create_index([("deleted_at", ASCENDING)],
                                           expireAfterSeconds=DELETED_ACCOUNT_TTL_S)
        # Admin dashboard queries (Phase 10a).
        self.gradings.create_index([("created_at", DESCENDING), ("_id", DESCENDING)])
        self.gradings.create_index([("result.grade", ASCENDING), ("created_at", DESCENDING)])
        self.gradings.create_index([("result.model_version", ASCENDING), ("created_at", DESCENDING)])
        self.gradings.create_index([("device", ASCENDING), ("created_at", DESCENDING)])
        self.rejections.create_index([("status", ASCENDING), ("created_at", DESCENDING)])
        # Phase 10e: model monitoring by version, "reviewed by me" in the review queue.
        self.rejections.create_index([("model_version", ASCENDING), ("created_at", DESCENDING)])
        self.reviews.create_index([("reviewer_uid_hash", ASCENDING)])
        self.calibrations.create_index([("created_at", DESCENDING), ("_id", DESCENDING)])
        self.certificates.create_index([("issued_at", DESCENDING), ("_id", DESCENDING)])
        self.certificates.create_index([("status", ASCENDING), ("issued_at", DESCENDING)])
        self.feedback.create_index([("created_at", DESCENDING), ("_id", DESCENDING)])
        self.audit_log.create_index([("at", DESCENDING), ("_id", DESCENDING)])
        self.audit_log.create_index([("action", ASCENDING), ("at", DESCENDING)])
        self.users.create_index([("created_at", DESCENDING)])
        self.users.create_index([("email", ASCENDING)])
        # Phase 10b: one review per grading, announcement windows.
        self.reviews.create_index([("grading_id", ASCENDING)], unique=True, name="grading_unique")
        self.reviews.create_index([("created_at", DESCENDING)])
        self.announcements.create_index([("active", ASCENDING), ("starts_at", ASCENDING)])
        # Phase N1: notifications (user list newest first, cleared filter).
        self.notifications.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        self.notifications.create_index([("uid", ASCENDING), ("cleared_at", ASCENDING)])
        # Phase 10f: all users' notifications (admin), sent history.
        self.notifications.create_index([("created_at", DESCENDING), ("_id", DESCENDING)])
        self.notifications.create_index([("source", ASCENDING), ("created_at", DESCENDING)])
        self.admin_broadcasts.create_index([("at", DESCENDING), ("_id", DESCENDING)])
        self.admin_broadcasts.create_index([("target", ASCENDING), ("at", DESCENDING)])
        # counters, app_config and certificates (cert_no) are looked up by _id.

    def seed_app_config(self):
        """Creates app_config/"global" with the defaults if it does not exist."""
        self.app_config.update_one({"_id": "global"},
                                   {"$setOnInsert": copy.deepcopy(DEFAULT_APP_CONFIG)}, upsert=True)

    def get_app_config(self):
        """app_config/"global" without _id, cached in memory for 60 s. Falls back to
        the defaults (or the last cached value) if MongoDB cannot be read."""
        with self._config_lock:
            if self._config is not None and time.monotonic() - self._config_at < CONFIG_CACHE_SECONDS:
                return copy.deepcopy(self._config)
        try:
            doc = self.app_config.find_one({"_id": "global"}, {"_id": 0}) or {}
            cfg = copy.deepcopy(DEFAULT_APP_CONFIG)
            for k, v in doc.items():
                if isinstance(v, dict) and isinstance(cfg.get(k), dict):
                    cfg[k].update(v)
                else:
                    cfg[k] = v
        except Exception:
            with self._config_lock:
                return copy.deepcopy(self._config or DEFAULT_APP_CONFIG)
        with self._config_lock:
            self._config, self._config_at = cfg, time.monotonic()
        return copy.deepcopy(cfg)

    def invalidate_app_config(self):
        with self._config_lock:
            self._config, self._config_at = None, 0.0

    def close(self):
        self.client.close()

    def next_seq(self, name):
        """Atomic global counter."""
        doc = self.counters.find_one_and_update(
            {"_id": name}, {"$inc": {"seq": 1}}, upsert=True, return_document=ReturnDocument.AFTER)
        return doc["seq"]

    def ensure_user(self, uid, email):
        """Creates the user on first request; returns the user document."""
        now = utcnow()
        return self.users.find_one_and_update(
            {"_id": uid},
            {"$setOnInsert": {
                "email": email, "display_name": None, "account_type": "individual",
                "role": "user", "country": None, "phone": None,
                "company": {"name": None, "reg_no": None, "industry": None,
                            "address": None, "logo_key": None},
                "settings": dict(DEFAULT_USER_SETTINGS), "created_at": now, "updated_at": now,
            }},
            upsert=True, return_document=ReturnDocument.AFTER)
