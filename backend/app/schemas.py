"""Request and response schemas."""
from datetime import datetime
from typing import Any, Dict, List, Literal, Optional, Union

from pydantic import BaseModel, ConfigDict, Field, field_validator


class Ciecam02(BaseModel):
    J: float
    M: float
    h: float
    s: float
    C: float


class ColourValues(BaseModel):
    L: float
    a: float
    b: float
    C: float
    H: float
    S: float
    B: float
    hex: str
    ciecam02: Optional[Ciecam02]
    approximate: bool


class Timings(BaseModel):
    total: float
    preprocess: float
    rf: float
    cnn: float


class Diagnostics(BaseModel):
    """Gate measurements and thresholds. On a rejection only the values measured
    up to the failing gate are present."""
    short_side_px: Optional[int] = None
    min_short_side_px: Optional[int] = None
    blur_variance: Optional[float] = None
    blur_min_variance: Optional[float] = None
    gate_stone_area: Optional[float] = None
    no_stone_min_area: Optional[float] = None
    stone_tray_contrast_de00: Optional[float] = None
    no_stone_min_contrast_de00: Optional[float] = None
    gate_centre_fallback: Optional[bool] = None
    hue_wb: Optional[float] = None
    hue_gate_min: Optional[float] = None
    hue_gate_max: Optional[float] = None
    hue_in_gate: Optional[bool] = None
    chroma_wb: Optional[float] = None
    min_chroma: Optional[float] = None
    segmentation_reliable: Optional[bool] = None
    hue_gate_skipped: Optional[bool] = None
    stone_area_fraction: Optional[float] = None
    model_segmentation_fallback: Optional[bool] = None
    ood_distance: Optional[float] = None
    ood_warn: Optional[float] = None
    ood_threshold: Optional[float] = None


class DebugInfo(BaseModel):
    """Development only (ENV=development and debug=true)."""
    rf_grade: int
    rf_probabilities: List[float]
    cnn_mc_grade: int
    cnn_mc_probabilities: List[float]
    cnn_deterministic_grade: int
    cnn_deterministic_probabilities: List[float]
    model_segmentation_fallback: bool
    gates_bypassed: List[str]      # gates that failed while gates=false (parity test)


class GradeResponse(BaseModel):
    """status is "ok", or a gate code (invalid_image, blurry, no_stone, not_blue,
    not_recognised) with a message and diagnostics but no grade."""
    status: str
    message: Optional[str] = None
    warnings: Optional[List[str]] = None
    grade: Optional[int] = None
    grade_name: Optional[str] = None
    trade_name: Optional[str] = None
    probabilities: Optional[List[float]] = None
    confidence: Optional[float] = None
    uncertainty: Optional[float] = None
    referred: Optional[bool] = None
    second_grade: Optional[int] = None
    colour: Optional[ColourValues] = None
    delta_e00_to_typical: Optional[float] = None
    calibration_mode: Optional[str] = None
    model_version: Optional[str] = None
    timings_ms: Optional[Timings] = None
    diagnostics: Diagnostics
    debug: Optional[DebugInfo] = None
    # Set when status is "ok" and the grading was saved.
    grading_id: Optional[str] = None
    stone_id: Optional[str] = None
    image_url: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    model_version: str
    models_loaded: bool
    versions: Dict[str, str]
    ciecam02_display_available: bool


class ErrorResponse(BaseModel):
    status: str = "error"
    detail: str


# ---- Users ----

Text = Optional[str]


def _text(n):
    return Field(None, max_length=n)


class CompanyUpdate(BaseModel):
    model_config = ConfigDict(extra="ignore")
    name: Text = _text(200)
    reg_no: Text = _text(100)
    industry: Text = _text(100)
    address: Text = _text(500)
    logo_key: Text = _text(300)


class UserSettingsUpdate(BaseModel):
    model_config = ConfigDict(extra="ignore")
    show_name_on_certificates: Optional[bool] = None
    referral_threshold: Optional[float] = Field(None, ge=0.40, le=0.90)


class ProfileUpdate(BaseModel):
    """PUT /me body. Unknown fields (including role, email, uid) are ignored."""
    model_config = ConfigDict(extra="ignore")
    display_name: Text = _text(100)
    account_type: Optional[Literal["individual", "company"]] = None
    country: Text = _text(100)
    phone: Text = _text(30)
    company: Optional[CompanyUpdate] = None
    settings: Optional[UserSettingsUpdate] = None


class Company(BaseModel):
    name: Text = None
    reg_no: Text = None
    industry: Text = None
    address: Text = None
    logo_key: Text = None


class UserSettings(BaseModel):
    show_name_on_certificates: bool = False
    referral_threshold: float = 0.60


class UserResponse(BaseModel):
    uid: str
    email: Text = None
    email_verified: bool
    display_name: Text = None
    account_type: Text = None
    role: Text = None
    country: Text = None
    phone: Text = None
    company: Company
    settings: UserSettings
    created_at: datetime
    updated_at: datetime


