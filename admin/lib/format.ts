import { format, formatDistanceToNowStrict, parseISO } from "date-fns";

function toDate(v: string | null | undefined): Date | null {
  if (!v) return null;
  const d = parseISO(v.endsWith("Z") || /[+-]\d\d:\d\d$/.test(v) ? v : `${v}Z`);
  return Number.isNaN(d.getTime()) ? null : d;
}

export function fmtDateTime(v: string | null | undefined): string {
  const d = toDate(v);
  return d ? format(d, "yyyy-MM-dd HH:mm") : "-";
}

export function fmtDate(v: string | null | undefined): string {
  const d = toDate(v);
  return d ? format(d, "yyyy-MM-dd") : "-";
}

export function fmtAgo(v: string | null | undefined): string {
  const d = toDate(v);
  return d ? `${formatDistanceToNowStrict(d)} ago` : "-";
}

export function fmtPct(v: number | null | undefined, digits = 1): string {
  return v == null ? "-" : `${(v * 100).toFixed(digits)}%`;
}

export function fmtNum(v: number | null | undefined, digits = 2): string {
  return v == null ? "-" : v.toFixed(digits);
}

export function fmtMs(v: number | null | undefined): string {
  return v == null ? "-" : v >= 1000 ? `${(v / 1000).toFixed(2)} s` : `${Math.round(v)} ms`;
}

/** Start (00:00) or end (23:59:59.999) of a yyyy-MM-dd day in local time, as ISO. */
export function dayBoundIso(day: string, end: boolean): string | undefined {
  if (!day) return undefined;
  const d = new Date(`${day}T${end ? "23:59:59.999" : "00:00:00"}`);
  return Number.isNaN(d.getTime()) ? undefined : d.toISOString();
}
