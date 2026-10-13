# Image-dir parity (/data/autocrop_test)

The 112 test images graded as originals and as read from the image dir (`run_parity.py --image-dir /data/autocrop_test`), each with gates on (as the app) and gates=false. Same server, no patches, referral_threshold 0.60.

Auto-crop detection status (autocrop.csv): not available. Upload bytes identical to the original (upload.csv): 0/112

| Metric | Normal | Image dir |
|---|---|---|
| Clean-98 accuracy, gates=false | 86/98 (87.76%) | 88/98 (89.80%) |
| All-112 accuracy, gates=false | 98/112 | 98/112 |
| Clean-98 accuracy on accepted images, gates on | 83/95 (87.37%) | 86/95 (90.53%) |
| Gate rejections, gates on (all 112) | 3 | 3 |
| - invalid_image | 0 | 0 |
| - no_stone | 2 | 2 |
| - blurry | 0 | 0 |
| - not_blue | 0 | 0 |
| - not_recognised | 1 | 1 |
| Grade agreement, image dir vs normal (gates=false) | 105/112 (93.75%) | |
| Mean abs confidence change | 0.0286 | |

| Criterion | Value | Result |
|---|---|---|
| Clean-98 accuracy within +/-1 image | +2 image(s) | **FAIL** |
| Gate rejections <= normal + 1 | 3 vs 3 | **PASS** |
| Overall | | **FAIL** |

## Grade changes (7)

| Image | True | Clean | Normal | Image dir | Conf normal | Conf image dir | Stone ratio |
|---|---|---|---|---|---|---|---|
| g2_148.jpg | 2 | False | 2 | 3 | 0.4034 | 0.4248 |  |
| g2_085.jpg | 2 | True | 1 | 2 | 0.5025 | 0.4896 |  |
| g3_030.jpg | 3 | True | 2 | 3 | 0.5420 | 0.4530 |  |
| g3_010.jpg | 3 | False | 3 | 4 | 0.5391 | 0.5801 |  |
| g5_129.jpg | 5 | True | 4 | 5 | 0.4532 | 0.4514 |  |
| g6_101.jpg | 6 | False | 5 | 7 | 0.4092 | 0.3850 |  |
| g6_085.jpg | 6 | True | 6 | 5 | 0.3131 | 0.3165 |  |

## Gate rejections

| Image | True | Normal | Image dir |
|---|---|---|---|
| g1_030.jpg | 1 | no_stone | no_stone |
| g6_085.jpg | 6 | not_recognised | not_recognised |
| g7_067.jpg | 7 | no_stone | no_stone |
