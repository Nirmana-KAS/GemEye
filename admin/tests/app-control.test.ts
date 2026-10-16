import { describe, expect, it } from "vitest";

import { announcementDefaults, announcementFormSchema, announcementStatus, toAnnouncementBody } from "@/lib/announcements";
import { errorFromResponse } from "@/lib/api";
import { auditDiff, targetText } from "@/lib/audit";
import {
  configDiff,
  configFormSchema,
  configPatch,
  configToForm,
  gateChanged,
  serverFieldPaths,
  turnsMaintenanceOn,
} from "@/lib/config";
import { certificateStatus, weeklyTrend } from "@/lib/feedback";
import { sendDefaults, sendFormSchema, toSendBody } from "@/lib/send-notification";
import type { AdminConfig } from "@/lib/types";

const CONFIG: AdminConfig = {
  referral_threshold_default: 0.6,
  calibration_validity_hours: 24,
  min_app_version: "1.0.0",
  update_message: "",
  maintenance: { enabled: false, message: "" },
  features: { repeatability_mode: true, gradcam: true, public_verification: true, session_mapping: false },
  verify_base_url: "https://gemeye-app-2026.web.app",
  gates: {
    blur_min_variance: 29.474166117400628,
    no_stone_min_area: 0.01571533203125,
    no_stone_min_contrast_de00: 5,
    hue_min: 170,
    hue_max: 265,
    min_chroma: 0.5,
    ood_warn: 20.648902893066406,
    ood_reject: 25.68535614013672,
  },
  gate_defaults: {
    blur_min_variance: 29.474166117400628,
    no_stone_min_area: 0.01571533203125,
    no_stone_min_contrast_de00: 5,
    hue_min: 170,
    hue_max: 265,
    min_chroma: 0.5,
    ood_warn: 20.648902893066406,
    ood_reject: 25.68535614013672,
  },
  gate_bounds: {
    blur_min_variance: { min: 5, max: 200 },
    no_stone_min_area: { min: 0.002, max: 0.05 },
    no_stone_min_contrast_de00: { min: 1, max: 15 },
    hue_min: { min: 100, max: 200 },
    hue_max: { min: 230, max: 320 },
    min_chroma: { min: 0, max: 5 },
    ood_warn: { min: 5, max: 60 },
    ood_reject: { min: 10, max: 80 },
  },
  bounds: {
    referral_threshold_default: { min: 0.4, max: 0.9 },
    calibration_validity_hours: { min: 1, max: 72 },
    message_max: 200,
  },
};

const schema = configFormSchema(CONFIG);
const base = configToForm(CONFIG);
const issuesAt = (v: unknown) => {
  const r = schema.safeParse(v);
  return r.success ? [] : r.error.issues.map((i) => i.path.join("."));
};

describe("config form bounds", () => {
  it("accepts the saved config and values on the bounds", () => {
    expect(issuesAt(base)).toEqual([]);
    expect(issuesAt({ ...base, referral_threshold_default: 0.4, calibration_validity_hours: 72 })).toEqual([]);
    expect(issuesAt({ ...base, gates: { ...base.gates, blur_min_variance: 200, min_chroma: 0 } })).toEqual([]);
  });

  it("rejects values outside the server bounds", () => {
    expect(issuesAt({ ...base, referral_threshold_default: 0.39 })).toEqual(["referral_threshold_default"]);
    expect(issuesAt({ ...base, referral_threshold_default: 0.91 })).toEqual(["referral_threshold_default"]);
    expect(issuesAt({ ...base, calibration_validity_hours: 0 })).toEqual(["calibration_validity_hours"]);
    expect(issuesAt({ ...base, calibration_validity_hours: 73 })).toEqual(["calibration_validity_hours"]);
    expect(issuesAt({ ...base, calibration_validity_hours: 2.5 })).toEqual(["calibration_validity_hours"]);
    expect(issuesAt({ ...base, gates: { ...base.gates, blur_min_variance: 4.9 } })).toEqual(["gates.blur_min_variance"]);
    expect(issuesAt({ ...base, gates: { ...base.gates, ood_reject: 81 } })).toEqual(["gates.ood_reject"]);
  });

  it("rejects empty numbers, bad versions, long messages and crossed gates", () => {
    expect(issuesAt({ ...base, gates: { ...base.gates, hue_min: Number.NaN } })).toEqual(["gates.hue_min"]);
    expect(issuesAt({ ...base, min_app_version: "1.0" })).toEqual(["min_app_version"]);
    expect(issuesAt({ ...base, min_app_version: "01.0.0" })).toEqual(["min_app_version"]);
    expect(issuesAt({ ...base, update_message: "x".repeat(201) })).toEqual(["update_message"]);
    expect(issuesAt({ ...base, gates: { ...base.gates, ood_warn: 30, ood_reject: 30 } })).toEqual(["gates.ood_reject"]);
    expect(issuesAt({ ...base, maintenance: { enabled: true, message: " " } })).toEqual(["maintenance.message"]);
  });
});

