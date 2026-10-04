"""Phase 2 STEP 4: test preprocessing hypotheses for Colab/server disagreements.

Runs INSIDE the container (no server call, loads the assets directly):
    docker compose exec api python tests/parity/investigate_parity.py

Each variant changes ONE step of the model path and reports agreement with the
Colab final / RF / CNN-MC predictions over all 112 test images. Nothing in
app/ is modified. Writes parity_investigation.md next to this file.
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
from app.assets import load_assets  # noqa: E402
from app.config import get_settings  # noqa: E402
from app.pipeline import colour as colour_path  # noqa: E402
from app.pipeline import features  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.environ.get("PARITY_DATA", "/data/merged")
GRADES = np.arange(1, 8, dtype=np.float64)


def model_rgb(raw, ccm, jpeg_quality=95, rounding=False, bgr_ccm=False):
    h, w, c = raw.shape
    src = raw[..., ::-1] if bgr_ccm else raw
    f = src.astype(np.float64).reshape(-1, 3) / 255.0
    v = np.clip(f @ ccm, 0, 1) * 255
    out = (np.round(v) if rounding else v).astype(np.uint8).reshape(h, w, c)
    if bgr_ccm:
        out = out[..., ::-1].copy()
    if jpeg_quality is None:
        return out, None
    ok, enc = cv2.imencode(".jpg", cv2.cvtColor(out, cv2.COLOR_RGB2BGR),
                           [cv2.IMWRITE_JPEG_QUALITY, jpeg_quality])
    return cv2.cvtColor(cv2.imdecode(enc, cv2.IMREAD_COLOR), cv2.COLOR_BGR2RGB), enc.tobytes()


def rf_probs(assets, rgb, interp=cv2.INTER_LINEAR, seed=features.SEED):
    img = cv2.resize(rgb, (256, 256), interpolation=interp)
    old = features.SEED
    features.SEED = seed
    try:
        # measure() resizes again; a 256->256 resize is an identity copy.
        feats, _ = features.model_features(img)
    finally:
        features.SEED = old
    x = assets.scaler.transform(feats.reshape(1, -1))
    return assets.rf.predict_proba(x)[0].astype(np.float64)[assets.rf_class_order]


def pooled(assets, rgb, cv2_resize=False):
    if cv2_resize:
        x = tf.convert_to_tensor(cv2.resize(rgb, (224, 224), interpolation=cv2.INTER_LINEAR), tf.float32)
    else:
        x = tf.cast(tf.image.resize(tf.convert_to_tensor(rgb), [224, 224]), tf.float32)
    x = keras.applications.efficientnet.preprocess_input(x)
    return assets.backbone(x[tf.newaxis])


def mc_mean(assets, p, seed=42, passes=30):
    model = assets.model
    split = next(i for i, layer in enumerate(model.layers)
                 if isinstance(layer, keras.layers.GlobalAveragePooling2D)) + 1
    x = tf.repeat(p, passes, axis=0)
    for i, layer in enumerate(model.layers[split:], start=split):
        if isinstance(layer, keras.layers.Dropout):
            keep = tf.random.stateless_uniform(tf.shape(x), seed=[seed, i]) >= layer.rate
            x = tf.where(keep, x / (1.0 - layer.rate), tf.zeros_like(x))
        else:
            x = layer(x, training=False)
    return x.numpy().astype(np.float64).mean(axis=0)


def final(assets, rf, cnn):
    p = assets.w_cnn * cnn + (1.0 - assets.w_cnn) * rf
    return int(np.argmax(p)) + 1


def main():
    s = get_settings()
    assets = load_assets(s.model_dir, s.export_dir)
    ccm = assets.ccm_training
    with open(os.path.join(HERE, "final_per_image_predictions.csv"), newline="") as f:
        rows = list(csv.DictReader(f))

    variants = {
        "baseline (server)": {},
        "no JPEG round trip": {"jpeg_quality": None},
        "JPEG quality 100": {"jpeg_quality": 100},
        "CCM output rounded (not truncated)": {"rounding": True},
        "CCM applied in BGR order": {"bgr_ccm": True},
        "RF resize INTER_AREA": {"rf_interp": cv2.INTER_AREA},
        "CNN resize cv2 (not tf)": {"cv2_resize": True},
        "CNN decode tf.io.decode_jpeg ACCURATE": {"tf_decode": "INTEGER_ACCURATE"},
        "CNN decode tf.io.decode_jpeg FAST": {"tf_decode": "INTEGER_FAST"},
        "CNN deterministic (no MC)": {"det": True},
    }
    agree = {k: [0, 0, 0] for k in variants}
    flips = {k: [] for k in variants}
    exif_rotated, gc_flip, mc_flip = [], {}, {}
    mc_seeds, gc_seeds = list(range(10)), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    mc_final_agree = np.zeros(len(mc_seeds))
    gc_rf_agree = np.zeros(len(gc_seeds))
    base_final = {}

    for n, r in enumerate(rows, 1):
        path = glob.glob(os.path.join(DATA, f"grade_{r['true_grade']}_*", r["image"]))[0]
        data = open(path, "rb").read()
        buf = np.frombuffer(data, np.uint8)
        raw = colour_path.decode_image(data)
        noexif = cv2.cvtColor(cv2.imdecode(buf, cv2.IMREAD_COLOR | cv2.IMREAD_IGNORE_ORIENTATION),
                              cv2.COLOR_BGR2RGB)
        if noexif.shape != raw.shape or not np.array_equal(noexif, raw):
            exif_rotated.append(r["image"])
        cf, crf, ccnn = int(r["final_pred"]), int(r["rf_pred"]), int(r["cnn_pred"])

        cache = {}
        for name, v in variants.items():
            key = (v.get("jpeg_quality", 95), v.get("rounding", False), v.get("bgr_ccm", False))
            if key not in cache:
                cache[key] = model_rgb(raw, ccm, *key)
            rgb, enc = cache[key]
            rf = rf_probs(assets, rgb, v.get("rf_interp", cv2.INTER_LINEAR))
            if "tf_decode" in v:
                cnn_rgb = tf.io.decode_jpeg(enc, channels=3, dct_method=v["tf_decode"]).numpy()
            else:
                cnn_rgb = rgb
            p = pooled(assets, cnn_rgb, v.get("cv2_resize", False))
            if v.get("det"):
                _, det = assets.head_det(p)
                cnn = det.numpy()[0].astype(np.float64)
            else:
                cnn = mc_mean(assets, p)
            g = final(assets, rf, cnn)
            a = agree[name]
            a[0] += g == cf
            a[1] += int(np.argmax(rf)) + 1 == crf
            a[2] += int(np.argmax(cnn)) + 1 == ccnn
            if name == "baseline (server)":
                base_final[r["image"]] = g
                base_rf, base_p = rf, p
            elif g != base_final[r["image"]]:
                flips[name].append(r["image"])

        # Seed sensitivity (baseline image): MC Dropout seeds and GrabCut seeds.
        rgb = cache[(95, False, False)][0]
        finals = []
        for j, sd in enumerate(mc_seeds):
            g = final(assets, base_rf, mc_mean(assets, base_p, seed=sd))
            mc_final_agree[j] += g == cf
            finals.append(g)
        if len(set(finals)) > 1:
            mc_flip[r["image"]] = sorted(set(finals))
        rfs = []
        for j, sd in enumerate(gc_seeds):
            g = int(np.argmax(rf_probs(assets, rgb, seed=sd))) + 1
            gc_rf_agree[j] += g == crf
            rfs.append(g)
        if len(set(rfs)) > 1:
            gc_flip[r["image"]] = sorted(set(rfs))
        print(f"[{n:3d}/112] {r['image']}", flush=True)

    N = len(rows)
    out = ["# Parity investigation (STEP 4)", "",
           "Each variant changes one model-path step; counts are agreement with Colab over 112 images.", "",
           "| Variant | Final | RF | CNN-MC | Final flips vs baseline |", "|---|---|---|---|---|"]
    for name, (a, b, c) in agree.items():
        out.append(f"| {name} | {a}/{N} | {b}/{N} | {c}/{N} | {len(flips[name])} |")
    out += ["", "## Seed sensitivity", "",
            f"- MC Dropout seeds 0-9 (RF fixed): final agreement per seed = "
            f"{', '.join(str(int(x)) for x in mc_final_agree)} / {N}; "
            f"min {int(mc_final_agree.min())}, max {int(mc_final_agree.max())}, mean {mc_final_agree.mean():.1f}.",
            f"- Images whose final grade changes with the MC seed ({len(mc_flip)}): "
            + ", ".join(f"{k} {v}" for k, v in mc_flip.items()),
            f"- GrabCut seeds 0-9: RF agreement per seed = "
            f"{', '.join(str(int(x)) for x in gc_rf_agree)} / {N}.",
            f"- Images whose RF grade changes with the GrabCut seed ({len(gc_flip)}): "
            + ", ".join(f"{k} {v}" for k, v in gc_flip.items()),
            "", "## EXIF orientation", "",
            f"- Images where cv2 EXIF auto-rotation changes the decoded pixels: {len(exif_rotated)} "
            f"{exif_rotated}",
            "", "## preprocess_input", "",
            "- keras.applications.efficientnet.preprocess_input is a pass-through (the model has its own "
            "Rescaling/Normalization layers); server and training both call it on 0-255 float32.",
            ]
    with open(os.path.join(HERE, "parity_investigation.md"), "w") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
