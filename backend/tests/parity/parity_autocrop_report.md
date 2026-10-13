# Auto-crop parity

The 112 test images graded as originals and as auto-cropped by the app (`run_parity.py --image-dir /data/autocrop_test`), each with gates on (as the app) and gates=false. Same server, no patches, referral_threshold 0.60.

Detection status (autocrop.csv): ok 112

| Metric | Normal | Auto-crop |
|---|---|---|
| Clean-98 accuracy, gates=false | 86/98 (87.76%) | 80/98 (81.63%) |
| All-112 accuracy, gates=false | 98/112 | 90/112 |
| Clean-98 accuracy on accepted images, gates on | 83/95 (87.37%) | 79/97 (81.44%) |
| Gate rejections, gates on (all 112) | 3 | 1 |
| - invalid_image | 0 | 0 |
| - no_stone | 2 | 0 |
| - blurry | 0 | 0 |
| - not_blue | 0 | 0 |
| - not_recognised | 1 | 1 |
| Grade agreement, auto-crop vs normal (gates=false) | 96/112 (85.71%) | |
| Mean abs confidence change | 0.0550 | |

| Criterion | Value | Result |
|---|---|---|
| Clean-98 accuracy within +/-1 image | -6 image(s) | **FAIL** |
| Gate rejections <= normal + 1 | 1 vs 3 | **PASS** |
| Overall | | **FAIL** |

## Grade changes (16)

| Image | True | Clean | Normal | Auto-crop | Conf normal | Conf auto-crop | Stone ratio |
|---|---|---|---|---|---|---|---|
| g1_032.jpg | 1 | True | 1 | 2 | 0.4918 | 0.5615 | 0.3487 |
| g1_016.jpg | 1 | True | 1 | 2 | 0.6286 | 0.3008 | 0.3486 |
| g1_030.jpg | 1 | True | 1 | 3 | 0.4097 | 0.4521 | 0.3487 |
| g2_105.jpg | 2 | True | 1 | 3 | 0.4579 | 0.3945 | 0.3487 |
| g2_148.jpg | 2 | False | 2 | 3 | 0.4034 | 0.4473 | 0.4308 |
| g2_085.jpg | 2 | True | 1 | 2 | 0.5025 | 0.4794 | 0.3483 |
| g3_030.jpg | 3 | True | 2 | 3 | 0.5420 | 0.4506 | 0.4169 |
| g3_010.jpg | 3 | False | 3 | 4 | 0.5391 | 0.5750 | 0.4194 |
| g4_031.jpg | 4 | True | 4 | 3 | 0.7408 | 0.4405 | 0.4186 |
| g4_095.jpg | 4 | True | 4 | 3 | 0.4710 | 0.5020 | 0.3487 |
| g4_067.jpg | 4 | True | 4 | 6 | 0.8549 | 0.4055 | 0.3487 |
| g5_129.jpg | 5 | True | 4 | 5 | 0.4532 | 0.4405 | 0.3526 |
| g5_067.jpg | 5 | True | 5 | 6 | 0.5599 | 0.3055 | 0.3486 |
| g6_101.jpg | 6 | False | 5 | 7 | 0.4092 | 0.3878 | 0.3583 |
| g7_106.jpg | 7 | True | 7 | 6 | 0.8245 | 0.5074 | 0.3486 |
| g7_067.jpg | 7 | True | 7 | 6 | 0.6606 | 0.6196 | 0.3486 |

## Gate rejections

| Image | True | Normal | Auto-crop |
|---|---|---|---|
| g1_030.jpg | 1 | no_stone | ok |
| g6_085.jpg | 6 | not_recognised | not_recognised |
| g7_067.jpg | 7 | no_stone | ok |
