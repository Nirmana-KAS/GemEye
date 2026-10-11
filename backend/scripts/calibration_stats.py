"""Read-only calibration statistics. Run inside the container (ENV=development):

    python scripts/calibration_stats.py > /tmp/calibration_stats.md   (markdown on stdout)

Refuses ENV=production. Never prints uid or email. Nothing is written to MongoDB."""
import json
import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.config import get_settings  # noqa: E402
from app.pipeline.colour import PATCH_ORDER, session_matrix  # noqa: E402
from pymongo import MongoClient  # noqa: E402

MIN_SESSIONS = 5


def relative_errors(p_user, p_train):
    """Per-patch error and overall RMS after the session matrix (computeCcm definition)."""
    u = np.asarray(p_user, np.float64) / 255.0
    t = np.asarray(p_train, np.float64) / 255.0
    a = session_matrix(p_user, p_train)
    sq = ((u @ a - t) ** 2).sum(axis=1)          # per patch, summed over RGB
    return float(np.sqrt(sq.mean())), np.sqrt(sq)


def sanity(p):
    """Returns {check: passed}."""
    p = np.asarray(p, np.float64)
    y = p @ np.array([0.299, 0.587, 0.114])
    w, k, g18, g50, b, r = range(6)
    return {
        "grey_steps": bool(y[g50] > y[g18] + 5 and y[g18] > y[k] + 5),
        "white_vs_grey50": bool(y[w] >= y[g50] - 5),
        "blue_dominant": bool(p[b, 2] > p[b, 0] + 20 and p[b, 2] > p[b, 1]),
        "red_dominant": bool(p[r, 0] > p[r, 2] + 20 and p[r, 0] > p[r, 1]),
        "white_not_overexposed": bool(not (p[w] >= 250).all()),
    }


def main():
    s = get_settings()
    if s.is_production:
        sys.exit("refusing to run with ENV=production")
    export_dir = Path(os.environ.get("EXPORT_DIR", s.export_dir))
    extra = json.loads((export_dir / "export_extra.json").read_text())
    train = np.asarray(extra["training_patch_rgb_0_255"], np.float64)

    client = MongoClient(s.mongodb_uri.get_secret_value(), tz_aware=True,
                         serverSelectionTimeoutMS=10000)
    docs = list(client[s.db_name]["calibrations"].find(
        {}, {"measured_patches": 1, "residual": 1, "quality": 1, "created_at": 1, "device": 1}
    ).sort("created_at", 1))

    rows = []
    for d in docs:
        try:
            p = np.asarray(d["measured_patches"], np.float64)
            if p.shape != (6, 3):
                continue
        except (KeyError, ValueError, TypeError):
            continue
        rel, per = relative_errors(p, train)
        worst = int(np.argmax(per))
        rows.append({
            "date": d["created_at"].strftime("%Y-%m-%d %H:%M") if d.get("created_at") else "-",
            "device": str(d.get("device") or "-")[:40],
            "abs": d.get("residual"), "rel": rel, "worst": PATCH_ORDER[worst],
            "worst_err": float(per[worst]), "san": sanity(p),
        })

    self_rel, _ = relative_errors(train, train)
    self_san = sanity(train)
    checks = list(self_san)
    rels = np.array([r["rel"] for r in rows])
    devices = sorted({r["device"] for r in rows})

    out = ["# Calibration statistics", "",
           f"Database: {s.db_name} (read-only). Sessions analysed: {len(rows)} of {len(docs)} stored.",
           f"Devices: {len(devices)}" + (f" ({', '.join(devices)})" if devices else ""), "",
           "Self-check on the training patches: relative_residual = "
           f"{self_rel:.2e} (expected ~0); sanity "
           + ("all pass" if all(self_san.values()) else f"FAIL {self_san}"), ""]

    if rows:
        out += ["## Sessions", "",
                "| # | Date (UTC) | Device | Abs. residual | Relative residual | Worst patch (err) | Sanity fails |",
                "|---|---|---|---|---|---|---|"]
        for i, r in enumerate(rows, 1):
            fails = [c for c, ok in r["san"].items() if not ok]
            ab = f"{r['abs']:.4f}" if isinstance(r["abs"], (int, float)) else "-"
            out.append(f"| {i} | {r['date']} | {r['device']} | {ab} | {r['rel']:.4f} | "
                       f"{r['worst']} ({r['worst_err']:.4f}) | {', '.join(fails) or 'none'} |")
        out += ["", "## relative_residual", "",
                f"min {rels.min():.4f}, median {np.median(rels):.4f}, "
                f"p90 {np.percentile(rels, 90):.4f}, max {rels.max():.4f}", "",
                "## Sanity failures", ""]
        for c in checks:
            out.append(f"- {c}: {sum(1 for r in rows if not r['san'][c])} of {len(rows)}")

    if len(rows) < MIN_SESSIONS:
        out += ["", "## Proposed limits", "",
                f"Only {len(rows)} session(s) stored (need at least {MIN_SESSIONS}). "
                "No X/Y proposed."]
        print("\n".join(out))
        print(f"sessions={len(rows)} too few for X/Y", file=sys.stderr)
        return

    x = float(np.percentile(rels, 90))
    y = float(max(2 * x, 1.2 * rels.max()))
    out += ["", "## Proposed limits (not applied anywhere)", "",
            f"- X (good limit) = 90th percentile of relative_residual = {x:.4f}",
            f"- Y (fail limit) = max(2 * X, 1.2 * max relative_residual) = {y:.4f}",
            "- Y is above every stored session, so no session already saved would be refused."]
    print("\n".join(out))
    print(f"sessions={len(rows)} rel min={rels.min():.4f} med={np.median(rels):.4f} "
          f"p90={x:.4f} max={rels.max():.4f} X={x:.4f} Y={y:.4f} "
          f"sanity_fails={ {c: sum(1 for r in rows if not r['san'][c]) for c in checks} }",
          file=sys.stderr)


if __name__ == "__main__":
    main()
