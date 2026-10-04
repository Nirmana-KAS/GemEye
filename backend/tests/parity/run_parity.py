"""Phase 2 parity test: does the server reproduce the v3 Colab test-set results?

Runs INSIDE the container (stdlib only):
    docker compose exec api python tests/parity/run_parity.py

Posts each of the 112 raw test images to /grade with debug=true and no patches
(training_session mode, referral_threshold 0.60), then compares with
parity_reference.csv (deterministic Colab reference: RF with GrabCut seeded 42 per
image, deterministic CNN) and, for information, with final_per_image_predictions.csv
(unseeded Colab run). Writes parity_report.md and parity_mismatches.csv next to
this file.
"""
import csv
import glob
import json
import math
import os
import sys
import time
import urllib.request
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
URL = os.environ.get("PARITY_URL", "http://localhost:8000/grade")
DATA = os.environ.get("PARITY_DATA", "/data/merged")
CSV_IN = os.path.join(HERE, "final_per_image_predictions.csv")
REF_IN = os.path.join(HERE, "parity_reference.csv")
CLEAN_JSON = os.path.join(HERE, "clean_summary.json")

EXPECTED_CLEAN_ACC = 86.73
EXPECTED_ALL_ACC = 85.71
REFERRAL = 0.60
RF_TOL = 1e-6
CNN_TOL = 0.01


def post(path):
    with open(path, "rb") as f:
        img = f.read()
    b = uuid.uuid4().hex
    ctype = "image/png" if path.lower().endswith(".png") else "image/jpeg"
    parts = [
        f"--{b}\r\nContent-Disposition: form-data; name=\"image\"; "
        f"filename=\"{os.path.basename(path)}\"\r\nContent-Type: {ctype}\r\n\r\n".encode() + img + b"\r\n",
        f"--{b}\r\nContent-Disposition: form-data; name=\"debug\"\r\n\r\ntrue\r\n".encode(),
        # Development only: grade every image even if a quality gate fails, so the
        # model path is compared on all 112 images (Phase 3).
        f"--{b}\r\nContent-Disposition: form-data; name=\"gates\"\r\n\r\nfalse\r\n".encode(),
        f"--{b}\r\nContent-Disposition: form-data; name=\"referral_threshold\"\r\n\r\n0.60\r\n".encode(),
        f"--{b}--\r\n".encode(),
    ]
    req = urllib.request.Request(URL, data=b"".join(parts), method="POST",
                                 headers={"Content-Type": f"multipart/form-data; boundary={b}"})
    t = time.perf_counter()
    with urllib.request.urlopen(req, timeout=120) as r:
        body = json.loads(r.read())
    return body, (time.perf_counter() - t) * 1000.0


def find_image(name, grade):
    hits = glob.glob(os.path.join(DATA, f"grade_{grade}_*", name))
    return hits[0] if len(hits) == 1 else None


def macro_f1(y, p):
    f1s = []
    for c in range(1, 8):
        tp = sum(1 for a, b in zip(y, p) if a == c and b == c)
        fp = sum(1 for a, b in zip(y, p) if a != c and b == c)
        fn = sum(1 for a, b in zip(y, p) if a == c and b != c)
        if tp + fp + fn == 0:
            continue
        f1s.append(2 * tp / (2 * tp + fp + fn))
    return sum(f1s) / len(f1s)


def pearson(x, y):
    n = len(x)
    mx, my = sum(x) / n, sum(y) / n
    sxy = sum((a - mx) * (b - my) for a, b in zip(x, y))
    sx = math.sqrt(sum((a - mx) ** 2 for a in x))
    sy = math.sqrt(sum((b - my) ** 2 for b in y))
    return sxy / (sx * sy) if sx and sy else float("nan")


def load_leaks():
    with open(CLEAN_JSON) as f:
        d = json.load(f)
    leaks = set(d.get("test_exact_leak", [])) | set(d.get("test_near_leak", []))
    if d.get("clean_test_n") != 98 or len(leaks) != 14:
        sys.exit(f"FAIL: clean_summary.json has clean_test_n={d.get('clean_test_n')} and "
                 f"{len(leaks)} leak names (expected 98 and 14)")
    return leaks


def load_reference():
    with open(REF_IN, newline="") as f:
        ref = {r["image"]: r for r in csv.DictReader(f)}
    if len(ref) != 112:
        sys.exit(f"Expected 112 rows in parity_reference.csv, found {len(ref)}")
    return ref


