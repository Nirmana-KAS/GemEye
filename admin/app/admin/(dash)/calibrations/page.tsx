"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { format } from "date-fns";
import { useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Scatter,
  ScatterChart,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { useApi } from "@/components/auth-provider";
import { ChartCard, tooltipStyle, useChartPalette } from "@/components/chart-card";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { PageHeader } from "@/components/states";
import { Input } from "@/components/ui/input";
import { fetchAllPages } from "@/lib/api";
import { dayBoundIso, fmtDateTime, fmtNum } from "@/lib/format";
import type { CalibrationRow, Page } from "@/lib/types";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 25;
const CHART_MAX = 500;
const NO_ROWS: CalibrationRow[] = [];
const DEVICE_COLOURS = ["#1E3A8A", "#2563EB", "#D97706", "#059669", "#7C3AED", "#DC2626", "#0891B2", "#DB2777"];

function QualityBadge({ q }: { q: string | number | null }) {
  if (q == null) return <span className="text-muted-foreground">-</span>;
  const s = String(q).toLowerCase();
  const tone =
    s === "excellent" || s === "good"
      ? "bg-success/15 text-success"
      : s === "acceptable"
        ? "bg-warning/15 text-warning"
        : s === "poor"
          ? "bg-destructive/10 text-destructive"
          : "bg-muted text-muted-foreground";
  return <span className={cn("rounded-md px-1.5 py-0.5 text-xs font-medium capitalize", tone)}>{String(q)}</span>;
}

function isValid(until: string | null): boolean | null {
  if (!until) return null;
  const t = new Date(until.endsWith("Z") || /[+-]\d\d:\d\d$/.test(until) ? until : `${until}Z`).getTime();
  return Number.isNaN(t) ? null : t > Date.now();
}

const col = columnHelper<CalibrationRow>();
const columns = col.columns([
  col.accessor("created_at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
  col.accessor("device", { header: "Device", cell: (i) => i.getValue() ?? "-" }),
  col.accessor("residual", { header: "Residual", cell: (i) => <span className="font-mono text-xs">{fmtNum(i.getValue(), 3)}</span> }),
  col.accessor("relative_residual", {
    header: "Relative residual",
    cell: (i) => <span className="font-mono text-xs">{fmtNum(i.getValue(), 3)}</span>,
  }),
  col.accessor("quality", { header: "Quality", cell: (i) => <QualityBadge q={i.getValue()} /> }),
  col.accessor("valid_until", {
    header: "Valid until",
    cell: (i) => {
      const v = isValid(i.getValue());
      return (
        <span className="whitespace-nowrap">
          {fmtDateTime(i.getValue())}
          {v !== null && <span className={cn("ml-2 text-xs", v ? "text-success" : "text-muted-foreground")}>{v ? "valid" : "expired"}</span>}
        </span>
      );
    },
  }),
]);

export default function CalibrationsPage() {
  const api = useApi();
  const palette = useChartPalette();
  const tip = tooltipStyle(palette);
  const paging = useCursorPaging();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [quality, setQuality] = useState("");
  const [deviceInput, setDeviceInput] = useState("");
  const device = useDebounced(deviceInput.trim());

  const filters = useMemo(
    () => ({ from: dayBoundIso(from, false), to: dayBoundIso(to, true), quality: quality || undefined, device: device || undefined }),
    [from, to, quality, device],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const list = useQuery({
    queryKey: ["admin-calibrations", filters, paging.cursor],
    queryFn: () => api<Page<CalibrationRow>>("/admin/calibrations", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  // Charts use up to the latest 500 sessions that match the filters.
  const chartData = useQuery({
    queryKey: ["admin-calibrations-chart", filters],
    queryFn: () =>
      fetchAllPages((cursor) => api<Page<CalibrationRow>>("/admin/calibrations", { query: { ...filters, limit: 100, cursor } }), CHART_MAX),
  });

  const charts = useMemo(() => {
    const rows = (chartData.data?.items ?? []).filter((r) => r.residual != null && r.created_at);
    const byDevice = new Map<string, { t: number; residual: number }[]>();
    for (const r of rows) {
      const key = r.device || "unknown";
      const t = new Date(r.created_at!.endsWith("Z") ? r.created_at! : `${r.created_at}Z`).getTime();
      const list = byDevice.get(key) ?? [];
      list.push({ t, residual: r.residual! });
      byDevice.set(key, list);
    }
    const devices = [...byDevice.entries()].sort((a, b) => b[1].length - a[1].length);
    const mean = devices.map(([name, pts]) => ({
      device: name,
      mean: pts.reduce((s, p) => s + p.residual, 0) / pts.length,
      count: pts.length,
    }));
    return { devices, mean };
  }, [chartData.data]);

  return (
    <>
      <PageHeader title="Calibrations" description="Colour-checker calibration sessions from the app." />
      <FilterBar>
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
        <NativeSelect
          label="Quality"
          value={quality}
          onChange={setQuality}
          options={[
            { value: "", label: "Any" },
            { value: "excellent", label: "Excellent" },
            { value: "acceptable", label: "Acceptable" },
            { value: "poor", label: "Poor" },
          ]}
        />
        <FilterField label="Device">
          <Input value={deviceInput} onChange={(e) => setDeviceInput(e.target.value)} placeholder="Contains" className="w-48" />
        </FilterField>
      </FilterBar>

      <div className="mb-6 grid gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <ChartCard
            title="Residual over time"
            description={`Fit error per session, coloured by device${chartData.data?.truncated ? ` (latest ${CHART_MAX})` : ""}`}
            query={chartData}
            isEmpty={charts.devices.length === 0}
          >
            <ResponsiveContainer width="100%" height="100%">
              <ScatterChart margin={{ top: 8, right: 12, left: -6, bottom: 0 }}>
                <CartesianGrid stroke={palette.grid} />
                <XAxis
                  dataKey="t"
                  type="number"
                  scale="time"
                  domain={["dataMin", "dataMax"]}
                  tickFormatter={(t: number) => format(t, "MM-dd")}
                  stroke={palette.axis}
                  fontSize={12}
                />
                <YAxis dataKey="residual" name="Residual" stroke={palette.axis} fontSize={12} />
                <Tooltip
                  {...tip}
                  formatter={(v, name) => (name === "Residual" ? fmtNum(Number(v), 3) : format(Number(v), "yyyy-MM-dd HH:mm"))}
                />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                {charts.devices.map(([name, pts], i) => (
                  <Scatter key={name} name={name} data={pts} fill={DEVICE_COLOURS[i % DEVICE_COLOURS.length]} />
                ))}
              </ScatterChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>
        <ChartCard title="Mean residual per device" query={chartData} isEmpty={charts.mean.length === 0}>
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={charts.mean} layout="vertical" margin={{ top: 8, right: 12, left: 8, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} horizontal={false} />
              <XAxis type="number" stroke={palette.axis} fontSize={12} />
              <YAxis type="category" dataKey="device" width={110} stroke={palette.axis} fontSize={11} />
              <Tooltip {...tip} cursor={{ fill: palette.grid, opacity: 0.4 }} formatter={(v) => fmtNum(Number(v), 3)} />
              <Bar dataKey="mean" name="Mean residual" fill={palette.accent} radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.calibration_id}
        emptyTitle="No calibration sessions"
      />
      <Pager
        page={paging.page}
        hasNext={!!list.data?.next_cursor}
        onPrev={paging.prev}
        onNext={() => paging.next(list.data?.next_cursor)}
        busy={list.isFetching}
      />
    </>
  );
}
