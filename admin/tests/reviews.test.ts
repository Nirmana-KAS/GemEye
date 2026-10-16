import { describe, expect, it } from "vitest";

import { agreementBars, compareVersions, perDaySeries, rejectionStack, seriesEmpty } from "@/lib/monitoring";
import {
  agreementFromMatrix,
  cellShare,
  confusionMatrix,
  EMPTY_REVIEW,
  gradeFromKey,
  reviewDefaults,
  reviewFormSchema,
  toReviewBody,
} from "@/lib/reviews";
import type { MonitoringDay, MonitoringVersion } from "@/lib/types";

describe("review form schema", () => {
  it("accepts a grade 1-7 with optional confidence and notes", () => {
    for (const g of [1, 4, 7]) {
      expect(reviewFormSchema.safeParse({ ...EMPTY_REVIEW, gemologist_grade: g }).success).toBe(true);
    }
    expect(
      reviewFormSchema.safeParse({ gemologist_grade: 3, reviewer_confidence: "high", unusable: false, notes: "ok" }).success,
    ).toBe(true);
  });

  it("rejects grades outside 1-7, decimals and a missing grade", () => {
    for (const g of [0, 8, 2.5]) {
      expect(reviewFormSchema.safeParse({ ...EMPTY_REVIEW, gemologist_grade: g }).success).toBe(false);
    }
    const missing = reviewFormSchema.safeParse(EMPTY_REVIEW);
    expect(missing.success).toBe(false);
    expect(missing.error?.issues[0].path).toEqual(["gemologist_grade"]);
  });

  it("allows unusable without a grade", () => {
    expect(reviewFormSchema.safeParse({ ...EMPTY_REVIEW, unusable: true }).success).toBe(true);
  });

  it("limits notes to 500 characters and rejects an unknown confidence", () => {
    const base = { ...EMPTY_REVIEW, gemologist_grade: 2 };
    expect(reviewFormSchema.safeParse({ ...base, notes: "n".repeat(500) }).success).toBe(true);
    expect(reviewFormSchema.safeParse({ ...base, notes: "n".repeat(501) }).success).toBe(false);
    expect(reviewFormSchema.safeParse({ ...base, reviewer_confidence: "sure" }).success).toBe(false);
  });

  it("builds the request body", () => {
    expect(toReviewBody({ gemologist_grade: 5, reviewer_confidence: "low", unusable: false, notes: "  hi " })).toEqual({
      gemologist_grade: 5,
      reviewer_confidence: "low",
      unusable: false,
      notes: "hi",
    });
    expect(toReviewBody({ gemologist_grade: 5, reviewer_confidence: null, unusable: true, notes: "   " })).toEqual({
      gemologist_grade: null,
      reviewer_confidence: null,
      unusable: true,
      notes: null,
    });
  });

  it("prefills an existing review", () => {
    expect(reviewDefaults(null)).toEqual(EMPTY_REVIEW);
    expect(
      reviewDefaults({
        gemologist_grade: 3,
        reviewer_confidence: "medium",
        notes: null,
        agrees: true,
        unusable: false,
        reviewed_at: null,
        mine: true,
      }),
    ).toEqual({ gemologist_grade: 3, reviewer_confidence: "medium", unusable: false, notes: "" });
  });

  it("maps keys 1-7 to grades", () => {
    expect(gradeFromKey("1")).toBe(1);
    expect(gradeFromKey("7")).toBe(7);
    expect(gradeFromKey("8")).toBeNull();
    expect(gradeFromKey("0")).toBeNull();
    expect(gradeFromKey("Enter")).toBeNull();
  });
});

