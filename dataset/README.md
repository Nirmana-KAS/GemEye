# GemEye Dataset

## Overview

| Item | Value |
|------|-------|
| Total images | 1,120 |
| Grades | 7 (GEMCLOUD standard) |
| Shapes | 4 (Baguette, Oval, Pear, Round) |
| Images per grade | 160 (40 per shape x 4 shapes) |
| Image format | JPEG |
| Resolution | 50MP (OnePlus Nord 2 5G, 1x sensor) |
| Lens | Apexel 100mm Ultra HD Macro + CPL filter |
| Calibration | CCC 6-patch session-level |
| Lighting | Indoor office, consistent, same location |
| Pre-processing | 80% crop, stone centred |

## Folder Structure

```
dataset/
├── raw_by_shape/          # Original images sorted by shape
│   ├── baguette/grade_1/ ... grade_7/    (40 images each)
│   ├── oval/grade_1/ ... grade_7/        (40 images each)
│   ├── pear/grade_1/ ... grade_7/        (40 images each)
│   └── round/grade_1/ ... grade_7/       (40 images each)
│
├── merged/                # All shapes merged by grade (training input)
│   ├── grade_1_dark/      (160 images)
│   ├── grade_2_deep/      (160 images)
│   ├── grade_3_vivid/     (160 images)
│   ├── grade_4_intense/   (160 images)
│   ├── grade_5_medium/    (160 images)
│   ├── grade_6_light/     (160 images)
│   └── grade_7_very_light/ (160 images)
│
├── ccc_patches/           # CCC calibration reference images
│   ├── white.jpg          # Patch 1: White (255, 255, 255)
│   ├── black.jpg          # Patch 2: Black (0, 0, 0)
│   ├── grey_18.jpg        # Patch 3: 18% Grey (117, 117, 117)
│   ├── grey_50.jpg        # Patch 4: 50% Grey (186, 186, 186)
│   ├── blue.jpg           # Patch 5: Blue (0, 63, 135)
│   └── red.jpg            # Patch 6: Red (175, 54, 60)
│
├── processed/             # After CCC colour correction (auto-generated)
│   └── grade_1/ ... grade_7/
│
├── splits/                # Train/Val/Test split (auto-generated)
│   ├── train/             # 80% of processed images
│   ├── val/               # 10% of processed images
│   └── test/              # 10% of processed images
│
└── README.md              # This file
```

## 7 GEMCLOUD Colour Grades

| Grade | Name | Trade Name | Colour Range |
|-------|------|------------|-------------|
| 1 | Dark | Ink Blue | #091A47 - #102670 |
| 2 | Deep | Midnight Blue | #102670 - #1B3A8C |
| 3 | Vivid | Royal Blue | #1B3A8C - #2E5BB8 |
| 4 | Intense | Sapphire Blue | #2E5BB8 - #4A80D4 |
| 5 | Medium | Ceylon Blue | #4A80D4 - #7BA7E8 |
| 6 | Light | Sky Blue | #7BA7E8 - #A8C8F0 |
| 7 | Very Light | Ice Blue | #A8C8F0 - #D6E5F8 |

## Capture Protocol

1. Place stone face-up on white gem tray
2. Attach Apexel 100mm macro lens + CPL filter to OnePlus Nord 2 5G
3. Capture CCC 6-patch images once per session (session-level calibration)
4. Capture stone images at 50MP, 1x sensor, consistent indoor office lighting
5. Crop to 80% zoom with stone centred in frame
6. 40 images per grade per shape

## Important Notes

- **Image files are NOT stored in this GitHub repository** (too large)
- Images are stored locally and on Google Drive for training
- This repository preserves only the folder structure via .gitkeep files
- To reproduce: place images in the correct grade folders and run the training pipeline

## Capture Device

- Phone: OnePlus Nord 2 5G (50MP main sensor)
- Lens: Apexel 100mm Ultra HD Macro
- Filter: CPL (Circular Polarising Lens)
- Zoom: 1x optical (native sensor)
- No dark box — controlled indoor office lighting
