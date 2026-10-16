"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertOctagon, CheckCheck, Gauge, Gem, Share2, Timer } from "lucide-react";
import { useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
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
import { NativeSelect } from "@/components/filters";
import { Kpi } from "@/components/kpi";
import { EmptyState, ErrorState, PageHeader } from "@/components/states";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fmtDateTime, fmtMs, fmtNum, fmtPct } from "@/lib/format";
import { agreementBars, type DayRow, perDaySeries, rejectionStack, seriesEmpty, sortVersions } from "@/lib/monitoring";
import type { ModelMonitoring, MonitoringDays, MonitoringSummary, MonitoringVersion } from "@/lib/types";
import { cn } from "@/lib/utils";

const RANGES: { days: MonitoringDays; label: string }[] = [
  { days: 7, label: "7 days" },
  { days: 30, label: "30 days" },
  { days: 90, label: "90 days" },
];
const ALL = "all";
const EXTRA_COLOURS = ["#0891B2", "#7C3AED", "#DB2777", "#65A30D"];

function shortDay(day: string) {
  return day.slice(5);
}

function pctAxis(v: number) {
  return `${Math.round(v * 100)}%`;
}

function useVersionColour() {
  const palette = useChartPalette();
  return (version: string, index: number) =>
    version === "v3" ? palette.primary : version === "v5" ? palette.warning : EXTRA_COLOURS[index % EXTRA_COLOURS.length];
}

function VersionKpis({ v }: { v: MonitoringVersion }) {
  const s = v.summary;
  const r = s.reviews;
  return (
    <div className="mb-4">
      <div className="mb-2 flex items-baseline gap-2">
        <h2 className="text-sm font-semibold">Model {v.model_version}</h2>
        <span className="text-xs text-muted-foreground">
          {s.last_seen ? `last grading ${fmtDateTime(s.last_seen)}` : "no gradings in this range"}
        </span>
      </div>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
        <Kpi label="Gradings" value={s.gradings.toLocaleString()} sub={`${s.unusual_image} unusual images`} icon={Gem} />
        <Kpi label="Avg confidence" value={fmtPct(s.avg_confidence)} sub={`uncertainty ${fmtNum(s.avg_uncertainty, 3)}`} icon={Gauge} />
        <Kpi label="Referral rate" value={fmtPct(s.referral_rate)} sub={`${s.referred} referred`} icon={Share2} />
        <Kpi label="Rejection rate" value={fmtPct(s.rejection_rate)} sub={`${s.rejections} rejected photos`} icon={AlertOctagon} />
        <Kpi
          label="Review agreement"
          value={fmtPct(r.agreement_rate)}
          sub={r.reviewed ? `within one ${fmtPct(r.within_one_rate)} (n ${r.reviewed})` : "no reviews yet"}
          icon={CheckCheck}
        />
        <Kpi label="p95 latency" value={fmtMs(s.p95_latency_ms)} sub={`avg ${fmtMs(s.avg_latency_ms)}`} icon={Timer} />
      </div>
    </div>
  );
}

const COMPARE_ROWS: { label: string; value: (s: MonitoringSummary) => string }[] = [
  { label: "Gradings", value: (s) => s.gradings.toLocaleString() },
  { label: "Avg confidence", value: (s) => fmtPct(s.avg_confidence) },
  { label: "Avg uncertainty", value: (s) => fmtNum(s.avg_uncertainty, 3) },
  { label: "Referral rate", value: (s) => fmtPct(s.referral_rate) },
  { label: "Rejection rate", value: (s) => fmtPct(s.rejection_rate) },
  { label: "Unusual image rate", value: (s) => fmtPct(s.unusual_image_rate) },
  { label: "Reviews (n)", value: (s) => String(s.reviews.reviewed) },
  { label: "Exact agreement", value: (s) => fmtPct(s.reviews.agreement_rate) },
  { label: "Within one grade", value: (s) => fmtPct(s.reviews.within_one_rate) },
  { label: "Avg latency", value: (s) => fmtMs(s.avg_latency_ms) },
  { label: "p95 latency", value: (s) => fmtMs(s.p95_latency_ms) },
];

