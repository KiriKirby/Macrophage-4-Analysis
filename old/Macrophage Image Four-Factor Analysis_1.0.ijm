macro "巨噬细胞图像四元素值分�? {

	// ══════════════════════════════════════════════════════════════════════�?
	// 语言选择 | 言語選�?
	// ══════════════════════════════════════════════════════════════════════�?
	Dialog.create("Language / 言�?/ 语言");
	Dialog.addMessage(
		"巨噬细胞图像四元素值分析\n" +
		"Macrophage Image Four-Factor Analysis\n" +
		"マクロファージ画�?要素解析\n\n" +
		"Version: 1.0\n" +
		"Author: Nishikata Lab 王舒扬\n" +
		"---------------------------------\n" +
		"请选择界面语言 / 言語を選択 / Select language"
	);
	Dialog.addChoice("Language", newArray("中文", "日本�?, "English"), "中文");
	Dialog.show();
	lang = Dialog.getChoice();


	// ══════════════════════════════════════════════════════════════════════�?
	// 全局开�?| グローバル設�?
	// ══════════════════════════════════════════════════════════════════════�?
	ENABLE_MOTTO_CN   = 1;
	ENABLE_MOTTO_ENJP = 0;
	LOG_VERBOSE       = 1;


	// ══════════════════════════════════════════════════════════════════════�?
	// 工具函数 | ユーティリテ�?
	// ══════════════════════════════════════════════════════════════════════�?
	function log(s) {
		if (LOG_VERBOSE) print(s);
	}

	function isImageFile(filename) {
		lname = toLowerCase(filename);
		return (
			endsWith(lname, ".tif")  ||
			endsWith(lname, ".tiff") ||
			endsWith(lname, ".png")  ||
			endsWith(lname, ".jpg")  ||
			endsWith(lname, ".jpeg")
		);
	}

	function getBaseName(filename) {
		dot = lastIndexOf(filename, ".");
		if (dot > 0) return substring(filename, 0, dot);
		return filename;
	}

	function printWithIndex(template, iVal, nVal, fVal) {
		s = replace(template, "%i", "" + iVal);
		s = replace(s, "%n", "" + nVal);
		s = replace(s, "%f", fVal);
		log(s);
	}

	function forcePixelUnit() {
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	}

	function ceilInt(x) {
		f = floor(x);
		if (x == f) return f;
		if (x > 0) return f + 1;
		return f;
	}

	function quantileSorted(arr, q) {
		n = arr.length;
		if (n <= 1) return arr[0];
		pos = (n - 1) * q;
		lo  = floor(pos);
		hi  = ceilInt(pos);
		if (hi == lo) return arr[lo];
		return arr[lo] + (arr[hi] - arr[lo]) * (pos - lo);
	}

	function idxImageTypeByCellCount(nCells) {
		if (nCells <= 255) return "8-bit black";
		if (nCells <= 65535) return "16-bit black";
		return "32-bit black";
	}

	function annotateCellsAndSave(dir, imgName, roiSuffix, idx, total) {
		open(dir + imgName);
		forcePixelUnit();

		base = getBaseName(imgName);

		roiManager("Reset");
		roiManager("Show All");

		msg = T_cell_msg;
		msg = replace(msg, "%i", "" + idx);
		msg = replace(msg, "%n", "" + total);
		msg = replace(msg, "%f", imgName);
		msg = replace(msg, "%s", roiSuffix);

		waitForUser(T_cell_title, msg);

		if (roiManager("count") > 0) {
			roiManager("Save", dir + base + roiSuffix + ".zip");
		}

		close();
	}

	function maybePrintMotto(lang) {
		if (
			(lang == "中文" && ENABLE_MOTTO_CN) ||
			(lang != "中文" && ENABLE_MOTTO_ENJP)
		) {
			if (T_mottos.length > 0) {
				motto_index = floor(random() * T_mottos.length);
				log("");
				log(T_mottos[motto_index]);
				log("");
			}
		}
	}


	// ══════════════════════════════════════════════════════════════════════�?
	// 多语言文本 | 多言語テキス�?
	// ══════════════════════════════════════════════════════════════════════�?
	if (lang == "中文") {

		T_choose     = "选择包含图像�?ROI 的文件夹";
		T_exit       = "未选择文件夹，程序已退出�?;
		T_noImages   = "文件夹中未检测到图像文件，程序已退出�?;
		T_exitScript = "用户选择退出脚本，程序已结束�?;

		T_mode_title = "工作模式";
		T_mode_label = "模式";
		T_mode_1     = "仅标画细�?ROI（生�?*_cells.zip�?;
		T_mode_2     = "仅分析四要素（需要已有细�?ROI�?;
		T_mode_3     = "标画细胞 ROI 后分析四要素（推荐）";
		T_mode_msg   =
			"请选择本次工作模式（下拉菜单）：\n\n" +
			"1）仅标画细胞 ROI：\n" +
			"   - 逐张打开图像，手动勾画细胞轮廓并保存 ROI\n" +
			"   - 默认 ROI 文件名：图片�?+ \"_cells.zip\"\n\n" +
			"2）仅分析四要素：\n" +
			"   - 直接进行磁珠检测与四要素统计\n" +
			"   - 必须存在对应细胞 ROI（默认：图片�?+ \"_cells.zip\"）\n\n" +
			"3）标画细�?ROI 后分析四要素：\n" +
			"   - 先生�?补齐细胞 ROI（默认：图片�?+ \"_cells.zip\"）\n" +
			"   - 再标注磁珠样本并进行四要素分析\n\n" +
			"注意：请使用 OK 确认选择；不要点 Cancel，否则可能导致流程状态异常�?;

		T_step_roi_title = "下一步：细胞 ROI 标注";
		T_step_roi_msg =
			"现在将进入【细�?ROI 标注】阶段。\n\n" +
			"你需要：\n" +
			"1）用你当前选中的工具勾画细胞轮廓（推荐自由手绘）\n" +
			"2）每画完一个细胞轮廓，�?T �?ROI 加入 ROI Manager\n" +
			"3）完成当前图像后，在提示窗口�?OK 进入下一张\n\n" +
			"说明：本宏不会自动切换绘图工具。\n" +
			"注意：请不要�?Cancel，否则可能导致程序状态异�?结果不完整�?;

		T_step_bead_title = "下一步：磁珠抽样标注";
		T_step_bead_msg =
			"现在将进入【磁珠抽样标注】阶段。\n\n" +
			"你需要：\n" +
			"1）使用椭圆工具快速圈出磁珠（精度无需很高）\n" +
			"2）每圈完一个磁珠，�?T �?ROI 加入 ROI Manager\n" +
			"3）当前图像标注结束后：在本窗口点 OK\n" +
			"4）随后会出现下拉菜单窗口，选择：下一�?/ 结束并计�?/ 退出脚本\n\n" +
			"注意：请不要�?Cancel，否则可能导致程序状态异�?结果不完整�?;

		T_step_param_title = "下一步：确认参数";
		T_step_param_msg =
			"现在将进入【参数确认】窗口。\n\n" +
			"说明：\n" +
			"- 默认值会根据你抽样圈选的磁珠面积分布自动估计，并留出自适应余地\n" +
			"- 可根据实验需要手动修改\n\n" +
			"注意：请�?OK 确认�?;

		T_step_main_title = "下一步：批量分析";
		T_step_main_msg =
			"现在将进入【批量分析】阶段。\n\n" +
			"说明：\n" +
			"- 宏会对文件夹内所有图像进行磁珠检测与四要素统计\n" +
			"- 若某张图像缺少细�?ROI，会弹出窗口询问：现在标�?/ 跳过 / 跳过全部 / 退出\n" +
			"- 即使跳过，该图像也会在最终结果表保留一行（值为空）\n\n" +
			"注意：请�?OK 开始�?;

		T_cell_title = "细胞轮廓标注";
		T_cell_msg =
			"当前进度：第 %i / %n 张\n" +
			"文件名：%f\n\n" +
			"请手动勾画细胞轮廓。\n" +
			"每画完一个轮廓，请按 T 加入 ROI。\n\n" +
			"完成后点�?OK 继续下一张。\n\n" +
			"ROI 保存规则：图片名 + \"%s.zip\"（默认：_cells.zip）\n" +
			"说明：本宏不会自动切换绘图工具。\n" +
			"注意：请不要点击 Cancel，否则可能导致流程状态异�?结果不完整�?;

		T_missing_title    = "缺少细胞 ROI";
		T_missing_label    = "处理方式";
		T_missing_anno     = "现在标注细胞 ROI（并继续分析�?;
		T_missing_skip     = "跳过此图像（结果表保留空值）";
		T_missing_skip_all = "跳过所有缺 ROI 的图像（后续不再提示�?;
		T_missing_exit     = "退出脚�?;
		T_missing_msg      =
			"检测到下列图像缺少对应的细�?ROI 文件：\n" +
			"【图像�?f\n" +
			"【期�?ROI�?b%s.zip\n\n" +
			"分析四要素需要细�?ROI。\n" +
			"请选择处理方式（下拉菜单）：\n" +
			"1）现在标注细�?ROI：打开图像，手动勾画后保存，再继续分析\n" +
			"2）跳过此图像：不分析该图像，结果表保留空值\n" +
			"3）跳过全部缺 ROI：后续不再提示，统一保留空值\n" +
			"4）退出脚本：立即结束\n\n" +
			"注意：请使用 OK 确认选择；不要点 Cancel，否则可能导致流程状态异常�?;

		T_sampling = "抽样阶段";
		T_promptAddROI =
			"【进度】第 %i/%n 张图像\n【文件�?f\n\n" +
			"操作说明：\n" +
			"1. 使用椭圆工具快速标注磁珠（精度无需很高）\n" +
			"2. 保存 ROI：点�?ROI Manager 的「Add」按钮，或按键盘「T」键\n" +
			"3. 标注完成后：请点击此窗口的「OK」继续\n\n" +
			"注意：请不要点击「Cancel」，否则可能导致程序状态异�?结果不完整。\n" +
			"下一步（下一�?结束并计�?退出脚本）将在随后下拉菜单窗口中选择�?;

		T_gdMessage =
			"请选择下一步操作（下拉菜单）：\n" +
			"【下一张】继续抽样下一张图像\n" +
			"【结束抽样并计算】停止抽样，使用已标注样本计算默认参数\n" +
			"【退出脚本】立即结束脚本\n\n" +
			"注意：此窗口也请不要�?Cancel，使�?OK 确认选择�?;

		T_gdNext   = "下一�?;
		T_gdCancel = "结束抽样并计�?;
		T_gdExit   = "退出脚�?;

		T_param    = "参数设置";
		T_minA     = "Bead 最小面积（像素²�?;
		T_maxA     = "Bead 最大面积（像素²�?;
		T_circ     = "Bead 最小圆形度�?-1�?;
		T_strict   = "磁珠判定严格程度";
		T_strict_S = "严格（更少误检�?;
		T_strict_N = "正常（推荐，略宽松）";
		T_strict_L = "宽松（尽量都算）";
		T_roll     = "背景 Rolling Ball 半径";
		T_suffix   = "细胞 ROI 文件后缀（不含扩展名�?;
		T_debug    = "调试模式（保留处理图像并添加 ROI�?;

		T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
		T_log_start           = "�?开始处理任�?;
		T_log_lang            = "  ├─ 语言：中�?;
		T_log_dir             = "  ├─ 文件夹已选择";
		T_log_mode            = "  └─ 模式�?s";
		T_log_roi_phase_start = "�?进入细胞 ROI 标注阶段";
		T_log_roi_phase_done  = "�?细胞 ROI 标注阶段完成";
		T_log_sampling_start  = "�?进入磁珠抽样阶段 [随机选择图像以建立参数模型]";
		T_log_sampling_cancel = "�?抽样已结�?[用户选择结束并计算]";
		T_log_sampling_none   = "�?警告：未标注任何样本，将使用预设默认参数";
		T_log_sampling_img    = "  ├─ 样本 [%i/%n]�?f";
		T_log_sampling_rois   = "  �? └─ 标注 ROI 数量�?i �?;
		T_log_params_calc     = "�?参数已自动计�?;
		T_log_params_default  = "  └─ 模式：预设默认�?| Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_params_sample   = "  └─ 模式：基于样本估�?| Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_main_start      = "�?进入主处理阶�?[批量分析所有图像]";
		T_log_processing      = "  ├─ 处理 [%i/%n]�?f";
		T_log_missing_roi     = "  �? �?缺少 ROI�?f";
		T_log_missing_choice  = "  �? └─ 处理方式�?s";
		T_log_load_roi        = "  �? ├─ 加载 ROI 文件";
		T_log_roi_count       = "  �? �? └─ 细胞总数�?i �?;
		T_log_bead_detect     = "  �? ├─ 磁珠检测与统计";
		T_log_bead_count      = "  �? �? ├─ 磁珠总数�?i �?;
		T_log_bead_incell     = "  �? �? ├─ 细胞内磁珠：%i �?;
		T_log_cell_withbead   = "  �? �? └─ 吞噬磁珠细胞�?i �?;
		T_log_complete        = "  �? └─ �?完成";
		T_log_skip_roi        = "  �? �?该图像未分析 [缺少 ROI，已按选择跳过]";
		T_log_skip_nocell     = "  �? �?已跳�?[ROI 文件中无有效细胞]";
		T_log_results_save    = "�?结果已保存至结果�?;
		T_log_all_done        = "✓✓�?所有任务已完成 ✓✓�?;
		T_log_summary         = "📊 汇总：共处�?%i 张图�?;

		T_mottos = newArray(
			"\"实事求是\"",
			"\"理论联系实际\"",
			"\"实践出真知\"",
			"\"具体问题具体分析\"",
			"\"由浅入深\"",
			"\"循序渐进\"",
			"\"在实践中检验\"",
			"\"认识来源于实践\""
		);

	} else if (lang == "日本�?) {

		T_choose     = "画像�?ROI を含むフォルダを選択してくださ�?;
		T_exit       = "フォルダが選択されていません。処理を終了します�?;
		T_noImages   = "フォルダに画像ファイルが見つかりません。処理を終了します�?;
		T_exitScript = "ユーザーが終了を選択しました。スクリプトを終了します�?;

		T_mode_title = "作業モー�?;
		T_mode_label = "モー�?;
		T_mode_1     = "細胞 ROI のみ作成�?_cells.zip を生成）";
		T_mode_2     = "4要素解析のみ（既存の細胞 ROI が必要）";
		T_mode_3     = "細胞 ROI 作成後に 4要素解析（推奨）";
		T_mode_msg   =
			"作業モードを選択してください（プルダウン）：\n\n" +
			"1）細�?ROI のみ作成：\n" +
			"   - 画像を順に開き、細胞輪郭を手動で描画し�?ROI を保存\n" +
			"   - 既定�?ROI 名：画像�?+ \"_cells.zip\"\n\n" +
			"2�?要素解析のみ：\n" +
			"   - ビーズ検出と 4要素集計を実行\n" +
			"   - 対応する細胞 ROI が必須（既定：画像名 + \"_cells.zip\"）\n\n" +
			"3）細�?ROI 作成後に 4要素解析：\n" +
			"   - 先に細胞 ROI を作�?補完（既定：画像�?+ \"_cells.zip\"）\n" +
			"   - その後にビーズ抽出と解析\n\n" +
			"注意：OK で確定してください。Cancel は押さないでください（状態不整合の原因）�?;

		T_step_roi_title = "次へ：細�?ROI 作成";
		T_step_roi_msg =
			"これから【細�?ROI 作成】段階に入ります。\n\n" +
			"やること：\n" +
			"1）現在選択中のツールで細胞輪郭を描画（推奨：フリーハンド）\n" +
			"2�?細胞ごと�?T を押して ROI Manager に追加\n" +
			"3）完了後�?OK を押して次へ\n\n" +
			"説明：このマクロはツールを強制的に切り替えません。\n" +
			"注意：Cancel は押さないでください（状態不整合/結果不完全の可能性）�?;

		T_step_bead_title = "次へ：ビーズ抽出（サンプリング）";
		T_step_bead_msg =
			"これから【ビーズ抽出（サンプリング）】段階に入ります。\n\n" +
			"やること：\n" +
			"1）楕円ツールでビーズを素早くマーク（精密さは不要）\n" +
			"2�?つごとに T を押して ROI を追加\n" +
			"3）このウィンドウ�?OK で進む\n" +
			"4）続くプルダウンで「次�?/ 終了して計算 / 終了」を選択\n\n" +
			"注意：Cancel は押さないでください（状態不整合/結果不完全の可能性）�?;

		T_step_param_title = "次へ：パラメータ確認";
		T_step_param_msg =
			"次は【パラメータ確認】です。\n\n" +
			"説明：\n" +
			"- サンプリングしたビーズ面積分布からデフォルト値を推定します（自動余地あり）\n" +
			"- 必要なら手動で調整してください\n\n" +
			"OK で進みます�?;

		T_step_main_title = "次へ：バッチ解析";
		T_step_main_msg =
			"次は【バッチ解析】です。\n\n" +
			"説明：\n" +
			"- フォルダ内の全画像を解析し、結果テーブルを作成します\n" +
			"- 細胞 ROI が無い画像は「作�?スキップ/全スキッ�?終了」を尋ねます\n" +
			"- スキップしても結果表には行を残します（値は空）\n\n" +
			"OK で開始します�?;

		T_cell_title = "細胞輪郭アノテーショ�?;
		T_cell_msg =
			"進捗�?i / %n 枚目\n" +
			"ファイル名：%f\n\n" +
			"細胞輪郭を手動で描画してください。\n" +
			"1細胞ごと�?T を押して ROI に追加します。\n\n" +
			"完了後に OK を押して次へ。\n\n" +
			"ROI 保存規則：画像名 + \"%s.zip\"（既定：_cells.zip）\n" +
			"説明：このマクロはツールを強制的に切り替えません。\n" +
			"注意：Cancel は押さないでください（状態不整合/結果不完全の可能性）�?;

		T_missing_title    = "細胞 ROI が見つかりません";
		T_missing_label    = "対応";
		T_missing_anno     = "今ここで細胞 ROI を作成（続けて解析）";
		T_missing_skip     = "この画像をスキップ（結果表は空値）";
		T_missing_skip_all = "ROI不足の画像をすべてスキップ（以後表示しない）";
		T_missing_exit     = "スクリプト終�?;
		T_missing_msg      =
			"次の画像で対応する細�?ROI が見つかりません：\n" +
			"【画像�?f\n" +
			"【想�?ROI�?b%s.zip\n\n" +
			"4要素解析には細胞 ROI が必須です。\n" +
			"対応を選択してください（プルダウン）：\n" +
			"1）今ここで作成：描画→保存→解析続行\n" +
			"2）スキップ：解析せず、結果は空値\n" +
			"3）全スキップ：以後の不足確認を出さず空値\n" +
			"4）終了：直ちに終了\n\n" +
			"注意：OK で確定。Cancel は押さないでください�?;

		T_sampling = "サンプリング段階";
		T_promptAddROI =
			"【進捗�?i/%n 枚目\n【ファイル�?f\n\n" +
			"操作手順：\n" +
			"1. 楕円ツールでビーズをマーク（精密さは不要）\n" +
			"2. ROI保存：ROI Manager の「Add」または「T」\n" +
			"3. 終了後：このウィンドウは OK\n\n" +
			"注意：Cancel は押さないでください（状態不整合/結果不完全の可能性）。\n" +
			"次の選択は続くプルダウンで行います�?;

		T_gdMessage =
			"次のアクションを選択してください（プルダウン）：\n" +
			"【次へ】次の画像へ\n" +
			"【抽出終了して計算】サンプリングを終了し、デフォルトを計算\n" +
			"【スクリプト終了】ただちに終了\n\n" +
			"注意：Cancel は押さず、OK で確定してください�?;

		T_gdNext   = "次へ";
		T_gdCancel = "抽出終了して計算";
		T_gdExit   = "スクリプト終�?;

		T_param    = "パラメータ設�?;
		T_minA     = "Bead 最小面積（ピクセル²�?;
		T_maxA     = "Bead 最大面積（ピクセル²�?;
		T_circ     = "Bead 最小円形度�?-1�?;
		T_strict   = "ビーズ判定の厳し�?;
		T_strict_S = "厳格（誤検出を減らす�?;
		T_strict_N = "標準（推奨、やや緩め）";
		T_strict_L = "緩い（できるだけ拾う�?;
		T_roll     = "背景 Rolling Ball 半径";
		T_suffix   = "細胞 ROI ファイルの接尾辞（拡張子なし�?;
		T_debug    = "デバッグモード（処理画像�?ROI を保持）";

		T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
		T_log_start           = "�?タスク開�?;
		T_log_lang            = "  ├─ 言語：日本�?;
		T_log_dir             = "  ├─ フォルダが選択されました";
		T_log_mode            = "  └─ モード：%s";
		T_log_roi_phase_start = "�?細胞 ROI 作成段階に進入";
		T_log_roi_phase_done  = "�?細胞 ROI 作成段階が完了しまし�?;
		T_log_sampling_start  = "�?サンプリング段階に進入 [パラメータモデル構築用に画像をランダム選択]";
		T_log_sampling_cancel = "�?サンプリング終了 [終了して計算を選択]";
		T_log_sampling_none   = "�?警告：サンプルがありません。プリセット値を使用しま�?;
		T_log_sampling_img    = "  ├─ サンプル [%i/%n]�?f";
		T_log_sampling_rois   = "  �? └─ マークされた ROI 数：%i �?;
		T_log_params_calc     = "�?パラメータを自動計算しました";
		T_log_params_default  = "  └─ モード：プリセット�?| Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_params_sample   = "  └─ モード：サンプルから推定 | Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_main_start      = "�?メイン処理段階に進入 [すべての画像をバッチ処理]";
		T_log_processing      = "  ├─ 処理 [%i/%n]�?f";
		T_log_missing_roi     = "  �? �?ROI 不足�?f";
		T_log_missing_choice  = "  �? └─ 対応�?s";
		T_log_load_roi        = "  �? ├─ ROI ファイルをロード";
		T_log_roi_count       = "  �? �? └─ 細胞総数�?i �?;
		T_log_bead_detect     = "  �? ├─ ビーズ検出と統計";
		T_log_bead_count      = "  �? �? ├─ ビーズ総数：%i �?;
		T_log_bead_incell     = "  �? �? ├─ 細胞内ビーズ�?i �?;
		T_log_cell_withbead   = "  �? �? └─ 貪食細胞数：%i �?;
		T_log_complete        = "  �? └─ �?完了";
		T_log_skip_roi        = "  �? �?未解�?[ROI 不足のためスキップ]";
		T_log_skip_nocell     = "  �? �?スキップ [ROI に有効な細胞がありません]";
		T_log_results_save    = "�?結果をリザルトテーブルに保存しました";
		T_log_all_done        = "✓✓�?すべてのタスク完�?✓✓�?;
		T_log_summary         = "📊 サマリー：合�?%i 枚の画像を処�?;

		T_mottos = newArray(
			"\"実事求是\"",
			"\"理論と実践の統一\"",
			"\"実践から真の知識を得る\"",
			"\"具体的な問題を具体的に分析\"",
			"\"浅いから深いへ\"",
			"\"段階的に進む\"",
			"\"実践で検証する\"",
			"\"認識は実践に由来する\""
		);

	} else {

		T_choose     = "Select folder containing images and ROI files";
		T_exit       = "No folder selected. Program terminated.";
		T_noImages   = "No image files found in the folder. Program terminated.";
		T_exitScript = "User selected exit. Script terminated.";

		T_mode_title = "Work Mode";
		T_mode_label = "Mode";
		T_mode_1     = "Annotate cell ROIs only (generate *_cells.zip)";
		T_mode_2     = "Analyze four factors only (cell ROIs required)";
		T_mode_3     = "Annotate cell ROIs then analyze four factors (recommended)";
		T_mode_msg   =
			"Select work mode (dropdown):\n\n" +
			"1) Annotate cell ROIs only:\n" +
			"   - Open images one by one and draw cell outlines, then save ROIs\n" +
			"   - Default ROI name: image name + \"_cells.zip\"\n\n" +
			"2) Analyze four factors only:\n" +
			"   - Perform bead detection and compute statistics\n" +
			"   - Requires existing cell ROI file (default: image name + \"_cells.zip\")\n\n" +
			"3) Annotate cell ROIs then analyze:\n" +
			"   - Create/complete ROIs first (default: image name + \"_cells.zip\")\n" +
			"   - Then do bead sampling and analysis\n\n" +
			"Note: Confirm with OK. Do NOT click Cancel (may lead to inconsistent state).";

		T_step_roi_title = "Next: Cell ROI annotation";
		T_step_roi_msg =
			"You are entering the Cell ROI annotation phase.\n\n" +
			"What to do:\n" +
			"1) Use your currently selected drawing tool (recommended: freehand)\n" +
			"2) After each outline, press T to add ROI to ROI Manager\n" +
			"3) Click OK to proceed to next image\n\n" +
			"Note: This macro will NOT force-switch your drawing tool.\n" +
			"Do NOT click Cancel (may cause inconsistent state / incomplete results).";

		T_step_bead_title = "Next: Bead sampling annotation";
		T_step_bead_msg =
			"You are entering the bead sampling phase.\n\n" +
			"What to do:\n" +
			"1) Use the Oval Tool to mark beads (precision not critical)\n" +
			"2) After each bead, press T to add ROI\n" +
			"3) Click OK here when done\n" +
			"4) Use the following dropdown to choose Next / Finish & compute / Exit\n\n" +
			"Do NOT click Cancel (may cause inconsistent state / incomplete results).";

		T_step_param_title = "Next: Confirm parameters";
		T_step_param_msg =
			"You will now confirm analysis parameters.\n\n" +
			"Notes:\n" +
			"- Defaults are estimated from sampled bead area distribution with adaptive margin\n" +
			"- Adjust them if needed\n\n" +
			"Click OK to proceed.";

		T_step_main_title = "Next: Batch analysis";
		T_step_main_msg =
			"You are about to start batch analysis.\n\n" +
			"Notes:\n" +
			"- All images in the folder will be analyzed\n" +
			"- Missing cell ROI will prompt: annotate / skip / skip all / exit\n" +
			"- Skipped images will remain as a row with blank values\n\n" +
			"Click OK to start.";

		T_cell_title = "Cell ROI Annotation";
		T_cell_msg =
			"Progress: %i / %n\n" +
			"File: %f\n\n" +
			"Draw cell outlines manually.\n" +
			"After each outline, press T to add ROI.\n\n" +
			"Click OK to proceed.\n\n" +
			"ROI naming rule: image name + \"%s.zip\" (default: _cells.zip)\n" +
			"Note: This macro will NOT force-switch your drawing tool.\n" +
			"Do NOT click Cancel (may cause inconsistent state / incomplete results).";

		T_missing_title    = "Missing Cell ROI";
		T_missing_label    = "Action";
		T_missing_anno     = "Annotate cell ROI now (then continue analysis)";
		T_missing_skip     = "Skip this image (keep blank values in results)";
		T_missing_skip_all = "Skip all missing-ROI images (do not ask again)";
		T_missing_exit     = "Exit script";
		T_missing_msg      =
			"Cell ROI file is missing for the following image:\n" +
			"[Image] %f\n" +
			"[Expected ROI] %b%s.zip\n\n" +
			"Four-factor analysis requires a cell ROI.\n" +
			"Select action (dropdown):\n" +
			"1) Annotate now: draw, save ROI, then continue\n" +
			"2) Skip: keep blank values in final table\n" +
			"3) Skip all: do not ask again; keep blanks for all missing\n" +
			"4) Exit: terminate now\n\n" +
			"Note: Confirm with OK. Do NOT click Cancel.";

		T_sampling = "Sampling Phase";
		T_promptAddROI =
			"【Progress】Image %i of %n\n【File�?f\n\n" +
			"Instructions:\n" +
			"1) Use the Oval Tool to mark beads (precision not critical)\n" +
			"2) Save ROI: click \"Add\" in ROI Manager or press \"T\"\n" +
			"3) When done: click OK in this window\n\n" +
			"Note: Do NOT click Cancel here.\n" +
			"Next step will be chosen in the following dropdown window.";

		T_gdMessage =
			"Select next action (dropdown):\n" +
			"【Next Image】Continue sampling\n" +
			"【Finish Sampling & Compute】Stop sampling and compute defaults\n" +
			"【Exit Script】Terminate the script\n\n" +
			"Note: Please do NOT press Cancel here either; confirm using OK.";

		T_gdNext   = "Next Image";
		T_gdCancel = "Finish Sampling & Compute";
		T_gdExit   = "Exit Script";

		T_param    = "Parameters";
		T_minA     = "Bead Minimum Area (pixel²)";
		T_maxA     = "Bead Maximum Area (pixel²)";
		T_circ     = "Bead Minimum Circularity (0-1)";
		T_strict   = "Bead strictness";
		T_strict_S = "Strict (fewer false positives)";
		T_strict_N = "Normal (recommended, slightly looser)";
		T_strict_L = "Loose (count more candidates)";
		T_roll     = "Background Rolling Ball Radius";
		T_suffix   = "Cell ROI File Suffix (without extension)";
		T_debug    = "Debug Mode (keep processed images and ROIs)";

		T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
		T_log_start           = "�?Task Started";
		T_log_lang            = "  ├─ Language: English";
		T_log_dir             = "  ├─ Folder Selected";
		T_log_mode            = "  └─ Mode: %s";
		T_log_roi_phase_start = "�?Entering Cell ROI Annotation Phase";
		T_log_roi_phase_done  = "�?Cell ROI Annotation Phase Completed";
		T_log_sampling_start  = "�?Entering Sampling Phase [randomly selecting images to build parameter model]";
		T_log_sampling_cancel = "�?Sampling finished [user selected finish & compute]";
		T_log_sampling_none   = "�?Warning: No samples marked. Using preset default parameters";
		T_log_sampling_img    = "  ├─ Sample [%i/%n]: %f";
		T_log_sampling_rois   = "  �? └─ Marked ROI count: %i";
		T_log_params_calc     = "�?Parameters Auto-Calculated";
		T_log_params_default  = "  └─ Mode: Preset Values | Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_params_sample   = "  └─ Mode: Estimated from samples | Area[%i-%i] px² | Circularity[%f-1.00]";
		T_log_main_start      = "�?Entering Main Processing Phase [batch processing all images]";
		T_log_processing      = "  ├─ Processing [%i/%n]: %f";
		T_log_missing_roi     = "  �? �?Missing ROI: %f";
		T_log_missing_choice  = "  �? └─ Action: %s";
		T_log_load_roi        = "  �? ├─ Loading ROI File";
		T_log_roi_count       = "  �? �? └─ Total cells: %i";
		T_log_bead_detect     = "  �? ├─ Bead Detection and Statistics";
		T_log_bead_count      = "  �? �? ├─ Total beads: %i";
		T_log_bead_incell     = "  �? �? ├─ Beads in cells: %i";
		T_log_cell_withbead   = "  �? �? └─ Phagocytic cells: %i";
		T_log_complete        = "  �? └─ �?Completed";
		T_log_skip_roi        = "  �? �?Not analyzed [missing ROI; skipped]";
		T_log_skip_nocell     = "  �? �?Skipped [no valid cells in ROI file]";
		T_log_results_save    = "�?Results Saved to Results Table";
		T_log_all_done        = "✓✓�?All Tasks Completed ✓✓�?;
		T_log_summary         = "📊 Summary: Total %i images processed";

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


	// ══════════════════════════════════════════════════════════════════════�?
	// 模式选择 | モード選�?
	// ══════════════════════════════════════════════════════════════════════�?
	Dialog.create(T_mode_title);
	Dialog.addMessage(T_mode_msg);
	Dialog.addChoice(T_mode_label, newArray(T_mode_1, T_mode_2, T_mode_3), T_mode_3);
	Dialog.show();
	modeChoice = Dialog.getChoice();

	doROI     = (modeChoice == T_mode_1) || (modeChoice == T_mode_3);
	doAnalyze = (modeChoice == T_mode_2) || (modeChoice == T_mode_3);


	// ══════════════════════════════════════════════════════════════════════�?
	// 文件夹与图像列表 | フォルダと画像リスト
	// ══════════════════════════════════════════════════════════════════════�?
	dir = getDirectory(T_choose);
	if (dir == "") exit(T_exit);

	rawList = getFileList(dir);

	imgFiles = newArray();
	for (i = 0; i < rawList.length; i++) {
		name = rawList[i];
		if (endsWith(toLowerCase(name), ".zip")) continue;
		if (!isImageFile(name)) continue;
		imgFiles = Array.concat(imgFiles, name);
	}
	if (imgFiles.length == 0) exit(T_noImages);

	for (i = imgFiles.length - 1; i > 0; i--) {
		j = floor(random() * (i + 1));
		tmp = imgFiles[i]; imgFiles[i] = imgFiles[j]; imgFiles[j] = tmp;
	}

	roiSuffix  = "_cells";
	nTotalImgs = imgFiles.length;

	bases    = newArray(nTotalImgs);
	roiPaths = newArray(nTotalImgs);
	for (i = 0; i < nTotalImgs; i++) {
		bases[i]    = getBaseName(imgFiles[i]);
		roiPaths[i] = dir + bases[i] + roiSuffix + ".zip";
	}

	log(T_log_sep);
	log(T_log_start);
	log(T_log_lang);
	log(T_log_dir);
	log(replace(T_log_mode, "%s", modeChoice));
	log(T_log_sep);

	run("ROI Manager...");


	// ══════════════════════════════════════════════════════════════════════�?
	// 细胞 ROI 标注 | 細胞ROI作成
	// ══════════════════════════════════════════════════════════════════════�?
	if (doROI && !doAnalyze) {

		waitForUser(T_step_roi_title, T_step_roi_msg);

		log(T_log_roi_phase_start);
		for (i = 0; i < nTotalImgs; i++) {
			annotateCellsAndSave(dir, imgFiles[i], roiSuffix, i + 1, nTotalImgs);
		}
		log(T_log_roi_phase_done);

		maybePrintMotto(lang);
		exit("");
	}

	if (doROI && doAnalyze) {

		waitForUser(T_step_roi_title, T_step_roi_msg);

		log(T_log_roi_phase_start);
		for (i = 0; i < nTotalImgs; i++) {
			if (!File.exists(roiPaths[i])) {
				annotateCellsAndSave(dir, imgFiles[i], roiSuffix, i + 1, nTotalImgs);
			}
		}
		log(T_log_roi_phase_done);
		log(T_log_sep);
	}


	// ══════════════════════════════════════════════════════════════════════�?
	// 磁珠抽样 | ビーズサンプリン�?
	// ══════════════════════════════════════════════════════════════════════�?
	waitForUser(T_step_bead_title, T_step_bead_msg);

	log(T_log_sampling_start);

	sampleAreas = newArray();
	saCount = 0;

	run("Set Measurements...", "area redirect=None decimal=3");

	for (s = 0; s < nTotalImgs; s++) {

		name = imgFiles[s];
		printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, name);

		open(dir + name);
		forcePixelUnit();

		setTool("oval");
		roiManager("Reset");
		roiManager("Show All");

		msg = T_promptAddROI;
		msg = replace(msg, "%i", "" + (s + 1));
		msg = replace(msg, "%n", "" + nTotalImgs);
		msg = replace(msg, "%f", name);
		waitForUser(T_sampling + " " + name, msg);

		Dialog.create(T_sampling + " " + name);
		Dialog.addMessage(T_gdMessage);
		Dialog.addChoice("Action", newArray(T_gdNext, T_gdCancel, T_gdExit), T_gdNext);
		Dialog.show();
		action = Dialog.getChoice();

		if (action == T_gdExit) exit(T_exitScript);

		nR = roiManager("count");
		log(replace(T_log_sampling_rois, "%i", "" + nR));

		if (nR > 0) {

			run("Clear Results");

			for (r = 0; r < nR; r++) {
				roiManager("select", r);
				run("Measure");
			}

			for (row = 0; row < nResults; row++) {
				sampleAreas[saCount] = getResult("Area", row);
				saCount++;
			}

			run("Clear Results");
		}

		close();

		if (action == T_gdCancel) {
			log(T_log_sampling_cancel);
			break;
		}
	}

	log(T_log_sep);


	// ══════════════════════════════════════════════════════════════════════�?
	// 默认参数估计 | デフォルト推�?
	// ══════════════════════════════════════════════════════════════════════�?
	defMinA  = 5;
	defMaxA  = 200;
	defCirc  = 0;
	defRoll  = 50;
	defDebug = false;

	if (saCount == 0) {

		log(T_log_sampling_none);
		beadUnitArea = (defMinA + defMaxA) / 2;

	} else {

		Array.sort(sampleAreas);
		sorted = sampleAreas;

		med = quantileSorted(sorted, 0.50);
		beadUnitArea = med;
		if (beadUnitArea < 1) beadUnitArea = 1;

		if (saCount < 4) {

			minV = med * 0.5;
			maxV = med * 2.0;

		} else {

			q1  = quantileSorted(sorted, 0.25);
			q3  = quantileSorted(sorted, 0.75);
			iqr = q3 - q1;

			if (iqr <= 0) {
				iqr = med * 0.15;
				if (iqr < 1) iqr = 1;
			}

			minV = q1 - 1.5 * iqr;
			maxV = q3 + 1.5 * iqr;

			padding = med * 0.12;
			if (padding < 1) padding = 1;

			minV = minV - padding;
			maxV = maxV + padding;
		}

		if (minV < 1) minV = 1;

		defMinA = floor(minV);
		defMaxA = ceilInt(maxV);

		if (defMaxA <= defMinA) defMaxA = defMinA + 1;
	}

	log(T_log_params_calc);

	if (saCount == 0) {
		params_log = replace(T_log_params_default, "%i", "" + defMinA);
		params_log = replace(params_log, "%i", "" + defMaxA);
		params_log = replace(params_log, "%f", "" + defCirc);
		log(params_log);
	} else {
		params_log = replace(T_log_params_sample, "%i", "" + defMinA);
		params_log = replace(params_log, "%i", "" + defMaxA);
		params_log = replace(params_log, "%f", "" + defCirc);
		log(params_log);
	}


	// ══════════════════════════════════════════════════════════════════════�?
	// 参数确认 | パラメータ確�?
	// ══════════════════════════════════════════════════════════════════════�?
	waitForUser(T_step_param_title, T_step_param_msg);

	Dialog.create(T_param);
	Dialog.addNumber(T_minA, defMinA);
	Dialog.addNumber(T_maxA, defMaxA);
	Dialog.addNumber(T_circ, defCirc);
	Dialog.addChoice(T_strict, newArray(T_strict_S, T_strict_N, T_strict_L), T_strict_N);
	Dialog.addNumber(T_roll, defRoll);
	Dialog.addString(T_suffix, roiSuffix);
	Dialog.addCheckbox(T_debug, defDebug);
	Dialog.show();

	beadMinArea   = Dialog.getNumber();
	beadMaxArea   = Dialog.getNumber();
	beadMinCirc   = Dialog.getNumber();
	strictChoice  = Dialog.getChoice();
	rollingRadius = Dialog.getNumber();
	roiSuffix     = Dialog.getString();
	debugMode     = Dialog.getCheckbox();

	for (i = 0; i < nTotalImgs; i++) {
		roiPaths[i] = dir + bases[i] + roiSuffix + ".zip";
	}

	if (beadUnitArea < 1) beadUnitArea = (beadMinArea + beadMaxArea) / 2;
	if (beadUnitArea < 1) beadUnitArea = 1;

	effMinArea = beadMinArea;
	effMaxArea = beadMaxArea;
	effMinCirc = beadMinCirc;

	if (strictChoice == T_strict_S) {
		effMinArea = beadMinArea * 0.90;
		effMaxArea = beadMaxArea * 1.10;
		effMinCirc = beadMinCirc + 0.05;
	} else if (strictChoice == T_strict_N) {
		effMinArea = beadMinArea * 0.75;
		effMaxArea = beadMaxArea * 1.35;
		effMinCirc = beadMinCirc - 0.06;
	} else {
		effMinArea = beadMinArea * 0.55;
		effMaxArea = beadMaxArea * 1.75;
		effMinCirc = beadMinCirc - 0.12;
	}

	if (effMinArea < 1) effMinArea = 1;
	effMinArea = floor(effMinArea);
	effMaxArea = ceilInt(effMaxArea);

	if (effMinCirc < 0) effMinCirc = 0;
	if (effMinCirc > 0.95) effMinCirc = 0.95;
	if (effMaxArea <= effMinArea) effMaxArea = effMinArea + 1;


	// ══════════════════════════════════════════════════════════════════════�?
	// 批量分析 | バッチ解�?
	// ══════════════════════════════════════════════════════════════════════�?
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

	for (i = 0; i < nTotalImgs; i++) {

		imgName = imgFiles[i];
		base    = bases[i];
		roiPath = roiPaths[i];

		printWithIndex(T_log_processing, i + 1, nTotalImgs, imgName);
		imgNameA[i] = base;

		if (!File.exists(roiPath)) {

			log(replace(T_log_missing_roi, "%f", imgName));

			if (skipAllMissingROI == 0) {

				setBatchMode(false);

				Dialog.create(T_missing_title);
				m = T_missing_msg;
				m = replace(m, "%f", imgName);
				m = replace(m, "%b", base);
				m = replace(m, "%s", roiSuffix);
				Dialog.addMessage(m);
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
					annotateCellsAndSave(dir, imgName, roiSuffix, i + 1, nTotalImgs);
				}

				setBatchMode(true);

			} else {
				log(replace(T_log_missing_choice, "%s", T_missing_skip_all));
			}
		}

		if (!File.exists(roiPath)) {
			log(T_log_skip_roi);
			allA[i]     = "";
			incellA[i]  = "";
			cellA[i]    = "";
			allcellA[i] = "";
			continue;
		}

		open(dir + imgName);
		forcePixelUnit();
		origID = getImageID();

		roiManager("Reset");
		roiManager("Open", roiPath);
		nCellsAll = roiManager("count");

		if (nCellsAll == 0) {
			log(T_log_skip_nocell);
			close();
			allA[i]     = "";
			incellA[i]  = "";
			cellA[i]    = "";
			allcellA[i] = "";
			continue;
		}

		log(T_log_load_roi);
		log(replace(T_log_roi_count, "%i", "" + nCellsAll));

		w = getWidth();
		h = getHeight();

		idxType = idxImageTypeByCellCount(nCellsAll);
		newImage("cellIndex", idxType, w, h, 1);
		cellIndexID = getImageID();

		selectImage(cellIndexID);
		forcePixelUnit();

		for (c = 0; c < nCellsAll; c++) {
			roiManager("select", c);
			setColor(c + 1);
			run("Fill");
		}

		if (debugMode) dupTitle = "beads_" + base;
		else           dupTitle = "beads";

		selectImage(origID);
		run("Duplicate...", "title=" + dupTitle);
		selectImage(dupTitle);
		forcePixelUnit();

		run("8-bit");
		if (rollingRadius > 0) run("Subtract Background...", "rolling=" + rollingRadius);

		run("Find Edges");
		setAutoThreshold("Triangle");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Fill Holes");
		if (strictChoice != T_strict_L) run("Open");
		run("Watershed");

		run("Clear Results");
		run(
			"Analyze Particles...",
			"size=" + effMinArea + "-" + effMaxArea +
			" circularity=" + effMinCirc + "-1.00 show=Nothing clear"
		);

		nCand = nResults;

		log(T_log_bead_detect);

		nBeadsAll     = 0;
		nBeadsInCells = 0;
		cellsWithBead = newArray(nCellsAll);

		selectImage(cellIndexID);

		for (b = 0; b < nCand; b++) {

			x  = getResult("X", b);
			y  = getResult("Y", b);
			a  = getResult("Area", b);

			est = 1;
			if (a > beadUnitArea * 1.70) {
				est = round(a / beadUnitArea);
				if (est < 1) est = 1;
			}

			nBeadsAll += est;

			xi = floor(x + 0.5);
			yi = floor(y + 0.5);

			if (xi < 0 || yi < 0 || xi >= w || yi >= h) continue;

			val = getPixel(xi, yi);
			if (val > 0) {
				idx = val - 1;
				nBeadsInCells += est;
				cellsWithBead[idx] = 1;
			}
		}

		log(replace(T_log_bead_count, "%i", "" + nBeadsAll));

		nCellsWithBead = 0;
		for (c = 0; c < nCellsAll; c++) {
			if (cellsWithBead[c] == 1) nCellsWithBead++;
		}

		log(replace(T_log_bead_incell, "%i", "" + nBeadsInCells));
		log(replace(T_log_cell_withbead, "%i", "" + nCellsWithBead));

		allA[i]     = nBeadsAll;
		incellA[i]  = nBeadsInCells;
		cellA[i]    = nCellsWithBead;
		allcellA[i] = nCellsAll;

		log(T_log_complete);

		if (debugMode) {

			selectImage(origID);
			for (b = 0; b < nCand; b++) {
				makePoint(getResult("X", b), getResult("Y", b));
				roiManager("Add");
				roiManager("Rename", base + "_bead_" + b);
			}
			roiManager("Show All with labels");

			selectImage(cellIndexID); close();

		} else {

			selectImage(cellIndexID); close();
			selectImage(dupTitle);    close();
			selectImage(origID);      close();
		}

		run("Clear Results");
	}

	setBatchMode(false);


	// ══════════════════════════════════════════════════════════════════════�?
	// 输出结果 | 結果出力
	// ══════════════════════════════════════════════════════════════════════�?
	log(T_log_sep);
	log(T_log_results_save);

	run("Clear Results");

	for (k = 0; k < nTotalImgs; k++) {
		setResult("Image",            k, imgNameA[k]);
		setResult("Total Beads",      k, allA[k]);
		setResult("Beads in Cells",   k, incellA[k]);
		setResult("Cells with Beads", k, cellA[k]);
		setResult("Total Cells",      k, allcellA[k]);
	}

	updateResults();

	log(T_log_sep);
	log(T_log_all_done);
	log(replace(T_log_summary, "%i", "" + nTotalImgs));
	log(T_log_sep);

	maybePrintMotto(lang);

}
