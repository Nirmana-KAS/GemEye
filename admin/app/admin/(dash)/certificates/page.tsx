"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { useApi } from "@/components/auth-provider";
import { CertStatus } from "@/components/cert-status";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect, useDebounced } from "@/components/filters";
import { GradeChip } from "@/components/grade-chip";
import { PageHeader } from "@/components/states";
import { Input } from "@/components/ui/input";
import { fmtDateTime } from "@/lib/format";
import type { CertificateRow, Page } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_ROWS: CertificateRow[] = [];

const col = columnHelper<CertificateRow>();
const columns = col.columns([
  col.accessor("cert_no", { header: "Number", cell: (i) => <span className="font-mono text-xs">{i.getValue()}</span> }),
  col.accessor((r) => r.snapshot?.grade ?? null, { id: "grade", header: "Grade", cell: (i) => <GradeChip grade={i.getValue()} showName /> }),
  col.accessor("user_email", {
    header: "User",
    cell: (i) => i.getValue() ?? <span className="text-muted-foreground">{i.row.original.status === "withdrawn" ? "deleted account" : "-"}</span>,
  }),
  col.accessor("issued_at", { header: "Issued", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
  col.display({ id: "status", header: "Status", cell: (i) => <CertStatus c={i.row.original} /> }),
]);

export default function CertificatesPage() {
  const api = useApi();
  const router = useRouter();
  const paging = useCursorPaging();
  const [noInput, setNoInput] = useState("");
  const [emailInput, setEmailInput] = useState("");
  const [status, setStatus] = useState("");
  const q = useDebounced(noInput.trim());
  const email = useDebounced(emailInput.trim());

  const filters = useMemo(() => ({ q: q || undefined, email: email || undefined, status: status || undefined }), [q, email, status]);
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const list = useQuery({
    queryKey: ["admin-certificates", filters, paging.cursor],
    queryFn: () => api<Page<CertificateRow>>("/admin/certificates", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <PageHeader title="Certificates" description="Issued certificates. Open one to see its snapshot, revoke or supersede it." />
      <FilterBar>
        <FilterField label="Certificate number">
          <Input value={noInput} onChange={(e) => setNoInput(e.target.value)} placeholder="GE-202610-" className="w-48 font-mono text-xs" />
        </FilterField>
        <FilterField label="User email">
          <Input value={emailInput} onChange={(e) => setEmailInput(e.target.value)} placeholder="Contains" className="w-56" />
        </FilterField>
        <NativeSelect
          label="Status"
          value={status}
          onChange={setStatus}
          options={[
            { value: "", label: "Any" },
            { value: "valid", label: "Valid" },
            { value: "revoked", label: "Revoked" },
            { value: "superseded", label: "Superseded" },
            { value: "withdrawn", label: "Withdrawn" },
          ]}
        />
      </FilterBar>
      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.cert_no}
        onRowClick={(r) => router.push(`/admin/certificates/detail/?no=${encodeURIComponent(r.cert_no)}`)}
        emptyTitle="No certificates"
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />
    </>
  );
}
