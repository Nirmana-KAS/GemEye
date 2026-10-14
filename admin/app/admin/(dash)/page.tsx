"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Activity,
  AlertOctagon,
  Cpu,
  Database,
  Gauge,
  Gem,
  Share2,
  Timer,
  Users,
} from "lucide-react";
import { useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { useApi } from "@/components/auth-provider";
import { ChartCard, gateColour, tooltipStyle, useChartPalette } from "@/components/chart-card";
import { ErrorState, PageHeader } from "@/components/states";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fmtMs, fmtNum, fmtPct } from "@/lib/format";
import { GRADES } from "@/lib/grades";
import type { ModelMonitoring, StatsDays, StatsSummary, Timeseries, TimeseriesMetric } from "@/lib/types";
import { cn } from "@/lib/utils";

const RANGES: { days: StatsDays; label: string }[] = [
  { days: 1, label: "24 hours" },
  { days: 7, label: "7 days" },
  { days: 30, label: "30 days" },
];

function Kpi({
  label,
  value,
  sub,
  icon: Icon,
  tone,
}: {
  label: string;
  value: React.ReactNode;
  sub?: React.ReactNode;
  icon: React.ComponentType<{ className?: string }>;
  tone?: "ok" | "bad";
}) {
  return (
    <Card size="sm">
      <CardContent className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</p>
          <p
            className={cn(
              "mt-1 truncate text-2xl font-semibold tabular-nums",
              tone === "ok" && "text-success",
              tone === "bad" && "text-destructive",
            )}
          >
            {value}
          </p>
          {sub && <p className="mt-0.5 truncate text-xs text-muted-foreground">{sub}</p>}
        </div>
        <div className="rounded-md bg-accent p-2 text-primary dark:text-accent-foreground">
          <Icon className="size-4" />
        </div>
      </CardContent>
    </Card>
  );
}

function shortDay(day: string) {
  return day.slice(5);
}

