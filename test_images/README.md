# App Test Images

2 stone images per grade (14 total), copied from `dataset/merged/`. Every image was graded by the live backend model (v3, `grade()` in the Docker container) on 06 October 2026 and passed:

- correct grade, status `ok`, not referred (referral threshold 0.60, quality gates on, no calibration patches)
- tested twice: the original file, and as the app uploads it (longer side 2048 px, JPEG q95)

| Grade | Folder | Image | Confidence (original / app upload) | In training? |
|---|---|---|---|---|
| 1 Dark | grade_1_dark | g1_137.jpg | 0.982 / 0.983 | No (test set) |
| 1 Dark | grade_1_dark | g1_143.jpg | 0.982 / 0.982 | No (test set) |
| 2 Deep | grade_2_deep | g2_010.jpg | 0.767 / 0.765 | No (test set) |
| 2 Deep | grade_2_deep | g2_016.jpg | 0.687 / 0.697 | No (test set) |
| 3 Vivid | grade_3_vivid | g3_137.jpg | 0.670 / 0.670 | No (test set) |
| 3 Vivid | grade_3_vivid | g3_077.jpg | 0.894 / 0.895 | Yes (train/val) |
| 4 Intense | grade_4_intense | g4_067.jpg | 0.855 / 0.854 | No (test set) |
| 4 Intense | grade_4_intense | g4_085.jpg | 0.834 / 0.829 | No (test set) |
| 5 Medium Intense | grade_5_medium | g5_095.jpg | 0.748 / 0.755 | No (test set) |
| 5 Medium Intense | grade_5_medium | g5_016.jpg | 0.679 / 0.682 | No (test set) |
| 6 Light | grade_6_light | g6_067.jpg | 0.771 / 0.780 | No (test set) |
| 6 Light | grade_6_light | g6_148.jpg | 0.763 / 0.755 | No (test set) |
| 7 Very Light | grade_7_very_light | g7_137.jpg | 0.939 / 0.940 | No (test set) |
| 7 Very Light | grade_7_very_light | g7_143.jpg | 0.893 / 0.889 | No (test set) |

Notes:
- Test-set images are the clean held-out set (exact and near duplicates of training images excluded).
- Grade 3 has only one clean test image that passes without referral, so g3_077 (seen in training) is the second.
- Use: copy to the phone, then Capture screen > Gallery. Without a calibration session the result matches the table; with session patches applied the confidence may differ slightly.
