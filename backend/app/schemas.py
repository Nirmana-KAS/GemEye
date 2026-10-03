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


class Timings(BaseModel):
    total: float
    preprocess: float
    rf: float
    cnn: float


class Diagnostics(BaseModel):
    blur_variance: float
    stone_area_fraction: float
    hue_physical: float
    ood_distance: float
    ood_threshold: float


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


class HealthResponse(BaseModel):
    status: str
    model_version: str
    models_loaded: bool
    versions: Dict[str, str]
    ciecam02_display_available: bool


class ErrorResponse(BaseModel):
    status: str = "error"
    detail: str
