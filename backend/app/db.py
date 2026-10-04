"""MongoDB access. One MongoClient per process, created in the app lifespan.
All timestamps are timezone-aware UTC."""
from datetime import datetime, timezone

from pymongo import ASCENDING, DESCENDING, MongoClient, ReturnDocument

DEFAULT_USER_SETTINGS = {"show_name_on_certificates": False, "referral_threshold": 0.60}


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

    def ensure_indexes(self):
        self.gradings.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        self.rejections.create_index([("created_at", ASCENDING)])
        self.calibrations.create_index([("uid", ASCENDING), ("created_at", DESCENDING)])
        # counters is looked up by _id, which MongoDB always indexes.

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
