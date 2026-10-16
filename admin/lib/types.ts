// Response types for the GemEye admin API (docs/GemEye_API_Reference.md, Part 3).
// Datetimes are ISO strings.

export type Role = "admin" | "reviewer";
export type RoleSetting = Role | "none";

export interface Page<T> {
  items: T[];
  next_cursor: string | null;
}

export interface HealthResponse {
  status: string;
  model_version: string;
  models_loaded: boolean;
  versions?: Record<string, string>;
}

// ---- Stats ----

export type StatsDays = 1 | 7 | 30;

export interface StatsSummary {
  days: StatsDays;
  since: string;
  gradings: number;
  unique_users: number;
  referred: number;
  referral_rate: number | null;
  rejections: number;
  rejections_by_status: Record<string, number>;
  rejection_rate: number | null;
  avg_confidence: number | null;
  avg_uncertainty: number | null;
  avg_latency_ms: number | null;
  grade_distribution?: Record<string, number>;
  certificates_issued: number;
  feedback_count: number;
  server: { status: "ok" | "degraded"; models_loaded: boolean; model_version: string };
  database: { status: "ok" | "down" };
}

export type TimeseriesMetric = "gradings" | "rejections" | "referral_rate" | "avg_confidence";

export interface Timeseries {
  metric: TimeseriesMetric;
  bucket: "day";
  timezone: string;
  points: { day: string; value: number | null }[];
}

export type MonitoringDays = 7 | 30 | 90;

export interface MonitoringDay {
  day: string;
  count: number;
  mean_confidence: number | null;
  mean_uncertainty: number | null;
  referral_rate: number | null;
  unusual_image: number;
  mean_latency_ms: number | null;
  p95_latency_ms: number | null;
  rejections: number;
  rejections_by_gate: Record<string, number>;
  rejection_rate: number | null;
}

export interface Agreement {
  reviewed: number;
  agreed: number;
  within_one: number;
  agreement_rate: number | null;
  within_one_rate: number | null;
}

export interface MonitoringSummary {
  gradings: number;
  referred: number;
  referral_rate: number | null;
  avg_confidence: number | null;
  avg_uncertainty: number | null;
  unusual_image: number;
  unusual_image_rate: number | null;
  rejections: number;
  rejections_by_gate: Record<string, number>;
  rejection_rate: number | null;
  avg_latency_ms: number | null;
  p95_latency_ms: number | null;
  first_seen: string | null;
  last_seen: string | null;
  reviews: Agreement;
}

export interface MonitoringVersion {
  model_version: string;
  summary: MonitoringSummary;
  /** Every day of the range, oldest first (zero / null when there is no data). */
  days: MonitoringDay[];
  /** Only days with reviewed gradings. */
  review_agreement: ({ day: string } & Agreement)[];
}

export interface ModelMonitoring {
  days: number;
  timezone: string;
  model_version: string | null;
  day_keys: string[];
  versions: MonitoringVersion[];
  rejections_by_gate: { day: string; gate: string; model_version: string; count: number }[];
}

// ---- Users ----

export interface UserRow {
  uid: string;
  email: string | null;
  display_name: string | null;
  account_type: string | null;
  country: string | null;
  created_at: string | null;
  last_active: string | null;
  role?: RoleSetting | null;
  disabled?: boolean | null;
}

export interface CalibrationRow {
  calibration_id: string;
  uid: string;
  session_id: string | null;
  created_at: string | null;
  valid_until: string | null;
  device: string | null;
  residual: number | null;
  /** Not stored by the server yet; shown when present. */
  relative_residual?: number | null;
  quality: string | number | null;
}

export interface GradingRow {
  grading_id: string;
  stone_id: string | null;
  uid: string;
  created_at: string;
  status: string | null;
  grade: number | null;
  grade_name: string | null;
  confidence: number | null;
  uncertainty: number | null;
  referred: boolean | null;
  model_version: string | null;
  warnings: string[];
  device: string | null;
  app_version: string | null;
  image_url?: string | null;
  /** Admins only. */
  user_email?: string | null;
}

export interface UserDetail {
  profile: {
    uid: string;
    email: string | null;
    display_name: string | null;
    account_type: string | null;
    role: string | null;
    country: string | null;
    phone: string | null;
    company: Record<string, string | null> | null;
    created_at: string | null;
    updated_at: string | null;
  };
  settings: Record<string, unknown>;
  counts: Record<"gradings" | "rejections" | "calibrations" | "certificates" | "feedback", number>;
  last_gradings: GradingRow[];
  calibrations: CalibrationRow[];
  devices: string[];
  disabled: boolean | null;
  last_sign_in: string | null;
  role?: RoleSetting | null;
}

