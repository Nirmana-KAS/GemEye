"""Phase 2 parity test: does the server reproduce the v3 Colab test-set results?

Runs INSIDE the container (stdlib only):
    docker compose exec api python tests/parity/run_parity.py

Posts each of the 112 raw test images to /grade with debug=true and no patches
(training_session mode, referral_threshold 0.60), then compares with
final_per_image_predictions.csv. Writes parity_report.md and parity_mismatches.csv
next to this file.
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
CLEAN_JSON = os.path.join(HERE, "clean_summary.json")

EXPECTED_CLEAN_ACC = 86.73
EXPECTED_ALL_ACC = 85.71


def post(path):
    with open(path, "rb") as f:
        img = f.read()
    b = uuid.uuid4().hex
    ctype = "image/png" if path.lower().endswith(".png") else "image/jpeg"
    parts = [
        f"--{b}\r\nContent-Disposition: form-data; name=\"image\"; "
        f"filename=\"{os.path.basename(path)}\"\r\nContent-Type: {ctype}\r\n\r\n".encode() + img + b"\r\n",
        f"--{b}\r\nContent-Disposition: form-data; name=\"debug\"\r\n\r\ntrue\r\n".encode(),
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
    if not os.path.exists(CLEAN_JSON):
        return None
    with open(CLEAN_JSON) as f:
        d = json.load(f)
    return set(d.get("test_exact_leak", [])) | set(d.get("test_near_leak", []))


def acc(rows, key="srv_final"):
    return 100.0 * sum(r["true"] == r[key] for r in rows) / len(rows)


def main():
    with open(CSV_IN, newline="") as f:
        rows_in = list(csv.DictReader(f))
    if len(rows_in) != 112:
        sys.exit(f"Expected 112 rows in CSV, found {len(rows_in)}")

    missing = [r["image"] for r in rows_in if find_image(r["image"], r["true_grade"]) is None]
    if missing:
        sys.exit(f"FAIL: {len(missing)} of 112 images not found under {DATA}: {missing}")

    rows, lat = [], []
    for i, r in enumerate(rows_in, 1):
        body, ms = post(find_image(r["image"], r["true_grade"]))
        if body.get("status") != "ok" or "debug" not in body:
            sys.exit(f"Bad response for {r['image']} (is ENV=development?): {body.get('detail')}")
        d = body["debug"]
        lat.append(ms)
        rows.append({
            "image": r["image"], "true": int(r["true_grade"]),
            "colab_final": int(r["final_pred"]), "srv_final": body["grade"],
            "colab_conf": float(r["final_confidence"]), "srv_conf": body["confidence"],
            "colab_unc": float(r["mc_uncertainty_grade_units"]), "srv_unc": body["uncertainty"],
            "colab_rf": int(r["rf_pred"]), "srv_rf": d["rf_grade"],
            "colab_cnn": int(r["cnn_pred"]), "srv_cnn": d["cnn_mc_grade"],
            "srv_cnn_det": d["cnn_deterministic_grade"],
            "seg_fallback": d["model_segmentation_fallback"],
        })
        print(f"[{i:3d}/112] {r['image']:<14} true={r['true_grade']} colab={r['final_pred']} "
              f"srv={body['grade']} ({ms:.0f} ms)", flush=True)

    n = len(rows)
    leaks = load_leaks()
    clean = [r for r in rows if r["image"] not in leaks] if leaks is not None else None

    y = [r["true"] for r in rows]
    p = [r["srv_final"] for r in rows]
    agree = {k: sum(r[f"srv_{k}"] == r[f"colab_{k}"] for r in rows) for k in ("final", "rf", "cnn")}
    within1 = 100.0 * sum(abs(a - b) <= 1 for a, b in zip(y, p)) / n
    mae_conf = sum(abs(r["srv_conf"] - r["colab_conf"]) for r in rows) / n
    corr_unc = pearson([r["srv_unc"] for r in rows], [r["colab_unc"] for r in rows])
    colab_acc_all = acc(rows, "colab_final")

    def verdict(ok):
        return "PASS" if ok else "FAIL"

    crit = []
    if clean is not None:
        ca = acc(clean)
        crit.append((f"Clean-{len(clean)} accuracy within +/-2.0 of {EXPECTED_CLEAN_ACC}%",
                     f"{ca:.2f}%", verdict(abs(ca - EXPECTED_CLEAN_ACC) <= 2.0)))
    else:
        crit.append((f"Clean-98 accuracy within +/-2.0 of {EXPECTED_CLEAN_ACC}%",
                     "clean_summary.json missing", "BLOCKED"))
    crit.append(("Final-grade agreement with Colab >= 95% (>= 107/112)",
                 f"{agree['final']}/{n}", verdict(agree["final"] >= 107)))
    crit.append(("RF agreement >= 95%", f"{agree['rf']}/{n}", verdict(agree["rf"] >= 107)))
    crit.append(("CNN-MC agreement >= 95%", f"{agree['cnn']}/{n}", verdict(agree["cnn"] >= 107)))

    mism = [r for r in rows if r["srv_final"] != r["colab_final"]
            or r["srv_rf"] != r["colab_rf"] or r["srv_cnn"] != r["colab_cnn"]]

    out = ["# GemEye v3 parity report", "",
           f"Server: `{URL}`, training_session mode, referral_threshold 0.60, debug=true. "
           f"Images: {n}.", "", "## Pass criteria", "", "| Criterion | Value | Result |", "|---|---|---|"]
    out += [f"| {c} | {v} | **{res}** |" for c, v, res in crit]
    out += ["", "## Metrics", "", "| Metric | Server | Colab |", "|---|---|---|"]
    if clean is not None:
        out.append(f"| Accuracy, clean {len(clean)} | {acc(clean):.2f}% | {acc(clean, 'colab_final'):.2f}% "
                   f"(expected {EXPECTED_CLEAN_ACC}%) |")
    out += [
        f"| Accuracy, all {n} | {acc(rows):.2f}% | {colab_acc_all:.2f}% (expected {EXPECTED_ALL_ACC}%) |",
        f"| Macro-F1, all {n} | {macro_f1(y, p):.4f} | {macro_f1(y, [r['colab_final'] for r in rows]):.4f} |",
        f"| Within +/-1 grade, all {n} | {within1:.2f}% | "
        f"{100.0 * sum(abs(r['true'] - r['colab_final']) <= 1 for r in rows) / n:.2f}% |",
        f"| RF accuracy | {acc(rows, 'srv_rf'):.2f}% | {acc(rows, 'colab_rf'):.2f}% |",
        f"| CNN-MC accuracy | {acc(rows, 'srv_cnn'):.2f}% | {acc(rows, 'colab_cnn'):.2f}% |",
        f"| CNN deterministic accuracy | {acc(rows, 'srv_cnn_det'):.2f}% | - |",
        "", "| Agreement / error | Value |", "|---|---|",
        f"| Final-grade agreement | {agree['final']}/{n} ({100.0 * agree['final'] / n:.2f}%) |",
        f"| RF agreement | {agree['rf']}/{n} ({100.0 * agree['rf'] / n:.2f}%) |",
        f"| CNN-MC agreement | {agree['cnn']}/{n} ({100.0 * agree['cnn'] / n:.2f}%) |",
        f"| Mean abs(confidence - Colab confidence) | {mae_conf:.4f} |",
        f"| Pearson r, uncertainty vs Colab MC uncertainty | {corr_unc:.4f} |",
        f"| Model-path GrabCut fallbacks | {sum(r['seg_fallback'] for r in rows)}/{n} |",
        f"| Latency avg / max (client side, ms) | {sum(lat) / n:.0f} / {max(lat):.0f} |",
        "", f"## Disagreeing images ({len(mism)})", "",
        "| Image | True | Final srv/colab | RF srv/colab | CNN-MC srv/colab | Conf srv/colab | Seg fallback |",
        "|---|---|---|---|---|---|---|",
    ]
    out += [f"| {r['image']} | {r['true']} | {r['srv_final']}/{r['colab_final']} | {r['srv_rf']}/{r['colab_rf']} | "
            f"{r['srv_cnn']}/{r['colab_cnn']} | {r['srv_conf']:.4f}/{r['colab_conf']:.4f} | {r['seg_fallback']} |"
            for r in mism]
    with open(os.path.join(HERE, "parity_report.md"), "w") as f:
        f.write("\n".join(out) + "\n")

    with open(os.path.join(HERE, "parity_mismatches.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(mism)

    for c, v, res in crit:
        print(f"{res:<7} {c}: {v}")


if __name__ == "__main__":
    main()
