"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { ArrowLeft, Loader2, Save, SkipForward } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Controller, useForm, useWatch } from "react-hook-form";
import { toast } from "sonner";

import { useAuth } from "@/components/auth-provider";
import { GradeChip } from "@/components/grade-chip";
import { ColourValuesView, Photo, ProbabilityChart, Row, ZoomPhoto } from "@/components/grading-parts";
import { EmptyState } from "@/components/states";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { ApiError, saveReview } from "@/lib/api";
import { fmtDateTime, fmtNum, fmtPct } from "@/lib/format";
import { GRADES, gradeInfo, gradeTextColour } from "@/lib/grades";
import { gradeFromKey, NOTES_MAX, reasonLabel, reviewDefaults, reviewFormSchema, toReviewBody, type ReviewFormValues } from "@/lib/reviews";
import type { QueueItem, QueueReview } from "@/lib/types";
import { cn } from "@/lib/utils";

const CONFIDENCES = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
] as const;

function Kbd({ children }: { children: React.ReactNode }) {
  return <kbd className="rounded border bg-muted px-1 font-mono text-[10px] text-muted-foreground">{children}</kbd>;
}

function isTyping(target: EventTarget | null): boolean {
  const el = target as HTMLElement | null;
  return !!el && (el.tagName === "TEXTAREA" || el.tagName === "INPUT" || el.tagName === "SELECT" || el.isContentEditable);
}

