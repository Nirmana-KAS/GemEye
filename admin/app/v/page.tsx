"use client";

import {
  AlertTriangle,
  Ban,
  CheckCircle2,
  Download,
  FileCheck2,
  FileX2,
  Gem,
  Loader2,
  RefreshCw,
  SearchX,
  ShieldCheck,
  UserCheck,
  WifiOff,
} from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

import { API_BASE_URL } from "@/lib/env";
import { fmtDate } from "@/lib/format";
import { gradeInfo, gradeTextColour } from "@/lib/grades";
import { cn } from "@/lib/utils";
import {
  certNoOf,
  checkPdf,
  DISCLAIMER,
  fetchVerify,
  parseVerifySlug,
  type PublicCertificate,
  type VerifyState,
} from "@/lib/verify";

// Public certificate verification (the QR target). No login, no admin layout;
// mobile first because QR codes are scanned with phones.

type Loaded = VerifyState | { kind: "loading" };

export default function VerifyPage() {
  const [slug, setSlug] = useState<string | null | undefined>(undefined);
  const [state, setState] = useState<Loaded>({ kind: "loading" });

  const load = useCallback(async (s: string) => {
    setState({ kind: "loading" });
    setState(await fetchVerify(API_BASE_URL, s));
  }, []);

  useEffect(() => {
    // Accepts /v/?c={slug} and /v/{slug} (Firebase rewrite or the 404 redirect).
    const s = parseVerifySlug(window.location.pathname, window.location.search);
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the slug is only known in the browser
    setSlug(s);
    if (s) void load(s);
    else setState({ kind: "not_found" });
  }, [load]);

  return (
    <div className="min-h-dvh bg-white text-foreground">
      <header className="bg-primary text-primary-foreground">
        <div className="mx-auto flex max-w-xl items-center gap-2 px-4 py-3">
          <Gem className="size-5" aria-hidden />
          <span className="font-semibold tracking-tight">GemEye</span>
          <span className="ml-auto text-xs opacity-80">Certificate verification</span>
        </div>
      </header>
      <main className="mx-auto max-w-xl space-y-4 px-4 py-5">
        <Body state={state} slug={slug} onRetry={() => slug && void load(slug)} />
        <p className="pt-2 text-xs leading-relaxed text-muted-foreground">
          {state.kind !== "loading" && "cert" in state ? state.cert.disclaimer || DISCLAIMER : DISCLAIMER}
        </p>
      </main>
    </div>
  );
}

function Body({ state, slug, onRetry }: { state: Loaded; slug: string | null | undefined; onRetry: () => void }) {
  switch (state.kind) {
    case "loading":
      return (
        <div className="flex items-center gap-2 py-16 text-sm text-muted-foreground" role="status">
          <Loader2 className="size-4 animate-spin" aria-hidden /> Checking certificate...
        </div>
      );
    case "not_found":
      return (
        <Banner tone="muted" icon={<SearchX className="size-6" />} title="Certificate not found">
          This link or QR code does not match a GemEye certificate. Check that the whole link was scanned or
          typed{slug ? ` (${certNoOf(slug)})` : ""}.
        </Banner>
      );
    case "unreachable":
      return (
        <Banner
          tone="muted"
          icon={<WifiOff className="size-6" />}
          title={state.rateLimited ? "Too many checks" : "Cannot reach GemEye"}
          action={
            <button
              type="button"
              onClick={onRetry}
              className="mt-3 inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground"
            >
              <RefreshCw className="size-4" aria-hidden /> Try again
            </button>
          }
        >
          {state.rateLimited
            ? "Please wait a minute and try again."
            : "The verification service could not be reached. Check your connection and try again."}
        </Banner>
      );
    case "withdrawn":
      return (
        <>
          <Banner tone="muted" icon={<FileX2 className="size-6" />} title="Certificate withdrawn">
            {state.cert.revoked_reason || "This certificate is no longer available."} The grading details were
            removed.
          </Banner>
          <Summary cert={state.cert} />
        </>
      );
    case "revoked":
      return (
        <>
          <Banner tone="danger" icon={<Ban className="size-6" />} title="Certificate revoked">
            {state.cert.revoked_reason ? `Reason: ${state.cert.revoked_reason}. ` : ""}
            Revoked on {fmtDate(state.cert.revoked_at)}. Do not rely on this certificate.
          </Banner>
          <Details cert={state.cert} />
        </>
      );
    case "superseded":
      return (
        <>
          <Banner tone="warning" icon={<AlertTriangle className="size-6" />} title="Certificate replaced">
            Replaced by{" "}
            {state.cert.superseded_by_url ? (
              <a className="font-mono font-medium underline" href={state.cert.superseded_by_url}>
                {state.cert.superseded_by}
              </a>
            ) : (
              <span className="font-mono font-medium">{state.cert.superseded_by}</span>
            )}{" "}
            on {fmtDate(state.cert.revoked_at)}
            {state.cert.revoked_reason ? ` (${state.cert.revoked_reason})` : ""}. The values below are out of date.
          </Banner>
          <Details cert={state.cert} />
        </>
      );
    case "valid":
      return (
        <>
          <Banner tone="success" icon={<CheckCircle2 className="size-6" />} title="Valid certificate">
            This certificate was issued by GemEye and has not been changed or revoked.
          </Banner>
          <Details cert={state.cert} />
        </>
      );
  }
}

