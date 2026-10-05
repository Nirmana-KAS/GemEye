# GemEye API Reference

**Base URL (local demo):** `http://192.168.1.195:8000` | **Live docs:** `/docs` (Swagger), `/redoc`

**Auth:** every endpoint marked 🔒 needs the header `Authorization: Bearer <Firebase ID token>`.
Endpoints marked 🌐 are public.

---

## Part 1 - Endpoints

### System

#### 🌐 `GET /health`
- Checks that the server is running and the AI models are loaded.
- Returns the model version (`v3`) and the installed library versions.
- **Response:** `HealthResponse`

#### 🌐 `GET /config`
- Remote settings the app reads at startup.
- Includes the default referral threshold, how long a calibration stays valid (hours), maintenance mode, feature flags and the blur threshold.
- Lets you change app behaviour without releasing a new app version.
- **Response:** `AppConfig`

---

### Grading

#### 🔒 `POST /grade`
- **The main endpoint.** Uploads a stone photo and returns its colour grade.
- Sent as `multipart/form-data` (JPEG or PNG, up to 15 MB).
- Runs 5 quality gates first: `invalid_image`, `no_stone`, `blurry`, `not_blue`, `not_recognised`.
- If a gate fails: `status` is the gate code, with a `message` and no grade.
- If it passes: grade 1-7, confidence, uncertainty, probabilities, colour values and the referred flag.
- On success the photo is saved to S3 and the grading to MongoDB.
- `request_id` (UUID) prevents duplicates: a retry returns the original result.
- **Request:** `Body_grade_stone_grade_post` | **Response:** `GradeResponse`

#### 🔒 `GET /gradings`
- The user's grading history, newest first.
- Filters: `grade` (1-7), `referred`, `from`, `to` (dates).
- Paging: `limit` (1-50, default 20) and `cursor` (the `next_cursor` from the previous page).
- **Response:** `GradingList`

#### 🔒 `GET /gradings/{grading_id}`
- One grading with full details and a fresh photo link.
- Another user's grading returns 404.
- **Response:** `GradingItem`

#### 🔒 `DELETE /gradings/{grading_id}`
- Deletes a grading, its photo and its heatmap.
- Certificates already issued for it are kept.
- **Response:** `204 No Content`

#### 🔒 `POST /gradings/{grading_id}/heatmap`
- Generates a **Grad-CAM heatmap** showing where the AI looked.
- Explanation only; it never changes the grade.
- Cached in S3, so the second call is fast.
- **Response:** `HeatmapOut`

---

### Calibration

#### 🔒 `POST /calibrations`
- Saves a calibration session from the app's 6-patch colour check.
- Stores the 3x3 colour correction matrix (CCM), the error (residual), the quality rating and the measured patch colours.
- Sending the same `session_id` again returns 409.
- **Request:** `CalibrationIn` | **Response:** `CalibrationItem` (201)

#### 🔒 `GET /calibrations`
- The user's calibration history, newest first (max 50).
- **Response:** `CalibrationList`

---

### User profile

#### 🔒 `GET /me`
- The logged-in user's profile and settings.
- The account is created automatically on the first request.
- **Response:** `UserResponse`

#### 🔒 `PUT /me`
- Updates the profile: name, account type (individual/company), country, phone, company details and settings.
- Partial update: send only the fields you want to change.
- Protected fields (`role`, `email`) are ignored.
- **Request:** `ProfileUpdate` | **Response:** `UserResponse`

#### 🔒 `DELETE /me`
- **Permanently deletes the account** and all data: gradings, photos, calibrations, feedback and the Firebase user.
- Requires a recent sign-in (within 5 minutes).
- The user's certificates become "withdrawn".
- **Response:** `204 No Content`

---

### Certificates

#### 🔒 `POST /certificates`
- Issues a certificate for a grading.
- Number format: `GE-YYYYMM-NNNNN`.
- **If the grading already has a valid certificate, the same one is returned** (no new number).
- **Request:** `CertificateIn` | **Response:** `CertificateIssued` (201 new / 200 existing)