export function ReviewPanel({
  item,
  hasNext,
  onBack,
  onSaved,
  onNext,
}: {
  item: QueueItem;
  hasNext: boolean;
  onBack: () => void;
  /** The saved review, merged into the item by the parent. */
  onSaved: (review: QueueReview) => void;
  onNext: () => void;
}) {
  const { api, role } = useAuth();
  const isAdmin = role === "admin";
  const existing = item.review;
  const canEdit = !existing || existing.mine || isAdmin;
  const form = useForm<ReviewFormValues>({ resolver: zodResolver(reviewFormSchema), defaultValues: reviewDefaults(existing) });
  const [saving, setSaving] = useState(false);
  const goNextAfterSave = useRef(false);
  const unusable = useWatch({ control: form.control, name: "unusable" });
  const grade = useWatch({ control: form.control, name: "gemologist_grade" });
  const notes = useWatch({ control: form.control, name: "notes" });

  async function submit(values: ReviewFormValues) {
    setSaving(true);
    try {
      const body = toReviewBody(values);
      const saved = await saveReview(api, item.grading_id, body, !!existing);
      onSaved({
        ...body,
        agrees: saved.agrees,
        reviewed_at: new Date().toISOString(),
        mine: existing ? existing.mine : true,
      });
      toast.success(existing ? "Review updated." : "Review saved.");
      if (goNextAfterSave.current) onNext();
      else form.reset(values);
    } catch (e) {
      // The API client already showed the error; a conflict means someone else reviewed it.
      if (e instanceof ApiError && e.code === "already_reviewed") onBack();
    } finally {
      setSaving(false);
      goNextAfterSave.current = false;
    }
  }

  const save = (next: boolean) => {
    if (!canEdit || saving) return;
    goNextAfterSave.current = next;
    void form.handleSubmit(submit)();
  };
  const saveRef = useRef(save);
  useEffect(() => {
    saveRef.current = save;
  });

  // Keys 1-7 pick the grade; Enter saves (Ctrl/Cmd+Enter also from the notes box).
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.altKey || e.repeat) return;
      const typing = isTyping(e.target);
      if (e.key === "Enter") {
        if ((typing && !(e.ctrlKey || e.metaKey)) || (e.target as HTMLElement | null)?.tagName === "BUTTON") return;
        e.preventDefault();
        saveRef.current(false);
        return;
      }
      if (typing || e.ctrlKey || e.metaKey || !canEdit) return;
      const g = gradeFromKey(e.key);
      if (g != null && !form.getValues("unusable")) {
        e.preventDefault();
        form.setValue("gemologist_grade", g, { shouldDirty: true, shouldValidate: true });
      }
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [canEdit, form]);

  const info = gradeInfo(item.grade);
  const gradeError = form.formState.errors.gemologist_grade?.message;
  const notesError = form.formState.errors.notes?.message;

  return (
    <>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <Button variant="ghost" size="sm" onClick={onBack}>
          <ArrowLeft /> Review queue
        </Button>
        <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
          <span>{item.stone_id ?? item.grading_id}</span>
          <span>-</span>
          <span>{fmtDateTime(item.created_at)}</span>
          {item.device && <span>- {item.device}</span>}
          {item.model_version && <Badge variant="outline">{item.model_version}</Badge>}
        </div>
      </div>

      <div className="grid gap-4 xl:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)]">
        <div className="grid gap-4">
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Photo</CardTitle>
                <CardDescription>Click to zoom at a point</CardDescription>
              </CardHeader>
              <CardContent>
                <ZoomPhoto url={item.image_url} alt="Stone photo" empty="Photo not available" />
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Grad-CAM</CardTitle>
                <CardDescription>Where the CNN looked (explanation only)</CardDescription>
              </CardHeader>
              <CardContent>
                <Photo url={item.heatmap_url} alt="Grad-CAM heatmap" empty="No heatmap generated" />
              </CardContent>
            </Card>
          </div>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Model result</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-6 md:grid-cols-2">
              <div>
                <Row label="Model grade">{info ? <GradeChip grade={item.grade} showName /> : "-"}</Row>
                <Row label="Confidence">{fmtPct(item.confidence)}</Row>
                <Row label="Uncertainty">{fmtNum(item.uncertainty, 4)}</Row>
                <Row label="Second grade">{item.second_grade ? <GradeChip grade={item.second_grade} /> : "-"}</Row>
                <Row label="Referral threshold">{fmtNum(item.referral_threshold_used)}</Row>
                <Row label="Referred because">{item.referred_reasons.map(reasonLabel).join(", ") || "-"}</Row>
                <Row label="Calibration">{item.calibration_mode ?? "-"}</Row>
              </div>
              <div>
                {item.probabilities?.length ? (
                  <ProbabilityChart probs={item.probabilities} height={200} />
                ) : (
                  <EmptyState title="No probabilities stored" />
                )}
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Colour values</CardTitle>
              <CardDescription>{item.colour?.approximate ? "Approximate: stone outline was uncertain" : "Measured stone colour"}</CardDescription>
            </CardHeader>
            <CardContent>
              {item.colour ? (
                <ColourValuesView colour={item.colour} deltaE={item.delta_e00_to_typical} />
              ) : (
                <EmptyState title="No colour values stored" />
              )}
            </CardContent>
          </Card>
        </div>

        <Card className="h-fit xl:sticky xl:top-20">
          <CardHeader>
            <CardTitle className="text-base">{existing ? "Gemologist review" : "Your review"}</CardTitle>
            <CardDescription>
              {existing
                ? `Reviewed ${fmtDateTime(existing.reviewed_at)}${existing.mine ? " by you" : ""}`
                : "Enter the true grade after examining the stone."}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form
              className="grid gap-5"
              onSubmit={(e) => {
                e.preventDefault();
                save(false);
              }}
            >
              <fieldset disabled={!canEdit || saving} className="grid gap-5">
                <div>
                  <div className="mb-2 flex items-center justify-between text-sm font-medium">
                    True grade
                    <span className="text-xs font-normal text-muted-foreground">
                      <Kbd>1</Kbd>-<Kbd>7</Kbd>
                    </span>
                  </div>
                  <div className="grid grid-cols-7 gap-1.5" role="radiogroup" aria-label="True grade">
                    {GRADES.map((g) => {
                      const on = !unusable && grade === g.grade;
                      return (
                        <button
                          key={g.grade}
                          type="button"
                          role="radio"
                          aria-checked={on}
                          disabled={unusable}
                          title={`${g.grade} - ${g.name} (${g.trade})`}
                          onClick={() => form.setValue("gemologist_grade", g.grade, { shouldDirty: true, shouldValidate: true })}
                          className={cn(
                            "flex h-12 flex-col items-center justify-center rounded-lg border-2 text-sm font-semibold transition-all disabled:cursor-not-allowed disabled:opacity-30",
                            on ? "border-primary ring-3 ring-primary/30" : "border-transparent hover:scale-105",
                          )}
                          style={{ backgroundColor: g.hex, color: gradeTextColour(g.grade) }}
                        >
                          {g.grade}
                        </button>
                      );
                    })}
                  </div>
                  <p className="mt-1.5 min-h-4 text-xs text-muted-foreground">
                    {unusable ? "No grade: marked unusable." : grade ? `${gradeInfo(grade)?.name} - ${gradeInfo(grade)?.trade}` : ""}
                  </p>
                  {gradeError && <p className="text-xs text-destructive">{gradeError}</p>}
                </div>

                <Controller
                  control={form.control}
                  name="unusable"
                  render={({ field }) => (
                    <label className="flex items-start gap-2.5 text-sm">
                      <Checkbox
                        checked={field.value}
                        onCheckedChange={(checked: boolean) => {
                          field.onChange(checked);
                          if (checked) form.setValue("gemologist_grade", null);
                          void form.trigger("gemologist_grade");
                        }}
                        className="mt-0.5"
                      />
                      <span>
                        Not a blue sapphire / unusable photo
                        <span className="block text-xs text-muted-foreground">Left out of agreement statistics; exported with no grade.</span>
                      </span>
                    </label>
                  )}
                />

                <Controller
                  control={form.control}
                  name="reviewer_confidence"
                  render={({ field }) => (
                    <div>
                      <div className="mb-2 text-sm font-medium">Your confidence</div>
                      <div className="inline-flex rounded-lg border bg-card p-0.5">
                        {CONFIDENCES.map((c) => (
                          <button
                            key={c.value}
                            type="button"
                            aria-pressed={field.value === c.value}
                            onClick={() => field.onChange(field.value === c.value ? null : c.value)}
                            className={cn(
                              "rounded-md px-3 py-1 text-sm transition-colors",
                              field.value === c.value ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground",
                            )}
                          >
                            {c.label}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                />

                <div>
                  <label htmlFor="review-notes" className="mb-2 flex items-center justify-between text-sm font-medium">
                    Notes
                    <span className={cn("text-xs font-normal", notes.length > NOTES_MAX ? "text-destructive" : "text-muted-foreground")}>
                      {notes.length}/{NOTES_MAX}
                    </span>
                  </label>
                  <textarea
                    id="review-notes"
                    rows={4}
                    {...form.register("notes")}
                    placeholder="Optional: inclusions, lighting, why the grade differs"
                    className="w-full rounded-lg border border-input bg-background px-2.5 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
                  />
                  {notesError && <p className="text-xs text-destructive">{notesError}</p>}
                </div>
              </fieldset>

              {canEdit ? (
                <div className="flex flex-wrap items-center gap-2">
                  <Button type="submit" disabled={saving}>
                    {saving ? <Loader2 className="animate-spin" /> : <Save />} {existing ? "Save changes" : "Save"}
                  </Button>
                  {hasNext && (
                    <Button type="button" variant="outline" disabled={saving} onClick={() => save(true)}>
                      <SkipForward /> Save and next
                    </Button>
                  )}
                  <span className="text-xs text-muted-foreground">
                    <Kbd>Enter</Kbd> saves
                  </span>
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">Reviewed by another gemologist. Only an admin can change it.</p>
              )}
              {hasNext && (
                <Button type="button" variant="ghost" size="sm" className="justify-self-start" onClick={onNext} disabled={saving}>
                  Skip to next
                </Button>
              )}
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}
