import { z } from "zod";

import type { QueueReview, ReviewBody } from "./types";

export const NOTES_MAX = 500;

/** Review form: a true grade 1-7, or "unusable" (not a blue sapphire / unusable photo) with
 * no grade. Same limits as the server (POST /admin/reviews, PUT /admin/reviews/{id}). */
export const reviewFormSchema = z
  .object({
    gemologist_grade: z.number().int().min(1).max(7).nullable(),
    reviewer_confidence: z.enum(["low", "medium", "high"]).nullable(),
    unusable: z.boolean(),
    notes: z.string().max(NOTES_MAX, `Notes can be at most ${NOTES_MAX} characters.`),
  })
  .superRefine((v, ctx) => {
    if (!v.unusable && v.gemologist_grade == null) {
      ctx.addIssue({ code: "custom", path: ["gemologist_grade"], message: "Choose the true grade (1-7)." });
    }
  });

export type ReviewFormValues = z.infer<typeof reviewFormSchema>;

export const EMPTY_REVIEW: ReviewFormValues = {
  gemologist_grade: null,
  reviewer_confidence: null,
  unusable: false,
  notes: "",
};

/** Form values for an existing review (edit), or empty for a new one. */
export function reviewDefaults(review: QueueReview | null | undefined): ReviewFormValues {
  if (!review) return EMPTY_REVIEW;
  return {
    gemologist_grade: review.unusable ? null : review.gemologist_grade,
    reviewer_confidence: review.reviewer_confidence,
    unusable: review.unusable,
    notes: review.notes ?? "",
  };
}

/** Request body: unusable drops the grade, blank notes become null. */
export function toReviewBody(v: ReviewFormValues): ReviewBody {
  const notes = v.notes.trim();
  return {
    gemologist_grade: v.unusable ? null : v.gemologist_grade,
    reviewer_confidence: v.reviewer_confidence,
    unusable: v.unusable,
    notes: notes ? notes : null,
  };
}

/** Keyboard shortcut: "1"-"7" picks a grade; anything else is null. */
export function gradeFromKey(key: string): number | null {
  return /^[1-7]$/.test(key) ? Number(key) : null;
}

// ---- Agreement and confusion matrix (rows = model grade, columns = gemologist grade) ----

export interface AgreementSummary {
  n: number;
  exact: number;
  withinOne: number;
  exactRate: number | null;
  withinOneRate: number | null;
}

/** Exact and within-one-grade agreement from a 7x7 confusion matrix. */
export function agreementFromMatrix(m: number[][]): AgreementSummary {
  let n = 0;
  let exact = 0;
  let withinOne = 0;
  m.forEach((row, i) =>
    row.forEach((count, j) => {
      n += count;
      if (i === j) exact += count;
      if (Math.abs(i - j) <= 1) withinOne += count;
    }),
  );
  return {
    n,
    exact,
    withinOne,
    exactRate: n ? exact / n : null,
    withinOneRate: n ? withinOne / n : null,
  };
}

/** Same from (model grade, gemologist grade) pairs; pairs outside 1-7 are ignored. */
export function confusionMatrix(pairs: [number, number][]): number[][] {
  const m = Array.from({ length: 7 }, () => Array<number>(7).fill(0));
  for (const [model, gem] of pairs) {
    if (model >= 1 && model <= 7 && gem >= 1 && gem <= 7) m[model - 1][gem - 1] += 1;
  }
  return m;
}

/** Heatmap cell strength 0-1, relative to the row total (share of that model grade). */
export function cellShare(m: number[][], row: number, col: number): number {
  const total = m[row]?.reduce((a, b) => a + b, 0) ?? 0;
  return total ? (m[row][col] ?? 0) / total : 0;
}

export const REASON_LABELS: Record<string, string> = {
  low_confidence: "Low confidence",
  unusual_image: "Unusual image",
  referred: "Referred",
};

export function reasonLabel(code: string): string {
  return REASON_LABELS[code] ?? code.replace(/_/g, " ");
}
