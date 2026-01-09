# Macrophage Image Four-Factor Analysis
**README (English Version)**

Note for AI contributors: Read `AGENTS.md` in this repository before making any edits.

---

## 0. Overview

This repository provides a **Fiji / ImageJ macro** for semi-automated quantitative analysis of **macrophage images with beads** (current script version: **v2.2**).

The macro implements an end-to-end workflow:
- Manual **cell ROI annotation** with robust error checking
- **Target bead sampling** to infer scale, size range, and background subtraction
- Optional **exclusion sampling** for confounders or multiple bead types
- **Dual-path bead detection** (threshold + edge) with strictness control
- **Clump estimation** by area and **bead-in-cell** statistics
- Optional **tiny-uptake adjustment** (dynamic threshold)
- **Data formatting + optimization** for project-level reporting (PN/F, IBR/PCR, eIBR/ePCR)

---

## 1. What’s New / Updated in v2.2

- **Data formatting module** with explicit rules for filename parsing and column construction.
- **Data optimization (IBR/PCR)** to stabilize between-project and within-project variability.
- **Exclusion strictness**: per-image adaptive thresholding based on mean/std.
- **Richer logging** and phase-wise status outputs.
- **Improved default inference** from sampling (robust area estimates + rolling ball estimation).

---

## 2. Requirements

- Fiji (recommended) or ImageJ
- Supported image formats: `.tif / .tiff / .png / .jpg / .jpeg`

---

## 3. How to Run (Recommended)

Avoid this method (may cause non‑English text garbling):

```
Fiji → Plugins → Macros → Run...
```

Recommended method:

1. Open Fiji
2. **Drag and drop the `.ijm` macro file into the Fiji window**
3. Fiji opens the **Macro Editor**
4. Click **Run**

---

## 4. Workflow (Detailed, Phase‑by‑Phase)

### Phase 1) Language selection
Choose Chinese / English / Japanese for the UI.

### Phase 2) Mode selection
- **ROI only**: annotate cells and save ROIs; no bead analysis.
- **Analyze only**: analyze existing ROI files.
- **Annotate + analyze (recommended)**: full workflow.

### Phase 3) Folder selection
Select the folder containing images and ROI files.

### Phase 4) Cell ROI annotation (if enabled)
- Draw each cell boundary and press **T** to add to ROI Manager.
- Save as `imageName + _cells.zip` (suffix configurable).
- If ROI already exists, choose: edit / redraw / skip / skip all.

### Phase 5) Target bead sampling
Purpose: infer **typical single-bead scale** and default detection parameters.
- Draw oval ROIs around **single beads** (avoid clusters).
- The script measures **area + mean intensity** on an 8‑bit copy.
- Continue sampling across randomized images, then stop when adequate.

### Phase 6) Exclusion sampling (optional)
Use when multiple bead types or confounders exist.
- Oval/rect ROIs → learn **intensity + area** of exclusion beads
- Freehand/polygon ROIs → learn **intensity only** (no area gate)

### Phase 7) Parameter inference
- **Area range** inferred from target samples using robust statistics.
- **Rolling Ball** inferred from unit bead area (empirical conversion).
- **Exclusion threshold** inferred from intensity distributions.

### Phase 8) Parameter confirmation
Parameters include:
- Bead size range, circularity, clump estimation, tiny‑uptake adjustment
- Strictness (Strict / Normal / Loose)
- Background rolling ball radius
- ROI suffix
- Exclusion (enable, direction, threshold, strictness, size gate)
- **Data formatting** (rules, columns) and **data optimization** toggle

### Phase 9) Batch analysis
For each image:
- Load image, ensure 2D, force pixel units
- Build **cell label mask** (16‑bit, ID per ROI)
- Create 8‑bit bead image and subtract background if needed
- Run **dual‑path bead detection** and merge candidates
- Apply optional **exclusion filter**
- Count beads and compute cell statistics

### Phase 10) Results output
- Standard results table (if data formatting disabled)
- Or **custom formatted table** by PN/F rules and column schema

---

## 5. Core Algorithm (Professional Details)

### 5.1 ROI → 16‑bit label mask
- Each ROI is filled with an ID (1..65535) into a 16‑bit image.
- This enables **O(1)** bead‑to‑cell assignment via pixel lookup.
- The macro aborts if ROI count > 65535 or ROI[1] is invalid.

### 5.2 Target bead sampling → robust size inference
- Areas are sorted and trimmed; median/quantile/IQR estimates are used.
- Robust range is inferred as `[minA, maxA]` with fallback defaults.
- **Unit bead area** = inferred mid value; used for merging and clump estimation.

### 5.3 Rolling Ball estimation
- Uses unit bead area → equivalent diameter → empirical conversion.
- Clamped to safe bounds to prevent over/under subtraction.

### 5.4 Exclusion threshold inference
Let **T** = target bead mean intensities, **E** = exclusion intensities.
- If sample size < 3 or distributions overlap heavily → conservative threshold.
- Determine direction by median: if `median(E) > median(T)` → exclude bright; else dark.
- For bright exclusion:
  - Compute `t90` (target 90% quantile) and `e10` (exclusion 10% quantile).
  - If overlap (`t90 >= e10`) → use conservative `e10`.
  - Else threshold = `(t90 + e10)/2`.
