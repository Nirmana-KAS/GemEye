# GemEye AWS Audit (read-only)

- **Date:** 05 October 2026 (IST)
- **Scope:** profile `gemeye-audit`, region `ap-south-1`, describe/list/get only. Nothing was changed. No secret values, keys or policy documents were printed.
- **Blocker:** the AWS CLI reports `The config profile (gemeye-audit) could not be found`. The only local profile is `gemeye`. The audit was not run with any other profile, so every AWS check is CANNOT VERIFY.
- **Also:** `aws.exe` is installed (`C:\Program Files\Amazon\AWSCLIV2\aws.exe`) but is not on the Git Bash PATH.

| # | Check | Result | Detail |
|---|-------|--------|--------|
| 1 | STS identity | CANNOT VERIFY | Profile `gemeye-audit` missing |
| 2 | ECR `gemeye-api` (private, MUTABLE, lifecycle > 3, tags/digests) | CANNOT VERIFY | Profile missing |
| 3 | SSM `/gemeye/MONGODB_URI`, `/gemeye/FIREBASE_SERVICE_ACCOUNT_JSON` (SecureString, Standard, alias/aws/ssm) | CANNOT VERIFY | Profile missing |
| 4 | IAM role `gemeye-lambda-role` (trust, basic exec, inline `gemeye-lambda-access`, no `ACCOUNT_ID`) | CANNOT VERIFY | Profile missing |
| 5 | IAM user `gemeye-deployer` (no login profile, policy, 1 key, no `ACCOUNT_ID`) | CANNOT VERIFY | Profile missing |
| 6 | SNS `gemeye-alerts` subscriptions | CANNOT VERIFY | Profile missing |
| 7 | S3 `gemeye-images-2026` (region, PAB, encryption) | CANNOT VERIFY | Profile missing |
| 8 | Budgets (names, limits) | CANNOT VERIFY | Profile missing |
| 9 | Lambda `gemeye-api` config | CANNOT VERIFY | Profile missing |
| 10 | `gemeye-api:dev` image architecture (amd64) | CANNOT VERIFY | Profile missing |
| 11a | Local: `docker info` | PASS | Docker Desktop 29.7.2, x86_64 |
| 11b | Local: free space on the Docker data drive | PASS | Docker WSL data is at `D:\DockerData\DockerDesktopWSL`, and D: has 861.2 GB free of 931.4 GB. Note: C: has only 16.7 GB free of 219.8 GB |
| 11c | Local: AWS profiles (names only) | FAIL | Only `gemeye`; `gemeye-audit` is missing |
| 11d | Local: `key.properties` / `*.jks` git-ignored or outside the repo | PASS | No such files in the repo. `app/android/.gitignore` ignores `key.properties`, `**/*.jks`, `**/*.keystore` |

## Fixes needed

1. Create the `gemeye-audit` profile (read-only credentials, region `ap-south-1`) in `~/.aws/config` and `~/.aws/credentials`, then re-run checks 1-10. Or confirm that `gemeye` may be used for this audit.
2. Optional: add `C:\Program Files\Amazon\AWSCLIV2` to PATH so `aws` works in Git Bash.
3. Watch C: free space (16.7 GB). Docker data itself is on D:.
