"use client";

import { AppShell } from "@/components/app-shell";
import { useAuth } from "@/components/auth-provider";
import { RoleGuard } from "@/components/role-guard";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, role, loading } = useAuth();
  // The shell appears only for signed-in staff; RoleGuard redirects everyone else.
  if (loading || !user || !role) return <RoleGuard>{children}</RoleGuard>;
  return (
    <AppShell>
      <RoleGuard>{children}</RoleGuard>
    </AppShell>
  );
}
