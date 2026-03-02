# neoxp_haibao

This directory is the migration workspace for turning the Fiji macro workflow into a standalone desktop product.

## Goal

Build a non-linear desktop workflow (Electron front-end) while preserving scientific output consistency for phagocytosis analysis.

## Recommended Strategy

1. Keep a compatibility baseline (Fiji headless adapter) for parity checks.
2. Build a native primary engine step-by-step.
3. Replace Fiji-dependent compute modules only after metric-level regression passes.

## Why This Strategy

The current macro logic is deterministic but deeply tied to ImageJ command behavior. Directly replacing all image algorithms in one shot is high-risk and likely to drift from existing results.

## Current Scope in This Folder

1. `docs/`:
   - Fiji algorithm audit
   - migration architecture and sequencing
2. `packages/contracts`:
   - shared model definitions (error codes, phase keys, param-spec keys)
3. `packages/parser`:
   - filename/time parsing behavior aligned with macro presets
4. `packages/workflow`:
   - phase model and non-linear state machine baseline
5. `apps/desktop`:
   - runnable Electron + React shell
   - phase navigation and filename preset parser smoke check

## Next Build Targets

1. `packages/engine-adapter-fiji`: run existing pipeline in headless mode with structured output.
2. `packages/engine-native`: native implementations of thresholding/morphology/particle counting.
3. Extend `apps/desktop` with persisted project state, parameter editing, and batch execution views.
