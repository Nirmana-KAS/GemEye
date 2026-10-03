"""Runtime settings, read from environment variables (docker compose env_file)."""
from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore", case_sensitive=False, protected_namespaces=())

    model_dir: str = "models"
    export_dir: str = "export"
    env: str = "development"

    referral_threshold: float = 0.60
    max_upload_mb: int = 15

    # Used in later phases; optional for now.
    mongodb_uri: Optional[str] = None
    mongodb_db: Optional[str] = None
    aws_region: Optional[str] = None
    s3_bucket: Optional[str] = None
    firebase_credentials: Optional[str] = None


@lru_cache
def get_settings() -> Settings:
    return Settings()
