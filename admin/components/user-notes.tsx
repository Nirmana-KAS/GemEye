"use client";

import { useInfiniteQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ReasonField } from "@/components/reason-field";
import { EmptyState, ErrorState } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { NOTE_MAX } from "@/lib/admin-powers";
import { addNote, deleteNote, listNotes } from "@/lib/api";
import { fmtDateTime } from "@/lib/format";
import type { AdminNote } from "@/lib/types";

/** Admin-only notes about a user (never shown in the app). */
export function UserNotes({ uid }: { uid: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const [text, setText] = useState("");
  const [removing, setRemoving] = useState<AdminNote | null>(null);
  const key = ["admin-user-notes", uid];
  const notes = useInfiniteQuery({
    queryKey: key,
    queryFn: ({ pageParam }) => listNotes(api, uid, pageParam),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (p) => p.next_cursor ?? undefined,
  });
  const add = useMutation({
    mutationFn: () => addNote(api, uid, text.trim()),
    onSuccess: () => {
      toast.success("Note added.");
      setText("");
      void qc.invalidateQueries({ queryKey: key });
    },
  });
  const items = notes.data?.pages.flatMap((p) => p.items) ?? [];

  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="space-y-2">
          <ReasonField value={text} onChange={setText} label="New note (only admins see notes)" id="note-text" max={NOTE_MAX} />
          <div className="flex justify-end">
            <Button onClick={() => add.mutate()} disabled={!text.trim() || add.isPending}>
              {add.isPending ? <Loader2 className="animate-spin" /> : <Plus />} Add note
            </Button>
          </div>
        </CardContent>
      </Card>
      {notes.isPending ? (
        <Skeleton className="h-24 rounded-xl" />
      ) : notes.isError ? (
        <Card>
          <ErrorState error={notes.error} onRetry={() => void notes.refetch()} />
        </Card>
      ) : items.length === 0 ? (
        <Card>
          <EmptyState title="No notes yet" />
        </Card>
      ) : (
        <ul className="space-y-2">
          {items.map((n) => (
            <li key={n.id} className="rounded-xl border bg-card p-3">
              <div className="mb-1 flex items-center gap-2 text-xs text-muted-foreground">
                <span>{fmtDateTime(n.at)}</span>
                <span>{n.author_email ?? "unknown admin"}</span>
                <Button variant="ghost" size="icon-xs" className="ml-auto" aria-label="Delete note" onClick={() => setRemoving(n)}>
                  <Trash2 />
                </Button>
              </div>
              <p className="whitespace-pre-wrap break-words text-sm">{n.text}</p>
            </li>
          ))}
        </ul>
      )}
      {notes.hasNextPage && (
        <Button variant="outline" onClick={() => void notes.fetchNextPage()} disabled={notes.isFetchingNextPage}>
          Load more
        </Button>
      )}
      <ConfirmDialog
        open={removing !== null}
        onOpenChange={(o) => !o && setRemoving(null)}
        title="Delete this note?"
        description="The deletion is written to the audit log."
        confirmLabel="Delete"
        destructive
        onConfirm={async () => {
          if (!removing) return;
          await deleteNote(api, uid, removing.id);
          toast.success("Note deleted.");
          void qc.invalidateQueries({ queryKey: key });
        }}
      />
    </div>
  );
}
