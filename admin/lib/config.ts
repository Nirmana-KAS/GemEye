import { z } from "zod";

import type { AdminConfig, FeatureKey, GateKey } from "./types";

/** Same pattern as the server (MAJOR.MINOR.PATCH, up to 4 digits each, no leading zeros). */
/** verify_base_url: https, or http only for localhost / a private LAN IP (same rule as the server). */
export const VERIFY_BASE_URL =
  /^(https:\/\/[A-Za-z0-9]([A-Za-z0-9.-]{0,120}[A-Za-z0-9])?(:\d{2,5})?(\/[A-Za-z0-9._~/-]{0,100})?|http:\/\/(localhost|127\.\d{1,3}\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(:\d{2,5})?)\/?$/;
export const SEMVER = /^(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})$/;

export const GATE_KEYS: GateKey[] = [
  "blur_min_variance",
  "no_stone_min_area",
  "no_stone_min_contrast_de00",
  "hue_min",
  "hue_max",
  "min_chroma",
  "ood_warn",
  "ood_reject",
];

export const FEATURE_KEYS: FeatureKey[] = ["repeatability_mode", "gradcam", "session_mapping", "public_verification"];

export const GATE_LABELS: Record<GateKey, string> = {
  blur_min_variance: "Blur: minimum Laplacian variance",
  no_stone_min_area: "No stone: minimum area fraction",
  no_stone_min_contrast_de00: "No stone: minimum contrast (dE00)",
  hue_min: "Not blue: minimum hue (deg)",
  hue_max: "Not blue: maximum hue (deg)",
  min_chroma: "Not blue: minimum chroma",
  ood_warn: "Unusual image: warn distance",
  ood_reject: "Unusual image: reject distance",
};

export const FEATURE_LABELS: Record<FeatureKey, string> = {
  repeatability_mode: "Repeatability mode",
  gradcam: "Grad-CAM heatmaps",
  session_mapping: "Session mapping",
  public_verification: "Public certificate verification",
};

/** Editable part of the remote config, in the same shape as the server's PUT body. */
export interface ConfigFormValues {
  referral_threshold_default: number;
  calibration_validity_hours: number;
  /** null = no default daily grading limit. */
  daily_grading_limit_default: number | null;
  min_app_version: string;
  update_message: string;
  /** Base of the QR verify link in new certificates. */
  verify_base_url: string;
  maintenance: { enabled: boolean; message: string };
  features: Record<FeatureKey, boolean>;
  gates: Record<GateKey, number>;
}

/** Server bounds of the default daily limit (older servers do not send them). */
export const DAILY_LIMIT_DEFAULT_BOUNDS = { min: 1, max: 500 };

const num = (label: string) => z.number({ error: `${label} must be a number.` });

function bounded(label: string, min: number, max: number) {
  return num(label)
    .min(min, `${label} must be at least ${min}.`)
    .max(max, `${label} must be at most ${max}.`);
}

/** zod schema built from the bounds GET /admin/config returns (the ones PUT enforces). */
export function configFormSchema(cfg: Pick<AdminConfig, "bounds" | "gate_bounds">) {
  const b = cfg.bounds;
  const lim = b.daily_grading_limit_default ?? DAILY_LIMIT_DEFAULT_BOUNDS;
  const gates = Object.fromEntries(
    GATE_KEYS.map((k) => [k, bounded(GATE_LABELS[k], cfg.gate_bounds[k].min, cfg.gate_bounds[k].max)]),
  ) as Record<GateKey, z.ZodNumber>;
  const msg = (label: string) => z.string().max(b.message_max, `${label} can be at most ${b.message_max} characters.`);
  return z
    .object({
      referral_threshold_default: bounded(
        "Referral threshold",
        b.referral_threshold_default.min,
        b.referral_threshold_default.max,
      ),
      calibration_validity_hours: bounded(
        "Calibration validity",
        b.calibration_validity_hours.min,
        b.calibration_validity_hours.max,
      ).int("Calibration validity must be a whole number of hours."),
      daily_grading_limit_default: bounded("Daily grading limit", lim.min, lim.max)
        .int("Daily grading limit must be a whole number.")
        .nullable(),
      min_app_version: z.string().trim().regex(SEMVER, "Use MAJOR.MINOR.PATCH, for example 1.2.0."),
      update_message: msg("Update message"),
      verify_base_url: z
        .string()
        .trim()
        .max(200, "Verify page URL can be at most 200 characters.")
        .regex(VERIFY_BASE_URL, "Use an https URL (http only for localhost or a LAN IP such as http://192.168.1.20:3000)."),
      maintenance: z.object({ enabled: z.boolean(), message: msg("Maintenance message") }),
      features: z.object(Object.fromEntries(FEATURE_KEYS.map((k) => [k, z.boolean()])) as Record<FeatureKey, z.ZodBoolean>),
      gates: z.object(gates),
    })
    .superRefine((v, ctx) => {
      if (v.gates.hue_min >= v.gates.hue_max) {
        ctx.addIssue({ code: "custom", path: ["gates", "hue_max"], message: "Maximum hue must be above the minimum hue." });
      }
      if (v.gates.ood_warn >= v.gates.ood_reject) {
        ctx.addIssue({ code: "custom", path: ["gates", "ood_reject"], message: "Reject distance must be above the warn distance." });
      }
      if (v.maintenance.enabled && !v.maintenance.message.trim()) {
        ctx.addIssue({ code: "custom", path: ["maintenance", "message"], message: "Enter the message users see during maintenance." });
      }
    });
}

