"""Grad-CAM on the CNN branch of the v3 ensemble (Phase 8).

Explanation aid only: it never changes a grade. The CNN input is rebuilt from
the stored original upload with the same model path and the same calibration
mode the grading used (inference.grade), then Grad-CAM runs on the last conv
activation of EfficientNet-B0 ("top_activation") with the deterministic model
(Dropout off, BatchNorm in inference mode). The target class is the grading's
final (ensemble) grade, read on the CNN output.
"""
import cv2
import numpy as np
import tensorflow as tf

from app.pipeline import colour as colour_path
from app.pipeline import display
from app.pipeline.inference import cnn_input

METHOD = "gradcam_cnn_branch"
CONV_LAYER = "top_activation"
OVERLAY_ALPHA = 0.4
DISPLAY_MAX_SIDE = 640


def build(model):
    """tf.function (x (1, size, size, 3), class index) -> (cam (h, w), CNN probabilities).

    The Keras model nests the EfficientNet-B0 backbone as one Functional layer
    whose output is top_activation; the pooling and classification head follow
    as top-level layers. The gradient runs from the target class score (the
    logit, before softmax) back to that activation."""
    import keras

    conv_idx = next((i for i, layer in enumerate(model.layers)
                     if layer.name == CONV_LAYER
                     or (hasattr(layer, "get_layer") and _has_layer(layer, CONV_LAYER))), None)
    if conv_idx is None:
        raise RuntimeError(f"{CONV_LAYER} not found in the model")
    backbone = model.layers[conv_idx]
    if backbone.name != CONV_LAYER and backbone.get_layer(CONV_LAYER).output is not backbone.output:
        raise RuntimeError(f"{CONV_LAYER} is not the backbone output")
    head = model.layers[conv_idx + 1:]
    last = head[-1]
    softmax_last = (isinstance(last, keras.layers.Dense)
                    and getattr(last.activation, "__name__", "") == "softmax")
    size = int(model.input_shape[1])

    @tf.function(input_signature=[tf.TensorSpec([1, size, size, 3], tf.float32),
                                  tf.TensorSpec([], tf.int32)])
    def gradcam(x, class_idx):
        conv = x
        for layer in model.layers[:conv_idx + 1]:
            conv = layer(conv, training=False)
        with tf.GradientTape() as tape:
            tape.watch(conv)
            y = conv
            for layer in head[:-1]:
                y = layer(y, training=False)
            if softmax_last:
                logits = tf.matmul(y, last.kernel) + last.bias
                probs = tf.nn.softmax(logits)
            else:
                logits = probs = last(y, training=False)
            score = logits[:, class_idx]
        grads = tape.gradient(score, conv)
        if grads is None:
            raise RuntimeError("Grad-CAM gradient is None")
        weights = tf.reduce_mean(grads, axis=(1, 2))                       # (1, C)
        cam = tf.nn.relu(tf.reduce_sum(conv * weights[:, tf.newaxis, tf.newaxis, :], axis=-1))
        return cam[0], probs[0]

    return gradcam


def _has_layer(model, name):
    try:
        model.get_layer(name)
        return True
    except ValueError:
        return False


def model_cnn_input(assets, raw_rgb, patches):
    """The CNN input exactly as inference.grade/predict_cnn built it. patches is
    None for training_session gradings, the stored 6x3 patches for session_patches."""
    if patches is None:
        session = colour_path.session_matrix(None, None)
    else:
        session = colour_path.session_matrix(patches, assets.train_patches)
    _, jpeg = colour_path.model_path_image(raw_rgb, assets.ccm_training, session)
    size = int(assets.manifest.get("img_size", 224))
    return cnn_input(tf.io.decode_jpeg(jpeg, channels=3), size)[tf.newaxis]


def normalise(cam):
    """Scale to [0, 1]; an all-zero map stays zero."""
    cam = np.maximum(np.asarray(cam, np.float64), 0.0)
    top = cam.max()
    return cam / top if top > 0 else np.zeros_like(cam)


def compute(assets, raw_rgb, patches, grade):
    """Returns (cam in [0, 1] at conv resolution, CNN probabilities)."""
    x = model_cnn_input(assets, raw_rgb, patches)
    cam, probs = assets.gradcam(x, tf.constant(int(grade) - 1, tf.int32))
    return normalise(cam.numpy()), probs.numpy().astype(np.float64)


def stone_heat_fraction(cam, mask):
    """Share of the total heat inside the stone mask (cam upsampled to the mask size)."""
    h, w = mask.shape
    up = np.clip(cv2.resize(cam.astype(np.float32), (w, h), interpolation=cv2.INTER_LINEAR), 0, 1)
    total = float(up.sum())
    return float(up[mask].sum()) / total if total > 0 else 0.0


def overlay(raw_rgb, gain, cam):
    """Jet heatmap at OVERLAY_ALPHA over the tray-balanced display image (RGB uint8)."""
    h, w = raw_rgb.shape[:2]
    k = min(1.0, DISPLAY_MAX_SIDE / max(h, w))
    size = (max(1, round(w * k)), max(1, round(h * k)))
    img = cv2.resize(raw_rgb, size, interpolation=cv2.INTER_AREA) if k < 1 else raw_rgb
    base = np.clip(img.astype(np.float64) * gain, 0, 255)
    up = np.clip(cv2.resize(cam.astype(np.float32), size, interpolation=cv2.INTER_LINEAR), 0, 1)
    heat = cv2.applyColorMap(np.rint(up * 255).astype(np.uint8), cv2.COLORMAP_JET)
    heat = cv2.cvtColor(heat, cv2.COLOR_BGR2RGB).astype(np.float64)
    return np.rint((1 - OVERLAY_ALPHA) * base + OVERLAY_ALPHA * heat).astype(np.uint8)


def heatmap(assets, raw_rgb, patches, grade):
    """Full Grad-CAM for one grading: (PNG bytes, stone_mask_heat_fraction, cam)."""
    cam, _ = compute(assets, raw_rgb, patches, grade)
    wb = display.tray_balanced_measure(raw_rgb)
    fraction = stone_heat_fraction(cam, wb.mask)
    ok, png = cv2.imencode(".png", cv2.cvtColor(overlay(raw_rgb, wb.gain, cam), cv2.COLOR_RGB2BGR))
    if not ok:
        raise RuntimeError("png encode failed")
    return png.tobytes(), fraction, cam
