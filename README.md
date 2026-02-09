# Macrophage Image Four-Factor Analysis
Languages: [Chinese](README.zh-CN.md) | [English](README.en.md) | [Japanese](README.ja.md)

Fiji-only ImageJ macro for semi-automated quantification of macrophage images with target objects (beads). The script is interactive and guides ROI annotation, sampling, detection, and reporting in one workflow.

Key capabilities
- Cell ROI annotation with validation and label-mask acceleration
- Target object sampling to infer area scale, contrast thresholds, and background subtraction
- Dual-path round-object detection (threshold + edge) with strictness policies
- Clump detection and area-based count estimation
- Optional exclusion filter based on learned intensity and size gates
- Four-factor outputs with optional tiny-uptake adjustment
- Flexible PN/F/T parsing and per-cell expansion

## Overview
- Main script: `Macrophage Image Four-Factor Analysis_3.0.0.ijm`
- Reference image for feature selection: `sample.png`
- Runtime: Fiji (required). The macro is designed for Fiji and does not run in ImageJ alone.
- Supported image formats: tif/tiff/png/jpg/jpeg

## Quick start
Recommended run method (avoids non-English text garbling):
1. Open Fiji.
2. Drag and drop `Macrophage Image Four-Factor Analysis_3.0.0.ijm` into the Fiji window.
3. The Macro Editor opens. Click Run.

## Four-factor model and core metrics
The "four factors" are count-based quantities computed per image:
- TB: total target objects detected (after clump estimation if enabled).
- BIC: target objects inside cell ROIs (after clump estimation if enabled).
- CWB: number of cells containing at least one target object.
- TC: total number of cell ROIs.

Additional derived metrics:
- CWBA: adjusted CWB after tiny-uptake thresholding (optional).
- IBR = BIC / TB
- PCR = CWB / TC
- BPC = BIC / TC (mean objects per cell)

Summary metrics in formatted output:
- eIBR/ePCR/eBPC: mean ratios per PN (and per time if time parsing is enabled).
- ISDP/PSDP/BPCSDP: population standard deviation of the ratios in the same group.

## Workflow (phase by phase)
1. Language selection.
2. Mode selection: ROI only, analyze only, or annotate + analyze.
3. Folder selection (file mode or subfolder mode).
4. Cell ROI annotation (if enabled).
5. Target object sampling.
6. Exclusion sampling (optional).
7. Parameter inference and confirmation.
8. Batch analysis and results output.

## Image processing theory and implementation (hardcore)

### 1) Sampling and inference
Target sampling collects ROI-based statistics on an 8-bit copy of the image.
For each sampled ROI:
- Area and mean intensity are measured.
- A local contrast signature is computed:
  - centerMean: 3x3 mean at the ROI center.
  - ringMean: mean of 8 points on radius 0.75r.
  - outerMean: mean of 8 points on radius 1.35r.
  - centerDiff = centerMean - ringMean
  - bgDiff = abs(((centerMean + ringMean)/2) - outerMean)

Round vs clump sample classification:
- Round sample if ROI type is oval or rectangle and aspect ratio <= 1.6.
- Non-round ROI or very elongated ROI is treated as clump sample.
- In-cell flag uses the existing cell ROI mask when available:
  - A coarse grid is sampled inside the ROI.
  - If >= 30% of tested points overlap the cell label mask, the sample is marked in-cell.

Robust area range inference (estimateAreaRangeSafe):
- If < 3 samples: use median m, min = 0.45*m, max = 2.50*m.
- If >= 3: trim 5-95%, compute q10, q90, q25, q75, IQR.
- padding = max(IQR*1.20, m*0.35)
- marginFactor = 1.60 (n < 6), 1.35 (n < 15), else 1.15
- minA = floor((q10 - padding) / marginFactor)
- maxA = ceil((q90 + padding) * marginFactor)
- cap maxA by max(20*m, 6*q90)

Rolling Ball suggestion:
- unitArea = median of target areas.
- diameter d = 2*sqrt(unitArea/PI)
- radius = round(d*10) if d < 8, round(d*7) if d < 20, else round(d*5)
- clamped to [20, 220]

Feature thresholds inferred from samples:
- centerDiffThr = 70th percentile of abs(centerDiff), clamped to [6, 40].
- bgDiffThr = 50th percentile of abs(bgDiff), clamped to [4, 30].
- smallAreaRatio = clamp(q25/median, 0.45, 0.90).
- clumpMinRatio = 25th percentile of clumpArea/unitArea, clamped to [2.5, 20].

Sampling heuristics and filters:
- Round sample area cap: when >= 3 round samples exist, only round samples with area <= 3.0 * median are used for target area inference.
- Clump sample detection: a sample is treated as clump if the ROI is non-round or area >= unitArea * 2.5.
- Exclusion size sampling filter: during exclusion sampling, only ROIs with area < unitAreaGuess * 20 are used for size-range inference (unitAreaGuess is the representative target area; fallback is the default midpoint).

