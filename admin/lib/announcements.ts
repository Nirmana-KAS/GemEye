import { format } from "date-fns";
import { z } from "zod";

import type { Announcement, AnnouncementBody, AppAction } from "./types";

export const TITLE_MAX = 80;
export const BODY_MAX = 500;

export type AnnouncementStatus = "draft" | "scheduled" | "active" | "expired";

export const STATUS_LABELS: Record<AnnouncementStatus, string> = {
  draft: "Draft",
  scheduled: "Scheduled",
  active: "Active",
  expired: "Expired",
};

/** In-app screens a banner or notification can open (the app's AppNotificationAction). */
export const ACTION_OPTIONS: { value: AppAction; label: string }[] = [
  { value: "none", label: "No link" },
  { value: "openCapture", label: "Grade a stone (Capture)" },
  { value: "openCalibration", label: "Calibration" },
  { value: "openHistory", label: "Grading history" },
  { value: "openPrivacy", label: "Privacy policy" },
  { value: "openResult", label: "A grading result (needs a stone ID)" },
];

function time(v: string | Date): number {
  if (v instanceof Date) return v.getTime();
  return new Date(v.endsWith("Z") || /[+-]\d\d:\d\d$/.test(v) ? v : `${v}Z`).getTime();
}

/** Status shown in the dashboard: inactive = draft, otherwise by the time window. */
export function announcementStatus(
  a: Pick<Announcement, "active" | "starts_at" | "ends_at">,
  now: Date = new Date(),
): AnnouncementStatus {
  if (!a.active) return "draft";
  const t = now.getTime();
  if (time(a.starts_at) > t) return "scheduled";
  if (time(a.ends_at) < t) return "expired";
  return "active";
}

export const announcementFormSchema = z
  .object({
    title: z.string().trim().min(1, "Enter a title.").max(TITLE_MAX, `The title can be at most ${TITLE_MAX} characters.`),
    message: z.string().trim().min(1, "Enter the message.").max(BODY_MAX, `The message can be at most ${BODY_MAX} characters.`),
    level: z.enum(["info", "warning"]),
    /** datetime-local value; empty = starts now. */
    starts_at: z.string(),
    ends_at: z.string().min(1, "Choose when it ends."),
    action: z.enum(["none", "openResult", "openCalibration", "openCapture", "openHistory", "openPrivacy"]),
    active: z.boolean(),
    notify: z.boolean(),
  })
  .superRefine((v, ctx) => {
    const start = v.starts_at ? new Date(v.starts_at).getTime() : Date.now();
    const end = new Date(v.ends_at).getTime();
    if (v.starts_at && Number.isNaN(start)) ctx.addIssue({ code: "custom", path: ["starts_at"], message: "Invalid start time." });
    if (Number.isNaN(end)) ctx.addIssue({ code: "custom", path: ["ends_at"], message: "Invalid end time." });
    else if (!Number.isNaN(start) && end <= start) {
      ctx.addIssue({ code: "custom", path: ["ends_at"], message: "The end must be after the start." });
    }
  });

export type AnnouncementFormValues = z.infer<typeof announcementFormSchema>;

/** ISO time -> datetime-local input value (local time). */
export function toLocalInput(iso: string | null | undefined): string {
  if (!iso) return "";
  const t = time(iso);
  return Number.isNaN(t) ? "" : format(t, "yyyy-MM-dd'T'HH:mm");
}

export function announcementDefaults(a?: Announcement | null, now: Date = new Date()): AnnouncementFormValues {
  if (a) {
    return {
      title: a.title,
      message: a.message,
      level: a.level,
      starts_at: toLocalInput(a.starts_at),
      ends_at: toLocalInput(a.ends_at),
      action: a.action ?? "none",
      active: a.active,
      notify: false,
    };
  }
  return {
    title: "",
    message: "",
    level: "info",
    starts_at: "",
    ends_at: format(now.getTime() + 7 * 24 * 3600 * 1000, "yyyy-MM-dd'T'HH:mm"),
    action: "none",
    active: true,
    notify: false,
  };
}

export function toAnnouncementBody(v: AnnouncementFormValues): AnnouncementBody {
  return {
    title: v.title.trim(),
    message: v.message.trim(),
    level: v.level,
    starts_at: v.starts_at ? new Date(v.starts_at).toISOString() : null,
    ends_at: new Date(v.ends_at).toISOString(),
    active: v.active,
    action: v.action,
  };
}
