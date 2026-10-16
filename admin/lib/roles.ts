import type { Role } from "./types";

/** Dashboard role from Firebase custom claims (admin wins over reviewer). */
export function roleFromClaims(claims: Record<string, unknown> | null | undefined): Role | null {
  if (!claims) return null;
  if (claims.admin === true) return "admin";
  if (claims.reviewer === true) return "reviewer";
  return null;
}

export interface NavItem {
  href: string;
  label: string;
  roles: Role[];
  built: boolean;
}

export const NAV: NavItem[] = [
  { href: "/admin/", label: "Overview", roles: ["admin"], built: true },
  { href: "/admin/users/", label: "Users", roles: ["admin"], built: true },
  { href: "/admin/gradings/", label: "Gradings", roles: ["admin", "reviewer"], built: true },
  { href: "/admin/review-queue/", label: "Review queue", roles: ["admin", "reviewer"], built: true },
  { href: "/admin/model-monitoring/", label: "Model monitoring", roles: ["admin"], built: true },
  { href: "/admin/calibrations/", label: "Calibrations", roles: ["admin"], built: true },
  { href: "/admin/app-control/", label: "App control", roles: ["admin"], built: true },
  { href: "/admin/announcements/", label: "Announcements", roles: ["admin"], built: true },
  { href: "/admin/notifications/", label: "Notifications", roles: ["admin"], built: true },
  { href: "/admin/feedback/", label: "Feedback", roles: ["admin"], built: true },
  { href: "/admin/certificates/", label: "Certificates", roles: ["admin"], built: true },
  { href: "/admin/audit-log/", label: "Audit log", roles: ["admin"], built: true },
];

export const LOGIN_PATH = "/admin/login/";

function normalise(path: string): string {
  const p = path.split(/[?#]/)[0] || "/";
  return p.endsWith("/") ? p : `${p}/`;
}

export function samePath(a: string, b: string): boolean {
  return normalise(a) === normalise(b);
}

/** The nav section a path belongs to (detail pages belong to their list). */
export function sectionFor(pathname: string): NavItem | undefined {
  const p = normalise(pathname);
  if (p === "/admin/") return NAV[0];
  return NAV.filter((n) => n.href !== "/admin/" && p.startsWith(n.href)).sort(
    (a, b) => b.href.length - a.href.length,
  )[0];
}

export function navFor(role: Role): NavItem[] {
  return NAV.filter((n) => n.roles.includes(role));
}

export function canAccess(role: Role | null, pathname: string): boolean {
  if (!role) return false;
  const s = sectionFor(pathname);
  return !!s && s.roles.includes(role);
}

/** First page after sign-in. */
export function homeFor(role: Role): string {
  return role === "admin" ? "/admin/" : "/admin/gradings/";
}

export type GuardDecision = "loading" | "login" | "no-access" | "allow";

export function guardDecision(s: {
  loading: boolean;
  signedIn: boolean;
  role: Role | null;
  pathname: string;
  forbidden?: boolean;
}): GuardDecision {
  if (s.loading) return "loading";
  if (!s.signedIn || !s.role) return "login";
  if (s.forbidden || !canAccess(s.role, s.pathname)) return "no-access";
  return "allow";
}
