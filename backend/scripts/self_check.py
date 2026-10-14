"""Connectivity and project self-check. Never prints secret values.

Checks 1-6 run inside the container with ENV=test:
    docker compose exec -T -e ENV=test api python scripts/self_check.py --only 1,2,3,4,5,6 --json > a.json
Checks 7-8 run on the host (need git and docker):
    python backend/scripts/self_check.py --only 7,8 --json > b.json
Render the report:
    python backend/scripts/self_check.py --render a.json b.json > docs/connectivity_check.md
Each check records (check, status, detail); status is PASS, FAIL or SKIP."""
import argparse
import io
import json
import os
import re
import subprocess
import sys
from pathlib import Path
import time
import urllib.request

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

RESULTS = []


def rec(check, status, detail):
    RESULTS.append({"check": check, "status": status, "detail": detail})


def guarded(check, fn):
    try:
        fn()
    except Exception as e:      # a failing check must not stop the others
        rec(check, "FAIL", f"unexpected {type(e).__name__}")


def secret(v):
    return v.get_secret_value() if v else None


def host_of(uri):
    """Host part of a MongoDB URI without user or password."""
    m = re.match(r"^mongodb(?:\+srv)?://(?:[^@/]*@)?([^/?]+)", uri or "")
    return m.group(1) if m else "unknown"


# ------------------------------------------------------------------ 1. settings

def check_settings():
    from app.config import get_settings
    s = get_settings()
    st = s.status()
    missing = [k for k, v in st.items() if v == "missing"]
    rec("1 Settings", "FAIL" if missing else "PASS",
        f"env={s.env}; set: {', '.join(k for k, v in st.items() if v == 'set')}"
        + (f"; MISSING: {', '.join(missing)}" if missing else ""))


# ------------------------------------------------------------------ 2. MongoDB

def check_mongo():
    from pymongo import MongoClient
    from app.config import ENVIRONMENTS, get_settings
    s = get_settings()
    if not s.mongodb_uri:
        return rec("2 MongoDB", "FAIL", "MONGODB_URI missing")
    uri = secret(s.mongodb_uri)
    c = MongoClient(uri, serverSelectionTimeoutMS=10000, tz_aware=True)
    try:
        c.admin.command("ping")
    except Exception as e:
        hint = ("; if TCP 27017 is reachable, the Atlas IP access list probably lacks this "
                "machine's public IP" if type(e).__name__ == "ServerSelectionTimeoutError" else "")
        return rec("2 MongoDB ping", "FAIL", f"{type(e).__name__} (host {host_of(uri)}){hint}")
    rec("2 MongoDB ping", "PASS", f"cluster host {host_of(uri)}")
    try:
        names = set(c.list_database_names())
        rec("2 MongoDB databases", "PASS",
            ", ".join(f"{d}={'exists' if d in names else 'absent'}"
                      for d in (v[0] for v in ENVIRONMENTS.values())))
    except Exception as e:
        rec("2 MongoDB databases", "SKIP", f"listDatabases not permitted ({type(e).__name__})")
    db = c[s.db_name]
    rows = []
    ttl = None
    for coll in sorted(db.list_collection_names()):
        idx = db[coll].index_information()
        rows.append(f"{coll}: {db[coll].estimated_document_count()} docs; indexes {', '.join(sorted(idx))}")
        if coll == "deleted_accounts":
            ttl = [n for n, i in idx.items() if "expireAfterSeconds" in i]
    rec(f"2 MongoDB collections ({s.db_name})", "PASS" if rows else "SKIP",
        " | ".join(rows) if rows else "database has no collections yet (created at API startup)")
    if ttl is None:
        rec("2 MongoDB TTL index", "SKIP", "deleted_accounts collection absent in this DB")
    else:
        rec("2 MongoDB TTL index", "PASS" if ttl else "FAIL",
            f"deleted_accounts TTL index: {', '.join(ttl) or 'none'}")
    c.close()


# ------------------------------------------------------------------ 3. S3

