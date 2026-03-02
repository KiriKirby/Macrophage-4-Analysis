export interface TimeParseResult {
  tStr: string;
  tNum: number;
  ok: boolean;
  source: "hr" | "fallback-number" | "none";
}

const HR_PATTERN = /(\d+(?:\.\d+)?)\s*hr/i;
const FIRST_NUMBER_PATTERN = /(\d+(?:\.\d+)?)/;

export function parseTimeToken(input: string): TimeParseResult {
  const raw = String(input ?? "");
  const hrMatch = raw.match(HR_PATTERN);
  if (hrMatch) {
    const tStr = hrMatch[1];
    return { tStr, tNum: Number(tStr), ok: true, source: "hr" };
  }

  const first = raw.match(FIRST_NUMBER_PATTERN);
  if (first) {
    const tStr = first[1];
    return { tStr, tNum: Number(tStr), ok: true, source: "fallback-number" };
  }

  return { tStr: "", tNum: 0, ok: false, source: "none" };
}

