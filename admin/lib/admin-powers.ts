import { z } from "zod";

import type { ActivityType, BulkAction, BulkResult } from "./types";

/** Same limits as the server (backend/app/admin_powers.py and limits.py). */
export const BULK_MAX = 200;
export const REASON_MAX = 500;
export const NOTE_MAX = 1000;
export const DAILY_LIMIT_BOUNDS = { min: 1, max: 500 } as const;

/** The typed confirm used by ConfirmDialog: trimmed, case-insensitive. */
export function confirmMatches(typed: string, expected: string): boolean {
  return typed.trim().toLowerCase() === expected.trim().toLowerCase();
}

// ---- Row selection on the Gradings table ----

export interface SelectionChange {
  next: Set<string>;
  /** True when some rows were not added because BULK_MAX was reached. */
  limited: boolean;
}

export function toggleRow(selected: ReadonlySet<string>, id: string, max = BULK_MAX): SelectionChange {
  const next = new Set(selected);
  if (next.has(id)) {
    next.delete(id);
    return { next, limited: false };
  }
  if (next.size >= max) return { next, limited: true };
  next.add(id);
  return { next, limited: false };
}

/** Header checkbox: clears the page when all its rows are selected, else adds them (up to max). */
export function togglePage(selected: ReadonlySet<string>, pageIds: string[], max = BULK_MAX): SelectionChange {
  const next = new Set(selected);
  if (pageIds.length > 0 && pageIds.every((id) => next.has(id))) {
    for (const id of pageIds) next.delete(id);
    return { next, limited: false };
  }
  let limited = false;
  for (const id of pageIds) {
    if (next.has(id)) continue;
    if (next.size >= max) {
      limited = true;
      break;
    }
    next.add(id);
  }
  return { next, limited };
}

export function pageState(selected: ReadonlySet<string>, pageIds: string[]): "none" | "some" | "all" {
  const n = pageIds.filter((id) => selected.has(id)).length;
  return n === 0 ? "none" : n === pageIds.length ? "all" : "some";
}

// ---- Confirm rules ----

export interface ConfirmSpec {
  title: string;
  description: string;
  confirmLabel: string;
  /** Text the admin must type (destructive actions only). */
  confirmText?: string;
  reasonLabel: string;
  reasonRequired: boolean;
  destructive: boolean;
}

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;

export function bulkConfirm(action: Exclude<BulkAction, "export">, count: number): ConfirmSpec {
  switch (action) {
    case "hide":
      return {
        title: `Hide ${plural(count, "grading")}?`,
        description: "They disappear from the users' History and stats. They stay in the database and can be restored.",
        confirmLabel: "Hide",
        confirmText: `HIDE ${count}`,
        reasonLabel: "Reason (required)",
        reasonRequired: true,
        destructive: true,
      };
    case "restore":
      return {
        title: `Restore ${plural(count, "grading")}?`,
        description: "They appear in the users' History again.",
        confirmLabel: "Restore",
        reasonLabel: "Reason (optional)",
        reasonRequired: false,
        destructive: false,
      };
    case "send_to_review":
      return {
        title: `Send ${plural(count, "grading")} to review?`,
        description: 'They appear in the Review queue with the reason "admin". Already reviewed stones are skipped.',
        confirmLabel: "Send to review",
        reasonLabel: "Note for the reviewer (optional)",
        reasonRequired: false,
        destructive: false,
      };
  }
}

/** Whether the confirm button of a reason + typed-text dialog may be pressed. */
export function canConfirm(spec: Pick<ConfirmSpec, "confirmText" | "reasonRequired">, reason: string, typed: string): boolean {
  if (reason.length > REASON_MAX) return false;
  if (spec.reasonRequired && !reason.trim()) return false;
  return !spec.confirmText || confirmMatches(typed, spec.confirmText);
}

const SKIP_REASONS: Record<string, string> = {
  not_found: "not found",
  already_hidden: "already hidden",
  not_hidden: "not hidden",
  already_reviewed: "already reviewed",
  already_in_queue: "already in the queue",
  not_gradable: "not a graded stone",
};

const DONE_VERBS: Record<BulkResult["action"], string> = {
  hide: "Hidden",
  restore: "Restored",
  send_to_review: "Sent to review",
};

export function bulkSummary(r: BulkResult): string {
  const head = `${DONE_VERBS[r.action]}: ${plural(r.done.length, "grading")}.`;
  if (!r.skipped.length) return head;
  const counts = new Map<string, number>();
  for (const s of r.skipped) counts.set(s.reason, (counts.get(s.reason) ?? 0) + 1);
  const parts = [...counts].map(([reason, n]) => `${n} ${SKIP_REASONS[reason] ?? reason}`);
  return `${head} Skipped ${parts.join(", ")}.`;
}

// ---- Daily limit and profile ----

/** "" = no own limit (null); otherwise a whole number within the bounds. */
export function parseDailyLimit(input: string): { ok: true; value: number | null } | { ok: false; message: string } {
  const t = input.trim();
  if (!t) return { ok: true, value: null };
  if (!/^\d+$/.test(t)) return { ok: false, message: "Enter a whole number, or leave empty for no limit." };
  const n = Number(t);
  if (n < DAILY_LIMIT_BOUNDS.min || n > DAILY_LIMIT_BOUNDS.max) {
    return { ok: false, message: `Use ${DAILY_LIMIT_BOUNDS.min} - ${DAILY_LIMIT_BOUNDS.max}, or leave empty.` };
  }
  return { ok: true, value: n };
}

/** The app's profile limits (PUT /me): name 100, phone 30, company name 200. Empty clears a field. */
export const profileSchema = z.object({
  display_name: z.string().trim().max(100, "Name can be at most 100 characters."),
  phone: z.string().trim().max(30, "Phone can be at most 30 characters."),
  company: z.string().trim().max(200, "Company name can be at most 200 characters."),
});

export type ProfileForm = z.infer<typeof profileSchema>;

/** Only the fields that changed (trimmed), for PATCH. */
export function profilePatch(before: ProfileForm, after: ProfileForm): Partial<ProfileForm> {
  const out: Partial<ProfileForm> = {};
  for (const k of Object.keys(before) as (keyof ProfileForm)[]) {
    if (after[k].trim() !== before[k].trim()) out[k] = after[k].trim();
  }
  return out;
}

// ---- Activity timeline ----

export const ACTIVITY_LABELS: Record<ActivityType, string> = {
  grading: "Grading",
  calibration: "Calibration",
  feedback: "Feedback",
  certificate: "Certificate",
  admin_action: "Admin action",
  account_created: "Account",
  signed_in: "Sign-in",
  last_active: "Last active",
};

export function activityLink(type: ActivityType, ref: string): string | null {
  if (type === "grading") return `/admin/gradings/detail/?id=${encodeURIComponent(ref)}`;
  if (type === "certificate") return `/admin/certificates/detail/?no=${encodeURIComponent(ref)}`;
  return null;
}
