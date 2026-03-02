export const ERROR_CODES = [
  "E001", "E002", "E003", "E004", "E005", "E006", "E007", "E008", "E009", "E010",
  "E011", "E012", "E013", "E020",
  "E101", "E102", "E103", "E104", "E105", "E106", "E107", "E108", "E109", "E110",
  "E111", "E112", "E113", "E114", "E115",
  "E121", "E122", "E123", "E124", "E125", "E126", "E127", "E128", "E129", "E130",
  "E131", "E132", "E133", "E134", "E135",
  "E141", "E142", "E143", "E144", "E145", "E146", "E147", "E148", "E149",
  "E199",
  "E201", "E202", "E203", "E204", "E205", "E206", "E207", "E208"
] as const;

export type ErrorCode = typeof ERROR_CODES[number];

export interface CodedError {
  code: ErrorCode;
  message: string;
  stage?: string;
  file?: string;
}

