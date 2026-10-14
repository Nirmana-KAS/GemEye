"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { Download, Loader2, Search } from "lucide-react";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { PageHeader } from "@/components/states";
import { RoleBadge, StatusBadge } from "@/components/user-badges";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { fetchAllPages } from "@/lib/api";
import { downloadCsv, toCsv } from "@/lib/csv";
import { fmtAgo, fmtDate, fmtDateTime } from "@/lib/format";
import type { Page, UserRow } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_ROWS: UserRow[] = [];

const col = columnHelper<UserRow>();
const columns = col.columns([
  col.accessor("email", {
    header: "User",
    cell: (info) => (
      <div className="min-w-0">
        <div className="truncate font-medium">{info.getValue() ?? "(no email)"}</div>
        <div className="truncate text-xs text-muted-foreground">{info.row.original.display_name ?? "-"}</div>
      </div>
    ),
  }),
  col.accessor("role", { header: "Role", cell: (info) => <RoleBadge role={info.getValue()} /> }),
  col.accessor("disabled", { header: "Status", cell: (info) => <StatusBadge disabled={info.getValue()} /> }),
  col.accessor("account_type", { header: "Type", cell: (info) => <span className="capitalize">{info.getValue() ?? "-"}</span> }),
  col.accessor("country", { header: "Country", cell: (info) => info.getValue() ?? "-" }),
  col.accessor("created_at", { header: "Created", cell: (info) => fmtDate(info.getValue()) }),
  col.accessor("last_active", {
    header: "Last active",
    cell: (info) => <span title={fmtDateTime(info.getValue())}>{fmtAgo(info.getValue())}</span>,
  }),
]);

export default function UsersPage() {
  const api = useApi();
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [role, setRole] = useState("");
  const [disabled, setDisabled] = useState("");
  const [sort, setSort] = useState<"created" | "last_active">("created");
  const [exporting, setExporting] = useState(false);
  const q = useDebounced(search.trim());
  const paging = useCursorPaging();

  const filters = useMemo(() => ({ q: q || undefined, role: role || undefined, disabled: disabled || undefined, sort }), [q, role, disabled, sort]);
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    // New filters start again at page 1.
    setLastFilters(filters);
    paging.reset();
  }

  const users = useQuery({
    queryKey: ["admin-users", filters, paging.cursor],
    queryFn: () => api<Page<UserRow>>("/admin/users", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  async function exportCsv() {
    setExporting(true);
    try {
      const { items, truncated } = await fetchAllPages((cursor) =>
        api<Page<UserRow>>("/admin/users", { query: { ...filters, limit: 100, cursor } }),
      );
      // No uids in the export; email is allowed for admins.
      const csv = toCsv(items, [
        { header: "email", value: (u) => u.email },
        { header: "display_name", value: (u) => u.display_name },
        { header: "role", value: (u) => u.role },
        { header: "disabled", value: (u) => u.disabled },
        { header: "account_type", value: (u) => u.account_type },
        { header: "country", value: (u) => u.country },
        { header: "created_at", value: (u) => u.created_at },
        { header: "last_active", value: (u) => u.last_active },
      ]);
      downloadCsv(`gemeye-users-${new Date().toISOString().slice(0, 10)}.csv`, csv);
      toast.success(`Exported ${items.length} users${truncated ? " (first 2000 only)" : ""}.`);
    } catch {
      // The API client already showed the error.
    } finally {
      setExporting(false);
    }
  }

  return (
    <>
      <PageHeader
        title="Users"
        description="Accounts registered in the GemEye app."
        actions={
          <Button variant="outline" onClick={exportCsv} disabled={exporting}>
            {exporting ? <Loader2 className="animate-spin" /> : <Download />} Export CSV
          </Button>
        }
      />
      <FilterBar>
        <FilterField label="Search" className="w-72">
          <div className="relative">
            <Search className="absolute top-2 left-2.5 size-4 text-muted-foreground" />
            <Input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Email or name" className="pl-8" />
          </div>
        </FilterField>
        <NativeSelect
          label="Role"
          value={role}
          onChange={setRole}
          options={[
            { value: "", label: "Any role" },
            { value: "admin", label: "Admin" },
            { value: "reviewer", label: "Reviewer" },
            { value: "none", label: "User" },
          ]}
        />
        <NativeSelect
          label="Status"
          value={disabled}
          onChange={setDisabled}
          options={[
            { value: "", label: "Any status" },
            { value: "false", label: "Active" },
            { value: "true", label: "Disabled" },
          ]}
        />
        <NativeSelect
          label="Sort by"
          value={sort}
          onChange={(v) => setSort(v as "created" | "last_active")}
          options={[
            { value: "created", label: "Newest first" },
            { value: "last_active", label: "Last active" },
          ]}
        />
      </FilterBar>
      <DataTable
        columns={columns}
        data={users.data?.items ?? NO_ROWS}
        loading={users.isPending}
        error={users.isError ? users.error : undefined}
        onRetry={() => void users.refetch()}
        onRowClick={(u) => router.push(`/admin/users/detail/?uid=${encodeURIComponent(u.uid)}`)}
        getRowId={(u) => u.uid}
        emptyTitle="No users found"
      />
      <Pager
        page={paging.page}
        hasNext={!!users.data?.next_cursor}
        onPrev={paging.prev}
        onNext={() => paging.next(users.data?.next_cursor)}
        busy={users.isFetching}
      />
    </>
  );
}
