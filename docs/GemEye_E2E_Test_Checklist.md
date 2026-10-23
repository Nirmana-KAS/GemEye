# GemEye End-to-End Test Checklist

Manual test plan for the GemEye app, API and admin dashboard. Mark each row Pass or Fail and note the date, build and any observation. Screenshot names refer to `docs/screenshots/app/README.md`.

## Test setup

1. Double-click `Start GemEye Demo.bat` in the project root. Wait until the launcher reports that the API and the dashboard are running.
2. Connect the phone to the same Private Wi-Fi network as the PC (not a Public profile, not guest Wi-Fi). Install the latest debug build on the phone.
3. In MongoDB Atlas, Network Access must allow the current PC IP address.
4. For QR and certificate verification tests (CE-xx): in the dashboard, App control, set `verify_base_url` to `http://<PC IP>:3000` (PC IP from `ipconfig`), save, and make sure the PC firewall allows port 3000. Set it back afterwards.
5. Test accounts: one normal user (email), one normal user (Google), one admin, one reviewer. Dashboard: http://localhost:3000/admin/login/.
6. Have 3-4 sample stones: a clear blue sapphire, a non-blue object, a blurred photo, and a stone that gets referred.

## 1. Sign-up and sign-in

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| AU-01 | App sign-up (email) | Open app, accept agreement, Register, choose Individual, fill details, submit | Account created, onboarding shown on first login | | |
| AU-02 | App sign-up (company) | Register as Company with a company name | Account created, company name visible in Profile | | |
| AU-03 | App weak password | Register with a short password | Clear error, no account created | | |
| AU-04 | App sign-in (email) | Sign out, sign in with the new account | Home opens, greeting shows first name | | |
| AU-05 | App wrong password | Sign in with a wrong password | Friendly error message, no raw error text | | |
| AU-06 | App sign-in (Google) | Tap Continue with Google, pick an account | Signed in, Home opens | | |
| AU-07 | Agreement required | Fresh install, try to continue without ticking the agreement | Button disabled; cannot proceed | | |
| AU-08 | Dashboard sign-in (email) | Open /admin/login/, sign in as admin | Overview opens | | |
| AU-09 | Dashboard sign-in (Google) | Use Google sign-in with the admin account | Overview opens | | |
| AU-10 | Dashboard non-admin | Sign in to the dashboard with a normal user | Access refused, no data shown | | |
| AU-11 | Reviewer access | Sign in as reviewer | Only Gradings and Review queue open; other pages show "No access" | | |

## 2. Calibration

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| CA-01 | New calibration | Home banner, start the 3-step wizard with the CCC card | Calibration completes, status shows Calibrated | | |
| CA-02 | Calibration required | New user with no calibration taps Grade | Prompted to calibrate first | | |
| CA-03 | 24 h expiry | Use an account calibrated more than 24 h ago (or move the phone clock +25 h) | Banner asks for recalibration; grading blocked until redone | | |
| CA-04 | Card not found | Run the wizard without the card in view | Detection error and retry option | | |
| CA-05 | Admin invalidates | Dashboard, Calibrations, Invalidate a live session (reason + typed session id) | Row shows invalidated; app asks the user to recalibrate | | |
| CA-06 | Calibrations list | Open Calibrations page | Sessions listed with status; reset sessions show a "Reset" chip | | |

## 3. Grading

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| GR-01 | Valid stone | Calibrated user captures a clear blue sapphire, crops, submits | 7-step processing, then result with grade 1-7, confidence, Grad-CAM, colour values | | |
| GR-02 | Result values | Check the result screen | Grade badge, name, trade name and colour values (L*, Hue, delta E) shown | | |
| GR-03 | Gate: blur | Submit a blurred photo | Rejected with a clear blur message; no grade created | | |
| GR-04 | Gate: low light | Capture in very dim light | Light warning or rejection message | | |
| GR-05 | Gate: not a sapphire | Submit a non-blue object | Rejected with a "not a blue sapphire" style message | | |
| GR-06 | Gate: framing | Submit a photo with the stone too small or cut off | Rejected with a framing message | | |
| GR-07 | Gate: threshold | Dashboard, App control, tighten a gate within bounds; resubmit a borderline stone | Stone rejected for that gate; restore the gate afterwards | | |
| GR-08 | Referral | Submit the stone that triggers a low-confidence referral | Result says it was sent for expert review; appears in Review queue | | |
| GR-09 | Network lost | Switch phone to airplane mode and submit | Friendly error, no crash, can retry | | |
| GR-10 | Dashboard listing | Dashboard, Gradings | New grading listed with correct user, grade, confidence | | |
| GR-11 | Grading detail | Open the grading in the dashboard | Photo, Grad-CAM, probabilities and colour values match the app | | |