# ---- Gradings ----

class GradingItem(BaseModel):
    grading_id: str
    stone_id: str
    created_at: datetime
    status: str
    result: Dict[str, Any]
    image_url: Optional[str] = None
    calibration_session_id: Text = None
    app_version: Text = None
    device: Text = None
    referral_threshold_used: float


class GradingList(BaseModel):
    items: List[GradingItem]
    next_cursor: Optional[str] = None


# ---- Calibrations ----

class CalibrationIn(BaseModel):
    model_config = ConfigDict(extra="ignore")
    session_id: str = Field(min_length=1, max_length=100)
    valid_until: Optional[datetime] = None
    device: Text = _text(200)
    ccm: List[List[float]]
    residual: Optional[float] = None
    quality: Optional[Union[float, str]] = None
    measured_patches: List[List[float]]

    @field_validator("ccm")
    @classmethod
    def _ccm(cls, v):
        if len(v) != 3 or any(len(r) != 3 for r in v):
            raise ValueError("ccm must be 3x3")
        return v

    @field_validator("measured_patches")
    @classmethod
    def _patches(cls, v):
        if len(v) != 6 or any(len(r) != 3 for r in v) or any(not 0 <= x <= 255 for r in v for x in r):
            raise ValueError("measured_patches must be 6x3, 0-255")
        return v

    @field_validator("quality")
    @classmethod
    def _quality(cls, v):
        if isinstance(v, str) and len(v) > 50:
            raise ValueError("quality too long")
        return v


class CalibrationItem(BaseModel):
    calibration_id: str
    session_id: str
    created_at: datetime
    valid_until: Optional[datetime] = None
    device: Text = None
    ccm: List[List[float]]
    residual: Optional[float] = None
    quality: Optional[Union[float, str]] = None
    measured_patches: List[List[float]]


class CalibrationList(BaseModel):
    items: List[CalibrationItem]


# ---- Certificates ----

class CertificateIn(BaseModel):
    model_config = ConfigDict(extra="ignore")
    grading_id: str = Field(min_length=1, max_length=100)


class RevokeIn(BaseModel):
    model_config = ConfigDict(extra="ignore")
    reason: str = Field(min_length=1, max_length=500)


class CalibrationRef(BaseModel):
    session_id: str
    residual: Optional[float] = None


class CertificateSnapshot(BaseModel):
    """Frozen at issue time; later changes to the grading or profile do not affect it."""
    stone_id: str
    grade: int
    grade_name: str
    trade_name: str
    confidence: float
    uncertainty: float
    referred: bool
    colour: ColourValues
    delta_e00_to_typical: Optional[float] = None
    model_version: str
    captured_at: datetime
    issued_at: datetime
    calibration: Optional[CalibrationRef] = None


class CertificateOwner(BaseModel):
    display_name: Text = None
    company: Text = None


class CertificateIssued(BaseModel):
    cert_no: str
    verify_url: str
    issued_at: datetime


class CertificateItem(BaseModel):
    cert_no: str
    grading_id: str
    status: Literal["valid", "revoked"]
    issued_at: datetime
    verify_url: str
    snapshot: CertificateSnapshot
    owner: Optional[CertificateOwner] = None
    pdf_sha256: Text = None
    pdf_uploaded_at: Optional[datetime] = None
    revoked_reason: Text = None
    revoked_at: Optional[datetime] = None


class CertificateList(BaseModel):
    items: List[CertificateItem]
    next_cursor: Optional[str] = None


class PublicCertificate(BaseModel):
    """GET /public/v/{slug}. Never contains the owner's uid or email."""
    cert_no: str
    status: Literal["valid", "revoked", "withdrawn"]
    issued_at: datetime
    snapshot: Optional[CertificateSnapshot] = None
    owner: Optional[CertificateOwner] = None
    revoked_reason: Text = None
    revoked_at: Optional[datetime] = None
    image_url: Text = None
    pdf_url: Text = None
    pdf_sha256: Text = None
    disclaimer: str


# ---- Remote config and feedback ----

class Maintenance(BaseModel):
    enabled: bool
    message: str


class Features(BaseModel):
    model_config = ConfigDict(extra="allow")
    repeatability_mode: bool
    gradcam: bool
    public_verification: bool
    session_mapping: bool = False


class AppConfig(BaseModel):
    model_config = ConfigDict(extra="allow")
    referral_threshold_default: float
    calibration_validity_hours: int
    min_app_version: str
    maintenance: Maintenance
    features: Features
    blur_min_variance: float


class FeedbackIn(BaseModel):
    model_config = ConfigDict(extra="ignore")
    rating: int = Field(ge=1, le=5)
    category: Literal["accuracy", "app", "calibration", "other"]
    comment: Text = _text(500)
    app_version: Text = _text(50)


class FeedbackOut(BaseModel):
    feedback_id: str
    created_at: datetime
