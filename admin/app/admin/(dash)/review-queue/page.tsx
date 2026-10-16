"use client";

import { keepPreviousData, useQuery, useQueryClient } from "@tanstack/react-query";
import { Download, Loader2 } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth-provider";
import { columnHelper, DataTable, Pager, useCursorPaging, type Columns } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { GradeChip } from "@/components/grade-chip";
import { ReviewPanel } from "@/components/review-panel";
import { ReviewStatsCard } from "@/components/review-stats";
import { PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { exportReviewsCsv, listReviewQueue } from "@/lib/api";
import { downloadCsv } from "@/lib/csv";
import { dayBoundIso, fmtDateTime, fmtPct } from "@/lib/format";
import { reasonLabel } from "@/lib/reviews";
import type { QueueItem, QueueReview, ReviewQueueStatus } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_ROWS: QueueItem[] = [];

const col = columnHelper<QueueItem>();
const BASE_COLUMNS: Columns<QueueItem> = [
  col.accessor("created_at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
  col.accessor("grade", { header: "Model grade", cell: (i) => <GradeChip grade={i.getValue()} showName /> }),
  col.accessor("confidence", { header: "Confidence", cell: (i) => <span className="tabular-nums">{fmtPct(i.getValue())}</span> }),
  col.accessor("referred_reasons", {
    header: "Referred reason",
    cell: (i) => (
      <span className="flex flex-wrap gap-1">
        {i.getValue().map((r: string) => (
          <Badge key={r} variant="outline">
            {reasonLabel(r)}
          </Badge>
        ))}
      </span>
    ),
  }),
  col.accessor("model_version", { header: "Model", cell: (i) => i.getValue() ?? "-" }),
  col.accessor("device", { header: "Device", cell: (i) => <span className="block max-w-48 truncate">{i.getValue() ?? "-"}</span> }),
];
const REVIEW_COLUMN = col.accessor("review", {
  header: "Gemologist",
  cell: (i) => {
    const r = i.getValue();
    if (!r) return "-";
    return (
      <span className="inline-flex items-center gap-2">
        {r.unusable ? <Badge variant="secondary">Unusable</Badge> : <GradeChip grade={r.gemologist_grade} />}
        {r.agrees === false && <span className="text-xs text-destructive">differs</span>}
        {r.mine && <span className="text-xs text-muted-foreground">you</span>}
      </span>
    );
  },
});
const PENDING_COLUMNS = BASE_COLUMNS;
const REVIEWED_COLUMNS: Columns<QueueItem> = [...BASE_COLUMNS, REVIEW_COLUMN];

const STATUS_OPTIONS: { value: ReviewQueueStatus; label: string }[] = [
  { value: "pending", label: "Pending" },
  { value: "mine", label: "Reviewed by me" },
  { value: "reviewed", label: "All reviewed" },
];

export default function ReviewQueuePage() {
  const { api, role } = useAuth();
  const isAdmin = role === "admin";
  const queryClient = useQueryClient();
  const paging = useCursorPaging();
  const [status, setStatus] = useState<ReviewQueueStatus>("pending");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [modelInput, setModelInput] = useState("");
  const [selected, setSelected] = useState<QueueItem | null>(null);
  const [exporting, setExporting] = useState(false);
  const model = useDebounced(modelInput.trim());

  const filters = useMemo(
    () => ({ status, from: dayBoundIso(from, false), to: dayBoundIso(to, true), model_version: model || undefined }),
    [status, from, to, model],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const queue = useQuery({
    queryKey: ["review-queue", filters, paging.cursor],
    queryFn: () => listReviewQueue(api, { ...filters, limit: PAGE_SIZE, cursor: paging.cursor }),
    placeholderData: keepPreviousData,
    // Photo links expire after 10 minutes.
    staleTime: 60_000,
  });
  const rows = queue.data?.items ?? NO_ROWS;

  // The next item after the open one on this page (pending: the open one drops out after saving).
  const nextItem = useMemo(() => {
    if (!selected) return null;
    const i = rows.findIndex((r) => r.grading_id === selected.grading_id);
    const rest = i >= 0 ? rows.slice(i + 1) : rows;
    return rest.find((r) => r.grading_id !== selected.grading_id && (status !== "pending" || !r.review)) ?? null;
  }, [rows, selected, status]);

  function onSaved(review: QueueReview) {
    setSelected((s) => (s ? { ...s, review } : s));
    void queryClient.invalidateQueries({ queryKey: ["review-queue"] });
    void queryClient.invalidateQueries({ queryKey: ["review-stats"] });
    void queryClient.invalidateQueries({ queryKey: ["admin-grading"] });
  }

  function goNext() {
    if (nextItem) {
      setSelected(nextItem);
      window.scrollTo({ top: 0 });
    } else {
      setSelected(null);
      toast.info(status === "pending" ? "No more pending stones on this page." : "End of this page.");
    }
  }

  async function exportCsv() {
    setExporting(true);
    try {
      const csv = await exportReviewsCsv(api);
      // The server CSV already has its header; strip a BOM if present before downloadCsv adds one.
      downloadCsv(`gemeye-review-labels-${new Date().toISOString().slice(0, 10)}.csv`, csv.replace(/^﻿/, ""));
      const n = Math.max(0, csv.trim().split(/\r?\n/).length - 1);
      toast.success(`Exported ${n} reviewed stones as training labels.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setExporting(false);
    }
  }

  if (selected) {
    return (
      <ReviewPanel
        key={selected.grading_id}
        item={selected}
        hasNext={!!nextItem}
        onBack={() => setSelected(null)}
        onSaved={onSaved}
        onNext={goNext}
      />
    );
  }

  return (
    <>
      <PageHeader
        title="Review queue"
        description="Referred stones waiting for a gemologist. Open one to enter the true grade."
        actions={
          isAdmin && (
            <Button variant="outline" onClick={exportCsv} disabled={exporting}>
              {exporting ? <Loader2 className="animate-spin" /> : <Download />} Export reviewed as training labels
            </Button>
          )
        }
      />
      {isAdmin && <ReviewStatsCard />}
      <FilterBar>
        <NativeSelect label="Show" value={status} onChange={(v) => setStatus(v as ReviewQueueStatus)} options={STATUS_OPTIONS} />
        <FilterField label="Model version">
          <Input value={modelInput} onChange={(e) => setModelInput(e.target.value)} placeholder="e.g. v3" className="w-28" />
        </FilterField>
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
      </FilterBar>
      <DataTable
        columns={status === "pending" ? PENDING_COLUMNS : REVIEWED_COLUMNS}
        data={rows}
        loading={queue.isPending}
        error={queue.isError ? queue.error : undefined}
        onRetry={() => void queue.refetch()}
        onRowClick={setSelected}
        getRowId={(r) => r.grading_id}
        emptyTitle={status === "pending" ? "No stones waiting for review" : "No reviewed stones"}
        emptyHint={status === "pending" ? "Referred gradings appear here until a gemologist reviews them." : "Try changing the filters."}
      />
      <Pager
        page={paging.page}
        hasNext={!!queue.data?.next_cursor}
        onPrev={paging.prev}
        onNext={() => paging.next(queue.data?.next_cursor)}
        busy={queue.isFetching}
      />
    </>
  );
}
