export interface DiffRow {
  key: string;
  before: string;
  after: string;
  changed: boolean;
}

function isPlain(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

function flatten(v: unknown, prefix: string, out: Map<string, unknown>) {
  if (isPlain(v) && Object.keys(v).length) {
    for (const [k, x] of Object.entries(v)) flatten(x, prefix ? `${prefix}.${k}` : k, out);
  } else if (prefix) {
    out.set(prefix, v);
  }
}

function show(v: unknown): string {
  if (v === undefined) return "-";
  return typeof v === "string" ? v : JSON.stringify(v);
}

/** Before/after of an audit entry as one row per (nested) field, changed ones flagged. */
export function auditDiff(before: unknown, after: unknown): DiffRow[] {
  const a = new Map<string, unknown>();
  const b = new Map<string, unknown>();
  flatten(before, "", a);
  flatten(after, "", b);
  if (!isPlain(before) && before != null) a.set("value", before);
  if (!isPlain(after) && after != null) b.set("value", after);
  const keys = [...new Set([...a.keys(), ...b.keys()])].sort();
  return keys.map((key) => {
    const x = show(a.get(key));
    const y = show(b.get(key));
    return { key, before: x, after: y, changed: x !== y };
  });
}

/** Short text of an audit target ({uid: "..."} -> "uid: ..."). */
export function targetText(target: Record<string, unknown> | null | undefined): string {
  if (!target) return "-";
  return Object.entries(target)
    .map(([k, v]) => `${k}: ${typeof v === "string" ? v : JSON.stringify(v)}`)
    .join(", ");
}
