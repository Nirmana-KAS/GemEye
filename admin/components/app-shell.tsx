"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Activity,
  ClipboardCheck,
  FileBadge,
  Gem,
  LayoutDashboard,
  LogOut,
  Megaphone,
  MessageSquare,
  Moon,
  Pipette,
  ScrollText,
  SlidersHorizontal,
  Sun,
  Users,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTheme } from "next-themes";

import { useAuth } from "@/components/auth-provider";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { API_BASE_URL, environmentLabel } from "@/lib/env";
import { navFor, sectionFor } from "@/lib/roles";
import type { HealthResponse } from "@/lib/types";
import { cn } from "@/lib/utils";

const ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  "/admin/": LayoutDashboard,
  "/admin/users/": Users,
  "/admin/gradings/": Gem,
  "/admin/review-queue/": ClipboardCheck,
  "/admin/model-monitoring/": Activity,
  "/admin/calibrations/": Pipette,
  "/admin/app-control/": SlidersHorizontal,
  "/admin/announcements/": Megaphone,
  "/admin/feedback/": MessageSquare,
  "/admin/certificates/": FileBadge,
  "/admin/audit-log/": ScrollText,
};

function Sidebar() {
  const { role } = useAuth();
  const pathname = usePathname();
  const active = sectionFor(pathname)?.href;
  if (!role) return null;
  return (
    <aside className="sticky top-0 flex h-screen w-60 shrink-0 flex-col border-r bg-sidebar text-sidebar-foreground">
      <div className="flex h-14 items-center gap-2 border-b px-5">
        <div className="flex size-7 items-center justify-center rounded-md bg-primary text-primary-foreground">
          <Gem className="size-4" />
        </div>
        <span className="font-semibold tracking-tight">GemEye Admin</span>
      </div>
      <nav className="flex-1 space-y-0.5 overflow-y-auto p-3">
        {navFor(role).map((n) => {
          const Icon = ICONS[n.href] ?? LayoutDashboard;
          const on = active === n.href;
          return (
            <Link
              key={n.href}
              href={n.href}
              className={cn(
                "flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors",
                on
                  ? "bg-sidebar-accent font-medium text-sidebar-accent-foreground"
                  : "text-muted-foreground hover:bg-muted hover:text-foreground",
              )}
            >
              <Icon className={cn("size-4", on && "text-sidebar-primary")} />
              <span className="flex-1">{n.label}</span>
              {!n.built && <span className="text-[10px] uppercase tracking-wide text-muted-foreground/70">soon</span>}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}

function ServerStatus() {
  const { api } = useAuth();
  const health = useQuery({
    queryKey: ["health"],
    queryFn: () => api<HealthResponse>("/health", { anonymous: true, silent: true }),
    refetchInterval: 30_000,
    retry: false,
  });
  const ok = health.data?.status === "ok" && health.data.models_loaded;
  const state = health.isPending ? "checking" : health.isError ? "offline" : ok ? "online" : "degraded";
  const colour = { checking: "bg-muted-foreground", offline: "bg-destructive", online: "bg-success", degraded: "bg-warning" }[state];
  return (
    <Tooltip>
      <TooltipTrigger className="flex items-center gap-2 text-sm text-muted-foreground">
        <span className={cn("size-2.5 rounded-full", colour)} />
        Server {state}
      </TooltipTrigger>
      <TooltipContent>
        {API_BASE_URL}
        {health.data ? ` - model ${health.data.model_version}` : ""}
      </TooltipContent>
    </Tooltip>
  );
}

function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const dark = resolvedTheme === "dark";
  return (
    <Button variant="ghost" size="icon" aria-label="Toggle dark mode" onClick={() => setTheme(dark ? "light" : "dark")}>
      {dark ? <Sun /> : <Moon />}
    </Button>
  );
}

function UserMenu() {
  const { user, role, signOut } = useAuth();
  const initial = (user?.email ?? "?").charAt(0).toUpperCase();
  return (
    <DropdownMenu>
      <DropdownMenuTrigger render={<Button variant="ghost" className="gap-2 px-2" />}>
        <span className="flex size-7 items-center justify-center rounded-full bg-primary text-xs font-semibold text-primary-foreground">
          {initial}
        </span>
        <span className="hidden text-sm lg:inline">{user?.email}</span>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-64">
        <DropdownMenuGroup>
          <DropdownMenuLabel>
            <div className="truncate text-sm font-medium text-foreground">{user?.email}</div>
            <div className="text-xs capitalize text-muted-foreground">{role}</div>
          </DropdownMenuLabel>
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuItem onClick={() => void signOut()}>
          <LogOut /> Sign out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const env = environmentLabel();
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background/95 px-6 backdrop-blur">
          <span
            className={cn(
              "rounded-md px-2 py-0.5 text-xs font-semibold tracking-wide",
              env === "DEV" ? "bg-warning/15 text-warning" : "bg-success/15 text-success",
            )}
          >
            {env}
          </span>
          <ServerStatus />
          <div className="ml-auto flex items-center gap-1">
            <ThemeToggle />
            <UserMenu />
          </div>
        </header>
        <main className="mx-auto w-full max-w-[1400px] flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}
