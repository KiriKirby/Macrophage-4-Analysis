export const PHASES = [
  "phase1_language",
  "phase2_i18n_texts",
  "phase3_mode_select",
  "phase4_folder_and_scan",
  "phase5_roi_annotation",
  "phase6_auto_cell_sampling",
  "phase7_target_sampling",
  "phase8_exclusion_sampling",
  "phase9_parameter_estimation",
  "phase10_parameter_dialog",
  "phase11_parameter_normalization",
  "phase12_data_format",
  "phase13_batch_analysis",
  "phase14_results_output",
  "phase15_finish"
] as const;

export type PhaseKey = typeof PHASES[number];

export type PhaseStatus = "todo" | "active" | "done" | "blocked";

export interface PhaseState {
  key: PhaseKey;
  status: PhaseStatus;
}

