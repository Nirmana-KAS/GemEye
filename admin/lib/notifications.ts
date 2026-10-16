import { fmtDateTime } from "./format";
import type { AdminNotification } from "./types";

export type NotificationStatusKind = "visible" | "cleared" | "restored";

/** Status chip of a user's notification: cleared wins (it may be cleared again after a
 * restore), then restored, otherwise visible. */
export function notificationStatus(
  n: Pick<AdminNotification, "cleared_at" | "restored_at" | "restored_by_email">,
): { kind: NotificationStatusKind; label: string } {
  if (n.cleared_at) return { kind: "cleared", label: `Cleared ${fmtDateTime(n.cleared_at)}` };
  if (n.restored_at) {
    return {
      kind: "restored",
      label: `Restored ${fmtDateTime(n.restored_at)} by ${n.restored_by_email ?? "an admin"}`,
    };
  }
  return { kind: "visible", label: "Visible" };
}
