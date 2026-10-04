# Parity investigation (STEP 4)

Each variant changes one model-path step; counts are agreement with Colab over 112 images.

| Variant | Final | RF | CNN-MC | Final flips vs baseline |
|---|---|---|---|---|
| baseline (server) | 105/112 | 110/112 | 108/112 | 0 |
| no JPEG round trip | 102/112 | 89/112 | 103/112 | 9 |
| JPEG quality 100 | 104/112 | 101/112 | 108/112 | 3 |
| CCM output rounded (not truncated) | 101/112 | 94/112 | 111/112 | 10 |
| CCM applied in BGR order | 59/112 | 23/112 | 73/112 | 55 |
| RF resize INTER_AREA | 104/112 | 87/112 | 108/112 | 10 |
| CNN resize cv2 (not tf) | 105/112 | 110/112 | 108/112 | 0 |
| CNN decode tf.io.decode_jpeg ACCURATE | 105/112 | 110/112 | 108/112 | 0 |
| CNN decode tf.io.decode_jpeg FAST | 103/112 | 110/112 | 111/112 | 6 |
| CNN deterministic (no MC) | 106/112 | 110/112 | 108/112 | 3 |

## Seed sensitivity

- MC Dropout seeds 0-9 (RF fixed): final agreement per seed = 105, 104, 104, 105, 105, 108, 105, 104, 104, 104 / 112; min 104, max 108, mean 104.8.
- Images whose final grade changes with the MC seed (8): g3_105.jpg [2, 3], g3_106.jpg [2, 3], g3_095.jpg [1, 3, 4], g4_032.jpg [3, 4], g5_137.jpg [5, 6], g5_129.jpg [4, 5], g6_129.jpg [5, 6], g6_085.jpg [5, 6]
- GrabCut seeds 0-9: RF agreement per seed = 107, 108, 110, 111, 109, 106, 108, 111, 109, 109 / 112.
- Images whose RF grade changes with the GrabCut seed (10): g2_148.jpg [2, 3], g2_143.jpg [1, 3], g3_031.jpg [3, 4], g3_106.jpg [2, 3], g3_010.jpg [3, 4, 6], g4_031.jpg [3, 4], g4_030.jpg [3, 4, 5], g5_105.jpg [3, 5, 7], g5_137.jpg [5, 6], g6_016.jpg [6, 7]

## EXIF orientation

- Images where cv2 EXIF auto-rotation changes the decoded pixels: 0 []

## preprocess_input

- keras.applications.efficientnet.preprocess_input is a pass-through (the model has its own Rescaling/Normalization layers); server and training both call it on 0-255 float32.
