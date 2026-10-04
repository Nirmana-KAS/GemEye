"""Response schemas."""
from typing import Dict, List, Optional

from pydantic import BaseModel


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


class HealthResponse(BaseModel):
    status: str
    model_version: str
    models_loaded: bool
    versions: Dict[str, str]
    ciecam02_display_available: bool


class ErrorResponse(BaseModel):
    status: str = "error"
    detail: str
