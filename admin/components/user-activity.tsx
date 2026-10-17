"use client";

import { useInfiniteQuery } from "@tanstack/react-query";
import Link from "next/link";

import { useApi } from "@/components/auth-provider";
import { EmptyState, ErrorState } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { ACTIVITY_LABELS, activityLink } from "@/lib/admin-powers";
import { listActivity } from "@/lib/api";
import { fmtDateTime } from "@/lib/format";

/** Sign-ins, gradings, calibrations, feedback, certificates and admin actions, newest first. */
export function UserActivity({ uid }: { uid: string }) {
  const api = useApi();
  const activity = useInfiniteQuery({
    queryKey: ["admin-user-activity", uid],
    queryFn: ({ pageParam }) => listActivity(api, uid, pageParam),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (p) => p.next_cursor ?? undefined,
  });
  if (activity.isPending) return <Skeleton className="h-48 rounded-xl" />;
  if (activity.isError) {
    return (
      <Card>
        <ErrorState error={activity.error} onRetry={() => void activity.refetch()} />
      </Card>
    );
  }
  const items = activity.data.pages.flatMap((p) => p.items);
  if (!items.length) {
    return (
      <Card>
        <EmptyState title="No activity" />
      </Card>
    );
  }
  return (
    <div className="space-y-3">
      <ol className="divide-y rounded-xl border bg-card">
        {items.map((e) => {
          const href = activityLink(e.type, e.ref);
          return (
            <li key={e.id} className="grid gap-1 px-3 py-2 text-sm sm:grid-cols-[170px_130px_1fr] sm:items-center sm:gap-3">
              <span className="whitespace-nowrap text-xs text-muted-foreground">{fmtDateTime(e.at)}</span>
              <span>
                <Badge variant={e.type === "admin_action" ? "secondary" : "outline"}>{ACTIVITY_LABELS[e.type] ?? e.type}</Badge>
              </span>
              <span className="min-w-0 break-words">
                {href ? (
                  <Link href={href} className="text-primary hover:underline dark:text-brand-accent">
                    {e.summary}
                  </Link>
                ) : (
                  e.summary
                )}
                {e.admin_email && <span className="text-muted-foreground"> - {e.admin_email}</span>}
              </span>
            </li>
          );
        })}
      </ol>
      {activity.hasNextPage && (
        <Button variant="outline" onClick={() => void activity.fetchNextPage()} disabled={activity.isFetchingNextPage}>
          Load more
        </Button>
      )}
    </div>
  );
}
