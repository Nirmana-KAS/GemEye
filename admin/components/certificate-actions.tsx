"use client";

import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ReasonField } from "@/components/reason-field";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const CERT_NO = /^GE-\d{6}-\d{5}$/;

export type CertificateDialog = "revoke" | "supersede" | null;

/** Revoke (reason + typed number) and supersede (new number + reason) dialogs for one
 * certificate. Used by the Certificates detail page and the Grading detail page. */
export function CertificateActionDialogs({
  certNo,
  dialog,
  onDialogChange,
  onDone,
}: {
  certNo: string;
  dialog: CertificateDialog;
  onDialogChange: (d: CertificateDialog) => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [reason, setReason] = useState("");
  const [newNo, setNewNo] = useState("");
  const path = `/admin/certificates/${encodeURIComponent(certNo)}`;

  const done = (msg: string) => {
    toast.success(msg);
    setReason("");
    setNewNo("");
    onDone();
  };
  const revoke = useMutation({
    mutationFn: () => api(`${path}/revoke`, { method: "POST", body: { reason: reason.trim() } }),
    onSuccess: () => done("Certificate revoked. The owner was notified."),
  });
  const supersede = useMutation({
    mutationFn: () => api(`${path}/supersede`, { method: "POST", body: { new_cert_no: newNo.trim().toUpperCase(), reason: reason.trim() } }),
    onSuccess: () => done("Certificate superseded. The owner was notified."),
  });

  const newNoClean = newNo.trim().toUpperCase();
  const newNoOk = CERT_NO.test(newNoClean) && newNoClean !== certNo;

  return (
    <>
      <ConfirmDialog
        open={dialog === "revoke"}
        onOpenChange={(o) => onDialogChange(o ? "revoke" : null)}
        title="Revoke this certificate?"
        description="The public page shows it as revoked and the owner gets a notification. This cannot be undone."
        confirmLabel="Revoke"
        destructive
        confirmText={certNo}
        confirmDisabled={!reason.trim()}
        onConfirm={() => revoke.mutateAsync()}
      >
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "supersede"}
        onOpenChange={(o) => onDialogChange(o ? "supersede" : null)}
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
            <p className="text-xs text-destructive">{newNoClean === certNo ? "Use a different certificate." : "Format: GE-YYYYMM-NNNNN"}</p>
          )}
        </div>
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
    </>
  );
}
