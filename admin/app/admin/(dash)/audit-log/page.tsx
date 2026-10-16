"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { ChevronDown, ChevronRight, Download } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { PageHeader } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { fetchAllPages } from "@/lib/api";
import { auditDiff, targetText } from "@/lib/audit";
import { downloadCsv, toCsv } from "@/lib/csv";
import { dayBoundIso, fmtDateTime } from "@/lib/format";
import type { AuditRow, Page } from "@/lib/types";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 25;
const NO_ROWS: AuditRow[] = [];

const ACTIONS = [
  "account_deleted",
  "announcement_create",
  "announcement_delete",
  "announcement_update",
  "certificate_revoke",
  "certificate_supersede",
  "config_reset_gates",
  "config_update",
  "feedback_status",
  "notification_restore",
  "notification_restore_all",
  "notification_send",
  "review_create",
  "review_export",
  "review_update",
  "user_delete",
  "user_disable",
  "user_enable",
  "user_password_reset",
  "user_role",
];

function DiffView({ row }: { row: AuditRow }) {
  const rows = auditDiff(row.before, row.after);
  if (!rows.length) return <p className="text-xs text-muted-foreground">No before/after values recorded.</p>;
  return (
    <table className="mt-2 w-full max-w-3xl rounded-lg border text-xs">
      <thead className="bg-muted/50 text-muted-foreground">
        <tr>
          <th className="px-2 py-1 text-left font-medium">Field</th>
          <th className="px-2 py-1 text-left font-medium">Before</th>
          <th className="px-2 py-1 text-left font-medium">After</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((d) => (
          <tr key={d.key} className={cn("border-t align-top", d.changed && "bg-warning/10")}>
            <td className="px-2 py-1 font-mono">{d.key}</td>
            <td className="break-all px-2 py-1 font-mono text-muted-foreground">{d.before}</td>
            <td className="break-all px-2 py-1 font-mono">{d.after}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default function AuditLogPage() {
  const api = useApi();
  const paging = useCursorPaging();
  const [action, setAction] = useState("");
  const [adminInput, setAdminInput] = useState("");
  const [targetInput, setTargetInput] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [open, setOpen] = useState<Set<string>>(new Set());
  const [exporting, setExporting] = useState(false);
  const admin = useDebounced(adminInput.trim());
  const target = useDebounced(targetInput.trim());

  const filters = useMemo(
    () => ({
      action: action || undefined,
      admin: admin || undefined,
      target: target || undefined,
      from: dayBoundIso(from, false),
      to: dayBoundIso(to, true),
    }),
    [action, admin, target, from, to],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const list = useQuery({
    queryKey: ["admin-audit", filters, paging.cursor],
    queryFn: () => api<Page<AuditRow>>("/admin/audit-log", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  const toggle = (id: string) =>
    setOpen((s) => {
      const n = new Set(s);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });

  async function exportCsv() {
    setExporting(true);
    try {
      const { items, truncated } = await fetchAllPages(
        (cursor) => api<Page<AuditRow>>("/admin/audit-log", { query: { ...filters, limit: 100, cursor } }),
        10000,
      );
      const json = (v: unknown) => (v == null ? "" : JSON.stringify(v));
      downloadCsv(
        "gemeye_audit_log.csv",
        toCsv(items, [
          { header: "time", value: (r) => r.at },
          { header: "admin_email", value: (r) => r.admin_email },
          { header: "admin_uid_hash", value: (r) => r.uid_hash },
          { header: "role", value: (r) => r.role },
          { header: "action", value: (r) => r.action },
          { header: "target", value: (r) => json(r.target) },
          { header: "before", value: (r) => json(r.before) },
          { header: "after", value: (r) => json(r.after) },
        ]),
      );
      toast.success(truncated ? `Exported the latest ${items.length} entries.` : `Exported ${items.length} entries.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setExporting(false);
    }
  }

  const col = columnHelper<AuditRow>();
  const columns = col.columns([
    col.display({
      id: "expand",
      header: "",
      cell: (i) =>
        open.has(i.row.original.audit_id) ? <ChevronDown className="size-4 text-muted-foreground" /> : <ChevronRight className="size-4 text-muted-foreground" />,
    }),
    col.accessor("at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
    col.accessor("admin_email", {
      header: "Admin",
      cell: (i) =>
        i.getValue() ?? (
          <span className="font-mono text-xs text-muted-foreground" title={i.row.original.uid_hash ?? undefined}>
            {i.row.original.uid_hash ? `${i.row.original.uid_hash.slice(0, 10)}...` : "system"}
          </span>
        ),
    }),
    col.accessor("action", { header: "Action", cell: (i) => <span className="font-mono text-xs">{i.getValue()}</span> }),
    col.display({
      id: "target",
      header: "Target / changes",
      cell: (i) => (
        <div className="min-w-0">
          <span className="break-all font-mono text-xs">{targetText(i.row.original.target)}</span>
          {open.has(i.row.original.audit_id) && <DiffView row={i.row.original} />}
        </div>
      ),
    }),
  ]);

  return (
    <>
      <PageHeader
        title="Audit log"
        description="Every admin and reviewer write. Read only."
        actions={
          <Button variant="outline" onClick={() => void exportCsv()} disabled={exporting}>
            <Download /> Export CSV
          </Button>
        }
      />
      <FilterBar>
        <NativeSelect label="Action" value={action} onChange={setAction} options={[{ value: "", label: "Any" }, ...ACTIONS.map((a) => ({ value: a, label: a }))]} />
        <FilterField label="Admin">
          <Input value={adminInput} onChange={(e) => setAdminInput(e.target.value)} placeholder="Email contains" className="w-52" />
        </FilterField>
        <FilterField label="Target ID">
          <Input value={targetInput} onChange={(e) => setTargetInput(e.target.value)} placeholder="uid, cert no, id" className="w-56 font-mono text-xs" />
        </FilterField>
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
      </FilterBar>
      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.audit_id}
        onRowClick={(r) => toggle(r.audit_id)}
        emptyTitle="No audit entries"
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />
    </>
  );
}
