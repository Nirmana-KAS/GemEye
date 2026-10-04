"""GemEye inference API (Phase 1)."""
import json
import logging
import platform
import threading
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.assets import load_assets, warm_up
from app.config import get_settings
from app.pipeline.colour import decode_image
from app.pipeline.inference import grade, rejection
from app.schemas import GradeResponse, HealthResponse

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("gemeye.api")

_lock = threading.Lock()

# Keep uploads up to the size limit in memory (Starlette spools >1 MB to a temp file).
try:
    from starlette.formparsers import MultiPartParser
    MultiPartParser.spool_max_size = (get_settings().max_upload_mb + 1) * 1024 * 1024
except (ImportError, AttributeError):
    pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.assets = None
    try:
        app.state.assets = load_assets(settings.model_dir, settings.export_dir)
        warm_up(app.state.assets)
    except Exception:
        logger.exception("Failed to load model assets")
    yield


app = FastAPI(title="GemEye API", version="1.0.0", lifespan=lifespan)


def _error(code, detail):
    return JSONResponse(status_code=code, content={"status": "error", "detail": detail})


@app.exception_handler(HTTPException)
async def http_error(request: Request, exc: HTTPException):
    return _error(exc.status_code, str(exc.detail))


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError):
    return _error(400, "Invalid request.")


@app.exception_handler(Exception)
async def generic_error(request: Request, exc: Exception):
    logger.exception("Unhandled error")
    return _error(500, "Internal server error.")


def _runtime_versions():
    import colour
    import cv2
    import joblib
    import keras
    import numpy
    import sklearn
    import tensorflow

    return {
        "python": platform.python_version(),
        "tensorflow": tensorflow.__version__,
        "keras": keras.__version__,
        "numpy": numpy.__version__,
        "scikit_learn": sklearn.__version__,
        "opencv": cv2.__version__,
        "colour_science": colour.__version__,
        "joblib": joblib.__version__,
    }


@app.get("/health", response_model=HealthResponse)
def health(request: Request):
    assets = request.app.state.assets
    return {
        "status": "ok" if assets is not None else "degraded",
        "model_version": "v3",
        "models_loaded": assets is not None,
        "versions": _runtime_versions(),
        "ciecam02_display_available": bool(assets and assets.ciecam02_display_available),
    }


def _parse_patches(raw):
    if raw is None or raw.strip() == "":
        return None
    try:
        p = json.loads(raw)
        ok = (isinstance(p, list) and len(p) == 6
              and all(isinstance(r, list) and len(r) == 3 for r in p)
              and all(isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 255
                      for r in p for v in r))
    except ValueError:
        ok = False
    if not ok:
        raise HTTPException(400, "patches must be a JSON 6x3 array of 0-255 values "
                                 "(white, black, grey_18, grey_50, blue, red).")
    return [[float(v) for v in r] for r in p]


@app.post("/grade", response_model=GradeResponse, response_model_exclude_unset=True)
def grade_stone(
    request: Request,
    image: UploadFile = File(...),
    patches: Optional[str] = Form(None),
    referral_threshold: Optional[float] = Form(None),
    debug: bool = Form(False),
    gates: bool = Form(True),
):
    settings = get_settings()
    assets = request.app.state.assets
    if assets is None:
        raise HTTPException(500, "Internal server error.")

    limit = settings.max_upload_mb * 1024 * 1024
    data = image.file.read(limit + 1)
    if len(data) > limit:
        raise HTTPException(413, f"Image is larger than {settings.max_upload_mb} MB.")
    if not (data[:3] == b"\xff\xd8\xff" or data[:8] == b"\x89PNG\r\n\x1a\n"):
        raise HTTPException(400, "Image must be a JPEG or PNG.")
    try:
        raw_rgb = decode_image(data)
    except ValueError:
        raw_rgb = None
    finally:
        del data

    threshold = settings.referral_threshold if referral_threshold is None else referral_threshold
    if not 0.40 <= threshold <= 0.90:
        raise HTTPException(400, "referral_threshold must be between 0.40 and 0.90.")
    p = _parse_patches(patches)
    if raw_rgb is None:
        # JPEG/PNG signature, but the image cannot be decoded.
        return rejection("invalid_image", {})

    # One request at a time through TF / GrabCut; nothing is written to disk.
    with _lock:
        # Debug fields and gates=false are honoured only in development.
        dev = settings.env.lower() == "development"
        return grade(assets, raw_rgb, p, threshold, debug=debug and dev,
                     enforce_gates=gates or not dev)