function CompareTable({ versions }: { versions: MonitoringVersion[] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="text-xs text-muted-foreground">
            <th className="py-1.5 text-left font-medium">Metric</th>
            {versions.map((v) => (
              <th key={v.model_version} className="py-1.5 text-right font-medium">
                {v.model_version}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {COMPARE_ROWS.map((row) => (
            <tr key={row.label} className="border-t">
              <td className="py-1.5 text-muted-foreground">{row.label}</td>
              {versions.map((v) => (
                <td key={v.model_version} className="py-1.5 text-right tabular-nums">
                  {row.value(v.summary)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function missingVersionTitle(present: string[]): string {
  if (present.includes("v3") && !present.includes("v5")) return "No v5 gradings yet";
  return "Only one model version in this range";
}

export default function ModelMonitoringPage() {
  const api = useApi();
  const palette = useChartPalette();
  const tip = tooltipStyle(palette);
  const colourOf = useVersionColour();
  const [days, setDays] = useState<MonitoringDays>(30);
  const [version, setVersion] = useState(ALL);

  const fetchMonitoring = (v: string) => () =>
    api<ModelMonitoring>("/admin/model/monitoring", { query: { days, model_version: v === ALL ? undefined : v } });
  // "All" gives the version list; a selected version is filtered by the server.
  const all = useQuery({ queryKey: ["model-monitoring", days, ALL], queryFn: fetchMonitoring(ALL) });
  const one = useQuery({ queryKey: ["model-monitoring", days, version], queryFn: fetchMonitoring(version), enabled: version !== ALL });
  const query = version === ALL ? all : one;

  const present = useMemo(() => sortVersions(all.data?.versions ?? []).map((v) => v.model_version), [all.data]);
  const versions = useMemo(() => sortVersions(query.data?.versions ?? []), [query.data]);
  const names = versions.map((v) => v.model_version);
  const dayKeys = useMemo(() => query.data?.day_keys ?? [], [query.data]);

  const confidence = useMemo(() => {
    const conf = perDaySeries(versions, dayKeys, (d) => d.mean_confidence);
    const unc = perDaySeries(versions, dayKeys, (d) => d.mean_uncertainty);
    return conf.map((row, i) => {
      const out: DayRow = { ...row };
      for (const v of names) out[`${v} uncertainty`] = unc[i][v];
      return out;
    });
  }, [versions, dayKeys, names]);
  const referral = useMemo(() => perDaySeries(versions, dayKeys, (d) => d.referral_rate), [versions, dayKeys]);
  const latency = useMemo(() => {
    const avg = perDaySeries(versions, dayKeys, (d) => d.mean_latency_ms);
    const p95 = perDaySeries(versions, dayKeys, (d) => d.p95_latency_ms);
    return avg.map((row, i) => {
      const out: DayRow = { ...row };
      for (const v of names) out[`${v} p95`] = p95[i][v];
      return out;
    });
  }, [versions, dayKeys, names]);
  const rejections = useMemo(() => rejectionStack(versions, dayKeys), [versions, dayKeys]);
  const agreement = useMemo(() => agreementBars(versions), [versions]);

  const noData = query.isSuccess && versions.length === 0;

  return (
    <>
      <PageHeader
        title="Model monitoring"
        description="Confidence, referrals, rejections, latency and gemologist agreement per model version (Asia/Colombo days)."
        actions={
          <>
            <NativeSelect
              label="Model version"
              value={version}
              onChange={setVersion}
              options={[{ value: ALL, label: "All" }, ...present.map((v) => ({ value: v, label: v }))]}
            />
            <div className="flex flex-col gap-1 text-xs font-medium text-muted-foreground">
              Range
              <div className="inline-flex rounded-lg border bg-card p-0.5">
                {RANGES.map((r) => (
                  <button
                    key={r.days}
                    type="button"
                    onClick={() => setDays(r.days)}
                    className={cn(
                      "rounded-md px-3 py-1 text-sm transition-colors",
                      days === r.days ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground",
                    )}
                  >
                    {r.label}
                  </button>
                ))}
              </div>
            </div>
          </>
        }
      />

      {query.isError ? (
        <Card className="mb-6">
          <ErrorState error={query.error} onRetry={() => void query.refetch()} />
        </Card>
      ) : query.isPending ? (
        <div className="mb-6 grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
          {Array.from({ length: 6 }, (_, i) => (
            <Skeleton key={i} className="h-23 rounded-xl" />
          ))}
        </div>
      ) : noData ? (
        <Card className="mb-6">
          <EmptyState
            title={version === ALL ? "No gradings in this range" : `No ${version} gradings yet`}
            hint="Metrics appear once the app has graded stones with this model."
          />
        </Card>
      ) : (
        versions.map((v) => <VersionKpis key={v.model_version} v={v} />)
      )}

      {!noData && (
        <div className="mt-2 grid gap-4 xl:grid-cols-2">
          <ChartCard
            title="Confidence and uncertainty"
            description="Daily mean; dashed = uncertainty"
            query={query}
            isEmpty={seriesEmpty(confidence, names)}
          >
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={confidence} margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} vertical={false} />
                <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
                <YAxis domain={[0, 1]} tickFormatter={pctAxis} stroke={palette.axis} fontSize={12} />
                <Tooltip {...tip} formatter={(v) => fmtNum(Number(v), 3)} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                {names.flatMap((v, i) => [
                  <Line key={v} dataKey={v} name={`${v} confidence`} stroke={colourOf(v, i)} strokeWidth={2} connectNulls dot={{ r: 2 }} />,
                  <Line
                    key={`${v}-u`}
                    dataKey={`${v} uncertainty`}
                    stroke={colourOf(v, i)}
                    strokeWidth={1.5}
                    strokeDasharray="5 4"
                    connectNulls
                    dot={false}
                  />,
                ])}
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Referral rate" description="Share of gradings sent to a gemologist" query={query} isEmpty={seriesEmpty(referral, names)}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={referral} margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} vertical={false} />
                <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
                <YAxis domain={[0, 1]} tickFormatter={pctAxis} stroke={palette.axis} fontSize={12} />
                <Tooltip {...tip} formatter={(v) => fmtPct(Number(v))} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                {names.map((v, i) => (
                  <Line key={v} dataKey={v} stroke={colourOf(v, i)} strokeWidth={2} connectNulls dot={{ r: 2 }} />
                ))}
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard
            title="Rejections per gate"
            description="Photos stopped by a quality gate, per day"
            query={query}
            isEmpty={rejections.gates.length === 0}
          >
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={rejections.rows} margin={{ top: 8, right: 12, left: -12, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} vertical={false} />
                <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
                <YAxis allowDecimals={false} stroke={palette.axis} fontSize={12} />
                <Tooltip {...tip} cursor={{ fill: palette.grid, opacity: 0.4 }} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                {rejections.gates.map((g, i) => (
                  <Bar key={g} dataKey={g} stackId="r" fill={gateColour(g, i)} />
                ))}
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="Latency" description="Server time per grading; dashed = p95" query={query} isEmpty={seriesEmpty(latency, names)}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={latency} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} vertical={false} />
                <XAxis dataKey="day" tickFormatter={shortDay} stroke={palette.axis} fontSize={12} />
                <YAxis tickFormatter={(v: number) => fmtMs(v)} stroke={palette.axis} fontSize={12} width={64} />
                <Tooltip {...tip} formatter={(v) => fmtMs(Number(v))} />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                {names.flatMap((v, i) => [
                  <Line key={v} dataKey={v} name={`${v} avg`} stroke={colourOf(v, i)} strokeWidth={2} connectNulls dot={{ r: 2 }} />,
                  <Line
                    key={`${v}-p`}
                    dataKey={`${v} p95`}
                    stroke={colourOf(v, i)}
                    strokeWidth={1.5}
                    strokeDasharray="5 4"
                    connectNulls
                    dot={false}
                  />,
                ])}
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard
            title="Agreement with gemologist reviews"
            description="Share of reviewed stones per version"
            query={query}
            isEmpty={agreement.every((a) => a.reviewed === 0)}
          >
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={agreement} margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} vertical={false} />
                <XAxis dataKey="model_version" stroke={palette.axis} fontSize={12} />
                <YAxis domain={[0, 1]} tickFormatter={pctAxis} stroke={palette.axis} fontSize={12} />
                <Tooltip
                  {...tip}
                  cursor={{ fill: palette.grid, opacity: 0.4 }}
                  formatter={(v) => fmtPct(Number(v))}
                  labelFormatter={(label, p) => {
                    const n = (p?.[0]?.payload as { reviewed?: number } | undefined)?.reviewed ?? 0;
                    return `${label} (n ${n})`;
                  }}
                />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="exact" name="Exact grade" fill={palette.primary} radius={[4, 4, 0, 0]} />
                <Bar dataKey="within_one" name="Within one grade" fill={palette.soft} radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Version comparison</CardTitle>
              <CardDescription>Side by side over the selected range</CardDescription>
            </CardHeader>
            <CardContent>
              {query.isPending ? (
                <Skeleton className="h-64 w-full" />
              ) : versions.length >= 2 ? (
                <CompareTable versions={versions} />
              ) : (
                <EmptyState
                  title={missingVersionTitle(present)}
                  hint={
                    version === ALL
                      ? "The comparison appears once a second model version has gradings."
                      : "Choose All to compare versions."
                  }
                />
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </>
  );
}
