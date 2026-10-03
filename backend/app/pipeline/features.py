"""v3 GrabCut segmentation and 12-D colour features.

Copied from the v3 training / Phase 0 export code (CELL 5). Do not change the
maths here: the Random Forest and its scaler were fitted on exactly these
numbers.
"""
from dataclasses import dataclass

import cv2
import numpy as np

SEED = 42
FEATURE_NAMES = ["H", "S", "B", "L", "a", "b", "C", "J", "M", "h", "s", "C_cam"]


def grabcut_mask(rgb):
    h, w = rgb.shape[:2]
    mx, my = int(w * 0.15), int(h * 0.15)
    mask = np.zeros((h, w), np.uint8)
    bgd, fgd = np.zeros((1, 65)), np.zeros((1, 65))
    fallback = False
    try:
        # Fixed seed so the same image always gives the same mask.
        cv2.setRNGSeed(SEED)
        cv2.grabCut(rgb.copy(), mask, (mx, my, w - 2*mx, h - 2*my), bgd, fgd, 5, cv2.GC_INIT_WITH_RECT)
        sm = (mask == 1) | (mask == 3)
        if sm.sum() < h * w * 0.05:
            sm = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)[:, :, 1] > 30; fallback = True
        if sm.sum() < h * w * 0.03:
            sm = np.zeros((h, w), bool); sm[h//4:3*h//4, w//4:3*w//4] = True; fallback = True
    except Exception:
        sm = np.zeros((h, w), bool); sm[h//4:3*h//4, w//4:3*w//4] = True; fallback = True
    return sm, fallback


@dataclass
class StoneMeasure:
    H: float
    S: float
    B: float
    L: float
    a: float
    b: float
    C: float
    mean_rgb: np.ndarray  # 0-1, mean of the stone pixels
    area: float
    fallback: bool


def measure(rgb):
    """Resize to 256, segment, and take the v3 medians (LAB and HSV scaling as in training)."""
    img = cv2.resize(rgb, (256, 256))
    sm, gc_fallback = grabcut_mask(img)
    sp = img[sm] if sm.sum() >= 10 else img[64:192, 64:192].reshape(-1, 3)
    lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB).astype(np.float64)
    lab[:, :, 0] *= 100.0 / 255.0; lab[:, :, 1] -= 128.0; lab[:, :, 2] -= 128.0
    lp = lab[sm]
    L, a, b = np.median(lp[:, 0]), np.median(lp[:, 1]), np.median(lp[:, 2])
    C = np.sqrt(a**2 + b**2)
    hp = cv2.cvtColor(img, cv2.COLOR_RGB2HSV).astype(np.float64)[sm]
    H, S, B = np.median(hp[:, 0]) * 2.0, np.median(hp[:, 1]) / 255 * 100, np.median(hp[:, 2]) / 255 * 100
    mean_rgb = sp.astype(np.float64).mean(axis=0) / 255.0
    return StoneMeasure(float(H), float(S), float(B), float(L), float(a), float(b), float(C),
                        mean_rgb, float(sm.mean()), gc_fallback)


def model_features(rgb):
    """12-D RF features in FEATURE_NAMES order.

    The v3 training code wrapped a call to colour.appearance.CIECAM02 (which
    does not exist in colour-science 0.4.7) in try/except, so every training
    image fell back to J=L, M=C, h=H, s=S, C_cam=C (export_manifest
    ciecam02_check: 912/912 fallbacks). The RF learned on those values, so the
    server reproduces the fallback here instead of computing real CIECAM02.
    Real CIECAM02 is only used for display (pipeline/display.py).
    """
    m = measure(rgb)
    feats = np.array([m.H, m.S, m.B, m.L, m.a, m.b, m.C, m.L, m.C, m.H, m.S, m.C])
    return feats, m
