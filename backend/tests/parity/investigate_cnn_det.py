"""Phase 2.1: why does the deterministic CNN differ from parity_reference.csv?

Runs INSIDE the container (no server call, loads the assets directly):
    docker compose exec api python tests/parity/investigate_cnn_det.py

Each variant changes ONE step of the deterministic CNN input path and reports
max abs probability difference and grade agreement with the Colab deterministic
reference over all 112 test images. Nothing in app/ is modified. Writes
parity_investigation_cnn.md next to this file.
"""
import csv
import glob
import os
import sys

import cv2
import keras
import numpy as np
import tensorflow as tf

sys.path.insert(0, "/srv")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.assets import load_assets  # noqa: E402
from app.config import get_settings  # noqa: E402
from app.pipeline import colour as colour_path  # noqa: E402
from app.pipeline.inference import cnn_input  # noqa: E402
from investigate_parity import model_rgb  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get("PARITY_DATA", "/data/merged")


def det_split(assets, x):
    _, det = assets.head_det(assets.backbone(x[tf.newaxis]))
    return det.numpy()[0].astype(np.float64)


def det_full(assets, x):
    out = assets.model(x[tf.newaxis], training=False)
    if isinstance(out, (list, tuple)):
        out = out[-1]
    return out.numpy()[0].astype(np.float64)


def tf_resize(rgb, antialias=False):
    x = tf.image.resize(tf.convert_to_tensor(rgb), [224, 224], antialias=antialias)
    return keras.applications.efficientnet.preprocess_input(tf.cast(x, tf.float32))


def from_array(rgb):
    return keras.applications.efficientnet.preprocess_input(tf.convert_to_tensor(rgb, tf.float32))


def main():
    s = get_settings()
    assets = load_assets(s.model_dir, s.export_dir)
    ccm = assets.ccm_training
    with open(os.path.join(HERE, "parity_reference.csv"), newline="") as f:
        ref = list(csv.DictReader(f))

    def variants(raw, raw_noexif):
        rgb, enc = model_rgb(raw, ccm)
        yield "cv2 decode (server before EDIT-088)", lambda: det_split(assets, cnn_input(rgb, 224))
        yield "full keras model instead of split", lambda: det_full(assets, cnn_input(rgb, 224))
        for m in ("INTEGER_ACCURATE", "INTEGER_FAST"):
            yield f"decode tf.io.decode_jpeg {m}", lambda m=m: det_split(
                assets, cnn_input(tf.io.decode_jpeg(enc, channels=3, dct_method=m).numpy(), 224))
        yield "cv2 resize 256 then tf resize 224", lambda: det_split(
            assets, cnn_input(cv2.resize(rgb, (256, 256)), 224))
        yield "cv2 resize 224 INTER_LINEAR", lambda: det_split(
            assets, from_array(cv2.resize(rgb, (224, 224), interpolation=cv2.INTER_LINEAR)))
        yield "cv2 resize 224 INTER_AREA", lambda: det_split(
            assets, from_array(cv2.resize(rgb, (224, 224), interpolation=cv2.INTER_AREA)))
        yield "tf resize antialias=True", lambda: det_split(assets, tf_resize(rgb, True))
        yield "tf resize then uint8 cast", lambda: det_split(
            assets, from_array(tf.cast(tf.image.resize(rgb, [224, 224]), tf.uint8).numpy()))
        yield "no JPEG round trip", lambda: det_split(assets, cnn_input(model_rgb(raw, ccm, None)[0], 224))
        yield "CCM rounded", lambda: det_split(assets, cnn_input(model_rgb(raw, ccm, rounding=True)[0], 224))
        yield "BGR channel order", lambda: det_split(assets, cnn_input(rgb[..., ::-1].copy(), 224))
        yield "EXIF orientation ignored", lambda: det_split(assets, cnn_input(model_rgb(raw_noexif, ccm)[0], 224))
        yield "preprocess /255 (not pass-through)", lambda: det_split(assets, cnn_input(rgb, 224) / 255.0)

    stats = {}
    for n, r in enumerate(ref, 1):
        path = glob.glob(os.path.join(DATA, f"grade_{r['true_grade']}_*", r["image"]))[0]
        data = open(path, "rb").read()
        raw = colour_path.decode_image(data)
        noexif = cv2.cvtColor(cv2.imdecode(np.frombuffer(data, np.uint8),
                                           cv2.IMREAD_COLOR | cv2.IMREAD_IGNORE_ORIENTATION), cv2.COLOR_BGR2RGB)
        p_ref = np.array([float(r[f"cnn_det_p{k}"]) for k in range(1, 8)])
        g_ref = int(r["cnn_det_grade"])
        for name, fn in variants(raw, noexif):
            p = fn()
            d = float(np.abs(p - p_ref).max())
            st = stats.setdefault(name, {"dp": [], "agree": 0, "img": []})
            st["dp"].append(d)
            st["img"].append(r["image"])
            st["agree"] += int(np.argmax(p)) + 1 == g_ref
        print(f"[{n:3d}/112] {r['image']} base dp {stats[next(iter(stats))]['dp'][-1]:.3e}", flush=True)

    N = len(ref)
    out = ["# Deterministic CNN investigation (Phase 2.1)", "",
           "One input-path step changed per variant; compared with parity_reference.csv cnn_det_p1..7.", "",
           "| Variant | Max abs dp | Mean per-image max abs dp | Median | Grade agreement | Worst image |",
           "|---|---|---|---|---|---|"]
    for name, st in stats.items():
        dp = np.array(st["dp"])
        out.append(f"| {name} | {dp.max():.3e} | {dp.mean():.3e} | {np.median(dp):.3e} | "
                   f"{st['agree']}/{N} | {st['img'][int(dp.argmax())]} |")
    with open(os.path.join(HERE, "parity_investigation_cnn.md"), "w") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
