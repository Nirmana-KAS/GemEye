"""v3 inference: CNN (deterministic + MC Dropout), RF, ensemble and diagnostics."""
import time

import cv2
import numpy as np
import tensorflow as tf

from app import gates
from app.pipeline import colour as colour_path
from app.pipeline import display
from app.pipeline.features import model_features

GRADE_NAMES = ["Dark", "Deep", "Vivid", "Intense", "Medium Intense", "Light", "Very Light"]
TRADE_NAMES = ["Midnight Blue", "Twilight Blue", "Royal Blue", "Intense Cornflower",
               "Cornflower Blue", "Pastel Blue", "Very Light Blue"]
GRADES = np.arange(1, 8, dtype=np.float64)


def blur_variance(rgb):
    """Gate definition from gate_stats.json, measured on the RAW upload."""
    g = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    h, w = g.shape
    s = 512.0 / max(h, w)
    g = cv2.resize(g, (max(1, int(w * s)), max(1, int(h * s))), interpolation=cv2.INTER_AREA)
    h, w = g.shape
    c = g[h//4:3*h//4, w//4:3*w//4]
    return float(cv2.Laplacian(c, cv2.CV_64F, ksize=1).var())


def cnn_input(rgb, size):
    """Same as training load_img: tf.image.resize (bilinear), float32, preprocess_input."""
    img = tf.cast(tf.image.resize(tf.convert_to_tensor(rgb), [size, size]), tf.float32)
    return tf.keras.applications.efficientnet.preprocess_input(img)


def predict_cnn(assets, jpeg_bytes):
    """jpeg_bytes: the model-path JPEG, decoded with tf.io.decode_jpeg (default settings)
    exactly as training did. cv2 decoding differs slightly and shifts CNN probabilities."""
    size = int(assets.manifest.get("img_size", 224))
    rgb = tf.io.decode_jpeg(jpeg_bytes, channels=3)
    x = cnn_input(rgb, size)[tf.newaxis]
    pooled = assets.backbone(x)
    feat, det = assets.head_det(pooled)
    mc = assets.head_mc(tf.repeat(pooled, assets.mc_passes, axis=0)).numpy().astype(np.float64)  # (T, 7)
    expected = (mc * GRADES).sum(axis=1)                                                  # (T,)
    return {
        "deterministic": det.numpy()[0].astype(np.float64),
        "mc_mean": mc.mean(axis=0),
        "uncertainty": float(expected.std()),
        "features": feat.numpy()[0].astype(np.float64),
    }


def predict_rf(assets, feats):
    x = assets.scaler.transform(feats.reshape(1, -1))
    p = assets.rf.predict_proba(x)[0].astype(np.float64)
    return p[assets.rf_class_order]


def mahalanobis(assets, e):
    d = e - assets.ood_mean
    return float(np.sqrt(d @ assets.ood_precision @ d))


def rejection(code, diagnostics):
    """Gate failure: status code, message and the diagnostics measured so far."""
    return {"status": code, "message": gates.MESSAGES[code], "diagnostics": diagnostics}


def grade(assets, raw_rgb, patches, referral_threshold, debug=False, enforce_gates=True):
    """Gates in order, stopping at the first failure: invalid_image, no_stone,
    blurry, not_blue, not_recognised. The cheap gates run before the models.

    All user-facing colour values and the gate hue/chroma/contrast come from the
    tray white-balanced image (display.tray_balanced_measure). The model path
    below is unchanged and still identical to training.

    enforce_gates=False (development only, for the parity test) evaluates every
    gate but grades anyway; the failed gates are listed in debug.gates_bypassed."""
    t0 = time.perf_counter()
    h, w = raw_rgb.shape[:2]
    diag = {"short_side_px": int(min(h, w)), "min_short_side_px": gates.MIN_SHORT_SIDE_PX}
    bypassed = []
    if min(h, w) < gates.MIN_SHORT_SIDE_PX:
        if enforce_gates:
            return rejection("invalid_image", diag)
        bypassed.append("invalid_image")

    wb = display.tray_balanced_measure(raw_rgb)
    diag.update(gate_stone_area=wb.area, no_stone_min_area=gates.NO_STONE_MIN_AREA,
                stone_tray_contrast_de00=wb.contrast,
                no_stone_min_contrast_de00=gates.NO_STONE_MIN_CONTRAST_DE00,
                gate_centre_fallback=wb.centre_fallback)
    if gates.no_stone(wb):
        if enforce_gates:
            return rejection("no_stone", diag)
        bypassed.append("no_stone")

    blur = blur_variance(raw_rgb)
    diag.update(blur_variance=blur, blur_min_variance=gates.BLUR_MIN_VARIANCE)
    if blur < gates.BLUR_MIN_VARIANCE:
        if enforce_gates:
            return rejection("blurry", diag)
        bypassed.append("blurry")

    # The hue gate runs only when GrabCut segmented the stone (no fallback).
    seg_reliable = not wb.fallback
    diag.update(hue_wb=wb.H, hue_gate_min=gates.HUE_GATE_MIN, hue_gate_max=gates.HUE_GATE_MAX,
                hue_in_gate=gates.HUE_GATE_MIN <= wb.H <= gates.HUE_GATE_MAX,
                chroma_wb=wb.C, min_chroma=gates.MIN_CHROMA,
                segmentation_reliable=seg_reliable, hue_gate_skipped=not seg_reliable)
    if seg_reliable and gates.not_blue(wb):
        if enforce_gates:
            return rejection("not_blue", diag)
        bypassed.append("not_blue")

    # Model path (identical to training).
    if patches is None:
        session = colour_path.session_matrix(None, None)
        mode = "training_session"
    else:
        session = colour_path.session_matrix(patches, assets.train_patches)
        mode = "session_patches"
    model_rgb, model_jpeg = colour_path.model_path_image(raw_rgb, assets.ccm_training, session)
    feats, stone = model_features(model_rgb)
    t1 = time.perf_counter()

    rf_p = predict_rf(assets, feats)
    t2 = time.perf_counter()

    cnn = predict_cnn(assets, model_jpeg)
    t3 = time.perf_counter()

    ood = mahalanobis(assets, cnn["features"])
    diag.update(stone_area_fraction=stone.area,
                # Information only: GrabCut fallback on the model path (does not affect
                # segmentation_reliable, which comes from the tray-balanced image).
                model_segmentation_fallback=stone.fallback,
                ood_distance=ood, ood_warn=gates.OOD_WARN, ood_threshold=gates.OOD_REJECT)
    if ood > gates.OOD_REJECT:
        if enforce_gates:
            return rejection("not_recognised", diag)
        bypassed.append("not_recognised")
    warnings = ["unusual_image"] if ood > gates.OOD_WARN else []

    probs = assets.w_cnn * cnn["mc_mean"] + (1.0 - assets.w_cnn) * rf_p
    probs = probs / probs.sum()
    order = np.argsort(probs)[::-1]
    g = int(order[0]) + 1
    confidence = float(probs[order[0]])

    typical = assets.export_wb["grade_profiles_wb"][str(g)]["median"]
    colour_vals, de = display.analyse(wb, [typical["L"], typical["a"], typical["b"]],
                                      assets.ciecam02_display_available)
    t4 = time.perf_counter()

    result = {
        "status": "ok",
        "warnings": warnings,
        "grade": g,
        "grade_name": GRADE_NAMES[g - 1],
        "trade_name": TRADE_NAMES[g - 1],
        "probabilities": [float(p) for p in probs],
        "confidence": confidence,
        "uncertainty": cnn["uncertainty"],
        "referred": confidence < referral_threshold,
        "second_grade": int(order[1]) + 1,
        "colour": colour_vals,
        "delta_e00_to_typical": de,
        "calibration_mode": mode,
        "model_version": "v3",
        "timings_ms": {
            "total": (t4 - t0) * 1000.0,
            "preprocess": ((t1 - t0) + (t4 - t3)) * 1000.0,
            "rf": (t2 - t1) * 1000.0,
            "cnn": (t3 - t2) * 1000.0,
        },
        "diagnostics": diag,
    }
    if debug:
        result["debug"] = {
            "rf_grade": int(np.argmax(rf_p)) + 1,
            "rf_probabilities": [float(p) for p in rf_p],
            "cnn_mc_grade": int(np.argmax(cnn["mc_mean"])) + 1,
            "cnn_mc_probabilities": [float(p) for p in cnn["mc_mean"]],
            "cnn_deterministic_grade": int(np.argmax(cnn["deterministic"])) + 1,
            "cnn_deterministic_probabilities": [float(p) for p in cnn["deterministic"]],
            "model_segmentation_fallback": stone.fallback,
            "gates_bypassed": bypassed,
        }
    return result