const TONES = {
  success: "border-success/30 bg-success/10 text-success",
  danger: "border-destructive/30 bg-destructive/10 text-destructive",
  warning: "border-warning/30 bg-warning/10 text-warning",
  muted: "border-border bg-muted text-muted-foreground",
} as const;

function Banner({
  tone,
  icon,
  title,
  children,
  action,
}: {
  tone: keyof typeof TONES;
  icon: React.ReactNode;
  title: string;
  children: React.ReactNode;
  action?: React.ReactNode;
}) {
  return (
    <section className={cn("flex gap-3 rounded-xl border p-4", TONES[tone])} role="status">
      <div className="shrink-0 pt-0.5">{icon}</div>
      <div className="min-w-0">
        <h1 className="text-lg font-semibold">{title}</h1>
        <p className="mt-1 text-sm leading-relaxed text-foreground/80">{children}</p>
        {action}
      </div>
    </section>
  );
}

function Card({ children, className }: { children: React.ReactNode; className?: string }) {
  return <section className={cn("rounded-xl border border-border bg-white p-4", className)}>{children}</section>;
}

function Row({ label, children, mono }: { label: string; children: React.ReactNode; mono?: boolean }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-1.5 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className={cn("text-right", mono && "font-mono text-xs")}>{children}</span>
    </div>
  );
}

function Summary({ cert }: { cert: PublicCertificate }) {
  return (
    <Card>
      <Row label="Certificate number" mono>
        {cert.cert_no}
      </Row>
      <Row label="Issue date">{fmtDate(cert.issued_at)}</Row>
    </Card>
  );
}

function Details({ cert }: { cert: PublicCertificate }) {
  const s = cert.snapshot;
  const g = gradeInfo(s?.grade);
  const c = s?.colour;
  const reviewed = cert.review?.gemologist_grade;
  const n = (v: number | null | undefined, d = 1) => (v == null ? "-" : v.toFixed(d));
  return (
    <>
      <Card>
        <Row label="Certificate number" mono>
          {cert.cert_no}
        </Row>
        <Row label="Issue date">{fmtDate(cert.issued_at)}</Row>
        {s?.stone_id && (
          <Row label="Stone" mono>
            {s.stone_id}
          </Row>
        )}
        {cert.owner?.display_name && <Row label="Owner">{cert.owner.display_name}</Row>}
        {cert.owner?.company && <Row label="Company">{cert.owner.company}</Row>}
      </Card>

      {g && (
        <Card>
          <div className="flex items-center gap-3">
            <span
              className="inline-flex size-14 shrink-0 items-center justify-center rounded-xl text-2xl font-bold"
              style={{ backgroundColor: g.hex, color: gradeTextColour(g.grade) }}
              aria-label={`Grade ${g.grade}`}
            >
              {g.grade}
            </span>
            <div className="min-w-0">
              <div className="text-xs uppercase tracking-wide text-muted-foreground">GEMCLOUD colour grade</div>
              <div className="text-lg font-semibold">
                Grade {g.grade} - {g.name}
              </div>
              <div className="text-sm text-muted-foreground">{g.trade}</div>
            </div>
          </div>
          <p className="mt-3 text-sm leading-relaxed">{g.description}</p>
          {reviewed != null && (
            <p className="mt-3 flex items-center gap-2 rounded-lg bg-secondary px-3 py-2 text-sm font-medium text-secondary-foreground">
              <UserCheck className="size-4 shrink-0" aria-hidden /> Reviewed by gemologist: Grade {reviewed}
            </p>
          )}
        </Card>
      )}

      {cert.image_url && (
        <Card className="p-2">
          {/* eslint-disable-next-line @next/next/no-img-element -- presigned link, static export */}
          <img src={cert.image_url} alt="Stone photo" className="mx-auto max-h-80 w-full rounded-lg object-contain" />
        </Card>
      )}

      {s && (
        <Card>
          <h2 className="mb-1 text-sm font-semibold">Colour values</h2>
          {c?.hex && (
            <Row label="Measured colour">
              <span className="inline-flex items-center gap-2 font-mono text-xs">
                <span className="inline-block size-4 rounded border border-border" style={{ backgroundColor: c.hex }} />
                {c.hex}
              </span>
            </Row>
          )}
          <Row label="CIELAB (L*, a*, b*)" mono>
            {n(c?.L)}, {n(c?.a)}, {n(c?.b)}
          </Row>
          <Row label="Chroma C*" mono>
            {n(c?.C)}
          </Row>
          <Row label="Hue" mono>
            {c?.H == null ? "-" : `${n(c.H)}°`}
          </Row>
          <Row label="Saturation / Brightness" mono>
            {n(c?.S)} / {n(c?.B)}
          </Row>
          {s.delta_e00_to_typical != null && (
            <Row label="ΔE₀₀ to typical grade colour" mono>
              {n(s.delta_e00_to_typical, 2)}
            </Row>
          )}
          {s.confidence != null && (
            <Row label="Confidence" mono>
              {(s.confidence * 100).toFixed(1)}%
            </Row>
          )}
          <Row label="Model version" mono>
            {s.model_version || "-"}
          </Row>
          {c?.approximate && (
            <p className="mt-2 text-xs text-muted-foreground">Colour values are approximate (uncertain stone outline).</p>
          )}
        </Card>
      )}

      {cert.pdf_url && cert.pdf_sha256 && <PdfCheck url={cert.pdf_url} sha256={cert.pdf_sha256} certNo={cert.cert_no} />}
    </>
  );
}

