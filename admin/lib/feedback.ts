import { addWeeks, format, parseISO, startOfWeek } from "date-fns";

import type { CertificateRow, CertificateStatus, FeedbackRow } from "./types";

export interface WeekPoint {
  /** Monday of the week, yyyy-MM-dd (local time). */
  week: string;
  count: number;
  avg_rating: number | null;
}

function toDate(v: string): Date {
  return parseISO(v.endsWith("Z") || /[+-]\d\d:\d\d$/.test(v) ? v : `${v}Z`);
}

/** Feedback per week (Monday start) and average rating, oldest first, with empty weeks filled. */
export function weeklyTrend(rows: Pick<FeedbackRow, "created_at" | "rating">[]): WeekPoint[] {
  const weeks = new Map<number, { n: number; sum: number; rated: number }>();
  for (const r of rows) {
    const d = toDate(r.created_at);
    if (Number.isNaN(d.getTime())) continue;
    const key = startOfWeek(d, { weekStartsOn: 1 }).getTime();
    const w = weeks.get(key) ?? { n: 0, sum: 0, rated: 0 };
    w.n += 1;
    if (typeof r.rating === "number") {
      w.sum += r.rating;
      w.rated += 1;
    }
    weeks.set(key, w);
  }
  if (!weeks.size) return [];
  const keys = [...weeks.keys()].sort((a, b) => a - b);
  const out: WeekPoint[] = [];
  for (let t = new Date(keys[0]); t.getTime() <= keys[keys.length - 1]; t = addWeeks(t, 1)) {
    const w = weeks.get(t.getTime());
    out.push({
      week: format(t, "yyyy-MM-dd"),
      count: w?.n ?? 0,
      avg_rating: w && w.rated ? Math.round((w.sum / w.rated) * 100) / 100 : null,
    });
  }
  return out;
}

/** Display status: a revoked certificate with a replacement is "superseded". */
export function certificateStatus(c: Pick<CertificateRow, "status" | "superseded_by">): CertificateStatus {
  if (c.status === "revoked" && c.superseded_by) return "superseded";
  return c.status;
}
