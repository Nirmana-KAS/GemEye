# Automatic stone framing (Phase F1) - report

Result: **FAIL**. The app flow was not changed (step 5 not done).

## 1. Detector

`app/lib/utils/stone_autocrop.dart` (pure Dart, package:image). Decode + EXIF
orientation, working copy with longer side 512, tray colour = per-channel median
of an 8% border ring, mask = RGB distance from the tray colour > `kStoneDistance`,
3x3 open, 8-connected components, largest component with centroid in the
central 80% and area 0.2%-40%. Stone diameter = max(bbox width, height).

`kStoneDistance`: the first value, 40, let the darker shade band across the
middle of the training tray (tray distance up to about 50) join the stone
(median ratio 0.53, boxes spanning the tray). 80 gives tight boxes on all
training/validation images (checked visually on random and extreme samples);
80-100 give the same statistics (median 0.348 / 0.346). Set to 80.

## 2. Target from training data only

Training/validation = `dataset/merged` minus the 112 test images in
`backend/tests/parity/final_per_image_predictions.csv` (1008 images, all
1228x1228). `dart run tool/autocrop_batch.dart ../dataset/merged OUT --stats
--exclude ../backend/tests/parity/final_per_image_predictions.csv`:

| Statistic | Stone diameter / image side |
|---|---|
| n | 1008 |
| notFound | 0 |
| median (`kTargetStoneRatio`) | **0.3485** |
| p1 (`kMinStoneRatio`) | **0.1865** |
| p5 | 0.1979 |
| p95 | 0.4560 |
| p99 (`kMaxStoneRatio`) | **0.5090** |
| min / max | 0.1710 / 0.5261 |

## 3. Accuracy check on the 112 test images

`dart run tool/autocrop_batch.dart ../dataset/merged ../dataset/autocrop_test
--only ../backend/tests/parity/final_per_image_predictions.csv`, then
`run_parity.py --image-dir /data/autocrop_test` (gates on and gates=false; full
table in `backend/tests/parity/parity_autocrop_report.md`).

Detection: ok 112, notFound 0, tooClose 0, tooSmallImage 0. 45 images were
zoomed in (crop side 657-1227 px, median 1022); 67 already had the stone above
the target ratio, so their crop is the whole 1228 px frame (pixels unchanged,
only decoded and re-encoded by package:image at JPEG quality 100).

| Metric | Normal | Auto-crop |
|---|---|---|
| Clean-98 accuracy, gates=false | 86/98 (87.76%) | 80/98 (81.63%) |
| All-112 accuracy, gates=false | 98/112 | 90/112 |
| Clean-98 accuracy on accepted images, gates on | 83/95 (87.37%) | 79/97 (81.44%) |
| Gate rejections, gates on | 3 (no_stone 2, not_recognised 1) | 1 (not_recognised 1) |
| Grade agreement auto-crop vs normal | 96/112 (85.71%) | |
| Mean abs confidence change | 0.0550 | |

| Criterion | Value | Result |
|---|---|---|
| Clean-98 accuracy within +/-1 image | -6 images | **FAIL** |
| Gate rejections <= normal + 1 | 1 vs 3 | PASS |

### Changed grades (16)

| Image | True | Clean | Normal (conf) | Auto-crop (conf) | Crop |
|---|---|---|---|---|---|
| g1_032 | 1 | yes | 1 (0.4918) | 2 (0.5615) | zoomed |
| g1_016 | 1 | yes | 1 (0.6286) | 2 (0.3008) | zoomed |
| g1_030 | 1 | yes | 1 (0.4097) | 3 (0.4521) | zoomed |
| g2_105 | 2 | yes | 1 (0.4579) | 3 (0.3945) | zoomed |
| g2_148 | 2 | no | 2 (0.4034) | 3 (0.4473) | full frame |
| g2_085 | 2 | yes | 1 (0.5025) | 2 (0.4794) | zoomed |
| g3_030 | 3 | yes | 2 (0.5420) | 3 (0.4506) | full frame |
| g3_010 | 3 | no | 3 (0.5391) | 4 (0.5750) | full frame |
| g4_031 | 4 | yes | 4 (0.7408) | 3 (0.4405) | full frame |
| g4_095 | 4 | yes | 4 (0.4710) | 3 (0.5020) | zoomed |
| g4_067 | 4 | yes | 4 (0.8549) | 6 (0.4055) | zoomed |
| g5_129 | 5 | yes | 4 (0.4532) | 5 (0.4405) | zoomed |
| g5_067 | 5 | yes | 5 (0.5599) | 6 (0.3055) | zoomed |
| g6_101 | 6 | no | 5 (0.4092) | 7 (0.3878) | full frame |
| g7_106 | 7 | yes | 7 (0.8245) | 6 (0.5074) | zoomed |
| g7_067 | 7 | yes | 7 (0.6606) | 6 (0.6196) | zoomed |

## 4. Cause

1. **Zooming changes the model input.** 10 of the 45 zoomed images changed
   grade (22%), including confident ones (g4_067 0.85 -> grade 6, g7_106 0.82).
   The training images keep each stone at its natural size (ratio 0.19-0.51)
   with the tray around it; the model was never trained on photos rescaled to
   one fixed ratio, and enlarging small stones changes the CNN input scale and
   the tray share the RF/GrabCut features see.
2. **package:image decode + re-encode shifts pixels.** 6 of the 67 full-frame
   crops changed grade (9%) although the crop is the full frame. Compared with
   the original (decoded by OpenCV), the re-encoded files differ by 0.73 levels
   on average (mean signed +0.63, max 23), which is enough to move borderline
   stones. The OpenCV downscale check (`parity_downscale_report.md`) changed only
   3/112. Note: the app's existing upload path (`prepareUploadJpeg`) also decodes and
   re-encodes with package:image, so this effect may already be present in
   production. It is worth its own parity check.

No thresholds were tuned on the test set. Options for a later phase (need
training-data evidence first): keep framing guidance in the app instead of
zooming, crop the encoded JPEG losslessly so pixels are untouched, or retrain
with framing (scale) augmentation.
