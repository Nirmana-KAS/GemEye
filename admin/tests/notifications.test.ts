import { describe, expect, it } from "vitest";

import { fmtDateTime } from "@/lib/format";
import { notificationStatus } from "@/lib/notifications";

const T1 = "2026-10-15T08:30:00+00:00";
const T2 = "2026-10-16T09:45:00+00:00";

describe("notificationStatus", () => {
  it("is Visible when never cleared or restored", () => {
    expect(notificationStatus({ cleared_at: null, restored_at: null, restored_by_email: null })).toEqual({
      kind: "visible",
      label: "Visible",
    });
  });

  it("shows the clear time", () => {
    expect(notificationStatus({ cleared_at: T1, restored_at: null, restored_by_email: null })).toEqual({
      kind: "cleared",
      label: `Cleared ${fmtDateTime(T1)}`,
    });
  });

  it("shows restore time and admin email", () => {
    expect(notificationStatus({ cleared_at: null, restored_at: T2, restored_by_email: "a@x.com" })).toEqual({
      kind: "restored",
      label: `Restored ${fmtDateTime(T2)} by a@x.com`,
    });
    expect(notificationStatus({ cleared_at: null, restored_at: T2, restored_by_email: null }).label).toBe(
      `Restored ${fmtDateTime(T2)} by an admin`,
    );
  });

  it("is Cleared again when cleared after a restore", () => {
    expect(notificationStatus({ cleared_at: T2, restored_at: T1, restored_by_email: "a@x.com" }).kind).toBe("cleared");
  });
});