describe("config diff", () => {
  it("lists only changed fields with old and new values", () => {
    const after = {
      ...base,
      calibration_validity_hours: 12,
      maintenance: { enabled: true, message: "Back soon" },
      features: { ...base.features, gradcam: false },
      gates: { ...base.gates, hue_min: 165 },
    };
    const diff = configDiff(base, after);
    expect(diff.map((d) => [d.path, d.before, d.after])).toEqual([
      ["calibration_validity_hours", 24, 12],
      ["maintenance.enabled", false, true],
      ["maintenance.message", "", "Back soon"],
      ["features.gradcam", true, false],
      ["gates.hue_min", 170, 165],
    ]);
    expect(configPatch(diff)).toEqual({
      calibration_validity_hours: 12,
      maintenance: { enabled: true, message: "Back soon" },
      features: { gradcam: false },
      gates: { hue_min: 165 },
    });
    expect(turnsMaintenanceOn(diff)).toBe(true);
    expect(turnsMaintenanceOn(configDiff(after, base))).toBe(false);
  });

  it("ignores surrounding whitespace and finds no change in an untouched form", () => {
    expect(configDiff(base, configToForm(CONFIG))).toEqual([]);
    expect(configDiff(base, { ...base, update_message: "  " })).toEqual([]);
  });

  it("flags gates that differ from the default", () => {
    expect(gateChanged(CONFIG, "hue_min", 170)).toBe(false);
    expect(gateChanged(CONFIG, "hue_min", 171)).toBe(true);
  });

  it("maps server errors to form fields", () => {
    const err = errorFromResponse(400, { detail: "Invalid request.", fields: [{ field: "gates.hue_min", message: "too low" }, { bad: 1 }] });
    expect(serverFieldPaths(err)).toEqual([{ field: "gates.hue_min", message: "too low" }]);
    const gates = errorFromResponse(400, { code: "invalid_gates", message: "Gate values are inconsistent" });
    expect(serverFieldPaths(gates).map((f) => f.field)).toEqual(["gates.hue_max", "gates.ood_reject"]);
  });
});

describe("announcement status", () => {
  const now = new Date("2026-10-16T12:00:00Z");
  const a = (active: boolean, start: string, end: string) => ({ active, starts_at: start, ends_at: end });

  it("maps active flag and time window to draft/scheduled/active/expired", () => {
    expect(announcementStatus(a(false, "2026-10-16T10:00:00Z", "2026-10-17T00:00:00Z"), now)).toBe("draft");
    expect(announcementStatus(a(true, "2026-10-16T13:00:00Z", "2026-10-17T00:00:00Z"), now)).toBe("scheduled");
    expect(announcementStatus(a(true, "2026-10-15T00:00:00Z", "2026-10-16T11:59:00Z"), now)).toBe("expired");
    expect(announcementStatus(a(true, "2026-10-16T10:00:00Z", "2026-10-17T00:00:00Z"), now)).toBe("active");
    // Server datetimes may come without a zone (UTC).
    expect(announcementStatus(a(true, "2026-10-16T10:00:00", "2026-10-16T12:30:00"), now)).toBe("active");
  });

  it("validates the form and builds the request body", () => {
    const ok = { ...announcementDefaults(null, now), title: " Hello ", message: "World", ends_at: "2026-10-20T10:00" };
    expect(announcementFormSchema.safeParse(ok).success).toBe(true);
    expect(announcementFormSchema.safeParse({ ...ok, title: "x".repeat(81) }).success).toBe(false);
    expect(announcementFormSchema.safeParse({ ...ok, message: "x".repeat(501) }).success).toBe(false);
    expect(announcementFormSchema.safeParse({ ...ok, starts_at: "2026-10-21T10:00" }).success).toBe(false);
    const body = toAnnouncementBody(ok);
    expect(body.title).toBe("Hello");
    expect(body.starts_at).toBeNull();
    expect(body.ends_at).toBe(new Date("2026-10-20T10:00").toISOString());
  });
});

