"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, ChevronRight, Info, Loader2, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { Controller, useForm, useWatch, type FieldPath } from "react-hook-form";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { columnHelper, DataTable, Pager, useCursorPaging } from "@/components/data-table";
import { NativeSelect } from "@/components/filters";
import { PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  ACTION_OPTIONS,
  announcementDefaults,
  announcementFormSchema,
  announcementStatus,
  BODY_MAX,
  STATUS_LABELS,
  TITLE_MAX,
  toAnnouncementBody,
  type AnnouncementFormValues,
  type AnnouncementStatus,
} from "@/lib/announcements";
import { ApiError } from "@/lib/api";
import { fmtDateTime } from "@/lib/format";
import type { Announcement, Page, SendResult } from "@/lib/types";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 25;
const NO_ROWS: Announcement[] = [];

const STATUS_TONE: Record<AnnouncementStatus, string> = {
  active: "bg-success/15 text-success",
  scheduled: "bg-primary/10 text-primary dark:text-accent-foreground",
  expired: "bg-muted text-muted-foreground",
  draft: "bg-warning/15 text-warning",
};

function StatusChip({ a }: { a: Announcement }) {
  const s = announcementStatus(a);
  return <span className={cn("rounded-md px-1.5 py-0.5 text-xs font-medium", STATUS_TONE[s])}>{STATUS_LABELS[s]}</span>;
}

/** Approximation of the app's Home banner (white card, Royal Blue or amber accent). */
function BannerPreview({ title, message, level, action }: { title: string; message: string; level: "info" | "warning"; action: string }) {
  const warn = level === "warning";
  return (
    <div className="rounded-2xl border border-[#E5E7F0] bg-white p-3 text-[#1A1D2E] shadow-sm">
      <div className="flex gap-3">
        <div
          className={cn(
            "flex size-9 shrink-0 items-center justify-center rounded-full",
            warn ? "bg-[#F59E0B]/15 text-[#F59E0B]" : "bg-[#EEF1FA] text-[#1B3A8C]",
          )}
        >
          {warn ? <AlertTriangle className="size-4" /> : <Info className="size-4" />}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold">{title || "Announcement title"}</p>
          <p className="mt-0.5 line-clamp-3 text-xs text-[#6B7089]">{message || "The message users see on the Home screen."}</p>
        </div>
        {action !== "none" && <ChevronRight className="mt-2 size-4 shrink-0 text-[#A0A4B8]" />}
      </div>
    </div>
  );
}

function Err({ message }: { message?: string }) {
  return message ? <p className="text-xs text-destructive">{message}</p> : null;
}

