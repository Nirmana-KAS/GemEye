"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { RotateCcw } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, NativeSelect } from "@/components/filters";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { listUserNotifications, restoreAllUserNotifications, restoreUserNotification } from "@/lib/api";
import { fmtDateTime } from "@/lib/format";
import { notificationStatus } from "@/lib/notifications";
import type { AdminNotification, NotificationStatusFilter } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_ROWS: AdminNotification[] = [];

function StatusChip({ n }: { n: AdminNotification }) {
  const s = notificationStatus(n);
  if (s.kind === "cleared") return <Badge variant="secondary">{s.label}</Badge>;
  if (s.kind === "restored") return <Badge variant="outline">{s.label}</Badge>;
  return <span className="text-xs font-medium text-success">{s.label}</span>;
}

/** Every notification of one user, cleared ones included, with restore (admin only). */
export function UserNotifications({ uid }: { uid: string }) {
  const { api } = useAuth();
  const qc = useQueryClient();
  const paging = useCursorPaging();
  const [status, setStatus] = useState<NotificationStatusFilter>("all");
  const [restoreId, setRestoreId] = useState<string | null>(null);
  const [restoreAll, setRestoreAll] = useState(false);

  const list = useQuery({
    queryKey: ["admin-user-notifications", uid, status, paging.cursor],
    queryFn: () => listUserNotifications(api, uid, { status, limit: PAGE_SIZE, cursor: paging.cursor }),
  });
  const refetch = () => void qc.invalidateQueries({ queryKey: ["admin-user-notifications", uid] });

  const restoreOne = useMutation({
    mutationFn: (id: string) => restoreUserNotification(api, uid, id),
    onSuccess: () => {
      toast.success("Notification restored. The user sees it again.");
      refetch();
    },
  });
  const restoreEvery = useMutation({
    mutationFn: () => restoreAllUserNotifications(api, uid),
    onSuccess: (r) => {
      toast.success(r.restored === 1 ? "1 notification restored." : `${r.restored} notifications restored.`);
      paging.reset();
      refetch();
    },
  });

  const n = columnHelper<AdminNotification>();
  const columns = n.columns([
    n.accessor("created_at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
    n.accessor("type", { header: "Type", cell: (i) => <span className="capitalize">{i.getValue()}</span> }),
    n.accessor("category", { header: "Category", cell: (i) => <span className="capitalize">{i.getValue() ?? "-"}</span> }),
    n.accessor("title", { header: "Title" }),
    n.accessor("message", {
      header: "Message",
      cell: (i) => <span className="line-clamp-2 max-w-md text-muted-foreground">{i.getValue()}</span>,
    }),
    n.accessor("read_at", { header: "Read", cell: (i) => (i.getValue() ? "Yes" : "No") }),
    n.display({ id: "status", header: "Status", cell: (i) => <StatusChip n={i.row.original} /> }),
    n.display({
      id: "actions",
      header: "",
      cell: (i) =>
        i.row.original.cleared_at ? (
          <Button variant="outline" size="sm" onClick={() => setRestoreId(i.row.original.id)}>
            <RotateCcw /> Restore
          </Button>
        ) : null,
    }),
  ]);

  const cleared = list.data?.counts.cleared ?? 0;

  return (
    <>
      <FilterBar>
        <NativeSelect
          label="Show"
          value={status}
          onChange={(v) => {
            setStatus(v as NotificationStatusFilter);
            paging.reset();
          }}
          options={[
            { value: "all", label: "All" },
            { value: "visible", label: "Visible" },
            { value: "cleared", label: "Cleared" },
          ]}
        />
        <div className="ml-auto flex items-end gap-3">
          {list.data && (
            <span className="pb-2 text-sm text-muted-foreground">
              {list.data.counts.visible} visible, {cleared} cleared
            </span>
          )}
          <Button variant="outline" onClick={() => setRestoreAll(true)} disabled={!cleared || restoreEvery.isPending}>
            <RotateCcw /> Restore all cleared
          </Button>
        </div>
      </FilterBar>
      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.id}
        emptyTitle="No notifications"
      />
      <Pager
        page={paging.page}
        hasNext={!!list.data?.next_cursor}
        onPrev={paging.prev}
        onNext={() => paging.next(list.data?.next_cursor)}
        busy={list.isFetching}
      />

      <ConfirmDialog
        open={restoreId !== null}
        onOpenChange={(o) => !o && setRestoreId(null)}
        title="Restore this notification?"
        description="It shows again in the user's notification list."
        confirmLabel="Restore"
        onConfirm={async () => {
          if (restoreId) await restoreOne.mutateAsync(restoreId);
          setRestoreId(null);
        }}
      />
      <ConfirmDialog
        open={restoreAll}
        onOpenChange={setRestoreAll}
        title={`Restore all ${cleared} cleared notifications?`}
        description="They all show again in the user's notification list."
        confirmLabel="Restore all"
        onConfirm={() => restoreEvery.mutateAsync()}
      />
    </>
  );
}
