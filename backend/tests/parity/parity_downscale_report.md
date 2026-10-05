# Downscale parity (longer side <= 2048, JPEG q95)

Each image graded as the original and as the app uploads it (`run_parity.py --downscale`). Same server, gates off, no patches.

| Metric | Value |
|---|---|
| Grade agreement, downscaled vs normal | 109/112 (97.32%) |
| Correct, normal | 98/112 (87.50%) |
| Correct, downscaled | 97/112 (86.61%) |
| Mean abs confidence change | 0.0129 |
| Accuracy within +/-1 image | **PASS** (difference -1) |

## Grade changes (3)

| Image | True | Normal | Downscaled | Conf normal | Conf downscaled |
|---|---|---|---|---|---|
| g2_148.jpg | 2 | 2 | 3 | 0.4034 | 0.3893 |
| g3_010.jpg | 3 | 3 | 4 | 0.5391 | 0.6031 |
| g6_016.jpg | 6 | 7 | 6 | 0.4429 | 0.4324 |