def max_abs(a, b):
    return max(abs(x - y) for x, y in zip(a, b))


def acc(rows, key="srv_final"):
    return 100.0 * sum(r["true"] == r[key] for r in rows) / len(rows)


def verdict(ok):
    return "PASS" if ok else "FAIL"


def main():
    with open(CSV_IN, newline="") as f:
        rows_in = list(csv.DictReader(f))
    if len(rows_in) != 112:
        sys.exit(f"Expected 112 rows in CSV, found {len(rows_in)}")
    leaks = load_leaks()
    ref = load_reference()
    if set(ref) != {r["image"] for r in rows_in}:
        sys.exit("FAIL: parity_reference.csv images differ from final_per_image_predictions.csv")

    missing = [r["image"] for r in rows_in if find_image(r["image"], r["true_grade"]) is None]
    if missing:
        sys.exit(f"FAIL: {len(missing)} of 112 images not found under {DATA}: {missing}")

    rows, lat = [], []
    for i, r in enumerate(rows_in, 1):
        body, ms = post(find_image(r["image"], r["true_grade"]))
        if body.get("status") != "ok" or "debug" not in body:
            sys.exit(f"Bad response for {r['image']} (is ENV=development?): {body.get('detail')}")
        d = body["debug"]
        rr = ref[r["image"]]
        lat.append(ms)
        rows.append({
            "image": r["image"], "true": int(r["true_grade"]),
            "colab_final": int(r["final_pred"]), "srv_final": body["grade"],
            "colab_conf": float(r["final_confidence"]), "srv_conf": body["confidence"],
            "colab_unc": float(r["mc_uncertainty_grade_units"]), "srv_unc": body["uncertainty"],
            "colab_rf": int(r["rf_pred"]), "srv_rf": d["rf_grade"], "ref_rf": int(rr["rf_grade"]),
            "colab_cnn": int(r["cnn_pred"]), "srv_cnn": d["cnn_mc_grade"],
            "srv_cnn_det": d["cnn_deterministic_grade"], "ref_cnn_det": int(rr["cnn_det_grade"]),
            "rf_dp": max_abs(d["rf_probabilities"], [float(rr[f"rf_p{k}"]) for k in range(1, 8)]),
            "cnn_det_dp": max_abs(d["cnn_deterministic_probabilities"],
                                  [float(rr[f"cnn_det_p{k}"]) for k in range(1, 8)]),
            "both_below_referral": "",
            "seg_fallback": d["model_segmentation_fallback"],
        })
        print(f"[{i:3d}/112] {r['image']:<14} true={r['true_grade']} colab={r['final_pred']} "
              f"srv={body['grade']} rf_dp={rows[-1]['rf_dp']:.1e} det_dp={rows[-1]['cnn_det_dp']:.1e} "
              f"({ms:.0f} ms)", flush=True)

    n = len(rows)
    clean = [r for r in rows if r["image"] not in leaks]
    if len(clean) != 98:
        sys.exit(f"FAIL: clean set has {len(clean)} images, expected 98")

    y = [r["true"] for r in rows]
    p = [r["srv_final"] for r in rows]
    agree = {k: sum(r[f"srv_{k}"] == r[f"colab_{k}"] for r in rows) for k in ("final", "rf", "cnn")}
    within1 = 100.0 * sum(abs(a - b) <= 1 for a, b in zip(y, p)) / n
    mae_conf = sum(abs(r["srv_conf"] - r["colab_conf"]) for r in rows) / n
    corr_unc = pearson([r["srv_unc"] for r in rows], [r["colab_unc"] for r in rows])

    rf_agree = sum(r["srv_rf"] == r["ref_rf"] for r in rows)
    det_agree = sum(r["srv_cnn_det"] == r["ref_cnn_det"] for r in rows)
    rf_dp = max(r["rf_dp"] for r in rows)
    det_dp = max(r["cnn_det_dp"] for r in rows)
    final_dis = [r for r in rows if r["srv_final"] != r["colab_final"]]
    for r in final_dis:
        r["both_below_referral"] = r["srv_conf"] < REFERRAL and r["colab_conf"] < REFERRAL
    ca = acc(clean)

    crit = [
        ("A. RF exactness: grade agreement 112/112 AND max abs dp <= 1e-6",
         f"{rf_agree}/{n}, max abs dp {rf_dp:.2e}", verdict(rf_agree == n and rf_dp <= RF_TOL)),
        ("B. CNN deterministic: max abs dp <= 0.01 AND grade agreement >= 111/112",
         f"{det_agree}/{n}, max abs dp {det_dp:.2e}", verdict(det_dp <= CNN_TOL and det_agree >= 111)),
        (f"C. Clean-98 accuracy within +/-2.0 of {EXPECTED_CLEAN_ACC}%",
         f"{ca:.2f}%", verdict(abs(ca - EXPECTED_CLEAN_ACC) <= 2.0)),
        (f"D. Every final-grade disagreement vs unseeded Colab has confidence < {REFERRAL:.2f} on both sides",
         f"{sum(bool(r['both_below_referral']) for r in final_dis)}/{len(final_dis)}",
         verdict(all(r["both_below_referral"] for r in final_dis))),
    ]
    info = [
        ("Final-grade agreement with Colab >= 95% (>= 107/112)",
         f"{agree['final']}/{n}", verdict(agree["final"] >= 107)),
        ("RF agreement >= 95%", f"{agree['rf']}/{n}", verdict(agree["rf"] >= 107)),
        ("CNN-MC agreement >= 95%", f"{agree['cnn']}/{n}", verdict(agree["cnn"] >= 107)),
    ]

    mism = [r for r in rows if r["srv_final"] != r["colab_final"]
            or r["srv_rf"] != r["colab_rf"] or r["srv_cnn"] != r["colab_cnn"]
            or r["srv_rf"] != r["ref_rf"] or r["srv_cnn_det"] != r["ref_cnn_det"]]
    worst_rf = sorted(rows, key=lambda r: -r["rf_dp"])[:5]
    worst_det = sorted(rows, key=lambda r: -r["cnn_det_dp"])[:5]

    out = ["# GemEye v3 parity report", "",
           f"Server: `{URL}`, training_session mode, referral_threshold 0.60, debug=true. "
           f"Images: {n}. Reference: parity_reference.csv (RF with GrabCut seeded 42 per image, "
           "deterministic CNN).", "", "## Pass criteria", "",
           "| Criterion | Value | Result |", "|---|---|---|"]
    out += [f"| {c} | {v} | **{res}** |" for c, v, res in crit]
    out += ["", "Informational: vs unseeded Colab run (final_per_image_predictions.csv; GrabCut "
            "not seeded, different MC Dropout samples). These were the old pass criteria.", "",
            "| Criterion | Value | Result |", "|---|---|---|"]
    out += [f"| {c} | {v} | {res} |" for c, v, res in info]
    exact = crit[0][2] == "PASS" and crit[1][2] == "PASS"
    out += ["", "## Findings", "",
            "- v3 training used cv2 decoding for the RF features and tf.io.decode_jpeg (default "
            "settings) for the CNN input. The server now does the same: "
            + (f"it reproduces both {'exactly' if exact else 'NOT exactly'} (RF max abs dp {rf_dp:.2e}, "
               f"CNN deterministic max abs dp {det_dp:.2e}, grade agreement {rf_agree}/{n} and {det_agree}/{n})."),
            "- Remaining differences vs the original Colab evaluation (final_per_image_predictions.csv) "
            "come only from its unseeded GrabCut and unseeded MC Dropout"
            + (f"; all {len(final_dis)} final-grade disagreements are below the 0.60 referral threshold "
               "on both sides." if all(r["both_below_referral"] for r in final_dis) else "."),
            f"- Average /grade latency (client side): {sum(lat) / n:.0f} ms (max {max(lat):.0f} ms)."]
    out += [
        "", "## Deterministic reference", "",
        "| Metric | Value |", "|---|---|",
        f"| RF grade agreement | {rf_agree}/{n} |",
        f"| RF max abs probability difference | {rf_dp:.3e} |",
        f"| CNN deterministic grade agreement | {det_agree}/{n} |",
        f"| CNN deterministic max abs probability difference | {det_dp:.3e} |",
        f"| CNN deterministic mean per-image max abs difference | "
        f"{sum(r['cnn_det_dp'] for r in rows) / n:.3e} |",
        "", "Worst RF: " + ", ".join(f"{r['image']} ({r['rf_dp']:.2e})" for r in worst_rf),
        "", "Worst CNN deterministic: " + ", ".join(f"{r['image']} ({r['cnn_det_dp']:.2e})" for r in worst_det),
        "", f"## Final-grade disagreements vs unseeded Colab ({len(final_dis)})", "",
        "| Image | True | Final srv/colab | Conf srv | Conf colab | Both < 0.60 |", "|---|---|---|---|---|---|",
    ]
    out += [f"| {r['image']} | {r['true']} | {r['srv_final']}/{r['colab_final']} | {r['srv_conf']:.4f} | "
            f"{r['colab_conf']:.4f} | {r['both_below_referral']} |" for r in final_dis]
    out += ["", "## Metrics", "", "| Metric | Server | Colab |", "|---|---|---|",
            f"| Accuracy, clean {len(clean)} | {acc(clean):.2f}% | {acc(clean, 'colab_final'):.2f}% "
            f"(expected {EXPECTED_CLEAN_ACC}%) |",
            f"| Accuracy, all {n} | {acc(rows):.2f}% | {acc(rows, 'colab_final'):.2f}% "
            f"(expected {EXPECTED_ALL_ACC}%) |",
            f"| Macro-F1, all {n} | {macro_f1(y, p):.4f} | {macro_f1(y, [r['colab_final'] for r in rows]):.4f} |",
            f"| Within +/-1 grade, all {n} | {within1:.2f}% | "
            f"{100.0 * sum(abs(r['true'] - r['colab_final']) <= 1 for r in rows) / n:.2f}% |",
            f"| RF accuracy | {acc(rows, 'srv_rf'):.2f}% | {acc(rows, 'colab_rf'):.2f}% "
            f"(reference {acc(rows, 'ref_rf'):.2f}%) |",
            f"| CNN-MC accuracy | {acc(rows, 'srv_cnn'):.2f}% | {acc(rows, 'colab_cnn'):.2f}% |",
            f"| CNN deterministic accuracy | {acc(rows, 'srv_cnn_det'):.2f}% | "
            f"{acc(rows, 'ref_cnn_det'):.2f}% (reference) |",
            "", "| Agreement / error | Value |", "|---|---|",
            f"| Final-grade agreement | {agree['final']}/{n} ({100.0 * agree['final'] / n:.2f}%) |",
            f"| RF agreement (unseeded Colab) | {agree['rf']}/{n} ({100.0 * agree['rf'] / n:.2f}%) |",
            f"| CNN-MC agreement | {agree['cnn']}/{n} ({100.0 * agree['cnn'] / n:.2f}%) |",
            f"| Mean abs(confidence - Colab confidence) | {mae_conf:.4f} |",
            f"| Pearson r, uncertainty vs Colab MC uncertainty | {corr_unc:.4f} |",
            f"| Model-path GrabCut fallbacks | {sum(r['seg_fallback'] for r in rows)}/{n} |",
            f"| Latency avg / max (client side, ms) | {sum(lat) / n:.0f} / {max(lat):.0f} |",
            "", f"## Disagreeing images ({len(mism)}, any grade differs)", "",
            "| Image | True | Final srv/colab | RF srv/colab/ref | CNN-MC srv/colab | CNN-det srv/ref "
            "| RF max dp | CNN-det max dp | Conf srv/colab | Both < 0.60 | Seg fallback |",
            "|---|---|---|---|---|---|---|---|---|---|---|"]
    out += [f"| {r['image']} | {r['true']} | {r['srv_final']}/{r['colab_final']} | "
            f"{r['srv_rf']}/{r['colab_rf']}/{r['ref_rf']} | {r['srv_cnn']}/{r['colab_cnn']} | "
            f"{r['srv_cnn_det']}/{r['ref_cnn_det']} | {r['rf_dp']:.2e} | {r['cnn_det_dp']:.2e} | "
            f"{r['srv_conf']:.4f}/{r['colab_conf']:.4f} | {r['both_below_referral']} | {r['seg_fallback']} |"
            for r in mism]
    with open(os.path.join(HERE, "parity_report.md"), "w") as f:
        f.write("\n".join(out) + "\n")

    with open(os.path.join(HERE, "parity_mismatches.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(mism)

    for r in final_dis:
        print(f"final disagreement {r['image']}: srv {r['srv_final']} conf {r['srv_conf']:.4f}, "
              f"colab {r['colab_final']} conf {r['colab_conf']:.4f}, both < {REFERRAL:.2f}: "
              f"{r['both_below_referral']}")
    for c, v, res in crit:
        print(f"{res:<7} {c}: {v}")
    for c, v, res in info:
        print(f"info    {c}: {v} ({res}, vs unseeded Colab run)")


if __name__ == "__main__":
    main()