describe("agreement and confusion helpers", () => {
  it("builds a 7x7 matrix with rows = model grade", () => {
    const m = confusionMatrix([
      [3, 3],
      [4, 5],
      [5, 7],
      [2, 2],
      [9, 1],
    ]);
    expect(m).toHaveLength(7);
    expect(m[2][2]).toBe(1);
    expect(m[3][4]).toBe(1);
    expect(m[4][6]).toBe(1);
    expect(m.flat().reduce((a, b) => a + b, 0)).toBe(4);
  });

  it("computes exact and within-one agreement", () => {
    // Same data as the server test: exact 1, within one 2, n 3.
    const a = agreementFromMatrix(confusionMatrix([[3, 3], [4, 5], [5, 7]]));
    expect(a).toMatchObject({ n: 3, exact: 1, withinOne: 2 });
    expect(a.exactRate).toBeCloseTo(1 / 3);
    expect(a.withinOneRate).toBeCloseTo(2 / 3);
  });

  it("returns null rates for no reviews", () => {
    expect(agreementFromMatrix(confusionMatrix([]))).toEqual({ n: 0, exact: 0, withinOne: 0, exactRate: null, withinOneRate: null });
  });

  it("shades cells by share of the model-grade row", () => {
    const m = confusionMatrix([[4, 4], [4, 4], [4, 5], [4, 3]]);
    expect(cellShare(m, 3, 3)).toBe(0.5);
    expect(cellShare(m, 3, 4)).toBe(0.25);
    expect(cellShare(m, 0, 0)).toBe(0);
  });
});

function day(d: string, extra: Partial<MonitoringDay> = {}): MonitoringDay {
  return {
    day: d,
    count: 0,
    mean_confidence: null,
    mean_uncertainty: null,
    referral_rate: null,
    unusual_image: 0,
    mean_latency_ms: null,
    p95_latency_ms: null,
    rejections: 0,
    rejections_by_gate: {},
    rejection_rate: null,
    ...extra,
  };
}

function version(v: string, days: MonitoringDay[], reviews = { reviewed: 0, agreed: 0, within_one: 0 }): MonitoringVersion {
  const rate = (k: number) => (reviews.reviewed ? k / reviews.reviewed : null);
  return {
    model_version: v,
    days,
    review_agreement: [],
    summary: {
      gradings: 0,
      referred: 0,
      referral_rate: null,
      avg_confidence: null,
      avg_uncertainty: null,
      unusual_image: 0,
      unusual_image_rate: null,
      rejections: 0,
      rejections_by_gate: {},
      rejection_rate: null,
      avg_latency_ms: null,
      p95_latency_ms: null,
      first_seen: null,
      last_seen: null,
      reviews: { ...reviews, agreement_rate: rate(reviews.agreed), within_one_rate: rate(reviews.within_one) },
    },
  };
}

describe("monitoring helpers", () => {
  const keys = ["2026-10-14", "2026-10-15"];
  const v3 = version("v3", [day(keys[0], { mean_confidence: 0.8, rejections_by_gate: { blurry: 2 } }), day(keys[1])], {
    reviewed: 4,
    agreed: 2,
    within_one: 4,
  });
  const v5 = version("v5", [day(keys[0]), day(keys[1], { mean_confidence: 0.9, rejections_by_gate: { blurry: 1, not_blue: 3 } })]);

  it("orders versions naturally with unknown last", () => {
    expect(["unknown", "v10", "v5", "v3"].sort(compareVersions)).toEqual(["v3", "v5", "v10", "unknown"]);
  });

  it("puts one column per version on every day", () => {
    const rows = perDaySeries([v3, v5], keys, (d) => d.mean_confidence);
    expect(rows).toEqual([
      { day: keys[0], v3: 0.8, v5: null },
      { day: keys[1], v3: null, v5: 0.9 },
    ]);
    expect(seriesEmpty(rows, ["v3", "v5"])).toBe(false);
    expect(seriesEmpty(perDaySeries([v3], keys, (d) => d.p95_latency_ms), ["v3"])).toBe(true);
  });

  it("stacks rejections by gate across versions", () => {
    const { rows, gates } = rejectionStack([v3, v5], keys);
    expect(gates).toEqual(["blurry", "not_blue"]);
    expect(rows).toEqual([
      { day: keys[0], blurry: 2, not_blue: 0 },
      { day: keys[1], blurry: 1, not_blue: 3 },
    ]);
  });

  it("reports agreement per version", () => {
    expect(agreementBars([v3, v5])).toEqual([
      { model_version: "v3", reviewed: 4, exact: 0.5, within_one: 1 },
      { model_version: "v5", reviewed: 0, exact: null, within_one: null },
    ]);
  });
});
