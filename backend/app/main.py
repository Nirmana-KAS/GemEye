"""GemEye API: inference (Phases 1-3), auth, MongoDB and S3 storage (Phase 4a),
certificates, public verification, remote config and feedback (Phase 4b)."""
import json
import logging
import platform
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from typing import Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from slowapi.errors import RateLimitExceeded

from app.assets import load_assets, warm_up
from app.auth import active_user, init_firebase
from app.certificates import limiter, public_headers
from app.certificates import router as certificates_router
from app.config import get_settings
from app.db import Database, utcnow
from app.errors import ApiError
from app.pipeline.colour import decode_image
from app.pipeline.inference import grade, rejection
from app.routers import get_db, get_storage, router
from app.schemas import GradeResponse, HealthResponse
from app.storage import Storage

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("gemeye.api")

_lock = threading.Lock()
# S3 upload and MongoDB insert of a grading run concurrently.
_io = ThreadPoolExecutor(max_workers=8, thread_name_prefix="gemeye-io")
MAINTENANCE = "GemEye is under maintenance. Please try again later."

# Keep uploads up to the size limit in memory (Starlette spools >1 MB to a temp file).
try:
    from starlette.formparsers import MultiPartParser
    MultiPartParser.spool_max_size = (get_settings().max_upload_mb + 1) * 1024 * 1024
except (ImportError, AttributeError):
    pass


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    # Only "set"/"missing" is ever logged for configuration values.
    logger.info("ENV=%s db=%s s3_prefix=%r settings=%s", settings.env, settings.db_name,
                settings.s3_prefix, settings.status())
    app.state.assets = app.state.db = app.state.storage = None
    try:
        app.state.assets = load_assets(settings.model_dir, settings.export_dir)
        warm_up(app.state.assets)
    except Exception:
        logger.exception("Failed to load model assets")
    try:
        init_firebase(settings.firebase_credentials)
    except Exception as e:
        logger.error("Firebase init failed (%s)", type(e).__name__)
    if settings.mongodb_uri:
        try:
            app.state.db = Database(settings.mongodb_uri.get_secret_value(), settings.db_name)
            app.state.db.ensure_indexes()
            app.state.db.seed_app_config()
        except Exception as e:
            logger.error("MongoDB init failed (%s)", type(e).__name__)
            app.state.db = None
    if settings.s3_bucket and settings.aws_region:
        secret = lambda v: v.get_secret_value() if v else None  # noqa: E731
        app.state.storage = Storage(settings.s3_bucket, settings.aws_region,
                                    secret(settings.aws_access_key_id),
                                    secret(settings.aws_secret_access_key), settings.s3_prefix)
    yield
    if app.state.db is not None:
        app.state.db.close()


app = FastAPI(title="GemEye API", version="1.2.0", lifespan=lifespan)
app.state.limiter = limiter
app.include_router(router)
app.include_router(certificates_router)


def _error(request, code, detail, extra=None, headers=None):
    h = dict(headers or {})
    if request.url.path.startswith("/public/"):
        h.update(public_headers(request))
    return JSONResponse(status_code=code, headers=h,
                        content={"status": "error", **(extra or {}), "detail": detail})


@app.exception_handler(HTTPException)
async def http_error(request: Request, exc: HTTPException):
    return _error(request, exc.status_code, str(exc.detail), headers=exc.headers)


@app.exception_handler(ApiError)
async def api_error(request: Request, exc: ApiError):
    return _error(request, exc.status_code, exc.detail,
                  {"code": exc.code, "message": exc.detail})


@app.exception_handler(RateLimitExceeded)
async def rate_limited(request: Request, exc: RateLimitExceeded):
    return _error(request, 429, "Too many requests. Please try again later.",
                  headers={"Retry-After": "60"})


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError):
    return _error(request, 400, "Invalid request.")


@app.exception_handler(Exception)
async def generic_error(request: Request, exc: Exception):
    logger.exception("Unhandled error")
    return _error(request, 500, "Internal server error.")


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


def _short(v, n):
    v = (v or "").strip()
    return v[:n] or None