// ---- Grading detail ----

export interface ColourValues {
  L: number;
  a: number;
  b: number;
  C: number;
  H: number;
  S: number;
  B: number;
  hex: string;
  approximate: boolean;
  ciecam02?: { J: number; M: number; h: number; s: number; C: number } | null;
}

export interface GradeResult {
  status: string;
  message?: string | null;
  warnings?: string[] | null;
  grade?: number | null;
  grade_name?: string | null;
  trade_name?: string | null;
  probabilities?: number[] | null;
  confidence?: number | null;
  uncertainty?: number | null;
  referred?: boolean | null;
  second_grade?: number | null;
  colour?: ColourValues | null;
  delta_e00_to_typical?: number | null;
  calibration_mode?: string | null;
  model_version?: string | null;
  timings_ms?: Partial<Record<"total" | "preprocess" | "rf" | "cnn", number>> | null;
  diagnostics?: Record<string, number | boolean | string | null> | null;
  debug?: {
    rf_grade?: number;
    rf_probabilities?: number[];
    cnn_mc_grade?: number;
    cnn_mc_probabilities?: number[];
    cnn_deterministic_grade?: number;
    cnn_deterministic_probabilities?: number[];
  } | null;
}

export interface GradingDetail extends GradingRow {
  result: GradeResult | null;
  calibration_session_id: string | null;
  referral_threshold_used: number | null;
  heatmap_url: string | null;
  certificate: { cert_no: string; status: string; issued_at: string } | null;
  review?: { gemologist_grade: number | null; agrees: boolean | null; notes: string | null; reviewed_at: string | null } | null;
}

// ---- Review queue (Phase 10e) ----

export type ReviewQueueStatus = "pending" | "mine" | "reviewed";
export type ReviewerConfidence = "low" | "medium" | "high";

export interface QueueReview {
  gemologist_grade: number | null;
  reviewer_confidence: ReviewerConfidence | null;
  notes: string | null;
  agrees: boolean | null;
  unusable: boolean;
  reviewed_at: string | null;
  mine: boolean;
}

/** A referred grading for the review panel. Never carries user identity. */
export interface QueueItem extends Omit<GradingRow, "uid" | "user_email"> {
  trade_name: string | null;
  probabilities: number[] | null;
  second_grade: number | null;
  colour: ColourValues | null;
  delta_e00_to_typical: number | null;
  calibration_mode: string | null;
  referral_threshold_used: number | null;
  referred_reasons: string[];
  heatmap_url: string | null;
  review: QueueReview | null;
}

export interface ReviewBody {
  gemologist_grade: number | null;
  reviewer_confidence: ReviewerConfidence | null;
  unusable: boolean;
  notes: string | null;
}

export interface ReviewStats {
  reviewed: number;
  agreed: number;
  agreement_rate: number | null;
  within_one_grade_rate: number | null;
  unusable: number;
  pending: number;
  per_grade: { model_grade: number | null; reviewed: number; agreed: number; agreement_rate: number | null }[];
  per_model_version: { model_version: string; reviewed: number; agreed: number; agreement_rate: number | null }[];
  confusion_matrix: { rows: string; columns: string; counts: number[][] };
}

// ---- Errors and writes ----

export interface FieldError {
  /** Dotted field path, e.g. "gates.hue_min". */
  field: string;
  message: string;
}

export interface ApiErrorBody {
  status?: string;
  code?: string;
  message?: string;
  detail?: unknown;
  /** /admin/* validation errors (400). */
  fields?: FieldError[];
}

export interface PasswordResetResult {
  status: "sent" | "link";
  link?: string;
}

// ---- Notifications (Phase N1) ----

export type NotificationStatusFilter = "all" | "visible" | "cleared";

export interface AdminNotification {
  id: string;
  type: "success" | "warning" | "error" | "info";
  category: "calibration" | "referral" | "certificate" | null;
  title: string;
  message: string;
  action: string | null;
  payload: string | null;
  source: "app" | "server";
  created_at: string;
  read_at: string | null;
  cleared_at: string | null;
  restored_at: string | null;
  restored_by_email: string | null;
}

export interface AdminNotificationPage extends Page<AdminNotification> {
  counts: { visible: number; cleared: number };
}

// ---- App control (Phase 10f) ----

