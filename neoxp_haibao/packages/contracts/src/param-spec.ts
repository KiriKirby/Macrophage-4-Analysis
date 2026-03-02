export const PARAM_SPEC_KEYS = [
  "minA", "maxA", "circ", "allowClumps",
  "centerDiff", "bgDiff", "smallRatio", "clumpRatio",
  "exclEnable", "exclMode", "exclThr", "exclStrict", "exclSizeGate",
  "exclMinA", "exclMaxA", "minPhago", "pixelCount",
  "autoCellArea", "strict", "roll", "roiSuffix",
  "fluoTarget", "fluoNear", "fluoTol", "fluoExclEnable", "fluoExcl", "fluoExclTol",
  "mode", "hasFluo", "skipLearning", "autoRoiMode", "subfolderKeep", "fluoPrefix",
  "hasMultiBeads",
  "feature1", "feature2", "feature3", "feature4", "feature5", "feature6",
  "dataFormatEnable", "dataFormatPreset", "dataFormatCols",
  "autoNoiseOptimize", "debugMode", "tuneEnable", "tuneRepeat",
  "logVerbose"
] as const;

export type ParamSpecKey = typeof PARAM_SPEC_KEYS[number];

export type ParamSpecRecord = Record<ParamSpecKey, string>;

export function createEmptyParamSpecRecord(): ParamSpecRecord {
  const out = {} as ParamSpecRecord;
  for (const key of PARAM_SPEC_KEYS) {
    out[key] = "";
  }
  return out;
}

