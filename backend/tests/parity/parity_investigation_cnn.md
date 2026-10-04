# Deterministic CNN investigation (Phase 2.1)

One input-path step changed per variant; compared with parity_reference.csv cnn_det_p1..7.

| Variant | Max abs dp | Mean per-image max abs dp | Median | Grade agreement | Worst image |
|---|---|---|---|---|---|
| baseline (server: split model, tf resize 224) | 3.354e-01 | 4.058e-02 | 2.167e-02 | 108/112 | g5_016.jpg |
| full keras model instead of split | 3.354e-01 | 4.058e-02 | 2.167e-02 | 108/112 | g5_016.jpg |
| decode tf.io.decode_jpeg INTEGER_ACCURATE | 3.354e-01 | 4.058e-02 | 2.167e-02 | 108/112 | g5_016.jpg |
| decode tf.io.decode_jpeg INTEGER_FAST | 2.854e-06 | 7.612e-07 | 5.783e-07 | 112/112 | g5_031.jpg |
| cv2 resize 256 then tf resize 224 | 6.570e-01 | 1.713e-01 | 1.039e-01 | 90/112 | g6_031.jpg |
| cv2 resize 224 INTER_LINEAR | 3.142e-01 | 3.881e-02 | 1.964e-02 | 109/112 | g5_016.jpg |
| cv2 resize 224 INTER_AREA | 6.709e-01 | 1.519e-01 | 9.839e-02 | 93/112 | g6_031.jpg |
| tf resize antialias=True | 8.050e-01 | 2.318e-01 | 1.626e-01 | 83/112 | g6_031.jpg |
| tf resize then uint8 cast | 3.285e-01 | 4.054e-02 | 2.508e-02 | 109/112 | g5_016.jpg |
| no JPEG round trip | 4.095e-01 | 7.766e-02 | 5.271e-02 | 103/112 | g2_085.jpg |
| CCM rounded | 1.877e-01 | 3.585e-02 | 2.532e-02 | 110/112 | g5_016.jpg |
| BGR channel order | 6.978e-01 | 1.792e-01 | 1.358e-01 | 92/112 | g6_031.jpg |
| EXIF orientation ignored | 3.354e-01 | 4.058e-02 | 2.167e-02 | 108/112 | g5_016.jpg |
| preprocess /255 (not pass-through) | 9.935e-01 | 6.881e-01 | 7.115e-01 | 14/112 | g7_067.jpg |
