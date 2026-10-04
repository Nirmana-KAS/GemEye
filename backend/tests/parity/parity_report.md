# GemEye v3 parity report

Server: `http://localhost:8000/grade`, training_session mode, referral_threshold 0.60, debug=true. Images: 112. Reference: parity_reference.csv (RF with GrabCut seeded 42 per image, deterministic CNN).

## Pass criteria

| Criterion | Value | Result |
|---|---|---|
| A. RF exactness: grade agreement 112/112 AND max abs dp <= 1e-6 | 112/112, max abs dp 4.99e-13 | **PASS** |
| B. CNN deterministic: max abs dp <= 0.01 AND grade agreement >= 111/112 | 112/112, max abs dp 2.85e-06 | **PASS** |
| C. Clean-98 accuracy within +/-2.0 of 86.73% | 87.76% | **PASS** |
| D. Every final-grade disagreement vs unseeded Colab has confidence < 0.60 on both sides | 9/9 | **PASS** |

Informational: vs unseeded Colab run (final_per_image_predictions.csv; GrabCut not seeded, different MC Dropout samples). These were the old pass criteria.

| Criterion | Value | Result |
|---|---|---|
| Final-grade agreement with Colab >= 95% (>= 107/112) | 103/112 | FAIL |
| RF agreement >= 95% | 110/112 | PASS |
| CNN-MC agreement >= 95% | 111/112 | PASS |

## Findings

- v3 training used cv2 decoding for the RF features and tf.io.decode_jpeg (default settings) for the CNN input. The server now does the same: it reproduces both exactly (RF max abs dp 4.99e-13, CNN deterministic max abs dp 2.85e-06, grade agreement 112/112 and 112/112).
- Remaining differences vs the original Colab evaluation (final_per_image_predictions.csv) come only from its unseeded GrabCut and unseeded MC Dropout; all 9 final-grade disagreements are below the 0.60 referral threshold on both sides.
- Average /grade latency (client side): 1226 ms (max 1859 ms).

## Deterministic reference

| Metric | Value |
|---|---|
| RF grade agreement | 112/112 |
| RF max abs probability difference | 4.993e-13 |
| CNN deterministic grade agreement | 112/112 |
| CNN deterministic max abs probability difference | 2.854e-06 |
| CNN deterministic mean per-image max abs difference | 7.612e-07 |

Worst RF: g3_016.jpg (4.99e-13), g3_030.jpg (4.98e-13), g4_148.jpg (4.97e-13), g7_101.jpg (4.92e-13), g3_129.jpg (4.92e-13)

Worst CNN deterministic: g5_031.jpg (2.85e-06), g1_152.jpg (2.78e-06), g2_106.jpg (2.68e-06), g6_016.jpg (2.63e-06), g5_010.jpg (2.23e-06)

## Final-grade disagreements vs unseeded Colab (9)

| Image | True | Final srv/colab | Conf srv | Conf colab | Both < 0.60 |
|---|---|---|---|---|---|
| g1_031.jpg | 1 | 2/4 | 0.3813 | 0.3527 | True |
| g2_148.jpg | 2 | 2/3 | 0.4034 | 0.3810 | True |
| g2_085.jpg | 2 | 1/2 | 0.5025 | 0.4874 | True |
| g4_032.jpg | 4 | 4/3 | 0.4457 | 0.4427 | True |
| g5_031.jpg | 5 | 4/6 | 0.3616 | 0.3435 | True |
| g6_101.jpg | 6 | 5/7 | 0.4092 | 0.4026 | True |
| g6_106.jpg | 6 | 5/6 | 0.4320 | 0.4530 | True |
| g6_129.jpg | 6 | 6/5 | 0.4189 | 0.4389 | True |
| g6_085.jpg | 6 | 6/5 | 0.3131 | 0.3362 | True |

## Metrics

| Metric | Server | Colab |
|---|---|---|
| Accuracy, clean 98 | 87.76% | 86.73% (expected 86.73%) |
| Accuracy, all 112 | 87.50% | 85.71% (expected 85.71%) |
| Macro-F1, all 112 | 0.8731 | 0.8544 |
| Within +/-1 grade, all 112 | 100.00% | 99.11% |
| RF accuracy | 66.07% | 66.07% (reference 66.07%) |
| CNN-MC accuracy | 83.04% | 83.93% |
| CNN deterministic accuracy | 84.82% | 84.82% (reference) |

| Agreement / error | Value |
|---|---|
| Final-grade agreement | 103/112 (91.96%) |
| RF agreement (unseeded Colab) | 110/112 (98.21%) |
| CNN-MC agreement | 111/112 (99.11%) |
| Mean abs(confidence - Colab confidence) | 0.0224 |
| Pearson r, uncertainty vs Colab MC uncertainty | 0.8816 |
| Model-path GrabCut fallbacks | 19/112 |
| Latency avg / max (client side, ms) | 1226 / 1859 |

## Disagreeing images (11, any grade differs)

| Image | True | Final srv/colab | RF srv/colab/ref | CNN-MC srv/colab | CNN-det srv/ref | RF max dp | CNN-det max dp | Conf srv/colab | Both < 0.60 | Seg fallback |
|---|---|---|---|---|---|---|---|---|---|---|
| g1_031.jpg | 1 | 2/4 | 2/2/2 | 4/4 | 4/4 | 3.40e-13 | 1.28e-06 | 0.3813/0.3527 | True | False |
| g2_148.jpg | 2 | 2/3 | 2/3/2 | 2/2 | 2/2 | 4.46e-13 | 4.93e-07 | 0.4034/0.3810 | True | False |
| g2_095.jpg | 2 | 2/2 | 2/2/2 | 1/2 | 2/2 | 4.01e-13 | 5.34e-07 | 0.4995/0.5269 |  | False |
| g2_085.jpg | 2 | 1/2 | 2/2/2 | 1/1 | 1/1 | 3.88e-13 | 1.39e-06 | 0.5025/0.4874 | True | False |
| g3_106.jpg | 3 | 3/3 | 2/3/2 | 3/3 | 3/3 | 3.79e-13 | 1.25e-06 | 0.4030/0.5592 |  | True |
| g4_032.jpg | 4 | 4/3 | 4/4/4 | 3/3 | 3/3 | 3.33e-13 | 1.20e-06 | 0.4457/0.4427 | True | False |
| g5_031.jpg | 5 | 4/6 | 6/6/6 | 4/4 | 4/4 | 3.97e-13 | 2.85e-06 | 0.3616/0.3435 | True | False |
| g6_101.jpg | 6 | 5/7 | 7/7/7 | 5/5 | 5/5 | 2.96e-13 | 6.72e-07 | 0.4092/0.4026 | True | False |
| g6_106.jpg | 6 | 5/6 | 5/5/5 | 6/6 | 6/6 | 4.76e-13 | 1.90e-06 | 0.4320/0.4530 | True | False |
| g6_129.jpg | 6 | 6/5 | 5/5/5 | 6/6 | 6/6 | 4.13e-13 | 3.31e-07 | 0.4189/0.4389 | True | False |
| g6_085.jpg | 6 | 6/5 | 3/3/3 | 6/6 | 6/6 | 3.02e-13 | 1.82e-06 | 0.3131/0.3362 | True | False |
