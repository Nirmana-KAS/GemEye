"use client";

import { useQuery } from "@tanstack/react-query";

import { useApi } from "@/components/auth-provider";
import { GradeChip } from "@/components/grade-chip";
import { ErrorState } from "@/components/states";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fmtPct } from "@/lib/format";
import { GRADES } from "@/lib/grades";
import { agreementFromMatrix, cellShare } from "@/lib/reviews";
import type { ReviewStats } from "@/lib/types";

function Stat({ label, value, sub }: { label: string; value: React.ReactNode; sub?: string }) {
  return (
    <div className="rounded-lg border p-3">
      <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</p>
      <p className="mt-1 text-xl font-semibold tabular-nums">{value}</p>
      {sub && <p className="text-xs text-muted-foreground">{sub}</p>}
    </div>
  );
}

/** Confusion matrix as a heatmap: rows = model grade, columns = gemologist grade, shaded by
 * the share of that model grade; the diagonal is exact agreement. */
function ConfusionHeatmap({ counts }: { counts: number[][] }) {
  const a = agreementFromMatrix(counts);
  return (
    <div className="overflow-x-auto">
      <table className="border-separate border-spacing-1 text-xs">
        <thead>
          <tr>
            <th className="pr-2 text-left font-medium text-muted-foreground">Model \ Gemologist</th>
            {GRADES.map((g) => (
              <th key={g.grade} className="w-10 text-center">
                <GradeChip grade={g.grade} />
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {GRADES.map((g, i) => (
            <tr key={g.grade}>
              <th className="pr-2 text-left">
                <GradeChip grade={g.grade} />
              </th>
              {GRADES.map((_, j) => {
                const n = counts[i]?.[j] ?? 0;
                const share = cellShare(counts, i, j);
                return (
                  <td
                    key={j}
                    title={`Model ${i + 1}, gemologist ${j + 1}: ${n}`}
                    className={`h-9 w-10 rounded-md text-center tabular-nums ${i === j ? "ring-1 ring-primary/40" : ""}`}
                    style={{
                      backgroundColor: n ? `color-mix(in oklch, var(--primary) ${Math.round(15 + share * 75)}%, transparent)` : undefined,
                      color: share > 0.5 ? "var(--primary-foreground)" : undefined,
                    }}
                  >
                    {n || <span className="text-muted-foreground/50">0</span>}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
      <p className="mt-2 text-xs text-muted-foreground">
        Diagonal {a.exact}/{a.n} exact, {a.withinOne}/{a.n} within one grade. Shading is the share of each model grade row.
      </p>
    </div>
  );
}

export function ReviewStatsCard() {
  const api = useApi();
  const stats = useQuery({ queryKey: ["review-stats"], queryFn: () => api<ReviewStats>("/admin/reviews/stats") });
  const s = stats.data;
  return (
    <Card className="mb-6">
      <CardHeader>
        <CardTitle className="text-base">Review statistics</CardTitle>
        <CardDescription>All gemologist reviews; unusable stones are not counted in agreement</CardDescription>
      </CardHeader>
      <CardContent>
        {stats.isError ? (
          <ErrorState error={stats.error} onRetry={() => void stats.refetch()} />
        ) : !s ? (
          <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_auto]">
            <Skeleton className="h-40" />
            <Skeleton className="h-72 w-96" />
          </div>
        ) : (
          <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_auto]">
            <div className="grid h-fit grid-cols-2 gap-3">
              <Stat label="Reviewed" value={s.reviewed.toLocaleString()} sub={`${s.unusable} unusable`} />
              <Stat label="Pending" value={s.pending.toLocaleString()} sub="referred, not reviewed" />
              <Stat label="Exact agreement" value={fmtPct(s.agreement_rate)} sub={`${s.agreed} of ${s.reviewed}`} />
              <Stat label="Within one grade" value={fmtPct(s.within_one_grade_rate)} />
            </div>
            <ConfusionHeatmap counts={s.confusion_matrix.counts} />
          </div>
        )}
      </CardContent>
    </Card>
  );
}
