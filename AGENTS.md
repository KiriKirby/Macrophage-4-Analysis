# AGENTS

These instructions apply to this repository.

## Code Style
- Language: ImageJ macro (.ijm). Script is designed for Fiji and should be treated as Fiji-only.
- Prefer explicit loops and arrays over compact expressions; match existing style.
- Use the existing section layout and separators ("// -----" blocks).
- New functions should follow the existing doc block format:
  - "// -----------------------------------------------------------------------------"
  - "// 関数: name" and short Japanese description lines.
- Keep naming consistent: camelCase for functions, lowerCamel for locals, ALL_CAPS for constants and UI labels (T_*).
- Avoid introducing Unicode unless the file already uses it and it is necessary for UI text.
- Favor clear step-by-step control flow over clever tricks; avoid nested ternaries or compact one-liners.
- Use explicit temporaries for intermediate values when it improves readability or mirrors existing patterns.
- Keep ImageJ macro limitations in mind (no advanced data structures, no regex).
- Maintain existing error handling style: build message strings with replaceSafe and exit/showMessage.
- Keep numeric thresholds and default values grouped with related phase blocks or UI sections.
- Keep the top-of-file header block with the existing fields (概要/目的/想定/署名/版数) and the same separator style.

## UI/Localization
- UI strings are grouped by language blocks (CN/JP/EN). When adding new UI text, add it to all three blocks.
- Use existing label keys (T_*) where possible; do not hardcode UI text in logic.
- Keep dialog order and grouping consistent with existing sections (target/bg/roi/excl/format).
- Keep UI text concise but instructional; use full-width punctuation only where already present in the language block.
- When adding options, also add matching log labels and error strings if referenced in logic.

## Behavior
- Default behaviors should match the current script (e.g., dataOptimizeEnable defaults on unless explicitly exposed in UI).
- Do not change logging verbosity or batch mode unless requested.
- Preserve backward compatibility for existing column tokens and data format rules.
- Keep sampling flow and user prompts in the current sequence unless explicitly requested.
- Preserve ROI suffix behavior and default values unless explicitly asked to change them.
- Preserve algorithmic outputs unless explicitly requested; even “refactors” must keep counts, thresholds, grouping, and sorting identical.
- Avoid changing Results table ordering, grouping, or row counts; keep side-by-side PN layout and time grouping rules intact.

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
