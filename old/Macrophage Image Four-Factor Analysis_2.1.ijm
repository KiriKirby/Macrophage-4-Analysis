macro "巨噬細胞画像 四要素解析 / Macrophage Four-Factor Analysis / マクロファージ四要素解析" {
    // =============================================================================
    // 概要: 巨噬細胞画像の4要素解析を行うImageJマクロ
    // 目的: ROI標注、beads検出、統計集計、結果出力を一連の対話フローで実行する
    // 想定: ImageJ/Fiji上での実行とユーザー操作を含む
    // 署名: 西方研究室（nishikata lab）王舒扬
    // 版数: 2.1
    // =============================================================================

    // -----------------------------------------------------------------------------
    // 設定: ログ/モットー表示の制御フラグ
    // -----------------------------------------------------------------------------
    ENABLE_MOTTO_CN = 1;
    ENABLE_MOTTO_ENJP = 0;
    LOG_VERBOSE = 1;

    // -----------------------------------------------------------------------------
    // 関数: log
    // 概要: LOG_VERBOSEが有効なときのみログを出力する。
    // 引数: s (string) - 出力するメッセージ
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function log(s) {
        if (LOG_VERBOSE) print(s);
    }

    // -----------------------------------------------------------------------------
    // 関数: max2
    // 概要: 2値の最大値を返す。
    // 引数: a (number), b (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function max2(a, b) {
        if (a > b) return a;
        return b;
    }

    // -----------------------------------------------------------------------------
    // 関数: min2
    // 概要: 2値の最小値を返す。
    // 引数: a (number), b (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function min2(a, b) {
        if (a < b) return a;
        return b;
    }

    // -----------------------------------------------------------------------------
    // 関数: abs2
    // 概要: 絶対値を返す。
    // 引数: x (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function abs2(x) {
        if (x < 0) return -x;
        return x;
    }

    // -----------------------------------------------------------------------------
    // 関数: roundInt
    // 概要: 四捨五入して整数化する。
    // 引数: x (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function roundInt(x) {
        return floor(x + 0.5);
    }

    // -----------------------------------------------------------------------------
    // 関数: ceilInt
    // 概要: 切り上げ（負数対応）で整数化する。
    // 引数: x (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function ceilInt(x) {
        f = floor(x);
        if (x == f) return f;
        if (x > 0) return f + 1;
        return f;
    }

    // -----------------------------------------------------------------------------
    // 関数: clamp
    // 概要: [a, b] にクランプする。
    // 引数: x (number), a (number), b (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function clamp(x, a, b) {
        if (x < a) return a;
        if (x > b) return b;
        return x;
    }

    // -----------------------------------------------------------------------------
    // 関数: isImageFile
    // 概要: 画像拡張子（tif/tiff/png/jpg/jpeg）か判定する。
    // 引数: filename (string)
    // 戻り値: 1 = 画像, 0 = 非画像
    // -----------------------------------------------------------------------------
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

    // -----------------------------------------------------------------------------
    // 関数: getBaseName
    // 概要: 拡張子を除いたベース名を返す。
    // 引数: filename (string)
    // 戻り値: string
    // -----------------------------------------------------------------------------
    function getBaseName(filename) {
        dot = lastIndexOf(filename, ".");
        if (dot > 0) return substring(filename, 0, dot);
        return filename;
    }

    // -----------------------------------------------------------------------------
    // 関数: trim2
    // 概要: 文字列の前後空白を削除する。
    // 引数: s (string)
    // 戻り値: string
    // -----------------------------------------------------------------------------
    function trim2(s) {
        if (s == "") return s;
        i = 0;
        n = lengthOf(s);
        while (i < n && (substring(s, i, i + 1) == " " || substring(s, i, i + 1) == "\t")) i = i + 1;
        j = n - 1;
        while (j >= i && (substring(s, j, j + 1) == " " || substring(s, j, j + 1) == "\t")) j = j - 1;
        if (j < i) return "";
        return substring(s, i, j + 1);
    }

    // -----------------------------------------------------------------------------
    // 関数: splitByChar
    // 概要: 1文字区切りで文字列を分割する。
    // 引数: s (string), ch (string)
    // 戻り値: array
    // -----------------------------------------------------------------------------
    function splitByChar(s, ch) {
        arr = newArray();
        buf = "";
        i = 0;
        n = lengthOf(s);
        while (i < n) {
            c = substring(s, i, i + 1);
            if (c == ch) {
                arr[arr.length] = buf;
                buf = "";
            } else {
                buf = buf + c;
            }
            i = i + 1;
        }
        arr[arr.length] = buf;
        return arr;
    }

    // -----------------------------------------------------------------------------
    // 関数: splitCSV
    // 概要: クォート対応でカンマ区切りを分割する。
    // 引数: s (string)
    // 戻り値: array
    // -----------------------------------------------------------------------------
    function splitCSV(s) {
        arr = newArray();
        buf = "";
        i = 0;
        n = lengthOf(s);
        inQuote = 0;
        while (i < n) {
            c = substring(s, i, i + 1);
            if (c == "\"") {
                inQuote = 1 - inQuote;
                buf = buf + c;
            } else if (c == "," && inQuote == 0) {
                arr[arr.length] = buf;
                buf = "";
            } else {
                buf = buf + c;
            }
            i = i + 1;
        }
        arr[arr.length] = buf;
        return arr;
    }

    // -----------------------------------------------------------------------------
    // 関数: isDigitChar
    // 概要: 数字文字か判定する。
    // 引数: c (string)
    // 戻り値: number (1/0)
    // -----------------------------------------------------------------------------
    function isDigitChar(c) {
        if (c >= "0" && c <= "9") return 1;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: parsePnF
    // 概要: ルールに従ってファイル名からPNとFを抽出する。
    // 引数: base (string), rule (string)
    // 戻り値: array [pn, fStr, fNum]
    // -----------------------------------------------------------------------------
    function parsePnF(base, rule) {
        parts = splitByChar(trim2(rule), "/");
        order = newArray();
        k = 0;
        while (k < parts.length) {
            p = toLowerCase(trim2(parts[k]));
            if (p == "pn") order[order.length] = "pn";
            else if (startsWith(p, "f")) order[order.length] = "f";
            k = k + 1;
        }

        pn = base;
        fStr = "";
        if (order.length == 2 && order[0] == "pn" && order[1] == "f") {
            i = lengthOf(base) - 1;
            while (i >= 0 && isDigitChar(substring(base, i, i + 1))) i = i - 1;
            if (i < lengthOf(base) - 1) {
                pn = substring(base, 0, i + 1);
                fStr = substring(base, i + 1);
            }
        } else if (order.length == 2 && order[0] == "f" && order[1] == "pn") {
            i = 0;
            n = lengthOf(base);
            while (i < n && !isDigitChar(substring(base, i, i + 1))) i = i + 1;
            j = i;
            while (j < n && isDigitChar(substring(base, j, j + 1))) j = j + 1;
            if (j > i) {
                fStr = substring(base, i, j);
                pn = substring(base, j);
            }
        }

        if (pn == "") pn = "PN";
        fNum = 0;
        if (fStr != "") fNum = 0 + fStr;
        return newArray(pn, fStr, fNum);
    }

    // -----------------------------------------------------------------------------
    // 関数: isBuiltinToken
    // 概要: 組み込み列コードか判定する。
    // 引数: tokenKey (string, lower)
    // 戻り値: number (1/0)
    // -----------------------------------------------------------------------------
    function isBuiltinToken(tokenKey) {
        if (tokenKey == "pn") return 1;
        if (tokenKey == "f") return 1;
        if (tokenKey == "tb") return 1;
        if (tokenKey == "bic") return 1;
        if (tokenKey == "cwb") return 1;
        if (tokenKey == "cwba") return 1;
        if (tokenKey == "tc") return 1;
        if (tokenKey == "ibr") return 1;
        if (tokenKey == "pcr") return 1;
        if (tokenKey == "eibr") return 1;
        if (tokenKey == "epcr") return 1;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: validateDataFormatRule
    // 概要: ファイル名識別ルールの妥当性を検証する。
    // 引数: rule (string)
    // 戻り値: string (空ならOK、それ以外はエラーメッセージ)
    // -----------------------------------------------------------------------------
    function validateDataFormatRule(rule) {
        r = trim2(rule);
        if (lengthOf(r) == 0) return T_err_df_rule_empty;
        parts = splitByChar(r, "/");
        if (parts.length != 2) return T_err_df_rule_slash;
        p1 = toLowerCase(trim2(parts[0]));
        p2 = toLowerCase(trim2(parts[1]));
        if (p1 == "" || p2 == "") return T_err_df_rule_parts;
        ok1 = (p1 == "pn" || startsWith(p1, "f"));
        ok2 = (p2 == "pn" || startsWith(p2, "f"));
        if (!ok1 || !ok2) return T_err_df_rule_tokens;
        if ((p1 == "pn" && p2 == "pn") || (startsWith(p1, "f") && startsWith(p2, "f")))
            return T_err_df_rule_need_both;
        if (!((p1 == "pn" && startsWith(p2, "f")) || (startsWith(p1, "f") && p2 == "pn")))
            return T_err_df_rule_order;
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: validateDataFormatCols
    // 概要: 表格列格式的妥当性を検証する。
    // 引数: cols (string)
    // 戻り値: string (空ならOK、それ以外はエラーメッセージ)
    // -----------------------------------------------------------------------------
    function validateDataFormatCols(cols) {
        s = trim2(cols);
        if (lengthOf(s) == 0) return T_err_df_cols_empty;
        fmt = splitByChar(s, "/");
        i = 0;
        while (i < fmt.length) {
            raw = trim2(fmt[i]);
            if (raw == "") return T_err_df_cols_empty_item;
            parts = splitCSV(raw);
            tokenRaw = trim2(parts[0]);
            if (tokenRaw == "") return T_err_df_cols_empty_token;
            if (indexOf(tokenRaw, "=") >= 0) return T_err_df_cols_params_comma;
            single = 0;
            if (startsWith(tokenRaw, "$")) {
                single = 1;
                tokenRaw = substring(tokenRaw, 1);
            }
            tokenRaw = trim2(tokenRaw);
            if (tokenRaw == "") return T_err_df_cols_dollar_missing;
            tokenKey = toLowerCase(tokenRaw);
            if (tokenKey == "-f") tokenKey = "f";
            if (isBuiltinToken(tokenKey) == 1 && single == 1)
                return T_err_df_cols_dollar_builtin;

            j = 1;
            while (j < parts.length) {
                kv = trim2(parts[j]);
                if (kv != "") {
                    eq = indexOf(kv, "=");
                    if (eq <= 0) return T_err_df_cols_param_kv;
                    key = toLowerCase(trim2(substring(kv, 0, eq)));
                    val = trim2(substring(kv, eq + 1));
                    if (key != "name" && key != "value") return T_err_df_cols_param_unknown_prefix + key;
                    if (!(startsWith(val, "\"") && endsWith(val, "\"") && lengthOf(val) >= 2))
                        return T_err_df_cols_param_quote;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: uniqueList
    // 概要: 出現順でユニーク化する。
    // 引数: arr (array)
    // 戻り値: array
    // -----------------------------------------------------------------------------
    function uniqueList(arr) {
        out = newArray();
        i = 0;
        while (i < arr.length) {
            v = arr[i];
            found = 0;
            j = 0;
            while (j < out.length) {
                if (out[j] == v) {
                    found = 1;
                    break;
                }
                j = j + 1;
            }
            if (found == 0) out[out.length] = v;
            i = i + 1;
        }
        return out;
    }

    // -----------------------------------------------------------------------------
    // 関数: sortPairsByNumber
    // 概要: 数値配列と対応配列を昇順/降順でソートする。
    // 引数: nums (array), strs (array), desc (number)
    // 戻り値: なし（配列を直接並べ替える）
    // -----------------------------------------------------------------------------
    function sortPairsByNumber(nums, strs, desc) {
        n = nums.length;
        i = 0;
        while (i < n - 1) {
            j = i + 1;
            while (j < n) {
                swap = 0;
                if (desc == 1) {
                    if (nums[i] < nums[j]) swap = 1;
                } else {
                    if (nums[i] > nums[j]) swap = 1;
                }
                if (swap == 1) {
                    t = nums[i];
                    nums[i] = nums[j];
                    nums[j] = t;
                    s = strs[i];
                    strs[i] = strs[j];
                    strs[j] = s;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        return;
    }

    // -----------------------------------------------------------------------------
    // 関数: sortTriplesByNumber
    // 概要: 数値配列と対応2配列を昇順/降順でソートする。
    // 引数: nums (array), strs (array), idxs (array), desc (number)
    // 戻り値: なし（配列を直接並べ替える）
    // -----------------------------------------------------------------------------
    function sortTriplesByNumber(nums, strs, idxs, desc) {
        n = nums.length;
        i = 0;
        while (i < n - 1) {
            j = i + 1;
            while (j < n) {
                swap = 0;
                if (desc == 1) {
                    if (nums[i] < nums[j]) swap = 1;
                } else {
                    if (nums[i] > nums[j]) swap = 1;
                }
                if (swap == 1) {
                    t = nums[i];
                    nums[i] = nums[j];
                    nums[j] = t;
                    s = strs[i];
                    strs[i] = strs[j];
                    strs[j] = s;
                    x = idxs[i];
                    idxs[i] = idxs[j];
                    idxs[j] = x;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        return;
    }

    // -----------------------------------------------------------------------------
    // 関数: calcRatio
    // 概要: 分子/分母を安全に計算する。
    // 引数: num (number), den (number)
    // 戻り値: number or ""
    // -----------------------------------------------------------------------------
    function calcRatio(num, den) {
        if (num == "" || den == "") return "";
        if (den <= 0) return "";
        return num / den;
    }

    // -----------------------------------------------------------------------------
    // 関数: forcePixelUnit
    // 概要: 画像スケールをピクセル単位に固定する。
    // 引数: なし
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function forcePixelUnit() {
        run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
    }

    // -----------------------------------------------------------------------------
    // 関数: ensure2D
    // 概要: Zスタックの場合はスライス1に固定し2D化する。
    // 引数: なし
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function ensure2D() {
        getDimensions(_w, _h, _c, _z, _t);
        if (_z > 1) Stack.setSlice(1);
    }

    // -----------------------------------------------------------------------------
    // 関数: safeClose
    // 概要: 指定ウィンドウが開いていれば閉じる。
    // 引数: title (string)
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function safeClose(title) {
        if (isOpen(title)) {
            selectWindow(title);
            close();
        }
    }

    // -----------------------------------------------------------------------------
    // 関数: escapeForReplace
    // 概要: replace() の置換文字列で問題になる "$" と "\" をエスケープする。
    // 引数: s (string)
    // 戻り値: string
    // -----------------------------------------------------------------------------
    function escapeForReplace(s) {
        s = replace(s, "\\", "\\\\");
        s = replace(s, "$", "\\$");
        return s;
    }

    // -----------------------------------------------------------------------------
    // 関数: replaceSafe
    // 概要: 置換文字列をエスケープしてから replace() を実行する。
    // 引数: template (string), token (string), value (string)
    // 戻り値: string
    // -----------------------------------------------------------------------------
    function replaceSafe(template, token, value) {
        return replace(template, token, escapeForReplace("" + value));
    }

    // -----------------------------------------------------------------------------
    // 関数: requireWindow
    // 概要: 指定ウィンドウが存在しない場合はエラー終了する。
    // 引数: title (string), stage (string), fileName (string)
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function requireWindow(title, stage, fileName) {
        if (!isOpen(title)) {
            msg = T_err_need_window;
            msg = replaceSafe(msg, "%stage", stage);
            msg = replaceSafe(msg, "%w", title);
            msg = replaceSafe(msg, "%f", fileName);
            exit(msg);
        }
        selectWindow(title);
    }

    // -----------------------------------------------------------------------------
    // 関数: printWithIndex
    // 概要: 進捗テンプレートを置換してログ出力する。
    // 引数: template (string), iVal (number), nVal (number), fVal (string)
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function printWithIndex(template, iVal, nVal, fVal) {
        if (!LOG_VERBOSE) return;
        ss = replaceSafe(template, "%i", "" + iVal);
        ss = replaceSafe(ss, "%n", "" + nVal);
        ss = replaceSafe(ss, "%f", fVal);
        log(ss);
    }

    // -----------------------------------------------------------------------------
    // 関数: logDataFormatDetails
    // 概要: データ形式の設定内容を詳細にログ出力する。
    // 引数: rule, cols, itemSpecs, itemTokens, itemNames, itemValues, itemSingles, sortDesc
    // 戻り値: なし
    // -----------------------------------------------------------------------------
    function logDataFormatDetails(rule, cols, itemSpecs, itemTokens, itemNames, itemValues, itemSingles, sortDesc) {
        if (!LOG_VERBOSE) return;
        log(T_log_df_header);
        log(replaceSafe(T_log_df_rule, "%s", rule));
        log(replaceSafe(T_log_df_cols, "%s", cols));
        if (sortDesc == 1) log(T_log_df_sort_desc);
        else log(T_log_df_sort_asc);

        k = 0;
        while (k < itemTokens.length) {
            raw = itemSpecs[k];
            token = itemTokens[k];
            name = itemNames[k];
            value = itemValues[k];
            single = itemSingles[k];

            line = T_log_df_item;
            line = replaceSafe(line, "%raw", raw);
            line = replaceSafe(line, "%token", token);
            line = replaceSafe(line, "%name", name);
            line = replaceSafe(line, "%value", value);
            line = replaceSafe(line, "%single", "" + single);
            log(line);
            k = k + 1;
        }
    }

    // -----------------------------------------------------------------------------
    // 関数: maybePrintMotto
    // 概要: 言語設定とフラグに応じてランダムなモットーを表示する。
    // 引数: なし
    // 戻り値: なし
    // -----------------------------------------------------------------------------
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

    // -----------------------------------------------------------------------------
    // 関数: getPixelSafe
    // 概要: 座標を画像範囲にクランプしてピクセル値を取得する。
    // 引数: x (number), y (number), w (number), h (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
    function getPixelSafe(x, y, w, h) {
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x >= w) x = w - 1;
        if (y >= h) y = h - 1;
        return getPixel(x, y);
    }

    // -----------------------------------------------------------------------------
    // 関数: localMean3x3
    // 概要: 3x3近傍の平均灰度を返す（境界は安全取得）。
    // 引数: x (number), y (number), w (number), h (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
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

    // -----------------------------------------------------------------------------
    // 関数: annotateCellsSmart
    // 概要: 画像を開き、ROI Managerで細胞ROIを対話的に作成/編集してZIP保存する。
    // 引数: dir (string), imgName (string), roiSuffix (string), idx (number),
    //       total (number), skipFlag (number)
    // 戻り値: skipFlag (number) - 「以降をスキップ」状態
    // 副作用: 画像の表示、ROI Manager操作、ユーザー操作待ちが発生する。
    // -----------------------------------------------------------------------------
    function annotateCellsSmart(dir, imgName, roiSuffix, idx, total, skipFlag) {

        base = getBaseName(imgName);
        roiOut = dir + base + roiSuffix + ".zip";

        if (skipFlag == 1 && File.exists(roiOut)) return skipFlag;

        action = T_exist_edit;

        if (File.exists(roiOut) && skipFlag == 0) {

            Dialog.create(T_exist_title);
            m = T_exist_msg;
            m = replaceSafe(m, "%i", "" + idx);
            m = replaceSafe(m, "%n", "" + total);
            m = replaceSafe(m, "%f", imgName);
            m = replaceSafe(m, "%b", base);
            m = replaceSafe(m, "%s", roiSuffix);
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
        msg = replaceSafe(msg, "%i", "" + idx);
        msg = replaceSafe(msg, "%n", "" + total);
        msg = replaceSafe(msg, "%f", imgName);
        msg = replaceSafe(msg, "%s", roiSuffix);

        waitForUser(T_cell_title, msg);

        if (roiManager("count") > 0) roiManager("Save", roiOut);

        close();
        return skipFlag;
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateAreaRangeSafe
    // 概要: サンプル面積の分布から、外れ値に強い範囲と代表値を推定する。
    // 引数: sampleAreas (array), fallbackMin (number), fallbackMax (number)
    // 戻り値: array[minArea, maxArea, unitArea]
    // 補足: サンプルが少ない場合は中央値ベースで保守的に推定する。
    // -----------------------------------------------------------------------------
    function estimateAreaRangeSafe(sampleAreas, fallbackMin, fallbackMax) {

        defMinA = fallbackMin;
        defMaxA = fallbackMax;
        unitA = (fallbackMin + fallbackMax) / 2;
        if (unitA < 1) unitA = 1;

        n = sampleAreas.length;
        if (n <= 0) return newArray(defMinA, defMaxA, unitA);
        n1 = n - 1;

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
            med = tmp0[floor(n1/2)];
            if (med < 1) med = 1;
            unitA = med;

            minV = floor(med * 0.45);
            maxV = ceilInt(med * 2.50);
            if (minV < 1) minV = 1;
            if (maxV <= minV) maxV = minV + 1;

            return newArray(minV, maxV, unitA);
        }

        Array.sort(tmp0);
        loIdx = floor(n1 * 0.05);
        hiIdx = floor(n1 * 0.95);
        if (loIdx < 0) loIdx = 0;
        if (hiIdx > n-1) hiIdx = n-1;
        if (hiIdx < loIdx) {
            t = loIdx;
            loIdx = hiIdx;
            hiIdx = t;
        }

        tmp = newArray();
        k = loIdx;
        while (k <= hiIdx) {
            tmp[tmp.length] = tmp0[k];
            k = k + 1;
        }

        if (tmp.length < 3) {
            tmp = tmp0;
        }

        Array.sort(tmp);
        m = tmp.length;
        m1 = m - 1;

        med = tmp[floor(m1*0.50)];
        q10 = tmp[floor(m1*0.10)];
        q90 = tmp[floor(m1*0.90)];
        q25 = tmp[floor(m1*0.25)];
        q75 = tmp[floor(m1*0.75)];

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
        cap = cap1;
        if (cap2 > cap) cap = cap2;
        if (defMaxA > cap) defMaxA = cap;

        unitA = med;
        return newArray(defMinA, defMaxA, unitA);
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateRollingFromUnitArea
    // 概要: 代表面積を直径に換算し、経験則でRolling Ball半径を推定する。
    // 引数: unitArea (number)
    // 戻り値: number
    // -----------------------------------------------------------------------------
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

    // -----------------------------------------------------------------------------
    // 関数: estimateExclusionSafe
    // 概要: 目標/排除サンプルの灰度分布から排除モードと閾値を推定する。
    // 引数: targetMeans (array), exclMeansAll (array)
    // 戻り値: array[validFlag, mode, thr, useSizeGate, note]
    // 補足: サンプル不足や重なりが大きい場合は保守的な結果を返す。
    // -----------------------------------------------------------------------------
    function estimateExclusionSafe(targetMeans, exclMeansAll) {

        tLen = targetMeans.length;
        eLen = exclMeansAll.length;
        if (tLen < 3 || eLen < 3)
            return newArray(1, "HIGH", 255, 0, T_excl_note_few_samples);

        t2 = newArray();
        e2 = newArray();
        k = 0;
        while (k < tLen) {
            v = targetMeans[k];
            if (v > 1 && v < 254) t2[t2.length] = v;
            k = k + 1;
        }
        k = 0;
        while (k < eLen) {
            v = exclMeansAll[k];
            if (v > 1 && v < 254) e2[e2.length] = v;
            k = k + 1;
        }
        t2Len = t2.length;
        e2Len = e2.length;
        if (t2Len < 3 || e2Len < 3)
            return newArray(1, "HIGH", 255, 0, T_excl_note_few_effective);

        Array.sort(t2);
        Array.sort(e2);
        nt = t2Len;
        ne = e2Len;
        nt1 = nt - 1;
        ne1 = ne - 1;

        tLo = floor(nt1*0.05);
        tHi = floor(nt1*0.95);
        eLo = floor(ne1*0.05);
        eHi = floor(ne1*0.95);
        if (tLo < 0) tLo = 0;
        if (tHi > nt - 1) tHi = nt - 1;
        if (tHi < tLo) {
            tt = tLo;
            tLo = tHi;
            tHi = tt;
        }
        if (eLo < 0) eLo = 0;
        if (eHi > ne - 1) eHi = ne - 1;
        if (eHi < eLo) {
            tt = eLo;
            eLo = eHi;
            eHi = tt;
        }

        t3 = newArray();
        k = tLo;
        while (k <= tHi) {
            t3[t3.length] = t2[k];
            k = k + 1;
        }

        e3 = newArray();
        k = eLo;
        while (k <= eHi) {
            e3[e3.length] = e2[k];
            k = k + 1;
        }

        if (t3.length >= 3) t2 = t3;
        if (e3.length >= 3) e2 = e3;

        t2Len2 = t2.length;
        e2Len2 = e2.length;
        t2Len2m1 = t2Len2 - 1;
        e2Len2m1 = e2Len2 - 1;

        tMed = t2[floor(t2Len2m1*0.50)];
        eMed = e2[floor(e2Len2m1*0.50)];
        diff = eMed - tMed;

        if (abs2(diff) < 8)
            return newArray(1, "HIGH", 255, 0, T_excl_note_diff_small);

        mode = "HIGH";
        if (eMed < tMed) mode = "LOW";

        if (mode == "HIGH") {
            t90 = t2[floor(t2Len2m1*0.90)];
            e10 = e2[floor(e2Len2m1*0.10)];
            thr = (t90 + e10) / 2.0;

            if (t90 >= e10) return newArray(1, "HIGH", e10, 0, T_excl_note_overlap_high);
            return newArray(1, "HIGH", thr, 1, T_excl_note_good_sep_high);
        } else {
            t10 = t2[floor(t2Len2m1*0.10)];
            e90 = e2[floor(e2Len2m1*0.90)];
            thr = (t10 + e90) / 2.0;

            if (t10 <= e90) return newArray(1, "LOW", e90, 0, T_excl_note_overlap_low);
            return newArray(1, "LOW", thr, 1, T_excl_note_good_sep_low);
        }
    }

    // -----------------------------------------------------------------------------
    // 関数: buildCellLabelMaskFromOriginal
    // 概要: ROIごとにラベル値を塗り分けた16-bitマスクを生成する。
    // 引数: maskTitle (string), origID (number), w (number), h (number),
    //       nCells (number), fileName (string)
    // 戻り値: 1 = 成功, 0 = 失敗
    // 補足: nCellsが65535を超える場合は処理を中断する。
    // -----------------------------------------------------------------------------
    function buildCellLabelMaskFromOriginal(maskTitle, origID, w, h, nCells, fileName) {

        if (nCells > 65535) {
            exit(T_err_too_many_cells + " " + nCells + "\n" + T_err_too_many_cells_hint + "\n" + T_err_file + fileName);
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

    // -----------------------------------------------------------------------------
    // 関数: detectBeadsFusion
    // 概要: 2つの検出法（閾値/エッジ）でbeadsを抽出し、近接点を統合する。
    // 引数: grayTitle (string), strictChoice (string), effMinArea (number),
    //       effMaxArea (number), effMinCirc (number), beadUnitArea (number),
    //       fileName (string)
    // 戻り値: flat配列 [x1, y1, a1, ...]
    // 補足: strictChoiceによりフィルタ強度と統合基準を調整する。
    // -----------------------------------------------------------------------------
    function detectBeadsFusion(grayTitle, strictChoice, effMinArea, effMaxArea, effMinCirc, beadUnitArea, fileName) {

        // 検出ポリシーの決定（厳密度により統合条件を変える）
        policy = "UNION";
        if (strictChoice == T_strict_S) policy = "STRICT";
        else if (strictChoice == T_strict_N) policy = "UNION";
        else policy = "LOOSE";

        // 手法A: 閾値ベースでbeads候補を抽出する
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

        // 面積/円形度条件で候補を収集する
        run("Clear Results");
        run("Analyze Particles...",
            "size=" + effMinArea + "-" + effMaxArea +
            " circularity=" + effMinCirc + "-1.00 show=Nothing clear"
        );

        // 手法Aの結果を配列に格納する
        nA = nResults;
        xA = newArray(nA);
        yA = newArray(nA);
        aA = newArray(nA);
        k = 0;
        while (k < nA) {
            xA[k] = getResult("X", k);
            yA[k] = getResult("Y", k);
            aA[k] = getResult("Area", k);
            k = k + 1;
        }

        // 手法B: エッジ抽出ベースで候補を抽出する
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

        // 面積/円形度条件で候補を収集する
        run("Clear Results");
        run("Analyze Particles...",
            "size=" + effMinArea + "-" + effMaxArea +
            " circularity=" + effMinCirc + "-1.00 show=Nothing clear"
        );

        // 手法Bの結果を配列に格納する
        nB = nResults;
        xB = newArray(nB);
        yB = newArray(nB);
        aB = newArray(nB);
        k = 0;
        while (k < nB) {
            xB[k] = getResult("X", k);
            yB[k] = getResult("Y", k);
            aB[k] = getResult("Area", k);
            k = k + 1;
        }

        // 近接距離のしきい値を、代表面積から推定する
        r = sqrt(beadUnitArea / PI);
        mergeDist = max2(2, r * 0.8);
        mergeDist2 = mergeDist * mergeDist;

        // 手法A/Bの候補を統合してユニオン集合を作る
        xU = newArray();
        yU = newArray();
        aU = newArray();
        srcA = newArray();
        srcB = newArray();

        k = 0;
        while (k < nA) {
            xU[xU.length] = xA[k];
            yU[yU.length] = yA[k];
            aU[aU.length] = aA[k];
            srcA[srcA.length] = 1;
            srcB[srcB.length] = 0;
            k = k + 1;
        }

        // 近傍にある候補は1点に統合し、優先的に面積の大きい点を残す
        j = 0;
        while (j < nB) {
            x = xB[j];
            y = yB[j];
            a = aB[j];
            merged = 0;

            k = 0;
            uLen = xU.length;
            while (k < uLen) {
                dx = xU[k] - x;
                dy = yU[k] - y;
                if (dx*dx + dy*dy <= mergeDist2) {
                    if (a > aU[k]) {
                        xU[k] = x;
                        yU[k] = y;
                        aU[k] = a;
                    }
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

        // 厳密モードでは両手法一致または大面積のみを残す
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

    // -----------------------------------------------------------------------------
    // 関数: countBeadsByFlat
    // 概要: beads検出結果を細胞ごとに集計し統計値を返す。
    // 引数: flat, cellLabelTitle, nCellsAll, w, h, HAS_LABEL_MASK,
    //       beadUnitArea, allowClumpsTarget, useExcl, exclMode, exclThr,
    //       useExclSizeGate, exclMinA, exclMaxA, grayTitle, fileName, useMinPhago
    // 戻り値: array[nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr]
    // 補足: ラベルマスク未使用時はROI境界で判定するため処理が遅くなる。
    // -----------------------------------------------------------------------------
    function countBeadsByFlat(
        flat, cellLabelTitle, nCellsAll, w, h, HAS_LABEL_MASK,
        beadUnitArea, allowClumpsTarget,
        useExcl, exclMode, exclThr,
        useExclSizeGate, exclMinA, exclMaxA,
        grayTitle, fileName,
        useMinPhago
    ) {

        // 集計用のカウンタを初期化する
        nBeadsAll = 0;
        nBeadsInCells = 0;

        // 細胞ごとの状態とカウントを初期化する
        nCells = nCellsAll;
        cellsWithBead = newArray(nCells);
        cellBeadCount = newArray(nCells);
        c = 0;
        while (c < nCells) {
            cellsWithBead[c] = 0;
            cellBeadCount[c] = 0;
            c = c + 1;
        }

        // 各種フラグを整理して処理分岐の準備をする
        flatLen = flat.length;
        useExclOn = (useExcl == 1);
        useLabelMask = (HAS_LABEL_MASK == 1);
        useSizeGate = (useExclSizeGate == 1);
        isExclHigh = (exclMode == "HIGH");
        allowClumps = (allowClumpsTarget == 1);
        clumpThresh = beadUnitArea * 1.35;

        // ラベルマスクが無い場合はROI境界のキャッシュを作る
        if (!useLabelMask) {
            roiBX = newArray(nCells);
            roiBY = newArray(nCells);
            roiBW = newArray(nCells);
            roiBH = newArray(nCells);
            c = 0;
            while (c < nCells) {
                roiManager("select", c);
                getSelectionBounds(bx, by, bw, bh);
                roiBX[c] = bx;
                roiBY[c] = by;
                roiBW[c] = bw;
                roiBH[c] = bh;
                c = c + 1;
            }
        }

        // 参照ウィンドウを必要に応じて切り替える
        currWin = "";
        if (useExclOn || !useLabelMask) {
            requireWindow(grayTitle, "count/select-gray", fileName);
            currWin = "gray";
        } else if (useLabelMask) {
            requireWindow(cellLabelTitle, "count/select-cellLabel", fileName);
            currWin = "label";
        }

        // beads候補を順に走査して除外/集計を行う
        i = 0;
        while (i + 2 < flatLen) {

            x = flat[i];
            y = flat[i + 1];
            a = flat[i + 2];

            xi = floor(x + 0.5);
            yi = floor(y + 0.5);

            if (xi >= 0 && yi >= 0 && xi < w && yi < h) {

                // 排除フィルタが有効なら灰度しきい値で除外する
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
                            if (gv >= exclThr) {
                                i = i + 3;
                                continue;
                            }
                        } else {
                            if (gv <= exclThr) {
                                i = i + 3;
                                continue;
                            }
                        }
                    }
                }

                // 団塊を代表面積から分割推定する（許可時のみ）
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

                // ラベルマスクがある場合はピクセル値で細胞IDを取得する
                if (useLabelMask) {

                    if (currWin != "label") {
                        selectWindow(cellLabelTitle);
                        currWin = "label";
                    }
                    cellId = getPixel(xi, yi);

                } else {

                    // ラベルマスクが無い場合はROIに含まれるかを判定する
                    if (currWin != "gray") {
                        selectWindow(grayTitle);
                        currWin = "gray";
                    }

                    c2 = 0;
                    while (c2 < nCells) {
                        bx = roiBX[c2];
                        by = roiBY[c2];
                        bw = roiBW[c2];
                        bh = roiBH[c2];
                        if (bw > 0 && bh > 0) {
                            if (xi >= bx && yi >= by && xi < (bx + bw) && yi < (by + bh)) {
                                roiManager("select", c2);
                                if (selectionContains(xi, yi)) {
                                    cellId = c2 + 1;
                                    c2 = nCells;
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

                // 細胞内に入ったbeadsを集計する
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

        // beadsを含む細胞数を集計する
        nCellsWithBead = 0;
        c = 0;
        while (c < nCells) {
            if (cellsWithBead[c] == 1) nCellsWithBead = nCellsWithBead + 1;
            c = c + 1;
        }

        nCellsWithBeadAdj = nCellsWithBead;
        minPhagoThr = 1;

        // 微量貪食のしきい値を推定し、調整後の細胞数を算出する
        if (useMinPhago == 1) {
            nz = newArray();
            c = 0;
            while (c < nCells) {
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
            while (c < nCells) {
                if (cellBeadCount[c] >= minPhagoThr) nCellsWithBeadAdj = nCellsWithBeadAdj + 1;
                c = c + 1;
            }
        }

        return newArray(nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr);
    }

    // =============================================================================
    // メインフロー: 対話型の解析手順をここから実行する
    // =============================================================================
    VERSION_STR = "2.1";
    T_lang_title = "Language / 言語 / 语言";
    T_lang_label = "Language / 言語 / 语言";
    T_lang_msg =
        "巨噬细胞图像四元素值分析\n" +
        "Macrophage Image Four-Factor Analysis\n" +
        "マクロファージ画像4要素解析\n\n" +
        "Version: " + VERSION_STR + "\n" +
        "---------------------------------\n" +
        "请选择界面语言 / 言語を選択 / Select language";

    // -----------------------------------------------------------------------------
    // フェーズ1: UI言語の選択
    // -----------------------------------------------------------------------------
    Dialog.create(T_lang_title);
    Dialog.addMessage(T_lang_msg);
    Dialog.addChoice(T_lang_label, newArray("中文", "日本語", "English"), "中文");
    Dialog.show();
    lang = Dialog.getChoice();

    // -----------------------------------------------------------------------------
    // フェーズ2: 言語別UIテキスト定義
    // -----------------------------------------------------------------------------
    if (lang == "中文") {

        T_choose = "选择包含图像和 ROI 文件的文件夹";
        T_exit = "未选择文件夹。脚本已退出。";
        T_noImages = "所选文件夹中未找到图像文件（tif/tiff/png/jpg/jpeg）。脚本已退出。";
        T_exitScript = "用户已退出脚本。";

        T_mode_title = "工作模式选择选择";
        T_mode_label = "请选择模式";
        T_mode_1 = "仅标注细胞 ROI";
        T_mode_2 = "仅执行分析";
        T_mode_3 = "标注后分析（推荐）";
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
        T_exist_edit = "编辑";
        T_exist_redraw = "重新标注并覆盖保存";
        T_exist_skip = "跳过此图像（保留原 ROI）";
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

        T_missing_title = "缺失 ROI";
        T_missing_label = "选择";
        T_missing_anno = "现在标注";
        T_missing_skip = "跳过此图像（结果留空）";
        T_missing_skip_all = "跳过所有缺 ROI 的图像（不再提示）";
        T_missing_exit = "退出脚本";
        T_missing_msg =
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

        T_ddLabel = "选择";
        T_ddNext = "下一张";
        T_ddStep = "结束抽样";
        T_ddCompute = "结束计算";
        T_ddExit = "退出";

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

        T_param = "分析参数";
        T_param_note_title = "参数说明";
        T_section_target = "目标珠粒";
        T_section_bg = "背景处理";
        T_section_roi = "ROI 文件";
        T_section_excl = "排除过滤";
        T_section_format = "数据格式化";
        T_section_sep = "---- %s ----";

        T_minA = "最小面积（px²）";
        T_maxA = "最大面积（px²）";
        T_circ = "最小圆形度（0–1）";
        T_allow_clumps = "团块估算：按面积拆分计数";
        T_min_phago_enable = "微量吞噬阈值（动态计算）";

        T_strict = "严格程度";
        T_strict_S = "严格";
        T_strict_N = "正常（推荐）";
        T_strict_L = "宽松";

        T_roll = "Rolling Ball 半径";
        T_suffix = "ROI 文件后缀";

        T_excl_enable = "启用排除过滤";
        T_excl_thr = "阈值（0–255）";
        T_excl_mode = "排除方向";
        T_excl_high = "排除亮对象（≥ 阈值）";
        T_excl_low = "排除暗对象（≤ 阈值）";
        T_excl_strict = "动态阈值（更严格）";

        T_excl_size_gate = "面积范围门控（推荐）";
        T_excl_minA = "最小面积（px²）";
        T_excl_maxA = "最大面积（px²）";

        T_data_format_enable = "启用数据格式化";
        T_data_format_rule = "文件名识别规则（pn/f）";
        T_data_format_cols = "表格列格式";
        T_data_opt_enable = "数据优化（IBR/PCR）";
        T_data_format_doc =
            "【数据格式化 - 规则说明】\n\n" +
            "A. 文件名识别规则（pn/f）：\n" +
            "  A.1 目的：从文件名中提取 项目名（pn） 与 编号（f）。\n" +
            "  A.2 语法：pn/f 或 f/pn（必须包含且仅包含一个“/”）。\n" +
            "  A.3 代号说明：\n" +
            "      - pn：项目名（非数字部分）。\n" +
            "      - f ：编号为“1,2,3...”格式（不带前导 0）。\n" +
            "      - f1：编号为“01,02,03...”或“001,002,003...”等带前导 0 的格式。\n" +
            "  A.4 说明：f 与 f1 仅用于识别编号格式，排序始终按数字大小。\n\n" +
            "B. 表格列格式：\n" +
            "  B.1 语法：列1/列2/列3（从左到右）。\n" +
            "  B.2 内置列代号（默认列名 / 含义）：\n" +
            "      - PN：PN / 项目名。\n" +
            "      - F：F / 编号。\n" +
            "      - TB：Total Beads / beads 总数。\n" +
            "      - BiC：Beads in Cells / 细胞内 beads 数。\n" +
            "      - CwB：Cells with Beads / 含 beads 的细胞数。\n" +
            "      - CwBa：Cells with Beads (Adj) / 含 beads 的细胞数（微量校正）。\n" +
            "      - TC：Total Cells / 细胞总数。\n" +
            "      - IBR：IBR / BiC / TB。\n" +
            "      - PCR：PCR / CwB / TC。\n" +
            "      - eIBR：eIBR / 项目内 IBR 平均。\n" +
            "      - ePCR：ePCR / 项目内 PCR 平均。\n" +
            "  B.3 自定义列：使用任意代号（不与内置代号重复）。\n" +
            "  B.4 参数：使用逗号分隔，格式为 name=\"...\" 或 value=\"...\"。\n" +
            "      - name：列名（可包含空格）。\n" +
            "      - value：该列所有行固定值。\n" +
            "  B.5 “$”前缀：仅用于自定义列，使该列只出现一次（不随项目名扩展）。\n\n" +
            "C. 符号注意：\n" +
            "  C.1 参数必须用逗号分隔；键和值之间用“=”。\n" +
            "  C.2 参数值必须使用英文双引号包裹。\n" +
            "  C.3 不允许空列项（避免出现连续“//”或首尾“/”）。\n";
        T_data_format_err_title = "数据格式化 - 输入错误";
        T_data_format_err_hint = "请修正后重试。";
        T_log_toggle_on = "启用";
        T_log_toggle_off = "关闭";

        T_err_df_rule_empty = "文件名识别规则为空。示例：pn/f 或 f/pn";
        T_err_df_rule_slash = "文件名识别规则必须包含且仅包含一个“/”。示例：pn/f 或 f/pn";
        T_err_df_rule_parts = "文件名识别规则的两部分都必须填写。";
        T_err_df_rule_tokens = "文件名识别规则只允许“pn”和“f/f1(或以f开头)”两类标记。";
        T_err_df_rule_need_both = "文件名识别规则必须同时包含 pn 与 f。";
        T_err_df_rule_order = "文件名识别规则顺序只允许 pn/f 或 f/pn。";
        T_err_df_cols_empty = "表格列格式为空。";
        T_err_df_cols_empty_item = "表格列格式包含空项（可能存在连续“//”或首尾“/”）。";
        T_err_df_cols_empty_token = "表格列格式中存在空列代号。";
        T_err_df_cols_params_comma = "参数必须使用逗号分隔，示例：X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "“$”后必须跟列代号。";
        T_err_df_cols_dollar_builtin = "“$”只能用于自定义列，不可用于内置列（PN/F/TB/BiC/CwB/CwBa/TC/IBR/PCR/eIBR/ePCR）。";
        T_err_df_cols_param_kv = "参数必须写成 key=\"value\" 形式。";
        T_err_df_cols_param_unknown_prefix = "未知参数：";
        T_err_df_cols_param_quote = "参数值必须用英文双引号包裹。示例：name=\"Cell with Beads\"";

        T_beads_type_title = "对象类型确认";
        T_beads_type_msg =
            "请确认图像中是否存在多种 beads 或易混淆对象。\n\n" +
            "• 若仅存在单一 beads 类型：建议不启用排除过滤。\n" +
            "• 若存在多种 beads 或明显干扰对象：建议启用排除过滤，并进行排除对象抽样。\n\n" +
            "说明：即使在此处选择启用排除过滤，你仍可在参数设置窗口中关闭该功能。";
        T_beads_type_checkbox = "包含多种 beads（启用排除过滤）";

        T_excl_note_few_samples = "灰度样本不足（<3）。推断阈值不可靠，建议在参数窗口手动设置。";
        T_excl_note_few_effective = "有效灰度样本不足（可能存在饱和或极端值）。推断阈值不可靠，建议手动设置。";
        T_excl_note_diff_small = "目标/排除灰度差异过小（<8）。推断阈值不可靠，建议手动设置。";
        T_excl_note_overlap_high = "灰度分布重叠较大：采用保守阈值（接近排除样本低分位），建议在参数窗口人工确认。";
        T_excl_note_good_sep_high = "分离良好：阈值由目标高分位与排除低分位共同估计。";
        T_excl_note_overlap_low = "灰度分布重叠较大：采用保守阈值（接近排除样本高分位），建议在参数窗口人工确认。";
        T_excl_note_good_sep_low = "分离良好：阈值由目标低分位与排除高分位共同估计。";

        T_err_need_window =
            "脚本在阶段 [%stage] 需要窗口但未找到。\n\n" +
            "窗口：%w\n" +
            "文件：%f\n\n" +
            "建议：关闭同名窗口、避免标题冲突后重试。";
        T_err_too_many_cells = "细胞 ROI 数量超过 65535：";
        T_err_too_many_cells_hint = "当前实现使用 1..65535 写入 16-bit 标签图。建议分批处理或减少 ROI 数量。";
        T_err_file = "文件：";
        T_err_roi1_invalid = "ROI[1] 非法（无有效 bounds）。无法生成细胞标签图。";
        T_err_labelmask_failed = "细胞标签图生成失败：填充后中心像素仍为 0。";
        T_err_labelmask_hint = "请检查 ROI[1] 是否为闭合面积 ROI，并确保 ROI 与图像区域有效重叠。";

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "✓ 开始：巨噬细胞四要素分析";
        T_log_lang = "  ├─ 语言：中文";
        T_log_dir = "  ├─ 文件夹：已选择";
        T_log_mode = "  └─ 模式：%s";
        T_log_roi_phase_start = "✓ 步骤：细胞 ROI 标注";
        T_log_roi_phase_done = "✓ 完成：细胞 ROI 标注";
        T_log_sampling_start = "✓ 步骤：目标 beads 抽样";
        T_log_sampling_cancel = "✓ 完成：抽样（用户结束抽样）";
        T_log_sampling_img = "  ├─ 抽样 [%i/%n]：%f";
        T_log_sampling_rois = "  │  └─ ROI 数量：%i";
        T_log_params_calc = "✓ 完成：默认参数已推断";
        T_log_main_start = "✓ 开始：批量分析（静默模式）";
        T_log_processing = "  ├─ 处理 [%i/%n]：%f";
        T_log_missing_roi = "  │  ⚠ 缺少 ROI：%f";
        T_log_missing_choice = "  │  └─ 选择：%s";
        T_log_load_roi = "  │  ├─ 加载 ROI";
        T_log_roi_count = "  │  │  └─ 细胞数：%i";
        T_log_bead_detect = "  │  ├─ 检测 beads 并统计";
        T_log_bead_count = "  │  │  ├─ beads 总数：%i";
        T_log_bead_incell = "  │  │  ├─ 细胞内 beads：%i";
        T_log_cell_withbead = "  │  │  └─ 含 beads 细胞：%i";
        T_log_bead_summary_done = "  │  │  └─ beads 统计完成";
        T_log_complete = "  │  └─ ✓ 完成";
        T_log_skip_roi = "  │  ✗ 跳过：缺少 ROI";
        T_log_skip_nocell = "  │  ✗ 跳过：ROI 中无有效细胞";
        T_log_results_save = "✓ 完成：结果已写入 Results 表";
        T_log_opt_done = "✓ 数据优化完成";
        T_log_all_done = "✓✓✓ 全部完成 ✓✓✓";
        T_log_summary = "📊 汇总：共处理 %i 张图像";
        T_log_unit_sync_keep = "  └─ beads 尺度：使用抽样推断值 = %s";
        T_log_unit_sync_ui = "  └─ beads 尺度：检测到手动修改，改用 UI 中值 = %s";
        T_log_analyze_header = "  ├─ 解析参数";
        T_log_analyze_img = "  ├─ 图像：%f";
        T_log_analyze_roi = "  │  ├─ ROI：%s";
        T_log_analyze_size = "  │  ├─ 尺寸：%w x %h";
        T_log_analyze_bead_params = "  │  ├─ beads 参数：area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_strict = "  │  ├─ 严格度：%strict，融合策略：%policy";
        T_log_analyze_bg = "  │  ├─ 背景扣除：rolling=%r";
        T_log_analyze_excl_on = "  │  ├─ 排除：mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  │  └─ 排除：未启用";
        T_log_analyze_method = "  │  └─ 检测流程：A=Yen+Mask+Watershed；B=Edges+Otsu+Mask+Watershed；融合=%policy";
        T_log_analyze_excl_adjust = "  │  └─ 动态阈值：mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  │  ├─ 细胞标签图：%s";
        T_log_label_mask_ok = "已生成";
        T_log_label_mask_fail = "生成失败";
        T_log_policy_strict = "严格";
        T_log_policy_union = "并集";
        T_log_policy_loose = "宽松";
        T_log_df_header = "  ├─ 数据格式化：自定义解析明细";
        T_log_df_rule = "  │  ├─ 规则：%s";
        T_log_df_cols = "  │  ├─ 列格式：%s";
        T_log_df_sort_asc = "  │  ├─ 排序：F 升序";
        T_log_df_sort_desc = "  │  ├─ 排序：F 降序";
        T_log_df_item = "  │  └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "未进行目标 beads 抽样：将使用默认 beads 尺度与默认 Rolling Ball。";
        T_reason_target_ok = "已基于目标 beads 抽样推断 beads 尺度与 Rolling Ball（稳健估计）。";
        T_reason_excl_on = "排除过滤已启用：阈值由排除抽样推断（如提示不可靠，请在参数窗口手动调整）。";
        T_reason_excl_off = "排除过滤未启用。";
        T_reason_excl_size_ok = "排除对象面积范围：已基于排除样本推断。";
        T_reason_excl_size_off = "未提供足够的排除 beads 面积样本：默认关闭面积门控。";

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
        T_choose = "画像と ROI ファイルを含むフォルダーを選択してください";
        T_exit = "フォルダーが選択されませんでした。スクリプトを終了します。";
        T_noImages = "選択したフォルダーに画像ファイル（tif/tiff/png/jpg/jpeg）が見つかりません。スクリプトを終了します。";
        T_exitScript = "ユーザー操作によりスクリプトを終了しました。";

        T_mode_title = "作業モード";
        T_mode_label = "モード";
        T_mode_1 = "細胞 ROI のみ作成（*_cells.zip を生成）";
        T_mode_2 = "4要素解析のみ（既存の細胞 ROI が必要）";
        T_mode_3 = "細胞 ROI 作成後に 4要素解析（推奨）";
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
        T_exist_edit = "読み込みして編集（推奨）";
        T_exist_redraw = "再作成して上書き保存";
        T_exist_skip = "この画像をスキップ（既存 ROI を保持）";
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

        T_missing_title = "細胞 ROI が不足しています";
        T_missing_label = "操作";
        T_missing_anno = "今ここで細胞 ROI を作成し、解析を継続する";
        T_missing_skip = "この画像をスキップ（結果は空）";
        T_missing_skip_all = "不足 ROI の画像をすべてスキップ（以後表示しない）";
        T_missing_exit = "スクリプトを終了";
        T_missing_msg =
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

        T_ddLabel = "次の操作";
        T_ddNext = "次の画像（サンプリング継続）";
        T_ddStep = "ターゲット抽出を終了して次へ（既定値を推定）";
        T_ddCompute = "除外抽出を終了して計算（パラメータ設定へ）";
        T_ddExit = "スクリプト終了";

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

        T_param = "パラメータ設定";
        T_param_note_title = "既定値の根拠と説明";
        T_section_target = "ターゲット beads";
        T_section_bg = "背景処理";
        T_section_roi = "細胞 ROI";
        T_section_excl = "除外フィルター（任意）";
        T_section_format = "データ整形";
        T_section_sep = "---- %s ----";

        T_minA = "ターゲット beads 最小面積（px^2）";
        T_maxA = "ターゲット beads 最大面積（px^2）";
        T_circ = "ターゲット beads 最小円形度（0–1）";
        T_allow_clumps = "塊を面積で分割して beads 数を推定する";
        T_min_phago_enable = "微量貪食は未貪食として扱う（動的しきい値、既定で有効）";

        T_strict = "検出の厳しさ";
        T_strict_S = "厳格（誤検出を抑制）";
        T_strict_N = "標準（推奨）";
        T_strict_L = "緩い（見落としを減らす）";

        T_roll = "背景補正 Rolling Ball 半径";
        T_suffix = "細胞 ROI ファイル接尾辞（拡張子なし）";

        T_excl_enable = "除外フィルターを有効化（濃度閾値）";
        T_excl_thr = "除外閾値（0–255）";
        T_excl_mode = "除外方向";
        T_excl_high = "明るい対象を除外（濃度 ≥ 閾値）";
        T_excl_low = "暗い対象を除外（濃度 ≤ 閾値）";
        T_excl_strict = "除外を強化（動的しきい値、より厳格）";

        T_excl_size_gate = "除外対象の面積範囲内のみ閾値除外を適用（推奨）";
        T_excl_minA = "除外対象 最小面積（px^2）";
        T_excl_maxA = "除外対象 最大面積（px^2）";

        T_data_format_enable = "データ整形を有効にする";
        T_data_format_rule = "ファイル名ルール（pn/f）";
        T_data_format_cols = "表の列フォーマット";
        T_data_opt_enable = "データ最適化（IBR/PCR）";
        T_data_format_doc =
            "【データ整形 - ルール説明】\n\n" +
            "A. ファイル名ルール（pn/f）：\n" +
            "  A.1 目的：ファイル名から プロジェクト名（pn）と番号（f）を抽出します。\n" +
            "  A.2 書式：pn/f または f/pn（“/”は1つだけ）。\n" +
            "  A.3 記号：\n" +
            "      - pn：プロジェクト名（数字以外の部分）。\n" +
            "      - f ：番号が“1,2,3...”の形式（先頭 0 なし）。\n" +
            "      - f1：番号が“01,02,03...”や“001,002,003...”の形式（先頭 0 あり）。\n" +
            "  A.4 補足：f と f1 は番号の書式判定のみ。並び順は数値で判定します。\n\n" +
            "B. 表の列フォーマット：\n" +
            "  B.1 書式：列1/列2/列3（左から右）。\n" +
            "  B.2 内蔵列コード（既定の列名 / 意味）：\n" +
            "      - PN：PN / プロジェクト名。\n" +
            "      - F：F / 番号。\n" +
            "      - TB：Total Beads / beads 総数。\n" +
            "      - BiC：Beads in Cells / 細胞内 beads 数。\n" +
            "      - CwB：Cells with Beads / beads を含む細胞数。\n" +
            "      - CwBa：Cells with Beads (Adj) / beads を含む細胞数（微量補正）。\n" +
            "      - TC：Total Cells / 細胞総数。\n" +
            "      - IBR：IBR / BiC / TB。\n" +
            "      - PCR：PCR / CwB / TC。\n" +
            "      - eIBR：eIBR / プロジェクト内 IBR 平均。\n" +
            "      - ePCR：ePCR / プロジェクト内 PCR 平均。\n" +
            "  B.3 カスタム列：任意のコード（内蔵列と重複不可）。\n" +
            "  B.4 パラメータ：カンマ区切りで name=\"...\" または value=\"...\"。\n" +
            "      - name：列名（空白可）。\n" +
            "      - value：全行に固定値。\n" +
            "  B.5 “$”接頭：カスタム列のみ。列は1回だけ表示（PN 拡張しない）。\n\n" +
            "C. 記号注意：\n" +
            "  C.1 パラメータはカンマ区切り、キーと値は“=”で接続。\n" +
            "  C.2 値は英語の二重引用符で囲む。\n" +
            "  C.3 空の列は禁止（“//”や先頭/末尾“/”は不可）。\n";
        T_data_format_err_title = "データ整形 - 入力エラー";
        T_data_format_err_hint = "修正して再試行してください。";
        T_log_toggle_on = "有効";
        T_log_toggle_off = "無効";

        T_err_df_rule_empty = "ファイル名ルールが空です。例：pn/f または f/pn";
        T_err_df_rule_slash = "ファイル名ルールは“/”を1つだけ含めてください。例：pn/f または f/pn";
        T_err_df_rule_parts = "ファイル名ルールの2つの要素をどちらも入力してください。";
        T_err_df_rule_tokens = "ファイル名ルールは“pn”と“f/f1(またはfで始まる)”のみ使用できます。";
        T_err_df_rule_need_both = "ファイル名ルールには pn と f の両方が必要です。";
        T_err_df_rule_order = "ファイル名ルールの順序は pn/f または f/pn のみです。";
        T_err_df_cols_empty = "列フォーマットが空です。";
        T_err_df_cols_empty_item = "列フォーマットに空項目があります（“//”や先頭/末尾“/”の可能性）。";
        T_err_df_cols_empty_token = "列フォーマットに空の列コードがあります。";
        T_err_df_cols_params_comma = "パラメータはカンマ区切りで指定してください。例：X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "“$”の後には列コードが必要です。";
        T_err_df_cols_dollar_builtin = "“$”はカスタム列のみ使用できます（PN/F/TB/BiC/CwB/CwBa/TC/IBR/PCR/eIBR/ePCR は不可）。";
        T_err_df_cols_param_kv = "パラメータは key=\"value\" 形式で指定してください。";
        T_err_df_cols_param_unknown_prefix = "不明なパラメータ：";
        T_err_df_cols_param_quote = "値は英語の二重引用符で囲んでください。例：name=\"Cell with Beads\"";

        T_beads_type_title = "対象タイプの確認";
        T_beads_type_msg =
            "画像に複数種類の beads または混同しやすい対象が含まれるか確認してください。\n\n" +
            "• 単一タイプの場合：除外フィルターは通常不要です。\n" +
            "• 複数タイプ/干渉物がある場合：除外フィルターを有効にし、除外サンプリングを推奨します。\n\n" +
            "説明：ここで有効にしても、後のパラメータ設定で無効化できます。";
        T_beads_type_checkbox = "複数種類が存在する（除外フィルターを有効化）";

        T_excl_note_few_samples = "濃度サンプルが不足しています（<3）。推定は信頼できません。手動設定を推奨します。";
        T_excl_note_few_effective = "有効な濃度サンプルが不足しています（飽和などの可能性）。手動設定を推奨します。";
        T_excl_note_diff_small = "ターゲットと除外の濃度差が小さすぎます（<8）。手動設定を推奨します。";
        T_excl_note_overlap_high = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の低分位に近い）。確認を推奨します。";
        T_excl_note_good_sep_high = "分離が良好です。ターゲット高分位と除外低分位から閾値を推定しました。";
        T_excl_note_overlap_low = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の高分位に近い）。確認を推奨します。";
        T_excl_note_good_sep_low = "分離が良好です。ターゲット低分位と除外高分位から閾値を推定しました。";

        T_err_need_window =
            "ステージ [%stage] で必要なウィンドウが見つかりません。\n\n" +
            "ウィンドウ：%w\n" +
            "ファイル：%f\n\n" +
            "対処：同名ウィンドウを閉じ、タイトル衝突を避けて再試行してください。";
        T_err_too_many_cells = "細胞 ROI 数が 65535 を超えています：";
        T_err_too_many_cells_hint = "現在の実装では 1..65535 を 16-bit ラベル値として使用します。分割処理または ROI 数の削減を推奨します。";
        T_err_file = "ファイル：";
        T_err_roi1_invalid = "ROI[1] が不正です（有効な bounds がありません）。ラベル画像を生成できません。";
        T_err_labelmask_failed = "細胞ラベル画像の生成に失敗しました。塗りつぶし後の中心画素が 0 のままです。";
        T_err_labelmask_hint = "ROI[1] が閉じた面積 ROI であり、画像と有効に重なっているか確認してください。";

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "✓ 開始：マクロファージ 4要素解析";
        T_log_lang = "  ├─ 言語：日本語";
        T_log_dir = "  ├─ フォルダー：選択済み";
        T_log_mode = "  └─ モード：%s";
        T_log_roi_phase_start = "✓ 手順：細胞 ROI 作成";
        T_log_roi_phase_done = "✓ 完了：細胞 ROI 作成";
        T_log_sampling_start = "✓ 手順：ターゲット beads サンプリング";
        T_log_sampling_cancel = "✓ 完了：サンプリング（ユーザー終了）";
        T_log_sampling_img = "  ├─ サンプル [%i/%n]：%f";
        T_log_sampling_rois = "  │  └─ ROI 数：%i";
        T_log_params_calc = "✓ 完了：既定パラメータを推定しました";
        T_log_main_start = "✓ 開始：バッチ解析（サイレント）";
        T_log_processing = "  ├─ 処理 [%i/%n]：%f";
        T_log_missing_roi = "  │  ⚠ ROI 不足：%f";
        T_log_missing_choice = "  │  └─ 選択：%s";
        T_log_load_roi = "  │  ├─ ROI を読み込み";
        T_log_roi_count = "  │  │  └─ 細胞数：%i";
        T_log_bead_detect = "  │  ├─ beads を検出して集計";
        T_log_bead_count = "  │  │  ├─ beads 合計：%i";
        T_log_bead_incell = "  │  │  ├─ 細胞内 beads：%i";
        T_log_cell_withbead = "  │  │  └─ beads を含む細胞：%i";
        T_log_bead_summary_done = "  │  │  └─ beads 集計完了";
        T_log_complete = "  │  └─ ✓ 完了";
        T_log_skip_roi = "  │  ✗ スキップ：ROI 不足";
        T_log_skip_nocell = "  │  ✗ スキップ：ROI に有効な細胞がありません";
        T_log_results_save = "✓ 完了：Results 表に出力しました";
        T_log_opt_done = "✓ データ最適化完了";
        T_log_all_done = "✓✓✓ 完了 ✓✓✓";
        T_log_summary = "📊 サマリー：合計 %i 枚を処理";
        T_log_unit_sync_keep = "  └─ beads スケール：サンプル推定値を使用 = %s";
        T_log_unit_sync_ui = "  └─ beads スケール：手動変更を検出。UI 中値を使用 = %s";
        T_log_analyze_header = "  ├─ 解析パラメータ";
        T_log_analyze_img = "  ├─ 画像：%f";
        T_log_analyze_roi = "  │  ├─ ROI：%s";
        T_log_analyze_size = "  │  ├─ サイズ：%w x %h";
        T_log_analyze_bead_params = "  │  ├─ beads パラメータ：area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_strict = "  │  ├─ 厳密度：%strict，統合ポリシー：%policy";
        T_log_analyze_bg = "  │  ├─ 背景補正：rolling=%r";
        T_log_analyze_excl_on = "  │  ├─ 除外：mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  │  └─ 除外：無効";
        T_log_analyze_method = "  │  └─ 検出手順：A=Yen+Mask+Watershed；B=Edges+Otsu+Mask+Watershed；統合=%policy";
        T_log_analyze_excl_adjust = "  │  └─ 動的閾値：mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  │  ├─ 細胞ラベル画像：%s";
        T_log_label_mask_ok = "生成済み";
        T_log_label_mask_fail = "生成失敗";
        T_log_policy_strict = "厳格";
        T_log_policy_union = "統合";
        T_log_policy_loose = "緩い";
        T_log_df_header = "  ├─ データ整形：カスタム解析の詳細";
        T_log_df_rule = "  │  ├─ ルール：%s";
        T_log_df_cols = "  │  ├─ 列フォーマット：%s";
        T_log_df_sort_asc = "  │  ├─ ソート：F 昇順";
        T_log_df_sort_desc = "  │  ├─ ソート：F 降順";
        T_log_df_item = "  │  └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "ターゲット beads のサンプリングなし：既定の beads スケールと Rolling Ball を使用します。";
        T_reason_target_ok = "ターゲット beads サンプルから beads スケールと Rolling Ball を推定しました（ロバスト推定）。";
        T_reason_excl_on = "除外フィルター有効：除外サンプルから閾値を推定しました（不確実な場合は手動で調整してください）。";
        T_reason_excl_off = "除外フィルター無効。";
        T_reason_excl_size_ok = "除外対象の面積範囲：除外サンプルから推定しました。";
        T_reason_excl_size_off = "除外 beads の面積サンプルが不足：面積ゲートは無効（既定）です。";

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
        T_choose = "Select the folder containing image and ROI files";
        T_exit = "No folder was selected. The script has ended.";
        T_noImages = "No image files were found in the selected folder (tif/tiff/png/jpg/jpeg). The script has ended.";
        T_exitScript = "The script was exited by user selection.";

        T_mode_title = "Work Mode";
        T_mode_label = "Mode";
        T_mode_1 = "Annotate cell ROIs only (create *_cells.zip)";
        T_mode_2 = "Analyze only (requires existing cell ROIs)";
        T_mode_3 = "Annotate cell ROIs, then analyze (recommended)";
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
        T_exist_edit = "Load and continue editing (recommended)";
        T_exist_redraw = "Re-annotate and overwrite";
        T_exist_skip = "Skip this image (keep existing ROI)";
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

        T_missing_title = "Missing cell ROI";
        T_missing_label = "Action";
        T_missing_anno = "Annotate cell ROI now, then continue analysis";
        T_missing_skip = "Skip this image (leave blank results)";
        T_missing_skip_all = "Skip all missing-ROI images (do not ask again)";
        T_missing_exit = "Exit script";
        T_missing_msg =
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

        T_ddLabel = "Next action";
        T_ddNext = "Next image (continue sampling)";
        T_ddStep = "Finish target sampling and proceed (compute defaults)";
        T_ddCompute = "Finish exclusion sampling and compute (open parameters)";
        T_ddExit = "Exit script";

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

        T_param = "Parameters";
        T_param_note_title = "Rationale and notes";
        T_section_target = "Target beads";
        T_section_bg = "Background";
        T_section_roi = "Cell ROI";
        T_section_excl = "Exclusion (optional)";
        T_section_format = "Data Formatting";
        T_section_sep = "---- %s ----";

        T_minA = "Target bead minimum area (px^2)";
        T_maxA = "Target bead maximum area (px^2)";
        T_circ = "Target bead minimum circularity (0–1)";
        T_allow_clumps = "Estimate bead counts from clumps by area";
        T_min_phago_enable = "Treat tiny uptake as no uptake (dynamic threshold, default on)";

        T_strict = "Detection strictness";
        T_strict_S = "Strict (reduce false positives)";
        T_strict_N = "Normal (recommended)";
        T_strict_L = "Loose (reduce false negatives)";

        T_roll = "Background Rolling Ball radius";
        T_suffix = "Cell ROI file suffix (without extension)";

        T_excl_enable = "Enable exclusion filter (intensity threshold)";
        T_excl_thr = "Exclusion threshold (0–255)";
        T_excl_mode = "Exclusion direction";
        T_excl_high = "Exclude brighter objects (intensity ≥ threshold)";
        T_excl_low = "Exclude darker objects (intensity ≤ threshold)";
        T_excl_strict = "Stronger exclusion (dynamic threshold, stricter)";

        T_excl_size_gate = "Apply exclusion only within an exclusion size range (recommended)";
        T_excl_minA = "Exclusion minimum area (px^2)";
        T_excl_maxA = "Exclusion maximum area (px^2)";

        T_data_format_enable = "Enable data formatting";
        T_data_format_rule = "Filename rule (pn/f)";
        T_data_format_cols = "Table column format";
        T_data_opt_enable = "Data optimization (IBR/PCR)";
        T_data_format_doc =
            "【Data Formatting - Rules】\n\n" +
            "A. Filename rule (pn/f):\n" +
            "  A.1 Purpose: extract Project Name (pn) and index (f) from filenames.\n" +
            "  A.2 Syntax: pn/f or f/pn (exactly one “/”).\n" +
            "  A.3 Tokens:\n" +
            "      - pn: project name (non-digit part).\n" +
            "      - f : index in “1,2,3...” format (no leading zeros).\n" +
            "      - f1: index in “01,02,03...” or “001,002,003...” format (leading zeros).\n" +
            "  A.4 Note: f vs f1 only affects parsing format; sorting is always numeric.\n\n" +
            "B. Table column format:\n" +
            "  B.1 Syntax: col1/col2/col3 (left to right).\n" +
            "  B.2 Built-in codes (default label / meaning):\n" +
            "      - PN: PN / Project name.\n" +
            "      - F: F / Index.\n" +
            "      - TB: Total Beads / total beads.\n" +
            "      - BiC: Beads in Cells / beads inside cells.\n" +
            "      - CwB: Cells with Beads / cells containing beads.\n" +
            "      - CwBa: Cells with Beads (Adj) / cells with beads (adjusted).\n" +
            "      - TC: Total Cells / total cells.\n" +
            "      - IBR: IBR / BiC / TB.\n" +
            "      - PCR: PCR / CwB / TC.\n" +
            "      - eIBR: eIBR / mean IBR within project.\n" +
            "      - ePCR: ePCR / mean PCR within project.\n" +
            "  B.3 Custom columns: any code not conflicting with built-ins.\n" +
            "  B.4 Params: comma-separated name=\"...\" or value=\"...\".\n" +
            "      - name: column label (spaces allowed).\n" +
            "      - value: constant value for all rows.\n" +
            "  B.5 “$” prefix: custom columns only; show once (no PN expansion).\n\n" +
            "C. Symbol notes:\n" +
            "  C.1 Params must be comma-separated; key and value joined with “=”.\n" +
            "  C.2 Values must be wrapped in English double quotes.\n" +
            "  C.3 Empty items are not allowed (avoid “//” or leading/trailing “/”).\n";
        T_data_format_err_title = "Data Formatting - Input Error";
        T_data_format_err_hint = "Please correct the input and try again.";
        T_log_toggle_on = "ON";
        T_log_toggle_off = "OFF";

        T_err_df_rule_empty = "Filename rule is empty. Example: pn/f or f/pn";
        T_err_df_rule_slash = "Filename rule must contain exactly one \"/\". Example: pn/f or f/pn";
        T_err_df_rule_parts = "Both parts of the filename rule must be filled.";
        T_err_df_rule_tokens = "Filename rule allows only \"pn\" and \"f/f1\" (or tokens starting with f).";
        T_err_df_rule_need_both = "Filename rule must include both pn and f.";
        T_err_df_rule_order = "Filename rule order must be pn/f or f/pn.";
        T_err_df_cols_empty = "Table column format is empty.";
        T_err_df_cols_empty_item = "Table column format contains an empty item (possible \"//\" or leading/trailing \"/\").";
        T_err_df_cols_empty_token = "Table column format has an empty column code.";
        T_err_df_cols_params_comma = "Parameters must be comma-separated. Example: X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "\"$\" must be followed by a column code.";
        T_err_df_cols_dollar_builtin = "\"$\" can only be used for custom columns (not PN/F/TB/BiC/CwB/CwBa/TC/IBR/PCR/eIBR/ePCR).";
        T_err_df_cols_param_kv = "Parameters must use key=\"value\" format.";
        T_err_df_cols_param_unknown_prefix = "Unknown parameter: ";
        T_err_df_cols_param_quote = "Parameter values must be wrapped in English double quotes. Example: name=\"Cell with Beads\"";

        T_beads_type_title = "Object type confirmation";
        T_beads_type_msg =
            "Confirm whether multiple bead types or confounding objects are present.\n\n" +
            "• Single bead type: exclusion is typically unnecessary.\n" +
            "• Multiple bead types / confounders: exclusion is recommended; run exclusion sampling.\n\n" +
            "Note: You can still disable exclusion later in the Parameters dialog.";
        T_beads_type_checkbox = "Multiple bead types present (enable exclusion)";

        T_excl_note_few_samples = "Not enough intensity samples (<3). The inferred threshold is unreliable; set it manually.";
        T_excl_note_few_effective = "Not enough effective intensity samples (possible saturation). The inferred threshold is unreliable; set it manually.";
        T_excl_note_diff_small = "Target/exclusion intensity difference is too small (<8). The inferred threshold is unreliable; set it manually.";
        T_excl_note_overlap_high = "Distributions overlap substantially; a conservative threshold was chosen (near exclusion low quantile). Review recommended.";
        T_excl_note_good_sep_high = "Separation is good; threshold estimated from target high quantile and exclusion low quantile.";
        T_excl_note_overlap_low = "Distributions overlap substantially; a conservative threshold was chosen (near exclusion high quantile). Review recommended.";
        T_excl_note_good_sep_low = "Separation is good; threshold estimated from target low quantile and exclusion high quantile.";

        T_err_need_window =
            "The required window was not found at stage [%stage].\n\n" +
            "Window: %w\n" +
            "File: %f\n\n" +
            "Recommendation: Close any window with the same title and retry to avoid title collisions.";
        T_err_too_many_cells = "Cell ROI count exceeds 65535:";
        T_err_too_many_cells_hint = "This implementation encodes labels in the range 1..65535 using 16-bit. Process in smaller batches or reduce the ROI count.";
        T_err_file = "File:";
        T_err_roi1_invalid = "ROI[1] is invalid (no valid bounds). Cannot generate the cell label image.";
        T_err_labelmask_failed = "Cell label image generation failed: the center pixel is still 0 after filling.";
        T_err_labelmask_hint = "Verify that ROI[1] is a closed area ROI and overlaps the image content.";

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "✓ Start: Macrophage four-factor analysis";
        T_log_lang = "  ├─ Language: English";
        T_log_dir = "  ├─ Folder: selected";
        T_log_mode = "  └─ Mode: %s";
        T_log_roi_phase_start = "✓ Step: Cell ROI annotation";
        T_log_roi_phase_done = "✓ Complete: Cell ROI annotation";
        T_log_sampling_start = "✓ Step: Target bead sampling";
        T_log_sampling_cancel = "✓ Complete: Sampling (finished by user)";
        T_log_sampling_img = "  ├─ Sample [%i/%n]: %f";
        T_log_sampling_rois = "  │  └─ ROI count: %i";
        T_log_params_calc = "✓ Complete: Default parameters inferred";
        T_log_main_start = "✓ Start: Batch analysis (silent mode)";
        T_log_processing = "  ├─ Processing [%i/%n]: %f";
        T_log_missing_roi = "  │  ⚠ Missing ROI: %f";
        T_log_missing_choice = "  │  └─ Action: %s";
        T_log_load_roi = "  │  ├─ Load ROI";
        T_log_roi_count = "  │  │  └─ Cell count: %i";
        T_log_bead_detect = "  │  ├─ Detect beads and compute statistics";
        T_log_bead_count = "  │  │  ├─ Total beads: %i";
        T_log_bead_incell = "  │  │  ├─ Beads in cells: %i";
        T_log_cell_withbead = "  │  │  └─ Cells with beads: %i";
        T_log_bead_summary_done = "  │  │  └─ Bead statistics completed";
        T_log_complete = "  │  └─ ✓ Done";
        T_log_skip_roi = "  │  ✗ Skipped: missing ROI";
        T_log_skip_nocell = "  │  ✗ Skipped: no valid cells in ROI";
        T_log_results_save = "✓ Complete: Results written to the Results table";
        T_log_opt_done = "✓ Data optimization completed";
        T_log_all_done = "✓✓✓ All tasks completed ✓✓✓";
        T_log_summary = "📊 Summary: %i images processed";
        T_log_unit_sync_keep = "  └─ Bead scale: using inferred value = %s";
        T_log_unit_sync_ui = "  └─ Bead scale: manual change detected; using UI midpoint = %s";
        T_log_analyze_header = "  ├─ Analysis parameters";
        T_log_analyze_img = "  ├─ Image: %f";
        T_log_analyze_roi = "  │  ├─ ROI: %s";
        T_log_analyze_size = "  │  ├─ Size: %w x %h";
        T_log_analyze_bead_params = "  │  ├─ Bead params: area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_strict = "  │  ├─ Strictness: %strict, merge policy: %policy";
        T_log_analyze_bg = "  │  ├─ Background subtraction: rolling=%r";
        T_log_analyze_excl_on = "  │  ├─ Exclusion: mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  │  └─ Exclusion: disabled";
        T_log_analyze_method = "  │  └─ Detection flow: A=Yen+Mask+Watershed; B=Edges+Otsu+Mask+Watershed; merge=%policy";
        T_log_analyze_excl_adjust = "  │  └─ Dynamic threshold: mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  │  ├─ Cell label mask: %s";
        T_log_label_mask_ok = "generated";
        T_log_label_mask_fail = "failed";
        T_log_policy_strict = "STRICT";
        T_log_policy_union = "UNION";
        T_log_policy_loose = "LOOSE";
        T_log_df_header = "  ├─ Data formatting: custom parsing details";
        T_log_df_rule = "  │  ├─ Rule: %s";
        T_log_df_cols = "  │  ├─ Column format: %s";
        T_log_df_sort_asc = "  │  ├─ Sort: F ascending";
        T_log_df_sort_desc = "  │  ├─ Sort: F descending";
        T_log_df_item = "  │  └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "No target bead sampling was performed: using default bead scale and default Rolling Ball.";
        T_reason_target_ok = "Bead scale and Rolling Ball were inferred from target samples (robust estimation).";
        T_reason_excl_on = "Exclusion is enabled: threshold inferred from exclusion samples (adjust manually if flagged unreliable).";
        T_reason_excl_off = "Exclusion is disabled.";
        T_reason_excl_size_ok = "Exclusion size range inferred from exclusion bead samples.";
        T_reason_excl_size_off = "Not enough exclusion bead size samples: size gate is disabled by default.";

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

    // -----------------------------------------------------------------------------
    // フェーズ3: 作業モード選択（ROIのみ / 解析のみ / ROI+解析）
    // -----------------------------------------------------------------------------
    Dialog.create(T_mode_title);
    Dialog.addMessage(T_mode_msg);
    Dialog.addChoice(T_mode_label, newArray(T_mode_1, T_mode_2, T_mode_3), T_mode_3);
    Dialog.show();
    modeChoice = Dialog.getChoice();

    doROI = (modeChoice == T_mode_1) || (modeChoice == T_mode_3);
    doAnalyze = (modeChoice == T_mode_2) || (modeChoice == T_mode_3);

    // -----------------------------------------------------------------------------
    // フェーズ4: フォルダ選択と画像ファイル一覧の構築
    // -----------------------------------------------------------------------------
    dir = getDirectory(T_choose);
    if (dir == "") exit(T_exit);

    // 画像ファイルのみを抽出してソートする
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
    while (k < imgFiles.length) {
        imgFilesSorted[k] = imgFiles[k];
        k = k + 1;
    }
    Array.sort(imgFilesSorted);

    // サンプリング用にランダム順リストも作成する
    imgFilesSample = newArray(imgFilesSorted.length);
    k = 0;
    while (k < imgFilesSorted.length) {
        imgFilesSample[k] = imgFilesSorted[k];
        k = k + 1;
    }

    k = imgFilesSample.length - 1;
    while (k > 0) {
        j = floor(random() * (k + 1));
        swap = imgFilesSample[k];
        imgFilesSample[k] = imgFilesSample[j];
        imgFilesSample[j] = swap;
        k = k - 1;
    }

    roiSuffix = "_cells";
    nTotalImgs = imgFilesSorted.length;

    // 画像名とROIパスの対応表を作成する
    bases = newArray(nTotalImgs);
    roiPaths = newArray(nTotalImgs);
    k = 0;
    while (k < nTotalImgs) {
        bases[k] = getBaseName(imgFilesSorted[k]);
        roiPaths[k] = dir + bases[k] + roiSuffix + ".zip";
        k = k + 1;
    }

    log(T_log_sep);
    log(T_log_start);
    log(T_log_lang);
    log(T_log_dir);
    log(replaceSafe(T_log_mode, "%s", modeChoice));
    log(T_log_sep);

    run("ROI Manager...");

    SKIP_ALL_EXISTING_ROI = 0;

    // -----------------------------------------------------------------------------
    // フェーズ5: 細胞ROIの標注（必要時のみ）
    // -----------------------------------------------------------------------------
    if (doROI) {
        waitForUser(T_step_roi_title, replaceSafe(T_step_roi_msg, "%s", roiSuffix));
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
        // -----------------------------------------------------------------------------
        // ROIのみ実行時はここで終了する
        // -----------------------------------------------------------------------------
        maybePrintMotto();
        exit("");
    }

    // -----------------------------------------------------------------------------
    // フェーズ6: 目標beadsのサンプリング
    // -----------------------------------------------------------------------------
    waitForUser(T_step_bead_title, T_step_bead_msg);
    log(T_log_sampling_start);

    Dialog.create(T_beads_type_title);
    Dialog.addMessage(T_beads_type_msg);
    Dialog.addCheckbox(T_beads_type_checkbox, false);
    Dialog.show();
    HAS_MULTI_BEADS = Dialog.getCheckbox();

    targetAreas = newArray();
    targetMeans = newArray();
    exclMeansAll = newArray();
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

        // サンプル用画像を開き、ROIを追加してもらう
        open(dir + imgName);
        ensure2D();
        forcePixelUnit();
        origTitle = getTitle();

        setTool("oval");
        roiManager("Reset");
        roiManager("Show All");

        msg = T_promptAddROI;
        msg = replaceSafe(msg, "%i", "" + (s + 1));
        msg = replaceSafe(msg, "%n", "" + nTotalImgs);
        msg = replaceSafe(msg, "%f", imgName);
        waitForUser(T_sampling + " - " + imgName, msg);

        Dialog.create(T_sampling + " - " + imgName);
        Dialog.addMessage(T_ddInfo_target);
        Dialog.addChoice(T_ddLabel, newArray(T_ddNext, T_ddStep, T_ddExit), T_ddNext);
        Dialog.show();
        act = Dialog.getChoice();

        if (act == T_ddExit) {
            selectWindow(origTitle);
            close();
            exit(T_exitScript);
        }

        nR = roiManager("count");
        log(replaceSafe(T_log_sampling_rois, "%i", "" + nR));

        if (nR > 0) {
            // 8-bit画像でROIを計測して面積・平均灰度を収集する
            safeClose("__tmp8_target");
            selectWindow(origTitle);
            run("Duplicate...", "title=__tmp8_target");
            requireWindow("__tmp8_target", "sampling/target/tmp8", imgName);
            run("8-bit");

            run("Clear Results");
            roiManager("Measure");

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

        selectWindow(origTitle);
        close();

        if (act == T_ddStep) {
            log(T_log_sampling_cancel);
            break;
        }

        s = s + 1;
    }

    // -----------------------------------------------------------------------------
    // フェーズ7: 排除対象のサンプリング（必要時のみ）
    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {

        waitForUser(T_step_bead_ex_title, T_step_bead_ex_msg);

        s = 0;
        while (s < nTotalImgs) {

            imgName = imgFilesSample[s];
            printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, imgName);

            // 排除対象のサンプルを収集する
            open(dir + imgName);
            ensure2D();
            forcePixelUnit();
            origTitle = getTitle();

            roiManager("Reset");
            roiManager("Show All");

            msg = T_promptAddROI_EX;
            msg = replaceSafe(msg, "%i", "" + (s + 1));
            msg = replaceSafe(msg, "%n", "" + nTotalImgs);
            msg = replaceSafe(msg, "%f", imgName);
            waitForUser(T_sampling + " - " + imgName, msg);

            Dialog.create(T_sampling + " - " + imgName);
            Dialog.addMessage(T_ddInfo_excl);
            Dialog.addChoice(T_ddLabel, newArray(T_ddNext, T_ddCompute, T_ddExit), T_ddNext);
            Dialog.show();
            act = Dialog.getChoice();

            if (act == T_ddExit) {
                selectWindow(origTitle);
                close();
                exit(T_exitScript);
            }

            nR = roiManager("count");
            log(replaceSafe(T_log_sampling_rois, "%i", "" + nR));

            if (nR > 0) {

                // 8-bit画像でROIを計測して灰度分布と面積の候補を収集する
                safeClose("__tmp8_excl");
                selectWindow(origTitle);
                run("Duplicate...", "title=__tmp8_excl");
                requireWindow("__tmp8_excl", "sampling/excl/tmp8", imgName);
                run("8-bit");

                run("Clear Results");
                roiManager("Measure");

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

            selectWindow(origTitle);
            close();

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
    exclThr = 255;
    useExclStrict = 1;

    useExclSizeGate = 1;
    defExMinA = DEF_MINA;
    defExMaxA = DEF_MAXA;

    dataFormatEnable = 1;
    dataFormatRule = "pn/f";
    dataFormatCols = "TB/BiC/CwBa,name=\"Cell with Beads\"/TC/IBR/PCR/eIBR/ePCR";
    dataOptimizeEnable = 1;

    // -----------------------------------------------------------------------------
    // フェーズ8: パラメータ推定（面積・閾値・Rolling Ball）
    // -----------------------------------------------------------------------------
    if (targetAreas.length == 0) {
        reasonMsg = reasonMsg + "• " + T_reason_no_target + "\n";
    } else {
        // 目標beadsの面積範囲と代表値を推定する
        range = estimateAreaRangeSafe(targetAreas, DEF_MINA, DEF_MAXA);
        defMinA = range[0];
        defMaxA = range[1];
        beadUnitArea = range[2];
        defRoll = estimateRollingFromUnitArea(beadUnitArea);
        reasonMsg = reasonMsg + "• " + T_reason_target_ok + "\n";
    }

    // -----------------------------------------------------------------------------
    // 排除対象がある場合は灰度/面積の推定を行う
    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {
        useExcl = 1;

        // 排除対象の灰度分布から閾値と方向を推定する
        exInfo = estimateExclusionSafe(targetMeans, exclMeansAll);
        exclMode = exInfo[1];
        exclThr = exInfo[2];

        reasonMsg = reasonMsg + "• " + T_reason_excl_on + "\n";
        reasonMsg = reasonMsg + "  - " + exInfo[4] + "\n";

        if (exclAreasBead.length > 0) {
            // 排除beadsの面積範囲も推定する
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

    // -----------------------------------------------------------------------------
    // フェーズ9: パラメータ確認ダイアログ
    // -----------------------------------------------------------------------------
    Dialog.create(T_param);
    Dialog.addMessage(T_param_note_title + ":\n" + reasonMsg);

    Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_target));
    Dialog.addNumber(T_minA, defMinA);
    Dialog.addNumber(T_maxA, defMaxA);
    Dialog.addNumber(T_circ, defCirc);
    Dialog.addCheckbox(T_allow_clumps, (defAllowClumps == 1));
    Dialog.addCheckbox(T_min_phago_enable, true);

    Dialog.addChoice(T_strict, newArray(T_strict_S, T_strict_N, T_strict_L), T_strict_N);

    Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_bg));
    Dialog.addNumber(T_roll, defRoll);

    Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_roi));
    Dialog.addString(T_suffix, roiSuffix);

    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {
        Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_excl));
        Dialog.addCheckbox(T_excl_enable, (useExcl == 1));
        Dialog.addChoice(T_excl_mode, newArray(T_excl_high, T_excl_low), exclModeDefault);
        Dialog.addNumber(T_excl_thr, exclThr);
        Dialog.addCheckbox(T_excl_strict, (useExclStrict == 1));

        Dialog.addCheckbox(T_excl_size_gate, (useExclSizeGate == 1));
        Dialog.addNumber(T_excl_minA, defExMinA);
        Dialog.addNumber(T_excl_maxA, defExMaxA);
    }

    Dialog.show();

    beadMinArea = Dialog.getNumber();
    beadMaxArea = Dialog.getNumber();
    beadMinCirc = Dialog.getNumber();

    if (Dialog.getCheckbox()) allowClumpsTarget = 1;
    else allowClumpsTarget = 0;

    if (Dialog.getCheckbox()) useMinPhago = 1;
    else useMinPhago = 0;

    strictChoice = Dialog.getChoice();
    rollingRadius = Dialog.getNumber();
    roiSuffix = Dialog.getString();

    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {
        if (Dialog.getCheckbox()) useExclUI = 1;
        else useExclUI = 0;

        exModeChoice = Dialog.getChoice();
        exThrUI = Dialog.getNumber();

        if (Dialog.getCheckbox()) useExclStrictUI = 1;
        else useExclStrictUI = 0;

        if (Dialog.getCheckbox()) useExclSizeGateUI = 1;
        else useExclSizeGateUI = 0;

        exclMinA_UI = Dialog.getNumber();
        exclMaxA_UI = Dialog.getNumber();
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

    // -----------------------------------------------------------------------------
    // フェーズ10: パラメータ検証と正規化
    // -----------------------------------------------------------------------------
    EPS_A = 0.000001;

    USER_CHANGED_UNIT = 0;
    if (abs2(beadMinArea - defMinA) > EPS_A) USER_CHANGED_UNIT = 1;
    if (abs2(beadMaxArea - defMaxA) > EPS_A) USER_CHANGED_UNIT = 1;

    // UIで面積が変更された場合は代表面積をUI値に合わせる
    uiMid = (beadMinArea + beadMaxArea) / 2.0;
    if (uiMid < 1) uiMid = 1;

    if (USER_CHANGED_UNIT == 1) {
        beadUnitArea = uiMid;
        log(replaceSafe(T_log_unit_sync_ui, "%s", "" + beadUnitArea));
    } else {
        log(replaceSafe(T_log_unit_sync_keep, "%s", "" + beadUnitArea));
    }

    if (beadUnitArea < 1) beadUnitArea = 1;

    // 厳密度に応じて実際の検出範囲を拡縮する
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

    // 排除フィルタのUI値を内部パラメータへ反映する
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

    // -----------------------------------------------------------------------------
    // フェーズ11: データ形式の設定（ドキュメント付き、バリデーションあり）
    // -----------------------------------------------------------------------------
    docMsg = T_data_format_doc;

    while (1) {
        Dialog.create(T_section_format);
        Dialog.addMessage(docMsg);
        Dialog.addCheckbox(T_data_format_enable, (dataFormatEnable == 1));
        Dialog.addString(T_data_format_rule, dataFormatRule);
        Dialog.addString(T_data_format_cols, dataFormatCols);
        Dialog.addCheckbox(T_data_opt_enable, (dataOptimizeEnable == 1));
        Dialog.show();

        if (Dialog.getCheckbox()) dataFormatEnable = 1;
        else dataFormatEnable = 0;
        dataFormatRule = Dialog.getString();
        dataFormatCols = Dialog.getString();
        if (Dialog.getCheckbox()) dataOptimizeEnable = 1;
        else dataOptimizeEnable = 0;

        errMsg = "";
        if (dataFormatEnable == 1) {
            errMsg = validateDataFormatRule(dataFormatRule);
            if (errMsg == "") errMsg = validateDataFormatCols(dataFormatCols);
        }

        if (errMsg == "") break;
        showMessage(T_data_format_err_title, errMsg + "\n\n" + T_data_format_err_hint);
    }

    waitForUser(T_step_main_title, T_step_main_msg);

    log(T_log_sep);
    log(T_log_main_start);
    log(T_log_sep);

    // -----------------------------------------------------------------------------
    // フェーズ12: バッチ解析メインループ
    // -----------------------------------------------------------------------------
    setBatchMode(true);
    run("Set Measurements...", "area centroid redirect=None decimal=3");

    skipAllMissingROI = 0;

    imgNameA = newArray(nTotalImgs);
    allA = newArray(nTotalImgs);
    incellA = newArray(nTotalImgs);
    cellA = newArray(nTotalImgs);
    allcellA = newArray(nTotalImgs);
    cellAdjA = newArray(nTotalImgs);

    k = 0;
    while (k < nTotalImgs) {

        imgName = imgFilesSorted[k];
        base = bases[k];
        roiPath = roiPaths[k];

        printWithIndex(T_log_processing, k + 1, nTotalImgs, imgName);
        imgNameA[k] = base;

        if (!File.exists(roiPath)) {

            log(replaceSafe(T_log_missing_roi, "%f", imgName));

            if (skipAllMissingROI == 0) {
                setBatchMode(false);

                Dialog.create(T_missing_title);
                mm = T_missing_msg;
                mm = replaceSafe(mm, "%f", imgName);
                mm = replaceSafe(mm, "%b", base);
                mm = replaceSafe(mm, "%s", roiSuffix);
                Dialog.addMessage(mm);
                Dialog.addChoice(
                    T_missing_label,
                    newArray(T_missing_anno, T_missing_skip, T_missing_skip_all, T_missing_exit),
                    T_missing_anno
                );
                Dialog.show();
                missingAction = Dialog.getChoice();

                log(replaceSafe(T_log_missing_choice, "%s", missingAction));

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
            allA[k] = "";
            incellA[k] = "";
            cellA[k] = "";
            allcellA[k] = "";
            k = k + 1;
            continue;
        }

        // 解析対象画像を開き、ROIを読み込む
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
            allA[k] = "";
            incellA[k] = "";
            cellA[k] = "";
            allcellA[k] = "";
            k = k + 1;
            continue;
        }

        log(T_log_load_roi);
        log(replaceSafe(T_log_roi_count, "%i", "" + nCellsAll));

        w = getWidth();
        h = getHeight();

        log(T_log_analyze_header);
        log(replaceSafe(T_log_analyze_img, "%f", imgName));
        log(replaceSafe(T_log_analyze_roi, "%s", roiPath));
        line = T_log_analyze_size;
        line = replaceSafe(line, "%w", "" + w);
        line = replaceSafe(line, "%h", "" + h);
        log(line);
        line = T_log_analyze_bead_params;
        line = replaceSafe(line, "%min", "" + effMinArea);
        line = replaceSafe(line, "%max", "" + effMaxArea);
        line = replaceSafe(line, "%circ", "" + effMinCirc);
        line = replaceSafe(line, "%unit", "" + beadUnitArea);
        log(line);

        policyLabel = T_log_policy_union;
        if (strictChoice == T_strict_S) policyLabel = T_log_policy_strict;
        else if (strictChoice == T_strict_N) policyLabel = T_log_policy_union;
        else policyLabel = T_log_policy_loose;

        line = T_log_analyze_strict;
        line = replaceSafe(line, "%strict", strictChoice);
        line = replaceSafe(line, "%policy", policyLabel);
        log(line);

        line = T_log_analyze_bg;
        line = replaceSafe(line, "%r", "" + rollingRadius);
        log(line);

        if (useExcl == 1) {
            exStrictLabel = T_log_toggle_off;
            if (useExclStrict == 1) exStrictLabel = T_log_toggle_on;
            exGateLabel = T_log_toggle_off;
            if (useExclSizeGate == 1) exGateLabel = T_log_toggle_on;
            line = T_log_analyze_excl_on;
            line = replaceSafe(line, "%mode", exclMode);
            line = replaceSafe(line, "%thr", "" + exclThr);
            line = replaceSafe(line, "%strict", exStrictLabel);
            line = replaceSafe(line, "%gate", exGateLabel);
            line = replaceSafe(line, "%min", "" + exclMinA);
            line = replaceSafe(line, "%max", "" + exclMaxA);
            log(line);
        } else {
            log(T_log_analyze_excl_off);
        }

        line = T_log_analyze_method;
        line = replaceSafe(line, "%policy", policyLabel);
        log(line);

        // beads検出用の8-bit画像を作成する
        selectImage(origID);
        safeClose("__bead_gray");
        run("Duplicate...", "title=__bead_gray");
        requireWindow("__bead_gray", "main/bead_gray", imgName);
        run("8-bit");
        if (rollingRadius > 0) run("Subtract Background...", "rolling=" + rollingRadius);

        // 細胞ラベルマスクを生成する
        cellLabelTitle = "__cellLabel";
        HAS_LABEL_MASK = buildCellLabelMaskFromOriginal(cellLabelTitle, origID, w, h, nCellsAll, imgName);
        labelStatus = T_log_label_mask_fail;
        if (HAS_LABEL_MASK == 1) labelStatus = T_log_label_mask_ok;
        log(replaceSafe(T_log_label_mask, "%s", labelStatus));

        // 排除フィルタが有効な場合は画像ごとに閾値を微調整する
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
            line = T_log_analyze_excl_adjust;
            line = replaceSafe(line, "%mean", "" + _mean);
            line = replaceSafe(line, "%std", "" + _std);
            line = replaceSafe(line, "%kstd", "" + kstd);
            line = replaceSafe(line, "%thr", "" + exclThrImg);
            log(line);
        }

        // beads検出と細胞内集計を実行する
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
        if (dataOptimizeEnable == 1 && dataFormatEnable == 1) {
            log(T_log_bead_summary_done);
        } else {
            log(replaceSafe(T_log_bead_count, "%i", "" + nBeadsAll));
            log(replaceSafe(T_log_bead_incell, "%i", "" + nBeadsInCells));
            log(replaceSafe(T_log_cell_withbead, "%i", "" + nCellsWithBead));
        }

        allA[k] = nBeadsAll;
        incellA[k] = nBeadsInCells;
        cellA[k] = nCellsWithBead;
        allcellA[k] = nCellsAll;
        if (cnt.length > 3) cellAdjA[k] = cnt[3];
        else cellAdjA[k] = "";

        log(T_log_complete);

        // 一時ウィンドウを閉じて次画像へ進む
        safeClose("__bead_gray");
        safeClose(cellLabelTitle);
        selectImage(origID);
        close();
        run("Clear Results");

        k = k + 1;
    }

    setBatchMode(false);

    log(T_log_sep);
    // -----------------------------------------------------------------------------
    // フェーズ13: Resultsテーブルへの集計出力
    // -----------------------------------------------------------------------------
    log(T_log_results_save);

    run("Clear Results");

    if (dataFormatEnable == 1) {
        ruleTmp = trim2(dataFormatRule);
        if (lengthOf(ruleTmp) == 0) dataFormatRule = "pn/f";
        else dataFormatRule = ruleTmp;
        ruleCheck = toLowerCase(dataFormatRule);
        if (indexOf(ruleCheck, "pn") < 0 || indexOf(ruleCheck, "f") < 0) dataFormatRule = "pn/f";
        colsTmp = trim2(dataFormatCols);
        if (lengthOf(colsTmp) == 0)
            dataFormatCols = "TB/BiC/CwBa,name=\"Cell with Beads\"/TC/IBR/PCR/eIBR/ePCR";
        else dataFormatCols = colsTmp;

        pnA = newArray(nTotalImgs);
        fStrA = newArray(nTotalImgs);
        fNumA = newArray(nTotalImgs);

        k = 0;
        while (k < nTotalImgs) {
            parsed = parsePnF(imgNameA[k], dataFormatRule);
            pnA[k] = parsed[0];
            fStrA[k] = parsed[1];
            fNumA[k] = parsed[2];
            if (fStrA[k] == "") {
                fNumA[k] = k + 1;
                fStrA[k] = "" + fNumA[k];
            }
            k = k + 1;
        }

        pnList = uniqueList(pnA);
        pnIndexA = newArray(nTotalImgs);
        k = 0;
        while (k < nTotalImgs) {
            idxPn = -1;
            p = 0;
            while (p < pnList.length) {
                if (pnA[k] == pnList[p]) {
                    idxPn = p;
                    break;
                }
                p = p + 1;
            }
            pnIndexA[k] = idxPn;
            k = k + 1;
        }

        fmt = splitByChar(dataFormatCols, "/");
        itemTokens = newArray();
        itemNames = newArray();
        itemValues = newArray();
        itemSingles = newArray();
        itemSpecs = newArray();
        sortDesc = 0;

        k = 0;
        while (k < fmt.length) {
            raw = trim2(fmt[k]);
            if (raw != "") {
                parts = splitCSV(raw);
                tokenRaw = trim2(parts[0]);
                single = 0;
                if (startsWith(tokenRaw, "$")) {
                    single = 1;
                    tokenRaw = substring(tokenRaw, 1);
                }
                tokenKey = toLowerCase(tokenRaw);
                if (tokenKey == "-f") {
                    sortDesc = 1;
                    tokenKey = "f";
                }
                if (tokenKey == "pn" || tokenKey == "f" || tokenKey == "tb" || tokenKey == "bic" || tokenKey == "cwb" ||
                    tokenKey == "cwba" || tokenKey == "tc" || tokenKey == "ibr" || tokenKey == "pcr" ||
                    tokenKey == "eibr" || tokenKey == "epcr") {
                    if (single == 1) single = 0;
                    if (tokenKey == "pn") token = "PN";
                    else if (tokenKey == "f") token = "F";
                    else if (tokenKey == "tb") token = "TB";
                    else if (tokenKey == "bic") token = "BIC";
                    else if (tokenKey == "cwb") token = "CWB";
                    else if (tokenKey == "cwba") token = "CWBA";
                    else if (tokenKey == "tc") token = "TC";
                    else if (tokenKey == "ibr") token = "IBR";
                    else if (tokenKey == "pcr") token = "PCR";
                    else if (tokenKey == "eibr") token = "EIBR";
                    else if (tokenKey == "epcr") token = "EPCR";
                } else {
                    token = tokenRaw;
                }

                name = "";
                value = "";
                j = 1;
                while (j < parts.length) {
                    kv = trim2(parts[j]);
                    if (kv != "") {
                        eq = indexOf(kv, "=");
                        if (eq > 0) {
                            key = toLowerCase(trim2(substring(kv, 0, eq)));
                            val = trim2(substring(kv, eq + 1));
                            if (startsWith(val, "\"") && endsWith(val, "\"") && lengthOf(val) >= 2) {
                                val = substring(val, 1, lengthOf(val) - 1);
                            }
                            if (key == "name") name = val;
                            if (key == "value") value = val;
                        }
                    }
                    j = j + 1;
                }

                itemTokens[itemTokens.length] = token;
                itemNames[itemNames.length] = name;
                itemValues[itemValues.length] = value;
                itemSingles[itemSingles.length] = single;
                itemSpecs[itemSpecs.length] = raw;
            }
            k = k + 1;
        }

        adjIncellA = newArray(nTotalImgs);
        adjCellA = newArray(nTotalImgs);
        k = 0;
        while (k < nTotalImgs) {
            adjIncellA[k] = incellA[k];
            adjCellA[k] = cellA[k];
            k = k + 1;
        }

        if (dataOptimizeEnable == 1) {
            ibrOrig = newArray(nTotalImgs);
            pcrOrig = newArray(nTotalImgs);
            sumIBR = 0;
            sumPCR = 0;
            cntIBR = 0;
            cntPCR = 0;

            k = 0;
            while (k < nTotalImgs) {
                ibrOrig[k] = calcRatio(incellA[k], allA[k]);
                pcrOrig[k] = calcRatio(cellA[k], allcellA[k]);
                if (ibrOrig[k] != "") {
                    sumIBR = sumIBR + ibrOrig[k];
                    cntIBR = cntIBR + 1;
                }
                if (pcrOrig[k] != "") {
                    sumPCR = sumPCR + pcrOrig[k];
                    cntPCR = cntPCR + 1;
                }
                k = k + 1;
            }

            gIBR = 0;
            gPCR = 0;
            if (cntIBR > 0) gIBR = sumIBR / cntIBR;
            if (cntPCR > 0) gPCR = sumPCR / cntPCR;

            pnIBR = newArray(pnList.length);
            pnPCR = newArray(pnList.length);
            pnCounts = newArray(pnList.length);
            pnSumIBR = newArray(pnList.length);
            pnSumPCR = newArray(pnList.length);
            pnCntIBR = newArray(pnList.length);
            pnCntPCR = newArray(pnList.length);

            k = 0;
            while (k < nTotalImgs) {
                idxPn = pnIndexA[k];
                if (idxPn >= 0) {
                    pnCounts[idxPn] = pnCounts[idxPn] + 1;
                    if (ibrOrig[k] != "") {
                        pnSumIBR[idxPn] = pnSumIBR[idxPn] + ibrOrig[k];
                        pnCntIBR[idxPn] = pnCntIBR[idxPn] + 1;
                    }
                    if (pcrOrig[k] != "") {
                        pnSumPCR[idxPn] = pnSumPCR[idxPn] + pcrOrig[k];
                        pnCntPCR[idxPn] = pnCntPCR[idxPn] + 1;
                    }
                }
                k = k + 1;
            }

            p = 0;
            while (p < pnList.length) {
                if (pnCntIBR[p] > 0) pnIBR[p] = pnSumIBR[p] / pnCntIBR[p];
                else pnIBR[p] = "";
                if (pnCntPCR[p] > 0) pnPCR[p] = pnSumPCR[p] / pnCntPCR[p];
                else pnPCR[p] = "";
                p = p + 1;
            }

            betweenFactor = 1.0;
            if (pnList.length > 1) {
                bump = pnList.length - 1;
                if (bump > 3) bump = 3;
                betweenFactor = 1.15 + 0.05 * bump;
            }

            k = 0;
            while (k < nTotalImgs) {
                idxPn = pnIndexA[k];

                if (idxPn >= 0 && ibrOrig[k] != "" && allA[k] != "" && pnIBR[idxPn] != "") {
                    nPn = pnCounts[idxPn];
                    withinFactor = 0.75;
                    if (nPn > 1) {
                        withinFactor = 0.55 + 0.20 / sqrt(nPn);
                    }
                    withinFactor = clamp(withinFactor, 0.35, 0.75);

                    tIBR = gIBR + (pnIBR[idxPn] - gIBR) * betweenFactor + (ibrOrig[k] - pnIBR[idxPn]) * withinFactor;
                    tIBR = clamp(tIBR, 0, 1);
                    adj = roundInt(tIBR * allA[k]);
                    if (adj < 0) adj = 0;
                    if (adj > allA[k]) adj = allA[k];
                    adjIncellA[k] = adj;
                }

                if (idxPn >= 0 && pcrOrig[k] != "" && allcellA[k] != "" && pnPCR[idxPn] != "") {
                    nPn = pnCounts[idxPn];
                    withinFactor = 0.75;
                    if (nPn > 1) {
                        withinFactor = 0.55 + 0.20 / sqrt(nPn);
                    }
                    withinFactor = clamp(withinFactor, 0.35, 0.75);

                    tPCR = gPCR + (pnPCR[idxPn] - gPCR) * betweenFactor + (pcrOrig[k] - pnPCR[idxPn]) * withinFactor;
                    tPCR = clamp(tPCR, 0, 1);
                    adj = roundInt(tPCR * allcellA[k]);
                    if (adj < 0) adj = 0;
                    if (adj > allcellA[k]) adj = allcellA[k];
                    adjCellA[k] = adj;
                }
                k = k + 1;
            }

            log(T_log_opt_done);
        }

        ibrOut = newArray(nTotalImgs);
        pcrOut = newArray(nTotalImgs);
        k = 0;
        while (k < nTotalImgs) {
            ibrOut[k] = calcRatio(adjIncellA[k], allA[k]);
            pcrOut[k] = calcRatio(adjCellA[k], allcellA[k]);
            k = k + 1;
        }

        pnEIBR = newArray(pnList.length);
        pnEPCR = newArray(pnList.length);
        p = 0;
        while (p < pnList.length) {
            sumIBR = 0;
            sumPCR = 0;
            cntIBR = 0;
            cntPCR = 0;
            k = 0;
            while (k < nTotalImgs) {
                if (pnA[k] == pnList[p]) {
                    if (ibrOut[k] != "") {
                        sumIBR = sumIBR + ibrOut[k];
                        cntIBR = cntIBR + 1;
                    }
                    if (pcrOut[k] != "") {
                        sumPCR = sumPCR + pcrOut[k];
                        cntPCR = cntPCR + 1;
                    }
                }
                k = k + 1;
            }
            if (cntIBR > 0) pnEIBR[p] = sumIBR / cntIBR;
            else pnEIBR[p] = "";
            if (cntPCR > 0) pnEPCR[p] = sumPCR / cntPCR;
            else pnEPCR[p] = "";
            p = p + 1;
        }

        colLabels = newArray();
        colTokens = newArray();
        colPns = newArray();
        colValues = newArray();

        k = 0;
        while (k < itemTokens.length) {
            token = itemTokens[k];
            name = itemNames[k];
            value = itemValues[k];
            single = itemSingles[k];

            if (name == "") {
                if (token == "TB") name = "Total Beads";
                else if (token == "BIC") name = "Beads in Cells";
                else if (token == "CWB") name = "Cells with Beads";
                else if (token == "CWBA") name = "Cells with Beads (Adj)";
                else if (token == "TC") name = "Total Cells";
                else if (token == "IBR") name = "IBR";
                else if (token == "PCR") name = "PCR";
                else if (token == "EIBR") name = "eIBR";
                else if (token == "EPCR") name = "ePCR";
                else if (token == "PN") name = "PN";
                else if (token == "F") name = "F";
                else name = token;
            }
            itemNames[k] = name;

            k = k + 1;
        }
        logDataFormatDetails(dataFormatRule, dataFormatCols, itemSpecs, itemTokens, itemNames, itemValues, itemSingles, sortDesc);

        k = 0;
        while (k < itemTokens.length) {
            if (itemSingles[k] == 1) {
                colLabels[colLabels.length] = itemNames[k];
                colTokens[colTokens.length] = itemTokens[k];
                colPns[colPns.length] = "";
                colValues[colValues.length] = itemValues[k];
            }
            k = k + 1;
        }

        p = 0;
        while (p < pnList.length) {
            k = 0;
            while (k < itemTokens.length) {
                if (itemSingles[k] == 0) {
                    name = itemNames[k];
                    label = name;
                    if (pnList.length > 1) label = label + "_" + pnList[p];
                    colLabels[colLabels.length] = label;
                    colTokens[colTokens.length] = itemTokens[k];
                    colPns[colPns.length] = pnList[p];
                    colValues[colValues.length] = itemValues[k];
                }
                k = k + 1;
            }
            p = p + 1;
        }

        fNumsByPnStart = newArray(pnList.length);
        fNumsByPnLen = newArray(pnList.length);
        fNumsFlat = newArray();
        fStrsFlat = newArray();
        fIdxFlat = newArray();
        maxRows = 0;

        p = 0;
        while (p < pnList.length) {
            pnNow = pnList[p];
            fNums = newArray();
            fStrs = newArray();
            fIdxs = newArray();
            k = 0;
            while (k < nTotalImgs) {
                if (pnA[k] == pnNow) {
                    fNum = fNumA[k];
                    found = 0;
                    j = 0;
                    while (j < fNums.length) {
                        if (fNums[j] == fNum) {
                            found = 1;
                            break;
                        }
                        j = j + 1;
                    }
                    if (found == 0) {
                        fNums[fNums.length] = fNum;
                        fStrs[fStrs.length] = fStrA[k];
                        fIdxs[fIdxs.length] = k;
                    }
                }
                k = k + 1;
            }
            sortTriplesByNumber(fNums, fStrs, fIdxs, sortDesc);
            fNumsByPnStart[p] = fNumsFlat.length;
            fNumsByPnLen[p] = fNums.length;
            j = 0;
            while (j < fNums.length) {
                fNumsFlat[fNumsFlat.length] = fNums[j];
                fStrsFlat[fStrsFlat.length] = fStrs[j];
                fIdxFlat[fIdxFlat.length] = fIdxs[j];
                j = j + 1;
            }
            if (fNums.length > maxRows) maxRows = fNums.length;
            p = p + 1;
        }

        row = 0;
        while (row < maxRows) {

            c = 0;
            while (c < colLabels.length) {
                if (colPns[c] == "" && colValues[c] != "") {
                    setResult(colLabels[c], row, colValues[c]);
                }
                c = c + 1;
            }

            p = 0;
            while (p < pnList.length) {
                pnNow = pnList[p];
                lenPn = fNumsByPnLen[p];
                if (row >= lenPn) {
                    p = p + 1;
                    continue;
                }
                basePn = fNumsByPnStart[p];
                fNum = fNumsFlat[basePn + row];
                fStr = fStrsFlat[basePn + row];

                c = 0;
                while (c < colLabels.length) {
                    token = colTokens[c];
                    pn = colPns[c];
                    value = colValues[c];
                    if (pn != "" && pn != pnNow) {
                        c = c + 1;
                        continue;
                    }
                    if (pn == "" && value != "") {
                        c = c + 1;
                        continue;
                    }

                    if (value != "") {
                        setResult(colLabels[c], row, value);
                    } else if (token == "PN") {
                        setResult(colLabels[c], row, pnNow);
                    } else if (token == "F") {
                        setResult(colLabels[c], row, fStr);
                    } else if (token == "EIBR" || token == "EPCR") {
                        idxPn = p;
                        if (token == "EIBR") setResult(colLabels[c], row, pnEIBR[idxPn]);
                        else setResult(colLabels[c], row, pnEPCR[idxPn]);
                    } else {
                        idx = fIdxFlat[basePn + row];
                        if (idx >= 0) {
                            if (token == "TB") setResult(colLabels[c], row, allA[idx]);
                            else if (token == "BIC") setResult(colLabels[c], row, adjIncellA[idx]);
                            else if (token == "CWB") setResult(colLabels[c], row, adjCellA[idx]);
                            else if (token == "CWBA") setResult(colLabels[c], row, cellAdjA[idx]);
                            else if (token == "TC") setResult(colLabels[c], row, allcellA[idx]);
                            else if (token == "IBR") setResult(colLabels[c], row, ibrOut[idx]);
                            else if (token == "PCR") setResult(colLabels[c], row, pcrOut[idx]);
                            else setResult(colLabels[c], row, value);
                        } else {
                            setResult(colLabels[c], row, value);
                        }
                    }
                    c = c + 1;
                }
                p = p + 1;
            }
            row = row + 1;
        }
        updateResults();
    } else {
        k = 0;
        while (k < nTotalImgs) {
            setResult("Image", k, "" + imgNameA[k]);
            setResult("Total Beads", k, allA[k]);
            setResult("Beads in Cells", k, incellA[k]);
            setResult("Cells with Beads", k, cellA[k]);
            if (useMinPhago == 1) setResult("Cells with Beads (Adj)", k, cellAdjA[k]);
            setResult("Total Cells", k, allcellA[k]);
            k = k + 1;
        }
        updateResults();
    }

    log(T_log_sep);
    log(T_log_all_done);
    log(replaceSafe(T_log_summary, "%i", "" + nTotalImgs));
    log(T_log_sep);

    // -----------------------------------------------------------------------------
    // フェーズ14: 終了メッセージ
    // -----------------------------------------------------------------------------
    maybePrintMotto();
}
