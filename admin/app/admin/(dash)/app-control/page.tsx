"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { RotateCcw, Save } from "lucide-react";
import { useMemo, useState } from "react";
import { Controller, useForm, useWatch, type FieldPath } from "react-hook-form";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ErrorState, PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { ApiError } from "@/lib/api";
import {
  configDiff,
  configFormSchema,
  configPatch,
  configToForm,
  FEATURE_KEYS,
  FEATURE_LABELS,
  fmtConfigValue,
  GATE_KEYS,
  GATE_LABELS,
  gateChanged,
  serverFieldPaths,
  turnsMaintenanceOn,
  type ConfigChange,
  type ConfigFormValues,
} from "@/lib/config";
import type { AdminConfig } from "@/lib/types";
import { cn } from "@/lib/utils";

function FieldError({ message }: { message?: string }) {
  return message ? <p className="text-xs text-destructive">{message}</p> : null;
}

function Row({ label, hint, children }: { label: string; hint?: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="grid gap-1.5 py-2 md:grid-cols-[260px_1fr] md:items-start md:gap-4">
      <div>
        <Label className="text-sm">{label}</Label>
        {hint && <p className="mt-0.5 text-xs text-muted-foreground">{hint}</p>}
      </div>
      <div className="space-y-1">{children}</div>
    </div>
  );
}

function Section({ title, description, children, actions }: { title: string; description?: string; children: React.ReactNode; actions?: React.ReactNode }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-start justify-between gap-4">
        <div>
          <CardTitle className="text-base">{title}</CardTitle>
          {description && <CardDescription>{description}</CardDescription>}
        </div>
        {actions}
      </CardHeader>
      <CardContent className="divide-y">{children}</CardContent>
    </Card>
  );
}

type Dialog = "diff" | "maintenance" | "reset" | null;