def check_s3():
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
    from app.config import get_settings
    s = get_settings()
    if not (s.s3_bucket and s.aws_region):
        return rec("3 S3", "FAIL", "S3_BUCKET or AWS_REGION missing")
    cl = boto3.client("s3", region_name=s.aws_region, aws_access_key_id=secret(s.aws_access_key_id),
                      aws_secret_access_key=secret(s.aws_secret_access_key),
                      endpoint_url=f"https://s3.{s.aws_region}.amazonaws.com",
                      config=Config(signature_version="s3v4", s3={"addressing_style": "virtual"}))
    b = s.s3_bucket

    def call(label, fn, ok_codes=()):
        try:
            return fn()
        except ClientError as e:
            code = e.response.get("Error", {}).get("Code", "")
            if code in ok_codes:
                return code
            if code in ("AccessDenied", "403", "AllAccessDisabled"):
                rec(label, "SKIP", f"AccessDenied: missing permission for {label}")
            else:
                rec(label, "FAIL", f"error code {code}")
            return None

    r = call("s3:HeadBucket", lambda: cl.head_bucket(Bucket=b))
    if r is not None:
        region = r["ResponseMetadata"]["HTTPHeaders"].get("x-amz-bucket-region")
        rec("3 S3 bucket", "PASS" if region == "ap-south-1" else "FAIL", f"exists, region {region}")
    pab = call("s3:GetBucketPublicAccessBlock", lambda: cl.get_public_access_block(Bucket=b))
    if pab:
        cfg = pab["PublicAccessBlockConfiguration"]
        rec("3 S3 public access block", "PASS" if all(cfg.values()) else "FAIL",
            ", ".join(f"{k}={v}" for k, v in cfg.items()))
    enc = call("s3:GetEncryptionConfiguration", lambda: cl.get_bucket_encryption(Bucket=b))
    if enc:
        rules = enc["ServerSideEncryptionConfiguration"]["Rules"]
        rec("3 S3 encryption", "PASS",
            ", ".join(r_["ApplyServerSideEncryptionByDefault"]["SSEAlgorithm"] for r_ in rules))
    ver = call("s3:GetBucketVersioning", lambda: cl.get_bucket_versioning(Bucket=b))
    if ver is not None:
        rec("3 S3 versioning", "PASS", ver.get("Status", "never enabled (off)") if isinstance(ver, dict) else str(ver))
    pol = call("s3:GetBucketPolicy", lambda: cl.get_bucket_policy(Bucket=b), ok_codes=("NoSuchBucketPolicy",))
    if pol is not None:
        rec("3 S3 bucket policy", "PASS", "no bucket policy" if pol == "NoSuchBucketPolicy" else "bucket policy present")

    # round trip under test/selfcheck/
    key = f"test/selfcheck/{int(time.time())}.txt"
    body = b"gemeye self check"
    try:
        cl.put_object(Bucket=b, Key=key, Body=body, ContentType="text/plain", ServerSideEncryption="AES256")
        got = cl.get_object(Bucket=b, Key=key)["Body"].read()
        url = cl.generate_presigned_url("get_object", Params={"Bucket": b, "Key": key}, ExpiresIn=60)
        with urllib.request.urlopen(url, timeout=20) as resp:
            via_url = resp.read()
        cl.delete_object(Bucket=b, Key=key)
        absent = False
        try:
            cl.head_object(Bucket=b, Key=key)
        except ClientError:
            absent = True
        ok = got == body and via_url == body and absent
        rec("3 S3 round trip", "PASS" if ok else "FAIL",
            f"put/get/presign(open)/delete under test/selfcheck/: match={got == body and via_url == body}, deleted={absent}")
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        rec("3 S3 round trip", "SKIP" if code in ("AccessDenied", "403") else "FAIL",
            f"error code {code} (needs s3:PutObject/GetObject/DeleteObject on test/*)")
        try:
            cl.delete_object(Bucket=b, Key=key)
        except Exception:
            pass
    # top-level prefixes and object counts
    try:
        counts = {}
        for page in cl.get_paginator("list_objects_v2").paginate(Bucket=b):
            for o in page.get("Contents", []):
                top = o["Key"].split("/", 1)[0] + "/" if "/" in o["Key"] else "(root)"
                counts[top] = counts.get(top, 0) + 1
        rec("3 S3 prefixes", "PASS", ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) or "bucket is empty")
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        rec("3 S3 prefixes", "SKIP", f"{code}: missing s3:ListBucket")


# ------------------------------------------------------------------ 4/5. Firebase + API

def blank_png():
    import cv2
    import numpy as np
    ok, buf = cv2.imencode(".png", np.full((400, 400, 3), 255, np.uint8))
    return buf.tobytes()


