# Grad-CAM statistics (Phase 8.1)

112 test images, training_session mode, gates off, target = final grade. Area = stone_area_fraction (share of the 256 px image inside the GrabCut stone mask, seed 42). Heat = stone_mask_heat_fraction (share of the total Grad-CAM heat inside that mask). Heat/area = heat / area; 1.0 is what a uniform map would give.

## All images

| Group | n | Area mean | Area median | Heat mean | Heat median | Heat/area mean | Heat/area median | Heat/area > 1 |
|---|---|---|---|---|---|---|---|---|
| All | 112 | 0.083 | 0.069 | 0.372 | 0.381 | 4.89 | 4.95 | 112/112 (100.0%) |

## Per true grade

| Group | n | Area mean | Area median | Heat mean | Heat median | Heat/area mean | Heat/area median | Heat/area > 1 |
|---|---|---|---|---|---|---|---|---|
| Grade 1 | 16 | 0.113 | 0.079 | 0.311 | 0.296 | 3.38 | 3.63 | 16/16 (100.0%) |
| Grade 2 | 16 | 0.073 | 0.067 | 0.266 | 0.269 | 3.69 | 3.41 | 16/16 (100.0%) |
| Grade 3 | 16 | 0.085 | 0.076 | 0.355 | 0.344 | 4.43 | 4.63 | 16/16 (100.0%) |
| Grade 4 | 16 | 0.077 | 0.069 | 0.314 | 0.284 | 4.20 | 4.45 | 16/16 (100.0%) |
| Grade 5 | 16 | 0.081 | 0.074 | 0.374 | 0.400 | 4.87 | 5.40 | 16/16 (100.0%) |
| Grade 6 | 16 | 0.074 | 0.067 | 0.494 | 0.493 | 6.78 | 6.45 | 16/16 (100.0%) |
| Grade 7 | 16 | 0.077 | 0.066 | 0.494 | 0.462 | 6.90 | 7.11 | 16/16 (100.0%) |

## Per predicted grade (the Grad-CAM target)

| Group | n | Area mean | Area median | Heat mean | Heat median | Heat/area mean | Heat/area median | Heat/area > 1 |
|---|---|---|---|---|---|---|---|---|
| Grade 1 | 18 | 0.111 | 0.079 | 0.325 | 0.298 | 3.59 | 3.63 | 18/18 (100.0%) |
| Grade 2 | 15 | 0.069 | 0.066 | 0.243 | 0.233 | 3.50 | 3.40 | 15/15 (100.0%) |
| Grade 3 | 14 | 0.088 | 0.080 | 0.368 | 0.360 | 4.45 | 4.78 | 14/14 (100.0%) |
| Grade 4 | 20 | 0.077 | 0.069 | 0.288 | 0.264 | 3.88 | 3.85 | 20/20 (100.0%) |
| Grade 5 | 14 | 0.079 | 0.069 | 0.424 | 0.427 | 5.75 | 6.00 | 14/14 (100.0%) |
| Grade 6 | 13 | 0.077 | 0.080 | 0.507 | 0.548 | 6.71 | 6.11 | 13/13 (100.0%) |
| Grade 7 | 18 | 0.076 | 0.066 | 0.487 | 0.455 | 6.86 | 7.05 | 18/18 (100.0%) |

## Latency (client side)

| Metric | Value |
|---|---|
| Heatmap, first call avg / max (ms) | 1660 / 3159 |
| Heatmap, cache hit avg (ms) | 211 |

## Interpretation

Grad-CAM shows where the CNN branch looked, not the Random Forest or the ensemble. It is computed on the 7x7 top_activation grid and upsampled, so it is coarse and cannot resolve facets or small inclusions. It is correlational: high heat marks regions whose activations raise the target class score, not proof that the colour of those pixels caused the grade. Heat/area above 1 means the CNN weights the stone more than a uniform map would; heat outside the mask means it also uses the tray and edges. Reliance on the background would be a limitation of the CNN branch (it could react to tray, lighting or framing). These numbers describe where the heat falls on this test set only; they do not show whether that heat is used correctly.
