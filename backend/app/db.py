"""MongoDB access. One MongoClient per process, created in the app lifespan.
All timestamps are timezone-aware UTC."""
import copy
import threading
import time
from datetime import datetime, timezone

from pymongo import ASCENDING, DESCENDING, MongoClient, ReturnDocument

DEFAULT_USER_SETTINGS = {"show_name_on_certificates": False, "referral_threshold": 0.60}

# Remote config (app_config/"global"), seeded at startup if missing. Fields missing
# from the stored document fall back to these defaults.
DEFAULT_APP_CONFIG = {
    "referral_threshold_default": 0.60,
    "calibration_validity_hours": 8,
    "min_app_version": "1.0.0",
    "maintenance": {"enabled": False, "message": ""},
    "features": {"repeatability_mode": True, "gradcam": False, "public_verification": True},
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
        self._config, self._config_at = None, 0.0
        self._config_lock = threading.Lock()

    def ensure_indexes(self):
        self.gradings.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        self.rejections.create_index([("created_at", ASCENDING)])
        self.calibrations.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        self.certificates.create_index([("uid", ASCENDING), ("issued_at", DESCENDING)])
        # At most one valid certificate per grading (idempotent issue).
        self.certificates.create_index([("grading_id", ASCENDING)], unique=True,
                                       partialFilterExpression={"status": "valid"},
                                       name="one_valid_per_grading")
        self.feedback.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        # Tombstones of deleted accounts outlive any ID token issued before the deletion.
        self.deleted_accounts.create_index([("deleted_at", ASCENDING)],
                                           expireAfterSeconds=DELETED_ACCOUNT_TTL_S)
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