def check_firebase_api():
    from fastapi.testclient import TestClient
    from app.config import get_settings
    from app.main import app
    from tests.helpers.firebase_test_user import FirebaseTestUser, purge_user_data
    s = get_settings()
    if s.env != "test":
        return rec("4 Firebase", "SKIP", "refusing outside ENV=test")
    with TestClient(app) as c:
        # --- 5. API
        h = c.get("/health")
        d = h.json() if h.status_code == 200 else {}
        rec("5 API /health", "PASS" if d.get("status") == "ok" else "FAIL",
            f"HTTP {h.status_code}, status={d.get('status')}, models_loaded={d.get('models_loaded')}")
        cf = c.get("/config")
        cd = cf.json() if cf.status_code == 200 else {}
        maint = (cd.get("maintenance") or {}).get("enabled")
        rec("5 API /config", "PASS" if cf.status_code == 200 else "FAIL", f"HTTP {cf.status_code}")
        rec("5 Maintenance", "PASS" if maint is False else "FAIL", f"maintenance.enabled={maint}")
        schema = c.get("/openapi.json").json()
        pub = auth = 0
        for path, ops in schema["paths"].items():
            for method, op in ops.items():
                if method in ("get", "post", "put", "delete", "patch"):
                    if op.get("security"):
                        auth += 1
                    else:
                        pub += 1
        total = pub + auth
        rec("5 API routes", "PASS" if total == 19 else "FAIL",
            f"{total} operations (expected 19): {pub} public (no bearer), {auth} authenticated")
        # --- 4. Firebase
        try:
            import firebase_admin
            firebase_admin.get_app()
            rec("4 Firebase Admin SDK", "PASS", "initialised")
        except Exception as e:
            rec("4 Firebase Admin SDK", "FAIL", type(e).__name__)
        noauth = c.get("/me")
        rec("4 401 without token", "PASS" if noauth.status_code == 401 else "FAIL", f"GET /me -> {noauth.status_code}")
        uid = None
        try:
            with FirebaseTestUser() as u:
                uid = u.uid
                rec("4 Firebase test user + ID token", "PASS", "created, signed in, token obtained")
                me = c.get("/me", headers=u.headers)
                rec("4 GET /me with token", "PASS" if me.status_code == 200 else "FAIL", f"HTTP {me.status_code}")
                g = c.post("/grade", headers=u.headers, files={"image": ("blank.png", blank_png(), "image/png")})
                gj = g.json() if g.headers.get("content-type", "").startswith("application/json") else {}
                rejected = g.status_code == 200 and gj.get("status") not in (None, "ok")
                rec("4 POST /grade blank image", "PASS" if rejected else "FAIL",
                    f"HTTP {g.status_code}, status={gj.get('status')}, reason={gj.get('reason') or gj.get('code')}")
            rec("4 Test user deleted", "PASS", "deleted on exit")
        except Exception as e:
            rec("4 Firebase test user", "FAIL", f"{type(e).__name__}")
        finally:
            if uid:
                try:
                    purge_user_data(uid)
                except Exception:
                    pass


# ------------------------------------------------------------------ 6. model files

def check_models():
    from app.config import get_settings
    s = get_settings()
    mf = ["config_v3.json", "efficientnet_v3.keras", "rf_model_v3.pkl", "scaler_v3.pkl"]
    ef = ["export_extra.json", "export_manifest.json", "export_wb.json", "gate_stats.json",
          "grade_profiles.json", "ood_stats.json", "ood_stats.npz"]
    for label, d, names in (("model files", s.model_dir, mf), ("export files", s.export_dir, ef)):
        sizes, miss = [], []
        for n in names:
            p = os.path.join(d, n)
            if os.path.isfile(p):
                sizes.append(f"{n} {os.path.getsize(p)} B")
            else:
                miss.append(n)
        rec(f"6 {label}", "FAIL" if miss else "PASS",
            f"{len(names) - len(miss)}/{len(names)} present: {', '.join(sizes)}"
            + (f"; MISSING {', '.join(miss)}" if miss else ""))


# ------------------------------------------------------------------ 7. repo hygiene (host)

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")