- For dark exclusion:
  - Use `t10` and `e90` with symmetric logic.

### 5.5 Bead detection: dual‑path fusion
**Path A (Threshold / Yen):**
1. Optional median filter (except Loose)
2. Auto threshold (Yen)
3. Convert to mask, fill holes
4. Morphological open (once; twice in Strict)
5. Watershed split
6. Analyze particles by area + circularity

**Path B (Edges / Otsu):**
1. Find Edges
2. Auto threshold (Otsu)
3. Convert to mask, fill holes
4. Morphological open (unless Loose)
5. Watershed split
6. Analyze particles by area + circularity

**Fusion:**
- Candidates are merged by distance threshold `mergeDist = max(2, 0.8 * r)` where `r = sqrt(unitArea/π)`.
- If two candidates are within mergeDist, keep the **larger area**.
- **Strictness policy:**
  - **Strict**: keep only dual‑path matches, or large candidates (≥ 1.25 × unit area).
  - **Normal**: union of both paths.
  - **Loose**: minimal filtering, looser morphology.

### 5.6 Strictness scaling of size/circularity
Effective detection bounds are expanded/contracted:
- **Strict:** minA×0.85, maxA×1.20, circ+0.08
- **Normal:** minA×0.65, maxA×1.60, circ−0.06
- **Loose:** minA×0.50, maxA×2.10, circ−0.14

### 5.7 Exclusion filter (per candidate)
- Uses **local 3×3 mean intensity** at bead centroid.
- Optional size gate: only apply if area within `[exclMinA, exclMaxA]`.
- Mode HIGH: exclude if `mean ≥ threshold`.
- Mode LOW: exclude if `mean ≤ threshold`.

**Strict exclusion (per image):**
- Compute image mean/std; `kstd = clamp(std/mean, 0.10..0.60)`.
- Adjust threshold:
  - HIGH: `thr = min(userThr, mean + std*kstd)`
  - LOW: `thr = max(userThr, mean - std*kstd)`

### 5.8 Clump estimation
- If `area > 1.35 × unitArea`:
  - `count = round(area / unitArea)`
  - Clamp to `[1, 80]`

### 5.9 Bead‑in‑cell assignment
- With label mask: **pixel ID lookup** for bead centroid.
- Without label mask: ROI boundary test (slower)

### 5.10 Tiny‑uptake adjustment (optional)
- Gather per‑cell bead counts > 0.
- Compute **median (q50)** and **75th percentile (q75)**.
- Dynamic threshold = `round((q50 + q75)/2)`, min 1.
- Cells below threshold are excluded from `Cells with Beads (Adj)`.

---

## 6. Data Formatting (PN/F) and Output Schema

### 6.1 Filename parsing rules
- Rule format: `pn/f` or `f/pn` (exactly one `/`).
- Tokens:
  - `pn`: project name (non‑digit part)
  - `f`: index without leading zeros (1,2,3…)
  - `f1`: index with leading zeros (01/001/…)
- Sorting is **always numeric** by `f`.

### 6.2 Column format
Syntax: `col1/col2/col3/...`

Built‑in tokens:
- `PN`, `F`, `TB`, `BiC`, `CwB`, `CwBa`, `TC`, `IBR`, `PCR`, `eIBR`, `ePCR`

Custom columns:
- Any non‑built‑in code
- Parameters:
  - `name="..."` column label
  - `value="..."` constant value
- `$` prefix: custom column shown **once** (not expanded per project)
- `-F` or `-f`: sort `F` descending

---

## 7. Data Optimization (IBR / PCR)

### 7.1 Definitions
- **IBR** = Beads in Cells / Total Beads
- **PCR** = Cells with Beads / Total Cells

### 7.2 Optimization logic (hierarchical smoothing)
The macro computes:
- Global mean (gIBR / gPCR)
- Project‑level mean per PN
- Per‑image ratio

It then adjusts per‑image ratios by:
- **betweenFactor**: increases weight of project mean when multiple projects exist
- **withinFactor**: balances per‑image deviation based on sample size per project

Adjusted ratios are converted back to **adjusted counts**, which are used for:
- Output of BiC / CwB
- Computation of **eIBR / ePCR** (project means after adjustment)

This stabilizes output across uneven sample sizes while preserving within‑project trends.

---

## 8. Output Tables

### Standard output (formatting disabled)
Columns:
- Image, Total Beads, Beads in Cells, Cells with Beads, Cells with Beads (Adj), Total Cells

### Formatted output (formatting enabled)
- Columns follow the **column format schema**
- PN‑expanded columns if multiple projects exist
- Optional constants or one‑time columns via `$`

---

## 9. Notes / Pitfalls

- **ROI count limit**: max 65535 (16‑bit labels). Use smaller batches if exceeded.
- **Missing ROIs**: image can be annotated on the spot, skipped, or skipped globally.
- **Encoding issues**: run by drag‑and‑drop to avoid garbled non‑English UI text.

---

## 10. License

MIT License is recommended. Use GPL‑3.0 if copyleft is required.
