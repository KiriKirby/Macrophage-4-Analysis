# AGENTS

## Language Requirement
- Use English for all new narrative content in this file (AGENTS.md).
- Quoted strings and code/comment examples may remain in their original language.

These instructions apply to this repository.

## IMPORTANT: Script Module Index (Update Required)
- This repository maintains a module index for `Macrophage Image Four-Factor Analysis_3.0.0.ijm`.
- Every code change that adds/moves/removes logic must update the index line numbers below.
- Keep the index in sync so future AI can locate modules quickly.

## IMPORTANT: Error Code System (Update Required)
- Every user-facing error message must include a stable error code in the format `[E###]` at the start of the message text.
- Error codes must be kept consistent across CN/JP/EN strings for the same failure.
- When an error is shown or causes an exit, log the error with the code (use the structured log style and `T_log_error`).
- Any new failure points introduced by new features or optimizations must add:
  - A new error code and localized CN/JP/EN messages.
  - A log entry that includes the code.
  - A corresponding entry in the Error Code Index below.
- Validation errors inside dialogs should be recoverable (prompt the user to correct input and continue), not hard-exit the script unless the failure is truly fatal.

## Error Code Index (Macrophage Image Four-Factor Analysis_3.0.0.ijm)
- E001: Required window missing (requireWindow).
- E002: Image open failed (openImageSafe).
- E003: Too many cell ROIs (>65535) for label mask.
- E004: ROI[1] invalid bounds (label mask generation).
- E005: Label mask fill check failed (center pixel still 0).
- E006: Selected folder mixes files and subfolders.
- E007: Nested subfolders detected (recursive structure not supported).
- E008: No image files found in the selected folder.
- E009: ROI list empty when attempting to save.
- E010: ROI zip save failed (file not created).
- E011: ROI zip load failed or contains no valid ROI.
- E012: Feature selection conflict (Feature 1 + Feature 5).
- E013: No feature selected.
- E020: Feature reference image unavailable or timed out.
- E101: Filename rule empty.
- E102: Filename rule must contain exactly one slash.
- E103: Filename rule parts missing.
- E104: Filename rule tokens invalid (only <p>/<f> allowed).
- E105: Filename rule must include both <p> and <f>.
- E106: Filename rule order invalid.
- E107: Subfolder-keep mode requires folderRule//fileRule.
- E108: Subfolder rule not allowed in current mode.
- E109: Double slash appears more than once.
- E110: Rule parameters must be key="value".
- E111: Unknown rule parameter prefix.
- E112: Rule parameter value must be in English double quotes.
- E113: Invalid f parameter value (must be "F" or "T").
- E114: Duplicate f parameter in rule spec.
- E121: Column format empty.
- E122: Column format contains empty item.
- E123: Column format contains empty token.
- E124: Column parameters must be comma-separated.
- E125: "$" missing column code.
- E126: "$" used on built-in column.
- E127: Column parameters must be key="value".
- E128: Unknown column parameter prefix.
- E129: Column parameter value must be in English double quotes.
- E130: Unknown column token.
- E131: Column parameter name is empty.
- E132: Column parameter value is empty.
- E133: Duplicate column parameter key.
- E134: Custom column missing name/value parameter.
- E135: Multiple "$" custom columns specified.
- E201: Non-numeric value entered in numeric parameter dialog fields.
- E199: Data formatting validation error fallback (missing code in message).

### Module Index (Macrophage Image Four-Factor Analysis_3.0.0.ijm)
- Header + settings: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1`
- Log + math utilities: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:25`
- File/string/CSV helpers: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:114`
- Token/rule parsing + data-format validation: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:472`
- Grouping/sorting/ratio helpers: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:937`
- Image/window safety helpers: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1232`
- Data-format logging + mottos: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1296`
- ROI annotation helper: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1390`
- Sampling + parameter estimation: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1484`
- Cell label mask: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:1869`
- Bead detection (fusion): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:2275`
- Bead counting + exclusion filter: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:2649`
- Main flow entry: `Macrophage Image Four-Factor Analysis_3.0.0.ijm:2935`
- Phases:
  - Phase 1 (UI language): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:2955`
  - Phase 2 (UI text definitions): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:2964`
  - Phase 3 (mode select): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:4523`
  - Phase 4 (folder + file list): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:4535`
  - Phase 5 (ROI annotation): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:4703`
  - Phase 6 (target sampling): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:4728`
