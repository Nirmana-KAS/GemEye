import { Badge } from "@/components/ui/badge";

export function RoleBadge({ role }: { role: string | null | undefined }) {
  if (role === "admin") return <Badge>Admin</Badge>;
  if (role === "reviewer") return <Badge variant="secondary">Reviewer</Badge>;
  if (role === "none") return <span className="text-xs text-muted-foreground">User</span>;
  return <span className="text-xs text-muted-foreground">-</span>;
}

export function StatusBadge({ disabled }: { disabled: boolean | null | undefined }) {
  if (disabled == null) return <span className="text-xs text-muted-foreground">-</span>;
  return disabled ? (
    <Badge variant="destructive">Disabled</Badge>
  ) : (
    <span className="text-xs font-medium text-success">Active</span>
  );
}