type Check = { kind: "idle" } | { kind: "busy" } | { kind: "pick" } | { kind: "done"; match: boolean; actual: string };

function PdfCheck({ url, sha256, certNo }: { url: string; sha256: string; certNo: string }) {
  const [check, setCheck] = useState<Check>({ kind: "idle" });
  const fileRef = useRef<HTMLInputElement>(null);

  const run = async (data: ArrayBuffer) => setCheck({ kind: "done", ...(await checkPdf(data, sha256)) });

  // Downloads the PDF and hashes it here; if the storage link refuses a browser read
  // (CORS), the user picks the downloaded file instead.
  const checkLink = async () => {
    setCheck({ kind: "busy" });
    try {
      const res = await fetch(url, { credentials: "omit", cache: "no-store" });
      if (!res.ok) throw new Error(String(res.status));
      await run(await res.arrayBuffer());
    } catch {
      setCheck({ kind: "pick" });
    }
  };

  const checkFile = async (f: File | undefined) => {
    if (!f) return;
    setCheck({ kind: "busy" });
    try {
      await run(await f.arrayBuffer());
    } catch {
      setCheck({ kind: "pick" });
    }
  };

  return (
    <Card>
      <h2 className="mb-2 flex items-center gap-2 text-sm font-semibold">
        <ShieldCheck className="size-4 text-primary" aria-hidden /> Certificate PDF
      </h2>
      <div className="flex flex-wrap gap-2">
        <a
          href={url}
          download={`${certNo}.pdf`}
          className="inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground"
        >
          <Download className="size-4" aria-hidden /> Download PDF
        </a>
        <button
          type="button"
          onClick={() => void checkLink()}
          disabled={check.kind === "busy"}
          className="inline-flex h-10 items-center gap-2 rounded-lg border border-border px-4 text-sm font-medium disabled:opacity-60"
        >
          {check.kind === "busy" ? <Loader2 className="size-4 animate-spin" aria-hidden /> : <FileCheck2 className="size-4" aria-hidden />}
          Check file
        </button>
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          className="inline-flex h-10 items-center rounded-lg px-2 text-sm text-primary underline-offset-2 hover:underline"
        >
          Check a downloaded file
        </button>
        <input
          ref={fileRef}
          type="file"
          accept="application/pdf,.pdf"
          className="hidden"
          onChange={(e) => void checkFile(e.target.files?.[0])}
        />
      </div>
      <div className="mt-3 text-xs text-muted-foreground">SHA-256 fingerprint</div>
      <div className="break-all font-mono text-xs">{sha256}</div>
      {check.kind === "pick" && (
        <p className="mt-3 text-sm text-muted-foreground">
          The file could not be read automatically. Download the PDF, then tap &quot;Check a downloaded file&quot; and
          choose it.
        </p>
      )}
      {check.kind === "done" &&
        (check.match ? (
          <p className="mt-3 flex items-center gap-2 rounded-lg bg-success/10 px-3 py-2 text-sm font-medium text-success">
            <CheckCircle2 className="size-4 shrink-0" aria-hidden /> The file matches this certificate.
          </p>
        ) : (
          <div className="mt-3 rounded-lg bg-destructive/10 px-3 py-2 text-sm text-destructive">
            <p className="flex items-center gap-2 font-medium">
              <Ban className="size-4 shrink-0" aria-hidden /> The file does not match. It may have been edited.
            </p>
            <p className="mt-1 break-all font-mono text-xs">{check.actual}</p>
          </div>
        ))}
    </Card>
  );
}
