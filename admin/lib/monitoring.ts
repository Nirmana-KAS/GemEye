import type { MonitoringDay, MonitoringVersion } from "./types";

/** Natural order (v3 before v5 before v10); "unknown" last. */
export function compareVersions(a: string, b: string): number {
  if (a === b) return 0;
  if (a === "unknown") return 1;
  if (b === "unknown") return -1;
  return a.localeCompare(b, undefined, { numeric: true });
}

export function sortVersions(versions: MonitoringVersion[]): MonitoringVersion[] {
  return [...versions].sort((a, b) => compareVersions(a.model_version, b.model_version));
}

export type DayRow = { day: string } & Record<string, number | string | null>;

/** One row per day with one column per model version, for multi-line charts. */
export function perDaySeries(
  versions: MonitoringVersion[],
  dayKeys: string[],
  pick: (d: MonitoringDay) => number | null,
): DayRow[] {
  return dayKeys.map((day) => {
    const row: DayRow = { day };
    for (const v of versions) {
      const d = v.days.find((x) => x.day === day);
      row[v.model_version] = d ? pick(d) : null;
    }
    return row;
  });
}

/** Rejections per day stacked by gate (all selected versions together), zero-filled. */
export function rejectionStack(versions: MonitoringVersion[], dayKeys: string[]): { rows: DayRow[]; gates: string[] } {
  const gates = [...new Set(versions.flatMap((v) => v.days.flatMap((d) => Object.keys(d.rejections_by_gate))))].sort();
  const rows = dayKeys.map((day) => {
    const row: DayRow = { day };
    for (const g of gates) row[g] = 0;
    for (const v of versions) {
      const d = v.days.find((x) => x.day === day);
      for (const [g, n] of Object.entries(d?.rejections_by_gate ?? {})) row[g] = (row[g] as number) + n;
    }
    return row;
  });
  return { rows, gates };
}

/** Exact and within-one agreement (percent) per version, for the bar chart. */
export function agreementBars(versions: MonitoringVersion[]) {
  return versions.map((v) => ({
    model_version: v.model_version,
    reviewed: v.summary.reviews.reviewed,
    exact: v.summary.reviews.agreement_rate,
    within_one: v.summary.reviews.within_one_rate,
  }));
}

/** True when every value of the chosen field is empty (null or 0) on every day. */
export function seriesEmpty(rows: DayRow[], keys: string[]): boolean {
  return rows.every((r) => keys.every((k) => r[k] == null || r[k] === 0));
}