### 2) Target object features (F1 to F6)
Feature meanings (from the built-in reference image):
- F1: bright core with darker rim (reflection-type round object)
- F2: mid-tone round object with weak inner/outer contrast
- F3: dark clumps of aggregated objects (count by area)
- F4: dense/heterogeneous regions inside cells (in-cell only; count by area)
- F5: dark core with brighter rim (contrast-type round object)
- F6: low-contrast, small round objects close to cell intensity

Rules:
- F4 is in-cell only (requires overlap with cell ROI).
- F1 and F5 are mutually exclusive.
- Selected features control which feature-threshold parameters appear.

### 3) Preprocessing per image
For each image:
- Ensure 2D (first slice if z-stack) and force pixel units.
- Duplicate to 8-bit for detection and sampling.
- Optional background subtraction using Rolling Ball.

### 4) Round object detection (F1/F2/F5/F6)
Dual-path detection generates candidate round objects.

Threshold polarity:
- If target and exclusion medians are available:
  - Use DARK if targetMedian <= exclusionMedian, else LIGHT.
- If only targetMedian is available:
  - Compare to image mean to choose DARK vs LIGHT.
- If only F1 is selected, force DARK. If only F5 is selected, force LIGHT.

Path A: Yen threshold
1. Optional median filter (radius 1, except in Loose).
2. Auto threshold (Yen dark/light/auto).
3. Convert to mask, fill holes.
4. Morphological open (Strict applies twice).
5. Watershed in Strict.
6. Analyze Particles by area and circularity.

Path B: Edge + Otsu
1. Find Edges.
2. Auto threshold (Otsu dark/light/auto).
3. Convert to mask, fill holes.
4. Morphological open (unless Loose).
5. Watershed in Strict.
6. Analyze Particles by area and circularity.

Fusion and de-duplication:
- mergeDist = max(2, 0.8 * sqrt(unitArea/PI)).
- Candidates within mergeDist are merged, keeping the larger area.
- Strict policy keeps only:
  - candidates present in both paths, or
  - candidates with area >= 1.25 * unitArea.
- Normal policy uses union of both paths.
- Loose policy minimizes filtering.

### 5) Feature classification for round candidates
For each fused candidate:
- r = sqrt(area/PI)
- Compute centerDiff and bgDiff as in sampling.
- Classification:
  - If abs(centerDiff) >= centerDiffThr:
    - centerDiff >= thr and F1 enabled -> keep (F1)
    - centerDiff <= -thr and F5 enabled -> keep (F5)
  - Else:
    - isSmall if area <= unitArea * smallAreaRatio
    - isBgLike if bgDiff <= bgDiffThr
    - If F6 enabled and (isSmall or isBgLike) -> keep (F6)
    - Else if F2 enabled -> keep (F2)

### 6) Clump detection (F3/F4)
Clump candidates are detected from masks rather than roundness.

F3: dark clump mask
- Median filter (except Loose).
- Yen dark threshold, convert to mask, fill holes.
- Morphological open: Strict twice, Normal once, Loose none.

F4: in-cell clump mask
- Requires cell label mask.
- Variance filter on grayscale:
  - varRadius = round(0.45 * sqrt(unitArea/PI)), clamped 1..6
  - Strict +1, Loose -1
- Convert to 8-bit, Otsu light threshold, fill holes.
- Open in Strict.
- AND with cell mask to keep in-cell high-variance regions.

Combined mask:
- If both F3 and F4 are enabled, masks are OR-ed.
- Clumps are detected by Analyze Particles with:
  - min area = unitArea * clumpMinRatio
  - max area = image area

To avoid double counting, round candidates that fall inside the clump mask are removed.

### 7) Exclusion filter (optional)
Exclusion is a post-detection filter and never expands detections.

Sampling-based threshold inference (estimateExclusionSafe):
- Discard saturated values (<= 1 or >= 254).
- Trim 5-95% for both target and exclusion samples.
- If medians are too close (< 8), use conservative threshold 255.
- If exclusion median > target median:
  - mode HIGH (exclude bright)
  - compare t90 and e10; if overlapping, thr = e10; else thr = (t90 + e10)/2
- If exclusion median < target median:
  - mode LOW (exclude dark)
  - compare t10 and e90; if overlapping, thr = e90; else thr = (t10 + e90)/2

Size gate (optional):
- If exclusion samples include target-object-like ROIs, infer area range and apply intensity filtering only within that range.

Per-image strict adjustment:
- Compute image mean and std from the detection 8-bit image.
- kstd = clamp(std/mean, 0.10, 0.60)
- If HIGH: thr = min(userThr, mean + std*kstd)
- If LOW: thr = max(userThr, mean - std*kstd)

Per-candidate decision:
- Use local 3x3 mean intensity at candidate centroid.
- HIGH: discard if mean >= thr
- LOW: discard if mean <= thr

