# Macrophage Image Four-Factor Analysis (v4.0.0)
Languages: [English](README.md) | [中文](README.zh-CN.md) | [日本語](README.ja.md)

> AI Edit Notice
> This README is maintained with AI-assisted edits. Verify parameters and outputs in your own lab environment before production use.

> Haibao Desktop Project
> The desktop/UI planning and implementation repository has been split into a standalone project: [KiriKirby/neoxp-haibao](https://github.com/KiriKirby/neoxp-haibao).
> If you are looking for the Electron-based Haibao application, use that repository instead of this Fiji macro repository.

> Haibao Baseline Sync
> This repository is the source of truth for Fiji macro behavior. The Haibao repository copies the latest root-level Macrophage Image Four-Factor Analysis_X.Y.Z.ijm file, excluding 3.0.2, by running npm run sync:fiji-ref inside neoxp-haibao.
> After changing the active Fiji macro version here, refresh the copied baseline in the Haibao repository before behavior-sensitive desktop work.

Fiji-only ImageJ macro for macrophage phagocytosis analysis with interactive ROI annotation, target/exclusion sampling, feature-based detection, optional fluorescence quantification, and structured tabular output.

## 1. What This Project Is
- Primary script: `Macrophage Image Four-Factor Analysis_4.0.0.ijm`
- Permanent historical reference (do not edit): `Macrophage Image Four-Factor Analysis_3.0.2.ijm`
- Legacy snapshots: `old/`
- Feature reference image: `sample.png`
- Runtime: Fiji (required). The macro is designed for Fiji behavior and is not intended for plain ImageJ runtime compatibility.

## 2. Core Capabilities
- Guided multi-phase interactive workflow (language, mode, sampling, parameter validation, batch output)
- Cell ROI annotation flow with ROI zip save/load checks and label-mask acceleration
- Feature-based target detection (F1-F6) with mutual-exclusion constraints and in-cell clump handling
- Optional exclusion filtering (learned threshold direction + optional size gate)
- Optional fluorescence analysis with color sampling and per-cell/per-group output integration
- Preset-based PN/F filename parsing and optional time parsing (`<number>hr`)
- Deterministic side-by-side results layout by PN (and by time blocks when enabled)
- PARAM_SPEC import/export for reproducible parameter replay
- Structured error code system (`[E###]`) and tree-style logs

## 3. Quick Start (Recommended)
1. Install and open Fiji.
2. Drag `Macrophage Image Four-Factor Analysis_4.0.0.ijm` into Fiji.
3. In Macro Editor, click `Run`.
4. Follow dialogs phase by phase.
5. Review `Results` and logs; rerun with adjusted parameters if needed.

## 4. Workflow Overview (15 Phases)
1. UI language
2. UI text initialization
3. Mode selection
4. Folder scan and image list build
5. ROI annotation (or ROI-only path)
6. Auto cell-area sampling (AUTO_ROI mode)
7. Target sampling
8. Exclusion sampling
9. Parameter estimation
10. Parameter dialog
11. Parameter validation
12. Data format rule setup
13. Batch loop
14. Results output
15. Finish dialog

## 5. Detection Model (High-Level)
### 5.1 Target Features
- F1/F2/F5/F6: round-object classes with intensity-contrast logic
- F3/F4: clump classes (F4 in-cell only)
- Constraint: F1 and F5 are mutually exclusive

### 5.2 Candidate Generation
- Round-path fusion strategy (threshold-based path + edge-based path)
- Clump masks for dark/in-cell clumps depending on selected features
- Merge/de-duplication rules to avoid over-counting

### 5.3 Exclusion as Post-Detection Filter
- Exclusion removes candidates already detected by target logic based on learned likeness
- It does not expand target detections; it only filters post-detection candidates

## 6. Metrics and Output Tokens
Main count metrics:
- `TB`: total target quantity
- `BIC`: target quantity in cells
- `CWB`: cells with target
- `TC`: total cells

Derived/common metrics:
- `TPC` (target per cell)
- `ETPC` (group mean of per-cell target)
- `TPCSEM` (standard error for per-cell target)

Fluorescence-related columns are attached only to relevant base tokens (for example TB/BIC/TPC/ETPC/TPCSEM families), with labels prefixed by configured fluorescence prefix.

## 7. Fluorescence Analysis
- Optional fluorescence image matching by prefix
- Target/near/exclusion color sampling in RGB with tolerance controls
- Missing fluorescence images produce empty fluorescence cells (not forced zeros)
- Fluorescence values are integrated into the same PN/time table layout logic

## 8. Filename and Time Parsing Rules
Preset-only filename parsing (custom free-form rules are not supported):
- Windows preset: `name (1)`
- Dolphin preset: `name1`
- macOS preset: `name 1`

Time extraction:
- Supported pattern: literal `<number>hr`
- With `SUBFOLDER_KEEP_MODE` ON: parse from subfolder name
- With `SUBFOLDER_KEEP_MODE` OFF: parse from filename
- Failed time parse under time-enabled path falls back to `time=0`

## 9. Results Layout Rules
When time parsing is enabled:
- Rows are grouped by ascending numeric time
- Within each time block, each PN occupies its own logical table segment
- Block height equals max PN row count for that time
- Shorter PN segments are padded with empty strings

When time parsing is disabled:
- PN logical tables are placed side-by-side
- Total row count equals max PN length
- Shorter PN segments are padded with empty strings

Per-cell expansion:
- Activated by requesting per-cell metrics in output format
- Exception: AUTO_ROI mode keeps summary behavior for TPC/ETPC/TPCSEM

## 10. PARAM_SPEC Reproducibility
- Export line format: `PARAM_SPEC=key=value;...`
- Fixed key order is deterministic
- Unsupported/disabled keys are emitted as empty values, not removed
- Empty value means “do not override”; numeric `0` is a valid explicit override
- Parse supports both raw key-value list and prefixed `PARAM_SPEC=` string

## 11. Error Handling and Logging
- User-facing failures are coded with stable `[E###]` identifiers
- Logs use a structured tree style (`OK`, `WARN`, `X`, nested `|-` branches)
- Validation errors in dialogs are designed to be recoverable when possible

## 12. Repository Structure (Important)
- `Macrophage Image Four-Factor Analysis_4.0.0.ijm`: active macro
- `Macrophage Image Four-Factor Analysis_3.0.2.ijm`: locked reference version
- `old/`: archived old macro versions (reference only)

## 13. Desktop Project
The Electron desktop/softwareization project now lives in a separate repository:

- `https://github.com/KiriKirby/neoxp-haibao`

## 14. Reproducibility Checklist
Before comparing experiment runs:
1. Use the same Fiji version and plugin environment.
2. Use the same mode and feature selections.
3. Reuse identical `PARAM_SPEC` when possible.
4. Keep ROI suffix and folder mode consistent.
5. Confirm whether time parsing is enabled and from where (filename vs subfolder).
6. Confirm fluorescence prefix and color tolerance settings.

## 15. License
This macro script is released under CC0 1.0 Universal (Public Domain Dedication). See `LICENSE`.

This repository also contains third-party software and fonts under their own licenses. See `THIRD_PARTY_NOTICES.md`.