"""Phase 8: Grad-CAM statistics over the 112 test images.

Runs INSIDE the container against the running development server:
    docker compose exec api python tests/parity/run_gradcam_stats.py

Grades each image (as run_parity.py: gates off, no patches), then calls
POST /gradings/{id}/heatmap twice: the first call computes the heatmap (latency
reported), the second must be a cache hit with the same values.

Per image it records stone_area_fraction (share of the 256 px image inside the
GrabCut stone mask, seed 42: diagnostics.gate_stone_area, the same mask the
heat fraction uses), stone_mask_heat_fraction, and heat_over_area = heat
fraction / area fraction (1.0 = no more heat on the stone than a uniform map).
Writes gradcam_stats_report.md next to this file. The temporary user, its
gradings and S3 objects are deleted at the end.
"""
import csv
import json
import os
import statistics
import sys
import time
import urllib.request

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
import tests.parity.run_parity as parity  # noqa: E402
from tests.helpers.firebase_test_user import FirebaseTestUser, purge_user_data  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = parity.URL.rsplit("/grade", 1)[0]


def post_heatmap(grading_id):
    req = urllib.request.Request(f"{BASE}/gradings/{grading_id}/heatmap", data=b"", method="POST",
                                 headers=parity.USER.headers)
    t = time.perf_counter()
    with urllib.request.urlopen(req, timeout=120) as r:
        body = json.loads(r.read())
    return body, (time.perf_counter() - t) * 1000.0


def main():
    with open(parity.CSV_IN, newline="") as f:
        rows_in = list(csv.DictReader(f))
    rows = []
    for i, r in enumerate(rows_in, 1):
        path = parity.find_image(r["image"], r["true_grade"])
        if path is None:
            sys.exit(f"FAIL: {r['image']} not found under {parity.DATA}")
        g, _ = parity.post(path)
        if g.get("status") != "ok":
            sys.exit(f"Bad response for {r['image']}: {g.get('detail')}")
        h, ms = post_heatmap(g["grading_id"])
        h2, ms2 = post_heatmap(g["grading_id"])
        if h["target_grade"] != g["grade"] or h2["stone_mask_heat_fraction"] != h["stone_mask_heat_fraction"]:
            sys.exit(f"FAIL: {r['image']} target or cached value mismatch")
        area = g["diagnostics"].get("gate_stone_area")
        if not area:
            sys.exit(f"FAIL: {r['image']} has no stone area")
        frac = h["stone_mask_heat_fraction"]
        rows.append({"image": r["image"], "true": int(r["true_grade"]), "grade": g["grade"],
                     "area": area, "fraction": frac, "ratio": frac / area,
                     "ms": ms, "cached_ms": ms2})
        print(f"[{i:3d}/{len(rows_in)}] {r['image']:<14} grade={g['grade']} area={area:.3f} "
              f"heat={frac:.3f} ratio={frac / area:.2f} {ms:.0f} ms (cached {ms2:.0f} ms)",
              flush=True)
    write_report(rows)


def summary(rows):
    a = [r["area"] for r in rows]
    f = [r["fraction"] for r in rows]
    q = [r["ratio"] for r in rows]
    above = sum(x > 1.0 for x in q)
    return (f"{len(rows)} | {statistics.mean(a):.3f} | {statistics.median(a):.3f} | "
            f"{statistics.mean(f):.3f} | {statistics.median(f):.3f} | "
            f"{statistics.mean(q):.2f} | {statistics.median(q):.2f} | "
            f"{above}/{len(rows)} ({100.0 * above / len(rows):.1f}%)")


HEADER = ["| Group | n | Area mean | Area median | Heat mean | Heat median | "
          "Heat/area mean | Heat/area median | Heat/area > 1 |",
          "|---|---|---|---|---|---|---|---|---|"]


def write_report(rows):
    ms = [r["ms"] for r in rows]
    cached = [r["cached_ms"] for r in rows]
    out = ["# Grad-CAM statistics (Phase 8.1)", "",
           f"{len(rows)} test images, training_session mode, gates off, target = final grade. "
           "Area = stone_area_fraction (share of the 256 px image inside the GrabCut stone "
           "mask, seed 42). Heat = stone_mask_heat_fraction (share of the total Grad-CAM heat "
           "inside that mask). Heat/area = heat / area; 1.0 is what a uniform map would give.",
           "", "## All images", "", *HEADER, f"| All | {summary(rows)} |",
           "", "## Per true grade", "", *HEADER]
    out += [f"| Grade {k} | {summary([r for r in rows if r['true'] == k])} |"
            for k in range(1, 8) if any(r["true"] == k for r in rows)]
    out += ["", "## Per predicted grade (the Grad-CAM target)", "", *HEADER]
    out += [f"| Grade {k} | {summary([r for r in rows if r['grade'] == k])} |"
            for k in range(1, 8) if any(r["grade"] == k for r in rows)]
    out += ["", "## Latency (client side)", "", "| Metric | Value |", "|---|---|",
            f"| Heatmap, first call avg / max (ms) | {statistics.mean(ms):.0f} / {max(ms):.0f} |",
            f"| Heatmap, cache hit avg (ms) | {statistics.mean(cached):.0f} |",
            "", "## Interpretation", "",
            "Grad-CAM shows where the CNN branch looked, not the Random Forest or the ensemble. "
            "It is computed on the 7x7 top_activation grid and upsampled, so it is coarse and "
            "cannot resolve facets or small inclusions. It is correlational: high heat marks "
            "regions whose activations raise the target class score, not proof that the colour "
            "of those pixels caused the grade. Heat/area above 1 means the CNN weights the stone "
            "more than a uniform map would; heat outside the mask means it also uses the tray "
            "and edges. Reliance on the background would be a limitation of the CNN branch (it "
            "could react to tray, lighting or framing). These numbers describe where the heat "
            "falls on this test set only; they do not show whether that heat is used correctly."]
    with open(os.path.join(HERE, "gradcam_stats_report.md"), "w") as f:
        f.write("\n".join(out) + "\n")
    q = [r["ratio"] for r in rows]
    print(f"area mean/median {statistics.mean([r['area'] for r in rows]):.3f}/"
          f"{statistics.median([r['area'] for r in rows]):.3f}; heat mean/median "
          f"{statistics.mean([r['fraction'] for r in rows]):.3f}/"
          f"{statistics.median([r['fraction'] for r in rows]):.3f}; heat/area mean/median "
          f"{statistics.mean(q):.2f}/{statistics.median(q):.2f}; > 1: "
          f"{sum(x > 1 for x in q)}/{len(q)}; avg latency {statistics.mean(ms):.0f} ms")


if __name__ == "__main__":
    with FirebaseTestUser() as user:
        parity.USER = user
        try:
            main()
        finally:
            print(f"cleanup: {purge_user_data(user.uid)}")
