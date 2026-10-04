"""Phase 3 quality-gate test.

Runs INSIDE the container (uses the mounted dataset and the running server):
    docker compose exec api python tests/gates/run_gates.py

a) False rejections: the 112 raw test images (tests/parity/parity_reference.csv).
b) Synthetic negatives made from the test images (written to /tmp/gemeye_gates
   only, never to the repo): blurred, empty tray, recoloured stone, random.
c) Writes gates_report.md next to this file.
"""
import csv
import glob
import json
import os
import sys
import urllib.request
import uuid
from collections import Counter

import cv2
import numpy as np

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from app import gates  # noqa: E402
from app.pipeline.features import grabcut_mask  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
URL = os.environ.get("GATES_URL", "http://localhost:8000/grade")
DATA = os.environ.get("GATES_DATA", "/data/merged")
REF = os.path.join(HERE, "..", "parity", "parity_reference.csv")
TMP = "/tmp/gemeye_gates"
REPORT = os.path.join(HERE, "gates_report.md")
CODES = ["invalid_image", "no_stone", "blurry", "not_blue", "not_recognised"]
KEYS = ["stone_tray_contrast_de00", "gate_centre_fallback", "blur_variance", "hue_wb",
        "chroma_wb", "segmentation_reliable", "ood_distance"]


