# Image-dir parity (/data/autocrop_test)

The 112 test images graded as originals and as read from the image dir (`run_parity.py --image-dir /data/autocrop_test`), each with gates on (as the app) and gates=false. Same server, no patches, referral_threshold 0.60.

Auto-crop detection status (autocrop.csv): not available. Upload bytes identical to the original (upload.csv): 112/112

| Metric | Normal | Image dir |
|---|---|---|
| Clean-98 accuracy, gates=false | 86/98 (87.76%) | 86/98 (87.76%) |
| All-112 accuracy, gates=false | 98/112 | 98/112 |
| Clean-98 accuracy on accepted images, gates on | 83/95 (87.37%) | 83/95 (87.37%) |
| Gate rejections, gates on (all 112) | 3 | 3 |
| - invalid_image | 0 | 0 |
| - no_stone | 2 | 2 |
| - blurry | 0 | 0 |
| - not_blue | 0 | 0 |
| - not_recognised | 1 | 1 |
| Grade agreement, image dir vs normal (gates=false) | 112/112 (100.00%) | |
| Mean abs confidence change | 0.0000 | |

| Criterion | Value | Result |
|---|---|---|
| Clean-98 accuracy within +/-1 image | +0 image(s) | **PASS** |
| Gate rejections <= normal + 1 | 3 vs 3 | **PASS** |
| Overall | | **PASS** |

## Grade changes (0)

| Image | True | Clean | Normal | Image dir | Conf normal | Conf image dir | Stone ratio |
|---|---|---|---|---|---|---|---|

## Gate rejections

| Image | True | Normal | Image dir |
|---|---|---|---|
| g1_030.jpg | 1 | no_stone | no_stone |
| g6_085.jpg | 6 | not_recognised | not_recognised |
| g7_067.jpg | 7 | no_stone | no_stone |
