"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Ban, CheckCircle2, KeyRound, ShieldCheck, Trash2 } from "lucide-react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { toast } from "sonner";

import { useAuth } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { columnHelper, DataTable } from "@/components/data-table";
import { NativeSelect } from "@/components/filters";
import { GradeChip, YesNo } from "@/components/grade-chip";
import { EmptyState, ErrorState, PageHeader } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { RoleBadge, StatusBadge } from "@/components/user-badges";
import { UserNotifications } from "@/components/user-notifications";
import { fmtDateTime, fmtNum, fmtPct } from "@/lib/format";
import type { CalibrationRow, GradingRow, PasswordResetResult, RoleSetting, UserDetail } from "@/lib/types";

const g = columnHelper<GradingRow>();
const gradingColumns = g.columns([
  g.accessor("created_at", { header: "Time", cell: (i) => fmtDateTime(i.getValue()) }),
  g.accessor("grade", { header: "Grade", cell: (i) => <GradeChip grade={i.getValue()} showName /> }),
  g.accessor("confidence", { header: "Confidence", cell: (i) => fmtPct(i.getValue()) }),
  g.accessor("referred", { header: "Referred", cell: (i) => <YesNo value={i.getValue()} /> }),
  g.accessor("model_version", { header: "Model", cell: (i) => i.getValue() ?? "-" }),
  g.accessor("device", { header: "Device", cell: (i) => i.getValue() ?? "-" }),
]);

const c = columnHelper<CalibrationRow>();
const calibrationColumns = c.columns([
  c.accessor("created_at", { header: "Time", cell: (i) => fmtDateTime(i.getValue()) }),
  c.accessor("device", { header: "Device", cell: (i) => i.getValue() ?? "-" }),
  c.accessor("residual", { header: "Residual", cell: (i) => <span className="font-mono">{fmtNum(i.getValue(), 3)}</span> }),
  c.accessor("quality", { header: "Quality", cell: (i) => <span className="capitalize">{String(i.getValue() ?? "-")}</span> }),
  c.accessor("valid_until", { header: "Valid until", cell: (i) => fmtDateTime(i.getValue()) }),
]);

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-[140px_1fr] gap-2 py-1.5 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className="min-w-0 break-words">{children ?? "-"}</span>
    </div>
  );
}

/** Explains why a button is disabled (own account). */
function SelfGuard({ self, children }: { self: boolean; children: React.ReactElement }) {
  if (!self) return children;
  return (
    <Tooltip>
      <TooltipTrigger render={<span className="inline-flex" />}>{children}</TooltipTrigger>
      <TooltipContent>Not allowed on your own account</TooltipContent>
    </Tooltip>
  );
}

type Dialogs = "disable" | "enable" | "role" | "reset" | "delete" | null;

