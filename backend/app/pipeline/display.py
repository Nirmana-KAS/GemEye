"""User-facing colour values, measured on the tray white-balanced image.

Every colour value returned to the app (L*, a*, b*, C*, H, S, B, hex, CIECAM02,
dE00 to the typical grade colour) and the hue/chroma/contrast used by the
quality gates come from tray_balanced_measure(), which follows the
export_wb.json method:

    256 px, GrabCut stone mask (seed 42), tray = non-stone pixels >= 8 px from
    the stone in the brightest 50% V, per-channel median, gain = 229.5 / tray, clip.

The stone pixels are the GrabCut mask of the raw 256 px image (as in the export);
medians and Lab/HSV scaling are the same as features.measure and grade_profiles_wb.
The earlier affine "physical" display path is superseded (see colour.py).
"""
import math
from dataclasses import dataclass

import colour
import cv2
import numpy as np

from app.pipeline.features import grabcut_mask

WB_SIZE = 256
WB_TARGET_WHITE = 229.5
WB_TRAY_GAP_PX = 8


def _finite(x):
    x = float(x)
    return x if math.isfinite(x) else None


def ciecam02(mean_rgb):
    """Real CIECAM02 (XYZ 0-100, L_A=64, Y_b=20, Average surround). None if not finite."""
    try:
        xyz = colour.sRGB_to_XYZ(mean_rgb) * 100.0
        xyz_w = colour.sRGB_to_XYZ(np.array([1.0, 1.0, 1.0])) * 100.0
        spec = colour.XYZ_to_CIECAM02(xyz, xyz_w, 64.0, 20.0,
                                      colour.VIEWING_CONDITIONS_CIECAM02["Average"])
        vals = {"J": _finite(spec.J), "M": _finite(spec.M), "h": _finite(spec.h),
                "s": _finite(spec.s), "C": _finite(spec.C)}
    except Exception:
        return None
    return None if any(v is None for v in vals.values()) else vals


def _lab(rgb):
    """OpenCV 8-bit Lab scaled as in features.measure (and grade_profiles_wb)."""
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB).astype(np.float64)
    lab[..., 0] *= 100.0 / 255.0
    lab[..., 1] -= 128.0
    lab[..., 2] -= 128.0
    return lab


@dataclass
class WBMeasure:
    L: float
    a: float
    b: float
    C: float
    H: float
    S: float
    B: float
    mean_rgb: np.ndarray        # 0-1, mean of the balanced stone pixels
    area: float                 # stone mask fraction of the 256 px image
    contrast: float             # dE00 median stone vs median tray, balanced image
    fallback: bool              # GrabCut used the saturation mask or the centre box
    centre_fallback: bool       # GrabCut used the centre box
    tray_rgb: list              # tray median before balancing, 0-255
    mask: np.ndarray = None     # stone mask used above (256 x 256, bool); Grad-CAM heat share
    gain: np.ndarray = None     # per-channel tray gain; Grad-CAM display image


def tray_balanced_measure(raw_rgb):
    img = cv2.resize(raw_rgb, (WB_SIZE, WB_SIZE))
    sm, fallback = grabcut_mask(img)
    h, w = sm.shape
    box = np.zeros((h, w), bool)
    box[h//4:3*h//4, w//4:3*w//4] = True
    centre_fallback = bool(fallback and np.array_equal(sm, box))
    if not sm.any():
        sm = box

    dist = cv2.distanceTransform((~sm).astype(np.uint8), cv2.DIST_L2, 5)
    tray = dist >= WB_TRAY_GAP_PX
    if tray.sum() < 50:
        tray = ~sm
    if tray.sum() < 50:
        tray = np.ones((h, w), bool)
    v = cv2.cvtColor(img, cv2.COLOR_RGB2HSV)[..., 2]
    tray &= v >= np.median(v[tray])

    tray_rgb = np.median(img[tray].astype(np.float64), axis=0)
    gain = WB_TARGET_WHITE / np.maximum(tray_rgb, 1.0)
    bal = np.clip(img.astype(np.float64) * gain, 0, 255).astype(np.uint8)

    lab = _lab(bal)
    L, a, b = np.median(lab[sm], axis=0)
    tray_lab = np.median(lab[tray], axis=0)
    hsv = cv2.cvtColor(bal, cv2.COLOR_RGB2HSV).astype(np.float64)[sm]
    H, S, B = np.median(hsv[:, 0]) * 2.0, np.median(hsv[:, 1]) / 255 * 100, np.median(hsv[:, 2]) / 255 * 100
    return WBMeasure(
        L=float(L), a=float(a), b=float(b), C=float(np.hypot(a, b)),
        H=float(H), S=float(S), B=float(B),
        mean_rgb=bal[sm].astype(np.float64).mean(axis=0) / 255.0,
        area=float(sm.mean()),
        contrast=float(colour.delta_E(np.array([L, a, b]), tray_lab, method="CIE 2000")),
        fallback=bool(fallback), centre_fallback=centre_fallback,
        tray_rgb=[float(x) for x in tray_rgb],
        mask=sm, gain=gain,
    )


def analyse(m, typical_lab, ciecam02_available):
    """m: tray_balanced_measure() result. Returns (colour values, dE00 to typical).

    The values are approximate when GrabCut fell back to the saturation mask or
    the centre box (segmentation_reliable is False)."""
    r, g, b = (np.clip(np.rint(m.mean_rgb * 255), 0, 255)).astype(int)
    de = float(colour.delta_E(np.array([m.L, m.a, m.b]), np.asarray(typical_lab, np.float64),
                              method="CIE 2000"))
    return {
        "L": m.L, "a": m.a, "b": m.b, "C": m.C, "H": m.H, "S": m.S, "B": m.B,
        "hex": f"#{r:02X}{g:02X}{b:02X}",
        "ciecam02": ciecam02(m.mean_rgb) if ciecam02_available else None,
        "approximate": m.fallback,
    }, de