- Phase 7 (exclusion sampling): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5035`
- Phase 8 (parameter estimation): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5221`
- Phase 9 (parameter dialog): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5318`
- Phase 10 (parameter validation): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5455`
- Phase 11 (data format): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5572`
- Phase 12 (batch loop): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5638`
- Phase 13 (results output): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:5930`
- Phase 14 (finish): `Macrophage Image Four-Factor Analysis_3.0.0.ijm:7232`

## Code Style
- Language: ImageJ macro (.ijm). Script is designed for Fiji and should be treated as Fiji-only.
- Prefer explicit loops and arrays over compact expressions; match existing style.
- Use the existing section layout and separators ("// -----" blocks).
- New functions should follow the existing doc block format:
  - "// -----------------------------------------------------------------------------"
  - "// 関数: name" and short Japanese description lines.
- Keep naming consistent: camelCase for functions, lowerCamel for locals, ALL_CAPS for constants and UI labels (T_*).
- Legacy identifiers may include bead/beads; do not rename functions/variables/constants during terminology cleanup—only update user-facing strings (UI/logs/errors/docs).
- Avoid introducing Unicode unless the file already uses it and it is necessary for UI text.
- Favor clear step-by-step control flow over clever tricks; avoid nested ternaries or compact one-liners.
- Use explicit temporaries for intermediate values when it improves readability or mirrors existing patterns.
- Keep ImageJ macro limitations in mind (no advanced data structures, no regex).
- Maintain existing error handling style: build message strings with replaceSafe and exit/showMessage.
- Keep numeric thresholds and default values grouped with related phase blocks or UI sections.
- Keep the top-of-file header block with the existing fields (概要/目的/想定/署名/版数) and the same separator style.
- Prefer parameter grouping for function interfaces: bundle related values into arrays (e.g., targetParams, imgParams, featureFlags) and unpack inside the function to avoid argument-count limits and keep call sites stable.

## Code Layout / Formatting
- Indentation uses 4 spaces; do not use tabs.
- Brace style is K&R: opening brace on the same line, closing brace aligned with the block start.
- Keep one statement per line; avoid chained assignments.
- Prefer single-line function signatures when they fit; if wrapping is needed, align parameters and place one parameter per line.
- Use the standard phase banner format:
  - "// -----------------------------------------------------------------------------"
  - "// フェーズX: ..."
  - "// -----------------------------------------------------------------------------"
- Use the standard major header format with "// =============================================================================" above and below the title line.
- Keep one blank line between function blocks; within long functions, separate logical blocks with a short Japanese comment header and a blank line.
- For long run()/Dialog calls, break lines after commas/concats and align continued lines; close the call on its own line.
- Multi-line strings should be built with `+` on each new line, aligned with the first line, and end with an explicit `\n` where needed.

## Logging Style
- Logging is structured and tree-like using `T_log_*` labels; do not inline raw log strings in logic.
- Preserve the separator line format (e.g., "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━") and use it at phase boundaries.
- Use a consistent prefix scheme:
  - Phase start/end: "✓ ..."
  - Per-image entries: "  ├─ ..." and nested details with "  │  ├─"/"  │  └─"
  - Skips/errors: "  │  ✗ ..." or "  │  ⚠ ..."
- Keep log density similar to the current/old script: phase-level summaries plus per-image key stats; avoid adding verbose per-ROI logs unless explicitly requested.
- Log parameter summaries with labeled placeholders (e.g., `%mode`, `%thr`, `%min-%max`) using `replaceSafe`.

## UI Text / Localization Style
- UI text is instructional and professional; avoid casual tone or slang in any language.
- Terminology: use 目标物/対象物/target object in user-facing strings; do not rename identifiers, tokens, functions, or variables during terminology updates.
- Feature selection dialog text must state: feature 4 is in-cell only, feature 1 & 5 are mutually exclusive, and selected features control which feature-threshold parameters appear.
- Use consistent structure in multi-line dialogs:
  - Short title, then sections like "目的/操作要求/操作步骤/说明" (CN), "目的/手順/説明" (JP), "Purpose/Steps/Notes" (EN).
  - Use numbered steps with `1）` (CN/JP) and `1)` (EN); use bullet points with `•`.
- Keep language parity: CN/JP/EN versions should convey the same intent and detail level, with terminology matched (beads, ROI, sampling, exclusion, parameters).
- Preserve punctuation conventions from the old script:
  - CN/JP text uses full-width punctuation and quoted keys like “OK”/“T”.
  - EN uses ASCII punctuation and quoted keys like "OK"/"T".
- Keep messages concise but complete; avoid long single paragraphs—prefer short blocks with clear line breaks.
- UI strings are grouped by language blocks (CN/JP/EN). When adding new UI text, add it to all three blocks.
- Use existing label keys (T_*) where possible; do not hardcode UI text in logic.
- Keep dialog order and grouping consistent with existing sections (target/bg/roi/excl/format).
- When adding options, also add matching log labels and error strings if referenced in logic.

## Behavior
- Default behaviors should match the current script (e.g., dataOptimizeEnable defaults on unless explicitly exposed in UI).
- Do not change logging verbosity or batch mode unless requested.
- Preserve backward compatibility for existing column tokens and data format rules.
- Keep sampling flow and user prompts in the current sequence unless explicitly requested.
- Target sampling treats non-round or large ROIs as clump samples; when cell ROI data is available, in-cell samples inform Feature 4 clump defaults.
- Preserve ROI suffix behavior and default values unless explicitly asked to change them.
- Preserve algorithmic outputs unless explicitly requested; even “refactors” must keep counts, thresholds, grouping, and sorting identical.
- Avoid changing Results table ordering, grouping, or row counts; keep side-by-side PN layout and time grouping rules intact.
- Exclusion definition: exclusion is a post-detection filter that removes candidates already detected by the target algorithm based on learned exclusion samples (similarity/likeness); it must not replace or expand target detection.

## Output/Results
- Keep result columns and tokens stable unless explicitly asked to change them.
- If you add a new output column, also update validation and token parsing lists.
- When modifying formatting rules, update both parsing and sorting logic (rule validation, token mapping, output construction).
- Results table layout requirement (side-by-side by project/PN):
  - Each PN is its own logical table; tables are placed left-to-right in a single Results sheet.
  - Total row count equals the longest PN table; shorter PN tables leave trailing empty rows (no compression/interleaving).
  - This rule applies whether or not per-cell output is enabled.
  - When time parsing is enabled (hasTimeRule): output is grouped by time in ascending numeric order; within each time block, row count equals the maximum PN length for that time; shorter PN blocks leave empty rows until the time block ends; then continue to the next time.
  - If a PN has no data at a time block, its entire block for that time is empty.
  - Per-time summary columns (EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP) are computed across all images within the same PN and time, not per single image.
  - When no time rule is active, summary columns are computed across all images within the same PN.
  - Per-cell expansion mode is active when any of BPC/EBPC/BPCSDP appears in dataFormatCols; only per-cell columns vary per row, other columns repeat as needed.
  - If per-cell mode is active, per-time summaries (EBPC/BPCSDP) still aggregate across all cells in the PN+time block.
  - "Time parsing enabled" means the filename/folder rule maps <f> to T (f="T") in either file rule or folder rule; time is extracted from subfolder names only when SUBFOLDER_KEEP_MODE is on and a folder rule is provided.
  - If SUBFOLDER_KEEP_MODE is off (flatten mode), time can only be extracted from filename rule; subfolder names are not used for T.
  - If time parsing is enabled but a sample has no parsable time string, it is grouped into time=0 and the time label may be blank; do not drop such rows from summaries.

## Comments
- Add brief comments only when the logic is not self-explanatory.
- Do not remove existing author or version notes.
- New comments should explain intent or non-obvious assumptions, not re-state code.
- Comment language: Japanese for code comments and doc blocks; avoid English "NOTE:"-style comments in logic.
- Exception: the AI edit notice at the top of the main script should be present in CN/JP/EN.
- Use full-sentence comments with Japanese punctuation where the surrounding block does so.
- Prefer block-level comments ahead of a logical step or phase; avoid end-of-line comments.
- Typical comment density: one header per phase/section, and occasional inline comments for heuristics, thresholds, or non-obvious control flow.
- Function doc blocks follow the established order:
  - Separator line
  - "関数: name"
  - "概要: ..."
  - "引数: name (type), ..." (single line or short multi-line list)
  - "戻り値: ..."
  - Optional "補足:" / "副作用:" lines if needed
  - Separator line

## Compatibility / Non-Regression
- ImageJ macro does not support arrays-of-arrays; use flat arrays with start/len indexing when grouping or bucketing.
- Avoid returning `newArray(a, b)` where `a` and `b` are arrays; return flat arrays or mutate inputs in-place.
- String empty checks should prefer `lengthOf(s) == 0` when a function may return non-string values; avoid `if (trim2(...) == "")` in ambiguous contexts.
- Avoid compact boolean expressions that rely on implicit string evaluation; prefer explicit `if (...) return 1/0;` patterns.
- For token parsing, prefer a single case-normalization strategy (typically `toLowerCase`) to reduce version-specific API risks.
- When using `replace()`, remember it is regex-based; escape user/content strings via `replaceSafe` to avoid `$` and `\` issues.
- Do not introduce new ImageJ macro features outside the supported subset (no regex, no advanced data structures, no ternary tricks).

## Repository Structure
- `Macrophage Image Four-Factor Analysis_3.0.0.ijm` is the active script to modify unless told otherwise.
- `old/` contains archived legacy scripts for reference only (current set: 1.0, 2.0b, 2.1, 2.2b, 2.2.3, 2.2.4, 2.2.4b).
- Do not edit files under `old/` unless explicitly requested.
- `README*.md` files are documentation entry points and should retain the AI edit notice.

## Repository Notes
- AI contributors must read `AGENTS.md` before making any edits.
- Keep the AI edit notice at the top of the main script and the README.* entry points.
- License: CC0 1.0 Universal (Public Domain Dedication). Keep `LICENSE` and README license sections in sync.
 - Third-party software/fonts are included and remain under their own licenses. See `THIRD_PARTY_NOTICES.md`.
## Maintenance Requirements
- Keep the Script Module Index current after any change that adds/moves/removes logic.
- For any new or modified logic, identify likely failure points and add expected error prompts in CN/JP/EN with error codes and logs (see Error Code System).
- Do not document data-optimization behavior or adjustment logic in README files or script comments; only keep non-modifying definitions (e.g., IBR = BIC / TB, PCR = CWB / TC, BPC = BIC / TC).

## Lessons Learned
- ImageJ/Fiji macro functions have a hard limit on the number of arguments; exceeding it triggers "Too many arguments". Pack related parameters into arrays and unpack inside the function to avoid hitting the limit.

## Explanations
- When asked to explain the script, provide structured summaries (overview -> phases -> key functions).
- Avoid line-by-line narration unless explicitly requested.
- Offer to drill into specific phases or functions with targeted detail.
- Emphasize code style and comment conventions when the user asks for analysis of style.

## Style Checklist
- **Structure:** preserve section separators; keep phase ordering; group constants near their phase/use.
- **Naming:** camelCase for functions; lowerCamel for locals; ALL_CAPS for constants/UI labels (T_*); avoid new naming schemes.
- **Control Flow:** prefer explicit loops; avoid dense expressions; use temporaries for clarity.
- **UI/Strings:** add CN/JP/EN strings together; avoid hardcoded UI text in logic; keep labels aligned with dialogs.
- **Errors/Logs:** use replaceSafe for templated messages; keep log verbosity behavior unchanged; add log labels for new options.
- **Data Format:** if adding columns/tokens, update validation, token maps, and output construction consistently.
- **Results:** keep column order stable; avoid breaking existing tokens; maintain per-cell expansion rules.
- **Comments:** only when intent is non-obvious; keep existing author/version notes.
- **Compatibility:** no nested arrays; avoid regex pitfalls in `replace`; use `lengthOf` for empty checks; keep parsing/formatting logic stable.

## Update Log (Reference)
- Scope: algorithm-focused deltas across archived versions and current script. UI changes are omitted. Data-optimization functions are listed without detail.

### Version 1.0 (old/Macrophage Image Four-Factor Analysis_1.0.ijm)
- Baseline pipeline: background subtraction, ROI-based detection, and basic area/intensity aggregation. No clump estimation, exclusion filter, or feature classification.
- Added/Removed functions: none (baseline).

### Version 2.0b (old/Macrophage Image Four-Factor Analysis_2.0b.ijm)
- Algorithm updates:
  - Added exclusion filtering based on target/exclusion intensity distributions (direction + threshold).
  - Added clump size-based split estimation for large candidates using representative single-object area.
  - Added label-mask creation to support region-aware decisions.
  - Added safety guards for image/window access and pixel sampling.
- Added functions (reason / role):
  - max2, min2, abs2, roundInt, clamp: numeric helpers to standardize comparisons, thresholds, and rounding.
  - ensure2D, safeClose, requireWindow, getPixelSafe, localMean3x3: protect image operations and compute local intensity.
  - annotateCellsSmart: consolidate ROI handling flow (open/mark/save) for robust annotation.
  - estimateAreaRangeSafe, estimateRollingFromUnitArea: derive detection scale and background parameters from samples.
  - estimateExclusionSafe: infer exclusion direction and threshold from sample distributions.
  - buildCellLabelMaskFromOriginal: generate labeled ROI mask for region-aware processing.
  - detectBeadsFusion: core detection logic combining thresholds and shape constraints.
  - countBeadsByFlat: summarize detected candidates from the flat array.
- Removed functions:
  - quantileSorted, idxImageTypeByCellCount, annotateCellsAndSave: replaced by safer estimation/annotation flows above.

### Version 2.1 (old/Macrophage Image Four-Factor Analysis_2.1.ijm)
- Algorithm updates:
  - Detection pipeline stays mostly intact; adds structured data-format parsing to support output reformatting.
- Added functions (reason / role):
  - trim2, splitByChar, splitCSV, isDigitChar: robust parsing utilities for rule/column specs.
  - parsePnF, isBuiltinToken, validateDataFormatRule, validateDataFormatCols: rule/token validation for output configuration.
  - uniqueList, sortPairsByNumber, sortTriplesByNumber: grouping and ordering helpers for summary output.
  - calcRatio: safe ratio computation for summary fields.
  - escapeForReplace, replaceSafe, logDataFormatDetails: safe templating and structured logging of format settings.
- Removed functions: none.

### Version 2.2b (old/Macrophage Image Four-Factor Analysis_2.2b.ijm)
- Algorithm updates:
  - Detection pipeline unchanged; adds time-aware grouping and per-cell expansion in results handling.
- Added functions (reason / role):
  - detectSubstringInclusive, ensureTrailingSlash: runtime compatibility and path normalization.
  - joinNumberList, parseNumberList, charAtCompat, isDigitAt: string/number handling for parsing.
  - normalizeRuleToken, extractFirstNumberStr, parseByPattern, parseRuleSpec: rule parsing expansion.
  - requiresPerCellStats, findGroupIndex, sortQuadsByNumber: grouping and ordering helpers.
  - estimateMeanMedianSafe: stable central tendency estimation for sample-derived parameters.
  - meanFromCsv, scaleCsv, scaleCsvIntoArray, buildZeroCsv, getNumberAtCsv: data-adjustment helpers (details omitted per request).
- Removed functions: none.

### Version 2.2.3 (old/Macrophage Image Four-Factor Analysis_2.2.3.ijm)
- Algorithm updates:
  - Legacy snapshot between 2.2b and 2.2.4; details not documented.
- Added/Removed functions: not recorded.

### Version 2.2.4 (old/Macrophage Image Four-Factor Analysis_2.2.4.ijm)
- Algorithm updates:
  - Added feature-based round object classification using center/ring/outer intensity metrics.
  - Added clump mask construction (dark clumps and in-cell clumps) and mask-derived detection.
  - Added multi-feature detection pipeline that merges round-feature detection and clump detection.
  - Added mask-based filtering to exclude candidates within specified masks.
- Added functions (reason / role):
  - sampleRingMean, computeSpotStats: compute ring/outer intensity statistics for round candidates.
  - classifyRoundFeature: classify candidates by center contrast, background similarity, and size.
  - estimateAbsDiffThresholdSafe, estimateSmallAreaRatioSafe, estimateClumpRatioSafe, estimateClumpRatioFromSamples: infer thresholds/ratios from samples.
  - buildClumpMaskDark, buildClumpMaskInCell, detectClumpsFromMask: clump detection via masks.
  - detectTargetsMulti: unified detection pipeline for multiple feature types.
  - filterFlatByMask: remove detections covered by a mask.
  - formatFeatureList, openFeatureReferenceImage, showFeatureReferenceFallback: feature selection support (non-UI core only).
  - buildCsvCache, meanFromCache, scaleCsvCacheInPlace, getNumberFromCache, tokenCodeFromToken: data-adjustment/output helpers (details omitted per request).
- Removed functions: none.

### Version 2.2.4b (old/Macrophage Image Four-Factor Analysis_2.2.4b.ijm)
- Algorithm updates:
  - Data-format filename rule parsing extended to support multi-part literals and platform-specific naming patterns.
  - Default filename rule switched to Windows Explorer-style numbering.
- Added/Removed functions: not recorded.

