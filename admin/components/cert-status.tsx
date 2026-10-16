import { certificateStatus } from "@/lib/feedback";
import type { CertificateRow, CertificateStatus } from "@/lib/types";
import { cn } from "@/lib/utils";

const TONE: Record<CertificateStatus, string> = {
  valid: "bg-success/15 text-success",
  revoked: "bg-destructive/10 text-destructive",
  superseded: "bg-warning/15 text-warning",
  withdrawn: "bg-muted text-muted-foreground",
};

export function CertStatus({ c }: { c: Pick<CertificateRow, "status" | "superseded_by"> }) {
  const s = certificateStatus(c);
  return <span className={cn("rounded-md px-1.5 py-0.5 text-xs font-medium capitalize", TONE[s])}>{s}</span>;
}
