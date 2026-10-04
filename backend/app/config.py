"""Runtime settings, read from environment variables (docker compose env_file).

Secrets are SecretStr so they never appear in reprs or logs; log only set/missing."""
from functools import lru_cache
from typing import Literal, Optional

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

# ENV -> (MongoDB database, S3 key prefix)
ENVIRONMENTS = {
    "development": ("gemeye_dev", "dev/"),
    "test": ("gemeye_test", "test/"),
    "production": ("gemeye", ""),
}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore", case_sensitive=False, protected_namespaces=())

    model_dir: str = "models"
    export_dir: str = "export"
    env: Literal["development", "test", "production"] = "development"

    referral_threshold: float = 0.60
    max_upload_mb: int = 15

    mongodb_uri: Optional[SecretStr] = None
    aws_region: Optional[str] = None
    aws_access_key_id: Optional[SecretStr] = None
    aws_secret_access_key: Optional[SecretStr] = None
    s3_bucket: Optional[str] = None
    firebase_credentials: Optional[str] = None
    firebase_web_api_key: Optional[SecretStr] = None    # tests only

    @property
    def db_name(self) -> str:
        return ENVIRONMENTS[self.env][0]

    @property
    def s3_prefix(self) -> str:
        return ENVIRONMENTS[self.env][1]

    @property
    def is_production(self) -> bool:
        return self.env == "production"

    def status(self) -> dict:
        """Which settings are configured, as "set"/"missing" (never the values)."""
        names = ("mongodb_uri", "aws_region", "aws_access_key_id", "aws_secret_access_key",
                 "s3_bucket", "firebase_credentials", "firebase_web_api_key")
        return {n: "set" if getattr(self, n) else "missing" for n in names}


@lru_cache
def get_settings() -> Settings:
    return Settings()
