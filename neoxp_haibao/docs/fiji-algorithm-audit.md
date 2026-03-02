# Fiji Algorithm Audit for Macro 4.0.0

This audit was derived from:

1. The macro command usage in `Macrophage Image Four-Factor Analysis_4.0.0.ijm`.
2. `fiji/Fiji.app/jars/ij-1.54p.jar` command registration and class inspection.
3. `IJ_Props.txt` command-to-plugin mappings in `ij-1.54p.jar`.

## Key Finding

The macro does not rely on specialized third-party Fiji plugins for core detection/counting.
It mainly uses ImageJ 1 core commands/classes.

## Macro Detection Flow (High-Level)

1. Convert to 8-bit and optional rolling-ball background subtraction.
2. Build candidate masks via Yen/Otsu thresholding and morphology.
3. Detect particles from masks and merge candidate sets.
4. Apply exclusion threshold logic and in-cell assignment.
5. Output summary and per-cell metrics.

## Command-to-Implementation Mapping

| Macro Command | ImageJ/Fiji Implementation | Core Algorithm Family | Migration Note |
|---|---|---|---|
| `8-bit` | `ij.plugin.Converter("8-bit")` | type conversion | easy to replace |
| `Duplicate...` | `ij.plugin.Duplicator` | image clone | easy to replace |
| `Subtract Background...` | `ij.plugin.filter.BackgroundSubtracter` | rolling-ball / sliding paraboloid | important for parity |
| `setAutoThreshold("Otsu"/"Yen")` | `ij.process.AutoThresholder` | histogram thresholding | must match implementation details |
| `Convert to Mask` | `ij.plugin.Thresholder("mask")` | binary threshold mask | easy with controlled thresholds |
| `Fill Holes` | `ij.plugin.filter.Binary("fill")` | binary morphology | straightforward with morphology libs |
| `Open` | `ij.plugin.filter.Binary("open")` | erosion+dilation | straightforward |
| `Median...` | `ij.plugin.filter.RankFilters("median")` | rank filter | straightforward |
| `Variance...` | `ij.plugin.filter.RankFilters("variance")` | local variance filter | straightforward |
| `Find Edges` | `ij.plugin.filter.Filters("edge")` | edge filter (`ImageProcessor.findEdges`) | replace with Sobel-compatible behavior |
| `Watershed` | `ij.plugin.filter.EDM("watershed")` | EDT-based watershed split | parity-sensitive |
| `Analyze Particles...` | `ij.plugin.filter.ParticleAnalyzer` | connected components + shape filters | parity-sensitive |
| `Image Calculator...` | `ij.plugin.ImageCalculator` | mask boolean operations | straightforward |
| `Set Measurements...` | `ij.plugin.filter.Analyzer("set")` | measurement config | app-level config in migration |
| `Set Scale...` | `ij.plugin.filter.ScaleDialog` | calibration metadata | optional if pure pixel mode |
| `Clear Results` | `ij.plugin.filter.Analyzer("clear")` | table reset | app-side table reset |
| `ROI Manager...` | `ij.plugin.frame.RoiManager` | ROI container/IO | replace with native ROI model |

## Where the Scientific Risk Actually Is

The highest-risk replacement points are:

1. Thresholding edge cases and mask polarity.
2. Watershed splitting behavior.
3. Particle filtering and measurement semantics (area/circularity/centroid).
4. ROI in-cell assignment behavior and boundary handling.

## Recommendation

1. Keep a Fiji-compatible adapter as baseline.
2. Rebuild native modules in this order:
   - parser and result-layout logic
   - threshold/morphology primitives
   - particle analyzer and in-cell counting
3. Run regression checks on every module replacement.