## 4. History

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| HI-01 | History list | App, History tab | Graded stones listed newest first | | |
| HI-02 | Search and filter | Search or filter by grade | List narrows correctly | | |
| HI-03 | Admin hides | Dashboard, Gradings, select a stone, Hide (reason + typed `HIDE 1`) | Dashboard shows a Hidden chip | | |
| HI-04 | Hidden in app | Refresh the app History | Hidden stone no longer shown | | |
| HI-05 | Admin restores | Dashboard, Restore the stone | Stone reappears in the app after refresh | | |
| HI-06 | Bulk hide / restore | Select 2 stones, bulk Hide then Restore | Both change state | | |
| HI-07 | Delete permanently | Grading detail, Delete permanently (reason + typed id) on a test stone | Stone removed from dashboard and app | | |

## 5. Certificates

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| CE-01 | Issue certificate | App, open a result, Export certificate | A4 PDF made, number like GE-YYYYMM-NNNNN, QR code printed | | |
| CE-02 | Re-export same number | Export the same stone again | Same certificate number, never a new one | | |
| CE-03 | History badge | App History | Exported stone shows its certificate number | | |
| CE-04 | QR verify: Valid | Scan the QR with the phone camera (verify_base_url set) | Verify page opens, status Valid, details match | | |
| CE-05 | Verify by code | Open `/v/?c=<code>` on the PC | Same Valid result | | |
| CE-06 | Revoked | Dashboard, Certificates, Revoke (reason + typed number); rescan QR | Verify page shows Revoked | | |
| CE-07 | Superseded | Supersede a certificate with a new number; open the old QR | Old shows Superseded and points to the new number | | |
| CE-08 | Withdrawn | Withdraw a certificate (stone deleted or withdrawn by admin); open its QR | Verify page shows Withdrawn | | |
| CE-09 | Unknown code | Open `/v/?c=GE-000000-00000` | "Not found" message, no crash | | |
| CE-10 | SHA-256 match | On the verify page choose the exported PDF | Hash matches the recorded value | | |
| CE-11 | SHA-256 mismatch | Choose a different or edited PDF | Clear "does not match" result | | |
| CE-12 | Certificate list | Dashboard, Certificates, filter by status and search by number | Results correct for each status | | |

## 6. Notifications

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| NO-01 | Receive | Grade a stone | Notification appears in the app with correct text | | |
| NO-02 | Clear one | Clear one notification | It disappears and stays gone after refresh | | |
| NO-03 | Clear all | Clear all | List empty, stays empty after refresh | | |
| NO-04 | Admin sees cleared | Dashboard, Notifications, All notifications, filter by that user | Cleared items still visible to admin | | |
| NO-05 | Admin restore | Restore a cleared notification from the dashboard | It returns to the user's app after refresh | | |
| NO-06 | Admin send to one | Notifications, Send, pick one user by email, send | Only that user receives it | | |
| NO-07 | Admin send to all | Send to all users (check the recipient count in the confirm) | All test accounts receive it | | |
| NO-08 | Sent history | Notifications, Sent history | Broadcast listed with recipient count | | |
| NO-09 | Send from user page | User detail, Send notification | User preselected; delivered | | |

## 7. Announcements and maintenance

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| AN-01 | Create | Announcements, create one with level and dates | Saved with status active; preview shown | | |
| AN-02 | Banner in app | Open app Home | Announcement banner shown | | |
| AN-03 | Scheduled | Create one starting in the future | Status scheduled; not shown in app yet | | |
| AN-04 | Delete / expire | Delete one (or let it expire) | Banner disappears from the app | | |
| AN-05 | Also notify | Create with "Also send as notification to all users" | Banner and a notification both arrive | | |
| MA-01 | Maintenance on | App control, Maintenance on (type `MAINTENANCE`), save | App shows the maintenance screen; grading blocked | | |
| MA-02 | Maintenance off | Turn it off | App returns to normal after reopening | | |
| MA-03 | Dashboard unaffected | While maintenance is on, use the dashboard as admin | Dashboard still works | | |