function UserDetailView({ uid }: { uid: string }) {
  const { api, user: me, role: myRole } = useAuth();
  const router = useRouter();
  const qc = useQueryClient();
  const [dialog, setDialog] = useState<Dialogs>(null);
  const [newRole, setNewRole] = useState<RoleSetting>("none");
  const [resetLink, setResetLink] = useState<string | null>(null);

  const detail = useQuery({
    queryKey: ["admin-user", uid],
    queryFn: () => api<UserDetail>(`/admin/users/${encodeURIComponent(uid)}`),
  });

  const refresh = () => {
    void qc.invalidateQueries({ queryKey: ["admin-user", uid] });
    void qc.invalidateQueries({ queryKey: ["admin-users"] });
  };
  const path = `/admin/users/${encodeURIComponent(uid)}`;

  const setDisabled = useMutation({
    mutationFn: (disable: boolean) => api(`${path}/${disable ? "disable" : "enable"}`, { method: "POST" }),
    onSuccess: (_, disable) => {
      toast.success(disable ? "Account disabled." : "Account enabled.");
      refresh();
    },
  });
  const setRole = useMutation({
    mutationFn: (role: RoleSetting) => api(`${path}/role`, { method: "POST", body: { role } }),
    onSuccess: () => {
      toast.success("Role updated.");
      refresh();
    },
  });
  const reset = useMutation({
    mutationFn: () => api<PasswordResetResult>(`${path}/password-reset`, { method: "POST" }),
    onSuccess: (r) => {
      if (r.status === "link" && r.link) setResetLink(r.link);
      else toast.success("Password reset email sent.");
    },
  });
  const remove = useMutation({
    mutationFn: () => api(path, { method: "DELETE" }),
    onSuccess: () => {
      toast.success("User and their data deleted.");
      void qc.invalidateQueries({ queryKey: ["admin-users"] });
      router.replace("/admin/users/");
    },
  });

  const back = (
    <Link href="/admin/users/" className="mb-4 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-4" /> Users
    </Link>
  );

  if (detail.isPending) {
    return (
      <>
        {back}
        <Skeleton className="mb-6 h-10 w-80" />
        <div className="grid gap-4 lg:grid-cols-3">
          <Skeleton className="h-64 rounded-xl lg:col-span-2" />
          <Skeleton className="h-64 rounded-xl" />
        </div>
      </>
    );
  }
  if (detail.isError) {
    return (
      <>
        {back}
        <Card>
          <ErrorState error={detail.error} onRetry={() => void detail.refetch()} />
        </Card>
      </>
    );
  }

  const d = detail.data;
  const p = d.profile;
  const self = me?.uid === uid;
  const email = p.email ?? "";
  const company = p.company && Object.values(p.company).some(Boolean) ? p.company : null;

  return (
    <>
      {back}
      <PageHeader
        title={p.email ?? "(no email)"}
        description={p.display_name ?? undefined}
        actions={
          <>
            <RoleBadge role={d.role} />
            <StatusBadge disabled={d.disabled} />
          </>
        }
      />

      <Card className="mb-4">
        <CardContent className="flex flex-wrap gap-2">
          <SelfGuard self={self}>
            {d.disabled ? (
              <Button variant="outline" onClick={() => setDialog("enable")} disabled={self}>
                <CheckCircle2 /> Enable account
              </Button>
            ) : (
              <Button variant="outline" onClick={() => setDialog("disable")} disabled={self}>
                <Ban /> Disable account
              </Button>
            )}
          </SelfGuard>
          <SelfGuard self={self}>
            <Button
              variant="outline"
              onClick={() => {
                setNewRole(d.role ?? "none");
                setDialog("role");
              }}
              disabled={self}
            >
              <ShieldCheck /> Set role
            </Button>
          </SelfGuard>
          <Button variant="outline" onClick={() => setDialog("reset")} disabled={!p.email}>
            <KeyRound /> Send password reset
          </Button>
          <SelfGuard self={self}>
            <Button variant="destructive" onClick={() => setDialog("delete")} disabled={self || !email}>
              <Trash2 /> Delete user
            </Button>
          </SelfGuard>
        </CardContent>
      </Card>

      <div className="mb-4 grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Profile</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-x-8 md:grid-cols-2">
            <div>
              <Field label="Name">{p.display_name}</Field>
              <Field label="Email">{p.email}</Field>
              <Field label="Account type">
                <span className="capitalize">{p.account_type ?? "-"}</span>
              </Field>
              <Field label="Country">{p.country}</Field>
              <Field label="Phone">{p.phone}</Field>
              {company && <Field label="Company">{[company.name, company.reg_no, company.industry].filter(Boolean).join(" - ")}</Field>}
            </div>
            <div>
              <Field label="Created">{fmtDateTime(p.created_at)}</Field>
              <Field label="Updated">{fmtDateTime(p.updated_at)}</Field>
              <Field label="Last sign-in">{fmtDateTime(d.last_sign_in)}</Field>
              <Field label="Referral threshold">
                {typeof d.settings.referral_threshold === "number" ? fmtNum(d.settings.referral_threshold) : "default"}
              </Field>
              <Field label="Name on certificates">{d.settings.show_name_on_certificates ? "Yes" : "No"}</Field>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Activity</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {(
                [
                  ["Gradings", d.counts.gradings],
                  ["Rejected photos", d.counts.rejections],
                  ["Calibrations", d.counts.calibrations],
                  ["Certificates", d.counts.certificates],
                  ["Feedback", d.counts.feedback],
                ] as const
              ).map(([k, v]) => (
                <div key={k} className="rounded-lg border p-3">
                  <div className="text-xs text-muted-foreground">{k}</div>
                  <div className="text-xl font-semibold tabular-nums">{v}</div>
                </div>
              ))}
            </div>
            <div className="mt-4">
              <div className="mb-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">Devices</div>
              {d.devices.length ? (
                <ul className="space-y-1 text-sm">
                  {d.devices.map((dev) => (
                    <li key={dev}>{dev}</li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-muted-foreground">None recorded</p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="activity" className="mt-6">
        <TabsList>
          <TabsTrigger value="activity">Gradings and calibrations</TabsTrigger>
          {myRole === "admin" && <TabsTrigger value="notifications">Notifications</TabsTrigger>}
        </TabsList>
        <TabsContent value="activity">
          <h2 className="mb-2 mt-2 font-semibold">Recent gradings</h2>
          {d.last_gradings.length ? (
            <DataTable
              columns={gradingColumns}
              data={d.last_gradings}
              getRowId={(r) => r.grading_id}
              onRowClick={(r) => router.push(`/admin/gradings/detail/?id=${encodeURIComponent(r.grading_id)}`)}
            />
          ) : (
            <Card>
              <EmptyState title="No gradings" />
            </Card>
          )}

          <h2 className="mb-2 mt-6 font-semibold">Calibrations</h2>
          {d.calibrations.length ? (
            <DataTable columns={calibrationColumns} data={d.calibrations} getRowId={(r) => r.calibration_id} />
          ) : (
            <Card>
              <EmptyState title="No calibrations" />
            </Card>
          )}
        </TabsContent>
        {myRole === "admin" && (
          <TabsContent value="notifications" className="mt-2">
            <UserNotifications uid={uid} />
          </TabsContent>
        )}
      </Tabs>

      <ConfirmDialog
        open={dialog === "disable"}
        onOpenChange={(o) => setDialog(o ? "disable" : null)}
        title="Disable this account?"
        description="The user is signed out and cannot use the app until the account is enabled again."
        confirmLabel="Disable"
        destructive
        onConfirm={() => setDisabled.mutateAsync(true)}
      />
      <ConfirmDialog
        open={dialog === "enable"}
        onOpenChange={(o) => setDialog(o ? "enable" : null)}
        title="Enable this account?"
        description="The user can sign in and use the app again."
        confirmLabel="Enable"
        onConfirm={() => setDisabled.mutateAsync(false)}
      />
      <ConfirmDialog
        open={dialog === "role"}
        onOpenChange={(o) => setDialog(o ? "role" : null)}
        title="Set dashboard role"
        description="Admins can use the whole dashboard. Reviewers see only the review queue and gradings."
        confirmLabel="Save role"
        onConfirm={() => setRole.mutateAsync(newRole)}
      >
        <NativeSelect
          label="Role"
          value={newRole}
          onChange={(v) => setNewRole(v as RoleSetting)}
          options={[
            { value: "none", label: "None (app user)" },
            { value: "reviewer", label: "Reviewer" },
            { value: "admin", label: "Admin" },
          ]}
        />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "reset"}
        onOpenChange={(o) => setDialog(o ? "reset" : null)}
        title="Send a password reset email?"
        description={`Firebase sends a reset link to ${email}.`}
        confirmLabel="Send email"
        onConfirm={() => reset.mutateAsync()}
      />
      <ConfirmDialog
        open={dialog === "delete"}
        onOpenChange={(o) => setDialog(o ? "delete" : null)}
        title="Delete this user and all their data?"
        description="Gradings, photos, calibrations, feedback and the Firebase account are removed. Certificates become withdrawn. This cannot be undone."
        confirmLabel="Delete permanently"
        destructive
        confirmText={email}
        onConfirm={() => remove.mutateAsync()}
      />
      <ConfirmDialog
        open={resetLink !== null}
        onOpenChange={(o) => !o && setResetLink(null)}
        title="Email could not be sent"
        description="Copy this one-time reset link and send it to the user yourself. It is shown only here."
        confirmLabel="Copy link"
        onConfirm={async () => {
          await navigator.clipboard.writeText(resetLink ?? "");
          toast.success("Link copied.");
          setResetLink(null);
        }}
      >
        <Input readOnly value={resetLink ?? ""} className="font-mono text-xs" onFocus={(e) => e.target.select()} />
      </ConfirmDialog>
    </>
  );
}

function UserDetailPage() {
  const uid = useSearchParams().get("uid");
  if (!uid) return <EmptyState title="No user selected" />;
  return <UserDetailView key={uid} uid={uid} />;
}

export default function Page() {
  return (
    <Suspense fallback={<Skeleton className="h-64 rounded-xl" />}>
      <UserDetailPage />
    </Suspense>
  );
}
