"use client";

import { GradeChip } from "@/components/grade-chip";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { fmtDateTime, fmtNum, fmtPct } from "@/lib/format";
import { GRADES } from "@/lib/grades";
import type { GradeResult, Regrade } from "@/lib/types";

interface Column {
  key: string;
  title: string;
  sub: string;
  status: string;
  grade: number | null | undefined;
  confidence: number | null | undefined;
  uncertainty: number | null | undefined;
  referred: boolean | null | undefined;
  probs: number[] | null | undefined;
}

/** Original result next to its re-grades (newest first). The original is never changed. */
export function RegradeCompare({ original, regrades }: { original: GradeResult; regrades: Regrade[] }) {
  const cols: Column[] = [
    {
      key: "original",
      title: "Original",
      sub: original.model_version ?? "-",
      status: original.status,
      grade: original.grade,
      confidence: original.confidence,
      uncertainty: original.uncertainty,
      referred: original.referred,
      probs: original.probabilities,
    },
    ...[...regrades].reverse().map((r) => ({
      key: r.id,
      title: `Re-grade ${fmtDateTime(r.at)}`,
      sub: `${r.model_version ?? "-"}${r.by_email ? ` - ${r.by_email}` : ""}`,
      status: r.status,
      grade: r.grade,
      confidence: r.confidence,
      uncertainty: r.uncertainty,
      referred: r.referred,
      probs: r.probabilities,
    })),
  ];
  const row = (label: string, cell: (c: Column) => React.ReactNode, mono = false) => (
    <tr key={label} className="border-t">
      <td className="py-1.5 pr-3 text-muted-foreground">{label}</td>
      {cols.map((c) => (
        <td key={c.key} className={mono ? "py-1.5 pr-3 font-mono text-xs" : "py-1.5 pr-3"}>
          {cell(c)}
        </td>
      ))}
    </tr>
  );
  return (
    <Card className="mb-4">
      <CardHeader>
        <CardTitle className="text-base">Original vs re-grade</CardTitle>
        <CardDescription>Re-grades run the current model on the stored photo. The original result is kept as it was.</CardDescription>
      </CardHeader>
      <CardContent className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-xs text-muted-foreground">
              <th className="py-1 pr-3 font-medium" />
              {cols.map((c) => (
                <th key={c.key} className="py-1 pr-3 align-bottom font-medium">
                  <div className="text-foreground">{c.title}</div>
                  <div className="font-normal">{c.sub}</div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {row("Grade", (c) => (c.status === "ok" ? <GradeChip grade={c.grade} showName /> : <span className="capitalize">{c.status.replace(/_/g, " ")}</span>))}
            {row("Confidence", (c) => fmtPct(c.confidence), true)}
            {row("Uncertainty", (c) => fmtNum(c.uncertainty, 4), true)}
            {row("Referred", (c) => (c.referred == null ? "-" : c.referred ? "Yes" : "No"))}
            {GRADES.map((g, i) => row(`P(G${g.grade})`, (c) => fmtPct(c.probs?.[i], 1), true))}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}
