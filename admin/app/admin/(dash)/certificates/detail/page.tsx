"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Ban, Copy, ExternalLink, FileText, Replace } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { CertStatus } from "@/components/cert-status";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { GradeChip, YesNo } from "@/components/grade-chip";
import { ColourValuesView, Photo, Row } from "@/components/grading-parts";
import { EmptyState, ErrorState, PageHeader } from "@/components/states";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { fmtDateTime, fmtNum, fmtPct } from "@/lib/format";
import type { CertificateDetail } from "@/lib/types";

const CERT_NO = /^GE-\d{6}-\d{5}$/;
const REASON_MAX = 500;

function ReasonField({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="space-y-1.5">
      <div className="flex justify-between">
        <Label htmlFor="reason">Reason (required)</Label>
        <span className="text-xs text-muted-foreground">
          {value.length}/{REASON_MAX}
        </span>
      </div>
      <textarea
        id="reason"
        rows={3}
        maxLength={REASON_MAX}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
      />
    </div>
  );
}

function CertificateView({ certNo }: { certNo: string }) {
  const api = useApi();
  const qc = useQueryClient();
  const [dialog, setDialog] = useState<"revoke" | "supersede" | null>(null);
  const [reason, setReason] = useState("");
  const [newNo, setNewNo] = useState("");
  const path = `/admin/certificates/${encodeURIComponent(certNo)}`;

  const detail = useQuery({ queryKey: ["admin-certificate", certNo], queryFn: () => api<CertificateDetail>(path) });
  const done = (msg: string) => {
    toast.success(msg);
    setReason("");
    setNewNo("");
    void qc.invalidateQueries({ queryKey: ["admin-certificate", certNo] });
    void qc.invalidateQueries({ queryKey: ["admin-certificates"] });
  };
  const revoke = useMutation({
    mutationFn: () => api(`${path}/revoke`, { method: "POST", body: { reason: reason.trim() } }),
    onSuccess: () => done("Certificate revoked. The owner was notified."),
  });
  const supersede = useMutation({
    mutationFn: () => api(`${path}/supersede`, { method: "POST", body: { new_cert_no: newNo.trim().toUpperCase(), reason: reason.trim() } }),
    onSuccess: () => done("Certificate superseded. The owner was notified."),
  });

  const back = (
    <Link href="/admin/certificates/" className="mb-4 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-4" /> Certificates
    </Link>
  );
  if (detail.isPending) {
    return (
      <>
        {back}
        <Skeleton className="mb-6 h-10 w-80" />
        <Skeleton className="h-96 rounded-xl" />
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

  const c = detail.data;
  const s = c.snapshot;
  const valid = c.status === "valid";
  const newNoClean = newNo.trim().toUpperCase();
  const newNoOk = CERT_NO.test(newNoClean) && newNoClean !== c.cert_no;

  return (
    <>
      {back}
      <PageHeader
        title={c.cert_no}
        description={c.user_email ?? (c.status === "withdrawn" ? "Owner account deleted" : undefined)}
        actions={
          <>
            <CertStatus c={c} />
            {valid && (
              <>
                <Button variant="outline" onClick={() => setDialog("supersede")}>
                  <Replace /> Supersede
                </Button>
                <Button variant="destructive" onClick={() => setDialog("revoke")}>
                  <Ban /> Revoke
                </Button>
              </>
            )}
          </>
        }
      />

      {!valid && (
        <Card className="mb-4 border-destructive/30">
          <CardContent className="space-y-1 text-sm">
            <p>
              <span className="font-medium capitalize">{c.status}</span>
              {c.revoked_at && ` on ${fmtDateTime(c.revoked_at)}`}
              {c.withdrawn_at && ` on ${fmtDateTime(c.withdrawn_at)}`}
            </p>
            {c.revoked_reason && <p className="text-muted-foreground">Reason: {c.revoked_reason}</p>}
            {c.superseded_by && (
              <p>
                Replaced by{" "}
                <Link className="font-mono text-primary underline" href={`/admin/certificates/detail/?no=${encodeURIComponent(c.superseded_by)}`}>
                  {c.superseded_by}
                </Link>
              </p>
            )}
          </CardContent>
        </Card>
      )}

      <div className="grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Photo</CardTitle>
          </CardHeader>
          <CardContent>
            <Photo url={c.image_url} alt={`Stone of ${c.cert_no}`} empty="No photo" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Snapshot at issue</CardTitle>
          </CardHeader>
          <CardContent>
            {s ? (
              <>
                <Row label="Grade">
                  <GradeChip grade={s.grade} showName />
                </Row>
                <Row label="Trade name">{s.trade_name}</Row>
                <Row label="Stone ID" mono>
                  {s.stone_id}
                </Row>
                <Row label="Confidence">{fmtPct(s.confidence)}</Row>
                <Row label="Uncertainty">{fmtNum(s.uncertainty, 3)}</Row>
                <Row label="Referred">
                  <YesNo value={s.referred} />
                </Row>
                <Row label="Model version">{s.model_version}</Row>
                <Row label="Captured">{fmtDateTime(s.captured_at)}</Row>
                <Row label="Issued">{fmtDateTime(c.issued_at)}</Row>
                <Row label="Calibration" mono>
                  {s.calibration ? `${s.calibration.session_id} (${fmtNum(s.calibration.residual, 3)})` : "-"}
                </Row>
                <Row label="Owner on certificate">{c.owner ? [c.owner.display_name, c.owner.company].filter(Boolean).join(" - ") || "-" : "Hidden"}</Row>
                {c.grading_id && (
                  <Row label="Grading">
                    <Link className="text-primary underline" href={`/admin/gradings/detail/?id=${encodeURIComponent(c.grading_id)}`}>
                      Open grading
                    </Link>
                  </Row>
                )}
              </>
            ) : (
              <EmptyState title="No snapshot" hint="Withdrawn certificates keep only the number, date and status." />
            )}
          </CardContent>
        </Card>
        <div className="space-y-4">
          {s?.colour && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Colour values</CardTitle>
              </CardHeader>
              <CardContent>
                <ColourValuesView colour={s.colour} deltaE={s.delta_e00_to_typical} />
              </CardContent>
            </Card>
          )}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">PDF and verification</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              {c.pdf_url ? (
                <a href={c.pdf_url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1.5 text-primary underline">
                  <FileText className="size-4" /> Open PDF <ExternalLink className="size-3" />
                </a>
              ) : (
                <p className="text-muted-foreground">No PDF uploaded</p>
              )}
              <div>
                <p className="text-xs text-muted-foreground">SHA-256 {c.pdf_uploaded_at && `(uploaded ${fmtDateTime(c.pdf_uploaded_at)})`}</p>
                <p className="flex items-start gap-1 break-all font-mono text-xs">
                  {c.pdf_sha256 ?? "-"}
                  {c.pdf_sha256 && (
                    <Button
                      variant="ghost"
                      size="icon-xs"
                      aria-label="Copy hash"
                      onClick={() => void navigator.clipboard.writeText(c.pdf_sha256 ?? "").then(() => toast.success("Hash copied."))}
                    >
                      <Copy />
                    </Button>
                  )}
                </p>
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Verify URL</p>
                <p className="break-all font-mono text-xs">{c.verify_url_masked ?? "-"}</p>
                <p className="mt-1 text-xs text-muted-foreground">The secret token is not shown in the dashboard; the full link is in the QR code on the PDF.</p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      <ConfirmDialog
        open={dialog === "revoke"}
        onOpenChange={(o) => setDialog(o ? "revoke" : null)}
        title="Revoke this certificate?"
        description="The public page shows it as revoked and the owner gets a notification. This cannot be undone."
        confirmLabel="Revoke"
        destructive
        confirmText={c.cert_no}
        confirmDisabled={!reason.trim()}
        onConfirm={() => revoke.mutateAsync()}
      >
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "supersede"}
        onOpenChange={(o) => setDialog(o ? "supersede" : null)}
        title="Supersede this certificate?"
        description="It is revoked and the public page shows 'Replaced by' the new number, which must be a different valid certificate."
        confirmLabel="Supersede"
        destructive
        confirmDisabled={!reason.trim() || !newNoOk}
        onConfirm={() => supersede.mutateAsync()}
      >
        <div className="space-y-1.5">
          <Label htmlFor="new-no">New certificate number</Label>
          <Input
            id="new-no"
            value={newNo}
            onChange={(e) => setNewNo(e.target.value)}
            placeholder="GE-YYYYMM-NNNNN"
            className="font-mono"
            aria-invalid={!!newNo && !newNoOk}
          />
          {newNo && !newNoOk && (
            <p className="text-xs text-destructive">{newNoClean === c.cert_no ? "Use a different certificate." : "Format: GE-YYYYMM-NNNNN"}</p>
          )}
        </div>
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
    </>
  );
}

function CertificateDetailPage() {
  const no = useSearchParams().get("no");
  if (!no) return <EmptyState title="No certificate selected" />;
  return <CertificateView key={no} certNo={no} />;
}

export default function Page() {
  return (
    <Suspense fallback={<Skeleton className="h-64 rounded-xl" />}>
      <CertificateDetailPage />
    </Suspense>
  );
}
