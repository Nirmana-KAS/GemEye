"use client";

import { AlertTriangle, Construction, Inbox, Lock, RotateCw } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { ApiError } from "@/lib/api";

export function PageHeader({
  title,
  description,
  actions,
}: {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">{title}</h1>
        {description && <p className="mt-1 text-sm text-muted-foreground">{description}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  );
}

function Centered({ icon, title, children }: { icon: React.ReactNode; title: string; children?: React.ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-6 py-12 text-center">
      <div className="text-muted-foreground">{icon}</div>
      <p className="font-medium">{title}</p>
      {children}
    </div>
  );
}

export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) {
  const message = error instanceof ApiError ? error.message : "Something went wrong while loading.";
  return (
    <Centered icon={<AlertTriangle className="size-8 text-destructive" />} title="Could not load data">
      <p className="max-w-md text-sm text-muted-foreground">{message}</p>
      {onRetry && (
        <Button variant="outline" size="sm" className="mt-2" onClick={onRetry}>
          <RotateCw /> Retry
        </Button>
      )}
    </Centered>
  );
}

export function EmptyState({ title = "Nothing here yet", hint }: { title?: string; hint?: string }) {
  return (
    <Centered icon={<Inbox className="size-8" />} title={title}>
      {hint && <p className="max-w-md text-sm text-muted-foreground">{hint}</p>}
    </Centered>
  );
}

export function NoAccess() {
  return (
    <Card className="mx-auto mt-12 max-w-lg">
      <CardContent>
        <Centered icon={<Lock className="size-8" />} title="No access">
          <p className="text-sm text-muted-foreground">
            Your account does not have permission to view this page.
          </p>
        </Centered>
      </CardContent>
    </Card>
  );
}

export function ComingSoon({ title }: { title: string }) {
  return (
    <>
      <PageHeader title={title} />
      <Card>
        <CardContent>
          <Centered icon={<Construction className="size-8" />} title="Coming in next phase">
            <p className="text-sm text-muted-foreground">This section is part of a later dashboard phase.</p>
          </Centered>
        </CardContent>
      </Card>
    </>
  );
}