export type GateKey =
  | "blur_min_variance"
  | "no_stone_min_area"
  | "no_stone_min_contrast_de00"
  | "hue_min"
  | "hue_max"
  | "min_chroma"
  | "ood_warn"
  | "ood_reject";

export type FeatureKey = "repeatability_mode" | "gradcam" | "public_verification" | "session_mapping";

export interface Bound {
  min: number;
  max: number;
}

export interface AdminConfig {
  referral_threshold_default: number;
  calibration_validity_hours: number;
  min_app_version: string;
  update_message: string;
  maintenance: { enabled: boolean; message: string };
  features: Record<FeatureKey, boolean>;
  verify_base_url: string;
  gates: Record<GateKey, number>;
  gate_defaults: Record<GateKey, number>;
  gate_bounds: Record<GateKey, Bound>;
  bounds: {
    referral_threshold_default: Bound;
    calibration_validity_hours: Bound;
    message_max: number;
  };
}

// ---- Announcements ----

export type AppAction = "none" | "openResult" | "openCalibration" | "openCapture" | "openHistory" | "openPrivacy";

export interface Announcement {
  id: string;
  state: "live" | "scheduled" | "expired" | "disabled";
  title: string;
  message: string;
  level: "info" | "warning";
  starts_at: string;
  ends_at: string;
  active: boolean;
  action: AppAction;
  created_by_hash: string | null;
  created_by_email: string | null;
  created_at: string;
}

export interface AnnouncementBody {
  title: string;
  message: string;
  level: "info" | "warning";
  starts_at: string | null;
  ends_at: string;
  active: boolean;
  action: AppAction;
}

// ---- Send notifications ----

export type NotificationType = AdminNotification["type"];
export type NotificationCategory = NonNullable<AdminNotification["category"]>;

export interface SendNotificationBody {
  target: "user" | "all";
  uid?: string;
  type: NotificationType;
  category?: NotificationCategory;
  title: string;
  message: string;
  action: AppAction;
  payload?: string;
}

export interface SendResult {
  id: string;
  target: "user" | "all";
  count: number;
  at: string;
}

export interface Broadcast {
  id: string;
  target: "user" | "all";
  uid: string | null;
  count: number;
  title: string;
  type: NotificationType;
  category: NotificationCategory | null;
  action: AppAction | null;
  at: string;
  user_email: string | null;
  sent_by_email: string | null;
}

export type AllNotificationStatus = "all" | "visible" | "cleared" | "read" | "unread";

export interface AllNotificationRow extends Omit<AdminNotification, "source"> {
  source: "app" | "server" | "admin";
  uid: string;
  user_email: string | null;
  sent_by_email: string | null;
}

// ---- Feedback ----

export type FeedbackStatus = "open" | "resolved";

export interface FeedbackRow {
  feedback_id: string;
  uid: string;
  user_email: string | null;
  created_at: string;
  rating: number | null;
  category: string | null;
  comment: string | null;
  app_version: string | null;
  status: FeedbackStatus;
  status_note: string | null;
  status_at: string | null;
}

// ---- Certificates ----

export type CertificateStatus = "valid" | "revoked" | "superseded" | "withdrawn";

export interface CertificateSnapshot {
  stone_id: string;
  grade: number;
  grade_name: string;
  trade_name: string;
  confidence: number;
  uncertainty: number;
  referred: boolean;
  colour: ColourValues | null;
  delta_e00_to_typical?: number | null;
  model_version: string;
  captured_at: string;
  issued_at: string;
  calibration?: { session_id: string; residual: number | null } | null;
}

export interface CertificateRow {
  cert_no: string;
  uid: string | null;
  grading_id: string | null;
  user_email: string | null;
  status: "valid" | "revoked" | "withdrawn";
  issued_at: string;
  snapshot: CertificateSnapshot | null;
  owner: { display_name?: string | null; company?: string | null } | null;
  pdf_sha256: string | null;
  pdf_uploaded_at: string | null;
  revoked_reason: string | null;
  revoked_at: string | null;
  withdrawn_at: string | null;
  superseded_by: string | null;
}

export interface CertificateDetail extends CertificateRow {
  pdf_url: string | null;
  image_url: string | null;
  verify_url_masked: string | null;
}

// ---- Audit log ----

export interface AuditRow {
  audit_id: string;
  action: string;
  uid_hash: string | null;
  admin: boolean | null;
  role: string | null;
  target: Record<string, unknown> | null;
  before: unknown;
  after: unknown;
  at: string;
  admin_email: string | null;
}
