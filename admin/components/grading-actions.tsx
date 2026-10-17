"use client";

import { useQueryClient } from "@tanstack/react-query";
import { Ban, ChevronDown, ClipboardCheck, Eye, EyeOff, FileText, RefreshCw, Replace, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { CertificateActionDialogs, type CertificateDialog } from "@/components/certificate-actions";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ReasonField } from "@/components/reason-field";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { canConfirm } from "@/lib/admin-powers";
import { deleteGradingPermanently, gradingAction, regradeGrading } from "@/lib/api";
import type { GradingDetail } from "@/lib/types";

type Dialog = "hide" | "restore" | "review" | "regrade" | "delete" | null;

/** Admin action bar of the grading detail page, with its confirm dialogs. */
export function GradingActions({ d }: { d: GradingDetail }) {
  const api = useApi();
  const qc = useQueryClient();
  const router = useRouter();
  const [dialog, setDialog] = useState<Dialog>(null);
  const [certDialog, setCertDialog] = useState<CertificateDialog>(null);
  const [reason, setReason] = useState("");
  const id = d.grading_id;
  const reviewed = !!d.review;
  const inQueue = !reviewed && (!!d.result?.referred || !!d.review_request);
  const cert = d.certificate;

  const open = (x: Dialog) => {
    setReason("");
    setDialog(x);
  };
  const refresh = () => {
    void qc.invalidateQueries({ queryKey: ["admin-grading", id] });
    void qc.invalidateQueries({ queryKey: ["admin-gradings"] });
  };
  const run = async (fn: () => Promise<unknown>, msg: string) => {
    await fn();
    toast.success(msg);
    refresh();
  };

  return (
    <>
      <Card className="mb-4">
        <CardContent className="flex flex-wrap gap-2">
          {d.hidden ? (
            <Button variant="outline" onClick={() => open("restore")}>
              <Eye /> Restore
            </Button>
          ) : (
            <Button variant="outline" onClick={() => open("hide")}>
              <EyeOff /> Hide from user
            </Button>
          )}
          <Button variant="outline" onClick={() => open("review")} disabled={reviewed || inQueue || d.status !== "ok"}>
            <ClipboardCheck /> {reviewed ? "Reviewed" : inQueue ? "In review queue" : "Send to review"}
          </Button>
          <Button variant="outline" onClick={() => open("regrade")} disabled={!d.image_url}>
            <RefreshCw /> Re-grade
          </Button>
          <DropdownMenu>
            <DropdownMenuTrigger render={<Button variant="outline" disabled={!cert || cert.status !== "valid"} />}>
              <FileText /> Certificate <ChevronDown />
            </DropdownMenuTrigger>
            <DropdownMenuContent align="start">
              <DropdownMenuItem onClick={() => setCertDialog("supersede")}>
                <Replace /> Supersede
              </DropdownMenuItem>
              <DropdownMenuItem variant="destructive" onClick={() => setCertDialog("revoke")}>
                <Ban /> Revoke
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <Button variant="destructive" className="ml-auto" onClick={() => open("delete")}>
            <Trash2 /> Delete permanently
          </Button>
        </CardContent>
      </Card>

      <ConfirmDialog
        open={dialog === "hide"}
        onOpenChange={(o) => setDialog(o ? "hide" : null)}
        title="Hide this grading from the user?"
        description="It disappears from their History and stats in the app. It stays in the database and can be restored."
        confirmLabel="Hide"
        confirmDisabled={!canConfirm({ reasonRequired: true }, reason, "")}
        onConfirm={() => run(() => gradingAction(api, id, "hide", reason.trim()), "Grading hidden from the user.")}
      >
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "restore"}
        onOpenChange={(o) => setDialog(o ? "restore" : null)}
        title="Restore this grading?"
        description="It appears in the user's History again."
        confirmLabel="Restore"
        confirmDisabled={!canConfirm({ reasonRequired: false }, reason, "")}
        onConfirm={() => run(() => gradingAction(api, id, "restore", reason.trim() || undefined), "Grading restored.")}
      >
        <ReasonField value={reason} onChange={setReason} label="Reason (optional)" />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "review"}
        onOpenChange={(o) => setDialog(o ? "review" : null)}
        title="Send this stone to the review queue?"
        description='A gemologist sees it in the Review queue with the reason "admin".'
        confirmLabel="Send to review"
        confirmDisabled={!canConfirm({ reasonRequired: false }, reason, "")}
        onConfirm={() => run(() => gradingAction(api, id, "send-to-review", reason.trim() || undefined), "Sent to the review queue.")}
      >
        <ReasonField value={reason} onChange={setReason} label="Note for the reviewer (optional)" />
      </ConfirmDialog>
      <ConfirmDialog
        open={dialog === "regrade"}
        onOpenChange={(o) => setDialog(o ? "regrade" : null)}
        title="Re-grade with the current model?"
        description="The current model runs on the stored photo. The result is saved as a re-grade next to the original, which is never changed."
        confirmLabel="Re-grade"
        onConfirm={() => run(() => regradeGrading(api, id), "Re-grade saved.")}
      />
      <ConfirmDialog
        open={dialog === "delete"}
        onOpenChange={(o) => setDialog(o ? "delete" : null)}
        title="Delete this grading permanently?"
        description="For privacy requests only. The photo, Grad-CAM, reviews and the stone's notifications are deleted and its certificate is withdrawn. Only a minimal audit record without colour data is kept. This cannot be undone."
        confirmLabel="Delete permanently"
        destructive
        confirmText={id}
        confirmDisabled={!canConfirm({ reasonRequired: true }, reason, "")}
        onConfirm={async () => {
          const r = await deleteGradingPermanently(api, id, id, reason.trim());
          toast.success(r.withdrawn.length ? `Grading deleted. Certificate ${r.withdrawn.join(", ")} withdrawn.` : "Grading deleted.");
          void qc.invalidateQueries({ queryKey: ["admin-gradings"] });
          router.replace("/admin/gradings/");
        }}
      >
        <ReasonField value={reason} onChange={setReason} />
      </ConfirmDialog>
      {cert && <CertificateActionDialogs certNo={cert.cert_no} dialog={certDialog} onDialogChange={setCertDialog} onDone={refresh} />}
    </>
  );
}
