"use client";

import { createColumnHelper, tableFeatures, useTable, type ColumnDef, type RowData } from "@tanstack/react-table";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { useCallback, useState } from "react";

import { EmptyState, ErrorState } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { cn } from "@/lib/utils";

export const features = tableFeatures({});
export type Features = typeof features;

export function columnHelper<T extends RowData>() {
  return createColumnHelper<Features, T>();
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Columns<T extends RowData> = Array<ColumnDef<Features, T, any>>;

export function DataTable<T extends RowData>({
  columns,
  data,
  loading,
  error,
  onRetry,
  onRowClick,
  emptyTitle,
  emptyHint,
  getRowId,
}: {
  columns: Columns<T>;
  data: T[];
  loading?: boolean;
  error?: unknown;
  onRetry?: () => void;
  onRowClick?: (row: T) => void;
  emptyTitle?: string;
  emptyHint?: string;
  getRowId?: (row: T) => string;
}) {
  const table = useTable({
    features,
    columns,
    data,
    getRowId: getRowId ? (row: T) => getRowId(row) : undefined,
  });
  const colCount = columns.length;

  return (
    <div className="overflow-x-auto rounded-xl border bg-card">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((group) => (
            <TableRow key={group.id} className="hover:bg-transparent">
              {group.headers.map((header) => (
                <TableHead key={header.id} className="h-10 bg-muted/50 text-xs uppercase tracking-wide text-muted-foreground">
                  {header.isPlaceholder ? null : <table.FlexRender header={header} />}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {loading ? (
            Array.from({ length: 8 }, (_, i) => (
              <TableRow key={i}>
                <TableCell colSpan={colCount}>
                  <Skeleton className="h-5 w-full" />
                </TableCell>
              </TableRow>
            ))
          ) : error ? (
            <TableRow className="hover:bg-transparent">
              <TableCell colSpan={colCount}>
                <ErrorState error={error} onRetry={onRetry} />
              </TableCell>
            </TableRow>
          ) : data.length === 0 ? (
            <TableRow className="hover:bg-transparent">
              <TableCell colSpan={colCount}>
                <EmptyState title={emptyTitle ?? "No results"} hint={emptyHint ?? "Try changing the filters."} />
              </TableCell>
            </TableRow>
          ) : (
            table.getRowModel().rows.map((row) => (
              <TableRow
                key={row.id}
                className={cn(onRowClick && "cursor-pointer")}
                onClick={onRowClick ? () => onRowClick(row.original) : undefined}
              >
                {row.getAllCells().map((cell) => (
                  <TableCell key={cell.id} className="py-2.5">
                    <table.FlexRender cell={cell} />
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );
}

/** Previous/next paging over the API's opaque next_cursor. */
export function useCursorPaging() {
  const [stack, setStack] = useState<(string | undefined)[]>([undefined]);
  const cursor = stack[stack.length - 1];
  const next = useCallback((c: string | null | undefined) => {
    if (c) setStack((s) => [...s, c]);
  }, []);
  const prev = useCallback(() => setStack((s) => (s.length > 1 ? s.slice(0, -1) : s)), []);
  const reset = useCallback(() => setStack([undefined]), []);
  return { cursor, page: stack.length, next, prev, reset };
}

export function Pager({
  page,
  hasNext,
  onPrev,
  onNext,
  busy,
}: {
  page: number;
  hasNext: boolean;
  onPrev: () => void;
  onNext: () => void;
  busy?: boolean;
}) {
  return (
    <div className="mt-3 flex items-center justify-end gap-2 text-sm text-muted-foreground">
      <span>Page {page}</span>
      <Button variant="outline" size="sm" onClick={onPrev} disabled={page <= 1 || busy}>
        <ChevronLeft /> Previous
      </Button>
      <Button variant="outline" size="sm" onClick={onNext} disabled={!hasNext || busy}>
        Next <ChevronRight />
      </Button>
    </div>
  );
}
