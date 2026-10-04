"""Model and export assets, loaded once at startup."""
import json
import logging
import os
from dataclasses import dataclass

import joblib
import numpy as np

logger = logging.getLogger("gemeye.assets")


@dataclass
class Assets:
    model: object
    backbone: object               # tf.function: image batch -> pooled 1280-D (inference mode)
    head_det: object               # tf.function: pooled -> [256-D features, probs], no Dropout
    head_mc: object                # tf.function: pooled batch -> probs, Dropout layers active
    rf: object
    rf_class_order: np.ndarray     # column index of each grade 1..7 in predict_proba
    scaler: object
    config: dict
    w_cnn: float
    manifest: dict
    extra: dict
    gate_stats: dict
    ood_stats: dict
    grade_profiles: dict
    ccm_training: np.ndarray       # 3x3
    train_patches: np.ndarray      # 6x3, 0-255
    ccc_reference: np.ndarray      # 6x3, 0-255
    affine_default: np.ndarray     # 4x3
    ood_mean: np.ndarray
    ood_precision: np.ndarray
    ciecam02_display_available: bool
    mc_passes: int


def _json(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_assets(model_dir, export_dir):
    import tensorflow as tf
    import keras

    manifest = _json(os.path.join(export_dir, "export_manifest.json"))
    extra = _json(os.path.join(export_dir, "export_extra.json"))
    gate_stats = _json(os.path.join(export_dir, "gate_stats.json"))
    ood_stats = _json(os.path.join(export_dir, "ood_stats.json"))
    grade_profiles = _json(os.path.join(export_dir, "grade_profiles.json"))
    npz = np.load(os.path.join(export_dir, "ood_stats.npz"))
    config = _json(os.path.join(model_dir, "config_v3.json"))

    model = keras.models.load_model(os.path.join(model_dir, "efficientnet_v3.keras"), compile=False)
    dense = model.get_layer(ood_stats["feature_layer"])
    if getattr(dense, "units", None) != 256:
        raise RuntimeError("feature layer is not the 256-unit Dense layer")

    size = int(manifest.get("img_size", 224))

    # Dropout only exists in the classification head, so the backbone and pooling
    # run once per image in inference mode and only the head runs mc_passes times
    # as one batch. In head_mc only Dropout is active; BatchNorm stays in inference
    # mode (same as GemEye_Final_Evaluation_v3 mc_forward). Dropout masks come from
    # a fixed stateless seed keyed by the full-model layer index (one mask per batch
    # row), so the same image always gives the same MC result and grade. The maths
    # is Keras Dropout's: keep with prob 1-rate, scale kept units by 1/(1-rate).
    split = next(i for i, layer in enumerate(model.layers)
                 if isinstance(layer, keras.layers.GlobalAveragePooling2D)) + 1
    if any(isinstance(layer, keras.layers.Dropout) for layer in model.layers[:split]):
        raise RuntimeError("Dropout found before global pooling")
    pooled_dim = int(model.layers[split - 1].output.shape[-1])

    @tf.function(input_signature=[tf.TensorSpec([None, size, size, 3], tf.float32)])
    def backbone(x):
        for layer in model.layers[:split]:
            x = layer(x, training=False)
        return x

    @tf.function(input_signature=[tf.TensorSpec([None, pooled_dim], tf.float32)])
    def head_det(x):
        feat = None
        for layer in model.layers[split:]:
            x = layer(x, training=False)
            if layer is dense:
                feat = x
        return feat, x

    @tf.function(input_signature=[tf.TensorSpec([None, pooled_dim], tf.float32)])
    def head_mc(x):
        for i, layer in enumerate(model.layers[split:], start=split):
            if isinstance(layer, keras.layers.Dropout):
                keep = tf.random.stateless_uniform(tf.shape(x), seed=[42, i]) >= layer.rate
                x = tf.where(keep, x / (1.0 - layer.rate), tf.zeros_like(x))
            else:
                x = layer(x, training=False)
        return x

    rf = joblib.load(os.path.join(model_dir, "rf_model_v3.pkl"))
    scaler = joblib.load(os.path.join(model_dir, "scaler_v3.pkl"))
    classes = [int(c) for c in rf.classes_]
    if len(classes) != 7:
        raise RuntimeError("RF does not have 7 classes")
    # Classes may be 0..6 or 1..7; sorted order is grade order either way.
    rf_class_order = np.argsort(classes)
    if getattr(scaler, "n_features_in_", 12) != 12:
        raise RuntimeError("scaler does not expect 12 features")

    cam = extra.get("ciecam02_real", {})
    assets = Assets(
        model=model, backbone=backbone, head_det=head_det, head_mc=head_mc,
        rf=rf, rf_class_order=rf_class_order, scaler=scaler,
        config=config, w_cnn=float(config["w_cnn"]),
        manifest=manifest, extra=extra, gate_stats=gate_stats, ood_stats=ood_stats,
        grade_profiles=grade_profiles,
        ccm_training=np.asarray(manifest["ccm_training"], np.float64),
        train_patches=np.asarray(extra["training_patch_rgb_0_255"], np.float64),
        ccc_reference=np.asarray([manifest["ccc_reference_rgb"][k] for k in extra["patch_order"]], np.float64),
        affine_default=np.asarray(extra["ccm_affine_4x3"], np.float64),
        ood_mean=np.asarray(npz["mean"], np.float64),
        ood_precision=np.asarray(npz["precision"], np.float64),
        ciecam02_display_available=(int(cam.get("nan_count", 1)) == 0 and not cam.get("errors")),
        mc_passes=int(manifest.get("mc_dropout_passes", 30)),
    )
    logger.info("Assets loaded: RF classes %s, feature layer %s, MC passes %d",
                classes, dense.name, assets.mc_passes)
    return assets


def warm_up(assets):
    """One dummy prediction so the first real request is not slow."""
    size = int(assets.manifest.get("img_size", 224))
    x = np.zeros((1, size, size, 3), np.float32)
    pooled = assets.backbone(x)
    assets.head_det(pooled)
    assets.head_mc(np.repeat(pooled.numpy(), assets.mc_passes, axis=0))