function ConfigForm({ config }: { config: AdminConfig }) {
  const api = useApi();
  const qc = useQueryClient();
  const saved = useMemo(() => configToForm(config), [config]);
  const schema = useMemo(() => configFormSchema(config), [config]);
  const form = useForm<ConfigFormValues>({ resolver: zodResolver(schema), defaultValues: saved, mode: "onChange" });
  const { errors, isDirty } = form.formState;
  const gates = useWatch({ control: form.control, name: "gates" });
  const maintenanceOn = useWatch({ control: form.control, name: "maintenance.enabled" });
  const [dialog, setDialog] = useState<Dialog>(null);
  const [changes, setChanges] = useState<ConfigChange[]>([]);
  const max = config.bounds.message_max;

  const applySaved = (next: AdminConfig) => {
    qc.setQueryData(["admin-config"], next);
    form.reset(configToForm(next));
  };

  const save = useMutation({
    mutationFn: (body: Record<string, unknown>) => api<AdminConfig>("/admin/config", { method: "PUT", body, silent: true }),
    onSuccess: (next) => {
      toast.success("Settings saved. The app picks them up within a minute.");
      applySaved(next);
    },
  });
  const resetGates = useMutation({
    mutationFn: () => api<AdminConfig>("/admin/config/reset-gates", { method: "POST" }),
    onSuccess: (next) => {
      toast.success("Gate thresholds reset to the defaults.");
      applySaved(next);
    },
  });

  async function submitChanges() {
    try {
      await save.mutateAsync(configPatch(changes));
    } catch (e) {
      const err = e instanceof ApiError ? e : null;
      const fields = err ? serverFieldPaths(err) : [];
      if (fields.length) {
        for (const f of fields) form.setError(f.field as FieldPath<ConfigFormValues>, { type: "server", message: f.message });
        toast.error("The server did not accept some values. Check the highlighted fields.");
        setDialog(null);
        return;
      }
      toast.error(err?.message ?? "Could not save the settings.");
      throw e;
    }
  }

  const onValid = (values: ConfigFormValues) => {
    const diff = configDiff(saved, values);
    if (!diff.length) {
      toast.info("Nothing has changed.");
      return;
    }
    setChanges(diff);
    setDialog("diff");
  };

  const numberInput = (name: FieldPath<ConfigFormValues>, b: { min: number; max: number }, step = "any", className = "w-40") => (
    <Input
      type="number"
      step={step}
      min={b.min}
      max={b.max}
      className={cn("font-mono", className)}
      aria-invalid={!!form.getFieldState(name, form.formState).error}
      {...form.register(name, { valueAsNumber: true })}
    />
  );

  const gatesAtDefault = GATE_KEYS.every((k) => !gateChanged(config, k, config.gates[k]));

  return (
    <form onSubmit={form.handleSubmit(onValid)} className="space-y-4">
      <div className="sticky top-14 z-20 -mx-6 flex items-center justify-end gap-2 border-b bg-background/95 px-6 py-2 backdrop-blur">
        {isDirty && <span className="mr-auto text-sm text-warning">Unsaved changes</span>}
        <Button type="button" variant="outline" onClick={() => form.reset(saved)} disabled={!isDirty}>
          Discard
        </Button>
        <Button type="submit" disabled={!isDirty || save.isPending}>
          <Save /> Save changes
        </Button>
      </div>

      <Section title="Grading" description="Defaults the app uses when the user has not chosen their own.">
        <Row
          label="Referral threshold default"
          hint={`Below this confidence a stone is referred to a gemologist. ${config.bounds.referral_threshold_default.min} - ${config.bounds.referral_threshold_default.max}.`}
        >
          {numberInput("referral_threshold_default", config.bounds.referral_threshold_default, "0.01")}
          <FieldError message={errors.referral_threshold_default?.message} />
        </Row>
      </Section>

      <Section title="Calibration">
        <Row
          label="Calibration validity (hours)"
          hint={`How long a calibration stays valid. ${config.bounds.calibration_validity_hours.min} - ${config.bounds.calibration_validity_hours.max} hours.`}
        >
          {numberInput("calibration_validity_hours", config.bounds.calibration_validity_hours, "1")}
          <FieldError message={errors.calibration_validity_hours?.message} />
        </Row>
      </Section>

      <Section title="App version" description="Older app versions are asked to update.">
        <Row label="Minimum app version" hint="MAJOR.MINOR.PATCH">
          <Input className="w-40 font-mono" aria-invalid={!!errors.min_app_version} {...form.register("min_app_version")} />
          <FieldError message={errors.min_app_version?.message} />
        </Row>
        <Row label="Update message" hint={`Shown with the update prompt. Empty = the app's default text. Max ${max} characters.`}>
          <textarea
            rows={2}
            maxLength={max}
            className="w-full max-w-xl rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
            {...form.register("update_message")}
          />
          <FieldError message={errors.update_message?.message} />
        </Row>
      </Section>

      <Section title="Feature switches">
        {FEATURE_KEYS.map((k) => (
          <Row key={k} label={FEATURE_LABELS[k]}>
            <Controller
              control={form.control}
              name={`features.${k}`}
              render={({ field }) => (
                <label className="flex items-center gap-2 text-sm">
                  <Checkbox checked={field.value} onCheckedChange={(v) => field.onChange(v === true)} />
                  {field.value ? "On" : "Off"}
                </label>
              )}
            />
          </Row>
        ))}
      </Section>

      <Section
        title="Gate thresholds"
        description="Photo quality gates on the server. Values must stay inside the server bounds; the defaults are the validated originals."
        actions={
          <Button type="button" variant="outline" size="sm" onClick={() => setDialog("reset")} disabled={gatesAtDefault || resetGates.isPending}>
            <RotateCcw /> Reset gates to defaults
          </Button>
        }
      >
        <div className="hidden grid-cols-[1fr_170px_140px_140px_80px] gap-3 pb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground lg:grid">
          <span>Gate</span>
          <span>Value</span>
          <span>Bounds</span>
          <span>Default</span>
          <span />
        </div>
        {GATE_KEYS.map((k) => {
          const b = config.gate_bounds[k];
          const v = gates?.[k];
          const changed = typeof v === "number" && !Number.isNaN(v) && gateChanged(config, k, v);
          return (
            <div key={k} className="grid gap-2 py-2 lg:grid-cols-[1fr_170px_140px_140px_80px] lg:items-start lg:gap-3">
              <span className="text-sm">{GATE_LABELS[k]}</span>
              <div className="space-y-1">
                {numberInput(`gates.${k}`, b, "any", "w-40")}
                <FieldError message={errors.gates?.[k]?.message} />
              </div>
              <span className="font-mono text-xs text-muted-foreground lg:pt-2">
                {b.min} - {b.max}
              </span>
              <span className="font-mono text-xs text-muted-foreground lg:pt-2">{config.gate_defaults[k]}</span>
              <span className="lg:pt-1.5">{changed && <Badge variant="secondary">changed</Badge>}</span>
            </div>
          );
        })}
      </Section>

      <Section title="Maintenance" description="While on, the app shows the message and grading is paused (503 maintenance).">
        <Row label="Maintenance mode">
          <Controller
            control={form.control}
            name="maintenance.enabled"
            render={({ field }) => (
              <label className="flex items-center gap-2 text-sm">
                <Checkbox checked={field.value} onCheckedChange={(v) => field.onChange(v === true)} />
                <span className={cn(field.value && "font-medium text-destructive")}>{field.value ? "On" : "Off"}</span>
              </label>
            )}
          />
        </Row>
        <Row label="Message shown in the app" hint={`Max ${max} characters.`}>
          <textarea
            rows={2}
            maxLength={max}
            className="w-full max-w-xl rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive dark:bg-input/30"
            aria-invalid={!!errors.maintenance?.message}
            {...form.register("maintenance.message")}
          />
          <FieldError message={errors.maintenance?.message?.message} />
          {maintenanceOn && !config.maintenance.enabled && (
            <p className="text-xs text-warning">Saving turns maintenance on. You will be asked to type MAINTENANCE.</p>
          )}
        </Row>
      </Section>

      <ConfirmDialog
        open={dialog === "diff"}
        onOpenChange={(o) => setDialog(o ? "diff" : null)}
        title={`Save ${changes.length} change${changes.length === 1 ? "" : "s"}?`}
        description="Check the old and new values. Every change is written to the audit log."
        confirmLabel={turnsMaintenanceOn(changes) ? "Continue" : "Save"}
        onConfirm={async () => {
          if (turnsMaintenanceOn(changes)) {
            // Throwing keeps ConfirmDialog from closing itself (which would also close the next step).
            setDialog("maintenance");
            throw new Error("next step");
          }
          await submitChanges();
        }}
      >
        <DiffTable changes={changes} />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "maintenance"}
        onOpenChange={(o) => setDialog(o ? "maintenance" : null)}
        title="Turn maintenance mode on?"
        description="Users cannot grade stones until maintenance is turned off again."
        confirmLabel="Save and turn on"
        destructive
        confirmText="MAINTENANCE"
        onConfirm={submitChanges}
      >
        <DiffTable changes={changes} />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "reset"}
        onOpenChange={(o) => setDialog(o ? "reset" : null)}
        title="Reset all gate thresholds to the defaults?"
        description="Unsaved gate edits in the form are discarded. The change is audited."
        confirmLabel="Reset gates"
        onConfirm={() => resetGates.mutateAsync()}
      />
    </form>
  );
}

