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

export interface ApiErrorBody {
  status?: string;
  code?: string;
  message?: string;
  detail?: unknown;
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
