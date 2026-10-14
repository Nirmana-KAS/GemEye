import { gradeInfo, gradeTextColour } from "@/lib/grades";

export function GradeChip({ grade, showName = false }: { grade: number | null | undefined; showName?: boolean }) {
  const g = gradeInfo(grade);
  if (!g) return <span className="text-muted-foreground">-</span>;
  return (
    <span className="inline-flex items-center gap-2">
      <span
        className="inline-flex h-6 min-w-6 items-center justify-center rounded-md px-1.5 text-xs font-semibold"
        style={{ backgroundColor: g.hex, color: gradeTextColour(g.grade) }}
        title={`${g.name} - ${g.trade}`}
      >
        {g.grade}
      </span>
      {showName && <span className="text-sm">{g.name}</span>}
    </span>
  );
}

export function YesNo({ value }: { value: boolean | null | undefined }) {
  if (value == null) return <span className="text-muted-foreground">-</span>;
  return value ? (
    <span className="rounded-md bg-warning/15 px-1.5 py-0.5 text-xs font-medium text-warning">Referred</span>
  ) : (
    <span className="text-xs text-muted-foreground">No</span>
  );
}