export function configToForm(c: AdminConfig): ConfigFormValues {
  return {
    referral_threshold_default: c.referral_threshold_default,
    calibration_validity_hours: c.calibration_validity_hours,
    daily_grading_limit_default: c.daily_grading_limit_default ?? null,
    min_app_version: c.min_app_version,
    update_message: c.update_message ?? "",
    verify_base_url: c.verify_base_url ?? "",
    maintenance: { enabled: c.maintenance.enabled, message: c.maintenance.message ?? "" },
    features: { ...c.features },
    gates: { ...c.gates },
  };
}

export interface ConfigChange {
  /** Dotted path, the same as the form field and the server field. */
  path: string;
  label: string;
  before: ConfigValue;
  after: ConfigValue;
}

export type ConfigValue = string | number | boolean | null;

const TOP_LABELS = {
  referral_threshold_default: "Referral threshold default",
  calibration_validity_hours: "Calibration validity (hours)",
  daily_grading_limit_default: "Daily grading limit default",
  min_app_version: "Minimum app version",
  update_message: "Update message",
  verify_base_url: "Verify page base URL",
} as const;

/** Every field that differs between the saved config and the form (old -> new). */
export function configDiff(before: ConfigFormValues, after: ConfigFormValues): ConfigChange[] {
  const out: ConfigChange[] = [];
  const add = (path: string, label: string, a: ConfigValue, b: ConfigValue) => {
    const same = typeof a === "string" && typeof b === "string" ? a.trim() === b.trim() : a === b;
    if (!same) out.push({ path, label, before: a, after: typeof b === "string" ? b.trim() : b });
  };
  for (const k of Object.keys(TOP_LABELS) as (keyof typeof TOP_LABELS)[]) add(k, TOP_LABELS[k], before[k], after[k]);
  add("maintenance.enabled", "Maintenance mode", before.maintenance.enabled, after.maintenance.enabled);
  add("maintenance.message", "Maintenance message", before.maintenance.message, after.maintenance.message);
  for (const k of FEATURE_KEYS) add(`features.${k}`, FEATURE_LABELS[k], before.features[k], after.features[k]);
  for (const k of GATE_KEYS) add(`gates.${k}`, GATE_LABELS[k], before.gates[k], after.gates[k]);
  return out;
}

/** Partial PUT /admin/config body with only the changed fields (the server merges nested objects). */
export function configPatch(changes: ConfigChange[]): Record<string, unknown> {
  const body: Record<string, unknown> = {};
  for (const c of changes) {
    const [head, sub] = c.path.split(".");
    if (sub) body[head] = { ...((body[head] as Record<string, unknown>) ?? {}), [sub]: c.after };
    else body[head] = c.after;
  }
  return body;
}

/** True when the change turns maintenance mode on (needs the typed confirm). */
export function turnsMaintenanceOn(changes: ConfigChange[]): boolean {
  return changes.some((c) => c.path === "maintenance.enabled" && c.after === true);
}

export function gateChanged(cfg: Pick<AdminConfig, "gate_defaults">, key: GateKey, value: number): boolean {
  return value !== cfg.gate_defaults[key];
}

/** Form field for a server field error. Inconsistent gates have no field; they go on the upper bound. */
export function serverFieldPaths(err: { code: string; fields: { field: string; message: string }[] }) {
  if (err.code === "invalid_gates") {
    return [
      { field: "gates.hue_max", message: "Maximum hue must be above the minimum hue." },
      { field: "gates.ood_reject", message: "Reject distance must be above the warn distance." },
    ];
  }
  return err.fields.filter((f) => f.field);
}

export function fmtConfigValue(v: ConfigValue): string {
  if (v === null) return "No limit";
  if (typeof v === "boolean") return v ? "On" : "Off";
  if (typeof v === "string") return v === "" ? "(empty)" : v;
  return String(v);
}
