"""Colour correction: the model path (must equal training) and the display path."""
import cv2
import numpy as np

PATCH_ORDER = ["white", "black", "grey_18", "grey_50", "blue", "red"]


def decode_image(data):
    """Decode JPEG/PNG bytes to an RGB uint8 array. Raises ValueError if invalid."""
    buf = np.frombuffer(data, np.uint8)
    bgr = cv2.imdecode(buf, cv2.IMREAD_COLOR)
    if bgr is None or bgr.ndim != 3 or bgr.shape[0] < 16 or bgr.shape[1] < 16:
        raise ValueError("invalid image")
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)


# ---------------------------------------------------------------- model path

def session_matrix(p_user, p_train):
    """3x3 map (no offset) from this session's patch colours to the training session's."""
    if p_user is None:
        return np.eye(3)
    a, _, _, _ = np.linalg.lstsq(np.asarray(p_user, np.float64) / 255.0,
                                 np.asarray(p_train, np.float64) / 255.0, rcond=None)
    return a


def model_path_image(raw_rgb, ccm_training, session):
    """Session mapping, then the training CCM exactly as training applied it, then
    the same JPEG round trip the training images went through (cv2.imwrite .jpg).

    Returns (rgb, jpeg_bytes): rgb is the cv2-decoded image used for the RF features,
    jpeg_bytes are decoded separately for the CNN, which training read with tf.io.decode_jpeg."""
    h, w, c = raw_rgb.shape
    f = raw_rgb.astype(np.float64).reshape(-1, 3) / 255.0
    f = np.clip(f @ session, 0, 1)
    out = (np.clip(f @ ccm_training, 0, 1) * 255).astype(np.uint8).reshape(h, w, c)
    ok, enc = cv2.imencode(".jpg", cv2.cvtColor(out, cv2.COLOR_RGB2BGR))
    if not ok:
        raise RuntimeError("jpeg encode failed")
    return cv2.cvtColor(cv2.imdecode(enc, cv2.IMREAD_COLOR), cv2.COLOR_BGR2RGB), enc.tobytes()


# -------------------------------------------------------------- display path

def fit_affine(p_user, reference):
    """4x3 affine (with offset) from measured patches to the CCC reference, 0-1 units."""
    x = np.asarray(p_user, np.float64) / 255.0
    x = np.hstack([x, np.ones((x.shape[0], 1))])
    m, _, _, _ = np.linalg.lstsq(x, np.asarray(reference, np.float64) / 255.0, rcond=None)
    return m


def display_path_image(raw_rgb, affine):
    h, w, c = raw_rgb.shape
    f = raw_rgb.astype(np.float64).reshape(-1, 3) / 255.0
    f = np.hstack([f, np.ones((f.shape[0], 1))]) @ affine
    return (np.clip(f, 0, 1) * 255).astype(np.uint8).reshape(h, w, c)
