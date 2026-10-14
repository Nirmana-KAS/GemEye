// GEMCLOUD colour grades (same values as the app: assets/data/colour_grades.json).
export const GRADES = [
  { grade: 1, name: "Dark", trade: "Midnight Blue", hex: "#020519" },
  { grade: 2, name: "Deep", trade: "Twilight Blue", hex: "#0B0F3F" },
  { grade: 3, name: "Vivid", trade: "Royal Blue", hex: "#091A72" },
  { grade: 4, name: "Intense", trade: "Intense Cornflower", hex: "#2A408C" },
  { grade: 5, name: "Medium Intense", trade: "Cornflower Blue", hex: "#47619E" },
  { grade: 6, name: "Light", trade: "Pastel Blue", hex: "#718BB7" },
  { grade: 7, name: "Very Light", trade: "Very Light Blue", hex: "#ABBDD6" },
] as const;

export function gradeInfo(grade: number | null | undefined) {
  return GRADES.find((g) => g.grade === grade);
}

/** Grades 1-5 are dark enough for white text. */
export function gradeTextColour(grade: number): string {
  return grade <= 5 ? "#FFFFFF" : "#0F172A";
}
