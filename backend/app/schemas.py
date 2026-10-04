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
    blur_variance: float
    stone_area_fraction: float
    hue_physical: float
    hue_gate_min: float
    hue_gate_max: float
    hue_in_gate: bool
    segmentation_reliable: bool
    model_segmentation_fallback: bool
    ood_distance: float
    ood_threshold: float


class DebugInfo(BaseModel):
    """Development only (ENV=development and debug=true)."""
    rf_grade: int
    rf_probabilities: List[float]
    cnn_mc_grade: int
    cnn_mc_probabilities: List[float]
    cnn_deterministic_grade: int
    model_segmentation_fallback: bool


class GradeResponse(BaseModel):
    status: str
    grade: int
    grade_name: str
    trade_name: str
    probabilities: List[float]
    confidence: float
    uncertainty: float
    referred: bool
    second_grade: int
    colour: ColourValues
    delta_e00_to_typical: float
    calibration_mode: str
    model_version: str
    timings_ms: Timings
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