describe("send notification form", () => {
  const filled = { ...sendDefaults(), title: "Update", message: "Please update the app." };

  it("accepts a send to all and drops empty optional fields", () => {
    expect(sendFormSchema.safeParse(filled).success).toBe(true);
    expect(toSendBody(filled)).toEqual({ target: "all", type: "info", title: "Update", message: "Please update the app.", action: "none" });
  });

  it("needs a user for target user and sends its uid", () => {
    const r = sendFormSchema.safeParse({ ...filled, target: "user" });
    expect(r.success).toBe(false);
    expect(r.error?.issues[0].path).toEqual(["email"]);
    const user = { ...sendDefaults({ uid: "u1", email: "a@b.c" }), title: "T", message: "M", category: "certificate" as const };
    expect(sendFormSchema.safeParse(user).success).toBe(true);
    expect(toSendBody(user)).toMatchObject({ target: "user", uid: "u1", category: "certificate" });
  });

  it("enforces the server limits", () => {
    for (const bad of [
      { ...filled, title: "" },
      { ...filled, title: "   " },
      { ...filled, title: "x".repeat(121) },
      { ...filled, message: "x".repeat(1001) },
      { ...filled, payload: "x".repeat(201) },
      { ...filled, type: "fatal" },
      { ...filled, action: "openSettings" },
      { ...filled, action: "openResult", payload: "" },
    ]) {
      expect(sendFormSchema.safeParse(bad).success).toBe(false);
    }
    expect(sendFormSchema.safeParse({ ...filled, title: "x".repeat(120), message: "y".repeat(1000) }).success).toBe(true);
  });
});

describe("feedback, certificates and audit helpers", () => {
  it("groups feedback per Monday week with average rating and fills empty weeks", () => {
    const t = weeklyTrend([
      { created_at: "2026-10-05T10:00:00", rating: 5 },
      { created_at: "2026-10-06T10:00:00", rating: 2 },
      { created_at: "2026-10-20T10:00:00", rating: null },
    ]);
    expect(t.map((p) => [p.week, p.count, p.avg_rating])).toEqual([
      ["2026-10-05", 2, 3.5],
      ["2026-10-12", 0, null],
      ["2026-10-19", 1, null],
    ]);
    expect(weeklyTrend([])).toEqual([]);
  });

  it("shows a revoked certificate with a replacement as superseded", () => {
    expect(certificateStatus({ status: "revoked", superseded_by: "GE-202610-00002" })).toBe("superseded");
    expect(certificateStatus({ status: "revoked", superseded_by: null })).toBe("revoked");
    expect(certificateStatus({ status: "valid", superseded_by: null })).toBe("valid");
  });

  it("flattens before/after into changed rows", () => {
    const d = auditDiff({ gates: { hue_min: 170, hue_max: 265 } }, { gates: { hue_min: 165, hue_max: 265 } });
    expect(d).toEqual([
      { key: "gates.hue_max", before: "265", after: "265", changed: false },
      { key: "gates.hue_min", before: "170", after: "165", changed: true },
    ]);
    expect(auditDiff(null, { status: "revoked" })).toEqual([{ key: "status", before: "-", after: "revoked", changed: true }]);
    expect(targetText({ cert_no: "GE-202610-00001" })).toBe("cert_no: GE-202610-00001");
  });
});
