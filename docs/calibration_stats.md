# Calibration statistics

Database: gemeye_dev (read-only). Sessions analysed: 3 of 3 stored.
Devices: 1 (OnePlus DN2103)

Self-check on the training patches: relative_residual = 6.27e-16 (expected ~0); sanity all pass

## Sessions

| # | Date (UTC) | Device | Abs. residual | Relative residual | Worst patch (err) | Sanity fails |
|---|---|---|---|---|---|---|
| 1 | 2026-10-05 04:05 | OnePlus DN2103 | 0.1663 | 0.2668 | grey_18 (0.4816) | none |
| 2 | 2026-10-05 11:43 | OnePlus DN2103 | 0.1663 | 0.2668 | grey_18 (0.4816) | none |
| 3 | 2026-10-06 02:45 | OnePlus DN2103 | 0.0495 | 0.2479 | black (0.4881) | none |

## relative_residual

min 0.2479, median 0.2668, p90 0.2668, max 0.2668

## Sanity failures

- grey_steps: 0 of 3
- white_vs_grey50: 0 of 3
- blue_dominant: 0 of 3
- red_dominant: 0 of 3
- white_not_overexposed: 0 of 3

## Proposed limits

Only 3 session(s) stored (need at least 5). No X/Y proposed.
