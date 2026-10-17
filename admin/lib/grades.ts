// GEMCLOUD colour grades (same values as the app: assets/data/colour_grades.json).
export const GRADES = [
  { grade: 1, name: "Dark", trade: "Midnight Blue", hex: "#020519",
    description: "Very dark blue that can read almost black in low light. Colour is visible mainly at the edges and in strong daylight." },
  { grade: 2, name: "Deep", trade: "Twilight Blue", hex: "#0B0F3F",
    description: "Deep, dense blue with a slightly inky look. Saturated colour, but the dark tone limits brilliance." },
  { grade: 3, name: "Vivid", trade: "Royal Blue", hex: "#091A72",
    description: "Rich, strongly saturated blue with a medium-dark tone. The most sought-after balance of depth and brightness." },
  { grade: 4, name: "Intense", trade: "Intense Cornflower", hex: "#2A408C",
    description: "Bright, saturated blue with a medium tone. Lively colour with good light return." },
  { grade: 5, name: "Medium Intense", trade: "Cornflower Blue", hex: "#47619E",
    description: "Soft, velvety blue with a medium-light tone. Colour is pleasant but less saturated." },
  { grade: 6, name: "Light", trade: "Pastel Blue", hex: "#718BB7",
    description: "Light blue with a gentle, pastel look. Tone dominates over saturation." },
  { grade: 7, name: "Very Light", trade: "Very Light Blue", hex: "#ABBDD6",
    description: "Very pale blue, close to colourless in some lighting. Colour is faint and best seen face-up." },
] as const;

export function gradeInfo(grade: number | null | undefined) {
  return GRADES.find((g) => g.grade === grade);
}

/** Grades 1-5 are dark enough for white text. */
export function gradeTextColour(grade: number): string {
  return grade <= 5 ? "#FFFFFF" : "#0F172A";
}
