"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Send, X } from "lucide-react";
import { useState } from "react";
import { Controller, useForm, useWatch, type FieldPath } from "react-hook-form";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { NativeSelect, useDebounced } from "@/components/filters";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ACTION_OPTIONS } from "@/lib/announcements";
import { ApiError } from "@/lib/api";
import {
  SEND_MESSAGE_MAX,
  SEND_TITLE_MAX,
  sendDefaults,
  sendFormSchema,
  toSendBody,
  type SendFormValues,
} from "@/lib/send-notification";
import type { Page, SendResult, UserRow } from "@/lib/types";
import { cn } from "@/lib/utils";

const textareaClass =
  "w-full rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive dark:bg-input/30";

function Err({ message }: { message?: string }) {
  return message ? <p className="text-xs text-destructive">{message}</p> : null;
}

/** Email search over GET /admin/users (q matches email or name). */
function UserPicker({ value, onPick, invalid }: { value: string; onPick: (u: UserRow | null) => void; invalid?: boolean }) {
  const api = useApi();
  const [text, setText] = useState("");
  const q = useDebounced(text.trim());
  const results = useQuery({
    queryKey: ["admin-users-pick", q],
    queryFn: () => api<Page<UserRow>>("/admin/users", { query: { q, limit: 8 } }),
    enabled: q.length >= 2 && !value,
  });
  if (value) {
    return (
      <div className="flex h-8 items-center gap-2 rounded-lg border bg-muted/40 px-2 text-sm">
        <span className="truncate">{value}</span>
        <Button type="button" variant="ghost" size="icon-xs" aria-label="Change user" className="ml-auto" onClick={() => onPick(null)}>
          <X />
        </Button>
      </div>
    );
  }
  return (
    <div className="relative">
      <Input value={text} onChange={(e) => setText(e.target.value)} placeholder="Search by email" aria-invalid={invalid} autoComplete="off" />
      {q.length >= 2 && (
        <div className="absolute z-50 mt-1 w-full overflow-hidden rounded-lg border bg-popover shadow-md">
          {results.isPending ? (
            <p className="px-3 py-2 text-sm text-muted-foreground">Searching...</p>
          ) : !results.data?.items.length ? (
            <p className="px-3 py-2 text-sm text-muted-foreground">No users found</p>
          ) : (
            results.data.items.map((u) => (
              <button
                key={u.uid}
                type="button"
                className="block w-full px-3 py-1.5 text-left text-sm hover:bg-muted"
                onClick={() => {
                  setText("");
                  onPick(u);
                }}
              >
                <span className="block truncate">{u.email ?? "(no email)"}</span>
                {u.display_name && <span className="block truncate text-xs text-muted-foreground">{u.display_name}</span>}
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
}

/** Send a notification to one user or to all users (POST /admin/notifications/send). With
 * `user`, that user is preselected and the target cannot be changed. */
export function SendNotificationForm({
  user,
  onSent,
}: {
  user?: { uid: string; email: string | null } | null;
  onSent?: (r: SendResult) => void;
}) {
  const api = useApi();
  const qc = useQueryClient();
  const form = useForm<SendFormValues>({ resolver: zodResolver(sendFormSchema), defaultValues: sendDefaults(user) });
  const { errors } = form.formState;
  const [target, email, title, message, action] = useWatch({
    control: form.control,
    name: ["target", "email", "title", "message", "action"],
  });
  const [pending, setPending] = useState<SendFormValues | null>(null);

  const audience = useQuery({
    queryKey: ["admin-notification-audience"],
    queryFn: () => api<{ users: number }>("/admin/notifications/audience"),
    enabled: pending?.target === "all",
  });

  const send = useMutation({
    mutationFn: (v: SendFormValues) => api<SendResult>("/admin/notifications/send", { method: "POST", body: toSendBody(v), silent: true }),
    onSuccess: (r, v) => {
      toast.success(r.count === 1 ? "Notification sent to 1 user." : `Notification sent to ${r.count} users.`);
      void qc.invalidateQueries({ queryKey: ["admin-broadcasts"] });
      void qc.invalidateQueries({ queryKey: ["admin-all-notifications"] });
      if (v.uid) void qc.invalidateQueries({ queryKey: ["admin-user-notifications", v.uid] });
      form.reset(sendDefaults(user));
      onSent?.(r);
    },
  });

  async function confirmSend() {
    if (!pending) return;
    try {
      await send.mutateAsync(pending);
    } catch (e) {
      const err = e instanceof ApiError ? e : null;
      if (err?.fields.length) {
        for (const f of err.fields) {
          const field = (f.field === "uid" ? "email" : f.field) as FieldPath<SendFormValues>;
          form.setError(field, { type: "server", message: f.message });
        }
        toast.error("The server did not accept some values. Check the highlighted fields.");
        setPending(null);
        return;
      }
      toast.error(err?.status === 404 ? "This user no longer exists." : (err?.message ?? "Could not send the notification."));
      throw e;
    }
  }

  const count = pending?.target === "all" ? audience.data?.users : 1;

  return (
    <form onSubmit={form.handleSubmit((v) => setPending(v))} className="space-y-4">
      {!user && (
        <div className="space-y-1.5">
          <Label>Send to</Label>
          <Controller
            control={form.control}
            name="target"
            render={({ field }) => (
              <div className="flex gap-2">
                {(["user", "all"] as const).map((t) => (
                  <Button
                    key={t}
                    type="button"
                    size="sm"
                    variant={field.value === t ? "default" : "outline"}
                    onClick={() => field.onChange(t)}
                  >
                    {t === "user" ? "One user" : "All users"}
                  </Button>
                ))}
              </div>
            )}
          />
        </div>
      )}
      {target === "user" && (
        <div className="space-y-1.5">
          <Label>User</Label>
          {user ? (
            <div className="flex h-8 items-center rounded-lg border bg-muted/40 px-2 text-sm">{user.email ?? user.uid}</div>
          ) : (
            <UserPicker
              value={email}
              invalid={!!errors.email}
              onPick={(u) => {
                form.setValue("uid", u?.uid ?? "");
                form.setValue("email", u ? (u.email ?? u.uid) : "", { shouldValidate: !!u });
              }}
            />
          )}
          <Err message={errors.email?.message} />
        </div>
      )}
      <div className="flex flex-wrap gap-3">
        <Controller
          control={form.control}
          name="type"
          render={({ field }) => (
            <NativeSelect
              label="Type"
              value={field.value}
              onChange={field.onChange}
              options={[
                { value: "info", label: "Info" },
                { value: "success", label: "Success" },
                { value: "warning", label: "Warning" },
                { value: "error", label: "Error" },
              ]}
            />
          )}
        />
        <Controller
          control={form.control}
          name="category"
          render={({ field }) => (
            <NativeSelect
              label="Category (user can mute)"
              value={field.value}
              onChange={field.onChange}
              options={[
                { value: "", label: "None (always shown)" },
                { value: "calibration", label: "Calibration" },
                { value: "referral", label: "Referral" },
                { value: "certificate", label: "Certificate" },
              ]}
            />
          )}
        />
        <Controller
          control={form.control}
          name="action"
          render={({ field }) => <NativeSelect label="Opens in the app" value={field.value} onChange={field.onChange} options={ACTION_OPTIONS} />}
        />
      </div>
      <div className="space-y-1.5">
        <div className="flex justify-between">
          <Label htmlFor="send-title">Title</Label>
          <span className={cn("text-xs text-muted-foreground", title.length > SEND_TITLE_MAX && "text-destructive")}>
            {title.length}/{SEND_TITLE_MAX}
          </span>
        </div>
        <Input id="send-title" aria-invalid={!!errors.title} {...form.register("title")} />
        <Err message={errors.title?.message} />
      </div>
      <div className="space-y-1.5">
        <div className="flex justify-between">
          <Label htmlFor="send-message">Message</Label>
          <span className={cn("text-xs text-muted-foreground", message.length > SEND_MESSAGE_MAX && "text-destructive")}>
            {message.length}/{SEND_MESSAGE_MAX}
          </span>
        </div>
        <textarea id="send-message" rows={4} className={textareaClass} aria-invalid={!!errors.message} {...form.register("message")} />
        <Err message={errors.message?.message} />
      </div>
      {action === "openResult" && (
        <div className="space-y-1.5">
          <Label htmlFor="send-payload">Stone ID</Label>
          <Input id="send-payload" placeholder="GE-STONE-00001" aria-invalid={!!errors.payload} {...form.register("payload")} />
          <Err message={errors.payload?.message} />
        </div>
      )}
      <div className="flex justify-end">
        <Button type="submit" disabled={send.isPending}>
          <Send /> Review and send
        </Button>
      </div>

      <ConfirmDialog
        open={pending !== null}
        onOpenChange={(o) => !o && setPending(null)}
        title={
          pending?.target === "all"
            ? count === undefined
              ? "Send to all users?"
              : `Send to all ${count} users?`
            : `Send to ${pending?.email || "this user"}?`
        }
        description={
          pending?.target === "all"
            ? "Every user gets this notification in the app. At most 5 sends to all users per hour."
            : "The user sees it in the app's notification list."
        }
        confirmLabel="Send"
        onConfirm={confirmSend}
      >
        {pending && (
          <div className="rounded-lg border p-3 text-sm">
            <p className="font-medium">{pending.title}</p>
            <p className="mt-1 whitespace-pre-wrap text-muted-foreground">{pending.message}</p>
          </div>
        )}
      </ConfirmDialog>
    </form>
  );
}
