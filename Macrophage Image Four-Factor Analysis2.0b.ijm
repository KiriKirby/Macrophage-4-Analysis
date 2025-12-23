// ========================= Part 3/3 =========================
		T_choose     = "Select the folder containing image and ROI files";
		T_exit       = "No folder was selected. The script has ended.";
		T_noImages   = "No image files were found in the selected folder (tif/tiff/png/jpg/jpeg). The script has ended.";
		T_exitScript = "The script was exited by user selection.";

		T_mode_title = "Work Mode";
		T_mode_label = "Mode";
		T_mode_1     = "Annotate cell ROIs only (create *_cells.zip)";
		T_mode_2     = "Analyze only (requires existing cell ROIs)";
		T_mode_3     = "Annotate cell ROIs, then analyze (recommended)";
		T_mode_msg =
			"Select a work mode (dropdown):\n\n" +
			"1) Annotate cell ROIs only\n" +
			"   • Images will be opened one by one.\n" +
			"   • You will draw cell outlines and add them to ROI Manager.\n" +
			"   • The script will save cell ROIs as a zip file (default: image name + “_cells.zip”).\n\n" +
			"2) Analyze only\n" +
			"   • Runs bead detection and statistics directly.\n" +
			"   • A corresponding cell ROI zip must exist for each image (default: image name + “_cells.zip”).\n\n" +
			"3) Annotate then analyze (recommended)\n" +
			"   • Creates missing cell ROIs first.\n" +
			"   • Then performs target bead sampling (and optional exclusion sampling), followed by batch analysis.\n\n" +
			"Note: Click “OK” to confirm your selection.";

		T_step_roi_title = "Step 1: Cell ROI annotation";
		T_step_roi_msg =
			"You are about to enter the Cell ROI annotation phase.\n\n" +
			"During this step:\n" +
			"1) Use your currently selected drawing tool to outline each cell (freehand is recommended).\n" +
			"2) After completing an outline, press “T” to add it to ROI Manager.\n" +
			"3) When the current image is complete, click “OK” to proceed to the next image.\n\n" +
			"Save rule:\n" +
			"• ROIs are saved as: image name + “%s.zip”.\n\n" +
			"Important:\n" +
			"• This script does not switch tools automatically and does not infer cell boundaries.\n" +
			"• For stable results, ensure outlines form closed area ROIs covering the full cell region.";

		T_step_bead_title = "Step 2: Target bead sampling";
		T_step_bead_msg =
			"You are about to enter the Target bead sampling phase.\n\n" +
			"Purpose:\n" +
			"• Uses your samples to infer a typical single-bead area scale and intensity characteristics.\n" +
			"• These estimates are used to propose default detection parameters, estimate bead counts from clumps, and suggest a Rolling Ball radius.\n\n" +
			"Instructions:\n" +
			"1) Use the Oval Tool to mark target beads (high precision is not required, but keep it reasonably tight).\n" +
			"2) Prefer typical single beads; avoid obvious clumps to improve inference reliability.\n" +
			"3) After each ROI, press “T” to add it to ROI Manager.\n" +
			"4) When done with this image, click “OK”.\n" +
			"5) A “Next action” dropdown will then appear to continue sampling, finish and proceed, or exit.";

		T_step_bead_ex_title = "Step 3: Exclusion sampling (optional)";
		T_step_bead_ex_msg =
			"You are about to enter the Exclusion sampling phase (recommended when multiple bead types or confounding objects are present).\n\n" +
			"Purpose:\n" +
			"• Learns an exclusion intensity threshold (and optional size range) to reduce false positives.\n\n" +
			"ROI conventions:\n" +
			"• Oval/Rectangle ROIs: treated as exclusion bead samples (learn intensity and size).\n" +
			"• Freehand/Polygon ROIs: treated as exclusion regions (learn intensity only).\n\n" +
			"Instructions:\n" +
			"1) Mark objects or regions to be excluded.\n" +
			"2) Press “T” to add each ROI to ROI Manager.\n" +
			"3) Click “OK” when finished.\n" +
			"4) Use the dropdown to continue, finish & compute, or exit.";

		T_step_param_title = "Step 4: Confirm parameters";
		T_step_param_msg =
			"The Parameters dialog will open next.\n\n" +
			"You will see:\n" +
			"• Defaults inferred from target bead samples (area range, bead scale for clump estimation, Rolling Ball suggestion).\n" +
			"• If exclusion is enabled, an inferred intensity threshold and (optional) size gate range.\n\n" +
			"Recommendation:\n" +
			"• For first-time use, run once with defaults and adjust only if needed.\n\n" +
			"Note: Click “OK” to confirm and proceed to batch analysis.";

		T_step_main_title = "Start batch analysis";
		T_step_main_msg =
			"You are about to start batch analysis.\n\n" +
			"The script will process all images in the selected folder:\n" +
			"• Load cell ROIs\n" +
			"• Detect beads and compute statistics (including clump estimation and optional exclusion)\n" +
			"• Write a summary table to the Results window\n\n" +
			"Execution mode:\n" +
			"• Runs in silent/batch mode to minimize intermediate windows.\n\n" +
			"If a cell ROI is missing:\n" +
			"• You will be prompted to annotate now / skip / skip all / exit.\n" +
			"• Skipped images remain in the Results table with blank values.\n\n" +
			"Note: Click “OK” to start.";

		T_cell_title = "Cell ROI annotation";
		T_cell_msg =
			"Progress: %i / %n\n" +
			"File: %f\n\n" +
			"Create cell outlines:\n" +
			"1) Draw a cell outline.\n" +
			"2) Press “T” to add it to ROI Manager.\n" +
			"3) Repeat until all cells in this image are complete.\n\n" +
			"Click “OK” to save and continue.\n\n" +
			"Saved as: image name + “%s.zip”";

		T_exist_title = "Existing cell ROI detected";
		T_exist_label = "Action";
		T_exist_edit  = "Load and continue editing (recommended)";
		T_exist_redraw= "Re-annotate and overwrite";
		T_exist_skip  = "Skip this image (keep existing ROI)";
		T_exist_skip_all = "Skip all images with existing ROIs";
		T_exist_msg =
			"A cell ROI zip already exists for this image.\n\n" +
			"Progress: %i / %n\n" +
			"Image: %f\n" +
			"ROI: %b%s.zip\n\n" +
			"Options:\n" +
			"• Load and continue editing: opens existing ROIs for review and correction.\n" +
			"• Re-annotate and overwrite: starts from an empty ROI set and overwrites the zip.\n" +
			"• Skip this image: does not open the image and proceeds.\n" +
			"• Skip all: future existing-ROI images will be skipped without prompting.\n\n" +
			"Select an action (dropdown):";

		T_missing_title    = "Missing cell ROI";
		T_missing_label    = "Action";
		T_missing_anno     = "Annotate cell ROI now, then continue analysis";
		T_missing_skip     = "Skip this image (leave blank results)";
		T_missing_skip_all = "Skip all missing-ROI images (do not ask again)";
		T_missing_exit     = "Exit script";
		T_missing_msg      =
			"No corresponding cell ROI zip was found for this image.\n\n" +
			"Image: %f\n" +
			"Expected ROI: %b%s.zip\n\n" +
			"Notes:\n" +
			"• Four-factor analysis requires a cell ROI.\n" +
			"• If skipped, the image remains in the Results table with blank values.\n\n" +
			"Select an action (dropdown):";

		T_sampling = "Sampling";
		T_promptAddROI =
			"Progress: %i / %n\n" +
			"File: %f\n\n" +
			"Mark target beads (prefer typical single beads; avoid obvious clumps).\n" +
			"• Press “T” to add each ROI to ROI Manager.\n\n" +
			"Click “OK” when finished.\n" +
			"Then choose the next action in the dropdown dialog.";

		T_promptAddROI_EX =
			"Progress: %i / %n\n" +
			"File: %f\n\n" +
			"Mark objects/regions to exclude.\n" +
			"• Oval/Rectangle: exclusion bead samples (intensity + size)\n" +
			"• Freehand/Polygon: exclusion regions (intensity only)\n\n" +
			"Press “T” to add each ROI.\n" +
			"Click “OK” when finished.\n" +
			"Then choose the next action in the dropdown dialog.";

		T_ddLabel  = "Next action";
		T_ddNext   = "Next image (continue sampling)";
		T_ddStep   = "Finish target sampling and proceed (compute defaults)";
		T_ddCompute= "Finish exclusion sampling and compute (open parameters)";
		T_ddExit   = "Exit script";

		T_ddInfo_target =
			"Select the next action (dropdown):\n\n" +
			"• Next image: continue sampling on the next image.\n" +
			"• Finish target sampling and proceed: stop sampling and infer default parameters from collected samples.\n" +
			"• Exit script: terminate immediately (batch analysis will not run).\n\n" +
			"Note: Click “OK” to confirm.";

		T_ddInfo_excl =
			"Select the next action (dropdown):\n\n" +
			"• Next image: continue sampling on the next image.\n" +
			"• Finish exclusion sampling and compute: stop exclusion sampling and open the Parameters dialog.\n" +
			"• Exit script: terminate immediately.\n\n" +
			"Note: Click “OK” to confirm.";

		T_param    = "Parameters";
		T_param_note_title = "Rationale and notes";
		T_section_target = "Target beads";
		T_section_bg     = "Background";
		T_section_roi    = "Cell ROI";
		T_section_excl   = "Exclusion (optional)";

		T_minA     = "Target bead minimum area (px^2)";
		T_maxA     = "Target bead maximum area (px^2)";
		T_circ     = "Target bead minimum circularity (0–1)";
		T_allow_clumps = "Estimate bead counts from clumps by area";

		T_strict   = "Detection strictness";
		T_strict_S = "Strict (reduce false positives)";
		T_strict_N = "Normal (recommended)";
		T_strict_L = "Loose (reduce false negatives)";

		T_roll     = "Background Rolling Ball radius";
		T_suffix   = "Cell ROI file suffix (without extension)";

		T_excl_enable    = "Enable exclusion filter (intensity threshold)";
		T_excl_thr       = "Exclusion threshold (0–255)";
		T_excl_mode      = "Exclusion direction";
		T_excl_high      = "Exclude brighter objects (intensity ≥ threshold)";
		T_excl_low       = "Exclude darker objects (intensity ≤ threshold)";

		T_excl_size_gate = "Apply exclusion only within an exclusion size range (recommended)";
		T_excl_minA      = "Exclusion minimum area (px^2)";
		T_excl_maxA      = "Exclusion maximum area (px^2)";

		T_beads_type_title = "Object type confirmation";
		T_beads_type_msg =
			"Confirm whether multiple bead types or confounding objects are present.\n\n" +
			"• Single bead type: exclusion is typically unnecessary.\n" +
			"• Multiple bead types / confounders: exclusion is recommended; run exclusion sampling.\n\n" +
			"Note: You can still disable exclusion later in the Parameters dialog.";
		T_beads_type_checkbox = "Multiple bead types present (enable exclusion)";

		T_excl_note_few_samples   = "Not enough intensity samples (<3). The inferred threshold is unreliable; set it manually.";
		T_excl_note_few_effective = "Not enough effective intensity samples (possible saturation). The inferred threshold is unreliable; set it manually.";
		T_excl_note_diff_small    = "Target/exclusion intensity difference is too small (<8). The inferred threshold is unreliable; set it manually.";
		T_excl_note_overlap_high  = "Distributions overlap substantially; a conservative threshold was chosen (near exclusion low quantile). Review recommended.";
		T_excl_note_good_sep_high = "Separation is good; threshold estimated from target high quantile and exclusion low quantile.";
		T_excl_note_overlap_low   = "Distributions overlap substantially; a conservative threshold was chosen (near exclusion high quantile). Review recommended.";
		T_excl_note_good_sep_low  = "Separation is good; threshold estimated from target low quantile and exclusion high quantile.";

		T_err_need_window =
			"The required window was not found at stage [%stage].\n\n" +
			"Window: %w\n" +
			"File: %f\n\n" +
			"Recommendation: Close any window with the same title and retry to avoid title collisions.";
		T_err_too_many_cells = "Cell ROI count exceeds 255:";
		T_err_too_many_cells_hint = "This implementation encodes labels in the range 1..255. Process in smaller batches or reduce the ROI count.";
		T_err_file = "File:";
		T_err_roi1_invalid = "ROI[1] is invalid (no valid bounds). Cannot generate the cell label image.";
		T_err_labelmask_failed = "Cell label image generation failed: the center pixel is still 0 after filling.";
		T_err_labelmask_hint = "Verify that ROI[1] is a closed area ROI and overlaps the image content.";

		T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
		T_log_start           = "✓ Start: Macrophage four-factor analysis";
		T_log_lang            = "  ├─ Language: English";
		T_log_dir             = "  ├─ Folder: selected";
		T_log_mode            = "  └─ Mode: %s";
		T_log_roi_phase_start = "✓ Step: Cell ROI annotation";
		T_log_roi_phase_done  = "✓ Complete: Cell ROI annotation";
		T_log_sampling_start  = "✓ Step: Target bead sampling";
		T_log_sampling_cancel = "✓ Complete: Sampling (finished by user)";
		T_log_sampling_img    = "  ├─ Sample [%i/%n]: %f";
		T_log_sampling_rois   = "  │  └─ ROI count: %i";
		T_log_params_calc     = "✓ Complete: Default parameters inferred";
		T_log_main_start      = "✓ Start: Batch analysis (silent mode)";
		T_log_processing      = "  ├─ Processing [%i/%n]: %f";
		T_log_missing_roi     = "  │  ⚠ Missing ROI: %f";
		T_log_missing_choice  = "  │  └─ Action: %s";
		T_log_load_roi        = "  │  ├─ Load ROI";
		T_log_roi_count       = "  │  │  └─ Cell count: %i";
		T_log_bead_detect     = "  │  ├─ Detect beads and compute statistics";
		T_log_bead_count      = "  │  │  ├─ Total beads: %i";
		T_log_bead_incell     = "  │  │  ├─ Beads in cells: %i";
		T_log_cell_withbead   = "  │  │  └─ Cells with beads: %i";
		T_log_complete        = "  │  └─ ✓ Done";
		T_log_skip_roi        = "  │  ✗ Skipped: missing ROI";
		T_log_skip_nocell     = "  │  ✗ Skipped: no valid cells in ROI";
		T_log_results_save    = "✓ Complete: Results written to the Results table";
		T_log_all_done        = "✓✓✓ All tasks completed ✓✓✓";
		T_log_summary         = "📊 Summary: %i images processed";
		T_log_unit_sync_keep  = "  └─ Bead scale: using inferred value = %s";
		T_log_unit_sync_ui    = "  └─ Bead scale: manual change detected; using UI midpoint = %s";

		T_reason_no_target = "No target bead sampling was performed: using default bead scale and default Rolling Ball.";
		T_reason_target_ok = "Bead scale and Rolling Ball were inferred from target samples (robust estimation).";
		T_reason_excl_on   = "Exclusion is enabled: threshold inferred from exclusion samples (adjust manually if flagged unreliable).";
		T_reason_excl_off  = "Exclusion is disabled.";
		T_reason_excl_size_ok = "Exclusion size range inferred from exclusion bead samples.";
		T_reason_excl_size_off= "Not enough exclusion bead size samples: size gate is disabled by default.";

		T_mottos = newArray(
			"\"Seek truth from facts\"",
			"\"Integrate theory with practice\"",
			"\"Truth comes from practice\"",
			"\"Analyze concrete problems concretely\"",
			"\"Progress from shallow to deep\"",
			"\"Advance step by step\"",
			"\"Verify in practice\"",
			"\"Knowledge originates from practice\""
		);
	}

	// =========================================================================
	// Mode selection (unchanged)
	// =========================================================================
	Dialog.create(T_mode_title);
	Dialog.addMessage(T_mode_msg);
	Dialog.addChoice(T_mode_label, newArray(T_mode_1, T_mode_2, T_mode_3), T_mode_3);
	Dialog.show();
	modeChoice = Dialog.getChoice();

	doROI     = (modeChoice == T_mode_1) || (modeChoice == T_mode_3);
	doAnalyze = (modeChoice == T_mode_2) || (modeChoice == T_mode_3);

	// =========================================================================
	// Folder & file list (MODIFIED ordering policy)
	// =========================================================================
	dir = getDirectory(T_choose);
	if (dir == "") exit(T_exit);

	rawList = getFileList(dir);

	imgFiles = newArray();
	k = 0;
	while (k < rawList.length) {
		name = rawList[k];
		if (!endsWith(toLowerCase(name), ".zip")) {
			if (isImageFile(name)) imgFiles[imgFiles.length] = name;
		}
		k = k + 1;
	}
	if (imgFiles.length == 0) exit(T_noImages);

	// -------------------------------------------------------------------------
	// Order policy:
	// - Cell ROI annotation, batch analysis, and output: SORTED by filename
	// - Target/Exclusion sampling: SHUFFLED order
	// -------------------------------------------------------------------------
	imgFilesSorted = newArray(imgFiles.length);
	k = 0;
	while (k < imgFiles.length) { imgFilesSorted[k] = imgFiles[k]; k = k + 1; }
	Array.sort(imgFilesSorted);

	imgFilesSample = newArray(imgFilesSorted.length);
	k = 0;
	while (k < imgFilesSorted.length) { imgFilesSample[k] = imgFilesSorted[k]; k = k + 1; }

	k = imgFilesSample.length - 1;
	while (k > 0) {
		j = floor(random() * (k + 1));
		swap = imgFilesSample[k]; imgFilesSample[k] = imgFilesSample[j]; imgFilesSample[j] = swap;
		k = k - 1;
	}

	roiSuffix  = "_cells";
	nTotalImgs = imgFilesSorted.length;

	bases    = newArray(nTotalImgs);
	roiPaths = newArray(nTotalImgs);
	k = 0;
	while (k < nTotalImgs) {
		bases[k]    = getBaseName(imgFilesSorted[k]);
		roiPaths[k] = dir + bases[k] + roiSuffix + ".zip";
		k = k + 1;
	}

	log(T_log_sep);
	log(T_log_start);
	log(T_log_lang);
	log(T_log_dir);
	log(replace(T_log_mode, "%s", modeChoice));
	log(T_log_sep);

	run("ROI Manager...");

	// =========================================================================
	// ROI phase (sorted)
	// =========================================================================
	SKIP_ALL_EXISTING_ROI = 0;

	if (doROI) {
		waitForUser(T_step_roi_title, replace(T_step_roi_msg, "%s", roiSuffix));
		log(T_log_roi_phase_start);

		k = 0;
		while (k < nTotalImgs) {
			SKIP_ALL_EXISTING_ROI = annotateCellsSmart(dir, imgFilesSorted[k], roiSuffix, k + 1, nTotalImgs, SKIP_ALL_EXISTING_ROI);
			k = k + 1;
		}

		log(T_log_roi_phase_done);
		log(T_log_sep);
	}

	if (doROI && !doAnalyze) {
		maybePrintMotto();
		exit("");
	}

	// =========================================================================
	// Sampling + Params (sampling shuffled)
	// =========================================================================
	waitForUser(T_step_bead_title, T_step_bead_msg);
	log(T_log_sampling_start);

	Dialog.create(T_beads_type_title);
	Dialog.addMessage(T_beads_type_msg);
	Dialog.addCheckbox(T_beads_type_checkbox, false);
	Dialog.show();
	HAS_MULTI_BEADS = Dialog.getCheckbox();

	targetAreas = newArray();
	targetMeans = newArray();
	exclMeansAll  = newArray();
	exclAreasBead = newArray();

	DEF_MINA = 5;
	DEF_MAXA = 200;
	DEF_CIRC = 0;
	DEF_ROLL = 50;

	run("Set Measurements...", "area mean redirect=None decimal=3");

	// ---------- TARGET sampling ----------
	s = 0;
	while (s < nTotalImgs) {

		imgName = imgFilesSample[s];
		printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, imgName);

		open(dir + imgName);
		ensure2D();
		forcePixelUnit();
		origTitle = getTitle();

		setTool("oval");
		roiManager("Reset");
		roiManager("Show All");

		msg = T_promptAddROI;
		msg = replace(msg, "%i", "" + (s + 1));
		msg = replace(msg, "%n", "" + nTotalImgs);
		msg = replace(msg, "%f", imgName);
		waitForUser(T_sampling + " - " + imgName, msg);

		Dialog.create(T_sampling + " - " + imgName);
		Dialog.addMessage(T_ddInfo_target);
		Dialog.addChoice(T_ddLabel, newArray(T_ddNext, T_ddStep, T_ddExit), T_ddNext);
		Dialog.show();
		act = Dialog.getChoice();

		if (act == T_ddExit) {
			selectWindow(origTitle); close();
			exit(T_exitScript);
		}

		nR = roiManager("count");
		log(replace(T_log_sampling_rois, "%i", "" + nR));

		if (nR > 0) {
			run("Clear Results");
			safeClose("__tmp8_target");
			selectWindow(origTitle);
			run("Duplicate...", "title=__tmp8_target");
			requireWindow("__tmp8_target", "sampling/target/tmp8", imgName);
			run("8-bit");

			run("Clear Results");
			roiManager("Measure");
			updateResults();

			if (nResults > 0) {
				row = 0;
				while (row < nResults) {
					targetAreas[targetAreas.length] = getResult("Area", row);
					targetMeans[targetMeans.length] = getResult("Mean", row);
					row = row + 1;
				}
			}

			run("Clear Results");
			selectWindow("__tmp8_target"); close();
		}

		selectWindow(origTitle); close();

		if (act == T_ddStep) {
			log(T_log_sampling_cancel);
			break;
		}

		s = s + 1;
	}

	// ---------- EXCLUSION sampling ----------
	if (HAS_MULTI_BEADS) {

		waitForUser(T_step_bead_ex_title, T_step_bead_ex_msg);

		s = 0;
		while (s < nTotalImgs) {

			imgName = imgFilesSample[s];
			printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, imgName);

			open(dir + imgName);
			ensure2D();
			forcePixelUnit();
			origTitle = getTitle();

			roiManager("Reset");
			roiManager("Show All");

			msg = T_promptAddROI_EX;
			msg = replace(msg, "%i", "" + (s + 1));
			msg = replace(msg, "%n", "" + nTotalImgs);
			msg = replace(msg, "%f", imgName);
			waitForUser(T_sampling + " - " + imgName, msg);

			Dialog.create(T_sampling + " - " + imgName);
			Dialog.addMessage(T_ddInfo_excl);
			Dialog.addChoice(T_ddLabel, newArray(T_ddNext, T_ddCompute, T_ddExit), T_ddNext);
			Dialog.show();
			act = Dialog.getChoice();

			if (act == T_ddExit) {
				selectWindow(origTitle); close();
				exit(T_exitScript);
			}

			nR = roiManager("count");
			log(replace(T_log_sampling_rois, "%i", "" + nR));

			if (nR > 0) {

				run("Clear Results");
				safeClose("__tmp8_excl");
				selectWindow(origTitle);
				run("Duplicate...", "title=__tmp8_excl");
				requireWindow("__tmp8_excl", "sampling/excl/tmp8", imgName);
				run("8-bit");

				run("Clear Results");
				roiManager("Measure");
				updateResults();

				beadUnitAreaGuess = (DEF_MINA + DEF_MAXA) / 2;
				if (targetAreas.length > 0) {
					rng0 = estimateAreaRangeSafe(targetAreas, DEF_MINA, DEF_MAXA);
					beadUnitAreaGuess = rng0[2];
				}
				if (beadUnitAreaGuess < 1) beadUnitAreaGuess = 1;

				rowLast = nResults - 1;
				row = 0;
				while (row <= rowLast) {
					a = getResult("Area", row);
					mm = getResult("Mean", row);

					exclMeansAll[exclMeansAll.length] = mm;

					isBead = 1;
					if (a >= beadUnitAreaGuess * 20) isBead = 0;

					if (isBead == 1) {
						exclAreasBead[exclAreasBead.length] = a;
					}

					row = row + 1;
				}

				run("Clear Results");
				selectWindow("__tmp8_excl"); close();
			}

			selectWindow(origTitle); close();

			if (act == T_ddCompute) {
				log(T_log_sampling_cancel);
				break;
			}

			s = s + 1;
		}
	}

	log(T_log_sep);

	// =========================================================================
	// Defaults + reason message
	// =========================================================================
	reasonMsg = "";

	defMinA = DEF_MINA;
	defMaxA = DEF_MAXA;
	defCirc = DEF_CIRC;
	defRoll = DEF_ROLL;

	beadUnitArea = (defMinA + defMaxA) / 2;
	if (beadUnitArea < 1) beadUnitArea = 1;

	defAllowClumps = 1;

	useExcl = 0;
	exclMode = "HIGH";
	exclThr  = 255;

	useExclSizeGate = 1;
	defExMinA = DEF_MINA;
	defExMaxA = DEF_MAXA;

	if (targetAreas.length == 0) {
		reasonMsg = reasonMsg + "• " + T_reason_no_target + "\n";
	} else {
		range = estimateAreaRangeSafe(targetAreas, DEF_MINA, DEF_MAXA);
		defMinA = range[0];
		defMaxA = range[1];
		beadUnitArea = range[2];
		defRoll = estimateRollingFromUnitArea(beadUnitArea);
		reasonMsg = reasonMsg + "• " + T_reason_target_ok + "\n";
	}

	if (HAS_MULTI_BEADS) {
		useExcl = 1;

		exInfo = estimateExclusionSafe(targetMeans, exclMeansAll);
		exclMode = exInfo[1];
		exclThr  = exInfo[2];

		reasonMsg = reasonMsg + "• " + T_reason_excl_on + "\n";
		reasonMsg = reasonMsg + "  - " + exInfo[4] + "\n";

		if (exclAreasBead.length > 0) {
			exRange = estimateAreaRangeSafe(exclAreasBead, DEF_MINA, DEF_MAXA);
			defExMinA = exRange[0];
			defExMaxA = exRange[1];
			reasonMsg = reasonMsg + "• " + T_reason_excl_size_ok + "\n";
		} else {
			defExMinA = DEF_MINA;
			defExMaxA = DEF_MAXA;
			useExclSizeGate = 0;
			reasonMsg = reasonMsg + "• " + T_reason_excl_size_off + "\n";
		}
	} else {
		useExcl = 0;
		reasonMsg = reasonMsg + "• " + T_reason_excl_off + "\n";
	}

	log(T_log_params_calc);

	// =========================================================================
	// Parameter confirmation
	// =========================================================================
	waitForUser(T_step_param_title, T_step_param_msg);

	if (exclMode == "LOW") exclModeDefault = T_excl_low;
	else exclModeDefault = T_excl_high;

	Dialog.create(T_param);
	Dialog.addMessage(T_param_note_title + ":\n" + reasonMsg);

	Dialog.addMessage("---- " + T_section_target + " ----");
	Dialog.addNumber(T_minA, defMinA);
	Dialog.addNumber(T_maxA, defMaxA);
	Dialog.addNumber(T_circ, defCirc);
	Dialog.addCheckbox(T_allow_clumps, (defAllowClumps == 1));

	Dialog.addChoice(T_strict, newArray(T_strict_S, T_strict_N, T_strict_L), T_strict_N);

	Dialog.addMessage("---- " + T_section_bg + " ----");
	Dialog.addNumber(T_roll, defRoll);

	Dialog.addMessage("---- " + T_section_roi + " ----");
	Dialog.addString(T_suffix, roiSuffix);

	Dialog.addMessage("---- " + T_section_excl + " ----");
	Dialog.addCheckbox(T_excl_enable, (useExcl == 1));
	Dialog.addChoice(T_excl_mode, newArray(T_excl_high, T_excl_low), exclModeDefault);
	Dialog.addNumber(T_excl_thr, exclThr);

	Dialog.addCheckbox(T_excl_size_gate, (useExclSizeGate == 1));
	Dialog.addNumber(T_excl_minA, defExMinA);
	Dialog.addNumber(T_excl_maxA, defExMaxA);

	Dialog.show();

	beadMinArea   = Dialog.getNumber();
	beadMaxArea   = Dialog.getNumber();
	beadMinCirc   = Dialog.getNumber();

	if (Dialog.getCheckbox()) allowClumpsTarget = 1;
	else allowClumpsTarget = 0;

	strictChoice  = Dialog.getChoice();
	rollingRadius = Dialog.getNumber();
	roiSuffix     = Dialog.getString();

	if (Dialog.getCheckbox()) useExclUI = 1;
	else useExclUI = 0;

	exModeChoice  = Dialog.getChoice();
	exThrUI       = Dialog.getNumber();

	if (Dialog.getCheckbox()) useExclSizeGateUI = 1;
	else useExclSizeGateUI = 0;

	exclMinA_UI   = Dialog.getNumber();
	exclMaxA_UI   = Dialog.getNumber();

	k = 0;
	while (k < nTotalImgs) {
		roiPaths[k] = dir + bases[k] + roiSuffix + ".zip";
		k = k + 1;
	}

	// =========================================================================
	// beadUnitArea sync with UI (FIXED: only if user changed dialog values)
	// =========================================================================
	EPS_A = 0.000001;

	USER_CHANGED_UNIT = 0;
	if (abs2(beadMinArea - defMinA) > EPS_A) USER_CHANGED_UNIT = 1;
	if (abs2(beadMaxArea - defMaxA) > EPS_A) USER_CHANGED_UNIT = 1;

	uiMid = (beadMinArea + beadMaxArea) / 2.0;
	if (uiMid < 1) uiMid = 1;

	if (USER_CHANGED_UNIT == 1) {
		beadUnitArea = uiMid;
		log(replace(T_log_unit_sync_ui, "%s", "" + beadUnitArea));
	} else {
		log(replace(T_log_unit_sync_keep, "%s", "" + beadUnitArea));
	}

	if (beadUnitArea < 1) beadUnitArea = 1;

	// strictness-dependent effective thresholds (unchanged)
	effMinArea = beadMinArea;
	effMaxArea = beadMaxArea;
	effMinCirc = beadMinCirc;

	if (strictChoice == T_strict_S) {
		effMinArea = beadMinArea * 0.85;
		effMaxArea = beadMaxArea * 1.20;
		effMinCirc = beadMinCirc + 0.08;
	} else if (strictChoice == T_strict_N) {
		effMinArea = beadMinArea * 0.65;
		effMaxArea = beadMaxArea * 1.60;
		effMinCirc = beadMinCirc - 0.06;
	} else {
		effMinArea = beadMinArea * 0.50;
		effMaxArea = beadMaxArea * 2.10;
		effMinCirc = beadMinCirc - 0.14;
	}

	if (effMinArea < 1) effMinArea = 1;
	effMinArea = floor(effMinArea);
	effMaxArea = ceilInt(effMaxArea);

	if (effMinCirc < 0) effMinCirc = 0;
	if (effMinCirc > 0.95) effMinCirc = 0.95;
	if (effMaxArea <= effMinArea) effMaxArea = effMinArea + 1;

	if (useExclUI == 1) useExcl = 1;
	else useExcl = 0;

	exclThr = exThrUI;
	if (exclThr < 0) exclThr = 0;
	if (exclThr > 255) exclThr = 255;

	if (exModeChoice == T_excl_low) exclMode = "LOW";
	else exclMode = "HIGH";

	if (useExclSizeGateUI == 1) useExclSizeGate = 1;
	else useExclSizeGate = 0;

	exclMinA = floor(exclMinA_UI);
	exclMaxA = ceilInt(exclMaxA_UI);
	if (exclMinA < 1) exclMinA = 1;
	if (exclMaxA <= exclMinA) exclMaxA = exclMinA + 1;

	// =========================================================================
	// Batch analysis (sorted)
	// =========================================================================
	waitForUser(T_step_main_title, T_step_main_msg);

	log(T_log_sep);
	log(T_log_main_start);
	log(T_log_sep);

	setBatchMode(true);
	run("Set Measurements...", "area centroid redirect=None decimal=3");

	skipAllMissingROI = 0;

	imgNameA = newArray(nTotalImgs);
	allA     = newArray(nTotalImgs);
	incellA  = newArray(nTotalImgs);
	cellA    = newArray(nTotalImgs);
	allcellA = newArray(nTotalImgs);

	k = 0;
	while (k < nTotalImgs) {

		imgName = imgFilesSorted[k];
		base    = bases[k];
		roiPath = roiPaths[k];

		printWithIndex(T_log_processing, k + 1, nTotalImgs, imgName);
		imgNameA[k] = base;

		if (!File.exists(roiPath)) {

			log(replace(T_log_missing_roi, "%f", imgName));

			if (skipAllMissingROI == 0) {
				setBatchMode(false);

				Dialog.create(T_missing_title);
				mm = T_missing_msg;
				mm = replace(mm, "%f", imgName);
				mm = replace(mm, "%b", base);
				mm = replace(mm, "%s", roiSuffix);
				Dialog.addMessage(mm);
				Dialog.addChoice(
					T_missing_label,
					newArray(T_missing_anno, T_missing_skip, T_missing_skip_all, T_missing_exit),
					T_missing_anno
				);
				Dialog.show();
				missingAction = Dialog.getChoice();

				log(replace(T_log_missing_choice, "%s", missingAction));

				if (missingAction == T_missing_exit) exit(T_exitScript);

				if (missingAction == T_missing_skip_all) {
					skipAllMissingROI = 1;
					missingAction = T_missing_skip;
				}

				if (missingAction == T_missing_anno) {
					SKIP_ALL_EXISTING_ROI = annotateCellsSmart(dir, imgName, roiSuffix, k + 1, nTotalImgs, 0);
					roiPath = dir + base + roiSuffix + ".zip";
					roiPaths[k] = roiPath;
				}

				setBatchMode(true);
			}
		}

		if (!File.exists(roiPath)) {
			log(T_log_skip_roi);
			allA[k]     = "";
			incellA[k]  = "";
			cellA[k]    = "";
			allcellA[k] = "";
			k = k + 1;
			continue;
		}

		open(dir + imgName);
		ensure2D();
		forcePixelUnit();
		origID = getImageID();

		roiManager("Reset");
		roiManager("Open", roiPath);
		nCellsAll = roiManager("count");

		if (nCellsAll == 0) {
			log(T_log_skip_nocell);
			close();
			allA[k]     = "";
			incellA[k]  = "";
			cellA[k]    = "";
			allcellA[k] = "";
			k = k + 1;
			continue;
		}

		log(T_log_load_roi);
		log(replace(T_log_roi_count, "%i", "" + nCellsAll));

		w = getWidth();
		h = getHeight();

		selectImage(origID);
		safeClose("__bead_gray");
		run("Duplicate...", "title=__bead_gray");
		requireWindow("__bead_gray", "main/bead_gray", imgName);
		run("8-bit");
		if (rollingRadius > 0) run("Subtract Background...", "rolling=" + rollingRadius);

		cellLabelTitle = "__cellLabel";
		HAS_LABEL_MASK = buildCellLabelMaskFromOriginal(cellLabelTitle, origID, w, h, nCellsAll, imgName);

		flat = detectBeadsFusion("__bead_gray", strictChoice, effMinArea, effMaxArea, effMinCirc, beadUnitArea, imgName);

		cnt = countBeadsByFlat(
			flat, cellLabelTitle, nCellsAll, w, h, HAS_LABEL_MASK,
			beadUnitArea, allowClumpsTarget,
			useExcl, exclMode, exclThr,
			useExclSizeGate, exclMinA, exclMaxA,
			"__bead_gray", imgName
		);

		nBeadsAll = cnt[0];
		nBeadsInCells = cnt[1];
		nCellsWithBead = cnt[2];

		log(T_log_bead_detect);
		log(replace(T_log_bead_count, "%i", "" + nBeadsAll));
		log(replace(T_log_bead_incell, "%i", "" + nBeadsInCells));
		log(replace(T_log_cell_withbead, "%i", "" + nCellsWithBead));

		allA[k]     = nBeadsAll;
		incellA[k]  = nBeadsInCells;
		cellA[k]    = nCellsWithBead;
		allcellA[k] = nCellsAll;

		log(T_log_complete);

		safeClose("__bead_gray");
		safeClose(cellLabelTitle);
		selectImage(origID); close();
		run("Clear Results");

		k = k + 1;
	}

	setBatchMode(false);

	// =========================================================================
	// Output (unchanged)
	// =========================================================================
	log(T_log_sep);
	log(T_log_results_save);

	run("Clear Results");

	k = 0;
	while (k < nTotalImgs) {
		setResult("Image",            k, "" + imgNameA[k]);
		setResult("Total Beads",      k, allA[k]);
		setResult("Beads in Cells",   k, incellA[k]);
		setResult("Cells with Beads", k, cellA[k]);
		setResult("Total Cells",      k, allcellA[k]);
		k = k + 1;
	}
	updateResults();

	log(T_log_sep);
	log(T_log_all_done);
	log(replace(T_log_summary, "%i", "" + nTotalImgs));
	log(T_log_sep);

	maybePrintMotto();
}