#### 🔒 `GET /certificates`
- The user's certificates, newest first.
- Paging: `limit` (1-100) and `cursor`.
- **Response:** `CertificateList`

#### 🔒 `GET /certificates/{cert_no}`
- One certificate with its frozen result snapshot, verify link and PDF hash.
- **Response:** `CertificateItem`

#### 🔒 `POST /certificates/{cert_no}/pdf`
- Uploads the certificate PDF made by the app (max 5 MB).
- **Allowed once only.** The server stores its SHA-256 hash to detect tampering.
- **Request:** `Body_upload_pdf...` (multipart `file`) | **Response:** `CertificateItem`

#### 🔒 `POST /certificates/{cert_no}/revoke`
- Cancels a certificate, with a reason.
- The public page then shows "revoked".
- **Request:** `RevokeIn` | **Response:** `CertificateItem`

---

### Public verification

#### 🌐 `GET /public/v/{slug}`
- Used by the QR code / web page to check that a certificate is genuine.
- `slug` = `GE-YYYYMM-NNNNN-<secret token>`.
- A wrong number or token returns the same 404, so certificates cannot be guessed.
- Never shows the owner's email or user ID.
- Rate limit: 30 requests per minute per IP.
- **Response:** `PublicCertificate`

---

### Common errors

| Code | Meaning |
|---|---|
| 400 | Bad input (wrong file type, invalid JSON) |
| 401 | Not logged in / token invalid / account deleted |
| 404 | Not found (also used for other users' data) |
| 409 | Conflict (duplicate, PDF already uploaded, certificate not valid) |
| 413 | File too large |
| 422 | Request fields fail validation |
| 429 | Too many requests |
| 503 | Database/storage unavailable or maintenance mode |

---

## Part 2 - Schemas

`*` = required field. `?` = may be `null`.

### Grading schemas

#### `Body_grade_stone_grade_post` (request for `/grade`)
| Field | Type | Meaning |
|---|---|---|
| `image`* | file | Stone photo (JPEG/PNG) |
| `patches`? | JSON string | 6x3 calibration patch colours |
| `referral_threshold`? | number | 0.40-0.90; below this confidence the stone is referred |
| `session_id`? | string | Calibration session ID |
| `request_id`? | UUID | Prevents duplicate gradings on retry |
| `app_version`?, `device`? | string | Stored for tracking |
| `debug`, `gates` | boolean | Development only |

#### `GradeResponse`
| Field | Type | Meaning |
|---|---|---|
| `status`* | string | `ok` or a gate code (`blurry`, `no_stone` ...) |
| `message`? | string | Reason when rejected |
| `warnings`? | string[] | e.g. `unusual_image` |
| `grade`? | int | 1-7 |
| `grade_name`?, `trade_name`? | string | e.g. "Vivid", "Royal Blue" |
| `probabilities`? | number[7] | Probability of each grade |
| `confidence`? | number | Top probability (0-1) |
| `uncertainty`? | number | MC Dropout spread |
| `referred`? | boolean | true = send to a human expert |
| `second_grade`? | int | Next most likely grade |
| `colour`? | `ColourValues` | Measured colour |
| `delta_e00_to_typical`? | number | ΔE₀₀ to the grade's typical colour |
| `calibration_mode`? | string | `training_session` / `session_patches` |
| `model_version`? | string | `v3` |
| `timings_ms`? | `Timings` | Processing times |
| `diagnostics`* | `Diagnostics` | Gate measurements |
| `debug`? | `DebugInfo` | Development only |
| `grading_id`?, `stone_id`? | string | Saved record IDs (`GE-STONE-NNNNN`) |
| `image_url`? | string | Photo link (valid 10 min) |

#### `ColourValues`
| Field | Type | Meaning |
|---|---|---|
| `L`*, `a`*, `b`* | number | CIELAB colour |
| `C`* | number | Chroma (colour strength) |
| `H`*, `S`*, `B`* | number | Hue, Saturation, Brightness |
| `hex`* | string | Display colour, e.g. `#2A408C` |
| `ciecam02`? | `Ciecam02` | Colour appearance values |
| `approximate`* | boolean | true = stone outline was uncertain |

#### `Ciecam02`
- `J`* lightness, `M`* colourfulness, `h`* hue angle, `s`* saturation, `C`* chroma (all numbers).

#### `Timings`
- `total`*, `preprocess`*, `rf`*, `cnn`* - milliseconds.

#### `Diagnostics` (all optional)
| Group | Fields |
|---|---|
| Image size | `short_side_px`, `min_short_side_px` |
| Blur | `blur_variance`, `blur_min_variance` |
| Stone found | `gate_stone_area`, `no_stone_min_area`, `stone_tray_contrast_de00`, `no_stone_min_contrast_de00`, `gate_centre_fallback`, `stone_area_fraction` |
| Blue check | `hue_wb`, `hue_gate_min`, `hue_gate_max`, `hue_in_gate`, `chroma_wb`, `min_chroma`, `hue_gate_skipped` |
| Segmentation | `segmentation_reliable`, `model_segmentation_fallback` |
| Unusual image (OOD) | `ood_distance`, `ood_warn`, `ood_threshold` |

#### `DebugInfo` (development only)
- `rf_grade`, `rf_probabilities` - Random Forest result.
- `cnn_mc_grade`, `cnn_mc_probabilities` - CNN with MC Dropout.
- `cnn_deterministic_grade`, `cnn_deterministic_probabilities` - CNN single pass.
- `model_segmentation_fallback`, `gates_bypassed`.

#### `GradingItem`
| Field | Type | Meaning |
|---|---|---|
| `grading_id`*, `stone_id`* | string | IDs |
| `created_at`* | datetime | When graded |
| `status`* | string | `ok` |
| `result`* | object | The full grade response |
| `image_url`? | string | Photo link (10 min) |
| `calibration_session_id`? | string | Calibration used |
| `app_version`?, `device`? | string | Tracking |
| `referral_threshold_used`* | number | Threshold at grading time |

#### `GradingList`
- `items`* - list of `GradingItem`; `next_cursor`? - for the next page.

#### `HeatmapOut`
- `url`* - heatmap PNG link (10 min).
- `method`* - `gradcam_cnn_branch`.
- `target_grade`* - the grade explained.
- `stone_mask_heat_fraction`* - share of the heat on the stone (0-1).

---

### Calibration schemas

#### `CalibrationIn` (request)
| Field | Type | Meaning |
|---|---|---|
| `session_id`* | string | e.g. `S-2026-10-05-01` |
| `valid_until`? | datetime | Expiry (usually +8 h) |
| `device`? | string | Phone model |
| `ccm`* | number[3][3] | Colour correction matrix |
| `residual`? | number | Fit error |
| `quality`? | string/number | excellent / acceptable / poor |
| `measured_patches`* | number[6][3] | RGB of the 6 patches |

#### `CalibrationItem`
- Same as `CalibrationIn` plus `calibration_id`* and `created_at`*.

#### `CalibrationList`
- `items`* - list of `CalibrationItem`.

#### `CalibrationRef`
- `session_id`*, `residual`? - calibration info inside a certificate.

---

### User schemas

#### `UserResponse`
| Field | Type | Meaning |
|---|---|---|
| `uid`* | string | Firebase user ID |
| `email`?, `email_verified`* | string, boolean | Account email |
| `display_name`? | string | Name |
| `account_type`? | string | `individual` / `company` |
| `role`? | string | `user` (server-set) |
| `country`?, `phone`? | string | Contact |
| `company`* | `Company` | Company details |
| `settings`* | `UserSettings` | Preferences |
| `created_at`*, `updated_at`* | datetime | Timestamps |

#### `ProfileUpdate` (request, all optional)
- `display_name`, `account_type`, `country`, `phone`, `company` (`CompanyUpdate`), `settings` (`UserSettingsUpdate`).

#### `Company` / `CompanyUpdate`
- `name`, `reg_no`, `industry`, `address`, `logo_key` (all optional strings).

#### `UserSettings` / `UserSettingsUpdate`
- `show_name_on_certificates` (boolean, default false) - print the owner's name on public certificates.
- `referral_threshold` (number, default 0.60) - confidence below which stones are referred.

---

### Certificate schemas

#### `CertificateIn` (request)
- `grading_id`* - the grading to certify.

#### `CertificateIssued`
- `cert_no`* (`GE-YYYYMM-NNNNN`), `verify_url`* (QR link), `issued_at`*.

#### `CertificateItem`
| Field | Type | Meaning |
|---|---|---|
| `cert_no`* | string | Certificate number |
| `grading_id`* | string | Linked grading |
| `status`* | string | `valid` / `revoked` / `withdrawn` |
| `issued_at`* | datetime | Issue time |
| `verify_url`* | string | Public verification link |
| `snapshot`* | `CertificateSnapshot` | Frozen result |
| `owner`? | `CertificateOwner` | Only if the owner opted in |
| `pdf_sha256`?, `pdf_uploaded_at`? | string, datetime | PDF fingerprint |
| `revoked_reason`?, `revoked_at`? | string, datetime | If revoked |

#### `CertificateSnapshot` (the result frozen at issue time)
- `stone_id`*, `grade`*, `grade_name`*, `trade_name`*, `confidence`*, `uncertainty`*, `referred`*.
- `colour`* (`ColourValues`), `delta_e00_to_typical`?, `model_version`*.
- `captured_at`*, `issued_at`*, `calibration`? (`CalibrationRef`).

#### `CertificateOwner`
- `display_name`?, `company`?.

#### `CertificateList`
- `items`* - list of `CertificateItem`; `next_cursor`?.

#### `Body_upload_pdf...` (request)
- `file`* - the PDF file.

#### `RevokeIn` (request)
- `reason`* - why it is revoked (1-500 characters).

#### `PublicCertificate` (public verification result)
| Field | Type | Meaning |
|---|---|---|
| `cert_no`*, `status`*, `issued_at`* | | Certificate state |
| `snapshot`? | `CertificateSnapshot` | Grade details (null if withdrawn) |
| `owner`? | `CertificateOwner` | Only if allowed |
| `revoked_reason`?, `revoked_at`? | | If revoked |
| `image_url`?, `pdf_url`? | string | Links (10 min) |
| `pdf_sha256`? | string | Check the PDF has not been edited |
| `disclaimer`* | string | Legal note |

---

### Other schemas

#### `FeedbackIn` (request)
- `rating`* (1-5), `category`* (`accuracy` / `app` / `calibration` / `other`), `comment`? (max 500), `app_version`?.

#### `FeedbackOut`
- `feedback_id`*, `created_at`*.

#### `HealthResponse`
- `status`*, `model_version`*, `models_loaded`*, `versions`* (library versions), `ciecam02_display_available`*.

#### `AppConfig`
| Field | Meaning |
|---|---|
| `referral_threshold_default`* | Default 0.60 |
| `calibration_validity_hours`* | Default 8 |
| `min_app_version`* | Oldest app allowed |
| `maintenance`* | `Maintenance` |
| `features`* | `Features` |
| `blur_min_variance`* | Blur threshold shared with the app |

#### `Maintenance`
- `enabled`* (boolean), `message`* (shown to users).

#### `Features` (feature flags)
- `repeatability_mode`*, `gradcam`*, `public_verification`*, `session_mapping` (all boolean).

#### `HTTPValidationError` / `ValidationError`
- Returned with 422 when request fields are wrong.
- `detail` is a list of `{loc, msg, type}`, showing which field failed and why.
