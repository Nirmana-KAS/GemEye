"use client";

import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, Download, RotateCcw, Star } from "lucide-react";
import { useMemo, useState } from "react";
import { Bar, CartesianGrid, ComposedChart, Legend, Line, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ChartCard, tooltipStyle, useChartPalette } from "@/components/chart-card";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect } from "@/components/filters";
import { PageHeader } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { fetchAllPages } from "@/lib/api";
import { downloadCsv, toCsv } from "@/lib/csv";
import { weeklyTrend } from "@/lib/feedback";
import { dayBoundIso, fmtDateTime } from "@/lib/format";
import type { FeedbackRow, FeedbackStatus, Page } from "@/lib/types";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 25;
const CHART_MAX = 2000;
const NOTE_MAX = 300;
const NO_ROWS: FeedbackRow[] = [];

function Rating({ value }: { value: number | null }) {
  if (value == null) return <span className="text-muted-foreground">-</span>;
  return (
    <span className="inline-flex items-center gap-0.5" aria-label={`${value} of 5`}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star key={i} className={cn("size-3.5", i < value ? "fill-warning text-warning" : "text-muted-foreground/40")} />
      ))}
    </span>
  );
}

function StatusCell({ f }: { f: FeedbackRow }) {
  return (
    <span className="block max-w-48">
      <span className={cn("text-xs font-medium", f.status === "resolved" ? "text-success" : "text-warning")}>
        {f.status === "resolved" ? "Resolved" : "Open"}
      </span>
      {f.status_note && <span className="block truncate text-xs text-muted-foreground" title={f.status_note}>{f.status_note}</span>}
    </span>
  );
}

