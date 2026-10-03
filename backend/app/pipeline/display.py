"""Physical colour values for display, measured on the display-path image."""
import math

import colour
import numpy as np

from app.pipeline.features import measure


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


def analyse(display_rgb, typical_lab, ciecam02_available):
    m = measure(display_rgb)
    r, g, b = (np.clip(np.rint(m.mean_rgb * 255), 0, 255)).astype(int)
    lab = np.array([m.L, m.a, m.b])
    de = float(colour.delta_E(lab, np.asarray(typical_lab, np.float64), method="CIE 2000"))
    return {
        "L": m.L, "a": m.a, "b": m.b, "C": m.C, "H": m.H, "S": m.S, "B": m.B,
        "hex": f"#{r:02X}{g:02X}{b:02X}",
        "ciecam02": ciecam02(m.mean_rgb) if ciecam02_available else None,
    }, de