def check_hygiene():
    top = run(["git", "rev-parse", "--show-toplevel"])
    if top.returncode != 0:
        return rec("7 Repo hygiene", "SKIP", "git not available here (run on the host)")
    root = top.stdout.strip()
    files = run(["git", "-C", root, "ls-files"]).stdout.splitlines()
    bad = [f for f in files if re.search(r"(^|/)\.env$", f) or f.startswith(("backend/models/", "backend/secrets/"))
           or f.endswith(".pem") or re.search(r"(credentials?|accessKeys?|rootkey).*\.csv$", f, re.I)]
    bad = [f for f in bad if not f.endswith(".gitkeep")]
    rec("7 Tracked sensitive files", "FAIL" if bad else "PASS",
        ("tracked: " + ", ".join(bad)) if bad else "no .env, models/secrets files, *.pem or credential csv tracked")
    ign = []
    for p in ("backend/.env", "backend/models/efficientnet_v3.keras", "backend/secrets/firebase-service-account.json"):
        r = run(["git", "-C", root, "check-ignore", "-q", p])
        ign.append((p.split("/")[1], r.returncode == 0))
    rec("7 Ignored paths", "PASS" if all(v for _, v in ign) else "FAIL",
        ", ".join(f"{n}={'ignored' if v else 'NOT ignored'}" for n, v in ign))
    pats = {"AKIA": r"AKIA[0-9A-Z]{16}", "mongodb password": r"mongodb(\+srv)?://[^/\s:@<>]+:[^@\s<>]+@",
            "private_key": r"private_key"}
    hits = []
    for f in files:
        if f.endswith((".png", ".jpg", ".jpeg", ".gif", ".ico", ".keras", ".pkl", ".npz", ".pdf", ".ttf", ".otf", ".zip", ".webp", ".mp4")):
            continue
        try:
            with open(os.path.join(root, f), "r", encoding="utf-8") as fh:
                for i, line in enumerate(fh, 1):
                    for name, rx in pats.items():
                        if re.search(rx, line):
                            hits.append(f"{f}:{i} ({name})")
        except (UnicodeDecodeError, OSError):
            continue
    rec("7 Secret patterns in tracked files", "FAIL" if hits else "PASS",
        ("; ".join(hits[:40])) if hits else "no AKIA keys, mongodb URIs with password or private_key found")


# ------------------------------------------------------------------ 8. docker (host)

def check_docker():
    r = run(["docker", "inspect", "gemeye-api"])
    if r.returncode != 0:
        return rec("8 Docker", "SKIP", "docker not available here or container missing (run on the host)")
    d = json.loads(r.stdout)[0]
    st = d["State"]
    health = (st.get("Health") or {}).get("Status")
    rec("8 Docker container", "PASS" if st["Status"] == "running" and health == "healthy" else "FAIL",
        f"status={st['Status']}, health={health}, image={d['Config']['Image']}")
    mounts = ", ".join(f"{m['Source'].replace(chr(92), '/')} -> {m['Destination']} ({'ro' if not m['RW'] else 'rw'})"
                       for m in d["Mounts"])
    rec("8 Compose data location", "PASS", "bind mounts only, no named volumes: " + mounts
        if not any(m["Type"] == "volume" for m in d["Mounts"]) else mounts)


CHECKS = {1: check_settings, 2: check_mongo, 3: check_s3, 4: check_firebase_api, 6: check_models,
          7: check_hygiene, 8: check_docker}


def render(paths):
    rows = []
    for p in paths:
        with open(p, "r", encoding="utf-8-sig") as fh:
            rows += json.load(fh)
    n = {k: sum(r["status"] == k for r in rows) for k in ("PASS", "FAIL", "SKIP")}
    out = ["# Connectivity check", "",
           f"Generated by `backend/scripts/self_check.py` (ENV=test for checks 1-6). "
           f"**{n['PASS']} PASS, {n['FAIL']} FAIL, {n['SKIP']} SKIP.** No secret values are recorded.", ""]
    fails = [r for r in rows if r["status"] == "FAIL"]
    out += ["## Failures", ""]
    out += [f"- **{r['check']}**: {r['detail']}" for r in fails] or ["None."]
    out += ["", "## All checks", "", "| Check | Status | Detail |", "|---|---|---|"]
    order = {"FAIL": 0, "SKIP": 1, "PASS": 2}
    for r in sorted(rows, key=lambda r: (order[r["status"]], r["check"])):
        out.append(f"| {r['check']} | {r['status']} | {r['detail'].replace('|', '/')} |")
    print("\n".join(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="1,2,3,4,5,6,7,8")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--render", nargs="+")
    a = ap.parse_args()
    if a.render:
        return render(a.render)
    sel = {int(x) for x in a.only.split(",")}
    if 5 in sel:
        sel.add(4)      # checks 4 and 5 share one app instance
    real = sys.stdout
    sys.stdout = io.StringIO()     # keep library chatter out of the JSON
    try:
        for k, fn in CHECKS.items():
            if k in sel:
                guarded(f"{k}", fn)
    finally:
        sys.stdout = real
    print(json.dumps(RESULTS, indent=1))


if __name__ == "__main__":
    main()
