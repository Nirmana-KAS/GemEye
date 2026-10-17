"use client";

import { useQueryClient } from "@tanstack/react-query";
import { Ban, CheckCircle2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ReasonField } from "@/components/reason-field";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { canConfirm } from "@/lib/admin-powers";
import { setDeviceBlocked } from "@/lib/api";
import { fmtDateTime } from "@/lib/format";
import type { DeviceState } from "@/lib/types";

/** Devices the user graded or calibrated on, with block / unblock (reason required). */
export function UserDevices({ uid, devices }: { uid: string; devices: DeviceState[] }) {
  const api = useApi();
  const qc = useQueryClient();
  const [target, setTarget] = useState<DeviceState | null>(null);
  const [reason, setReason] = useState("");
  if (!devices.length) return <p className="text-sm text-muted-foreground">None recorded</p>;
  const blocking = !!target && !target.blocked;

  return (
    <>
      <ul className="space-y-2 text-sm">
        {devices.map((d) => (
          <li key={d.device_id} className="flex items-start gap-2">
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-1.5">
                <span className="break-words">{d.name ?? "Unknown model"}</span>
                <span className="font-mono text-xs text-muted-foreground">{d.short_id ?? d.device_id.slice(0, 8)}</span>
                {d.blocked && <Badge variant="destructive">Blocked</Badge>}
              </div>
              {d.blocked && (
                <p className="text-xs text-muted-foreground">
                  {fmtDateTime(d.blocked_at)}
                  {d.blocked_by_email && ` by ${d.blocked_by_email}`}
                  {d.blocked_reason && ` - ${d.blocked_reason}`}
                </p>
              )}
            </div>
            <Button
              variant="ghost"
              size="xs"
              onClick={() => {
                setReason("");
                setTarget(d);
              }}
            >
              {d.blocked ? (
                <>
                  <CheckCircle2 /> Unblock
                </>
              ) : (
                <>
                  <Ban /> Block
                </>
              )}
            </Button>
          </li>
        ))}
      </ul>
      <ConfirmDialog
        open={target !== null}
        onOpenChange={(o) => !o && setTarget(null)}
        title={blocking ? "Block this device?" : "Unblock this device?"}
        description={
          blocking
            ? `Grading and calibration uploads from this ${target?.name ?? "device"} (${target?.device_id.slice(0, 8)}) are refused ("This device is blocked. Contact support."). Other phones of the same model are not affected.`
            : `This ${target?.name ?? "device"} (${target?.device_id.slice(0, 8)}) can grade and calibrate again.`
        }
        confirmLabel={blocking ? "Block device" : "Unblock"}
        destructive={blocking}
        confirmText={blocking ? "BLOCK" : undefined}
        confirmDisabled={!canConfirm({ reasonRequired: true }, reason, "")}
        onConfirm={async () => {
          if (!target) return;
          await setDeviceBlocked(api, target.device_id, blocking, reason.trim());
          toast.success(blocking ? "Device blocked." : "Device unblocked.");
          void qc.invalidateQueries({ queryKey: ["admin-user", uid] });
        }}
      >
        <ReasonField value={reason} onChange={setReason} id="device-reason" />
      </ConfirmDialog>
    </>
  );
}
