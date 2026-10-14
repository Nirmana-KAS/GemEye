"""Phase 3 quality gates: thresholds (one place), messages and gate decisions.

All thresholds are provisional, tune in Phase 7 (later editable from the admin
dashboard). Values are copied from the Phase 0 exports named in each comment.
The measurements come from display.tray_balanced_measure (export_wb.json method).
"""

# ------------------------------------------------------------------ thresholds

# invalid_image: shorter image side in pixels. Provisional, tune in Phase 7.
MIN_SHORT_SIDE_PX = 300

# blurry: gate_stats.json blur_threshold_suggested (Laplacian variance on the raw
# upload, see inference.blur_variance). Provisional, tune in Phase 7.
BLUR_MIN_VARIANCE = 29.474166117400628

# no_stone: 0.5 x gate_stats.json stone_area_fraction p0.5 (0.0314306640625).
# Safety net that rarely fires: the GrabCut mask is at least 3% of the image
# (or the 25% centre box) by construction. Provisional, tune in Phase 7.
NO_STONE_MIN_AREA = 0.5 * 0.0314306640625

# no_stone: minimum dE00 between the median stone and median tray colour on the
# tray-balanced image. Phase 3 test: sharp stone-free tray crops max 4.38, real
# test stones (excluding segmentation failures) min 5.37. Provisional, tune in Phase 7.
NO_STONE_MIN_CONTRAST_DE00 = 5.0

# not_blue: tray-balanced stone hue in degrees (median HSV hue of the stone pixels,
# as grade_profiles_wb H). Chosen from gate_stats.json hue_deg p0.5-p99.5 (166-250)
# with margin; export_wb.json hue_wb_range_suggested (6-280) is not used because it
# includes GrabCut fallbacks. Phase 3 test stones: p1 181, max 226.
# Provisional, tune in Phase 7.
HUE_GATE_MIN = 170.0
HUE_GATE_MAX = 265.0

# not_blue: 0.5 x the lowest per-grade p10 C* in export_wb.json grade_profiles_wb
# (grade 5, 1.0). Dark stones are near-neutral in 8-bit Lab (grade 1 p10 C* = 2.0).
# Provisional, tune in Phase 7.
MIN_CHROMA = 0.5 * 1.0

# not_recognised: Mahalanobis distance on the CNN 256-D Dense features.
# OOD_WARN = ood_stats.json val_distance p95, OOD_REJECT = threshold_p99.
# Provisional, tune in Phase 7.
OOD_WARN = 20.648902893066406
OOD_REJECT = 25.68535614013672

MESSAGES = {
    "invalid_image": "The image could not be read or is too small.",
    "blurry": "The photo is blurry. Refocus on the stone and retake it.",
    "no_stone": "No gemstone detected. Centre the stone on the white tray.",
    "not_blue": "This stone is not in the blue sapphire colour range.",
    "not_recognised": ("This image does not look like the blue sapphires GemEye was "
                       "trained on. Check the stone and capture setup."),
}


# ------------------------------------------------------------------ remote config
# The editable gates live in app_config.gates (admin dashboard). The constants above are
# the defaults; BOUNDS are hard limits enforced in code. MIN_SHORT_SIDE_PX is not editable.

DEFAULTS = {
    "blur_min_variance": BLUR_MIN_VARIANCE,
    "no_stone_min_area": NO_STONE_MIN_AREA,
    "no_stone_min_contrast_de00": NO_STONE_MIN_CONTRAST_DE00,
    "hue_min": HUE_GATE_MIN,
    "hue_max": HUE_GATE_MAX,
    "min_chroma": MIN_CHROMA,
    "ood_warn": OOD_WARN,
    "ood_reject": OOD_REJECT,
}
BOUNDS = {
    "blur_min_variance": (5.0, 200.0),
    "no_stone_min_area": (0.002, 0.05),
    "no_stone_min_contrast_de00": (1.0, 15.0),
    "hue_min": (100.0, 200.0),
    "hue_max": (230.0, 320.0),
    "min_chroma": (0.0, 5.0),
    "ood_warn": (5.0, 60.0),
    "ood_reject": (10.0, 80.0),
}


def valid(cfg):
    """True if every value is a number inside its bounds and ood_warn < ood_reject."""
    try:
        ok = all(not isinstance(cfg[k], bool) and isinstance(cfg[k], (int, float))
                 and lo <= cfg[k] <= hi for k, (lo, hi) in BOUNDS.items())
        return ok and cfg["ood_warn"] < cfg["ood_reject"] and cfg["hue_min"] < cfg["hue_max"]
    except (KeyError, TypeError):
        return False


def effective(config=None):
    """Gate values from a remote config dict (db.get_app_config(), cached 60 s). An
    invalid stored value falls back to its default, so a bad document cannot break grading."""
    stored = (config or {}).get("gates") or {}
    cfg = {k: (stored[k] if k in stored else d) for k, d in DEFAULTS.items()}
    if valid(cfg):
        return cfg
    cfg = {}
    for k, d in DEFAULTS.items():
        v, (lo, hi) = stored.get(k, d), BOUNDS[k]
        cfg[k] = v if (not isinstance(v, bool) and isinstance(v, (int, float)) and lo <= v <= hi) else d
    return cfg if valid(cfg) else dict(DEFAULTS)


def no_stone(m, cfg=None):
    """m: display.WBMeasure."""
    cfg = cfg or DEFAULTS
    return (m.area < cfg["no_stone_min_area"]
            or m.contrast < cfg["no_stone_min_contrast_de00"]
            or (m.centre_fallback and m.contrast < 2 * cfg["no_stone_min_contrast_de00"]))


def not_blue(m, cfg=None):
    """m: display.WBMeasure. Only applied when the segmentation is reliable."""
    cfg = cfg or DEFAULTS
    return not (cfg["hue_min"] <= m.H <= cfg["hue_max"]) or m.C < cfg["min_chroma"]
