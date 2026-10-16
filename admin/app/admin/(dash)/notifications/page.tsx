"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { useApi } from "@/components/auth-provider";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { FilterBar, FilterField, NativeSelect } from "@/components/filters";
import { SendNotificationForm } from "@/components/send-notification-form";
import { PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { dayBoundIso, fmtDateTime } from "@/lib/format";
import { notificationStatus } from "@/lib/notifications";
import type { AllNotificationRow, AllNotificationStatus, Broadcast, Page } from "@/lib/types";

const PAGE_SIZE = 25;
const NO_BROADCASTS: Broadcast[] = [];
const NO_ROWS: AllNotificationRow[] = [];

const b = columnHelper<Broadcast>();
const broadcastColumns = b.columns([
  b.accessor("at", { header: "Sent", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
  b.accessor("target", {
    header: "To",
    cell: (i) => (i.getValue() === "all" ? <Badge>All users</Badge> : (i.row.original.user_email ?? i.row.original.uid ?? "-")),
  }),
  b.accessor("count", { header: "Recipients", cell: (i) => <span className="tabular-nums">{i.getValue()}</span> }),
  b.accessor("title", { header: "Title" }),
  b.accessor("type", { header: "Type", cell: (i) => <span className="capitalize">{i.getValue()}</span> }),
  b.accessor("sent_by_email", { header: "Sent by", cell: (i) => i.getValue() ?? "-" }),
]);

const n = columnHelper<AllNotificationRow>();
const notificationColumns = n.columns([
  n.accessor("created_at", { header: "Time", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
  n.accessor("user_email", { header: "User", cell: (i) => i.getValue() ?? i.row.original.uid }),
  n.accessor("source", {
    header: "Source",
    cell: (i) => (
      <span className="capitalize">
        {i.getValue()}
        {i.row.original.sent_by_email && <span className="block text-xs text-muted-foreground">{i.row.original.sent_by_email}</span>}
      </span>
    ),
  }),
  n.accessor("type", { header: "Type", cell: (i) => <span className="capitalize">{i.getValue()}</span> }),
  n.accessor("title", { header: "Title" }),
  n.accessor("message", { header: "Message", cell: (i) => <span className="line-clamp-2 max-w-md text-muted-foreground">{i.getValue()}</span> }),
  n.accessor("read_at", { header: "Read", cell: (i) => (i.getValue() ? "Yes" : "No") }),
  n.display({
    id: "status",
    header: "Status",
    cell: (i) => {
      const s = notificationStatus(i.row.original);
      return s.kind === "visible" ? <span className="text-xs text-success">{s.label}</span> : <Badge variant="secondary">{s.label}</Badge>;
    },
  }),
]);

function SentHistory() {
  const api = useApi();
  const paging = useCursorPaging();
  const [target, setTarget] = useState("");
  const list = useQuery({
    queryKey: ["admin-broadcasts", target, paging.cursor],
    queryFn: () => api<Page<Broadcast>>("/admin/broadcasts", { query: { target: target || undefined, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });
  return (
    <>
      <FilterBar>
        <NativeSelect
          label="To"
          value={target}
          onChange={(v) => {
            setTarget(v);
            paging.reset();
          }}
          options={[
            { value: "", label: "Anyone" },
            { value: "all", label: "All users" },
            { value: "user", label: "One user" },
          ]}
        />
      </FilterBar>
      <DataTable
        columns={broadcastColumns}
        data={list.data?.items ?? NO_BROADCASTS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.id}
        emptyTitle="Nothing sent yet"
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />
    </>
  );
}

function AllNotifications() {
  const api = useApi();
  const router = useRouter();
  const paging = useCursorPaging();
  const [status, setStatus] = useState<AllNotificationStatus>("all");
  const [source, setSource] = useState("");
  const [uid, setUid] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const filters = useMemo(
    () => ({
      status,
      source: source || undefined,
      uid: uid.trim() || undefined,
      from: dayBoundIso(from, false),
      to: dayBoundIso(to, true),
    }),
    [status, source, uid, from, to],
  );
  const [lastFilters, setLastFilters] = useState(filters);
  if (lastFilters !== filters) {
    setLastFilters(filters);
    paging.reset();
  }

  const list = useQuery({
    queryKey: ["admin-all-notifications", filters, paging.cursor],
    queryFn: () => api<Page<AllNotificationRow>>("/admin/notifications", { query: { ...filters, limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });

  return (
    <>
      <FilterBar>
        <NativeSelect
          label="Status"
          value={status}
          onChange={(v) => setStatus(v as AllNotificationStatus)}
          options={[
            { value: "all", label: "All" },
            { value: "visible", label: "Visible" },
            { value: "cleared", label: "Cleared" },
            { value: "read", label: "Read" },
            { value: "unread", label: "Unread" },
          ]}
        />
        <NativeSelect
          label="Source"
          value={source}
          onChange={setSource}
          options={[
            { value: "", label: "Any" },
            { value: "app", label: "App" },
            { value: "server", label: "Server" },
            { value: "admin", label: "Admin" },
          ]}
        />
        <FilterField label="User ID">
          <Input value={uid} onChange={(e) => setUid(e.target.value)} placeholder="uid" className="w-56 font-mono text-xs" />
        </FilterField>
        <FilterField label="From">
          <Input type="date" value={from} max={to || undefined} onChange={(e) => setFrom(e.target.value)} className="w-36" />
        </FilterField>
        <FilterField label="To">
          <Input type="date" value={to} min={from || undefined} onChange={(e) => setTo(e.target.value)} className="w-36" />
        </FilterField>
      </FilterBar>
      <DataTable
        columns={notificationColumns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.id}
        onRowClick={(r) => router.push(`/admin/users/detail/?uid=${encodeURIComponent(r.uid)}&tab=notifications`)}
        emptyTitle="No notifications"
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />
    </>
  );
}

export default function NotificationsPage() {
  const [tab, setTab] = useState("send");
  return (
    <>
      <PageHeader title="Notifications" description="Send in-app notifications and see every user's notifications." />
      <Tabs value={tab} onValueChange={(v) => setTab(String(v))}>
        <TabsList>
          <TabsTrigger value="send">Send</TabsTrigger>
          <TabsTrigger value="history">Sent history</TabsTrigger>
          <TabsTrigger value="all">All notifications</TabsTrigger>
        </TabsList>
        <TabsContent value="send" className="mt-4">
          <Card className="max-w-2xl">
            <CardHeader>
              <CardTitle className="text-base">Send a notification</CardTitle>
              <CardDescription>It appears in the app&apos;s notification list. Every send is audited.</CardDescription>
            </CardHeader>
            <CardContent>
              <SendNotificationForm onSent={() => setTab("history")} />
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="history" className="mt-4">
          <SentHistory />
        </TabsContent>
        <TabsContent value="all" className="mt-4">
          <AllNotifications />
        </TabsContent>
      </Tabs>
    </>
  );
}
