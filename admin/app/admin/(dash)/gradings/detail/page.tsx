"use client";

import { useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";

import { useAuth } from "@/components/auth-provider";
import { GradeChip, YesNo } from "@/components/grade-chip";
import { ColourValuesView, Photo, ProbabilityChart, Row } from "@/components/grading-parts";
import { EmptyState, ErrorState, PageHeader } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fmtDateTime, fmtMs, fmtNum, fmtPct } from "@/lib/format";
import { GRADES, gradeInfo } from "@/lib/grades";
import type { GradeResult, GradingDetail } from "@/lib/types";

const DIAGNOSTIC_GROUPS: { title: string; keys: string[] }[] = [
  { title: "Image size", keys: ["short_side_px", "min_short_side_px"] },
  { title: "Blur", keys: ["blur_variance", "blur_min_variance"] },
  {
    title: "Stone found",
    keys: [
      "gate_stone_area",
      "no_stone_min_area",
      "stone_tray_contrast_de00",
      "no_stone_min_contrast_de00",
      "gate_centre_fallback",
      "stone_area_fraction",
    ],
  },
  { title: "Blue check", keys: ["hue_wb", "hue_gate_min", "hue_gate_max", "hue_in_gate", "chroma_wb", "min_chroma", "hue_gate_skipped"] },
  { title: "Segmentation", keys: ["segmentation_reliable", "model_segmentation_fallback"] },
  { title: "Unusual image (OOD)", keys: ["ood_distance", "ood_warn", "ood_threshold"] },
];

function fmtValue(v: unknown): string {
  if (v == null) return "-";
  if (typeof v === "boolean") return v ? "yes" : "no";
  if (typeof v === "number") return Number.isInteger(v) ? String(v) : v.toFixed(4);
  return String(v);
}

function Diagnostics({ diag }: { diag: NonNullable<GradeResult["diagnostics"]> }) {
  const known = new Set(DIAGNOSTIC_GROUPS.flatMap((g) => g.keys));
  const other = Object.keys(diag).filter((k) => !known.has(k));
  const groups = [...DIAGNOSTIC_GROUPS, ...(other.length ? [{ title: "Other", keys: other }] : [])];
  return (
    <div className="grid gap-x-8 gap-y-4 md:grid-cols-2 xl:grid-cols-3">
      {groups
        .filter((g) => g.keys.some((k) => k in diag))
        .map((g) => (
          <div key={g.title}>
            <div className="mb-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">{g.title}</div>
            {g.keys
              .filter((k) => k in diag)
              .map((k) => (
                <Row key={k} label={k} mono>
                  {fmtValue(diag[k])}
                </Row>
              ))}
          </div>
        ))}
    </div>
  );
}

