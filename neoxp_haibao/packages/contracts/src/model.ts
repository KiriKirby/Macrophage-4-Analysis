import type { PhaseKey } from "./phases.js";
import type { ParamSpecRecord } from "./param-spec.js";

export type ModeKey = "M1" | "M2" | "M3" | "M4";

export type FilePreset = "WINDOWS" | "DOLPHIN" | "MACOS";

export interface FeatureFlags {
  feature1: boolean;
  feature2: boolean;
  feature3: boolean;
  feature4: boolean;
  feature5: boolean;
  feature6: boolean;
}

export interface ProjectConfig {
  mode: ModeKey;
  hasFluo: boolean;
  autoRoiMode: boolean;
  subfolderKeep: boolean;
  fluoPrefix: string;
  filePreset: FilePreset;
  paramSpec: ParamSpecRecord;
  features: FeatureFlags;
}

export interface ProjectCheckpoint {
  phase: PhaseKey;
  timestampMs: number;
  configSnapshot: ProjectConfig;
}

export interface ImageMetrics {
  image: string;
  pn: string;
  f: string;
  t: string;
  tb: number | "";
  bic: number | "";
  cwb: number | "";
  tc: number | "";
  tpc: number | "";
  etpc: number | "";
  tpcsem: number | "";
}