### 8) Counting and clump estimation
For each candidate:
- If clump estimation is enabled and area > unitArea*1.35:
  - est = round(area / unitArea), clamped to [1, 80]
- TB adds est for all candidates.
- BIC adds est only when the centroid falls inside a cell.

Cell assignment:
- With label mask: O(1) lookup of the centroid pixel value.
- Without label mask: ROI containment test (slower).

### 9) Tiny-uptake adjustment (optional)
To reduce noise from marginal uptake:
- Collect per-cell counts > 0.
- q50 = median, q75 = 75th percentile.
- minPhagoThr = round((q50 + q75)/2), min 1.
- CWBA counts cells with target object count >= minPhagoThr.

## Parameter logic and strictness
Strictness modifies detection windows and feature thresholds.

Area and circularity scaling:
- Strict: minA*0.85, maxA*1.20, circ+0.08
- Normal: minA*0.65, maxA*1.60, circ-0.06
- Loose: minA*0.50, maxA*2.10, circ-0.14

Feature threshold scaling:
- Strict: centerDiff*1.15, bgDiff*0.80, smallRatio*0.90, clumpRatio*1.20
- Loose: centerDiff*0.85, bgDiff*1.20, smallRatio*1.10, clumpRatio*0.85

Clamping:
- centerDiff 2..80, bgDiff 1..60, smallRatio 0.20..1.00, clumpRatio 2..20
- effMinArea is floored, effMaxArea is ceiled.

If the user edits min/max area in the UI, unitArea is synchronized to the new midpoint.

Default parameters (v3.0.0):
- ROI suffix: _cells
- Default target area range: minA=5, maxA=200, circ=0
- Default background radius: rolling=50
- Default feature thresholds: centerDiff=12, bgDiff=10, smallRatio=0.70, clumpRatio=4.0
- Clump sample ratio threshold: 2.5 (used to flag large samples as clumps)
- Default features: F1/F2/F3 enabled; F4/F5/F6 disabled
- Default strictness: Normal
- Clump estimation: enabled
- Tiny-uptake adjustment: enabled
- Exclusion: disabled unless multi-object mode; default mode HIGH, threshold 255, strict adjustment on, size gate on only when size samples exist
- Data formatting: enabled; default rule `<p>/<f>,f="F"` or `<f>/hr,f="T"//<p>/<f>` in subfolder keep mode
- Default columns: `TB/BIC/CWBA,name="Cell with Target Objects"/TC/IBR/PCR/EIBR/EPCR/ISDP/PSDP`
- Data optimization: enabled

## Data formatting and results layout
Formatted output is enabled by default and uses rules that parse PN/F/T.

### Rule syntax
- File rule: `pattern, f="F"` or `pattern, f="T"`
- Subfolder keep mode: `folderSpec//fileSpec`
- pattern must contain exactly one "/" separating PN and F tokens:
  - PN token: `<p>` or `<pn>`
  - F token: `<f>` or `<f1>`
- f="T" tells the parser to treat the F number as time instead of F.
- Time parsing is enabled when f="T" is set in the file rule or folder rule.
- If subfolder keep mode is off (flatten mode), time can only be parsed from the file rule; subfolder names are not used.
- If time parsing is enabled but no time is found, time is set to 0.

### Column schema
Columns are listed as `col1/col2/...`.

Built-in tokens:
- PN, F, T, TB, BIC, CWB, CWBA, TC, BPC, IBR, PCR, EBPC, BPCSDP, EIBR, EPCR, ISDP, PSDP

Custom columns:
- Any non-built-in token with parameters, for example:
  - `name="Dose", value="10"`
- `$` prefix makes a custom column output once (not expanded by PN).
- `-F` or `-f` reverses F sorting.

### Table layout rules
- Each PN is its own logical table. PN tables are placed left-to-right in one Results sheet.
- Row count equals the longest PN table; shorter tables leave trailing empty rows.
- If time parsing is enabled:
  - Rows are grouped by time (ascending numeric).
  - Each time block has row count equal to the max PN length for that time.
  - PN without data in a time block outputs blank rows for that block.

Per-cell expansion:
- If BPC/EBPC/BPCSDP is present, the table expands to one row per cell.
- Only per-cell columns vary by row; other columns repeat.
- Summary columns (EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP) are still aggregated per PN and time block.

## Practical guidance and pitfalls
- Sample typical single objects for robust parameter inference.
- Use Freehand/Polygon ROIs for clump samples (F3 or F4).
- If ROI count exceeds 65535, split the dataset or reduce per-image cells.
- Saturated intensities (<=1 or >=254) are ignored in exclusion inference.
- Missing ROI files can be annotated on the spot or skipped; skipped images still appear in results with blanks.
- Run via drag-and-drop to avoid encoding issues in non-English UI text.

## License
CC0 1.0 Universal (Public Domain Dedication). See `LICENSE`.
This repository also includes third-party software and fonts under their own licenses. See `THIRD_PARTY_NOTICES.md`.




