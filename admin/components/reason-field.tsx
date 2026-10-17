"use client";

import { Label } from "@/components/ui/label";
import { REASON_MAX } from "@/lib/admin-powers";

/** Multi-line reason input with a counter (the server limit is 500 characters). */
export function ReasonField({
  value,
  onChange,
  label = "Reason (required)",
  id = "reason",
  max = REASON_MAX,
}: {
  value: string;
  onChange: (v: string) => void;
  label?: string;
  id?: string;
  max?: number;
}) {
  return (
    <div className="space-y-1.5">
      <div className="flex justify-between">
        <Label htmlFor={id}>{label}</Label>
        <span className="text-xs text-muted-foreground">
          {value.length}/{max}
        </span>
      </div>
      <textarea
        id={id}
        rows={3}
        maxLength={max}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-lg border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
      />
    </div>
  );
}