export default function FeedbackPage() {
  const api = useApi();
  const qc = useQueryClient();
  const palette = useChartPalette();
  const tip = tooltipStyle(palette);
  const paging = useCursorPaging();
  const [status, setStatus] = useState("");
  const [category, setCategory] = useState("");
  const [rating, setRating] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [target, setTarget] = useState<FeedbackRow | null>(null);
  const [note, setNote] = useState("");
  const [exporting, setExporting] = useState(false);

  const filters = useMemo(
    () => ({
      status: status || undefined,
      category: category || undefined,
      rating: rating || undefined,
      from: dayBoundIso(from, false),
      to: dayBoundIso(to, true),
    }),
    [status, category, rating, from, to],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const list = useQuery({
    queryKey: ["admin-feedback", filters, paging.cursor],
    queryFn: () => api<Page<FeedbackRow>>("/admin/feedback", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });
  const all = (f: typeof filters, max: number) =>
    fetchAllPages((cursor) => api<Page<FeedbackRow>>("/admin/feedback", { query: { ...f, limit: 100, cursor } }), max);
  const trendData = useQuery({ queryKey: ["admin-feedback-trend", filters], queryFn: () => all(filters, CHART_MAX) });
  const trend = useMemo(() => weeklyTrend(trendData.data?.items ?? []), [trendData.data]);

  const setStatusMut = useMutation({
    mutationFn: ({ id, next, note }: { id: string; next: FeedbackStatus; note: string }) =>
      api(`/admin/feedback/${encodeURIComponent(id)}/status`, { method: "POST", body: { status: next, note: note.trim() || null } }),
    onSuccess: (_, v) => {
      toast.success(v.next === "resolved" ? "Marked resolved." : "Reopened.");
      void qc.invalidateQueries({ queryKey: ["admin-feedback"] });
    },
  });

  async function exportCsv() {
    setExporting(true);
    try {
      const { items, truncated } = await all(filters, 10000);
      const csv = toCsv(items, [
        { header: "time", value: (r) => r.created_at },
        { header: "user_email", value: (r) => r.user_email },
        { header: "rating", value: (r) => r.rating },
        { header: "category", value: (r) => r.category },
        { header: "comment", value: (r) => r.comment },
        { header: "app_version", value: (r) => r.app_version },
        { header: "status", value: (r) => r.status },
        { header: "admin_note", value: (r) => r.status_note },
      ]);
      downloadCsv("gemeye_feedback.csv", csv);
      toast.success(truncated ? `Exported the latest ${items.length} rows.` : `Exported ${items.length} rows.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setExporting(false);
    }
  }

  const col = columnHelper<FeedbackRow>();
  const columns = col.columns([
    col.accessor("created_at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
    col.accessor("user_email", { header: "User", cell: (i) => i.getValue() ?? <span className="text-muted-foreground">deleted user</span> }),
    col.accessor("rating", { header: "Rating", cell: (i) => <Rating value={i.getValue()} /> }),
    col.accessor("category", { header: "Category", cell: (i) => <span className="capitalize">{i.getValue() ?? "-"}</span> }),
    col.accessor("comment", {
      header: "Comment",
      cell: (i) => <span className="line-clamp-3 max-w-md whitespace-pre-wrap text-muted-foreground">{i.getValue() || "-"}</span>,
    }),
    col.accessor("app_version", { header: "App", cell: (i) => <span className="font-mono text-xs">{i.getValue() ?? "-"}</span> }),
    col.display({ id: "status", header: "Status", cell: (i) => <StatusCell f={i.row.original} /> }),
    col.display({
      id: "actions",
      header: "",
      cell: (i) => (
        <Button
          variant="outline"
          size="sm"
          onClick={() => {
            setNote(i.row.original.status_note ?? "");
            setTarget(i.row.original);
          }}
        >
          {i.row.original.status === "resolved" ? (
            <>
              <RotateCcw /> Reopen
            </>
          ) : (
            <>
              <CheckCircle2 /> Resolve
            </>
          )}
        </Button>
      ),
    }),
  ]);

  const next: FeedbackStatus = target?.status === "resolved" ? "open" : "resolved";

  return (
    <>
      <PageHeader
        title="Feedback"
        description="Ratings and comments sent from the app."
        actions={
          <Button variant="outline" onClick={() => void exportCsv()} disabled={exporting}>
            <Download /> Export CSV
          </Button>
        }
      />
      <FilterBar>
        <NativeSelect
          label="Status"
          value={status}
          onChange={setStatus}
          options={[
            { value: "", label: "Any" },
            { value: "open", label: "Open" },
            { value: "resolved", label: "Resolved" },
          ]}
        />
        <NativeSelect
          label="Category"
          value={category}
          onChange={setCategory}
          options={[
            { value: "", label: "Any" },
            { value: "accuracy", label: "Accuracy" },
            { value: "app", label: "App" },
            { value: "calibration", label: "Calibration" },
            { value: "other", label: "Other" },
          ]}
        />
        <NativeSelect
          label="Rating"
          value={rating}
          onChange={setRating}
          options={[{ value: "", label: "Any" }, ...[5, 4, 3, 2, 1].map((r) => ({ value: String(r), label: `${r} star${r > 1 ? "s" : ""}` }))]}
        />
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
      </FilterBar>

      <div className="mb-6">
        <ChartCard
          title="Feedback per week"
          description={`Count and average rating (weeks start on Monday)${trendData.data?.truncated ? `, latest ${CHART_MAX}` : ""}`}
          query={trendData}
          isEmpty={trend.length === 0}
        >
          <ResponsiveContainer width="100%" height="100%">
            <ComposedChart data={trend} margin={{ top: 8, right: 4, left: -6, bottom: 0 }}>
              <CartesianGrid stroke={palette.grid} vertical={false} />
              <XAxis dataKey="week" stroke={palette.axis} fontSize={12} />
              <YAxis yAxisId="n" allowDecimals={false} stroke={palette.axis} fontSize={12} />
              <YAxis yAxisId="r" orientation="right" domain={[1, 5]} ticks={[1, 2, 3, 4, 5]} stroke={palette.axis} fontSize={12} />
              <Tooltip {...tip} cursor={{ fill: palette.grid, opacity: 0.4 }} />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Bar yAxisId="n" dataKey="count" name="Feedback" fill={palette.accent} radius={[4, 4, 0, 0]} />
              <Line yAxisId="r" dataKey="avg_rating" name="Average rating" stroke={palette.warning} strokeWidth={2} dot connectNulls />
            </ComposedChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.feedback_id}
        emptyTitle="No feedback"
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />

      <ConfirmDialog
        open={target !== null}
        onOpenChange={(o) => !o && setTarget(null)}
        title={next === "resolved" ? "Mark this feedback resolved?" : "Reopen this feedback?"}
        description={target?.comment ? `"${target.comment.slice(0, 160)}"` : undefined}
        confirmLabel={next === "resolved" ? "Mark resolved" : "Reopen"}
        onConfirm={async () => {
          if (note.length > NOTE_MAX) throw new Error("too long");
          if (target) await setStatusMut.mutateAsync({ id: target.feedback_id, next, note });
          setTarget(null);
        }}
      >
        <div className="space-y-1.5">
          <div className="flex justify-between">
            <Label htmlFor="fb-note">Admin note (optional)</Label>
            <span className={cn("text-xs text-muted-foreground", note.length > NOTE_MAX && "text-destructive")}>
              {note.length}/{NOTE_MAX}
            </span>
          </div>
          <Input id="fb-note" value={note} maxLength={NOTE_MAX} onChange={(e) => setNote(e.target.value)} />
        </div>
      </ConfirmDialog>
    </>
  );
}