@app.post("/grade", response_model=GradeResponse, response_model_exclude_unset=True)
def grade_stone(
    request: Request,
    image: UploadFile = File(...),
    patches: Optional[str] = Form(None),
    referral_threshold: Optional[float] = Form(None),
    debug: bool = Form(False),
    gates: bool = Form(True),
    session_id: Optional[str] = Form(None),
    app_version: Optional[str] = Form(None),
    device: Optional[str] = Form(None),
    user: dict = Depends(active_user),
    db: Database = Depends(get_db),
    storage: Storage = Depends(get_storage),
):
    settings = get_settings()
    assets = request.app.state.assets
    if assets is None:
        raise HTTPException(500, "Internal server error.")
    maintenance = db.get_app_config().get("maintenance") or {}
    if maintenance.get("enabled"):
        raise ApiError(503, "maintenance", maintenance.get("message") or MAINTENANCE)

    limit = settings.max_upload_mb * 1024 * 1024
    data = image.file.read(limit + 1)
    if len(data) > limit:
        raise HTTPException(413, f"Image is larger than {settings.max_upload_mb} MB.")
    is_png = data[:8] == b"\x89PNG\r\n\x1a\n"
    if not (data[:3] == b"\xff\xd8\xff" or is_png):
        raise HTTPException(400, "Image must be a JPEG or PNG.")
    if referral_threshold is not None and not 0.40 <= referral_threshold <= 0.90:
        raise HTTPException(400, "referral_threshold must be between 0.40 and 0.90.")
    p = _parse_patches(patches)
    try:
        raw_rgb = decode_image(data)
    except ValueError:
        raw_rgb = None

    profile = db.ensure_user(user["uid"], user["email"])
    if referral_threshold is None:
        referral_threshold = (profile.get("settings") or {}).get("referral_threshold",
                                                                 settings.referral_threshold)
    threshold = float(referral_threshold)
    meta = {"app_version": _short(app_version, 50), "device": _short(device, 200)}

    if raw_rgb is None:
        # JPEG/PNG signature, but the image cannot be decoded.
        result = rejection("invalid_image", {})
    else:
        # One request at a time through TF / GrabCut.
        with _lock:
            # Debug fields and gates=false are honoured only outside production.
            dev = not settings.is_production
            result = grade(assets, raw_rgb, p, threshold, debug=debug and dev,
                           enforce_gates=gates or not dev)
        del raw_rgb

    stored = GradeResponse(**result).model_dump(mode="json", exclude_unset=True, exclude={"debug"})
    if result["status"] != "ok":
        # Rejections keep diagnostics only; the image is never stored.
        del data
        try:
            db.rejections.insert_one({
                "_id": uuid.uuid4().hex, "uid": user["uid"], "created_at": utcnow(),
                "status": result["status"], "message": result.get("message"),
                "diagnostics": stored.get("diagnostics", {}), **meta})
        except Exception:
            logger.exception("Could not record rejection")
        return result

    # Status ok: store the original upload and the grading record concurrently;
    # respond only when both succeeded, otherwise undo the one that did.
    grading_id = uuid.uuid4().hex
    key = storage.grading_key(user["uid"], grading_id, "png" if is_png else "jpg")

    def save_record():
        stone_id = f"GE-STONE-{db.next_seq('stone'):05d}"
        db.gradings.insert_one({
            "_id": grading_id, "uid": user["uid"], "stone_id": stone_id, "created_at": utcnow(),
            "status": "ok", "result": stored, "image_key": key,
            "calibration_session_id": _short(session_id, 100), **meta,
            "referral_threshold_used": threshold, "deleted": False})
        return stone_id

    upload = _io.submit(storage.put, key, data, "image/png" if is_png else "image/jpeg")
    record = _io.submit(save_record)
    failed = []
    for name, future in (("S3 upload", upload), ("MongoDB insert", record)):
        try:
            future.result()
        except Exception:
            logger.exception("%s failed", name)
            failed.append(future)
    del data
    if failed:
        cleanups = []
        if upload not in failed:
            cleanups.append(("S3", lambda: storage.delete(key)))
        if record not in failed:
            cleanups.append(("MongoDB", lambda: db.gradings.delete_one({"_id": grading_id})))
        for name, undo in cleanups:
            try:
                undo()
            except Exception:
                logger.exception("%s cleanup failed", name)
        raise HTTPException(500, "Could not save the grading. Please try again.")
    stone_id = record.result()

    result.update(grading_id=grading_id, stone_id=stone_id, image_url=storage.presigned_get(key))
    return result