## 8. Account control

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| AC-01 | Disabled account | Disable a user from the dashboard | User cannot continue; clear "account disabled" message | | |
| AC-02 | Enable account | Enable again | User can sign in again | | |
| AC-03 | Force sign-out | User detail, Admin actions, Force sign-out | App signs the user out on next request | | |
| AC-04 | Edit profile | Admin edits name, phone, company | Changes visible in the app Profile | | |
| AC-05 | Daily limit | Set daily limit 1 for a user; grade two stones | Second grading refused with a daily-limit message | | |
| AC-06 | Limit cleared | Clear the limit | Grading works again | | |
| AC-07 | Blocked device | User detail, Devices, Block (reason + typed `BLOCK`) | App on that device is refused with a clear message | | |
| AC-08 | Unblock device | Unblock with a reason | App works again | | |
| AC-09 | Admin notes | Add and delete a note on a user | Note saved, admin only | | |
| AC-10 | Activity timeline | Open the user's Activity tab | Recent events listed; Load more works | | |

## 9. Review queue (reviewer role)

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| RQ-01 | Queue list | Sign in as reviewer, open Review queue | Referred stones listed; filters work | | |
| RQ-02 | Review panel | Open a stone | Zoomable photo, Grad-CAM, model grade, probabilities and colour values shown | | |
| RQ-03 | Save review | Pick a true grade (keys 1-7), confidence, save (Enter) | Review saved; stone leaves the pending list | | |
| RQ-04 | Save and next | Use Save and next | Next pending stone opens | | |
| RQ-05 | Unusable photo | Tick "not a blue sapphire / unusable photo" and save | Saved without a grade | | |
| RQ-06 | Own reviews only | Reviewer tries to edit another reviewer's review | Not allowed | | |
| RQ-07 | Admin statistics | As admin, open Review queue | Agreement and confusion heatmap shown; label CSV downloads | | |
| RQ-08 | Send to review | Admin sends a normal grading to review | Appears in the queue | | |
| RQ-09 | Re-grade | Grading detail, Re-grade | Original vs re-grade table shown | | |

## 10. Model monitoring and app control

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| MM-01 | Monitoring page | Model monitoring, switch 7 / 30 / 90 days | KPI cards and charts update | | |
| MM-02 | Version compare | Choose a model version; compare two versions | Per-version KPIs and side-by-side table | | |
| MM-03 | Overview counts | Dashboard Overview | Counts match the Users and Gradings pages | | |
| AP-01 | Bounds | App control, enter a gate value outside the allowed bounds | Field error, Save blocked | | |
| AP-02 | Valid change | Change one gate within bounds, Save | Diff dialog (old to new) shown; saved | | |
| AP-03 | Reset gates | Reset gates to defaults | Asks first, then restores defaults | | |
| AP-04 | Feature switch | Turn a feature switch off | Feature hidden or disabled in the app | | |
| AP-05 | Minimum version | Set minimum app version above the installed one | App shows an update-required message | | |
| AP-06 | Daily default | Set the default daily grading limit | Applies to users without their own limit | | |

## 11. Audit log and account deletion

| ID | Area | Steps | Expected result | Pass/Fail | Notes |
|---|---|---|---|---|---|
| AL-01 | Entries written | After the tests above, open Audit log | Entries exist for hide, restore, revoke, config change, block, notification send, invalidate | | |
| AL-02 | Entry detail | Click a row | Before / after field diff shown | | |
| AL-03 | Filters and CSV | Filter by action and admin; Export CSV | Filtered rows; CSV downloads | | |
| AL-04 | Read only | Look for edit or delete controls | None present | | |
| DEL-01 | Delete account | App, Settings, Delete account, confirm | Account and data removed; user signed out | | |
| DEL-02 | After deletion | Try to sign in with the deleted account | Not possible; user gone from the dashboard Users list | | |
| DEL-03 | Certificate after deletion | Open a QR of the deleted user's certificate | Verify page shows the documented state (Withdrawn) | | |
