import { PHASES, type PhaseKey } from "@neoxp/contracts";

const NEXT_PHASE: Record<PhaseKey, PhaseKey | null> = {
  phase1_language: "phase2_i18n_texts",
  phase2_i18n_texts: "phase3_mode_select",
  phase3_mode_select: "phase4_folder_and_scan",
  phase4_folder_and_scan: "phase5_roi_annotation",
  phase5_roi_annotation: "phase6_auto_cell_sampling",
  phase6_auto_cell_sampling: "phase7_target_sampling",
  phase7_target_sampling: "phase8_exclusion_sampling",
  phase8_exclusion_sampling: "phase9_parameter_estimation",
  phase9_parameter_estimation: "phase10_parameter_dialog",
  phase10_parameter_dialog: "phase11_parameter_normalization",
  phase11_parameter_normalization: "phase12_data_format",
  phase12_data_format: "phase13_batch_analysis",
  phase13_batch_analysis: "phase14_results_output",
  phase14_results_output: "phase15_finish",
  phase15_finish: null
};

export function getNextPhase(phase: PhaseKey): PhaseKey | null {
  return NEXT_PHASE[phase];
}

export function isKnownPhase(phase: string): phase is PhaseKey {
  return (PHASES as readonly string[]).includes(phase);
}