export default function OverviewPage() {
  const api = useApi();
  const palette = useChartPalette();
  const tip = tooltipStyle(palette);
  const [days, setDays] = useState<StatsDays>(7);
  // Daily charts need more than one point, so "24 hours" shows the last 7 days.
  const chartDays = Math.max(days, 7);

  const summary = useQuery({
    queryKey: ["stats-summary", days],
    queryFn: () => api<StatsSummary>("/admin/stats/summary", { query: { days } }),
  });

  const series = (metric: TimeseriesMetric) => ({
    queryKey: ["stats-timeseries", metric, chartDays],
    queryFn: () => api<Timeseries>("/admin/stats/timeseries", { query: { metric, days: chartDays } }),
  });
  const gradings = useQuery(series("gradings"));
  const referral = useQuery(series("referral_rate"));
  const confidence = useQuery(series("avg_confidence"));
  const monitoring = useQuery({
    queryKey: ["model-monitoring", chartDays],
    queryFn: () => api<ModelMonitoring>("/admin/model/monitoring", { query: { days: chartDays } }),
  });

  const rejections = useMemo(() => {
    const data = monitoring.data;
    if (!data) return { rows: [], gates: [] as string[] };
    const gates = [...new Set(data.rejections_by_gate.map((r) => r.gate))].sort();
    const byDay = new Map<string, Record<string, number | string>>();
    // Same days as the other charts (gradings series), zero-filled.
    for (const p of gradings.data?.points ?? []) byDay.set(p.day, { day: p.day });
    for (const r of data.rejections_by_gate) {
      const row = byDay.get(r.day) ?? { day: r.day };
      row[r.gate] = ((row[r.gate] as number) ?? 0) + r.count;
      byDay.set(r.day, row);
    }
    const rows = [...byDay.values()]
      .sort((a, b) => String(a.day).localeCompare(String(b.day)))
      .map((row) => Object.fromEntries([["day", row.day], ...gates.map((g) => [g, row[g] ?? 0])]));
    return { rows, gates };
  }, [monitoring.data, gradings.data]);

  const distribution = useMemo(
    () =>
      GRADES.map((g) => ({
        grade: `G${g.grade}`,
        name: g.name,
        hex: g.hex,
        count: summary.data?.grade_distribution?.[String(g.grade)] ?? 0,
      })),
    [summary.data],
  );

  const s = summary.data;
  const allZero = (pts?: { value: number | null }[]) => !pts || pts.every((p) => !p.value);

  return (
    <>
      <PageHeader
        title="Overview"
        description="Gradings, users and system health across GemEye."
        actions={
          <div className="inline-flex rounded-lg border bg-card p-0.5">
            {RANGES.map((r) => (
              <button
                key={r.days}
                type="button"
                onClick={() => setDays(r.days)}
                className={cn(
                  "rounded-md px-3 py-1.5 text-sm transition-colors",
                  days === r.days ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground",
                )}
              >
                {r.label}
              </button>
            ))}
          </div>
        }
      />

      {summary.isError ? (
        <Card className="mb-6">
          <ErrorState error={summary.error} onRetry={() => void summary.refetch()} />
        </Card>
      ) : (
        <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
          {!s ? (
            Array.from({ length: 8 }, (_, i) => <Skeleton key={i} className="h-[92px] rounded-xl" />)
          ) : (
            <>
              <Kpi label="Gradings" value={s.gradings.toLocaleString()} sub={`${s.referred} referred`} icon={Gem} />
              <Kpi label="Active users" value={s.unique_users.toLocaleString()} sub="graded or attempted" icon={Users} />
              <Kpi label="Referral rate" value={fmtPct(s.referral_rate)} sub="sent to a gemologist" icon={Share2} />
              <Kpi
                label="Rejection rate"
                value={fmtPct(s.rejection_rate)}
                sub={`${s.rejections} rejected photos`}
                icon={AlertOctagon}
              />
              <Kpi
                label="Avg confidence"
                value={fmtPct(s.avg_confidence)}
                sub={`uncertainty ${fmtNum(s.avg_uncertainty, 3)}`}
                icon={Gauge}
              />
              <Kpi label="Avg latency" value={fmtMs(s.avg_latency_ms)} sub="server processing" icon={Timer} />
              <Kpi label="Model version" value={s.server.model_version} sub={s.server.models_loaded ? "models loaded" : "models not loaded"} icon={Cpu} />
              <Kpi
                label="Server / DB"
                value={`${s.server.status === "ok" ? "OK" : "Degraded"} / ${s.database.status === "ok" ? "OK" : "Down"}`}
                tone={s.server.status === "ok" && s.database.status === "ok" ? "ok" : "bad"}
                sub="checked now"
                icon={s.database.status === "ok" ? Database : Activity}
              />
            </>
          )}
        </div>
      )}

      <div className="grid gap-4 xl:grid-cols-2">
        <ChartCard
          title="Gradings per day"
          description={`Last ${chartDays} days (Asia/Colombo)`}
          query={gradings}
          isEmpty={allZero(gradings.data?.points)}
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={gradings.data?.points} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
              <YAxis allowDecimals={false} stroke={palette.axis} fontSize={12} />
              <Tooltip {...tip} />
              <Line type="monotone" dataKey="value" name="Gradings" stroke={palette.primary} strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Rejections per day by reason"
          description="Photos stopped by a quality gate"
          query={monitoring}
          isEmpty={rejections.gates.length === 0}
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={rejections.rows} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
              <YAxis allowDecimals={false} stroke={palette.axis} fontSize={12} />
              <Tooltip {...tip} />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              {rejections.gates.map((g, i) => (
                <Bar key={g} dataKey={g} stackId="r" fill={gateColour(g, i)} />
              ))}
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Referral rate"
          description="Share of gradings referred to a gemologist"
          query={referral}
          isEmpty={referral.data?.points.every((p) => p.value == null)}
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={referral.data?.points} margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
              <YAxis domain={[0, 1]} tickFormatter={(v: number) => `${Math.round(v * 100)}%`} stroke={palette.axis} fontSize={12} />
              <Tooltip {...tip} formatter={(v) => fmtPct(Number(v))} />
              <Line type="monotone" dataKey="value" name="Referral rate" stroke={palette.warning} strokeWidth={2} connectNulls dot={{ r: 2 }} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Average confidence"
          description="Mean top-class probability per day"
          query={confidence}
          isEmpty={confidence.data?.points.every((p) => p.value == null)}
        >
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={confidence.data?.points} margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
              <YAxis domain={[0, 1]} tickFormatter={(v: number) => `${Math.round(v * 100)}%`} stroke={palette.axis} fontSize={12} />
              <Tooltip {...tip} formatter={(v) => fmtPct(Number(v))} />
              <Line type="monotone" dataKey="value" name="Avg confidence" stroke={palette.accent} strokeWidth={2} connectNulls dot={{ r: 2 }} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard
          title="Grade distribution"
          description={`Gradings by GEMCLOUD grade (${RANGES.find((r) => r.days === days)?.label})`}
          query={summary}
          isEmpty={distribution.every((d) => d.count === 0)}
        >
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={distribution} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="grade" stroke={palette.axis} fontSize={12} />
              <YAxis allowDecimals={false} stroke={palette.axis} fontSize={12} />
              <Tooltip
                {...tip}
                cursor={{ fill: palette.grid, opacity: 0.4 }}
                labelFormatter={(_, p) => {
                  const d = p?.[0]?.payload as { grade: string; name: string } | undefined;
                  return d ? `${d.grade} - ${d.name}` : "";
                }}
              />
              <Bar dataKey="count" name="Gradings" radius={[4, 4, 0, 0]}>
                {distribution.map((d) => (
                  <Cell key={d.grade} fill={d.hex} stroke={palette.axis} strokeOpacity={0.25} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>
    </>
  );
}