def post(img_bytes, name="image.jpg"):
    b = uuid.uuid4().hex
    body = (f"--{b}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{name}\"\r\n"
            f"Content-Type: image/jpeg\r\n\r\n").encode() + img_bytes + f"\r\n--{b}--\r\n".encode()
    req = urllib.request.Request(URL, data=body, method="POST",
                                 headers={"Content-Type": f"multipart/form-data; boundary={b}"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def jpeg(rgb):
    ok, enc = cv2.imencode(".jpg", cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 95])
    assert ok
    return enc.tobytes()


def fmt(d):
    out = []
    for k in KEYS:
        v = d.get(k)
        if v is None:
            continue
        out.append(f"{k}={v:.2f}" if isinstance(v, float) else f"{k}={v}")
    return ", ".join(out)


def stone_mask(rgb):
    """GrabCut mask (256 px, seed 42) scaled back to the image size."""
    small = cv2.resize(rgb, (256, 256))
    sm, _ = grabcut_mask(small)
    h, w = rgb.shape[:2]
    return cv2.resize(sm.astype(np.uint8), (w, h), interpolation=cv2.INTER_NEAREST).astype(bool)


def tray_crop(rgb, mask):
    """Largest stone-free corner square (side = 1/3 of the short side), resized up."""
    h, w = rgb.shape[:2]
    s = min(h, w) // 3
    best = None
    for y, x in [(0, 0), (0, w - s), (h - s, 0), (h - s, w - s),
                 (0, (w - s) // 2), (h - s, (w - s) // 2), ((h - s) // 2, 0), ((h - s) // 2, w - s)]:
        frac = mask[y:y + s, x:x + s].mean()
        if best is None or frac < best[0]:
            best = (frac, y, x)
    _, y, x = best
    return cv2.resize(rgb[y:y + s, x:x + s], (w, h), interpolation=cv2.INTER_CUBIC)


def recolour(rgb, mask, hue_deg=None):
    """Rotate the stone pixels' hue so their median goes to hue_deg (None = greyscale)."""
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    if hue_deg is None:
        hsv[..., 1][mask] = 0
    else:
        h = hsv[..., 0].astype(np.int32)
        shift = int(round(hue_deg / 2.0)) - int(np.median(h[mask]))
        h[mask] = (h[mask] + shift) % 180
        hsv[..., 0] = h.astype(np.uint8)
    return cv2.cvtColor(hsv, cv2.COLOR_HSV2RGB)


def random_images(h, w):
    rng = np.random.default_rng(0)
    out = []
    for i in range(5):
        out.append((f"noise_{i}", rng.integers(0, 256, (h, w, 3), dtype=np.uint8)))
    for cell in (16, 64, 160):
        yy, xx = np.indices((h, w))
        board = (((yy // cell) + (xx // cell)) % 2 * 255).astype(np.uint8)
        out.append((f"checker_{cell}", np.dstack([board] * 3)))
    out.append(("solid_grey", np.full((h, w, 3), 128, np.uint8)))
    return out


def main():
    os.makedirs(TMP, exist_ok=True)
    rows = list(csv.DictReader(open(REF, encoding="utf-8")))
    images = []
    for r in rows:
        hits = glob.glob(os.path.join(DATA, f"grade_{r['true_grade']}_*", r["image"]))
        if len(hits) != 1:
            sys.exit(f"missing test image {r['image']}")
        images.append((r["image"], int(r["true_grade"]), hits[0]))

    # a) false rejections on the raw test images
    real = []
    for name, g, path in images:
        with open(path, "rb") as f:
            body = post(f.read(), name)
        real.append((name, g, body))
        print(f"real {name}: {body['status']}", flush=True)
    rejected = [x for x in real if x[2]["status"] != "ok"]
    warned = [x for x in real if x[2]["status"] == "ok" and x[2].get("warnings")]

    # b) synthetic negatives
    synth = {}  # category -> list of (label, status)

    def run(cat, label, rgb):
        cv2.imwrite(os.path.join(TMP, f"{cat}__{label}.jpg"), cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))
        body = post(jpeg(rgb), f"{label}.jpg")
        synth.setdefault(cat, []).append((label, body["status"], body["diagnostics"]))
        print(f"{cat} {label}: {body['status']}", flush=True)

    h0 = w0 = None
    for name, g, path in images:
        rgb = cv2.cvtColor(cv2.imread(path), cv2.COLOR_BGR2RGB)
        h0, w0 = rgb.shape[:2]
        mask = stone_mask(rgb)
        stem = os.path.splitext(name)[0]
        run("blur_sigma3", stem, cv2.GaussianBlur(rgb, (0, 0), 3))
        run("blur_sigma6", stem, cv2.GaussianBlur(rgb, (0, 0), 6))
        run("empty_tray_crop", stem, tray_crop(rgb, mask))
        run("recolour_red", stem, recolour(rgb, mask, 0))
        run("recolour_green", stem, recolour(rgb, mask, 120))
        run("recolour_yellow", stem, recolour(rgb, mask, 55))
        run("recolour_grey", stem, recolour(rgb, mask, None))
    run("empty_near_white", "plain", np.full((h0, w0, 3), (232, 234, 236), np.uint8))
    noisy = np.clip(np.full((h0, w0, 3), (232, 234, 236), np.float64)
                    + np.random.default_rng(1).normal(0, 6, (h0, w0, 3)), 0, 255).astype(np.uint8)
    run("empty_near_white", "sensor_noise", noisy)
    for label, rgb in random_images(h0, w0):
        run("random", label, rgb)

    write_report(real, rejected, warned, synth)
    print(f"\nfalse rejections: {len(rejected)}/{len(real)}; unusual_image warnings: {len(warned)}")
    for cat, items in synth.items():
        n = sum(1 for _, s, _ in items if s != "ok")
        print(f"{cat}: {n}/{len(items)} rejected {dict(Counter(s for _, s, _ in items))}")


def write_report(real, rejected, warned, synth):
    expect = {
        "blur_sigma3": "blurry or no_stone", "blur_sigma6": "blurry or no_stone",
        "empty_tray_crop": "no_stone", "empty_near_white": "no_stone",
        "recolour_red": "not_blue", "recolour_green": "not_blue",
        "recolour_yellow": "not_blue", "recolour_grey": "not_blue",
        "random": "no_stone or not_recognised",
    }
    L = ["# Phase 3 quality-gate report", "",
         "Generated by `tests/gates/run_gates.py` against the running server (no patches, "
         "training_session mode). Synthetic images were written to /tmp only.", "",
         "Gate order: invalid_image, no_stone, blurry, not_blue, not_recognised.", "",
         "## Changes from first run", "",
         "First run (EDIT-089): 69/112 false rejections (not_blue 65, no_stone 4). The "
         "affine display path clipped dark stone pixels to black (S = 0, H = 0), so the "
         "median hue was 0 degrees for most grade 1-3 stones.", "",
         "- Hue gate and all output colour values now use the tray white-balanced image "
         "(export_wb method); the affine display path is commented out as superseded; "
         "`hue_physical` renamed `hue_wb`.",
         "- MIN_CHROMA 2.7 -> 0.5 (0.5 x lowest per-grade p10 C*, grade 5).",
         "- NO_STONE_MIN_CONTRAST_DE00 8.0 -> 5.0 (sharp tray crops max 4.38).",
         "- Gate order: no_stone now runs before blurry, so empty or near-white images "
         "are reported as no_stone.",
         "- dE00 to typical uses the `grade_profiles_wb` median (was `grade_profiles_physical`).", "",
         "## Output field sources", "",
         "| Field | Produced by |", "|---|---|",
         "| colour.L, a, b, C, H, S, B | display.tray_balanced_measure (medians of the stone pixels, tray-balanced image) |",
         "| colour.hex | display.analyse, from tray_balanced_measure mean_rgb |",
         "| colour.ciecam02 J, M, h, s, C | display.ciecam02(mean_rgb of tray_balanced_measure) |",
         "| colour.approximate | tray_balanced_measure fallback |",
         "| delta_e00_to_typical | display.analyse: tray_balanced_measure Lab vs grade_profiles_wb median |",
         "| diagnostics.hue_wb, chroma_wb, stone_tray_contrast_de00, gate_stone_area, "
         "gate_centre_fallback, segmentation_reliable | display.tray_balanced_measure |",
         "| diagnostics.blur_variance | inference.blur_variance (raw upload, gate_stats definition) |",
         "| diagnostics.stone_area_fraction, model_segmentation_fallback | features.model_features (model path, information only) |",
         "| diagnostics.ood_distance | inference.mahalanobis (CNN Dense features, model path) |",
         "| grade, probabilities, confidence, uncertainty | model path (unchanged, see parity report) |", "",
         "No output value or gate uses the affine display path "
         "(`fit_affine`, `display_path_image` are commented out in pipeline/colour.py).", "",
         "## Thresholds used (app/gates.py, provisional, tune in Phase 7)", "",
         "| Constant | Value | Source |", "|---|---|---|",
         f"| MIN_SHORT_SIDE_PX | {gates.MIN_SHORT_SIDE_PX} | chosen |",
         f"| BLUR_MIN_VARIANCE | {gates.BLUR_MIN_VARIANCE:.2f} | gate_stats blur_threshold_suggested |",
         f"| NO_STONE_MIN_AREA | {gates.NO_STONE_MIN_AREA:.4f} | 0.5 x gate_stats stone_area_fraction p0.5 |",
         f"| NO_STONE_MIN_CONTRAST_DE00 | {gates.NO_STONE_MIN_CONTRAST_DE00:.1f} | chosen from Phase 3 tray crops (tray-balanced image) |",
         f"| HUE_GATE_MIN / MAX | {gates.HUE_GATE_MIN:.0f} / {gates.HUE_GATE_MAX:.0f} | tray-balanced hue, chosen from gate_stats hue_deg |",
         f"| MIN_CHROMA | {gates.MIN_CHROMA:.2f} | 0.5 x lowest per-grade p10 C* in export_wb (grade 5) |",
         f"| OOD_WARN | {gates.OOD_WARN:.2f} | ood_stats val_distance p95 |",
         f"| OOD_REJECT | {gates.OOD_REJECT:.2f} | ood_stats threshold_p99 |", "",
         "## a) False rejections on the 112 raw test images", "",
         f"Rejected: **{len(rejected)}/{len(real)}** (target <= 2). "
         f"Graded with `unusual_image` warning: {len(warned)}.", "",
         "| Gate | Rejected |", "|---|---|"]
    cnt = Counter(b["status"] for _, _, b in rejected)
    for c in CODES:
        L.append(f"| {c} | {cnt.get(c, 0)} |")
    L += ["", "| Image | True grade | Gate | Values |", "|---|---|---|---|"]
    for name, g, b in rejected:
        L.append(f"| {name} | {g} | {b['status']} | {fmt(b['diagnostics'])} |")
    if warned:
        L += ["", "Images graded with the `unusual_image` warning:", "",
              "| Image | True grade | Grade | OOD distance |", "|---|---|---|---|"]
        for name, g, b in warned:
            L.append(f"| {name} | {g} | {b['grade']} | {b['diagnostics']['ood_distance']:.2f} |")
    L += ["", "## b) Synthetic negatives", "",
          "| Category | Expected | n | Rejected | Rate | Gates fired |", "|---|---|---|---|---|---|"]
    for cat, items in synth.items():
        n = len(items)
        rej = sum(1 for _, s, _ in items if s != "ok")
        fired = ", ".join(f"{k} {v}" for k, v in Counter(s for _, s, _ in items).most_common())
        L.append(f"| {cat} | {expect[cat]} | {n} | {rej} | {100.0 * rej / n:.1f}% | {fired} |")
    L += ["", "### Synthetic images that were graded (status ok)", "",
          "| Category | Image | Values |", "|---|---|---|"]
    for cat, items in synth.items():
        for label, s, d in items:
            if s == "ok":
                L.append(f"| {cat} | {label} | {fmt(d)} |")
    L += ["", "## Limits", "",
          "Synthetic negatives only approximate real failure cases. Real rubies and other "
          "non-blue sapphires, blue glass and blue spinel, and field photos (other phones, "
          "lighting and trays) are tested in Phase 7, where the thresholds are tuned.", ""]
    with open(REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(L))


if __name__ == "__main__":
    main()
