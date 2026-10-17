import { describe, expect, it } from "vitest";

import {
  BULK_MAX,
  activityLink,
  bulkConfirm,
  bulkSummary,
  canConfirm,
  confirmMatches,
  pageState,
  parseDailyLimit,
  profilePatch,
  profileSchema,
  toggleRow,
  togglePage,
} from "@/lib/admin-powers";
import { configDiff, configPatch, fmtConfigValue } from "@/lib/config";
import type { ConfigFormValues } from "@/lib/config";

const ids = (n: number, prefix = "g") => Array.from({ length: n }, (_, i) => `${prefix}${i}`);

describe("row selection", () => {
  it("toggles one row on and off", () => {
    const a = toggleRow(new Set(), "g1");
    expect([...a.next]).toEqual(["g1"]);
    expect(a.limited).toBe(false);
    expect(toggleRow(a.next, "g1").next.size).toBe(0);
  });

  it("never selects more than 200 rows", () => {
    const full = new Set(ids(BULK_MAX));
    const r = toggleRow(full, "extra");
    expect(r.limited).toBe(true);
    expect(r.next.size).toBe(BULK_MAX);
    expect(r.next.has("extra")).toBe(false);
    // Unselecting still works at the limit.
    expect(toggleRow(full, "g0").next.size).toBe(BULK_MAX - 1);
  });

  it("header checkbox selects the page, then clears it", () => {
    const page = ids(25);
    const on = togglePage(new Set(["other"]), page);
    expect(on.next.size).toBe(26);
    expect(pageState(on.next, page)).toBe("all");
    const off = togglePage(on.next, page);
    expect([...off.next]).toEqual(["other"]);
    expect(pageState(off.next, page)).toBe("none");
  });

  it("header checkbox fills up to the limit and reports it", () => {
    const r = togglePage(new Set(ids(190, "x")), ids(25));
    expect(r.next.size).toBe(BULK_MAX);
    expect(r.limited).toBe(true);
    expect(pageState(r.next, ids(25))).toBe("some");
  });

  it("a partly selected page is selected fully, not cleared", () => {
    const r = togglePage(new Set(["g0"]), ids(3));
    expect(pageState(r.next, ids(3))).toBe("all");
    expect(pageState(new Set(), [])).toBe("none");
  });
});

describe("confirm logic", () => {
  it("typed confirm is trimmed and case-insensitive", () => {
    expect(confirmMatches("  hide 3 ", "HIDE 3")).toBe(true);
    expect(confirmMatches("HIDE 4", "HIDE 3")).toBe(false);
    expect(confirmMatches("", "abc")).toBe(false);
  });

  it("bulk hide needs a reason and the typed count; restore and review do not", () => {
    const hide = bulkConfirm("hide", 12);
    expect(hide.confirmText).toBe("HIDE 12");
    expect(hide.reasonRequired && hide.destructive).toBe(true);
    expect(hide.title).toBe("Hide 12 gradings?");
    expect(bulkConfirm("hide", 1).title).toBe("Hide 1 grading?");
    expect(canConfirm(hide, "", "HIDE 12")).toBe(false);
    expect(canConfirm(hide, "  ", "HIDE 12")).toBe(false);
    expect(canConfirm(hide, "Spam", "HIDE 11")).toBe(false);
    expect(canConfirm(hide, "Spam", "hide 12")).toBe(true);
    for (const a of ["restore", "send_to_review"] as const) {
      const s = bulkConfirm(a, 5);
      expect(s.confirmText).toBeUndefined();
      expect(canConfirm(s, "", "")).toBe(true);
    }
  });

  it("a reason over 500 characters is refused", () => {
    expect(canConfirm({ reasonRequired: false }, "r".repeat(501), "")).toBe(false);
    expect(canConfirm({ reasonRequired: true }, "r".repeat(500), "")).toBe(true);
  });

  it("permanent delete: the grading id must be typed exactly", () => {
    const spec = { confirmText: "a1b2c3", reasonRequired: true };
    expect(canConfirm(spec, "Privacy request", "a1b2c")).toBe(false);
    expect(canConfirm(spec, "Privacy request", "a1b2c3")).toBe(true);
    expect(canConfirm(spec, "", "a1b2c3")).toBe(false);
  });

  it("summarises a bulk result with skip reasons", () => {
    expect(bulkSummary({ action: "hide", requested: 2, done: ["a", "b"], skipped: [] })).toBe("Hidden: 2 gradings.");
    expect(
      bulkSummary({
        action: "send_to_review",
        requested: 4,
        done: ["a"],
        skipped: [
          { id: "b", reason: "already_reviewed" },
          { id: "c", reason: "already_reviewed" },
          { id: "d", reason: "not_found" },
        ],
      }),
    ).toBe("Sent to review: 1 grading. Skipped 2 already reviewed, 1 not found.");
  });
});

describe("daily limit and profile", () => {
  it("parses the daily limit input", () => {
    expect(parseDailyLimit("")).toEqual({ ok: true, value: null });
    expect(parseDailyLimit(" 25 ")).toEqual({ ok: true, value: 25 });
    expect(parseDailyLimit("1")).toEqual({ ok: true, value: 1 });
    expect(parseDailyLimit("500")).toEqual({ ok: true, value: 500 });
    for (const bad of ["0", "501", "2.5", "-3", "abc"]) expect(parseDailyLimit(bad).ok).toBe(false);
  });

  it("profile form uses the app limits and sends only changes", () => {
    const before = { display_name: "Nimal", phone: "", company: "Orava" };
    expect(profileSchema.safeParse({ ...before, phone: "1".repeat(31) }).success).toBe(false);
    expect(profileSchema.safeParse({ ...before, display_name: "n".repeat(101) }).success).toBe(false);
    expect(profileSchema.safeParse({ ...before, company: "c".repeat(201) }).success).toBe(false);
    expect(profilePatch(before, { ...before, phone: " +94 77 1234567 ", company: "Orava " })).toEqual({ phone: "+94 77 1234567" });
    expect(profilePatch(before, { ...before, company: "" })).toEqual({ company: "" });
  });

  it("links activity rows to gradings and certificates", () => {
    expect(activityLink("grading", "g 1")).toBe("/admin/gradings/detail/?id=g%201");
    expect(activityLink("certificate", "GE-202610-00001")).toBe("/admin/certificates/detail/?no=GE-202610-00001");
    expect(activityLink("feedback", "f1")).toBeNull();
  });

  it("config diff sends null to clear the default daily limit", () => {
    const base = { daily_grading_limit_default: 20 } as ConfigFormValues;
    const changes = configDiff(
      { ...base, maintenance: { enabled: false, message: "" }, features: {}, gates: {} } as unknown as ConfigFormValues,
      { ...base, daily_grading_limit_default: null, maintenance: { enabled: false, message: "" }, features: {}, gates: {} } as unknown as ConfigFormValues,
    );
    const limit = changes.filter((c) => c.path === "daily_grading_limit_default");
    expect(limit).toHaveLength(1);
    expect(configPatch(limit)).toEqual({ daily_grading_limit_default: null });
    expect(fmtConfigValue(null)).toBe("No limit");
  });
});
