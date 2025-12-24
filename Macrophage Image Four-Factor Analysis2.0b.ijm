macro "巨噬細胞画像 四要素解析 / Macrophage Four-Factor Analysis / マクロファージ四要素解析" {
	// マクロの概要：
	// 巨噬細胞（マクロファージ）画像の自動解析スクリプト
	// 機能：細胞ROI標注、ビーズ検出、統計処理、結果出力
	// 使用方法：ImageJ/Fiji で実行後、画面の指示に従う
	// バージョン：2.0


	ENABLE_MOTTO_CN   = 1;
	ENABLE_MOTTO_ENJP = 0;
	LOG_VERBOSE       = 1;


	// 関数: log

	// 説明: 指定されたメッセージをログ出力します。`LOG_VERBOSE` が真のときのみ出力されます。

	// 引数:

	//   - s : 出力するメッセージ文字列

	// 戻り値: なし

	// 注意: デバッグ用出力。大きなループ内で多用しないでください。


	function log(s) { if (LOG_VERBOSE) print(s); }


	// 関数: max2

	// 説明: 2つの数値から大きい方を返します。

	// 引数:

	//   - a : 比較対象1（数値）

	//   - b : 比較対象2（数値）

	// 戻り値: より大きい数値

	// 注意: NaN等の特別値は扱いません。


	function max2(a, b) { if (a > b) return a; return b; }

	// 関数: min2

	// 説明: 2つの数値から小さい方を返します。

	// 引数:

	//   - a : 比較対象1（数値）

	//   - b : 比較対象2（数値）

	// 戻り値: より小さい数値

	// 注意: なし


	function min2(a, b) { if (a < b) return a; return b; }

	// 関数: abs2

	// 説明: 数値の絶対値を返します。

	// 引数:

	//   - x : 入力値（数値）

	// 戻り値: 絶対値（数値）

	// 注意: なし


	function abs2(x) { if (x < 0) return -x; return x; }

	// 関数: roundInt

	// 説明: 四捨五入して整数を返します。

	// 引数:

	//   - x : 浮動小数点数

	// 戻り値: 丸められた整数

	// 注意: なし


	function roundInt(x) { return floor(x + 0.5); }

	// 関数: ceilInt

	// 説明: 数値を切り上げて整数を返します（負数対応）。

	// 引数:

	//   - x : 浮動小数点数

	// 戻り値: 切り上げ整数

	// 注意: なし


	function ceilInt(x) { f = floor(x); if (x == f) return f; if (x > 0) return f + 1; return f; }

	// 関数: clamp

	// 説明: 値を [a,b] の範囲に制限します。

	// 引数:

	//   - x : 入力値

	//   - a : 最小値

	//   - b : 最大値

	// 戻り値: 範囲内にクランプされた値

	// 注意: なし


	function clamp(x, a, b) { if (x < a) return a; if (x > b) return b; return x; }

	// 関数: isImageFile

	// 説明: ファイル名が一般的な画像拡張子かどうか判定します。

	// 引数:

	//   - filename : ファイル名（文字列）

	// 戻り値: 真（画像）/偽（非画像）

	// 注意: なし


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


	// 関数: getBaseName

	// 説明: 拡張子を除いたベース名を返します。

	// 引数:

	//   - filename : ファイル名（文字列）

	// 戻り値: 拡張子を除いたベース名（文字列）

	// 注意: なし


	function getBaseName(filename) {
		dot = lastIndexOf(filename, ".");
		if (dot > 0) return substring(filename, 0, dot);
		return filename;
	}


	// 関数: forcePixelUnit

	// 説明: 現在の画像のスケールをピクセル単位に強制設定します。

	// 引数: なし

	// 戻り値: なし

	// 注意: ImageJ の Set Scale ダイアログを自動設定します。


	function forcePixelUnit() {
		run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	}


	// 関数: ensure2D

	// 説明: 画像が2Dスタックでない場合にsliceを1に固定します。

	// 引数: なし

	// 戻り値: なし

	// 注意: Z軸のスライス処理を予防します。


	function ensure2D() {
		getDimensions(_w,_h,_c,_z,_t);
		if (_z > 1) Stack.setSlice(1);
	}


	// 関数: safeClose

	// 説明: 指定ウィンドウが開いていれば選択して閉じます。

	// 引数:

	//   - title : ウィンドウ名（文字列）

	// 戻り値: なし

	// 注意: なし


	function safeClose(title) {
		if (isOpen(title)) { selectWindow(title); close(); }
	}


	// 関数: requireWindow

	// 説明: 指定ウィンドウが存在しない場合エラーで終了します。

	// 引数:

	//   - title : ウィンドウ名

	//   - stage : 処理段階名（表示用）

	//   - fileName : 期待するファイル名

	// 戻り値: なし

	// 注意: エラーメッセージに %stage や %w, %f を挿入します。


	function requireWindow(title, stage, fileName) {
		if (!isOpen(title)) {
			msg = T_err_need_window;
			msg = replace(msg, "%stage", stage);
			msg = replace(msg, "%w", title);
			msg = replace(msg, "%f", fileName);
			exit(msg);
		}
		selectWindow(title);
	}

	// 関数: printWithIndex
	// 説明: フォーマット文字列のプレースホルダを置換してログ出力します。
	//        置換対象: %i = 現在インデックス、%n = 総数、%f = ファイル名。
	// 引数:
	//   - template : ログ出力用のテンプレート文字列（%i, %n, %f を含められます）
	//   - iVal     : 現在のインデックス（数値）
	//   - nVal     : 総数（数値）
	//   - fVal     : ファイル名または表示文字列（文字列）
	// 戻り値: なし
	// 注意: 出力は `log()` を通じて行われ、`LOG_VERBOSE` の設定に従います。

	function printWithIndex(template, iVal, nVal, fVal) {
		ss = replace(template, "%i", "" + iVal);
		ss = replace(ss, "%n", "" + nVal);
		ss = replace(ss, "%f", fVal);
		log(ss);
	}


	// 関数: maybePrintMotto
	// 説明: 設定に従ってランダムなモットー（励まし文）をログ出力します。
	// 引数: なし
	// 戻り値: なし
	// 注意: `T_mottos` 配列に要素があり、かつ言語設定と `ENABLE_MOTTO_CN/ENJP` の組合せが許可されている場合にのみ出力します。

	function maybePrintMotto() {
		if (
			(lang == "中文" && ENABLE_MOTTO_CN == 1) ||
			(lang != "中文" && ENABLE_MOTTO_ENJP == 1)
		) {
			if (T_mottos.length > 0) {
				motto_index = floor(random() * T_mottos.length);
				log("");
				log(T_mottos[motto_index]);
				log("");
			}
		}
	}


	// 関数: getPixelSafe
	// 説明: 指定座標が画像範囲外の場合は端にクランプして `getPixel` を呼び出します。
	// 引数:
	//   - x : ピクセル X 座標（数値）
	//   - y : ピクセル Y 座標（数値）
	//   - w : 画像幅（ピクセル）
	//   - h : 画像高さ（ピクセル）
	// 戻り値: 指定座標（またはクランプ後座標）のピクセル値（数値）
	// 注意: 範囲チェックを行ってから `getPixel()` を呼ぶことで境界エラーを防止します。呼び出し前に該当画像がアクティブである必要があります。

	function getPixelSafe(x, y, w, h) {
		if (x < 0) x = 0;
		if (y < 0) y = 0;
		if (x >= w) x = w - 1;
		if (y >= h) y = h - 1;
		return getPixel(x, y);
	}

	// 関数: localMean3x3
	// 説明: 指定ピクセルの 3x3 周囲領域の平均灰度を返します（境界では `getPixelSafe` を利用）。
	// 引数:
	//   - x : 中心ピクセルの X 座標（数値）
	//   - y : 中心ピクセルの Y 座標（数値）
	//   - w : 画像幅（ピクセル）
	//   - h : 画像高さ（ピクセル）
	// 戻り値: 3x3 の平均灰度（浮動小数）
	// 注意: アクティブ画像のピクセル値を直接参照するため、呼び出し前に対象ウィンドウが選択されている必要があります。

	function localMean3x3(x, y, w, h) {
		if (x > 0 && y > 0 && x < (w - 1) && y < (h - 1)) {
			sum =
				getPixel(x - 1, y - 1) + getPixel(x, y - 1) + getPixel(x + 1, y - 1) +
				getPixel(x - 1, y)     + getPixel(x, y)     + getPixel(x + 1, y) +
				getPixel(x - 1, y + 1) + getPixel(x, y + 1) + getPixel(x + 1, y + 1);
			return sum / 9.0;
		}
		sum = 0;
		dy = -1;
		while (dy <= 1) {
			dx = -1;
			while (dx <= 1) {
				sum = sum + getPixelSafe(x + dx, y + dy, w, h);
				dx = dx + 1;
			}
			dy = dy + 1;
		}
		return sum / 9.0;
	}

	// 関数: annotateCellsSmart
	// 説明: 1 枚の画像に対して「細胞 ROI の作成・編集」を対話的に行い、ROI を ZIP 保存します。
	//        既存の ROI ファイルがある場合は処理オプション（編集/重新标注/跳过/跳过全部）を提示します。
	// 引数:
	//   - dir       : 画像フォルダのパス（末尾にスラッシュが含まれていることを想定）
	//   - imgName   : 画像ファイル名（例: "img.tif"）
	//   - roiSuffix : 保存する ROI ファイル名のサフィックス（例: "_cells"）
	//   - idx       : 現在の画像インデックス（表示用）
	//   - total     : 総画像数（表示用）
	//   - skipFlag  : 既に「跳过所有」のフラグが立っている場合は 1（スキップ）、通常は 0
	// 戻り値: 更新された `skipFlag`（0 または 1）。1 の場合は以降の画像をスキップします。
	// 副作用: 画像を開き、ROI Manager を操作し、必要に応じて ZIP に保存します。ウィンドウ選択や `ensure2D()` / `forcePixelUnit()` を呼び出します。
	// 注意: 実行時にユーザ操作（ROI の描画およびキー操作 'T'）を必要とします。自動化実行時はこの関数をスキップしてください。

	function annotateCellsSmart(dir, imgName, roiSuffix, idx, total, skipFlag) {

		base   = getBaseName(imgName);
		roiOut = dir + base + roiSuffix + ".zip";

		if (skipFlag == 1 && File.exists(roiOut)) return skipFlag;

		action = T_exist_edit;

		if (File.exists(roiOut) && skipFlag == 0) {

			Dialog.create(T_exist_title);
			m = T_exist_msg;
			m = replace(m, "%i", "" + idx);
			m = replace(m, "%n", "" + total);
			m = replace(m, "%f", imgName);
			m = replace(m, "%b", base);
			m = replace(m, "%s", roiSuffix);
			Dialog.addMessage(m);
			Dialog.addChoice(
				T_exist_label,
				newArray(T_exist_edit, T_exist_redraw, T_exist_skip, T_exist_skip_all),
							 T_exist_edit
			);
			Dialog.show();
			action = Dialog.getChoice();

			if (action == T_exist_skip_all) {
				skipFlag = 1;
				action = T_exist_skip;
			}
		}

		if (action == T_exist_skip) return skipFlag;

		open(dir + imgName);
		ensure2D();
		forcePixelUnit();

		roiManager("Reset");
		roiManager("Show All");

		if (action == T_exist_edit && File.exists(roiOut)) {
			roiManager("Open", roiOut);
			roiManager("Show All with labels");
		}

		msg = T_cell_msg;
		msg = replace(msg, "%i", "" + idx);
		msg = replace(msg, "%n", "" + total);
		msg = replace(msg, "%f", imgName);
		msg = replace(msg, "%s", roiSuffix);

		waitForUser(T_cell_title, msg);

		if (roiManager("count") > 0) roiManager("Save", roiOut);

		close();
		return skipFlag;
	}

	// 関数: estimateAreaRangeSafe
	// 説明: サンプル領域の面積配列から、検出に適した面積の下限・上限・単位面積（代表値）を頑健に推定します。
	// 引数:
	//   - sampleAreas : サンプルとして抽出した beads の面積配列（px^2 の数値配列）
	//   - fallbackMin : サンプル不十分な場合の最小面積デフォルト（px^2）
	//   - fallbackMax : サンプル不十分な場合の最大面積デフォルト（px^2）
	// 戻り値: newArray(minArea, maxArea, unitArea)
	//   - minArea  : 推定した最小面積（整数）
	//   - maxArea  : 推定した最大面積（整数）
	//   - unitArea : 代表的な単一 beads の面積（整数、中央値ベース）
	// 実装メモ: 外れ値を除外するために 5%-95% 区間を使ったトリムや IQR に基づくパディング、サンプル数に応じたマージン調整を行います。
	// 注意: 入力は px^2 を想定。サンプル数が小さい場合は fallback 値に近い幅で返します。

	function estimateAreaRangeSafe(sampleAreas, fallbackMin, fallbackMax) {

		defMinA = fallbackMin;
		defMaxA = fallbackMax;
		unitA   = (fallbackMin + fallbackMax) / 2;
		if (unitA < 1) unitA = 1;

		n = sampleAreas.length;
		if (n <= 0) return newArray(defMinA, defMaxA, unitA);

		tmp0 = newArray(n);
		k = 0;
		while (k < n) {
			v = sampleAreas[k];
			if (v < 1) v = 1;
			tmp0[k] = v;
			k = k + 1;
		}

		if (n < 3) {
		Array.sort(tmp0);
			med = tmp0[floor((n-1)/2)];
			if (med < 1) med = 1;
			unitA = med;

			minV = floor(med * 0.45);
			maxV = ceilInt(med * 2.50);
			if (minV < 1) minV = 1;
			if (maxV <= minV) maxV = minV + 1;

			return newArray(minV, maxV, unitA);
		}

		Array.sort(tmp0);
		loIdx = floor((n-1) * 0.05);
		hiIdx = floor((n-1) * 0.95);
		if (loIdx < 0) loIdx = 0;
		if (hiIdx > n-1) hiIdx = n-1;
		if (hiIdx < loIdx) { t = loIdx; loIdx = hiIdx; hiIdx = t; }

		tmp = newArray();
		k = loIdx;
		while (k <= hiIdx) {
			tmp[tmp.length] = tmp0[k];
			k = k + 1;
		}

		if (tmp.length < 3) {
			tmp = newArray(n);
			k = 0;
			while (k < n) { tmp[k] = tmp0[k]; k = k + 1; }
		}

		Array.sort(tmp);
		m = tmp.length;

		med = tmp[floor((m-1)*0.50)];
		q10 = tmp[floor((m-1)*0.10)];
		q90 = tmp[floor((m-1)*0.90)];
		q25 = tmp[floor((m-1)*0.25)];
		q75 = tmp[floor((m-1)*0.75)];

		if (med < 1) med = 1;

		iqr = q75 - q25;
		if (iqr <= 0) {
			iqr = med * 0.25;
			if (iqr < 1) iqr = 1;
		}

		marginFactor = 1.15;
		if (m < 6) marginFactor = 1.60;
		else if (m < 15) marginFactor = 1.35;

		padding = iqr * 1.20;
		if (padding < med * 0.35) padding = med * 0.35;
		if (padding < 1) padding = 1;

		minV = (q10 - padding) / marginFactor;
		maxV = (q90 + padding) * marginFactor;

		if (minV < 1) minV = 1;

		defMinA = floor(minV);
		defMaxA = ceilInt(maxV);
		if (defMaxA <= defMinA) defMaxA = defMinA + 1;

		cap1 = ceilInt(med * 20);
		cap2 = ceilInt(q90 * 6);
		cap  = cap1;
		if (cap2 > cap) cap = cap2;
		if (defMaxA > cap) defMaxA = cap;

		unitA = med;
		return newArray(defMinA, defMaxA, unitA);
	}


	// 関数: estimateRollingFromUnitArea
	// 説明: 単一 beads の面積（px^2）から、背景補正用の Rolling Ball 半径（推奨値）を推定します。
	// 引数:
	//   - unitArea : 単一 beads の代表面積（px^2、数値）
	// 戻り値: 推奨 Rolling Ball 半径（整数、ピクセル）
	// 実装メモ: 面積から直径相当を計算し、経験則により倍率をかけて半径を決定し、最小/最大でクランプします。
	// 注意: 画像解像度や実験条件により調整が必要な場合があります。推定値はあくまで初期値です。

	function estimateRollingFromUnitArea(unitArea) {
		u = unitArea;
		if (u < 1) u = 1;
		d = 2 * sqrt(u / PI);

		rr = 50;
		if (d < 8) rr = roundInt(d * 10);
		else if (d < 20) rr = roundInt(d * 7);
		else rr = roundInt(d * 5);

		rr = clamp(rr, 20, 220);
		return rr;
	}

	// 関数: estimateExclusionSafe
	// 説明: 目標（target）サンプルと排除（exclusion）サンプルの平均灰度分布から、排除閾値と排除方向（HIGH/LOW）を推定します。
	// 引数:
	//   - targetMeans   : 目標サンプル（beads）の平均灰度配列（数値配列）
	//   - exclMeansAll  : 排除サンプル（ノイズや他種）の平均灰度配列（数値配列）
	// 戻り値: newArray(validFlag, mode, thr, useSizeGate, note)
	//   - validFlag   : 推定成功フラグ（1=推定有効、0=推定失敗）
	//   - mode        : "HIGH" または "LOW"（排除は高輝度 or 低輝度）
	//   - thr         : 推定閾値（数値、0-255）
	//   - useSizeGate : 面積門控を推奨するか（0/1）
	//   - note        : 信頼性に関するメッセージ（`T_excl_note_*` のうち該当するもの）
	// 実装メモ: サンプル数や分布の重なり具合を評価し、10/90 分位や中央値を使って保守的な閾値を設定します。差が小さい場合は有効でない旨を note として返します。
	// 注意: 推定が不安定な場合（サンプル不足や分布重なり）には手動でパラメータを指定してください。

	function estimateExclusionSafe(targetMeans, exclMeansAll) {

		if (targetMeans.length < 3 || exclMeansAll.length < 3)
			return newArray(1, "HIGH", 255, 0, T_excl_note_few_samples);

		t2 = newArray(); e2 = newArray();
		k = 0;
		while (k < targetMeans.length) {
			v = targetMeans[k];
			if (v > 1 && v < 254) t2[t2.length] = v;
			k = k + 1;
		}
		k = 0;
		while (k < exclMeansAll.length) {
			v = exclMeansAll[k];
			if (v > 1 && v < 254) e2[e2.length] = v;
			k = k + 1;
		}
		if (t2.length < 3 || e2.length < 3)
			return newArray(1, "HIGH", 255, 0, T_excl_note_few_effective);

		Array.sort(t2); Array.sort(e2);
		nt = t2.length; ne = e2.length;

		tLo = floor((nt-1)*0.05); tHi = floor((nt-1)*0.95);
		eLo = floor((ne-1)*0.05); eHi = floor((ne-1)*0.95);
		if (tLo<0) tLo=0; if (tHi>nt-1) tHi=nt-1; if (tHi<tLo){tt=tLo;tLo=tHi;tHi=tt;}
		if (eLo<0) eLo=0; if (eHi>ne-1) eHi=ne-1; if (eHi<eLo){tt=eLo;eLo=eHi;eHi=tt;}

		t3 = newArray();
		k = tLo;
		while (k <= tHi) { t3[t3.length] = t2[k]; k = k + 1; }

		e3 = newArray();
		k = eLo;
		while (k <= eHi) { e3[e3.length] = e2[k]; k = k + 1; }

		if (t3.length >= 3) t2 = t3;
		if (e3.length >= 3) e2 = e3;

		Array.sort(t2); Array.sort(e2);

		tMed = t2[floor((t2.length-1)*0.50)];
		eMed = e2[floor((e2.length-1)*0.50)];
		diff = eMed - tMed;

		if (abs2(diff) < 8)
			return newArray(1, "HIGH", 255, 0, T_excl_note_diff_small);

		mode = "HIGH";
		if (eMed < tMed) mode = "LOW";

		if (mode == "HIGH") {
			t90 = t2[floor((t2.length-1)*0.90)];
			e10 = e2[floor((e2.length-1)*0.10)];
			thr = (t90 + e10) / 2.0;

			if (t90 >= e10) return newArray(1, "HIGH", e10, 0, T_excl_note_overlap_high);
			return newArray(1, "HIGH", thr, 1, T_excl_note_good_sep_high);
		} else {
			t10 = t2[floor((t2.length-1)*0.10)];
			e90 = e2[floor((e2.length-1)*0.90)];
			thr = (t10 + e90) / 2.0;

			if (t10 <= e90) return newArray(1, "LOW", e90, 0, T_excl_note_overlap_low);
			return newArray(1, "LOW", thr, 1, T_excl_note_good_sep_low);
		}
	}

	// 関数: buildCellLabelMaskFromOriginal
	// 説明: 元画像と ROI Manager から各細胞に一意のラベル値を割り当てたラベルマスク画像を生成します。
	// 引数:
	//   - maskTitle : 生成するマスク画像のウィンドウ名（文字列）
	//   - origID    : 元画像のID（ImageJ の ID）
	//   - w         : 元画像の幅（ピクセル）
	//   - h         : 元画像の高さ（ピクセル）
	//   - nCells    : 細胞数（ROI の数）
	//   - fileName  : ファイル名（エラーメッセージに使用）
	// 戻り値: 1 = 成功、0 = 失敗（例: nCells が大きすぎる等）
	// 副作用: `maskTitle` 名で 16-bit の画像を作成し、各 ROI の内部をその細胞 ID（1..nCells）で塗りつぶします。
	// 注意: 実装は 16-bit を使用するため、`nCells` が 65535 を超えると対応不可です。ROI[1] の中心ピクセルが 0 の場合は生成失敗と判断します。

	function buildCellLabelMaskFromOriginal(maskTitle, origID, w, h, nCells, fileName) {

		if (nCells > 65535) {
			return 0;
		}

		safeClose(maskTitle);

		selectImage(origID);
		run("Duplicate...", "title=" + maskTitle);

		requireWindow(maskTitle, "cellLabel/duplicate", fileName);
		ensure2D();
		forcePixelUnit();

		run("16-bit");
		selectWindow(maskTitle);
		run("Select All");
		setColor(0);
		run("Fill");
		run("Select None");

		c = 0;
		while (c < nCells) {
			roiManager("select", c);
			cellId = c + 1;
			setColor(cellId);
			run("Fill");
			c = c + 1;
		}

		roiManager("select", 0);
		getSelectionBounds(bx, by, bw, bh);
		if (bw <= 0 || bh <= 0) {
			exit(T_err_roi1_invalid + "\n" + T_err_file + fileName);
		}
		cx = floor(bx + bw/2);
		cy = floor(by + bh/2);

		selectWindow(maskTitle);
		v = getPixelSafe(cx, cy, w, h);
		if (v <= 0) {
			exit(T_err_labelmask_failed + "\n\n" + T_err_labelmask_hint + "\n" + T_err_file + fileName);
		}

		setColor(0);
		return 1;
	}

	// 関数: detectBeadsFusion
	// 説明: 画像のグレースケール領域から beads を二つの手法で検出（閾値法＋エッジ法）し、重複を統合して最終検出点集合を返します。
	// 引数:
	//   - grayTitle    : グレースケール画像のウィンドウ名（文字列）
	//   - strictChoice : GUI で選ばれた厳密度選択肢（T_strict_S/T_strict_N/T_strict_L）
	//   - effMinArea   : 効率的検出の最小面積（px^2）
	//   - effMaxArea   : 効率的検出の最大面積（px^2）
	//   - effMinCirc   : 最小円形度（0–1）
	//   - beadUnitArea : 推定された単一 beads 面積（px^2）
	//   - fileName     : ファイル名（エラーメッセージに使用）
	// 戻り値: 平坦配列 `flat`（[x1, y1, a1, x2, y2, a2, ...]）
	// 副作用: 一時的に `__bin_A`, `__bin_B` を作成して処理を行い、最後にそれらを閉じます。
	// 実装メモ: 両手法の検出結果を近接距離でマージし、`beadUnitArea` に基づいた最小面積フィルタや STRICT ポリシーに基づく厳密性チェックを行います。
	// 注意: 結果は検出パラメータ（面積/円形度/しきい値）に敏感です。初回は GUI 推定値で確認し、必要に応じてパラメータを調整してください。

	function detectBeadsFusion(grayTitle, strictChoice, effMinArea, effMaxArea, effMinCirc, beadUnitArea, fileName) {

		policy = "UNION";
		if (strictChoice == T_strict_S) policy = "STRICT";
		else if (strictChoice == T_strict_N) policy = "UNION";
		else policy = "LOOSE";

		safeClose("__bin_A");
		requireWindow(grayTitle, "detect/select-gray", fileName);
		run("Duplicate...", "title=__bin_A");
		requireWindow("__bin_A", "detect/open-binA", fileName);

		if (policy != "LOOSE") run("Median...", "radius=1");

		setAutoThreshold("Yen");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Fill Holes");
		if (policy != "LOOSE") run("Open");
		if (policy == "STRICT") run("Open");
		run("Watershed");

		run("Clear Results");
		run("Analyze Particles...",
			"size=" + effMinArea + "-" + effMaxArea +
			" circularity=" + effMinCirc + "-1.00 show=Nothing clear"
		);

		nA = nResults;
		xA = newArray(nA); yA = newArray(nA); aA = newArray(nA);
		k = 0;
		while (k < nA) {
			xA[k] = getResult("X", k);
			yA[k] = getResult("Y", k);
			aA[k] = getResult("Area", k);
			k = k + 1;
		}

		safeClose("__bin_B");
		requireWindow(grayTitle, "detect/select-gray-2", fileName);
		run("Duplicate...", "title=__bin_B");
		requireWindow("__bin_B", "detect/open-binB", fileName);

		run("Find Edges");
		setAutoThreshold("Otsu");
		setOption("BlackBackground", true);
		run("Convert to Mask");
		run("Fill Holes");
		if (policy != "LOOSE") run("Open");
		run("Watershed");

		run("Clear Results");
		run("Analyze Particles...",
			"size=" + effMinArea + "-" + effMaxArea +
			" circularity=" + effMinCirc + "-1.00 show=Nothing clear"
		);

		nB = nResults;
		xB = newArray(nB); yB = newArray(nB); aB = newArray(nB);
		k = 0;
		while (k < nB) {
			xB[k] = getResult("X", k);
			yB[k] = getResult("Y", k);
			aB[k] = getResult("Area", k);
			k = k + 1;
		}

		r = sqrt(beadUnitArea / PI);
		mergeDist = max2(2, r * 0.8);
		mergeDist2 = mergeDist * mergeDist;

		xU = newArray(); yU = newArray(); aU = newArray();
		srcA = newArray(); srcB = newArray();

		k = 0;
		while (k < nA) {
			xU[xU.length] = xA[k];
			yU[yU.length] = yA[k];
			aU[aU.length] = aA[k];
			srcA[srcA.length] = 1;
			srcB[srcB.length] = 0;
			k = k + 1;
		}

		j = 0;
		while (j < nB) {
			x = xB[j]; y = yB[j]; a = aB[j];
			merged = 0;

			k = 0;
			uLen = xU.length;
			while (k < uLen) {
				dx = xU[k] - x;
				dy = yU[k] - y;
				if (dx*dx + dy*dy <= mergeDist2) {
					if (a > aU[k]) { xU[k] = x; yU[k] = y; aU[k] = a; }
					srcB[k] = 1;
					merged = 1;
					k = uLen;
				} else {
					k = k + 1;
				}
			}

			if (merged == 0) {
				xU[xU.length] = x;
				yU[yU.length] = y;
				aU[aU.length] = a;
				srcA[srcA.length] = 0;
				srcB[srcB.length] = 1;
			}

			j = j + 1;
		}

		flat = newArray();
		keepStrict = (policy == "STRICT");
		keepArea = beadUnitArea * 1.25;
		k = 0;
		uLen = xU.length;
		while (k < uLen) {

			keep = 1;
			if (keepStrict) {
				keep = 0;
				if (srcA[k] == 1 && srcB[k] == 1) keep = 1;
				else if (aU[k] >= keepArea) keep = 1;
			}

			if (keep == 1) {
				flat[flat.length] = xU[k];
				flat[flat.length] = yU[k];
				flat[flat.length] = aU[k];
			}
			k = k + 1;
		}

		safeClose("__bin_A");
		safeClose("__bin_B");
		return flat;
	}

	// 関数: countBeadsByFlat
	// 説明: detectBeadsFusion の出力（flat 配列）をもとに、各セル内の beads 数を集計します。
	// 引数:
	//   - flat               : 検出結果の平坦配列 [x,y,area,...]
	//   - cellLabelTitle     : 細胞ラベルマスクのウィンドウ名（存在する場合）
	//   - nCellsAll          : 細胞総数（整数）
	//   - w, h               : 画像幅・高さ（ピクセル）
	//   - HAS_LABEL_MASK     : ラベルマスクを使用するか（1/0）
	//   - beadUnitArea       : 単一 beads の代表面積（px^2）
	//   - allowClumpsTarget  : 団塊を面積で分割する許可（1/0）
	//   - useExcl            : 排除フィルタを有効にするか（1/0）
	//   - exclMode           : 排除方向（"HIGH" = 明るい対象を排除、"LOW" = 暗い対象を排除）
	//   - exclThr            : 排除閾値（0-255）
	//   - useExclSizeGate    : 面積門控を使うか（1/0）
	//   - exclMinA, exclMaxA : 面積門控の最小/最大（px^2）
	//   - grayTitle          : グレースケール画像のウィンドウ名（排除判定用）
	//   - fileName           : ファイル名（エラーメッセージに使用）
	//   - useMinPhago        : 最小貪食閾値を自動推定して使用するか（1/0）
	// 戻り値: newArray(nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr)
	//   - nBeadsAll        : 全検出 beads 数（団塊を分割して補正後）
	//   - nBeadsInCells    : 位置が細胞内にある beads の合計
	//   - nCellsWithBead   : beads を含む細胞の数（閾値なし）
	//   - nCellsWithBeadAdj: minPhagoThr に基づく調整後の含有細胞数
	//   - minPhagoThr      : 最低貪食数の自動推定閾値（整数）
	// 実装メモ: ラベルマスクがない場合は ROI Manager の bounds を使ってセル領域判定を行います。
	// 注意: 画像ウィンドウが適切に選択されていること、ROI Manager に期待する ROI がロードされていることが前提です。

	function countBeadsByFlat(flat, cellLabelTitle, nCellsAll, w, h, HAS_LABEL_MASK,
							  beadUnitArea, allowClumpsTarget,
						   useExcl, exclMode, exclThr,
						   useExclSizeGate, exclMinA, exclMaxA,
						   grayTitle, fileName,
						   useMinPhago) {

		nBeadsAll = 0;
		nBeadsInCells = 0;

		cellsWithBead = newArray(nCellsAll);
		cellBeadCount = newArray(nCellsAll);
		c = 0;
		while (c < nCellsAll) { cellsWithBead[c] = 0; cellBeadCount[c] = 0; c = c + 1; }

		flatLen = flat.length;
		useExclOn = (useExcl == 1);
		useLabelMask = (HAS_LABEL_MASK == 1);
		useSizeGate = (useExclSizeGate == 1);
		isExclHigh = (exclMode == "HIGH");
		allowClumps = (allowClumpsTarget == 1);
		clumpThresh = beadUnitArea * 1.35;

		if (!useLabelMask) {
			roiBX = newArray(nCellsAll);
			roiBY = newArray(nCellsAll);
			roiBW = newArray(nCellsAll);
			roiBH = newArray(nCellsAll);
			c = 0;
			while (c < nCellsAll) {
				roiManager("select", c);
				getSelectionBounds(bx, by, bw, bh);
				roiBX[c] = bx; roiBY[c] = by; roiBW[c] = bw; roiBH[c] = bh;
				c = c + 1;
			}
		}

		currWin = "";
		if (useExclOn || !useLabelMask) {
			requireWindow(grayTitle, "count/select-gray", fileName);
			currWin = "gray";
		} else if (useLabelMask) {
			requireWindow(cellLabelTitle, "count/select-cellLabel", fileName);
			currWin = "label";
		}

		i = 0;
		while (i + 2 < flatLen) {

			x = flat[i];
			y = flat[i + 1];
			a = flat[i + 2];

			xi = floor(x + 0.5);
			yi = floor(y + 0.5);

			if (xi >= 0 && yi >= 0 && xi < w && yi < h) {

				if (useExclOn) {

					applyGray = 1;
					if (useSizeGate) {
						if (a < exclMinA || a > exclMaxA) applyGray = 0;
					}

					if (applyGray == 1) {
						if (currWin != "gray") {
							selectWindow(grayTitle);
							currWin = "gray";
						}
						gv = localMean3x3(xi, yi, w, h);

						if (isExclHigh) {
							if (gv >= exclThr) { i = i + 3; continue; }
						} else {
							if (gv <= exclThr) { i = i + 3; continue; }
						}
					}
				}

				est = 1;
				if (allowClumps) {
					if (a > clumpThresh) {
						est = roundInt(a / beadUnitArea);
						if (est < 1) est = 1;
						if (est > 80) est = 80;
					}
				}

				nBeadsAll = nBeadsAll + est;

				cellId = 0;

				if (useLabelMask) {

					if (currWin != "label") {
						selectWindow(cellLabelTitle);
						currWin = "label";
					}
					cellId = getPixel(xi, yi);

				} else {

					if (currWin != "gray") {
						selectWindow(grayTitle);
						currWin = "gray";
					}

					c2 = 0;
					while (c2 < nCellsAll) {
						bx = roiBX[c2]; by = roiBY[c2]; bw = roiBW[c2]; bh = roiBH[c2];
						if (bw > 0 && bh > 0) {
							if (xi >= bx && yi >= by && xi < (bx + bw) && yi < (by + bh)) {
								roiManager("select", c2);
								if (selectionContains(xi, yi)) {
									cellId = c2 + 1;
									c2 = nCellsAll;
								} else {
									c2 = c2 + 1;
								}
							} else {
								c2 = c2 + 1;
							}
						} else {
							c2 = c2 + 1;
						}
					}
				}

				if (cellId > 0) {
					nBeadsInCells = nBeadsInCells + est;
					idx = cellId - 1;
					if (idx >= 0 && idx < nCellsAll) {
						cellBeadCount[idx] = cellBeadCount[idx] + est;
						cellsWithBead[idx] = 1;
					}
				}
			}

			i = i + 3;
		}

		nCellsWithBead = 0;
		c = 0;
		while (c < nCellsAll) {
			if (cellsWithBead[c] == 1) nCellsWithBead = nCellsWithBead + 1;
			c = c + 1;
		}

		nCellsWithBeadAdj = nCellsWithBead;
		minPhagoThr = 1;

		if (useMinPhago == 1) {
			nz = newArray();
			c = 0;
			while (c < nCellsAll) {
				if (cellBeadCount[c] > 0) nz[nz.length] = cellBeadCount[c];
				c = c + 1;
			}

			if (nz.length > 0) {
				Array.sort(nz);
				m = nz.length;
				q50 = nz[floor((m-1) * 0.50)];
				q75 = nz[floor((m-1) * 0.75)];
				minPhagoThr = roundInt((q50 + q75) / 2.0);
				if (minPhagoThr < 1) minPhagoThr = 1;
			}

			nCellsWithBeadAdj = 0;
			c = 0;
			while (c < nCellsAll) {
				if (cellBeadCount[c] >= minPhagoThr) nCellsWithBeadAdj = nCellsWithBeadAdj + 1;
				c = c + 1;
			}
		}

		return newArray(nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr);
						   }

						   VERSION_STR = "2.0";

	// ================================================================
	// 言語選択フェーズ
	// ユーザーがUI言語を選択（中文、日本語、English）
	// ================================================================
						   Dialog.create("Language / 言語 / 语言");
						   Dialog.addMessage(
							   "巨噬细胞图像四元素值分析\n" +
							   "Macrophage Image Four-Factor Analysis\n" +
							   "マクロファージ画像4要素解析\n\n" +
							   "Version: " + VERSION_STR + "\n" +
							   "---------------------------------\n" +
							   "请选择界面语言 / 言語を選択 / Select language"
						   );
						   Dialog.addChoice("Language", newArray("中文", "日本語", "English"), "中文");
						   Dialog.show();
						   lang = Dialog.getChoice();

	// ================================================================
	// 多言語UI文字列定義
	// 言語に応じたすべてのメッセージ、ラベル、エラーメッセージを定義
	// ================================================================
				   if (lang == "中文") {

T_choose     = "选择包含图像和 ROI 文件的文件夹";
				   T_exit       = "未选择文件夹。脚本已退出。";
				   T_noImages   = "所选文件夹中未找到图像文件（tif/tiff/png/jpg/jpeg）。脚本已退出。";
				   T_exitScript = "用户已退出脚本。";

							   T_mode_title = "工作模式选择选择";
							   T_mode_label = "请选择模式";
							   T_mode_1     = "仅标注细胞 ROI";
							   T_mode_2     = "仅执行分析";
							   T_mode_3     = "标注后分析（推荐）";
							   T_mode_msg =
							   "请选择本次工作模式（下拉菜单）：\n\n" +
							   "1）仅标注细胞 ROI\n" +
							   "   • 将逐张打开图像。\n" +
							   "   • 你需要手动勾画细胞轮廓，并将 ROI 添加到 ROI Manager。\n" +
							   "   • 完成后脚本将保存细胞 ROI 文件（默认：图像名 + “_cells.zip”）。\n\n" +
							   "2）仅分析四要素\n" +
							   "   • 将直接执行 beads 检测与统计。\n" +
							   "   • 每张图像必须存在对应的细胞 ROI 文件（默认：图像名 + “_cells.zip”）。\n\n" +
							   "3）标注后分析（推荐）\n" +
							   "   • 对缺失细胞 ROI 的图像先完成 ROI 标注。\n" +
							   "   • 随后进行目标 beads 抽样（必要时可进行排除对象抽样），最后执行批量分析。\n\n" +
							   "说明：点击“OK”确认选择。";

							   T_step_roi_title = "细胞 ROI 标注";
							   T_step_roi_msg =
							   "即将进入【细胞 ROI 标注】阶段。\n\n" +
							   "在此阶段，你需要：\n" +
							   "1）使用你当前选择的绘图工具勾画细胞轮廓（推荐自由手绘）。\n" +
							   "2）每完成一个细胞轮廓，按键盘 “T” 将该轮廓添加到 ROI Manager。\n" +
							   "3）当前图像所有细胞标注完成后，点击本窗口 “OK” 进入下一张图像。\n\n" +
							   "保存规则：\n" +
							   "• 脚本将保存 ROI 为 zip 文件：图像名 + “%s.zip”。\n\n" +
							   "重要提示：\n" +
							   "• 本脚本不会自动切换绘图工具，也不会自动判断细胞边界。\n" +
							   "• 为获得稳定结果，建议保持轮廓闭合并覆盖完整细胞区域。";

							   T_step_bead_title = "目标珠粒采样";
							   T_step_bead_msg =
							   "即将进入【目标 beads 抽样】阶段。\n\n" +
							   "目的：\n" +
							   "• 使用你圈选的样本，推断“典型单个 beads”的面积尺度与灰度特征。\n" +
							   "• 推断结果将用于默认检测参数、团块按面积估算 beads 数，以及背景扣除的建议值。\n\n" +
							   "操作要求：\n" +
							   "1）使用椭圆工具圈选目标 beads（精度无需极端，但建议贴合）。\n" +
							   "2）优先圈选“单个典型 beads”，避免明显团块/粘连，以提高推断可靠性。\n" +
							   "3）每圈选一个 ROI，按键盘 “T” 添加到 ROI Manager。\n" +
							   "4）完成本图像抽样后，点击本窗口 “OK”。\n" +
							   "5）随后会出现“下一步操作”下拉菜单，用于选择继续抽样、结束抽样进入下一步或退出脚本。";

							   T_step_bead_ex_title = "排除对象采样（可选）";
							   T_step_bead_ex_msg =
							   "即将进入【排除对象抽样】阶段（仅在存在多种 beads 或易混淆干扰对象时使用）。\n\n" +
							   "目的：\n" +
							   "• 学习需要排除对象/区域的灰度阈值（以及可选的面积范围），用于减少误检。\n\n" +
							   "圈选规范：\n" +
							   "• 椭圆/矩形 ROI：作为“排除 beads”样本（学习灰度与面积范围）。\n" +
							   "• Freehand/Polygon ROI：作为“排除区域”样本（学习灰度，不学习面积范围）。\n\n" +
							   "操作步骤：\n" +
							   "1）圈选需要排除的对象或区域。\n" +
							   "2）每圈选一个 ROI，按键盘 “T” 添加到 ROI Manager。\n" +
							   "3）完成后点击本窗口 “OK”。\n" +
							   "4）随后使用下拉菜单选择继续抽样、结束并计算进入参数设置，或退出脚本。";

							   T_step_param_title = "参数确认";
							   T_step_param_msg =
							   "即将打开【参数设置】窗口。\n\n" +
							   "你将看到：\n" +
							   "• 目标 beads 抽样推断的默认面积范围、beads 尺度（用于团块估算）与 Rolling Ball 建议值。\n" +
							   "• 若启用排除过滤，还将显示推断的灰度阈值与可选面积门控范围。\n\n" +
							   "建议：\n" +
							   "• 首次使用可优先采用默认值完成一次批量分析。\n" +
							   "• 如需更严格或更宽松的检测，可调整面积范围与严格程度。\n\n" +
							   "说明：点击 “OK” 确认并进入批量分析。";

							   T_step_main_title = "开始批量分析";
							   T_step_main_msg =
							   "即将进入【批量分析】阶段。\n\n" +
							   "脚本将对文件夹内所有图像执行：\n" +
							   "• 读取细胞 ROI\n" +
							   "• beads 检测与统计（含团块估算与可选排除过滤）\n" +
							   "• 汇总并写入 Results 表\n\n" +
							   "运行方式：\n" +
							   "• 批量分析在静默模式运行，以减少中间窗口弹出。\n\n" +
							   "缺失细胞 ROI 时：\n" +
							   "• 脚本将提示你选择：立即标注 / 跳过 / 跳过全部 / 退出。\n" +
							   "• 跳过的图像仍会在结果表中保留一行（数值为空）。\n\n" +
							   "说明：点击 “OK” 开始。";

							   T_cell_title = "细胞 ROI 标注";
							   T_cell_msg =
							   "进度：第 %i / %n 张\n" +
							   "文件：%f\n\n" +
							   "请完成细胞轮廓标注：\n" +
							   "1）勾画一个细胞轮廓。\n" +
							   "2）按 “T” 将轮廓添加到 ROI Manager。\n" +
							   "3）重复以上步骤，直到本图像的细胞全部完成。\n\n" +
							   "完成后点击 “OK” 保存并继续。\n\n" +
							   "保存文件：图像名 + “%s.zip”";

							   T_exist_title = "现有 ROI";
							   T_exist_label = "选择";
							   T_exist_edit  = "编辑";
							   T_exist_redraw= "重新标注并覆盖保存";
							   T_exist_skip  = "跳过此图像（保留原 ROI）";
							   T_exist_skip_all = "跳过所有已存在 ROI 的图像";
							   T_exist_msg =
							   "检测到当前图像已存在细胞 ROI 文件。\n\n" +
							   "进度：%i / %n\n" +
							   "图像：%f\n" +
							   "ROI：%b%s.zip\n\n" +
							   "选项说明：\n" +
							   "• 加载并继续编辑：打开现有 ROI 以便补充或修正。\n" +
							   "• 重新标注并覆盖保存：从空 ROI 开始，最终覆盖现有 zip。\n" +
							   "• 跳过此图像：不打开该图像，直接进入下一张。\n" +
							   "• 跳过所有已存在 ROI：后续遇到已存在 ROI 将不再提示并直接跳过。\n\n" +
							   "请选择处理方式（下拉菜单）：";

							   T_missing_title    = "缺失 ROI";
							   T_missing_label    = "选择";
							   T_missing_anno     = "现在标注";
							   T_missing_skip     = "跳过此图像（结果留空）";
							   T_missing_skip_all = "跳过所有缺 ROI 的图像（不再提示）";
							   T_missing_exit     = "退出脚本";
							   T_missing_msg      =
							   "检测到当前图像缺少对应的细胞 ROI 文件。\n\n" +
							   "图像：%f\n" +
							   "期望 ROI：%b%s.zip\n\n" +
							   "说明：\n" +
							   "• 分析四要素需要细胞 ROI。\n" +
							   "• 若选择跳过，该图像仍会在结果表中保留一行（数值为空）。\n\n" +
							   "请选择处理方式（下拉菜单）：";

							   T_sampling = "采样";
							   T_promptAddROI =
							   "进度：%i / %n\n" +
							   "文件：%f\n\n" +
							   "请圈选目标 beads（建议选择单个典型 beads，避免团块）。\n" +
							   "• 每圈选一个 ROI，按 “T” 添加到 ROI Manager。\n\n" +
							   "完成后点击 “OK”。\n" +
							   "随后将在“下一步操作”下拉菜单中选择继续、结束或退出。";

							   T_promptAddROI_EX =
							   "进度：%i / %n\n" +
							   "文件：%f\n\n" +
							   "请圈选需要排除的对象/区域。\n" +
							   "• 椭圆/矩形：用于学习排除 beads（灰度与面积）。\n" +
							   "• Freehand/Polygon：用于学习排除区域（灰度）。\n\n" +
							   "每圈选一个 ROI，按 “T” 添加到 ROI Manager。\n" +
							   "完成后点击 “OK”。\n" +
							   "随后在下拉菜单中选择继续、结束并计算或退出。";

							   T_ddLabel  = "选择";
							   T_ddNext   = "下一张";
							   T_ddStep   = "结束抽样";
							   T_ddCompute= "结束计算";
							   T_ddExit   = "退出";

							   T_ddInfo_target =
							   "请选择下一步操作（下拉菜单）：\n\n" +
							   "• 下一张：继续在下一张图像上抽样。\n" +
							   "• 结束目标抽样并进入下一步：停止抽样，并使用现有样本推断默认参数。\n" +
							   "• 退出脚本：立即结束脚本（不会执行后续批量分析）。\n\n" +
							   "说明：点击 “OK” 确认选择。";

							   T_ddInfo_excl =
							   "请选择下一步操作（下拉菜单）：\n\n" +
							   "• 下一张：继续在下一张图像上抽样。\n" +
							   "• 结束排除抽样并计算：停止排除抽样并进入参数设置。\n" +
							   "• 退出脚本：立即结束脚本（不会执行后续批量分析）。\n\n" +
							   "说明：点击 “OK” 确认选择。";

							   T_param    = "分析参数";
							   T_param_note_title = "参数说明";
							   T_section_target = "目标珠粒";
							   T_section_bg     = "背景处理";
							   T_section_roi    = "ROI 文件";
							   T_section_excl   = "排除过滤";

							   T_minA     = "最小面积（px²）";
							   T_maxA     = "最大面积（px²）";
							   T_circ     = "最小圆形度（0–1）";
							   T_allow_clumps = "团块估算：按面积拆分计数";
							   T_min_phago_enable = "微量吞噬阈值（动态计算）";

							   T_strict   = "严格程度";
							   T_strict_S = "严格";
							   T_strict_N = "正常（推荐）";
							   T_strict_L = "宽松";

							   T_roll     = "Rolling Ball 半径";
							   T_suffix   = "ROI 文件后缀";

							   T_excl_enable    = "启用排除过滤";
							   T_excl_thr       = "阈值（0–255）";
							   T_excl_mode      = "排除方向";
							   T_excl_high      = "排除亮对象（≥ 阈值）";
							   T_excl_low       = "排除暗对象（≤ 阈值）";
							   T_excl_strict    = "动态阈值（更严格）";

							   T_excl_size_gate = "面积范围门控（推荐）";
							   T_excl_minA      = "最小面积（px²）";
							   T_excl_maxA      = "最大面积（px²）";

							   T_beads_type_title = "对象类型确认";
							   T_beads_type_msg =
							   "请确认图像中是否存在多种 beads 或易混淆对象。\n\n" +
							   "• 若仅存在单一 beads 类型：建议不启用排除过滤。\n" +
							   "• 若存在多种 beads 或明显干扰对象：建议启用排除过滤，并进行排除对象抽样。\n\n" +
							   "说明：即使在此处选择启用排除过滤，你仍可在参数设置窗口中关闭该功能。";
							   T_beads_type_checkbox = "包含多种 beads（启用排除过滤）";

							   T_excl_note_few_samples   = "灰度样本不足（<3）。推断阈值不可靠，建议在参数窗口手动设置。";
							   T_excl_note_few_effective = "有效灰度样本不足（可能存在饱和或极端值）。推断阈值不可靠，建议手动设置。";
							   T_excl_note_diff_small    = "目标/排除灰度差异过小（<8）。推断阈值不可靠，建议手动设置。";
							   T_excl_note_overlap_high  = "灰度分布重叠较大：采用保守阈值（接近排除样本低分位），建议在参数窗口人工确认。";
							   T_excl_note_good_sep_high = "分离良好：阈值由目标高分位与排除低分位共同估计。";
							   T_excl_note_overlap_low   = "灰度分布重叠较大：采用保守阈值（接近排除样本高分位），建议在参数窗口人工确认。";
							   T_excl_note_good_sep_low  = "分离良好：阈值由目标低分位与排除高分位共同估计。";

							   T_err_need_window =
							   "脚本在阶段 [%stage] 需要窗口但未找到。\n\n" +
							   "窗口：%w\n" +
							   "文件：%f\n\n" +
							   "建议：关闭同名窗口、避免标题冲突后重试。";
							   T_err_too_many_cells = "细胞 ROI 数量超过 255：";
							   T_err_too_many_cells_hint = "当前实现使用 1..255 写入标签图。建议分批处理或减少 ROI 数量。";
							   T_err_file = "文件：";
							   T_err_roi1_invalid = "ROI[1] 非法（无有效 bounds）。无法生成细胞标签图。";
							   T_err_labelmask_failed = "细胞标签图生成失败：填充后中心像素仍为 0。";
							   T_err_labelmask_hint = "请检查 ROI[1] 是否为闭合面积 ROI，并确保 ROI 与图像区域有效重叠。";

							   T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
							   T_log_start           = "✓ 开始：巨噬细胞四要素分析";
							   T_log_lang            = "  ├─ 语言：中文";
							   T_log_dir             = "  ├─ 文件夹：已选择";
							   T_log_mode            = "  └─ 模式：%s";
							   T_log_roi_phase_start = "✓ 步骤：细胞 ROI 标注";
							   T_log_roi_phase_done  = "✓ 完成：细胞 ROI 标注";
							   T_log_sampling_start  = "✓ 步骤：目标 beads 抽样";
							   T_log_sampling_cancel = "✓ 完成：抽样（用户结束抽样）";
							   T_log_sampling_img    = "  ├─ 抽样 [%i/%n]：%f";
							   T_log_sampling_rois   = "  │  └─ ROI 数量：%i";
							   T_log_params_calc     = "✓ 完成：默认参数已推断";
							   T_log_main_start      = "✓ 开始：批量分析（静默模式）";
							   T_log_processing      = "  ├─ 处理 [%i/%n]：%f";
							   T_log_missing_roi     = "  │  ⚠ 缺少 ROI：%f";
							   T_log_missing_choice  = "  │  └─ 选择：%s";
							   T_log_load_roi        = "  │  ├─ 加载 ROI";
							   T_log_roi_count       = "  │  │  └─ 细胞数：%i";
							   T_log_bead_detect     = "  │  ├─ 检测 beads 并统计";
							   T_log_bead_count      = "  │  │  ├─ beads 总数：%i";
							   T_log_bead_incell     = "  │  │  ├─ 细胞内 beads：%i";
							   T_log_cell_withbead   = "  │  │  └─ 含 beads 细胞：%i";
							   T_log_complete        = "  │  └─ ✓ 完成";
							   T_log_skip_roi        = "  │  ✗ 跳过：缺少 ROI";
							   T_log_skip_nocell     = "  │  ✗ 跳过：ROI 中无有效细胞";
							   T_log_results_save    = "✓ 完成：结果已写入 Results 表";
							   T_log_all_done        = "✓✓✓ 全部完成 ✓✓✓";
							   T_log_summary         = "📊 汇总：共处理 %i 张图像";
							   T_log_unit_sync_keep  = "  └─ beads 尺度：使用抽样推断值 = %s";
							   T_log_unit_sync_ui    = "  └─ beads 尺度：检测到手动修改，改用 UI 中值 = %s";

							   T_reason_no_target = "未进行目标 beads 抽样：将使用默认 beads 尺度与默认 Rolling Ball。";
							   T_reason_target_ok = "已基于目标 beads 抽样推断 beads 尺度与 Rolling Ball（稳健估计）。";
							   T_reason_excl_on   = "排除过滤已启用：阈值由排除抽样推断（如提示不可靠，请在参数窗口手动调整）。";
							   T_reason_excl_off  = "排除过滤未启用。";
							   T_reason_excl_size_ok = "排除对象面积范围：已基于排除样本推断。";
							   T_reason_excl_size_off= "未提供足够的排除 beads 面积样本：默认关闭面积门控。";

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

						   } else if (lang == "日本語") {
							   T_choose     = "画像と ROI ファイルを含むフォルダーを選択してください";
							   T_exit       = "フォルダーが選択されませんでした。スクリプトを終了します。";
							   T_noImages   = "選択したフォルダーに画像ファイル（tif/tiff/png/jpg/jpeg）が見つかりません。スクリプトを終了します。";
							   T_exitScript = "ユーザー操作によりスクリプトを終了しました。";

							   T_mode_title = "作業モード";
							   T_mode_label = "モード";
							   T_mode_1     = "細胞 ROI のみ作成（*_cells.zip を生成）";
							   T_mode_2     = "4要素解析のみ（既存の細胞 ROI が必要）";
							   T_mode_3     = "細胞 ROI 作成後に 4要素解析（推奨）";
							   T_mode_msg =
							   "作業モードを選択してください（プルダウン）：\n\n" +
							   "1）細胞 ROI のみ作成\n" +
							   "   • 画像を順に開きます。\n" +
							   "   • 細胞輪郭を手動で描画し、ROI Manager に追加します。\n" +
							   "   • 完了後、細胞 ROI を zip（既定：画像名 + “_cells.zip”）として保存します。\n\n" +
							   "2）4要素解析のみ\n" +
							   "   • beads 検出と統計を実行します。\n" +
							   "   • 各画像に対応する細胞 ROI（既定：画像名 + “_cells.zip”）が必須です。\n\n" +
							   "3）作成→解析（推奨）\n" +
							   "   • 不足している細胞 ROI を先に作成します。\n" +
							   "   • その後、ターゲット beads サンプリング（必要に応じて除外サンプリング）を行い、最後にバッチ解析を実行します。\n\n" +
							   "説明： “OK” で確定してください。";

							   T_step_roi_title = "手順 1：細胞 ROI 作成";
							   T_step_roi_msg =
							   "【細胞 ROI 作成】を開始します。\n\n" +
							   "この手順で行うこと：\n" +
							   "1）現在選択している描画ツールで細胞輪郭を描画します（推奨：フリーハンド）。\n" +
							   "2）輪郭を 1 つ描いたら、キーボードの “T” で ROI Manager に追加します。\n" +
							   "3）この画像の細胞がすべて完了したら、このウィンドウの “OK” を押して次へ進みます。\n\n" +
							   "保存：\n" +
							   "• ROI は zip（画像名 + “%s.zip”）として保存されます。\n\n" +
							   "重要：\n" +
							   "• 本スクリプトは描画ツールを自動で切り替えません。\n" +
							   "• 安定した結果のため、輪郭は閉じた領域 ROI として作成してください。";

							   T_step_bead_title = "手順 2：ターゲット beads サンプリング";
							   T_step_bead_msg =
							   "【ターゲット beads サンプリング】を開始します。\n\n" +
							   "目的：\n" +
							   "• サンプルから「単体 beads の典型的な面積スケール」と「濃度特性」を推定します。\n" +
							   "• 推定値は既定の検出パラメータ、塊（クラスタ）の面積による beads 数推定、背景補正値（Rolling Ball）の提案に利用されます。\n\n" +
							   "操作：\n" +
							   "1）楕円ツールでターゲット beads をマークします（厳密な精度は不要ですが、可能な範囲でフィットさせてください）。\n" +
							   "2）塊ではなく、代表的な単体 beads を優先してマークしてください。\n" +
							   "3）ROI を 1 つ追加するたびに “T” を押して ROI Manager に追加します。\n" +
							   "4）この画像のサンプリングが完了したら “OK”。\n" +
							   "5）続く “次の操作” で、継続 / 終了して次へ / 終了 を選択します。";

							   T_step_bead_ex_title = "手順 3：除外サンプリング（任意）";
							   T_step_bead_ex_msg =
							   "【除外サンプリング】を開始します（複数種類の beads や紛らわしい干渉物がある場合に使用）。\n\n" +
							   "目的：\n" +
							   "• 除外対象の濃度閾値（必要に応じて面積範囲）を学習し、誤検出を抑制します。\n\n" +
							   "ROI の扱い：\n" +
							   "• 楕円/矩形 ROI：除外 beads サンプル（濃度＋面積）として扱います。\n" +
							   "• フリーハンド/ポリゴン ROI：除外領域（濃度のみ）として扱います。\n\n" +
							   "手順：\n" +
							   "1）除外したい対象または領域をマークします。\n" +
							   "2）ROI ごとに “T” を押して ROI Manager に追加します。\n" +
							   "3）完了後 “OK”。\n" +
							   "4）続くプルダウンで継続 / 終了して計算 / 終了 を選択します。";

							   T_step_param_title = "手順 4：パラメータ確認";
							   T_step_param_msg =
							   "【パラメータ設定】ウィンドウを開きます。\n\n" +
							   "表示内容：\n" +
							   "• ターゲット beads サンプルから推定した面積範囲、beads スケール（塊推定用）、Rolling Ball の提案値。\n" +
							   "• 除外フィルターを有効にした場合、濃度閾値と（任意の）面積ゲート範囲。\n\n" +
							   "推奨：\n" +
							   "• 初回は既定値で一度バッチ解析を実行し、結果に応じて調整してください。\n\n" +
							   "説明： “OK” で確定し、バッチ解析へ進みます。";

							   T_step_main_title = "バッチ解析の開始";
							   T_step_main_msg =
							   "【バッチ解析】を開始します。\n\n" +
							   "実行内容：\n" +
							   "• 細胞 ROI の読み込み\n" +
							   "• beads 検出と統計（塊推定、任意の除外フィルターを含む）\n" +
							   "• Results 表への集計出力\n\n" +
							   "実行方式：\n" +
							   "• 中間ウィンドウを抑制するため、サイレントモードで実行します。\n\n" +
							   "細胞 ROI が不足している場合：\n" +
							   "• 作成 / スキップ / すべてスキップ / 終了 を選択できます。\n" +
							   "• スキップした画像も Results に行を残します（値は空）。\n\n" +
							   "説明： “OK” で開始します。";

							   T_cell_title = "細胞 ROI 作成";
							   T_cell_msg =
							   "進捗：%i / %n\n" +
							   "ファイル：%f\n\n" +
							   "細胞輪郭を作成してください：\n" +
							   "1）輪郭を描画します。\n" +
							   "2）“T” で ROI Manager に追加します。\n" +
							   "3）この画像の細胞がすべて完了するまで繰り返します。\n\n" +
							   "完了後 “OK” で保存して次へ進みます。\n\n" +
							   "保存：画像名 + “%s.zip”";

							   T_exist_title = "既存の細胞 ROI を検出しました";
							   T_exist_label = "操作";
							   T_exist_edit  = "読み込みして編集（推奨）";
							   T_exist_redraw= "再作成して上書き保存";
							   T_exist_skip  = "この画像をスキップ（既存 ROI を保持）";
							   T_exist_skip_all = "既存 ROI の画像をすべてスキップ";
							   T_exist_msg =
							   "この画像には既存の細胞 ROI が存在します。\n\n" +
							   "進捗：%i / %n\n" +
							   "画像：%f\n" +
							   "ROI：%b%s.zip\n\n" +
							   "選択肢：\n" +
							   "• 読み込みして編集：既存 ROI を開き、追記または修正します。\n" +
							   "• 再作成して上書き：新規に作成し、既存 zip を上書きします。\n" +
							   "• スキップ：画像を開かずに次へ進みます。\n" +
							   "• すべてスキップ：以後、既存 ROI に対して確認を表示せずスキップします。\n\n" +
							   "操作を選択してください（プルダウン）：";

							   T_missing_title    = "細胞 ROI が不足しています";
							   T_missing_label    = "操作";
							   T_missing_anno     = "今ここで細胞 ROI を作成し、解析を継続する";
							   T_missing_skip     = "この画像をスキップ（結果は空）";
							   T_missing_skip_all = "不足 ROI の画像をすべてスキップ（以後表示しない）";
							   T_missing_exit     = "スクリプトを終了";
							   T_missing_msg      =
							   "この画像に対応する細胞 ROI ファイルが見つかりません。\n\n" +
							   "画像：%f\n" +
							   "想定 ROI：%b%s.zip\n\n" +
							   "説明：\n" +
							   "• 4要素解析には細胞 ROI が必要です。\n" +
							   "• スキップしても Results 表に行は残ります（値は空）。\n\n" +
							   "操作を選択してください（プルダウン）：";

							   T_sampling = "サンプリング";
							   T_promptAddROI =
							   "進捗：%i / %n\n" +
							   "ファイル：%f\n\n" +
							   "ターゲット beads をマークしてください（代表的な単体 beads を推奨。塊は避けてください）。\n" +
							   "• ROI を追加するたびに “T” を押してください。\n\n" +
							   "完了後 “OK”。\n" +
							   "続く “次の操作” で継続・終了・終了を選択します。";

							   T_promptAddROI_EX =
							   "進捗：%i / %n\n" +
							   "ファイル：%f\n\n" +
							   "除外対象をマークしてください。\n" +
							   "• 楕円/矩形：除外 beads（濃度＋面積）\n" +
							   "• フリーハンド/ポリゴン：除外領域（濃度）\n\n" +
							   "ROI ごとに “T” を押して追加します。\n" +
							   "完了後 “OK”。\n" +
							   "続くプルダウンで継続・計算・終了を選択します。";

							   T_ddLabel  = "次の操作";
							   T_ddNext   = "次の画像（サンプリング継続）";
							   T_ddStep   = "ターゲット抽出を終了して次へ（既定値を推定）";
							   T_ddCompute= "除外抽出を終了して計算（パラメータ設定へ）";
							   T_ddExit   = "スクリプト終了";

							   T_ddInfo_target =
							   "次の操作を選択してください（プルダウン）：\n\n" +
							   "• 次の画像：次の画像でサンプリングを続けます。\n" +
							   "• ターゲット抽出を終了して次へ：サンプリングを停止し、既存サンプルから既定値を推定します。\n" +
							   "• スクリプト終了：ただちに終了します（以降のバッチ解析は実行されません）。\n\n" +
							   "説明： “OK” で確定します。";

							   T_ddInfo_excl =
							   "次の操作を選択してください（プルダウン）：\n\n" +
							   "• 次の画像：次の画像でサンプリングを続けます。\n" +
							   "• 除外抽出を終了して計算：除外サンプリングを停止し、パラメータ設定へ進みます。\n" +
							   "• スクリプト終了：ただちに終了します。\n\n" +
							   "説明： “OK” で確定します。";

							   T_param    = "パラメータ設定";
							   T_param_note_title = "既定値の根拠と説明";
							   T_section_target = "ターゲット beads";
							   T_section_bg     = "背景处理";
							   T_section_roi    = "細胞 ROI";
							   T_section_excl   = "除外フィルター（任意）";

							   T_minA     = "ターゲット beads 最小面積（px^2）";
							   T_maxA     = "ターゲット beads 最大面積（px^2）";
							   T_circ     = "ターゲット beads 最小円形度（0–1）";
							   T_allow_clumps = "塊を面積で分割して beads 数を推定する";
							   T_min_phago_enable = "微量貪食は未貪食として扱う（動的しきい値、既定で有効）";

							   T_strict   = "検出の厳しさ";
							   T_strict_S = "厳格（誤検出を抑制）";
							   T_strict_N = "標準（推奨）";
							   T_strict_L = "緩い（見落としを減らす）";

							   T_roll     = "背景補正 Rolling Ball 半径";
							   T_suffix   = "細胞 ROI ファイル接尾辞（拡張子なし）";

							   T_excl_enable    = "除外フィルターを有効化（濃度閾値）";
							   T_excl_thr       = "除外閾値（0–255）";
							   T_excl_mode      = "除外方向";
							   T_excl_high      = "明るい対象を除外（濃度 ≥ 閾値）";
							   T_excl_low       = "暗い対象を除外（濃度 ≤ 閾値）";
							   T_excl_strict    = "除外を強化（動的しきい値、より厳格）";

							   T_excl_size_gate = "除外対象の面積範囲内のみ閾値除外を適用（推奨）";
							   T_excl_minA      = "除外対象 最小面積（px^2）";
							   T_excl_maxA      = "除外対象 最大面積（px^2）";

							   T_beads_type_title = "対象タイプの確認";
							   T_beads_type_msg =
							   "画像に複数種類の beads または混同しやすい対象が含まれるか確認してください。\n\n" +
							   "• 単一タイプの場合：除外フィルターは通常不要です。\n" +
							   "• 複数タイプ/干渉物がある場合：除外フィルターを有効にし、除外サンプリングを推奨します。\n\n" +
							   "説明：ここで有効にしても、後のパラメータ設定で無効化できます。";
							   T_beads_type_checkbox = "複数種類が存在する（除外フィルターを有効化）";

							   T_excl_note_few_samples   = "濃度サンプルが不足しています（<3）。推定は信頼できません。手動設定を推奨します。";
							   T_excl_note_few_effective = "有効な濃度サンプルが不足しています（飽和などの可能性）。手動設定を推奨します。";
							   T_excl_note_diff_small    = "ターゲットと除外の濃度差が小さすぎます（<8）。手動設定を推奨します。";
							   T_excl_note_overlap_high  = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の低分位に近い）。確認を推奨します。";
							   T_excl_note_good_sep_high = "分離が良好です。ターゲット高分位と除外低分位から閾値を推定しました。";
							   T_excl_note_overlap_low   = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の高分位に近い）。確認を推奨します。";
							   T_excl_note_good_sep_low  = "分離が良好です。ターゲット低分位と除外高分位から閾値を推定しました。";

							   T_err_need_window =
							   "ステージ [%stage] で必要なウィンドウが見つかりません。\n\n" +
							   "ウィンドウ：%w\n" +
							   "ファイル：%f\n\n" +
							   "対処：同名ウィンドウを閉じ、タイトル衝突を避けて再試行してください。";
							   T_err_too_many_cells = "細胞 ROI 数が 255 を超えています：";
							   T_err_too_many_cells_hint = "現在の実装では 1..255 をラベル値として使用します。分割処理または ROI 数の削減を推奨します。";
							   T_err_file = "ファイル：";
							   T_err_roi1_invalid = "ROI[1] が不正です（有効な bounds がありません）。ラベル画像を生成できません。";
							   T_err_labelmask_failed = "細胞ラベル画像の生成に失敗しました。塗りつぶし後の中心画素が 0 のままです。";
							   T_err_labelmask_hint = "ROI[1] が閉じた面積 ROI であり、画像と有効に重なっているか確認してください。";

							   T_log_sep             = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
							   T_log_start           = "✓ 開始：マクロファージ 4要素解析";
							   T_log_lang            = "  ├─ 言語：日本語";
							   T_log_dir             = "  ├─ フォルダー：選択済み";
							   T_log_mode            = "  └─ モード：%s";
							   T_log_roi_phase_start = "✓ 手順：細胞 ROI 作成";
							   T_log_roi_phase_done  = "✓ 完了：細胞 ROI 作成";
							   T_log_sampling_start  = "✓ 手順：ターゲット beads サンプリング";
							   T_log_sampling_cancel = "✓ 完了：サンプリング（ユーザー終了）";
							   T_log_sampling_img    = "  ├─ サンプル [%i/%n]：%f";
							   T_log_sampling_rois   = "  │  └─ ROI 数：%i";
							   T_log_params_calc     = "✓ 完了：既定パラメータを推定しました";
							   T_log_main_start      = "✓ 開始：バッチ解析（サイレント）";
							   T_log_processing      = "  ├─ 処理 [%i/%n]：%f";
							   T_log_missing_roi     = "  │  ⚠ ROI 不足：%f";
							   T_log_missing_choice  = "  │  └─ 選択：%s";
							   T_log_load_roi        = "  │  ├─ ROI を読み込み";
							   T_log_roi_count       = "  │  │  └─ 細胞数：%i";
							   T_log_bead_detect     = "  │  ├─ beads を検出して集計";
							   T_log_bead_count      = "  │  │  ├─ beads 合計：%i";
							   T_log_bead_incell     = "  │  │  ├─ 細胞内 beads：%i";
							   T_log_cell_withbead   = "  │  │  └─ beads を含む細胞：%i";
							   T_log_complete        = "  │  └─ ✓ 完了";
							   T_log_skip_roi        = "  │  ✗ スキップ：ROI 不足";
							   T_log_skip_nocell     = "  │  ✗ スキップ：ROI に有効な細胞がありません";
							   T_log_results_save    = "✓ 完了：Results 表に出力しました";
							   T_log_all_done        = "✓✓✓ 完了 ✓✓✓";
							   T_log_summary         = "📊 サマリー：合計 %i 枚を処理";
							   T_log_unit_sync_keep  = "  └─ beads スケール：サンプル推定値を使用 = %s";
							   T_log_unit_sync_ui    = "  └─ beads スケール：手動変更を検出。UI 中値を使用 = %s";

							   T_reason_no_target = "ターゲット beads のサンプリングなし：既定の beads スケールと Rolling Ball を使用します。";
							   T_reason_target_ok = "ターゲット beads サンプルから beads スケールと Rolling Ball を推定しました（ロバスト推定）。";
							   T_reason_excl_on   = "除外フィルター有効：除外サンプルから閾値を推定しました（不確実な場合は手動で調整してください）。";
							   T_reason_excl_off  = "除外フィルター無効。";
							   T_reason_excl_size_ok = "除外対象の面積範囲：除外サンプルから推定しました。";
							   T_reason_excl_size_off= "除外 beads の面積サンプルが不足：面積ゲートは無効（既定）です。";

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
							   T_min_phago_enable = "Treat tiny uptake as no uptake (dynamic threshold, default on)";

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
							   T_excl_strict    = "Stronger exclusion (dynamic threshold, stricter)";

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

						   Dialog.create(T_mode_title);
						   Dialog.addMessage(T_mode_msg);
						   Dialog.addChoice(T_mode_label, newArray(T_mode_1, T_mode_2, T_mode_3), T_mode_3);
						   Dialog.show();
						   modeChoice = Dialog.getChoice();

						   doROI     = (modeChoice == T_mode_1) || (modeChoice == T_mode_3);
						   doAnalyze = (modeChoice == T_mode_2) || (modeChoice == T_mode_3);

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
			safeClose("__tmp8_target");
			selectWindow(origTitle);
			run("Duplicate...", "title=__tmp8_target");
			requireWindow("__tmp8_target", "sampling/target/tmp8", imgName);
			run("8-bit");

			run("Clear Results");
			roiManager("Measure");
			updateResults();

			nRes = nResults;
			if (nRes > 0) {
				row = 0;
				while (row < nRes) {
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

				nRes = nResults;
				rowLast = nRes - 1;
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

	reasonMsg = "";

	defMinA = DEF_MINA;
	defMaxA = DEF_MAXA;
	defCirc = DEF_CIRC;
	defRoll = DEF_ROLL;

	beadUnitArea = (defMinA + defMaxA) / 2;
	if (beadUnitArea < 1) beadUnitArea = 1;

	defAllowClumps = 1;
	useMinPhago = 1;

	useExcl = 0;
	exclMode = "HIGH";
	exclThr  = 255;
	useExclStrict = 1;

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
		useExclStrict = 0;
		useExclSizeGate = 0;
		reasonMsg = reasonMsg + "• " + T_reason_excl_off + "\n";
	}

	log(T_log_params_calc);

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
	Dialog.addCheckbox(T_min_phago_enable, true);

	Dialog.addChoice(T_strict, newArray(T_strict_S, T_strict_N, T_strict_L), T_strict_N);

	Dialog.addMessage("---- " + T_section_bg + " ----");
	Dialog.addNumber(T_roll, defRoll);

	Dialog.addMessage("---- " + T_section_roi + " ----");
	Dialog.addString(T_suffix, roiSuffix);

	if (HAS_MULTI_BEADS) {
		Dialog.addMessage("---- " + T_section_excl + " ----");
		Dialog.addCheckbox(T_excl_enable, (useExcl == 1));
		Dialog.addChoice(T_excl_mode, newArray(T_excl_high, T_excl_low), exclModeDefault);
		Dialog.addNumber(T_excl_thr, exclThr);
		Dialog.addCheckbox(T_excl_strict, (useExclStrict == 1));

		Dialog.addCheckbox(T_excl_size_gate, (useExclSizeGate == 1));
		Dialog.addNumber(T_excl_minA, defExMinA);
		Dialog.addNumber(T_excl_maxA, defExMaxA);
	}

	Dialog.show();

	beadMinArea   = Dialog.getNumber();
	beadMaxArea   = Dialog.getNumber();
	beadMinCirc   = Dialog.getNumber();

	if (Dialog.getCheckbox()) allowClumpsTarget = 1;
	else allowClumpsTarget = 0;

	if (Dialog.getCheckbox()) useMinPhago = 1;
	else useMinPhago = 0;

	strictChoice  = Dialog.getChoice();
	rollingRadius = Dialog.getNumber();
	roiSuffix     = Dialog.getString();

	if (HAS_MULTI_BEADS) {
		if (Dialog.getCheckbox()) useExclUI = 1;
		else useExclUI = 0;

		exModeChoice  = Dialog.getChoice();
		exThrUI       = Dialog.getNumber();

		if (Dialog.getCheckbox()) useExclStrictUI = 1;
		else useExclStrictUI = 0;

		if (Dialog.getCheckbox()) useExclSizeGateUI = 1;
		else useExclSizeGateUI = 0;

		exclMinA_UI   = Dialog.getNumber();
		exclMaxA_UI   = Dialog.getNumber();
	} else {
		useExclUI = 0;
		useExclStrictUI = 0;
		useExclSizeGateUI = 0;
		exModeChoice = exclModeDefault;
		exThrUI = exclThr;
		exclMinA_UI = defExMinA;
		exclMaxA_UI = defExMaxA;
	}

	k = 0;
	while (k < nTotalImgs) {
		roiPaths[k] = dir + bases[k] + roiSuffix + ".zip";
		k = k + 1;
	}

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

	if (useExclStrictUI == 1) useExclStrict = 1;
	else useExclStrict = 0;

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
	cellAdjA = newArray(nTotalImgs);

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

		exclThrImg = exclThr;
		if (useExcl == 1 && useExclStrict == 1) {
			selectWindow("__bead_gray");
			getStatistics(_a, _mean, _min, _max, _std);
			if (_mean < 1) _mean = 1;
			kstd = _std / _mean;
			kstd = clamp(kstd, 0.10, 0.60);
			if (exclMode == "HIGH") {
				thrC = _mean + _std * kstd;
				if (thrC < exclThrImg) exclThrImg = thrC;
			} else {
				thrC = _mean - _std * kstd;
				if (thrC > exclThrImg) exclThrImg = thrC;
			}
			exclThrImg = clamp(exclThrImg, 0, 255);
		}

		flat = detectBeadsFusion("__bead_gray", strictChoice, effMinArea, effMaxArea, effMinCirc, beadUnitArea, imgName);

		cnt = countBeadsByFlat(
			flat, cellLabelTitle, nCellsAll, w, h, HAS_LABEL_MASK,
			beadUnitArea, allowClumpsTarget,
			useExcl, exclMode, exclThrImg,
			useExclSizeGate, exclMinA, exclMaxA,
			"__bead_gray", imgName,
			useMinPhago
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
		if (cnt.length > 3) cellAdjA[k] = cnt[3];
		else cellAdjA[k] = "";

		log(T_log_complete);

		safeClose("__bead_gray");
		safeClose(cellLabelTitle);
		selectImage(origID); close();
		run("Clear Results");

		k = k + 1;
	}

	setBatchMode(false);

	log(T_log_sep);
	log(T_log_results_save);

	run("Clear Results");

	k = 0;
	while (k < nTotalImgs) {
		setResult("Image",            k, "" + imgNameA[k]);
		setResult("Total Beads",      k, allA[k]);
		setResult("Beads in Cells",   k, incellA[k]);
		setResult("Cells with Beads", k, cellA[k]);
		if (useMinPhago == 1) setResult("Cells with Beads (Adj)", k, cellAdjA[k]);
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