function ModelParts({ debug }: { debug: GradeResult["debug"] }) {
  const parts = [
    { name: "Random Forest", grade: debug?.rf_grade, probs: debug?.rf_probabilities },
    { name: "CNN (MC Dropout)", grade: debug?.cnn_mc_grade, probs: debug?.cnn_mc_probabilities },
    { name: "CNN (single pass)", grade: debug?.cnn_deterministic_grade, probs: debug?.cnn_deterministic_probabilities },
  ].filter((p) => p.probs?.length);
  if (!parts.length) {
    return (
      <p className="text-sm text-muted-foreground">
        The separate CNN and Random Forest outputs are not stored for app gradings (development debug only). The
        probabilities above are the combined model result.
      </p>
    );
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="text-xs text-muted-foreground">
            <th className="py-1 text-left font-medium">Part</th>
            <th className="py-1 text-left font-medium">Grade</th>
            {GRADES.map((g) => (
              <th key={g.grade} className="py-1 text-right font-medium">
                G{g.grade}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {parts.map((p) => (
            <tr key={p.name} className="border-t">
              <td className="py-1.5">{p.name}</td>
              <td className="py-1.5">
                <GradeChip grade={p.grade} />
              </td>
              {GRADES.map((g, i) => (
                <td key={g.grade} className="py-1.5 text-right font-mono text-xs">
                  {fmtPct(p.probs?.[i], 0)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function GradingDetailView({ id }: { id: string }) {
  const { api, role } = useAuth();
  const isAdmin = role === "admin";
  const detail = useQuery({
    queryKey: ["admin-grading", id],
    queryFn: () => api<GradingDetail>(`/admin/gradings/${encodeURIComponent(id)}`),
    // Photo links expire after 10 minutes.
    staleTime: 5 * 60_000,
  });

  const back = (
    <Link href="/admin/gradings/" className="mb-4 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
      <ArrowLeft className="size-4" /> Gradings
    </Link>
  );

  if (detail.isPending) {
    return (
      <>
        {back}
        <Skeleton className="mb-6 h-10 w-80" />
        <div className="grid gap-4 lg:grid-cols-3">
          <Skeleton className="aspect-square rounded-xl" />
          <Skeleton className="aspect-square rounded-xl" />
          <Skeleton className="aspect-square rounded-xl" />
        </div>
      </>
    );
  }
  if (detail.isError) {
    return (
      <>
        {back}
        <Card>
          <ErrorState error={detail.error} onRetry={() => void detail.refetch()} />
        </Card>
      </>
    );
  }

  const d = detail.data;
  const r: GradeResult = d.result ?? { status: d.status ?? "unknown" };
  const info = gradeInfo(r.grade);
  const colour = r.colour;

  return (
    <>
      {back}
      <PageHeader
        title={d.stone_id ?? d.grading_id}
        description={`Graded ${fmtDateTime(d.created_at)}${d.device ? ` on ${d.device}` : ""}${d.app_version ? ` - app ${d.app_version}` : ""}`}
        actions={
          <>
            <GradeChip grade={r.grade} showName />
            {r.referred && <YesNo value />}
            {d.review ? (
              <Badge variant={d.review.agrees ? "secondary" : "destructive"}>
                {d.review.gemologist_grade == null ? "Reviewed: unusable" : `Reviewed: grade ${d.review.gemologist_grade}`}
              </Badge>
            ) : r.referred ? (
              <Badge variant="outline">Awaiting review</Badge>
            ) : null}
          </>
        }
      />

      <div className="mb-4 grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Photo</CardTitle>
          </CardHeader>
          <CardContent>
            <Photo url={d.image_url} alt="Stone photo" empty="Photo not available" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Grad-CAM</CardTitle>
            <CardDescription>Where the CNN looked (explanation only)</CardDescription>
          </CardHeader>
          <CardContent>
            <Photo url={d.heatmap_url} alt="Grad-CAM heatmap" empty="No heatmap generated" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Result</CardTitle>
          </CardHeader>
          <CardContent>
            <Row label="Grade">{info ? `${info.grade} - ${info.name} (${info.trade})` : (r.grade ?? "-")}</Row>
            <Row label="Confidence">{fmtPct(r.confidence)}</Row>
            <Row label="Uncertainty">{fmtNum(r.uncertainty, 4)}</Row>
            <Row label="Second grade">{r.second_grade ?? "-"}</Row>
            <Row label="Referred">{r.referred == null ? "-" : r.referred ? "Yes" : "No"}</Row>
            <Row label="Referral threshold">{fmtNum(d.referral_threshold_used)}</Row>
            <Row label="Model version">{r.model_version ?? "-"}</Row>
            <Row label="Calibration">{r.calibration_mode ?? "-"}</Row>
            <Row label="Session">{d.calibration_session_id ?? "-"}</Row>
            <Row label="Warnings">{r.warnings?.length ? r.warnings.join(", ") : "none"}</Row>
            <Row label="Time (total)">{fmtMs(r.timings_ms?.total)}</Row>
            {isAdmin && (
              <Row label="User">
                {d.user_email ? (
                  <Link className="text-primary hover:underline dark:text-brand-accent" href={`/admin/users/detail/?uid=${encodeURIComponent(d.uid)}`}>
                    {d.user_email}
                  </Link>
                ) : (
                  "-"
                )}
              </Row>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="mb-4 grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Probabilities</CardTitle>
            <CardDescription>Combined model output per grade</CardDescription>
          </CardHeader>
          <CardContent>
            {r.probabilities?.length ? <ProbabilityChart probs={r.probabilities} /> : <EmptyState title="No probabilities stored" />}
            <div className="mt-4">
              <div className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">Model parts</div>
              <ModelParts debug={r.debug} />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Colour values</CardTitle>
            <CardDescription>{colour?.approximate ? "Approximate: stone outline was uncertain" : "Measured stone colour"}</CardDescription>
          </CardHeader>
          <CardContent>
            {colour ? (
              <ColourValuesView colour={colour} deltaE={r.delta_e00_to_typical} />
            ) : (
              <EmptyState title="No colour values stored" />
            )}
          </CardContent>
        </Card>
      </div>

      <div className="mb-4 grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Certificate</CardTitle>
          </CardHeader>
          <CardContent>
            {d.certificate ? (
              <>
                <Row label="Number" mono>
                  <Link className="text-primary hover:underline dark:text-brand-accent" href={`/admin/certificates/?q=${encodeURIComponent(d.certificate.cert_no)}`}>
                    {d.certificate.cert_no}
                  </Link>
                </Row>
                <Row label="Status">
                  <span className="capitalize">{d.certificate.status}</span>
                </Row>
                <Row label="Issued">{fmtDateTime(d.certificate.issued_at)}</Row>
              </>
            ) : (
              <p className="text-sm text-muted-foreground">No certificate issued for this stone.</p>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Gemologist review</CardTitle>
          </CardHeader>
          <CardContent>
            {d.review ? (
              <>
                <Row label="Gemologist grade">
                  {d.review.gemologist_grade == null ? "Unusable photo" : <GradeChip grade={d.review.gemologist_grade} showName />}
                </Row>
                <Row label="Agrees with model">{d.review.agrees == null ? "-" : d.review.agrees ? "Yes" : "No"}</Row>
                <Row label="Reviewed">{fmtDateTime(d.review.reviewed_at)}</Row>
                <Row label="Notes">{d.review.notes ?? "-"}</Row>
              </>
            ) : (
              <p className="text-sm text-muted-foreground">
                {r.referred ? "Referred, waiting in the review queue." : "Not reviewed (not referred)."}
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Quality gates</CardTitle>
          <CardDescription>Measurements from the gates that this photo passed</CardDescription>
        </CardHeader>
        <CardContent>
          {r.diagnostics && Object.keys(r.diagnostics).length ? (
            <Diagnostics diag={r.diagnostics} />
          ) : (
            <EmptyState title="No gate measurements stored" />
          )}
          {r.timings_ms && (
            <div className="mt-4 flex flex-wrap gap-4 text-xs text-muted-foreground">
              {Object.entries(r.timings_ms).map(([k, v]) => (
                <span key={k}>
                  {k}: <span className="font-mono text-foreground">{fmtMs(v)}</span>
                </span>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </>
  );
}

function GradingDetailPage() {
  const id = useSearchParams().get("id");
  if (!id) return <EmptyState title="No grading selected" />;
  return <GradingDetailView key={id} id={id} />;
}

export default function Page() {
  return (
    <Suspense fallback={<Skeleton className="h-64 rounded-xl" />}>
      <GradingDetailPage />
    </Suspense>
  );
}
