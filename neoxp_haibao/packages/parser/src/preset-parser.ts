import type { FilePreset } from "@neoxp/contracts";

export interface ParseResult {
  pn: string;
  fStr: string;
  fNum: number;
  ok: boolean;
  detail: string;
}

export function normalizeRuleMatchString(input: string): string {
  let out = "";
  let prevSpace = false;

  for (const raw of input) {
    let ch = raw;
    if (ch === "\u3000" || ch === "\t") ch = " ";
    else if (ch === "\uFF08") ch = "(";
    else if (ch === "\uFF09") ch = ")";

    if (ch === " ") {
      if (prevSpace) continue;
      prevSpace = true;
      out += ch;
      continue;
    }

    prevSpace = false;
    out += ch;
  }
  return out.trim();
}

function extractTrailingDigits(s: string): string {
  let i = s.length - 1;
  while (i >= 0) {
    const c = s.charCodeAt(i);
    if (c < 48 || c > 57) break;
    i -= 1;
  }
  const start = i + 1;
  if (start >= s.length) return "";
  return s.slice(start);
}

export function parsePresetWindowsName(baseName: string): ParseResult {
  const s = normalizeRuleMatchString(baseName);
  if (s.length === 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "empty" };
  }
  if (!s.endsWith(")")) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "not_end_rparen" };
  }

  const idxR = s.lastIndexOf(")");
  const idxL = s.lastIndexOf("(");
  if (idxL < 1 || idxL >= idxR) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "paren_pos" };
  }
  if (s[idxL - 1] !== " ") {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "pre_not_space" };
  }

  const inner = s.slice(idxL + 1, idxR).trim();
  if (!/^\d+$/.test(inner)) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "inner_not_digit" };
  }

  const pn = s.slice(0, idxL).trim();
  return { pn, fStr: inner, fNum: Number(inner), ok: true, detail: "ok" };
}

export function parsePresetDolphinName(baseName: string): ParseResult {
  const s = normalizeRuleMatchString(baseName);
  if (s.length === 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "empty" };
  }

  const fStr = extractTrailingDigits(s);
  if (fStr.length === 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "no_trailing_num" };
  }

  const start = s.length - fStr.length;
  if (start <= 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "pos" };
  }

  const prev = s[start - 1];
  if (prev === " " || prev === "_" || prev === "-" || prev === "(" || prev === ")") {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "has_sep" };
  }

  const pn = s.slice(0, start).trim();
  return { pn, fStr, fNum: Number(fStr), ok: true, detail: "ok" };
}

export function parsePresetMacName(baseName: string): ParseResult {
  const s = normalizeRuleMatchString(baseName);
  if (s.length === 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "empty" };
  }

  const fStr = extractTrailingDigits(s);
  if (fStr.length === 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "no_trailing_num" };
  }

  const start = s.length - fStr.length;
  if (start <= 0) {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "pos" };
  }
  if (s[start - 1] !== " ") {
    return { pn: "", fStr: "", fNum: 0, ok: false, detail: "pre_not_space" };
  }

  const pn = s.slice(0, start).trim();
  return { pn, fStr, fNum: Number(fStr), ok: true, detail: "ok" };
}

export function parseByPreset(baseName: string, preset: FilePreset): ParseResult {
  if (preset === "WINDOWS") return parsePresetWindowsName(baseName);
  if (preset === "DOLPHIN") return parsePresetDolphinName(baseName);
  return parsePresetMacName(baseName);
}