function AnnouncementDialog({
  open,
  editing,
  onClose,
}: {
  open: boolean;
  editing: Announcement | null;
  onClose: () => void;
}) {
  const api = useApi();
  const qc = useQueryClient();
  const form = useForm<AnnouncementFormValues>({
    resolver: zodResolver(announcementFormSchema),
    defaultValues: announcementDefaults(editing),
  });
  const { errors, isSubmitting } = form.formState;
  const [title, message, level, action, notify] = useWatch({
    control: form.control,
    name: ["title", "message", "level", "action", "notify"],
  });

  async function submit(v: AnnouncementFormValues) {
    const body = toAnnouncementBody(v);
    try {
      if (editing) await api(`/admin/announcements/${encodeURIComponent(editing.id)}`, { method: "PUT", body, silent: true });
      else await api("/admin/announcements", { method: "POST", body, silent: true });
    } catch (e) {
      const err = e instanceof ApiError ? e : null;
      for (const f of err?.fields ?? []) {
        if (f.field) form.setError(f.field as FieldPath<AnnouncementFormValues>, { type: "server", message: f.message });
      }
      toast.error(err?.message ?? "Could not save the announcement.");
      return;
    }
    toast.success(editing ? "Announcement updated." : "Announcement created.");
    void qc.invalidateQueries({ queryKey: ["admin-announcements"] });
    if (v.notify) {
      try {
        const r = await api<SendResult>("/admin/notifications/send", {
          method: "POST",
          silent: true,
          body: { target: "all", type: v.level, title: body.title, message: body.message, action: v.action },
        });
        toast.success(`Also sent as a notification to ${r.count} users.`);
        void qc.invalidateQueries({ queryKey: ["admin-broadcasts"] });
      } catch (e) {
        toast.error(`Saved, but the notification was not sent: ${e instanceof ApiError ? e.message : "unknown error"}`);
      }
    }
    onClose();
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !o && !isSubmitting && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit announcement" : "New announcement"}</DialogTitle>
          <DialogDescription>Shown as a banner on the app&apos;s Home screen while it is active.</DialogDescription>
        </DialogHeader>
        <form id="announcement-form" onSubmit={form.handleSubmit(submit)} className="grid gap-4 md:grid-cols-[1fr_260px]">
          <div className="space-y-3">
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Label htmlFor="a-title">Title</Label>
                <span className={cn("text-xs text-muted-foreground", title.length > TITLE_MAX && "text-destructive")}>
                  {title.length}/{TITLE_MAX}
                </span>
              </div>
              <Input id="a-title" aria-invalid={!!errors.title} {...form.register("title")} />
              <Err message={errors.title?.message} />
            </div>
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Label htmlFor="a-message">Message</Label>
                <span className={cn("text-xs text-muted-foreground", message.length > BODY_MAX && "text-destructive")}>
                  {message.length}/{BODY_MAX}
                </span>
              </div>
              <textarea
                id="a-message"
                rows={4}
                aria-invalid={!!errors.message}
                className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive dark:bg-input/30"
                {...form.register("message")}
              />
              <Err message={errors.message?.message} />
            </div>
            <div className="flex flex-wrap gap-3">
              <Controller
                control={form.control}
                name="level"
                render={({ field }) => (
                  <NativeSelect
                    label="Level"
                    value={field.value}
                    onChange={field.onChange}
                    options={[
                      { value: "info", label: "Info" },
                      { value: "warning", label: "Warning" },
                    ]}
                  />
                )}
              />
              <Controller
                control={form.control}
                name="action"
                render={({ field }) => <NativeSelect label="Action link (in-app screen)" value={field.value} onChange={field.onChange} options={ACTION_OPTIONS} />}
              />
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1.5">
                <Label htmlFor="a-start">Start (empty = now)</Label>
                <Input id="a-start" type="datetime-local" aria-invalid={!!errors.starts_at} {...form.register("starts_at")} />
                <Err message={errors.starts_at?.message} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="a-end">End</Label>
                <Input id="a-end" type="datetime-local" aria-invalid={!!errors.ends_at} {...form.register("ends_at")} />
                <Err message={errors.ends_at?.message} />
              </div>
            </div>
            <Controller
              control={form.control}
              name="active"
              render={({ field }) => (
                <label className="flex items-center gap-2 text-sm">
                  <Checkbox checked={!field.value} onCheckedChange={(c) => field.onChange(c !== true)} />
                  Save as draft (not shown in the app)
                </label>
              )}
            />
            <Controller
              control={form.control}
              name="notify"
              render={({ field }) => (
                <label className="flex items-center gap-2 text-sm">
                  <Checkbox checked={field.value} onCheckedChange={(c) => field.onChange(c === true)} />
                  Also send as notification to all users
                </label>
              )}
            />
            {notify && <p className="text-xs text-warning">Every user gets a notification now, even if the banner starts later.</p>}
          </div>
          <div className="space-y-2">
            <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">App Home preview</p>
            <div className="rounded-3xl border bg-[#FFFFFF] p-3">
              <BannerPreview title={title.trim()} message={message.trim()} level={level} action={action} />
            </div>
          </div>
        </form>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button type="submit" form="announcement-form" disabled={isSubmitting}>
            {isSubmitting && <Loader2 className="animate-spin" />}
            {editing ? "Save changes" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

export default function AnnouncementsPage() {
  const api = useApi();
  const qc = useQueryClient();
  const paging = useCursorPaging();
  const [editor, setEditor] = useState<{ open: boolean; editing: Announcement | null; key: number }>({ open: false, editing: null, key: 0 });
  const [deleting, setDeleting] = useState<Announcement | null>(null);

  const list = useQuery({
    queryKey: ["admin-announcements", paging.cursor],
    queryFn: () => api<Page<Announcement>>("/admin/announcements", { query: { limit: PAGE_SIZE, cursor: paging.cursor } }),
    placeholderData: keepPreviousData,
  });
  const remove = useMutation({
    mutationFn: (id: string) => api(`/admin/announcements/${encodeURIComponent(id)}`, { method: "DELETE" }),
    onSuccess: () => {
      toast.success("Announcement deleted.");
      void qc.invalidateQueries({ queryKey: ["admin-announcements"] });
    },
  });
  const openEditor = (editing: Announcement | null) => setEditor((e) => ({ open: true, editing, key: e.key + 1 }));

  const col = columnHelper<Announcement>();
  const columns = col.columns([
    col.accessor("title", {
      header: "Title",
      cell: (i) => (
        <span className="flex items-center gap-2">
          {i.row.original.level === "warning" && <AlertTriangle className="size-3.5 text-warning" />}
          <span className="font-medium">{i.getValue()}</span>
        </span>
      ),
    }),
    col.display({ id: "status", header: "Status", cell: (i) => <StatusChip a={i.row.original} /> }),
    col.accessor("starts_at", { header: "Start", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
    col.accessor("ends_at", { header: "End", cell: (i) => <span className="whitespace-nowrap">{fmtDateTime(i.getValue())}</span> }),
    col.accessor("action", {
      header: "Link",
      cell: (i) => (i.getValue() && i.getValue() !== "none" ? <Badge variant="outline">{i.getValue()}</Badge> : "-"),
    }),
    col.accessor("created_by_email", {
      header: "Created by",
      cell: (i) => i.getValue() ?? <span className="font-mono text-xs text-muted-foreground">{i.row.original.created_by_hash?.slice(0, 10) ?? "-"}</span>,
    }),
    col.display({
      id: "actions",
      header: "",
      cell: (i) => (
        <div className="flex justify-end gap-1">
          <Button variant="ghost" size="icon-sm" aria-label="Edit" onClick={() => openEditor(i.row.original)}>
            <Pencil />
          </Button>
          <Button variant="ghost" size="icon-sm" aria-label="Delete" onClick={() => setDeleting(i.row.original)}>
            <Trash2 className="text-destructive" />
          </Button>
        </div>
      ),
    }),
  ]);

  return (
    <>
      <PageHeader
        title="Announcements"
        description="Messages shown as a banner on the app's Home screen inside their time window."
        actions={
          <Button onClick={() => openEditor(null)}>
            <Plus /> New announcement
          </Button>
        }
      />
      <DataTable
        columns={columns}
        data={list.data?.items ?? NO_ROWS}
        loading={list.isPending}
        error={list.isError ? list.error : undefined}
        onRetry={() => void list.refetch()}
        getRowId={(r) => r.id}
        emptyTitle="No announcements"
        emptyHint="Create one to show a banner in the app."
      />
      <Pager page={paging.page} hasNext={!!list.data?.next_cursor} onPrev={paging.prev} onNext={() => paging.next(list.data?.next_cursor)} busy={list.isFetching} />

      <AnnouncementDialog
        key={editor.key}
        open={editor.open}
        editing={editor.editing}
        onClose={() => setEditor((e) => ({ ...e, open: false }))}
      />
      <ConfirmDialog
        open={deleting !== null}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete this announcement?"
        description={deleting ? `"${deleting.title}" disappears from the app. This cannot be undone.` : undefined}
        confirmLabel="Delete"
        destructive
        onConfirm={async () => {
          if (deleting) await remove.mutateAsync(deleting.id);
          setDeleting(null);
        }}
      />
    </>
  );
}
