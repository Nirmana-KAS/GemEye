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

export interface MonitoringDay {
  day: string;
  count: number;
  mean_confidence: number | null;
  mean_uncertainty: number | null;
  referral_rate: number;
  unusual_image: number;
  mean_latency_ms: number | null;
}

export interface ModelMonitoring {
  days: number;
  timezone: string;
  versions: {
    model_version: string;
    days: MonitoringDay[];
    review_agreement: { day: string; reviewed: number; agreed: number; agreement_rate: number }[];
  }[];
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
  review?: { gemologist_grade: number; agrees: boolean | null; notes: string | null; reviewed_at: string | null } | null;
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
