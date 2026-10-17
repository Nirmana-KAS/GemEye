"use client";

import { keepPreviousData, useQuery, useQueryClient } from "@tanstack/react-query";
import { ClipboardCheck, Download, Eye, EyeOff, Loader2, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { columnHelper, DataTable, Pager, useCursorPaging, type Columns } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { GradeChip, YesNo } from "@/components/grade-chip";
import { ReasonField } from "@/components/reason-field";
import { PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { BULK_MAX, bulkConfirm, bulkSummary, canConfirm, pageState, toggleRow, togglePage } from "@/lib/admin-powers";
import { bulkGradings, exportGradingsCsv, fetchAllPages } from "@/lib/api";
import { downloadCsv, toCsv } from "@/lib/csv";
import { dayBoundIso, fmtDateTime, fmtPct } from "@/lib/format";
import { GRADES } from "@/lib/grades";
import type { BulkAction, GradingRow, Page, UserRow } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_ROWS: GradingRow[] = [];

const col = columnHelper<GradingRow>();
const timeCol = col.accessor("created_at", {
  header: "Time",
  cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span>,
});
const userCol = col.accessor("user_email", {
  header: "User",
  cell: (i) => <span className="block max-w-56 truncate">{i.getValue() ?? "-"}</span>,
});
const restCols = [
  col.accessor("grade", {
    header: "Grade",
    cell: (i) => (
      <span className="flex items-center gap-1.5">
        <GradeChip grade={i.getValue()} showName />
        {i.row.original.hidden && <Badge variant="outline">Hidden</Badge>}
      </span>
    ),
  }),
  col.accessor("confidence", { header: "Confidence", cell: (i) => <span className="tabular-nums">{fmtPct(i.getValue())}</span> }),
  col.accessor("referred", { header: "Referred", cell: (i) => <YesNo value={i.getValue()} /> }),
  col.accessor("model_version", { header: "Model", cell: (i) => i.getValue() ?? "-" }),
  col.accessor("device", { header: "Device", cell: (i) => <span className="block max-w-56 truncate">{i.getValue() ?? "-"}</span> }),
];
const ADMIN_COLUMNS: Columns<GradingRow> = [timeCol, userCol, ...restCols];
const REVIEWER_COLUMNS: Columns<GradingRow> = [timeCol, ...restCols];

type BulkDialog = Exclude<BulkAction, "export"> | null;

/** Checkbox column (admins): the header toggles this page, a row toggles itself, max 200 in all. */
function selectColumn(selected: ReadonlySet<string>, pageIds: string[], onChange: (next: Set<string>, limited: boolean) => void) {
  const state = pageState(selected, pageIds);
  const stop = (e: React.SyntheticEvent) => e.stopPropagation();
  return col.display({
    id: "select",
    header: () => (
      <span onClick={stop} className="inline-flex">
        <Checkbox
          aria-label="Select this page"
          checked={state === "all"}
          indeterminate={state === "some"}
          onCheckedChange={() => {
            const r = togglePage(selected, pageIds);
            onChange(r.next, r.limited);
          }}
        />
      </span>
    ),
    cell: (i) => (
      <span onClick={stop} className="inline-flex">
        <Checkbox
          aria-label="Select row"
          checked={selected.has(i.row.original.grading_id)}
          onCheckedChange={() => {
            const r = toggleRow(selected, i.row.original.grading_id);
            onChange(r.next, r.limited);
          }}
        />
      </span>
    ),
  });
}

export default function GradingsPage() {
  const { api, role } = useAuth();
  const router = useRouter();
  const isAdmin = role === "admin";
  const paging = useCursorPaging();
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [grade, setGrade] = useState("");
  const [referred, setReferred] = useState("");
  const [modelInput, setModelInput] = useState("");
  const [deviceInput, setDeviceInput] = useState("");
  const [emailInput, setEmailInput] = useState("");
  const [hidden, setHidden] = useState("");
  const [exporting, setExporting] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(() => new Set());
  const [bulk, setBulk] = useState<BulkDialog>(null);
  const [bulkReason, setBulkReason] = useState("");
  const [bulkExporting, setBulkExporting] = useState(false);
  const qc = useQueryClient();
  const model = useDebounced(modelInput.trim());
  const device = useDebounced(deviceInput.trim());
  const email = useDebounced(emailInput.trim().toLowerCase(), 500);

  // The API filters by uid; resolve the typed email to one user first.
  const userLookup = useQuery({
    queryKey: ["admin-user-by-email", email],
    enabled: isAdmin && email.length > 0,
    queryFn: async () => {
      const page = await api<Page<UserRow>>("/admin/users", { query: { q: email, limit: 10 } });
      const exact = page.items.find((u) => u.email?.toLowerCase() === email);
      return exact ?? (page.items.length === 1 ? page.items[0] : null);
    },
  });
  const uid = isAdmin && email ? userLookup.data?.uid : undefined;
  const noSuchUser = isAdmin && !!email && userLookup.isSuccess && !userLookup.data;

  const filters = useMemo(
    () => ({
      from: dayBoundIso(from, false),
      to: dayBoundIso(to, true),
      grade: grade || undefined,
      referred: referred || undefined,
      model_version: model || undefined,
      device: device || undefined,
      hidden: hidden || undefined,
      uid,
    }),
    [from, to, grade, referred, model, device, hidden, uid],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
    setSelected(new Set());
  }

  const waitingForUser = isAdmin && !!email && (userLookup.isPending || noSuchUser);
  const gradings = useQuery({
    queryKey: ["admin-gradings", filters, paging.cursor],
    enabled: !waitingForUser,
    queryFn: () => api<Page<GradingRow>>("/admin/gradings", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  async function exportCsv() {
    setExporting(true);
    try {
      const { items, truncated } = await fetchAllPages((cursor) =>
        api<Page<GradingRow>>("/admin/gradings", { query: { ...filters, limit: 100, cursor } }),
      );
      const csv = toCsv(items, [
        { header: "grading_id", value: (r) => r.grading_id },
        { header: "stone_id", value: (r) => r.stone_id },
        { header: "created_at", value: (r) => r.created_at },
        { header: "user_email", value: (r) => r.user_email },
        { header: "grade", value: (r) => r.grade },
        { header: "grade_name", value: (r) => r.grade_name },
        { header: "confidence", value: (r) => r.confidence },
        { header: "uncertainty", value: (r) => r.uncertainty },
        { header: "referred", value: (r) => r.referred },
        { header: "model_version", value: (r) => r.model_version },
        { header: "device", value: (r) => r.device },
        { header: "app_version", value: (r) => r.app_version },
        { header: "warnings", value: (r) => r.warnings.join(" ") },
      ]);
      downloadCsv(`gemeye-gradings-${new Date().toISOString().slice(0, 10)}.csv`, csv);
      toast.success(`Exported ${items.length} gradings${truncated ? " (first 2000 only)" : ""}.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setExporting(false);
    }
  }

  const rows = noSuchUser ? NO_ROWS : (gradings.data?.items ?? NO_ROWS);
  const pageIds = rows.map((r) => r.grading_id);
  const onSelect = (next: Set<string>, limited: boolean) => {
    setSelected(next);
    if (limited) toast.warning(`At most ${BULK_MAX} gradings can be selected.`);
  };
  const columns = isAdmin ? [selectColumn(selected, pageIds, onSelect), ...ADMIN_COLUMNS] : REVIEWER_COLUMNS;
  const spec = bulk ? bulkConfirm(bulk, selected.size) : null;

  const openBulk = (a: Exclude<BulkAction, "export">) => {
    setBulkReason("");
    setBulk(a);
  };

  async function runBulk() {
    if (!bulk) return;
    const r = await bulkGradings(api, bulk, [...selected], bulkReason.trim() || undefined);
    toast.success(bulkSummary(r));
    setSelected(new Set());
    void qc.invalidateQueries({ queryKey: ["admin-gradings"] });
  }

  async function exportSelected() {
    setBulkExporting(true);
    try {
      const csv = await exportGradingsCsv(api, [...selected]);
      downloadCsv(`gemeye-gradings-selected-${new Date().toISOString().slice(0, 10)}.csv`, csv);
      toast.success(`Exported ${selected.size} gradings.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setBulkExporting(false);
    }
  }

  return (
    <>
      <PageHeader
        title="Gradings"
        description="Every stone graded by the model, newest first."
        actions={
          isAdmin && (
            <Button variant="outline" onClick={exportCsv} disabled={exporting || noSuchUser}>
              {exporting ? <Loader2 className="animate-spin" /> : <Download />} Export CSV
            </Button>
          )
        }
      />
      <FilterBar>
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
        <NativeSelect
          label="Grade"
          value={grade}
          onChange={setGrade}
          options={[{ value: "", label: "All grades" }, ...GRADES.map((g) => ({ value: String(g.grade), label: `${g.grade} - ${g.name}` }))]}
        />
        <NativeSelect
          label="Referred"
          value={referred}
          onChange={setReferred}
          options={[
            { value: "", label: "Any" },
            { value: "true", label: "Referred" },
            { value: "false", label: "Not referred" },
          ]}
        />
        <FilterField label="Model version">
          <Input value={modelInput} onChange={(e) => setModelInput(e.target.value)} placeholder="e.g. v3" className="w-28" />
        </FilterField>
        <FilterField label="Device">
          <Input value={deviceInput} onChange={(e) => setDeviceInput(e.target.value)} placeholder="Contains" className="w-40" />
        </FilterField>
        {isAdmin && (
          <NativeSelect
            label="Visibility"
            value={hidden}
            onChange={setHidden}
            options={[
              { value: "", label: "All" },
              { value: "false", label: "Visible in app" },
              { value: "true", label: "Hidden" },
            ]}
          />
        )}
        {isAdmin && (
          <FilterField label="User email">
            <Input value={emailInput} onChange={(e) => setEmailInput(e.target.value)} placeholder="name@example.com" className="w-56" />
          </FilterField>
        )}
      </FilterBar>
      {isAdmin && selected.size > 0 && (
        <div className="sticky top-14 z-20 mb-3 flex flex-wrap items-center gap-2 rounded-xl border bg-card p-2 shadow-sm">
          <span className="px-2 text-sm font-medium">
            {selected.size} selected <span className="text-muted-foreground">(max {BULK_MAX})</span>
          </span>
          <Button size="sm" variant="outline" onClick={() => openBulk("hide")}>
            <EyeOff /> Hide
          </Button>
          <Button size="sm" variant="outline" onClick={() => openBulk("restore")}>
            <Eye /> Restore
          </Button>
          <Button size="sm" variant="outline" onClick={() => openBulk("send_to_review")}>
            <ClipboardCheck /> Send to review
          </Button>
          <Button size="sm" variant="outline" onClick={exportSelected} disabled={bulkExporting}>
            {bulkExporting ? <Loader2 className="animate-spin" /> : <Download />} Export CSV
          </Button>
          <Button size="sm" variant="ghost" className="ml-auto" onClick={() => setSelected(new Set())}>
            <X /> Clear
          </Button>
        </div>
      )}
      <DataTable
        columns={columns}
        data={rows}
        loading={!noSuchUser && (gradings.isPending || (waitingForUser && userLookup.isPending))}
        error={gradings.isError ? gradings.error : undefined}
        onRetry={() => void gradings.refetch()}
        onRowClick={(r) => router.push(`/admin/gradings/detail/?id=${encodeURIComponent(r.grading_id)}`)}
        getRowId={(r) => r.grading_id}
        emptyTitle={noSuchUser ? "No user with that email" : "No gradings found"}
      />
      <Pager
        page={paging.page}
        hasNext={!noSuchUser && !!gradings.data?.next_cursor}
        onPrev={paging.prev}
        onNext={() => paging.next(gradings.data?.next_cursor)}
        busy={gradings.isFetching}
      />
      {spec && (
        <ConfirmDialog
          open={bulk !== null}
          onOpenChange={(o) => !o && setBulk(null)}
          title={spec.title}
          description={spec.description}
          confirmLabel={spec.confirmLabel}
          destructive={spec.destructive}
          confirmText={spec.confirmText}
          confirmDisabled={!canConfirm({ reasonRequired: spec.reasonRequired }, bulkReason, "")}
          onConfirm={runBulk}
        >
          <ReasonField value={bulkReason} onChange={setBulkReason} label={spec.reasonLabel} id="bulk-reason" />
        </ConfirmDialog>
      )}
    </>
  );
}
