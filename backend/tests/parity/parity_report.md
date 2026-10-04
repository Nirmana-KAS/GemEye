# GemEye v3 parity report

Server: `http://localhost:8000/grade`, training_session mode, referral_threshold 0.60, debug=true. Images: 112.

## Pass criteria

| Criterion | Value | Result |
|---|---|---|
| Clean-98 accuracy within +/-2.0 of 86.73% | clean_summary.json missing | **BLOCKED** |
| Final-grade agreement with Colab >= 95% (>= 107/112) | 105/112 | **FAIL** |
| RF agreement >= 95% | 110/112 | **PASS** |
| CNN-MC agreement >= 95% | 108/112 | **PASS** |

## Metrics

| Metric | Server | Colab |
|---|---|---|
| Accuracy, all 112 | 86.61% | 85.71% (expected 85.71%) |
| Macro-F1, all 112 | 0.8651 | 0.8544 |
| Within +/-1 grade, all 112 | 100.00% | 99.11% |
| RF accuracy | 66.07% | 66.07% |
| CNN-MC accuracy | 82.14% | 83.93% |
| CNN deterministic accuracy | 83.93% | - |

| Agreement / error | Value |
|---|---|
| Final-grade agreement | 105/112 (93.75%) |
| RF agreement | 110/112 (98.21%) |
| CNN-MC agreement | 108/112 (96.43%) |
| Mean abs(confidence - Colab confidence) | 0.0301 |
| Pearson r, uncertainty vs Colab MC uncertainty | 0.8659 |
| Model-path GrabCut fallbacks | 19/112 |
| Latency avg / max (client side, ms) | 1385 / 2103 |

## Disagreeing images (11)

| Image | True | Final srv/colab | RF srv/colab | CNN-MC srv/colab | Conf srv/colab | Seg fallback |
|---|---|---|---|---|---|---|
| g1_031.jpg | 1 | 2/4 | 2/2 | 4/4 | 0.3655/0.3527 | False |
| g2_148.jpg | 2 | 2/3 | 2/3 | 2/2 | 0.4463/0.3810 | False |
| g2_095.jpg | 2 | 2/2 | 2/2 | 1/2 | 0.5139/0.5269 | False |
| g3_105.jpg | 3 | 2/3 | 2/2 | 3/3 | 0.4094/0.3671 | True |
| g3_106.jpg | 3 | 2/3 | 2/3 | 3/3 | 0.4252/0.5592 | True |
| g3_129.jpg | 3 | 3/3 | 3/3 | 3/4 | 0.4642/0.4183 | False |
| g5_031.jpg | 5 | 4/6 | 6/6 | 4/4 | 0.4371/0.3435 | False |
| g5_016.jpg | 5 | 5/5 | 5/5 | 4/5 | 0.5239/0.6923 | False |
| g5_067.jpg | 5 | 5/5 | 5/5 | 4/5 | 0.5277/0.6100 | True |
| g6_129.jpg | 6 | 6/5 | 5/5 | 6/6 | 0.4240/0.4389 | False |
| g6_085.jpg | 6 | 6/5 | 3/3 | 6/6 | 0.3289/0.3362 | False |