function DiffTable({ changes }: { changes: ConfigChange[] }) {
  return (
    <div className="max-h-72 overflow-y-auto rounded-lg border text-sm">
      <table className="w-full">
        <thead className="bg-muted/50 text-xs uppercase tracking-wide text-muted-foreground">
          <tr>
            <th className="px-3 py-1.5 text-left">Setting</th>
            <th className="px-3 py-1.5 text-left">Old</th>
            <th className="px-3 py-1.5 text-left">New</th>
          </tr>
        </thead>
        <tbody>
          {changes.map((c) => (
            <tr key={c.path} className="border-t align-top">
              <td className="px-3 py-1.5">{c.label}</td>
              <td className="break-all px-3 py-1.5 font-mono text-xs text-muted-foreground">{fmtConfigValue(c.before)}</td>
              <td className="break-all px-3 py-1.5 font-mono text-xs">{fmtConfigValue(c.after)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function AppControlPage() {
  const api = useApi();
  const config = useQuery({ queryKey: ["admin-config"], queryFn: () => api<AdminConfig>("/admin/config") });
  return (
    <>
      <PageHeader title="App control" description="Remote settings the app reads at start-up (cached up to 60 seconds)." />
      {config.isPending ? (
        <div className="space-y-4">
          <Skeleton className="h-32 rounded-xl" />
          <Skeleton className="h-72 rounded-xl" />
        </div>
      ) : config.isError ? (
        <Card>
          <ErrorState error={config.error} onRetry={() => void config.refetch()} />
        </Card>
      ) : (
        <ConfigForm key={JSON.stringify(config.data)} config={config.data} />
      )}
    </>
  );
}
