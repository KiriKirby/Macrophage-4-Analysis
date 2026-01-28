macro "巨噬細胞画像 四要素解�?/ Macrophage Four-Factor Analysis / マクロファージ四要素解析" {
    // =============================================================================
    // 概要: 巨噬細胞画像�?要素解析を行うImageJマクロ（Fiji専用�?
    // 目的: ROI標注、対象物検出、統計集計、結果出力を一連の対話フローで実行する
    // 想定: Fiji上での実行とユーザー操作を含む（ImageJ単体では動作しない）
    // 署名: 西方研究室（nishikata lab�?/ wangsychn@outlook.com
    // 版数: 2.2.4b / ライセン�? CC0 1.0（本スクリプト）
    // 注意: 同梱のFiji/フォント等は各ライセンスに従う（THIRD_PARTY_NOTICES.md参照）�?    // =============================================================================

    // AI编辑提示：修改前请先阅读本仓库的AGENTS.md�?
    // AIによる編集前に、このリポジトリのAGENTS.mdを必ず確認すること�?
    // Note for AI contributors: Read AGENTS.md in this repository before editing.

    // -----------------------------------------------------------------------------
    // 設定: ログ/モットー表示の制御フラグ
    // -----------------------------------------------------------------------------
    ENABLE_MOTTO_CN = 1;
    ENABLE_MOTTO_ENJP = 0;
    LOG_VERBOSE = 1;
    SUBSTRING_INCLUSIVE = 0;
    DATA_OPT_UI = 1;

    // -----------------------------------------------------------------------------
    // 関数: log
    // 概要: LOG_VERBOSEが有効なときのみログを出力する�?
    // 引数: s (string) - 出力するメッセー�?
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function log(s) {
        if (LOG_VERBOSE) print(s);
    }

    // -----------------------------------------------------------------------------
    // 関数: detectSubstringInclusive
    // 概要: substring の終端がinclusiveか判定する�?
    // 引数: なし
    // 戻り�? number (1=inclusive, 0=exclusive)
    // -----------------------------------------------------------------------------
    function detectSubstringInclusive() {
        return (lengthOf(substring("a", 0, 0)) == 1);
    }
    SUBSTRING_INCLUSIVE = detectSubstringInclusive();

    // -----------------------------------------------------------------------------
    // 関数: max2
    // 概要: 2値の最大値を返す�?
    // 引数: a (number), b (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function max2(a, b) {
        if (a > b) return a;
        return b;
    }

    // -----------------------------------------------------------------------------
    // 関数: min2
    // 概要: 2値の最小値を返す�?
    // 引数: a (number), b (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function min2(a, b) {
        if (a < b) return a;
        return b;
    }

    // -----------------------------------------------------------------------------
    // 関数: abs2
    // 概要: 絶対値を返す�?
    // 引数: x (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function abs2(x) {
        if (x < 0) return -x;
        return x;
    }

    // -----------------------------------------------------------------------------
    // 関数: roundInt
    // 概要: 四捨五入して整数化する�?
    // 引数: x (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function roundInt(x) {
        return floor(x + 0.5);
    }

    // -----------------------------------------------------------------------------
    // 関数: ceilInt
    // 概要: 切り上げ（負数対応）で整数化する�?
    // 引数: x (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function ceilInt(x) {
        f = floor(x);
        if (x == f) return f;
        if (x > 0) return f + 1;
        return f;
    }

    // -----------------------------------------------------------------------------
    // 関数: clamp
    // 概要: [a, b] にクランプする�?
    // 引数: x (number), a (number), b (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function clamp(x, a, b) {
        if (x < a) return a;
        if (x > b) return b;
        return x;
    }

    // -----------------------------------------------------------------------------
    // 関数: isImageFile
    // 概要: 画像拡張子（tif/tiff/png/jpg/jpeg）か判定する�?
    // 引数: filename (string)
    // 戻り�? 1 = 画像, 0 = 非画�?
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
    // 概要: 拡張子を除いたベース名を返す�?
    // 引数: filename (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function getBaseName(filename) {
        dot = lastIndexOf(filename, ".");
        if (dot > 0) return substring(filename, 0, dot);
        return filename;
    }

    // -----------------------------------------------------------------------------
    // 関数: trim2
    // 概要: 文字列の前後空白を削除する�?
    // 引数: s (string)
    // 戻り�? string
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
    // 関数: ensureTrailingSlash
    // 概要: パス末尾にスラッシュを付与する�?
    // 引数: p (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function ensureTrailingSlash(p) {
        if (p == "") return p;
        if (endsWith(p, "/")) return p;
        return p + "/";
    }

    // -----------------------------------------------------------------------------
    // 関数: splitByChar
    // 概要: 1文字区切りで文字列を分割する�?
    // 引数: s (string), ch (string)
    // 戻り�? array
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
    // 関数: joinNumberList
    // 概要: 数値配列をカンマ区切りの文字列に変換する�?
    // 引数: arr (array)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function joinNumberList(arr) {
        s = "";
        i = 0;
        while (i < arr.length) {
            if (i > 0) s = s + ",";
            s = s + arr[i];
            i = i + 1;
        }
        return s;
    }

    // -----------------------------------------------------------------------------
    // 関数: parseNumberList
    // 概要: カンマ区切りの数値文字列を配列に変換する�?
    // 引数: s (string)
    // 戻り�? array
    // -----------------------------------------------------------------------------
    function parseNumberList(s) {
        s = "" + s;
        if (s == "") return newArray();
        parts = splitByChar(s, ",");
        out = newArray(parts.length);
        i = 0;
        while (i < parts.length) {
            if (parts[i] == "") out[i] = 0;
            else out[i] = 0 + parts[i];
            i = i + 1;
        }
        return out;
    }

    // -----------------------------------------------------------------------------
    // 関数: meanFromCsv
    // 概要: カンマ区切り数値の平均を返す（空は""）�?
    // 引数: s (string)
    // 戻り�? number or ""
    // -----------------------------------------------------------------------------
    function meanFromCsv(s) {
        s = "" + s;
        if (s == "") return "";
        arr = parseNumberList(s);
        if (arr.length == 0) return "";
        sum = 0;
        i = 0;
        while (i < arr.length) {
            sum = sum + arr[i];
            i = i + 1;
        }
        return sum / arr.length;
    }

    // -----------------------------------------------------------------------------
    // 関数: scaleCsv
    // 概要: カンマ区切り数値を係数でスケールする（四捨五入、負数は0）�?
    // 引数: s (string), factor (number)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function scaleCsv(s, factor) {
        s = "" + s;
        if (s == "") return s;
        if (factor == 1) return s;
        arr = parseNumberList(s);
        i = 0;
        while (i < arr.length) {
            v = arr[i] * factor;
            arr[i] = roundInt(v);
            if (arr[i] < 0) arr[i] = 0;
            i = i + 1;
        }
        return joinNumberList(arr);
    }

    // -----------------------------------------------------------------------------
    // 関数: scaleCsvIntoArray
    // 概要: CSV文字列配列の指定要素を係数でスケールして上書きする�?
    // 引数: arr (array), idx (number), factor (number)
    // 戻り�? number (0)
    // -----------------------------------------------------------------------------
    function scaleCsvIntoArray(arr, idx, factor) {
        if (idx < 0 || idx >= arr.length) return 0;
        s = "" + arr[idx];
        if (s == "") return 0;
        if (factor == 1) return 0;
        vals = parseNumberList(s);
        i = 0;
        while (i < vals.length) {
            v = vals[i] * factor;
            vals[i] = roundInt(v);
            if (vals[i] < 0) vals[i] = 0;
            i = i + 1;
        }
        arr[idx] = joinNumberList(vals);
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: buildCsvCache
    // 概要: CSV文字列配列をフラット配列に展開し開始/長さを記録する�?
    // 引数: csvArr (array), startArr (array), lenArr (array)
    // 戻り�? array (flat)
    // -----------------------------------------------------------------------------
    function buildCsvCache(csvArr, startArr, lenArr) {
        flat = newArray();
        i = 0;
        while (i < csvArr.length) {
            startArr[i] = flat.length;
            vals = parseNumberList(csvArr[i]);
            j = 0;
            while (j < vals.length) {
                flat[flat.length] = vals[j];
                j = j + 1;
            }
            lenArr[i] = vals.length;
            i = i + 1;
        }
        return flat;
    }

    // -----------------------------------------------------------------------------
    // 関数: meanFromCache
    // 概要: フラット配列キャッシュから平均値を計算する�?
    // 引数: flat (array), startIdx (number), len (number)
    // 戻り�? number or ""
    // -----------------------------------------------------------------------------
    function meanFromCache(flat, startIdx, len) {
        if (len <= 0) return "";
        sum = 0;
        i = 0;
        while (i < len) {
            sum = sum + flat[startIdx + i];
            i = i + 1;
        }
        return sum / len;
    }

    // -----------------------------------------------------------------------------
    // 関数: scaleCsvCacheInPlace
    // 概要: フラット配列キャッシュの指定要素を係数でスケールする�?
    // 引数: flat (array), startArr (array), lenArr (array), idx (number), factor (number)
    // 戻り�? number (0)
    // -----------------------------------------------------------------------------
    function scaleCsvCacheInPlace(flat, startArr, lenArr, idx, factor) {
        if (idx < 0 || idx >= startArr.length) return 0;
        if (factor == 1) return 0;
        startIdx = startArr[idx];
        len = lenArr[idx];
        i = 0;
        while (i < len) {
            v = flat[startIdx + i] * factor;
            v = roundInt(v);
            if (v < 0) v = 0;
            flat[startIdx + i] = v;
            i = i + 1;
        }
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: getNumberFromCache
    // 概要: フラット配列キャッシュから指定位置の値を取得する�?
    // 引数: flat (array), startArr (array), lenArr (array), idx (number), cellIdx (number)
    // 戻り�? number or ""
    // -----------------------------------------------------------------------------
    function getNumberFromCache(flat, startArr, lenArr, idx, cellIdx) {
        if (idx < 0 || idx >= startArr.length) return "";
        startIdx = startArr[idx];
        len = lenArr[idx];
        if (cellIdx < 0 || cellIdx >= len) return "";
        return flat[startIdx + cellIdx];
    }

    // -----------------------------------------------------------------------------
    // 関数: buildZeroCsv
    // 概要: 指定数の0をカンマ区切りで生成する�?
    // 引数: n (number)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function buildZeroCsv(n) {
        if (n <= 0) return "";
        s = "";
        i = 0;
        while (i < n) {
            if (i > 0) s = s + ",";
            s = s + "0";
            i = i + 1;
        }
        return s;
    }

    // -----------------------------------------------------------------------------
    // 関数: getNumberAtCsv
    // 概要: カンマ区切り文字列の指定位置の数値を返す�?
    // 引数: s (string), idx (number)
    // 戻り�? number or ""
    // -----------------------------------------------------------------------------
    function getNumberAtCsv(s, idx) {
        s = "" + s;
        if (s == "") return "";
        parts = splitByChar(s, ",");
        if (idx < 0 || idx >= parts.length) return "";
        if (parts[idx] == "") return "";
        return 0 + parts[idx];
    }

    // -----------------------------------------------------------------------------
    // 関数: splitCSV
    // 概要: クォート対応でカンマ区切りを分割する�?
    // 引数: s (string)
    // 戻り�? array
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
    // 概要: 数字文字か判定する�?
    // 引数: c (string)
    // 戻り�? number (1/0)
    // -----------------------------------------------------------------------------
    function isDigitChar(c) {
        if (c >= "0" && c <= "9") return 1;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: charAtCompat
    // 概要: substring仕様に合わせ�?文字を取得する�?
    // 引数: s (string), idx (number)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function charAtCompat(s, idx) {
        n = lengthOf(s);
        if (idx < 0 || idx >= n) return "";
        if (SUBSTRING_INCLUSIVE == 1) return substring(s, idx, idx);
        return substring(s, idx, idx + 1);
    }

    // -----------------------------------------------------------------------------
    // 関数: isDigitAt
    // 概要: 文字列の指定位置が数字か判定する�?
    // 引数: s (string), idx (number)
    // 戻り�? number (1/0)
    // -----------------------------------------------------------------------------
    function isDigitAt(s, idx) {
        c = charAtCompat(s, idx);
        if (c == "") return 0;
        return isDigitChar(c);
    }

    // -----------------------------------------------------------------------------
    // 関数: normalizeRuleToken
    // 概要: ルールトークンを正規化する�?
    // 引数: part (string)
    // 戻り�? string ("p"/"f"/"")
    // -----------------------------------------------------------------------------
    function normalizeRuleToken(part) {
        s = toLowerCase(trim2(part));
        if (s == "p" || s == "pn" || s == "<p>" || s == "<pn>") return "p";
        if (s == "f" || s == "f1" || s == "<f>" || s == "<f1>") return "f";
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: extractFirstNumberStr
    // 概要: 文字列内の最初の連続数字を返す�?
    // 引数: s (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function extractFirstNumberStr(s) {
        n = lengthOf(s);
        i = 0;
        while (i < n && !isDigitAt(s, i)) i = i + 1;
        j = i;
        while (j < n && isDigitAt(s, j)) j = j + 1;
        if (j > i) return substring(s, i, j);
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: parsePatternParts
    // 概要: パターン�?"/" 区切りで分解し、トーク�?リテラル配列を作る�?    // 引数: pattern (string), types (array), texts (array)
    // 戻り�? string (空ならOK、それ以外はエラーメッセージ)
    // -----------------------------------------------------------------------------
    function parsePatternParts(pattern, types, texts) {
        parts = splitByChar(trim2(pattern), "/");
        if (parts.length == 0) return T_err_df_rule_empty;
        i = 0;
        while (i < parts.length) {
            raw = trim2(parts[i]);
            if (raw == "") return T_err_df_rule_parts;
            if (startsWith(raw, "\"") && endsWith(raw, "\"") && lengthOf(raw) >= 2) {
                lit = substring(raw, 1, lengthOf(raw) - 1);
                if (lengthOf(lit) == 0) return T_err_df_rule_parts;
                types[types.length] = "L";
                texts[texts.length] = lit;
            } else {
                token = normalizeRuleToken(raw);
                if (token != "") {
                    types[types.length] = token;
                    texts[texts.length] = "";
                } else {
                    types[types.length] = "L";
                    texts[texts.length] = raw;
                }
            }
            i = i + 1;
        }
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: parseByPattern
    // 概要: パターンに従ってベース名からPN/Fを抽出する�?    // 引数: base (string), pattern (string)
    // 戻り�? array [pn, fStr, fNum]
    // -----------------------------------------------------------------------------
    function parseByPattern(base, pattern) {
        pn = "";
        fStr = "";
        fNum = 0;
        types = newArray();
        texts = newArray();
        err = parsePatternParts(pattern, types, texts);
        if (err != "") return newArray(pn, fStr, fNum);

        tokenCount = 0;
        literalCount = 0;
        hasP = 0;
        hasF = 0;
        i = 0;
        while (i < types.length) {
            if (types[i] == "L") literalCount = literalCount + 1;
            else {
                tokenCount = tokenCount + 1;
                if (types[i] == "p") hasP = 1;
                if (types[i] == "f") hasF = 1;
            }
            i = i + 1;
        }

        if (literalCount == 0 && tokenCount == 2 && types.length == 2) {
            t1 = types[0];
            t2 = types[1];
            hasP = (t1 == "p" || t2 == "p");
            if (hasP) pn = base;

            if (t1 == "p" && t2 == "f") {
                i = lengthOf(base) - 1;
                while (i >= 0 && isDigitAt(base, i)) i = i - 1;
                if (i < lengthOf(base) - 1) {
                    pn = substring(base, 0, i + 1);
                    fStr = substring(base, i + 1);
                }
            } else if (t1 == "f" && t2 == "p") {
                i = 0;
                n = lengthOf(base);
                while (i < n && !isDigitAt(base, i)) i = i + 1;
                j = i;
                while (j < n && isDigitAt(base, j)) j = j + 1;
                if (j > i) {
                    fStr = substring(base, i, j);
                    pn = substring(base, j);
                }
            }
        } else {
            i = 0;
            seg = 0;
            while (seg < types.length) {
                t = types[seg];
                if (t == "L") {
                    lit = texts[seg];
                    if (!startsWith(substring(base, i), lit)) return newArray("", "", 0);
                    i = i + lengthOf(lit);
                } else {
                    nextLit = "";
                    nextIdx = seg + 1;
                    while (nextIdx < types.length && types[nextIdx] != "L") nextIdx = nextIdx + 1;
                    if (nextIdx < types.length) nextLit = texts[nextIdx];

                    if (nextLit == "") {
                        tokenStr = substring(base, i);
                        i = lengthOf(base);
                    } else {
                        idx = indexOf(substring(base, i), nextLit);
                        if (idx < 0) return newArray("", "", 0);
                        tokenStr = substring(base, i, i + idx);
                        i = i + idx;
                    }

                    if (t == "p") pn = tokenStr;
                    else fStr = tokenStr;
                }
                seg = seg + 1;
            }
            if (types.length > 0 && types[types.length - 1] == "L" && i != lengthOf(base))
                return newArray("", "", 0);
        }

        if (hasP == 1) {
            if (pn == "") pn = "PN";
        } else {
            pn = "";
        }
        if (fStr != "") fNum = 0 + fStr;
        return newArray(pn, fStr, fNum);
    }

    // -----------------------------------------------------------------------------
    // 関数: parseRuleSpec
    // 概要: ルール指定文字列からパターンとF/T割当を抽出する�?
    // 引数: spec (string), defaultTarget (string)
    // 戻り�? array [pattern, fTarget, errMsg]
    // -----------------------------------------------------------------------------
    function parseRuleSpec(spec, defaultTarget) {
        parts = splitCSV(spec);
        pattern = trim2(parts[0]);
        fTarget = defaultTarget;
        err = "";
        seenF = 0;

        i = 1;
        while (i < parts.length) {
            kv = trim2(parts[i]);
            if (kv != "") {
                eq = indexOf(kv, "=");
                if (eq <= 0) {
                    err = T_err_df_rule_param_kv;
                    break;
                }
                key = toLowerCase(trim2(substring(kv, 0, eq)));
                val = trim2(substring(kv, eq + 1));
                if (!(startsWith(val, "\"") && endsWith(val, "\"") && lengthOf(val) >= 2)) {
                    err = T_err_df_rule_param_quote;
                    break;
                }
                val = substring(val, 1, lengthOf(val) - 1);
                if (key != "f") {
                    err = T_err_df_rule_param_unknown_prefix + key;
                    break;
                }
                if (seenF == 1) {
                    err = T_err_df_rule_param_duplicate;
                    break;
                }
                valU = toUpperCase(trim2(val));
                if (valU != "F" && valU != "T") {
                    err = T_err_df_rule_param_f_value;
                    break;
                }
                seenF = 1;
                fTarget = valU;
            }
            i = i + 1;
        }
        return newArray(pattern, fTarget, err);
    }

    // -----------------------------------------------------------------------------
    // 関数: parsePnF
    // 概要: ルールに従ってベース名からPN/Fを抽出し、F/T割当を返す�?
    // 引数: base (string), ruleSpec (string), defaultTarget (string)
    // 戻り�? array [pn, fStr, fNum, fTarget]
    // -----------------------------------------------------------------------------
    function parsePnF(base, ruleSpec, defaultTarget) {
        spec = parseRuleSpec(ruleSpec, defaultTarget);
        pattern = spec[0];
        fTarget = spec[1];
        parsed = parseByPattern(base, pattern);
        pn = parsed[0];
        fStr = parsed[1];
        fNum = parsed[2];
        return newArray(pn, fStr, fNum, fTarget);
    }

    // -----------------------------------------------------------------------------
    // 関数: isBuiltinToken
    // 概要: 組み込み列コードか判定する�?
    // 引数: tokenKey (string, lower)
    // 戻り�? number (1/0)
    // -----------------------------------------------------------------------------
    function isBuiltinToken(tokenKey) {
        if (tokenKey == "pn") return 1;
        if (tokenKey == "f") return 1;
        if (tokenKey == "t") return 1;
        if (tokenKey == "tb") return 1;
        if (tokenKey == "bic") return 1;
        if (tokenKey == "cwb") return 1;
        if (tokenKey == "cwba") return 1;
        if (tokenKey == "tc") return 1;
        if (tokenKey == "bpc") return 1;
        if (tokenKey == "ibr") return 1;
        if (tokenKey == "pcr") return 1;
        if (tokenKey == "ebpc") return 1;
        if (tokenKey == "bpcsdp") return 1;
        if (tokenKey == "eibr") return 1;
        if (tokenKey == "epcr") return 1;
        if (tokenKey == "isdp") return 1;
        if (tokenKey == "psdp") return 1;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: tokenCodeFromToken
    // 概要: 列トークンを内部コードに変換する�?
    // 引数: token (string)
    // 戻り�? number (0=custom/unknown)
    // -----------------------------------------------------------------------------
    function tokenCodeFromToken(token) {
        if (token == "PN") return 1;
        if (token == "F") return 2;
        if (token == "T") return 3;
        if (token == "TB") return 4;
        if (token == "BIC") return 5;
        if (token == "CWB") return 6;
        if (token == "CWBA") return 7;
        if (token == "TC") return 8;
        if (token == "BPC") return 9;
        if (token == "IBR") return 10;
        if (token == "PCR") return 11;
        if (token == "EBPC") return 12;
        if (token == "BPCSDP") return 13;
        if (token == "EIBR") return 14;
        if (token == "EPCR") return 15;
        if (token == "ISDP") return 16;
        if (token == "PSDP") return 17;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: validateDataFormatRule
    // 概要: ファイル名識別ルールの妥当性を検証する�?
    // 引数: rule (string)
    // 戻り�? string (空ならOK、それ以外はエラーメッセージ)
    // -----------------------------------------------------------------------------
    function validateDataFormatRule(rule) {
        r = trim2(rule);
        if (lengthOf(r) == 0) return T_err_df_rule_empty;

        folderSpec = "";
        fileSpec = r;
        idx = indexOf(r, "//");
        if (SUBFOLDER_KEEP_MODE == 1) {
            if (idx < 0) return T_err_df_rule_need_subfolder;
            if (indexOf(r, "//", idx + 2) >= 0) return T_err_df_rule_double_slash;
            folderSpec = trim2(substring(r, 0, idx));
            fileSpec = trim2(substring(r, idx + 2));
            if (folderSpec == "" || fileSpec == "") return T_err_df_rule_parts;
        } else {
            if (idx >= 0) return T_err_df_rule_no_subfolder;
        }

        spec = parseRuleSpec(fileSpec, "F");
        if (spec[2] != "") return spec[2];
        pattern = spec[0];
        if (pattern == "") return T_err_df_rule_empty;
        parts = splitByChar(pattern, "/");
        if (parts.length < 2) return T_err_df_rule_slash;
        pTypes = newArray();
        pTexts = newArray();
        err = parsePatternParts(pattern, pTypes, pTexts);
        if (err != "") return err;

        hasP = 0;
        hasF = 0;
        tokenCount = 0;
        literalCount = 0;
        adjacentToken = 0;
        i = 0;
        while (i < pTypes.length) {
            if (pTypes[i] == "L") literalCount = literalCount + 1;
            else {
                tokenCount = tokenCount + 1;
                if (pTypes[i] == "p") hasP = 1;
                if (pTypes[i] == "f") hasF = 1;
                if (i > 0 && pTypes[i - 1] != "L") adjacentToken = 1;
            }
            i = i + 1;
        }
        if (hasP == 0 && hasF == 0) return T_err_df_rule_tokens;
        if (hasP == 0 || hasF == 0) return T_err_df_rule_need_both;
        if (adjacentToken == 1 && !(literalCount == 0 && pTypes.length == 2))
            return T_err_df_rule_tokens;

        if (folderSpec != "") {
            spec2 = parseRuleSpec(folderSpec, "T");
            if (spec2[2] != "") return spec2[2];
            pattern2 = spec2[0];
            if (pattern2 == "") return T_err_df_rule_empty;
            parts2 = splitByChar(pattern2, "/");
            if (parts2.length < 2) return T_err_df_rule_slash;
            fTypes = newArray();
            fTexts = newArray();
            err2 = parsePatternParts(pattern2, fTypes, fTexts);
            if (err2 != "") return err2;

            hasP2 = 0;
            hasF2 = 0;
            tokenCount2 = 0;
            literalCount2 = 0;
            adjacentToken2 = 0;
            j = 0;
            while (j < fTypes.length) {
                if (fTypes[j] == "L") literalCount2 = literalCount2 + 1;
                else {
                    tokenCount2 = tokenCount2 + 1;
                    if (fTypes[j] == "p") hasP2 = 1;
                    if (fTypes[j] == "f") hasF2 = 1;
                    if (j > 0 && fTypes[j - 1] != "L") adjacentToken2 = 1;
                }
                j = j + 1;
            }
            if (hasP2 == 0 && hasF2 == 0) return T_err_df_rule_tokens;
            if (adjacentToken2 == 1 && !(literalCount2 == 0 && fTypes.length == 2))
                return T_err_df_rule_tokens;
        }
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: validateDataFormatCols
    // 概要: 表格列格式的妥当性を検証する�?
    // 引数: cols (string)
    // 戻り�? string (空ならOK、それ以外はエラーメッセージ)
    // -----------------------------------------------------------------------------
    function validateDataFormatCols(cols) {
        s = trim2(cols);
        if (lengthOf(s) == 0) return T_err_df_cols_empty;
        fmt = splitByChar(s, "/");
        singleCustomCount = 0;
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
            builtin = isBuiltinToken(tokenKey);
            if (builtin == 1 && single == 1)
                return T_err_df_cols_dollar_builtin;
            if (builtin == 0 && single == 1) {
                singleCustomCount = singleCustomCount + 1;
                if (singleCustomCount > 1) return T_err_df_cols_dollar_duplicate;
            }

            j = 1;
            paramCount = 0;
            seenName = 0;
            seenValue = 0;
            while (j < parts.length) {
                kv = trim2(parts[j]);
                if (kv != "") {
                    paramCount = paramCount + 1;
                    eq = indexOf(kv, "=");
                    if (eq <= 0) return T_err_df_cols_param_kv;
                    key = toLowerCase(trim2(substring(kv, 0, eq)));
                    val = trim2(substring(kv, eq + 1));
                    if (key != "name" && key != "value") return T_err_df_cols_param_unknown_prefix + key;
                    if (!(startsWith(val, "\"") && endsWith(val, "\"") && lengthOf(val) >= 2))
                        return T_err_df_cols_param_quote;
                    val = substring(val, 1, lengthOf(val) - 1);
                    if (key == "name") {
                        if (seenName == 1) return T_err_df_cols_param_duplicate + key;
                        seenName = 1;
                        if (lengthOf(val) == 0) return T_err_df_cols_param_empty_name;
                    } else if (key == "value") {
                        if (seenValue == 1) return T_err_df_cols_param_duplicate + key;
                        seenValue = 1;
                        if (lengthOf(val) == 0) return T_err_df_cols_param_empty_value;
                    }
                }
                j = j + 1;
            }
            if (builtin == 0 && paramCount == 0) return T_err_df_cols_custom_need_param;
            i = i + 1;
        }
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: requiresPerCellStats
    // 概要: 表格列配置が単細胞統計（BPC/EBPC/BPCSDP）を要求するか判定する�?
    // 引数: cols (string)
    // 戻り�? number (1=必要, 0=不要)
    // -----------------------------------------------------------------------------
    function requiresPerCellStats(cols) {
        s = trim2(cols);
        if (s == "") return 0;
        fmt = splitByChar(s, "/");
        i = 0;
        while (i < fmt.length) {
            raw = trim2(fmt[i]);
            if (raw != "") {
                parts = splitCSV(raw);
                tokenRaw = trim2(parts[0]);
                if (startsWith(tokenRaw, "$")) tokenRaw = substring(tokenRaw, 1);
                tokenKey = toLowerCase(trim2(tokenRaw));
                if (tokenKey == "bpc" || tokenKey == "ebpc" || tokenKey == "bpcsdp") return 1;
            }
            i = i + 1;
        }
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: uniqueList
    // 概要: 出現順でユニーク化する�?
    // 引数: arr (array)
    // 戻り�? array
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
    // 関数: findGroupIndex
    // 概要: (pn, keyNum) のグループインデックスを検索する�?
    // 引数: pn (string), keyNum (number), groupPn (array), groupKey (array)
    // 戻り�? number (index or -1)
    // -----------------------------------------------------------------------------
    function findGroupIndex(pn, keyNum, groupPn, groupKey) {
        i = 0;
        while (i < groupPn.length) {
            if (groupPn[i] == pn && groupKey[i] == keyNum) return i;
            i = i + 1;
        }
        return -1;
    }

    // -----------------------------------------------------------------------------
    // 関数: sortPairsByNumber
    // 概要: 数値配列と対応配列を昇�?降順でソートする�?
    // 引数: nums (array), strs (array), desc (number)
    // 戻り�? なし（配列を直接並べ替える）
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
    // 概要: 数値配列と対応2配列を昇�?降順でソートする�?
    // 引数: nums (array), strs (array), idxs (array), desc (number)
    // 戻り�? なし（配列を直接並べ替える）
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
    // 関数: sortQuadsByNumber
    // 概要: 数値配列と対応3配列を昇�?降順でソートする�?
    // 引数: nums (array), strs (array), idxs (array), ids2 (array), desc (number)
    // 戻り�? なし（配列を直接並べ替える）
    // -----------------------------------------------------------------------------
    function sortQuadsByNumber(nums, strs, idxs, ids2, desc) {
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
                    y = ids2[i];
                    ids2[i] = ids2[j];
                    ids2[j] = y;
                }
                j = j + 1;
            }
            i = i + 1;
        }
        return;
    }

    // -----------------------------------------------------------------------------
    // 関数: calcRatio
    // 概要: 分子/分母を安全に計算する�?
    // 引数: num (number), den (number)
    // 戻り�? number or ""
    // -----------------------------------------------------------------------------
    function calcRatio(num, den) {
        if (num == "" || den == "") return "";
        if (den <= 0) return "";
        return num / den;
    }

    // -----------------------------------------------------------------------------
    // 関数: forcePixelUnit
    // 概要: 画像スケールをピクセル単位に固定する�?
    // 引数: なし
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function forcePixelUnit() {
        run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
    }

    // -----------------------------------------------------------------------------
    // 関数: ensure2D
    // 概要: Zスタックの場合はスライス1に固定し2D化する�?
    // 引数: なし
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function ensure2D() {
        getDimensions(_w, _h, _c, _z, _t);
        if (_z > 1) Stack.setSlice(1);
    }

    // -----------------------------------------------------------------------------
    // 関数: safeClose
    // 概要: 指定ウィンドウが開いていれば閉じる�?
    // 引数: title (string)
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function safeClose(title) {
        if (isOpen(title)) {
            selectWindow(title);
            close();
        }
    }

    // -----------------------------------------------------------------------------
    // 関数: escapeForReplace
    // 概要: replace() の置換文字列で問題になる "$" �?"\" をエスケープする�?
    // 引数: s (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function escapeForReplace(s) {
        s = replace(s, "\\", "\\\\");
        s = replace(s, "$", "\\$");
        return s;
    }

    // -----------------------------------------------------------------------------
    // 関数: replaceSafe
    // 概要: 置換文字列をエスケープしてか�?replace() を実行する�?    // 引数: template (string), token (string), value (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function replaceSafe(template, token, value) {
        return replace(template, token, escapeForReplace("" + value));
    }

    // -----------------------------------------------------------------------------
    // 関数: isValidNumber
    // 概要: 数値が有効か（NaNでないか）判定する�?    // 引数: x (number)
    // 戻り�? number (1=有効, 0=無効)
    // -----------------------------------------------------------------------------
    function isValidNumber(x) {
        if (x != x) return 0;
        return 1;
    }

    // -----------------------------------------------------------------------------
    // 関数: validateDialogNumber
    // 概要: ダイアログ数値の妥当性を検証し、無効なら通知する�?    // 引数: val (number), label (string), stage (string)
    // 戻り�? number (1=OK, 0=NG)
    // -----------------------------------------------------------------------------
    function validateDialogNumber(val, label, stage) {
        if (isValidNumber(val) == 1) return 1;
        msg = T_err_param_num_msg;
        msg = replaceSafe(msg, "%s", label);
        msg = replaceSafe(msg, "%stage", stage);
        logErrorMessage(msg);
        showMessage(T_err_param_num_title, msg);
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: getDataFormatFix
    // 概要: データ形式エラーコードに対応する修正案を返す�?    // 引数: code (string)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function getDataFormatFix(code) {
        if (code == "101") return T_err_df_fix_101;
        if (code == "102") return T_err_df_fix_102;
        if (code == "103") return T_err_df_fix_103;
        if (code == "104") return T_err_df_fix_104;
        if (code == "105") return T_err_df_fix_105;
        if (code == "106") return T_err_df_fix_106;
        if (code == "107") return T_err_df_fix_107;
        if (code == "108") return T_err_df_fix_108;
        if (code == "109") return T_err_df_fix_109;
        if (code == "110") return T_err_df_fix_110;
        if (code == "111") return T_err_df_fix_111;
        if (code == "112") return T_err_df_fix_112;
        if (code == "113") return T_err_df_fix_113;
        if (code == "114") return T_err_df_fix_114;
        if (code == "121") return T_err_df_fix_121;
        if (code == "122") return T_err_df_fix_122;
        if (code == "123") return T_err_df_fix_123;
        if (code == "124") return T_err_df_fix_124;
        if (code == "125") return T_err_df_fix_125;
        if (code == "126") return T_err_df_fix_126;
        if (code == "127") return T_err_df_fix_127;
        if (code == "128") return T_err_df_fix_128;
        if (code == "129") return T_err_df_fix_129;
        if (code == "130") return T_err_df_fix_130;
        if (code == "131") return T_err_df_fix_131;
        if (code == "132") return T_err_df_fix_132;
        if (code == "133") return T_err_df_fix_133;
        if (code == "134") return T_err_df_fix_134;
        if (code == "135") return T_err_df_fix_135;
        return "";
    }

    // -----------------------------------------------------------------------------
    // 関数: logErrorMessage
    // 概要: エラー文字列をログに出力する�?    // 引数: msg (string)
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function logErrorMessage(msg) {
        line = T_log_error;
        line = replaceSafe(line, "%s", msg);
        log(line);
    }

    // -----------------------------------------------------------------------------
    // 関数: requireWindow
    // 概要: 指定ウィンドウが存在しない場合はエラー終了する�?
    // 引数: title (string), stage (string), fileName (string)
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function requireWindow(title, stage, fileName) {
        if (!isOpen(title)) {
            msg = T_err_need_window;
            msg = replaceSafe(msg, "%stage", stage);
            msg = replaceSafe(msg, "%w", title);
            msg = replaceSafe(msg, "%f", fileName);
            logErrorMessage(msg);
            exit(msg);
        }
        selectWindow(title);
    }

    // -----------------------------------------------------------------------------
    // 関数: openImageSafe
    // 概要: 画像ファイルを開き、開けない場合はエラー終了する�?    // 引数: path (string), stage (string), fileName (string)
    // 戻り�? string（開いたウィンドウタイトル）
    // -----------------------------------------------------------------------------
    function openImageSafe(path, stage, fileName) {
        if (!File.exists(path)) {
            msg = T_err_open_fail;
            msg = replaceSafe(msg, "%p", path);
            msg = replaceSafe(msg, "%stage", stage);
            msg = replaceSafe(msg, "%f", fileName);
            logErrorMessage(msg);
            exit(msg);
        }
        titles = getList("image.titles");
        n0 = titles.length;
        open(path);
        titles2 = getList("image.titles");
        if (titles2.length <= n0) {
            msg = T_err_open_fail;
            msg = replaceSafe(msg, "%p", path);
            msg = replaceSafe(msg, "%stage", stage);
            msg = replaceSafe(msg, "%f", fileName);
            logErrorMessage(msg);
            exit(msg);
        }
        title = titles2[titles2.length - 1];
        selectWindow(title);
        return title;
    }

    // -----------------------------------------------------------------------------
    // 関数: printWithIndex
    // 概要: 進捗テンプレートを置換してログ出力する�?    // 引数: template (string), iVal (number), nVal (number), fVal (string)
    // 戻り�? なし
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
    // 概要: データ形式の設定内容を詳細にログ出力する�?
    // 引数: rule, cols, itemSpecs, itemTokens, itemNames, itemValues, itemSingles, sortDesc, sortKeyLabel
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function logDataFormatDetails(rule, cols, itemSpecs, itemTokens, itemNames, itemValues, itemSingles, sortDesc, sortKeyLabel) {
        if (!LOG_VERBOSE) return;
        log(T_log_df_header);
        log(replaceSafe(T_log_df_rule, "%s", rule));
        log(replaceSafe(T_log_df_cols, "%s", cols));
        if (sortDesc == 1) log(replaceSafe(T_log_df_sort_desc, "%s", sortKeyLabel));
        else log(replaceSafe(T_log_df_sort_asc, "%s", sortKeyLabel));

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
    // 概要: 言語設定とフラグに応じてランダムなモットーを表示する�?
    // 引数: なし
    // 戻り�? なし
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
    // 概要: 座標を画像範囲にクランプしてピクセル値を取得する�?
    // 引数: x (number), y (number), w (number), h (number)
    // 戻り�? number
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
    // 概要: 3x3近傍の平均灰度を返す（境界は安全取得）�?
    // 引数: x (number), y (number), w (number), h (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function localMean3x3(x, y, w, h) {
        if (x > 0 && y > 0 && x < (w - 1) && y < (h - 1)) {
            sum =
                getPixel(x - 1, y - 1) + getPixel(x, y - 1) + getPixel(x + 1, y - 1) +
                getPixel(x - 1, y)     + getPixel(x, y)     + getPixel(x + 1, y) +
                getPixel(x - 1, y + 1) + getPixel(x, y + 1) + getPixel(x + 1, y + 1);
            return sum / 9.0;
        }
        x0 = clamp(x - 1, 0, w - 1);
        x1 = clamp(x, 0, w - 1);
        x2 = clamp(x + 1, 0, w - 1);
        y0 = clamp(y - 1, 0, h - 1);
        y1 = clamp(y, 0, h - 1);
        y2 = clamp(y + 1, 0, h - 1);
        sum =
            getPixel(x0, y0) + getPixel(x1, y0) + getPixel(x2, y0) +
            getPixel(x0, y1) + getPixel(x1, y1) + getPixel(x2, y1) +
            getPixel(x0, y2) + getPixel(x1, y2) + getPixel(x2, y2);
        return sum / 9.0;
    }

    // -----------------------------------------------------------------------------
    // 関数: annotateCellsSmart
    // 概要: 画像を開き、ROI Managerで細胞ROIを対話的に作�?編集してZIP保存する�?
    // 引数: dir (string), imgName (string), roiSuffix (string), idx (number),
    //       total (number), skipFlag (number)
    // 戻り�? skipFlag (number) - 「以降をスキップ」状�?
    // 副作�? 画像の表示、ROI Manager操作、ユーザー操作待ちが発生する�?
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

        openImageSafe(dir + imgName, "roi/open", imgName);
        ensure2D();
        forcePixelUnit();

        roiManager("Reset");
        roiManager("Show All");

        if (action == T_exist_edit && File.exists(roiOut)) {
            roiManager("Open", roiOut);
            if (roiManager("count") == 0) {
                msg = T_err_roi_open_msg;
                msg = replaceSafe(msg, "%p", roiOut);
                msg = replaceSafe(msg, "%stage", "roi/open");
                msg = replaceSafe(msg, "%f", imgName);
                logErrorMessage(msg);
                showMessage(T_err_roi_open_title, msg);
            }
            roiManager("Show All with labels");
        }

        msg = T_cell_msg;
        msg = replaceSafe(msg, "%i", "" + idx);
        msg = replaceSafe(msg, "%n", "" + total);
        msg = replaceSafe(msg, "%f", imgName);
        msg = replaceSafe(msg, "%s", roiSuffix);

        waitForUser(T_cell_title, msg);

        roiCount = roiManager("count");
        if (roiCount > 0) {
            roiManager("Save", roiOut);
            if (!File.exists(roiOut)) {
                msg = T_err_roi_save_msg;
                msg = replaceSafe(msg, "%p", roiOut);
                msg = replaceSafe(msg, "%stage", "roi/save");
                msg = replaceSafe(msg, "%f", imgName);
                logErrorMessage(msg);
                showMessage(T_err_roi_save_title, msg);
            }
        } else {
            msg = T_err_roi_empty_msg;
            msg = replaceSafe(msg, "%stage", "roi/save");
            msg = replaceSafe(msg, "%f", imgName);
            logErrorMessage(msg);
            showMessage(T_err_roi_empty_title, msg);
        }

        close();
        return skipFlag;
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateAreaRangeSafe
    // 概要: サンプル面積の分布から、外れ値に強い範囲と代表値を推定する�?
    // 引数: sampleAreas (array), fallbackMin (number), fallbackMax (number)
    // 戻り�? array[minArea, maxArea, unitArea]
    // 補足: サンプルが少ない場合は中央値ベースで保守的に推定する�?
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
    // 概要: 代表面積を直径に換算し、経験則でRolling Ball半径を推定する�?
    // 引数: unitArea (number)
    // 戻り�? number
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
    // 概要: 目標/排除サンプルの灰度分布から排除モードと閾値を推定する�?
    // 引数: targetMeans (array), exclMeansAll (array)
    // 戻り�? array[validFlag, mode, thr, useSizeGate, note]
    // 補足: サンプル不足や重なりが大きい場合は保守的な結果を返す�?
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
    // 関数: estimateMeanMedianSafe
    // 概要: 平均濃度サンプルから中央値を推定する�?
    // 引数: meanArray (array)
    // 戻り�? number（不十分な場合は-1�?
    // 補足: 飽和値を除外し、サンプル不足時�?1を返す�?
    // -----------------------------------------------------------------------------
    function estimateMeanMedianSafe(meanArray) {
        tLen = meanArray.length;
        if (tLen < 3) return -1;

        t2 = newArray();
        k = 0;
        while (k < tLen) {
            v = meanArray[k];
            if (v > 1 && v < 254) t2[t2.length] = v;
            k = k + 1;
        }
        if (t2.length < 3) return -1;

        Array.sort(t2);
        idx = floor((t2.length - 1) * 0.50);
        return t2[idx];
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateAbsDiffThresholdSafe
    // 概要: 絶対差分の分布から閾値を推定する�?
    // 引数: diffArray (array), fallback (number), minThr (number),
    //       maxThr (number), q (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function estimateAbsDiffThresholdSafe(diffArray, fallback, minThr, maxThr, q) {
        n = diffArray.length;
        if (n < 3) return fallback;

        tmp = newArray(n);
        k = 0;
        while (k < n) {
            v = abs2(diffArray[k]);
            tmp[k] = v;
            k = k + 1;
        }

        Array.sort(tmp);
        idx = floor((n - 1) * q);
        if (idx < 0) idx = 0;
        if (idx > n - 1) idx = n - 1;
        thr = tmp[idx];

        if (thr < minThr) thr = minThr;
        if (thr > maxThr) thr = maxThr;
        return thr;
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateSmallAreaRatioSafe
    // 概要: 小さめ判定に使う面積比率を推定する�?
    // 引数: areaArray (array), fallback (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function estimateSmallAreaRatioSafe(areaArray, fallback) {
        n = areaArray.length;
        if (n < 3) return fallback;

        tmp = newArray(n);
        k = 0;
        while (k < n) {
            v = areaArray[k];
            if (v < 1) v = 1;
            tmp[k] = v;
            k = k + 1;
        }

        Array.sort(tmp);
        med = tmp[floor((n - 1) * 0.50)];
        q25 = tmp[floor((n - 1) * 0.25)];
        if (med < 1) med = 1;
        ratio = q25 / med;

        if (ratio < 0.45) ratio = 0.45;
        if (ratio > 0.90) ratio = 0.90;
        return ratio;
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateClumpRatioSafe
    // 概要: 団塊判定に使う面積比率を推定する�?
    // 引数: areaArray (array), fallback (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function estimateClumpRatioSafe(areaArray, fallback) {
        n = areaArray.length;
        if (n < 3) return fallback;

        tmp = newArray(n);
        k = 0;
        while (k < n) {
            v = areaArray[k];
            if (v < 1) v = 1;
            tmp[k] = v;
            k = k + 1;
        }

        Array.sort(tmp);
        med = tmp[floor((n - 1) * 0.50)];
        q90 = tmp[floor((n - 1) * 0.90)];
        if (med < 1) med = 1;
        ratio = q90 / med;

        if (ratio < 2.5) ratio = fallback;
        if (ratio < 2.5) ratio = 2.5;
        if (ratio > 12) ratio = 12;
        return ratio;
    }

    // -----------------------------------------------------------------------------
    // 関数: estimateClumpRatioFromSamples
    // 概要: 塊サンプルの面積から団塊最小面積倍率を推定する�?
    // 引数: clumpAreas (array), unitArea (number), fallback (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function estimateClumpRatioFromSamples(clumpAreas, unitArea, fallback) {
        n = clumpAreas.length;
        if (n < 1) return fallback;
        if (unitArea <= 0) return fallback;

        tmp = newArray(n);
        k = 0;
        while (k < n) {
            v = clumpAreas[k];
            if (v < 1) v = 1;
            ratio = v / unitArea;
            if (ratio < 1) ratio = 1;
            tmp[k] = ratio;
            k = k + 1;
        }

        Array.sort(tmp);
        idx = floor((n - 1) * 0.25);
        if (idx < 0) idx = 0;
        if (idx > n - 1) idx = n - 1;
        ratio = tmp[idx];

        if (ratio < 2.5) ratio = 2.5;
        if (ratio > 20) ratio = 20;
        return ratio;
    }

    // -----------------------------------------------------------------------------
    // 関数: buildCellLabelMaskFromOriginal
    // 概要: ROIごとにラベル値を塗り分け�?6-bitマスクを生成する�?
    // 引数: maskTitle (string), origID (number), w (number), h (number),
    //       nCells (number), fileName (string)
    // 戻り�? 1 = 成功, 0 = 失敗
    // 補足: nCells�?5535を超える場合は処理を中断する�?
    // -----------------------------------------------------------------------------
    function buildCellLabelMaskFromOriginal(maskTitle, origID, w, h, nCells, fileName) {

        if (nCells > 65535) {
            msg = T_err_too_many_cells + " " + nCells + "\n" + T_err_too_many_cells_hint + "\n" + T_err_file + fileName;
            logErrorMessage(msg);
            exit(msg);
        }

        safeClose(maskTitle);

        selectImage(origID);
        newImage(maskTitle, "16-bit black", w, h, 1);

        requireWindow(maskTitle, "cellLabel/duplicate", fileName);
        ensure2D();
        forcePixelUnit();

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
            msg = T_err_roi1_invalid + "\n" + T_err_file + fileName;
            logErrorMessage(msg);
            exit(msg);
        }
        cx = floor(bx + bw/2);
        cy = floor(by + bh/2);

        selectWindow(maskTitle);
        v = getPixelSafe(cx, cy, w, h);
        if (v <= 0) {
            msg = T_err_labelmask_failed + "\n\n" + T_err_labelmask_hint + "\n" + T_err_file + fileName;
            logErrorMessage(msg);
            exit(msg);
        }

        setColor(0);
        return 1;
    }

    // -----------------------------------------------------------------------------
    // 関数: sampleRingMean
    // 概要: 指定半径のリング上の平均灰度を返す�?
    // 引数: cx (number), cy (number), r (number), w (number), h (number)
    // 戻り�? number
    // -----------------------------------------------------------------------------
    function sampleRingMean(cx, cy, r, w, h) {
        if (r < 1) r = 1;

        d = r;
        d2 = r * 0.7071;

        sum = 0;
        n = 0;

        x = roundInt(cx + d);
        y = roundInt(cy);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx - d);
        y = roundInt(cy);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx);
        y = roundInt(cy + d);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx);
        y = roundInt(cy - d);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx + d2);
        y = roundInt(cy + d2);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx - d2);
        y = roundInt(cy + d2);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx + d2);
        y = roundInt(cy - d2);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        x = roundInt(cx - d2);
        y = roundInt(cy - d2);
        sum = sum + getPixelSafe(x, y, w, h);
        n = n + 1;

        if (n <= 0) return localMean3x3(cx, cy, w, h);
        return sum / n;
    }

    // -----------------------------------------------------------------------------
    // 関数: computeSpotStats
    // 概要: 円形候補の中�?外周/背景の濃度指標を計算する�?
    // 引数: cx (number), cy (number), r (number), w (number), h (number)
    // 戻り�? array[centerMean, ringMean, outerMean, spotMean, centerDiff, bgDiff]
    // -----------------------------------------------------------------------------
    function computeSpotStats(cx, cy, r, w, h) {
        if (r < 1) r = 1;

        centerMean = localMean3x3(cx, cy, w, h);
        ringMean = sampleRingMean(cx, cy, r * 0.75, w, h);
        outerMean = sampleRingMean(cx, cy, r * 1.35, w, h);
        spotMean = (centerMean + ringMean) / 2.0;

        centerDiff = centerMean - ringMean;
        bgDiff = abs2(spotMean - outerMean);

        return newArray(centerMean, ringMean, outerMean, spotMean, centerDiff, bgDiff);
    }

    // -----------------------------------------------------------------------------
    // 関数: classifyRoundFeature
    // 概要: 円形候補の特徴カテゴリを判定する�?
    // 引数: centerDiff (number), bgDiff (number), area (number), unitArea (number),
    //       featureFlags (array), featureParams (array)
    // 戻り�? number�?/2/5/6 のいずれか。該当なしは0�?
    // -----------------------------------------------------------------------------
    function classifyRoundFeature(
        centerDiff, bgDiff, area, unitArea,
        featureFlags, featureParams
    ) {
        // パラメータ配列を展開する
        useF1 = featureFlags[0];
        useF2 = featureFlags[1];
        useF5 = featureFlags[4];
        useF6 = featureFlags[5];

        centerDiffThr = featureParams[0];
        bgDiffThr = featureParams[1];
        smallAreaRatio = featureParams[2];

        absDiff = abs2(centerDiff);

        if (absDiff >= centerDiffThr) {
            if (centerDiff >= centerDiffThr && useF1 == 1) return 1;
            if (centerDiff <= -centerDiffThr && useF5 == 1) return 5;
            return 0;
        }

        isSmall = 0;
        if (unitArea > 0 && area <= unitArea * smallAreaRatio) isSmall = 1;

        isBgLike = 0;
        if (bgDiff <= bgDiffThr) isBgLike = 1;

        if (useF6 == 1 && (isBgLike == 1 || isSmall == 1)) return 6;
        if (useF2 == 1) return 2;
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: formatFeatureList
    // 概要: 特徴選択の番号リストを作成する�?
    // 引数: useF1 (number), useF2 (number), useF3 (number), useF4 (number),
    //       useF5 (number), useF6 (number)
    // 戻り�? string
    // -----------------------------------------------------------------------------
    function formatFeatureList(useF1, useF2, useF3, useF4, useF5, useF6) {
        s = "";

        if (useF1 == 1) s = "1";
        if (useF2 == 1) {
            if (s != "") s = s + ",";
            s = s + "2";
        }
        if (useF3 == 1) {
            if (s != "") s = s + ",";
            s = s + "3";
        }
        if (useF4 == 1) {
            if (s != "") s = s + ",";
            s = s + "4";
        }
        if (useF5 == 1) {
            if (s != "") s = s + ",";
            s = s + "5";
        }
        if (useF6 == 1) {
            if (s != "") s = s + ",";
            s = s + "6";
        }
        return s;
    }

    // -----------------------------------------------------------------------------
    // 関数: openFeatureReferenceImage
    // 概要: 参照画像を開き、指定タイトルにリネームする�?
    // 引数: url (string), refTitle (string)
    // 戻り�? number�?=表示済み/成功, 0=失敗�?
    // -----------------------------------------------------------------------------
    function openFeatureReferenceImage(url, refTitle) {
        titles = getList("image.titles");
        k = 0;
        while (k < titles.length) {
            if (titles[k] == refTitle) return 1;
            k = k + 1;
        }

        n0 = titles.length;
        open(url);
        titles2 = getList("image.titles");
        if (titles2.length > n0) {
            rename(refTitle);
            return 1;
        }
        showFeatureReferenceFallback(FEATURE_REF_REPO_URL);
        return 0;
    }

    // -----------------------------------------------------------------------------
    // 関数: showFeatureReferenceFallback
    // 概要: 参照画像が開けない場合に代替案を表示する�?
    // 引数: repoUrl (string)
    // 戻り�? なし
    // -----------------------------------------------------------------------------
    function showFeatureReferenceFallback(repoUrl) {
        logErrorMessage(T_feat_ref_fail_msg);
        Dialog.create(T_feat_ref_fail_title);
        Dialog.addMessage(T_feat_ref_fail_msg);
        Dialog.addString(T_feat_ref_fail_label, repoUrl, 55);
        Dialog.show();
    }

    // -----------------------------------------------------------------------------
    // 関数: filterFlatByMask
    // 概要: マスク内にある候補を除外して返す�?
    // 引数: flat (array), maskTitle (string), w (number), h (number), fileName (string)
    // 戻り�? array
    // -----------------------------------------------------------------------------
    function filterFlatByMask(flat, maskTitle, w, h, fileName) {
        if (flat.length == 0) return flat;
        if (maskTitle == "") return flat;

        requireWindow(maskTitle, "mask/filter", fileName);

        out = newArray();
        i = 0;
        lenFlat = flat.length;
        while (i + 2 < lenFlat) {
            x = flat[i];
            y = flat[i + 1];
            a = flat[i + 2];

            xi = floor(x + 0.5);
            yi = floor(y + 0.5);

            keep = 1;
            if (xi >= 0 && yi >= 0 && xi < w && yi < h) {
                if (getPixel(xi, yi) > 0) keep = 0;
            }

            if (keep == 1) {
                out[out.length] = x;
                out[out.length] = y;
                out[out.length] = a;
            }
            i = i + 3;
        }
        return out;
    }

    // -----------------------------------------------------------------------------
    // 関数: buildClumpMaskDark
    // 概要: 濃暗な塊を抽出するマスクを作成する�?
    // 引数: grayTitle (string), strictChoice (string), fileName (string)
    // 戻り�? string（マスク画像タイトル�?
    // -----------------------------------------------------------------------------
    function buildClumpMaskDark(grayTitle, strictChoice, fileName) {
        maskTitle = "__mask_clump_dark";
        safeClose(maskTitle);

        requireWindow(grayTitle, "clump/select-gray", fileName);
        run("Duplicate...", "title=" + maskTitle);
        requireWindow(maskTitle, "clump/open-dark", fileName);

        if (strictChoice != T_strict_L) run("Median...", "radius=1");

        setAutoThreshold("Yen dark");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");

        if (strictChoice == T_strict_S) {
            run("Open");
            run("Open");
        } else if (strictChoice == T_strict_N) {
            run("Open");
        }
        return maskTitle;
    }

    // -----------------------------------------------------------------------------
    // 関数: buildClumpMaskInCell
    // 概要: 細胞内の高密度領域を抽出するマスクを作成する�?
    // 引数: grayTitle (string), cellLabelTitle (string), HAS_LABEL_MASK (number),
    //       strictChoice (string), unitArea (number), fileName (string)
    // 戻り�? string（マスク画像タイトル。作成不能なら空文字�?
    // -----------------------------------------------------------------------------
    function buildClumpMaskInCell(
        grayTitle, cellLabelTitle, HAS_LABEL_MASK, strictChoice, unitArea, fileName
    ) {
        if (HAS_LABEL_MASK != 1) return "";

        varTitle = "__mask_var";
        cellTitle = "__mask_cell";
        maskTitle = "__mask_clump_cell";

        safeClose(varTitle);
        safeClose(cellTitle);
        safeClose(maskTitle);

        requireWindow(grayTitle, "clump/select-gray2", fileName);
        run("Duplicate...", "title=" + varTitle);
        requireWindow(varTitle, "clump/open-var", fileName);

        r = sqrt(unitArea / PI) * 0.45;
        varRadius = roundInt(r);
        if (varRadius < 1) varRadius = 1;
        if (varRadius > 6) varRadius = 6;
        if (strictChoice == T_strict_S) varRadius = min2(6, varRadius + 1);
        else if (strictChoice == T_strict_L) varRadius = max2(1, varRadius - 1);

        run("Variance...", "radius=" + varRadius);
        run("8-bit");

        setAutoThreshold("Otsu light");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        if (strictChoice == T_strict_S) run("Open");

        requireWindow(cellLabelTitle, "clump/select-label", fileName);
        run("Duplicate...", "title=" + cellTitle);
        requireWindow(cellTitle, "clump/open-cell", fileName);
        setThreshold(1, 65535);
        setOption("BlackBackground", true);
        run("Convert to Mask");

        run("Image Calculator...", "image1=" + varTitle + " image2=" + cellTitle + " operation=AND create");
        rename(maskTitle);

        safeClose(varTitle);
        safeClose(cellTitle);

        return maskTitle;
    }

    // -----------------------------------------------------------------------------
    // 関数: detectClumpsFromMask
    // 概要: マスク画像から塊候補を抽出する�?
    // 引数: maskTitle (string), minArea (number), maxArea (number), fileName (string)
    // 戻り�? flat配列 [x1, y1, a1, ...]
    // -----------------------------------------------------------------------------
    function detectClumpsFromMask(maskTitle, minArea, maxArea, fileName) {
        if (maskTitle == "") return newArray();

        requireWindow(maskTitle, "clump/select-mask", fileName);

        run("Clear Results");
        run("Analyze Particles...",
            "size=" + minArea + "-" + maxArea +
            " show=Nothing clear"
        );

        nRes = nResults;
        flat = newArray(nRes * 3);
        pos = 0;
        row = 0;
        while (row < nRes) {
            flat[pos] = getResult("X", row);
            pos = pos + 1;
            flat[pos] = getResult("Y", row);
            pos = pos + 1;
            flat[pos] = getResult("Area", row);
            pos = pos + 1;
            row = row + 1;
        }
        run("Clear Results");
        return flat;
    }

    // -----------------------------------------------------------------------------
    // 関数: detectBeadsFusion
    // 概要: 2つの検出法（閾�?エッジ）で円形候補を抽出し、近接点を統合する�?
    // 引数: grayTitle (string), strictChoice (string), targetParams (array),
    //       imgParams (array), statsParams (array), thrModePref (string),
    //       fileName (string)
    // 戻り�? flat配列 [x1, y1, a1, ...]
    // 補足: strictChoiceによりフィルタ強度と統合基準を調整する�?
    // -----------------------------------------------------------------------------
    function detectBeadsFusion(
        grayTitle, strictChoice, targetParams, imgParams, statsParams, thrModePref,
        fileName
    ) {

        // パラメータ配列を展開する
        effMinArea = targetParams[0];
        effMaxArea = targetParams[1];
        effMinCirc = targetParams[2];
        beadUnitArea = targetParams[3];
        allowClumpsTarget = targetParams[4];

        imgW = imgParams[0];
        imgH = imgParams[1];

        targetMeanMed = statsParams[0];
        exclMeanMed = statsParams[1];

        // 検出ポリシーの決定（厳密度により統合条件を変える�?
        policy = "UNION";
        if (strictChoice == T_strict_S) policy = "STRICT";
        else if (strictChoice == T_strict_N) policy = "UNION";
        else policy = "LOOSE";

        // 検出に使う最大面積（塊推定を許可する場合は上限を緩める）
        detectMaxArea = effMaxArea;
        if (allowClumpsTarget == 1) {
            areaCap = imgW * imgH;
            if (areaCap < 1) areaCap = effMaxArea;
            detectMaxArea = max2(detectMaxArea, areaCap);
        }

        // 目標/排除の濃度中央値から極性を推定する
        thrMode = "AUTO";
        if (thrModePref == "DARK" || thrModePref == "LIGHT") {
            thrMode = thrModePref;
        } else {
            if (targetMeanMed >= 0 && exclMeanMed >= 0) {
                if (targetMeanMed <= exclMeanMed) thrMode = "DARK";
                else thrMode = "LIGHT";
            } else if (targetMeanMed >= 0) {
                requireWindow(grayTitle, "detect/select-gray-mean", fileName);
                getStatistics(_a, imgMean, _min, _max, _std);
                if (targetMeanMed <= imgMean) thrMode = "DARK";
                else thrMode = "LIGHT";
            }
        }

        // 手法A: 閾値ベースで円形候補を抽出す�?
        safeClose("__bin_A");
        requireWindow(grayTitle, "detect/select-gray", fileName);
        run("Duplicate...", "title=__bin_A");
        requireWindow("__bin_A", "detect/open-binA", fileName);

        if (policy != "LOOSE") run("Median...", "radius=1");

        if (thrMode == "DARK") setAutoThreshold("Yen dark");
        else if (thrMode == "LIGHT") setAutoThreshold("Yen light");
        else setAutoThreshold("Yen");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        if (policy != "LOOSE") run("Open");
        if (policy == "STRICT") run("Open");
        if (policy == "STRICT") run("Watershed");

        // 面積/円形度条件で候補を収集す�?
        run("Clear Results");
        run("Analyze Particles...",
            "size=" + effMinArea + "-" + detectMaxArea +
            " circularity=" + effMinCirc + "-1.00 show=Nothing clear"
        );

        // 手法Aの結果を配列に格納す�?
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

        // 手法B: エッジ抽出ベースで候補を抽出す�?
        safeClose("__bin_B");
        requireWindow(grayTitle, "detect/select-gray-2", fileName);
        run("Duplicate...", "title=__bin_B");
        requireWindow("__bin_B", "detect/open-binB", fileName);

        run("Find Edges");
        if (thrMode == "DARK") setAutoThreshold("Otsu dark");
        else if (thrMode == "LIGHT") setAutoThreshold("Otsu light");
        else setAutoThreshold("Otsu");
        setOption("BlackBackground", true);
        run("Convert to Mask");
        run("Fill Holes");
        if (policy != "LOOSE") run("Open");
        if (policy == "STRICT") run("Watershed");

        // 面積/円形度条件で候補を収集す�?
        run("Clear Results");
        run("Analyze Particles...",
            "size=" + effMinArea + "-" + detectMaxArea +
            " circularity=" + effMinCirc + "-1.00 show=Nothing clear"
        );

        // 手法Bの結果を配列に格納す�?
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

        // 近接距離のしきい値を、代表面積から推定す�?
        r = sqrt(beadUnitArea / PI);
        mergeDist = max2(2, r * 0.8);
        mergeDist2 = mergeDist * mergeDist;

        // 手法A/Bの候補を統合してユニオン集合を作る
        capU = nA + nB;
        xU = newArray(capU);
        yU = newArray(capU);
        aU = newArray(capU);
        srcA = newArray(capU);
        srcB = newArray(capU);

        uLen = 0;
        k = 0;
        while (k < nA) {
            xU[uLen] = xA[k];
            yU[uLen] = yA[k];
            aU[uLen] = aA[k];
            srcA[uLen] = 1;
            srcB[uLen] = 0;
            uLen = uLen + 1;
            k = k + 1;
        }

        // 近傍にある候補�?点に統合し、優先的に面積の大きい点を残�?
        j = 0;
        while (j < nB) {
            x = xB[j];
            y = yB[j];
            a = aB[j];
            merged = 0;

            k = 0;
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
                xU[uLen] = x;
                yU[uLen] = y;
                aU[uLen] = a;
                srcA[uLen] = 0;
                srcB[uLen] = 1;
                uLen = uLen + 1;
            }

            j = j + 1;
        }

        // 厳密モードでは両手法一致または大面積のみを残す
        flat = newArray();
        keepStrict = (policy == "STRICT");
        keepArea = beadUnitArea * 1.25;
        k = 0;
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
    // 関数: detectTargetsMulti
    // 概要: 特徴選択に基づき、円形候補と塊候補を統合して返す�?
    // 引数: grayTitle (string), strictChoice (string), targetParams (array),
    //       imgParams (array), statsParams (array), featureFlags (array),
    //       featureParams (array), cellLabelTitle (string), HAS_LABEL_MASK (number),
    //       fileName (string)
    // 戻り�? flat配列 [x1, y1, a1, ...]
    // -----------------------------------------------------------------------------
    function detectTargetsMulti(
        grayTitle, strictChoice,
        targetParams, imgParams, statsParams,
        featureFlags, featureParams,
        cellLabelTitle, HAS_LABEL_MASK,
        fileName
    ) {

        // パラメータ配列を展開する
        effMinArea = targetParams[0];
        effMaxArea = targetParams[1];
        effMinCirc = targetParams[2];
        beadUnitArea = targetParams[3];
        allowClumpsTarget = targetParams[4];

        imgW = imgParams[0];
        imgH = imgParams[1];

        targetMeanMed = statsParams[0];
        exclMeanMed = statsParams[1];

        useF1 = featureFlags[0];
        useF2 = featureFlags[1];
        useF3 = featureFlags[2];
        useF4 = featureFlags[3];
        useF5 = featureFlags[4];
        useF6 = featureFlags[5];

        centerDiffThr = featureParams[0];
        bgDiffThr = featureParams[1];
        smallAreaRatio = featureParams[2];
        clumpMinRatio = featureParams[3];

        flatRound = newArray();
        hasRound = 0;
        if (useF1 == 1 || useF2 == 1 || useF5 == 1 || useF6 == 1) hasRound = 1;

        if (hasRound == 1) {
            thrModePref = "AUTO";
            if (useF5 == 1 && useF1 == 0) thrModePref = "LIGHT";
            else if (useF1 == 1 && useF5 == 0) thrModePref = "DARK";

            flatCand = detectBeadsFusion(
                grayTitle, strictChoice, targetParams, imgParams, statsParams, thrModePref,
                fileName
            );

            if (flatCand.length > 0) {
                requireWindow(grayTitle, "detect/select-gray-main", fileName);

                i = 0;
                while (i + 2 < flatCand.length) {
                    x = flatCand[i];
                    y = flatCand[i + 1];
                    a = flatCand[i + 2];

                    xi = floor(x + 0.5);
                    yi = floor(y + 0.5);
                    r = sqrt(a / PI);
                    if (r < 1) r = 1;

                    stats = computeSpotStats(xi, yi, r, imgW, imgH);
                    centerDiff = stats[4];
                    bgDiff = stats[5];

                    feat = classifyRoundFeature(
                        centerDiff, bgDiff, a, beadUnitArea,
                        featureFlags, featureParams
                    );

                    if (feat > 0) {
                        flatRound[flatRound.length] = x;
                        flatRound[flatRound.length] = y;
                        flatRound[flatRound.length] = a;
                    }
                    i = i + 3;
                }
            }
        }

        maskDark = "";
        maskCell = "";
        maskClump = "";

        if (useF3 == 1) maskDark = buildClumpMaskDark(grayTitle, strictChoice, fileName);
        if (useF4 == 1)
            maskCell = buildClumpMaskInCell(grayTitle, cellLabelTitle, HAS_LABEL_MASK, strictChoice, beadUnitArea, fileName);

        // 塊検出用マスクを条件に応じて合成する�?        if (maskDark != "" && maskCell != "") {
            maskClump = "__mask_clump";
            safeClose(maskClump);
            run("Image Calculator...", "image1=" + maskDark + " image2=" + maskCell + " operation=Max create");
            rename(maskClump);
            safeClose(maskDark);
            safeClose(maskCell);
        } else if (maskDark != "") {
            maskClump = maskDark;
        } else if (maskCell != "") {
            maskClump = maskCell;
        }

        flatClump = newArray();
        if (maskClump != "") {
            clumpMinArea = beadUnitArea * clumpMinRatio;
            if (clumpMinArea < 1) clumpMinArea = 1;

            maxArea = imgW * imgH;
            if (maxArea < 1) maxArea = effMaxArea;

            flatClump = detectClumpsFromMask(maskClump, clumpMinArea, maxArea, fileName);
            if (flatRound.length > 0) {
                flatRound = filterFlatByMask(flatRound, maskClump, imgW, imgH, fileName);
            }
        }

        totalLen = flatRound.length + flatClump.length;
        flat = newArray(totalLen);
        pos = 0;
        k = 0;
        while (k + 2 < flatRound.length) {
            flat[pos] = flatRound[k];
            pos = pos + 1;
            flat[pos] = flatRound[k + 1];
            pos = pos + 1;
            flat[pos] = flatRound[k + 2];
            pos = pos + 1;
            k = k + 3;
        }
        k = 0;
        while (k + 2 < flatClump.length) {
            flat[pos] = flatClump[k];
            pos = pos + 1;
            flat[pos] = flatClump[k + 1];
            pos = pos + 1;
            flat[pos] = flatClump[k + 2];
            pos = pos + 1;
            k = k + 3;
        }

        if (maskClump != "") safeClose(maskClump);
        return flat;
    }

    // -----------------------------------------------------------------------------
    // 関数: countBeadsByFlat
    // 概要: 対象物検出結果を細胞ごとに集計し統計値を返す�?
    // 引数: flat, cellLabelTitle, nCellsAll, imgParams, HAS_LABEL_MASK,
    //       targetParams, exclParams, exclMode, grayTitle, fileName, useMinPhago,
    //       needPerCellStats
    // 戻り�? array[nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr, cellBeadStr]
    // 補足: targetParams �?[unitArea, allowClumps, usePixelCount] を想定する�?    // 補足: ラベルマスク未使用時はROI境界で判定するため処理が遅くなる�?    // -----------------------------------------------------------------------------
    function countBeadsByFlat(
        flat, cellLabelTitle, nCellsAll, imgParams, HAS_LABEL_MASK,
        targetParams, exclParams, exclMode, grayTitle, fileName,
        useMinPhago, needPerCellStats
    ) {

        // パラメータ配列を展開する
        w = imgParams[0];
        h = imgParams[1];

        beadUnitArea = targetParams[0];
        allowClumpsTarget = targetParams[1];
        usePixelCount = 0;
        if (targetParams.length > 2) usePixelCount = targetParams[2];

        useExcl = exclParams[0];
        exclThr = exclParams[1];
        useExclSizeGate = exclParams[2];
        exclMinA = exclParams[3];
        exclMaxA = exclParams[4];

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
        if (usePixelCount == 1) allowClumps = 0;
        clumpThresh = beadUnitArea * 1.35;
        useCellCounts = (needPerCellStats == 1 || useMinPhago == 1);

        // ラベルマスクが無い場合はROI境界のキャッシュを作�?
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

        // 参照ウィンドウを必要に応じて切り替え�?
        currWin = "";
        if (useExclOn || !useLabelMask) {
            requireWindow(grayTitle, "count/select-gray", fileName);
            currWin = "gray";
        } else if (useLabelMask) {
            requireWindow(cellLabelTitle, "count/select-cellLabel", fileName);
            currWin = "label";
        }

        // 対象物候補を順に走査して除�?集計を行�?
        if (useLabelMask && !useExclOn) {
            if (currWin != "label") {
                selectWindow(cellLabelTitle);
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

                    // 団塊を代表面積から分割推定する（許可時かつピクセル計数でない場合のみ）�?                    est = 1;
                    if (usePixelCount == 1) {
                        est = a;
                    } else if (allowClumps) {
                        if (a > clumpThresh) {
                            est = roundInt(a / beadUnitArea);
                            if (est < 1) est = 1;
                            if (est > 80) est = 80;
                        }
                    }

                    nBeadsAll = nBeadsAll + est;

                    cellId = getPixel(xi, yi);
                    if (cellId > 0) {
                        nBeadsInCells = nBeadsInCells + est;
                        idx = cellId - 1;
                        if (idx >= 0 && idx < nCellsAll) {
                            if (useCellCounts) cellBeadCount[idx] = cellBeadCount[idx] + est;
                            cellsWithBead[idx] = 1;
                        }
                    }
                }

                i = i + 3;
            }
        } else {
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

                    // 団塊を代表面積から分割推定する（許可時かつピクセル計数でない場合のみ）�?                    est = 1;
                    if (usePixelCount == 1) {
                        est = a;
                    } else if (allowClumps) {
                        if (a > clumpThresh) {
                            est = roundInt(a / beadUnitArea);
                            if (est < 1) est = 1;
                            if (est > 80) est = 80;
                        }
                    }

                    nBeadsAll = nBeadsAll + est;

                    cellId = 0;

                    // ラベルマスクがある場合はピクセル値で細胞IDを取得す�?
                    if (useLabelMask) {

                        if (currWin != "label") {
                            selectWindow(cellLabelTitle);
                            currWin = "label";
                        }
                        cellId = getPixel(xi, yi);

                    } else {

                        // ラベルマスクが無い場合はROIに含まれるかを判定す�?
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

                    // 細胞内に入った対象物を集計す�?
                    if (cellId > 0) {
                        nBeadsInCells = nBeadsInCells + est;
                        idx = cellId - 1;
                        if (idx >= 0 && idx < nCellsAll) {
                            if (useCellCounts) cellBeadCount[idx] = cellBeadCount[idx] + est;
                            cellsWithBead[idx] = 1;
                        }
                    }
                }

                i = i + 3;
            }
        }

        // 対象物を含む細胞数を集計する
        nCellsWithBead = 0;
        c = 0;
        while (c < nCells) {
            if (cellsWithBead[c] == 1) nCellsWithBead = nCellsWithBead + 1;
            c = c + 1;
        }

        nCellsWithBeadAdj = nCellsWithBead;
        minPhagoThr = 1;

        // 微量貪食のしきい値を推定し、調整後の細胞数を算出す�?
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

        if (useCellCounts) cellBeadStr = joinNumberList(cellBeadCount);
        else cellBeadStr = "";
        return newArray(nBeadsAll, nBeadsInCells, nCellsWithBead, nCellsWithBeadAdj, minPhagoThr, cellBeadStr);
    }

    // =============================================================================
    // メインフロー: 対話型の解析手順をここから実行す�?
    // =============================================================================
    VERSION_STR = "2.2.4b";
    FEATURE_REF_URL = "https://kirikirby.github.io/Macrophage-4-Analysis/sample.png";
    FEATURE_REF_REPO_URL = "https://github.com/KiriKirby/Macrophage-4-Analysis";
    T_lang_title = "Language / 言�?/ 语言";
    T_lang_label = "Language / 言�?/ 语言";
    T_lang_msg =
        "巨噬细胞图像四元素值分析\n" +
        "Macrophage Image Four-Factor Analysis\n" +
        "マクロファージ画�?要素解析\n\n" +
        "Version: " + VERSION_STR + "\n" +
        "Contact: wangsychn@outlook.com\n" +
        "---------------------------------\n" +
        "仅限 Fiji 宏，ImageJ 中无法运行。\n" +
        "Fiji専用マクロです。ImageJでは動作しません。\n" +
        "Fiji-only macro; it will not run in ImageJ.\n\n" +
        "请选择界面语言 / 言語を選択 / Select language";

    // -----------------------------------------------------------------------------
    // フェーズ1: UI言語の選択
    // -----------------------------------------------------------------------------
    Dialog.create(T_lang_title);
    Dialog.addMessage(T_lang_msg);
    Dialog.addChoice(T_lang_label, newArray("中文", "日本�?, "English"), "中文");
    Dialog.show();
    lang = Dialog.getChoice();

    // -----------------------------------------------------------------------------
    // フェーズ2: 言語別UIテキスト定義
    // -----------------------------------------------------------------------------
    if (lang == "中文") {

        T_choose = "选择包含图像�?ROI 文件的文件夹";
        T_exit = "未选择文件夹。脚本已退出�?;
        T_noImages = "[E008] 所选文件夹中未找到图像文件（tif/tiff/png/jpg/jpeg）。脚本已退出�?;
        T_exitScript = "用户已退出脚本�?;
        T_err_dir_illegal_title = "文件夹非�?;
        T_err_dir_illegal_msg =
            "[E006] 所选文件夹同时包含文件与子文件夹。\n\n" +
            "要求：文件夹要么只包含文件，要么只包含子文件夹。\n\n" +
            "请确认后退出脚本�?;
        T_err_subdir_illegal_title = "子文件夹非法";
        T_err_subdir_illegal_msg =
            "[E007] 检测到子文件夹中仍包含子文件夹�?s\n\n" +
            "脚本不支持递归子文件夹。\n\n" +
            "请整理目录后重试�?;
        T_subfolder_title = "子文件夹模式";
        T_subfolder_msg =
            "检测到所选文件夹包含子文件夹。\n" +
            "脚本将以子文件夹模式运行。\n\n" +
            "请选择运行方式�?;
        T_subfolder_label = "运行方式";
        T_subfolder_keep = "区分子文件夹（保持结构）";
        T_subfolder_flat = "平铺运行（子文件夹名_文件名）";

        T_mode_title = "工作模式选择选择";
        T_mode_label = "请选择模式";
        T_mode_1 = "仅标注细�?ROI";
        T_mode_2 = "仅执行分�?;
        T_mode_3 = "标注后分析（推荐�?;
        T_mode_msg =
            "请选择本次工作模式（下拉菜单）：\n\n" +
            "1）仅标注细胞 ROI\n" +
            "   �?将逐张打开图像。\n" +
            "   �?你需要手动勾画细胞轮廓，并将 ROI 添加�?ROI Manager。\n" +
            "   �?完成后脚本将保存细胞 ROI 文件（默认：图像�?+ “_cells.zip”）。\n\n" +
            "2）仅分析四要素\n" +
            "   �?将直接执行目标物检测与统计。\n" +
            "   �?每张图像必须存在对应的细�?ROI 文件（默认：图像�?+ “_cells.zip”）。\n\n" +
            "3）标注后分析（推荐）\n" +
            "   �?对缺失细�?ROI 的图像先完成 ROI 标注。\n" +
            "   �?随后进行目标物抽样（必要时可进行排除对象抽样），最后执行批量分析。\n\n" +
            "说明：点击“OK”确认选择�?;

        T_step_roi_title = "细胞 ROI 标注";
        T_step_roi_msg =
            "即将进入【细�?ROI 标注】阶段。\n\n" +
            "在此阶段，你需要：\n" +
            "1）使用你当前选择的绘图工具勾画细胞轮廓（推荐自由手绘）。\n" +
            "2）每完成一个细胞轮廓，按键�?“T�?将该轮廓添加�?ROI Manager。\n" +
            "3）当前图像所有细胞标注完成后，点击本窗口 “OK�?进入下一张图像。\n\n" +
            "保存规则：\n" +
            "�?脚本将保�?ROI �?zip 文件：图像名 + �?s.zip”。\n\n" +
            "重要提示：\n" +
            "�?本脚本不会自动切换绘图工具，也不会自动判断细胞边界。\n" +
            "�?为获得稳定结果，建议保持轮廓闭合并覆盖完整细胞区域�?;

        T_step_bead_title = "目标物采�?;
        T_step_bead_msg =
            "即将进入【目标物抽样】阶段。\n\n" +
            "目的：\n" +
            "�?使用你圈选的样本，推断“典型单个目标物”的面积尺度与灰度特征。\n" +
            "�?推断结果将用于默认检测参数、团块按面积估算目标物数量，以及背景扣除的建议值。\n\n" +
            "补充说明：\n" +
            "�?如需识别特征3/4，可�?Freehand/Polygon 圈选较大或不规则区域；细胞内区域对应特�?，细胞外区域对应特征3。\n\n" +
            "操作要求：\n" +
            "1）使用椭圆工具圈选目标物（精度无需极端，但建议贴合）。\n" +
            "2）优先圈选“单个典型目标物”，避免明显团块/粘连，以提高推断可靠性。\n" +
            "3）每圈选一�?ROI，按键盘 “T�?添加�?ROI Manager。\n" +
            "4）完成本图像抽样后，点击本窗�?“OK”。\n" +
            "5）随后会出现“下一步操作”下拉菜单，用于选择继续抽样、结束抽样进入下一步或退出脚本�?;

        T_step_bead_ex_title = "排除对象采样（可选）";
        T_step_bead_ex_msg =
            "即将进入【排除对象抽样】阶段（仅在存在多种目标物或易混淆干扰对象时使用）。\n\n" +
            "目的：\n" +
            "�?学习需要排除对�?区域的灰度阈值（以及可选的面积范围），用于减少误检。\n\n" +
            "圈选规范：\n" +
            "�?椭圆/矩形 ROI：作为“排除对象”样本（学习灰度与面积范围）。\n" +
            "�?Freehand/Polygon ROI：作为“排除区域”样本（学习灰度，不学习面积范围）。\n\n" +
            "操作步骤：\n" +
            "1）圈选需要排除的对象或区域。\n" +
            "2）每圈选一�?ROI，按键盘 “T�?添加�?ROI Manager。\n" +
            "3）完成后点击本窗�?“OK”。\n" +
            "4）随后使用下拉菜单选择继续抽样、结束并计算进入参数设置，或退出脚本�?;

        T_feat_title = "目标物特征选择";
        T_feat_msg =
            "即将进入【目标物特征选择】。\n\n" +
            "目的：\n" +
            "�?指定本次分析需要识别的目标物外观特征。\n\n" +
            "说明：\n" +
            "�?仅对所选特征执行检测；同一目标只计数一次。\n" +
            "�?特征4仅在细胞内判定（需与细�?ROI 重合）。\n" +
            "�?特征1与特�?互斥，不能同时选择。\n" +
            "�?勾选情况会影响后续参数窗口中可调阈值的显示。\n\n" +
            "操作步骤：\n" +
            "1）对照弹出的参考图，勾选需要的特征。\n" +
            "2）点击“OK”进入参数设置�?;
        T_feat_ref_title = "目标物特征参考图（编号对应）";
        T_feat_ref_fail_title = "参考图无法打开";
        T_feat_ref_fail_msg =
            "[E020] 目标物特征参考图无法打开或加载超时。\n\n" +
            "请手动访�?GitHub 仓库中的说明页面查看参考图：\n\n" +
            "如果网络受限或加载失败，可直接在浏览器中打开下方地址�?;
        T_feat_ref_fail_label = "仓库地址（可复制�?;
        T_feat_1 = "1）中心高亮、外圈偏暗的圆形目标（反光型�?;
        T_feat_2 = "2）中等灰度、内外反差较小的圆形目标";
        T_feat_3 = "3）多个圆形目标聚集形成的深色团块（按面积估算数量�?;
        T_feat_4 = "4）细胞内高密�?杂纹区域（仅细胞内，按面积估算）";
        T_feat_5 = "5）中心偏暗、外圈偏亮的圆形目标（反差型�?;
        T_feat_6 = "6）低对比度、小尺寸圆形目标（接近细胞灰度）";
        T_feat_err_title = "特征选择错误";
        T_feat_err_conflict = "[E012] 特征1与特�?互斥，不能同时选择。请调整后重试�?;
        T_feat_err_none = "[E013] 未选择任何特征。请至少选择一种特征�?;

        T_result_next_title = "结果输出完成";
        T_result_next_msg =
            "结果表已生成。\n\n" +
            "说明：\n" +
            "1）勾选下方复选框并点击“OK”，返回参数设置并重新分析。\n" +
            "2）不勾选并点击“OK”，结束脚本�?;
        T_result_next_checkbox = "返回参数设置并重新分�?;

        T_step_param_title = "参数确认";
        T_step_param_msg =
            "即将打开【参数设置】窗口。\n\n" +
            "你将看到：\n" +
            "�?目标物抽样推断的默认面积范围、目标物尺度（用于团块估算）�?Rolling Ball 建议值。\n" +
            "�?依据所选特征显示的阈值参数：内外对比、背景接近、小尺寸比例、团块最小倍数。\n" +
            "�?若启用排除过滤，还将显示推断的灰度阈值与可选面积门控范围。\n\n" +
            "说明：\n" +
            "�?参数设置将分为两个窗口依次显示。\n\n" +
            "建议：\n" +
            "�?首次使用可优先采用默认值完成一次批量分析。\n" +
            "�?如需更严格或更宽松的检测，可调整面积范围与严格程度。\n\n" +
            "说明：点�?“OK�?确认并进入批量分析�?;

        T_step_main_title = "开始批量分�?;
        T_step_main_msg =
            "即将进入【批量分析】阶段。\n\n" +
            "脚本将对文件夹内所有图像执行：\n" +
            "�?读取细胞 ROI\n" +
            "�?目标物检测与统计（含团块估算与可选排除过滤）\n" +
            "�?汇总并写入 Results 表\n\n" +
            "运行方式：\n" +
            "�?批量分析在静默模式运行，以减少中间窗口弹出。\n\n" +
            "缺失细胞 ROI 时：\n" +
            "�?脚本将提示你选择：立即标�?/ 跳过 / 跳过全部 / 退出。\n" +
            "�?跳过的图像仍会在结果表中保留一行（数值为空）。\n\n" +
            "说明：点�?“OK�?开始�?;

        T_cell_title = "细胞 ROI 标注";
        T_cell_msg =
            "进度：第 %i / %n 张\n" +
            "文件�?f\n\n" +
            "请完成细胞轮廓标注：\n" +
            "1）勾画一个细胞轮廓。\n" +
            "2）按 “T�?将轮廓添加到 ROI Manager。\n" +
            "3）重复以上步骤，直到本图像的细胞全部完成。\n\n" +
            "完成后点�?“OK�?保存并继续。\n\n" +
            "保存文件：图像名 + �?s.zip�?;

        T_exist_title = "现有 ROI";
        T_exist_label = "选择";
        T_exist_edit = "编辑";
        T_exist_redraw = "重新标注并覆盖保�?;
        T_exist_skip = "跳过此图像（保留�?ROI�?;
        T_exist_skip_all = "跳过所有已存在 ROI 的图�?;
        T_exist_msg =
            "检测到当前图像已存在细�?ROI 文件。\n\n" +
            "进度�?i / %n\n" +
            "图像�?f\n" +
            "ROI�?b%s.zip\n\n" +
            "选项说明：\n" +
            "�?加载并继续编辑：打开现有 ROI 以便补充或修正。\n" +
            "�?重新标注并覆盖保存：从空 ROI 开始，最终覆盖现�?zip。\n" +
            "�?跳过此图像：不打开该图像，直接进入下一张。\n" +
            "�?跳过所有已存在 ROI：后续遇到已存在 ROI 将不再提示并直接跳过。\n\n" +
            "请选择处理方式（下拉菜单）�?;

        T_missing_title = "缺失 ROI";
        T_missing_label = "选择";
        T_missing_anno = "现在标注";
        T_missing_skip = "跳过此图像（结果留空�?;
        T_missing_skip_all = "跳过所有缺 ROI 的图像（不再提示�?;
        T_missing_exit = "退出脚�?;
        T_missing_msg =
            "检测到当前图像缺少对应的细�?ROI 文件。\n\n" +
            "图像�?f\n" +
            "期望 ROI�?b%s.zip\n\n" +
            "说明：\n" +
            "�?分析四要素需要细�?ROI。\n" +
            "�?若选择跳过，该图像仍会在结果表中保留一行（数值为空）。\n\n" +
            "请选择处理方式（下拉菜单）�?;

        T_sampling = "采样";
        T_promptAddROI =
            "进度�?i / %n\n" +
            "文件�?f\n\n" +
            "请圈选目标物（建议选择单个典型目标物，避免团块）。\n" +
            "�?如需特征3/4，可�?Freehand/Polygon 圈选较大或不规则区域（细胞�?特征4，细胞外=特征3）。\n" +
            "�?每圈选一�?ROI，按 “T�?添加�?ROI Manager。\n\n" +
            "完成后点�?“OK”。\n" +
            "随后将在“下一步操作”下拉菜单中选择继续、结束或退出�?;

        T_promptAddROI_EX =
            "进度�?i / %n\n" +
            "文件�?f\n\n" +
            "请圈选需要排除的对象/区域。\n" +
            "�?椭圆/矩形：用于学习排除对象（灰度与面积）。\n" +
            "�?Freehand/Polygon：用于学习排除区域（灰度）。\n\n" +
            "每圈选一�?ROI，按 “T�?添加�?ROI Manager。\n" +
            "完成后点�?“OK”。\n" +
            "随后在下拉菜单中选择继续、结束并计算或退出�?;

        T_ddLabel = "选择";
        T_ddNext = "下一�?;
        T_ddStep = "结束抽样";
        T_ddCompute = "结束计算";
        T_ddExit = "退�?;

        T_ddInfo_target =
            "请选择下一步操作（下拉菜单）：\n\n" +
            "�?下一张：继续在下一张图像上抽样。\n" +
            "�?结束目标抽样并进入下一步：停止抽样，并使用现有样本推断默认参数。\n" +
            "�?退出脚本：立即结束脚本（不会执行后续批量分析）。\n\n" +
            "说明：点�?“OK�?确认选择�?;

        T_ddInfo_excl =
            "请选择下一步操作（下拉菜单）：\n\n" +
            "�?下一张：继续在下一张图像上抽样。\n" +
            "�?结束排除抽样并计算：停止排除抽样并进入参数设置。\n" +
            "�?退出脚本：立即结束脚本（不会执行后续批量分析）。\n\n" +
            "说明：点�?“OK�?确认选择�?;

        T_param = "分析参数";
        T_param_step1_title = "参数设置�?/2�?;
        T_param_step2_title = "参数设置�?/2�?;
        T_param_note_title = "参数说明";
        T_section_target = "目标�?;
        T_section_feature = "特征识别";
        T_section_bg = "背景处理";
        T_section_roi = "ROI 文件";
        T_section_excl = "排除过滤";
        T_section_format = "数据格式�?;
        T_section_sep = "---- %s ----";

        T_minA = "最小面积（px²�?;
        T_maxA = "最大面积（px²�?;
        T_circ = "最小圆形度�?�?�?;
        T_allow_clumps = "团块估算：按面积拆分计数";
        T_min_phago_enable = "微量吞噬阈值（动态计算）";
        T_pixel_count_enable = "像素计数模式（目标物数量按像素统计，忽略面积/圆度/团块拆分�?;

        T_feat_center_diff = "内外对比阈值（中心-外圈�?;
        T_feat_bg_diff = "与背景接近阈�?;
        T_feat_small_ratio = "小尺寸判定比例（相对典型面积�?;
        T_feat_clump_ratio = "团块最小面积倍数";

        T_strict = "严格程度";
        T_strict_S = "严格";
        T_strict_N = "正常（推荐）";
        T_strict_L = "宽松";

        T_roll = "Rolling Ball 半径";
        T_suffix = "ROI 文件后缀";

        T_excl_enable = "启用排除过滤";
        T_excl_thr = "阈值（0�?55�?;
        T_excl_mode = "排除方向";
        T_excl_high = "排除亮对象（�?阈值）";
        T_excl_low = "排除暗对象（�?阈值）";
        T_excl_strict = "动态阈值（更严格）";

        T_excl_size_gate = "面积范围门控（推荐）";
        T_excl_minA = "最小面积（px²�?;
        T_excl_maxA = "最大面积（px²�?;

        T_data_format_enable = "启用数据格式�?;
        T_data_format_rule = "文件名识别规则（<p>/<f>�?;
        T_data_format_cols = "表格列格�?;
        T_data_opt_enable = "数据优化（IBR/PCR�?;
        T_data_format_doc =
            "【数据格式化 - 代号速查】\n" +
            "A. 文件名规则（仅用于解析，不是列代号）：\n" +
            "  语法：用\"/\"分段�?p>/<f> 为代号；字面量可直接写；空格请写�?\" \"。\n" +
            "  代号�?p>=项目�?| <f>=数字 | f=\"F\"/\"T\" 绑定列。\n" +
            "  子文件夹：folderRule//fileRule。\n" +
            "  默认参考（可抄写）：\n" +
            "    Dolphin�?p>/<f>,f=\"F\"\n" +
            "    Windows Explorer�?p>/\" \"/(/<f>/),f=\"F\"\n" +
            "    macOS Finder�?p>/\" \"/<f>,f=\"F\"\n" +
            "  子文件夹示例�?f>/hr,f=\"T\"//<p>/\" \"/(/<f>/)\n\n" +
            "B. 表格列代号（内置）：\n" +
            "  识别类：PN=项目�?| F=编号 | T=时间\n" +
            "  计数类：TB=总目�?| BIC=细胞内目�?| CWB=含目标细胞\n" +
            "          CWBA=含目标细�?校正) | TC=细胞总数\n" +
            "  比例类：IBR=BIC/TC | PCR=CWB/TC\n" +
            "  单细胞：BPC=每细胞目标数\n" +
            "  均�?标准差：EIBR/ISDP(IBR) | EPCR/PSDP(PCR) | EBPC/BPCSDP(BPC)\n\n" +
            "C. 自定义列：\n" +
            "  - 代号不与内置冲突；参�?name=\"...\" value=\"...\"�?=只出现一次。\n\n" +
            "D. 备注：\n" +
            "  - 若指�?T，结果按 Time 升序；同一时间统计 EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP。\n" +
            "  - 若列�?BPC/EBPC/BPCSDP，则按细胞展开；仅单细胞列随行变化。\n" +
            "  - 像素计数模式下，TB/BIC/BPC/EBPC/BPCSDP 输出像素数量（px）。\n" +
            "  - 参数用逗号分隔，值需英文双引号；不允许空列项。\n";
        T_data_format_err_title = "数据格式�?- 输入错误";
        T_data_format_err_hint = "请修正后重试�?;
        T_log_toggle_on = "启用";
        T_log_toggle_off = "关闭";
        T_log_error = "  �? �?错误�?s";

        T_err_df_rule_empty = "[E101] 文件名识别规则为空。示例：<p>/\" \"/(/<f>/),f=\"F\"";
        T_err_df_rule_slash = "[E102] 文件名识别规则必须包含至少一个�?”分隔符。示例：<p>/\" \"/(/<f>/)";
        T_err_df_rule_parts = "[E103] 文件名识别规则的每一段都必须填写�?;
        T_err_df_rule_tokens = "[E104] 文件名识别规则仅允许 <p> �?<f> 作为代号，其余应为字面量�?;
        T_err_df_rule_need_both = "[E105] 文件名识别规则必须同时包�?<p> �?<f>�?;
        T_err_df_rule_order = "[E106] 文件名识别规则顺序只允许 <p>/<f> �?<f>/<p>�?;
        T_err_df_rule_need_subfolder = "[E107] 子文件夹保持结构模式需要使用“子文件夹规�?/文件名规则”�?;
        T_err_df_rule_no_subfolder = "[E108] 当前模式不允许使用�?/”子文件夹规则�?;
        T_err_df_rule_double_slash = "[E109] 文件名识别规则中�?/”只能出现一次�?;
        T_err_df_rule_param_kv = "[E110] 规则参数必须写成 key=\"value\" 形式�?;
        T_err_df_rule_param_unknown_prefix = "[E111] 未知规则参数�?;
        T_err_df_rule_param_quote = "[E112] 规则参数值必须使用英文双引号包裹�?;
        T_err_df_rule_param_f_value = "[E113] f 只能设置�?\"F\" �?\"T\"�?;
        T_err_df_rule_param_duplicate = "[E114] 规则参数 f 只能设置一次�?;
        T_err_df_cols_empty = "[E121] 表格列格式为空�?;
        T_err_df_cols_empty_item = "[E122] 表格列格式包含空项（可能存在连续�?/”或首尾�?”）�?;
        T_err_df_cols_empty_token = "[E123] 表格列格式中存在空列代号�?;
        T_err_df_cols_params_comma = "[E124] 参数必须使用逗号分隔，示例：X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "[E125] �?”后必须跟列代号�?;
        T_err_df_cols_dollar_builtin = "[E126] �?”只能用于自定义列，不可用于内置列（PN/F/T/TB/BiC/CwB/CwBa/TC/BPC/IBR/PCR/EBPC/BPCSDP/eIBR/ePCR/ISDP/PSDP）�?;
        T_err_df_cols_param_kv = "[E127] 参数必须写成 key=\"value\" 形式�?;
        T_err_df_cols_param_unknown_prefix = "[E128] 未知参数�?;
        T_err_df_cols_param_quote = "[E129] 参数值必须用英文双引号包裹。示例：name=\"Cell with Target Objects\"";
        T_err_df_cols_unknown_token = "[E130] 未知列代号：";
        T_err_df_cols_param_empty_name = "[E131] name 参数不能为空�?;
        T_err_df_cols_param_empty_value = "[E132] value 参数不能为空�?;
        T_err_df_cols_param_duplicate = "[E133] 参数重复�?;
        T_err_df_cols_custom_need_param = "[E134] 自定义列必须包含 name �?value 参数�?;
        T_err_df_cols_dollar_duplicate = "[E135] �?”自定义列只能出现一次�?;
        T_err_df_generic = "[E199] 数据格式化输入无效�?;
        T_err_df_generic_detail = "原因：未能识别输入内容�?;
        T_err_df_field = "请检查：%s";
        T_err_df_fix_101 = "修正：填写有效规则（例：<p>/\" \"/(/<f>/) �?<p>/<f>）�?;
        T_err_df_fix_102 = "修正：使用�?”分段（至少一个）�?;
        T_err_df_fix_103 = "修正：补齐每个�?”之间的内容�?;
        T_err_df_fix_104 = "修正：只�?<p>/<f> 作为代号，其余写成字面量�?;
        T_err_df_fix_105 = "修正：同时包�?<p> �?<f>�?;
        T_err_df_fix_106 = "修正：顺序仅 <p>/<f> �?<f>/<p>�?;
        T_err_df_fix_107 = "修正：按 folderRule//fileRule 格式填写�?;
        T_err_df_fix_108 = "修正：删除�?/”或切换到保持结构模式�?;
        T_err_df_fix_109 = "修正：�?/”只能出现一次�?;
        T_err_df_fix_110 = "修正：参数写�?key=\"value\"�?;
        T_err_df_fix_111 = "修正：仅允许 f 参数�?;
        T_err_df_fix_112 = "修正：值用英文双引号�?;
        T_err_df_fix_113 = "修正：f 只能�?\"F\" �?\"T\"�?;
        T_err_df_fix_114 = "修正：f 只能出现一次�?;
        T_err_df_fix_121 = "修正：至少填写一个列代号�?;
        T_err_df_fix_122 = "修正：移除空项（避免连续�?/”或首尾�?”）�?;
        T_err_df_fix_123 = "修正：补充列代号�?;
        T_err_df_fix_124 = "修正：参数用逗号分隔�?;
        T_err_df_fix_125 = "修正�? 后补列代号�?;
        T_err_df_fix_126 = "修正：内置列不要�?$�?;
        T_err_df_fix_127 = "修正：参数写�?key=\"value\"�?;
        T_err_df_fix_128 = "修正：仅允许 name �?value�?;
        T_err_df_fix_129 = "修正：值用英文双引号�?;
        T_err_df_fix_130 = "修正：使用内置列，或�?$ 自定义列并给 name/value�?;
        T_err_df_fix_131 = "修正：name 不能为空�?;
        T_err_df_fix_132 = "修正：value 不能为空�?;
        T_err_df_fix_133 = "修正：name/value 各只能出现一次�?;
        T_err_df_fix_134 = "修正：自定义列需 name �?value�?;
        T_err_df_fix_135 = "修正�? 自定义列只能一个�?;
        T_err_param_num_title = "参数输入错误";
        T_err_param_num_msg =
            "[E201] 数值输入无效：%s\n\n" +
            "阶段�?stage\n\n" +
            "建议：请输入数字，可包含小数点�?;

        T_beads_type_title = "对象类型确认";
        T_beads_type_msg =
            "请确认图像中是否存在多种目标物或易混淆对象。\n\n" +
            "�?若仅存在单一目标物类型：建议不启用排除过滤。\n" +
            "�?若存在多种目标物或明显干扰对象：建议启用排除过滤，并进行排除对象抽样。\n\n" +
            "说明：即使在此处选择启用排除过滤，你仍可在参数设置窗口中关闭该功能�?;
        T_beads_type_checkbox = "包含多种目标物（启用排除过滤�?;

        T_excl_note_few_samples = "灰度样本不足�?3）。推断阈值不可靠，建议在参数窗口手动设置�?;
        T_excl_note_few_effective = "有效灰度样本不足（可能存在饱和或极端值）。推断阈值不可靠，建议手动设置�?;
        T_excl_note_diff_small = "目标/排除灰度差异过小�?8）。推断阈值不可靠，建议手动设置�?;
        T_excl_note_overlap_high = "灰度分布重叠较大：采用保守阈值（接近排除样本低分位），建议在参数窗口人工确认�?;
        T_excl_note_good_sep_high = "分离良好：阈值由目标高分位与排除低分位共同估计�?;
        T_excl_note_overlap_low = "灰度分布重叠较大：采用保守阈值（接近排除样本高分位），建议在参数窗口人工确认�?;
        T_excl_note_good_sep_low = "分离良好：阈值由目标低分位与排除高分位共同估计�?;

        T_err_need_window =
            "[E001] 脚本在阶�?[%stage] 需要窗口但未找到。\n\n" +
            "窗口�?w\n" +
            "文件�?f\n\n" +
            "建议：关闭同名窗口、避免标题冲突后重试�?;
        T_err_open_fail =
            "[E002] 无法打开图像文件：\n%p\n\n" +
            "阶段�?stage\n" +
            "文件�?f\n\n" +
            "建议：确认文件存在且可在 Fiji 中打开。若文件损坏请替换或重新导出�?;
        T_err_roi_empty_title = "ROI 为空";
        T_err_roi_empty_msg =
            "[E009] 未检测到任何 ROI，无法保�?ROI 文件。\n\n" +
            "阶段�?stage\n" +
            "文件�?f\n\n" +
            "建议：使用绘图工具勾画细胞轮廓，并按 “T�?添加�?ROI Manager�?;
        T_err_roi_save_title = "ROI 保存失败";
        T_err_roi_save_msg =
            "[E010] 无法保存 ROI 文件：\n%p\n\n" +
            "阶段�?stage\n" +
            "文件�?f\n\n" +
            "建议：确认文件夹有写入权限，路径不含特殊字符�?;
        T_err_roi_open_title = "ROI 读取失败";
        T_err_roi_open_msg =
            "[E011] ROI 文件无法读取或不包含有效 ROI：\n%p\n\n" +
            "阶段�?stage\n" +
            "文件�?f\n\n" +
            "建议：确�?ROI zip 未损坏，必要时重新标注并保存�?;
        T_err_too_many_cells = "[E003] 细胞 ROI 数量超过 65535�?;
        T_err_too_many_cells_hint = "当前实现使用 1..65535 写入 16-bit 标签图。建议分批处理或减少 ROI 数量�?;
        T_err_file = "文件�?;
        T_err_roi1_invalid = "[E004] ROI[1] 非法（无有效 bounds）。无法生成细胞标签图�?;
        T_err_labelmask_failed = "[E005] 细胞标签图生成失败：填充后中心像素仍�?0�?;
        T_err_labelmask_hint = "请检�?ROI[1] 是否为闭合面�?ROI，并确保 ROI 与图像区域有效重叠�?;

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "�?开始：巨噬细胞四要素分�?;
        T_log_lang = "  ├─ 语言：中�?;
        T_log_dir = "  ├─ 文件夹：已选择";
        T_log_mode = "  └─ 模式�?s";
        T_log_roi_phase_start = "�?步骤：细�?ROI 标注";
        T_log_roi_phase_done = "�?完成：细�?ROI 标注";
        T_log_sampling_start = "�?步骤：目标物抽样";
        T_log_sampling_cancel = "�?完成：抽样（用户结束抽样�?;
        T_log_sampling_img = "  ├─ 抽样 [%i/%n]�?f";
        T_log_sampling_rois = "  �? └─ ROI 数量�?i";
        T_log_params_calc = "�?完成：默认参数已推断";
        T_log_feature_select = "  ├─ 目标物特征：%s";
        T_log_main_start = "�?开始：批量分析（静默模式）";
        T_log_processing = "  ├─ 处理 [%i/%n]�?f";
        T_log_missing_roi = "  �? �?缺少 ROI�?f";
        T_log_missing_choice = "  �? └─ 选择�?s";
        T_log_load_roi = "  �? ├─ 加载 ROI";
        T_log_roi_count = "  �? �? └─ 细胞数：%i";
        T_log_bead_detect = "  �? ├─ 检测目标物并统�?;
        T_log_bead_count = "  �? �? ├─ 目标物总数�?i";
        T_log_bead_incell = "  �? �? ├─ 细胞内目标物�?i";
        T_log_bead_count_px = "  �? �? ├─ 目标物像素总数�?i";
        T_log_bead_incell_px = "  �? �? ├─ 细胞内目标物像素�?i";
        T_log_cell_withbead = "  �? �? └─ 含目标物细胞�?i";
        T_log_bead_summary_done = "  �? �? └─ 目标物统计完�?;
        T_log_complete = "  �? └─ �?完成";
        T_log_skip_roi = "  �? �?跳过：缺�?ROI";
        T_log_skip_nocell = "  �? �?跳过：ROI 中无有效细胞";
        T_log_results_save = "�?完成：结果已写入 Results �?;
        T_log_opt_done = "�?数据优化完成";
        T_log_opt_time = "�?时间趋势优化完成";
        T_log_all_done = "✓✓�?全部完成 ✓✓�?;
        T_log_summary = "📊 汇总：共处�?%i 张图�?;
        T_log_unit_sync_keep = "  └─ 目标物尺度：使用抽样推断�?= %s";
        T_log_unit_sync_ui = "  └─ 目标物尺度：检测到手动修改，改�?UI 中�?= %s";
        T_log_analyze_header = "  ├─ 解析参数";
        T_log_analyze_img = "  ├─ 图像�?f";
        T_log_analyze_roi = "  �? ├─ ROI�?s";
        T_log_analyze_size = "  �? ├─ 尺寸�?w x %h";
        T_log_analyze_pixel_mode = "  �? ├─ 计数模式：像素计数（忽略面积/圆度/团块拆分�?;
        T_log_analyze_bead_params = "  �? ├─ 目标物参数：area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_features = "  �? ├─ 目标物特征：%s";
        T_log_analyze_feature_params = "  �? ├─ 特征参数：diff=%diff bg=%bg small=%small clump=%clump";
        T_log_analyze_strict = "  �? ├─ 严格度：%strict，融合策略：%policy";
        T_log_analyze_bg = "  �? ├─ 背景扣除：rolling=%r";
        T_log_analyze_excl_on = "  �? ├─ 排除：mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  �? └─ 排除：未启用";
        T_log_analyze_method = "  �? └─ 检测流程：A=Yen+Mask+Watershed；B=Edges+Otsu+Mask+Watershed；融�?%policy";
        T_log_analyze_excl_adjust = "  �? └─ 动态阈值：mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  �? ├─ 细胞标签图：%s";
        T_log_label_mask_ok = "已生�?;
        T_log_label_mask_fail = "生成失败";
        T_log_policy_strict = "严格";
        T_log_policy_union = "并集";
        T_log_policy_loose = "宽松";
        T_log_df_header = "  ├─ 数据格式化：自定义解析明�?;
        T_log_df_rule = "  �? ├─ 规则�?s";
        T_log_df_cols = "  �? ├─ 列格式：%s";
        T_log_df_sort_asc = "  �? ├─ 排序�?s 升序";
        T_log_df_sort_desc = "  �? ├─ 排序�?s 降序";
        T_log_df_item = "  �? └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "未进行目标物抽样：将使用默认目标物尺度与默认 Rolling Ball�?;
        T_reason_target_ok = "已基于目标物抽样推断目标物尺度与 Rolling Ball（稳健估计）�?;
        T_reason_excl_on = "排除过滤已启用：阈值由排除抽样推断（如提示不可靠，请在参数窗口手动调整）�?;
        T_reason_excl_off = "排除过滤未启用�?;
        T_reason_excl_size_ok = "排除对象面积范围：已基于排除样本推断�?;
        T_reason_excl_size_off = "未提供足够的排除对象面积样本：默认关闭面积门控�?;

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
        T_choose = "画像�?ROI ファイルを含むフォルダーを選択してください";
        T_exit = "フォルダーが選択されませんでした。スクリプトを終了します�?;
        T_noImages = "[E008] 選択したフォルダーに画像ファイル（tif/tiff/png/jpg/jpeg）が見つかりません。スクリプトを終了します�?;
        T_exitScript = "ユーザー操作によりスクリプトを終了しました�?;
        T_err_dir_illegal_title = "フォルダーが不正です";
        T_err_dir_illegal_msg =
            "[E006] 選択したフォルダーにファイルとサブフォルダーが混在しています。\n\n" +
            "要件：フォルダーは「ファイルのみ」または「サブフォルダーのみ」です。\n\n" +
            "確認後、スクリプトを終了します�?;
        T_err_subdir_illegal_title = "サブフォルダーが不正です";
        T_err_subdir_illegal_msg =
            "[E007] サブフォルダー内にさらにサブフォルダーがあります: %s\n\n" +
            "このスクリプトは再帰的なサブフォルダーをサポートしません。\n\n" +
            "フォルダー構成を整理して再実行してください�?;
        T_subfolder_title = "サブフォルダーモード";
        T_subfolder_msg =
            "選択したフォルダーにサブフォルダーが含まれています。\n" +
            "サブフォルダーモードで実行します。\n\n" +
            "実行方法を選択してください：";
        T_subfolder_label = "実行方法";
        T_subfolder_keep = "サブフォルダー別に実行（構造維持）";
        T_subfolder_flat = "フラット実行（サブフォルダー名_ファイル名）";

        T_mode_title = "作業モー�?;
        T_mode_label = "モー�?;
        T_mode_1 = "細胞 ROI のみ作成�?_cells.zip を生成）";
        T_mode_2 = "4要素解析のみ（既存の細胞 ROI が必要）";
        T_mode_3 = "細胞 ROI 作成後に 4要素解析（推奨）";
        T_mode_msg =
            "作業モードを選択してください（プルダウン）：\n\n" +
            "1）細�?ROI のみ作成\n" +
            "   �?画像を順に開きます。\n" +
            "   �?細胞輪郭を手動で描画し、ROI Manager に追加します。\n" +
            "   �?完了後、細�?ROI �?zip（既定：画像�?+ “_cells.zip”）として保存します。\n\n" +
            "2�?要素解析のみ\n" +
            "   �?対象物の検出と統計を実行します。\n" +
            "   �?各画像に対応する細胞 ROI（既定：画像�?+ “_cells.zip”）が必須です。\n\n" +
            "3）作成→解析（推奨）\n" +
            "   �?不足している細胞 ROI を先に作成します。\n" +
            "   �?その後、ターゲット対象物サンプリング（必要に応じて除外サンプリング）を行い、最後にバッチ解析を実行します。\n\n" +
            "説明�?“OK�?で確定してください�?;

        T_step_roi_title = "手順 1：細�?ROI 作成";
        T_step_roi_msg =
            "【細�?ROI 作成】を開始します。\n\n" +
            "この手順で行うこと：\n" +
            "1）現在選択している描画ツールで細胞輪郭を描画します（推奨：フリーハンド）。\n" +
            "2）輪郭を 1 つ描いたら、キーボード�?“T�?�?ROI Manager に追加します。\n" +
            "3）この画像の細胞がすべて完了したら、このウィンドウ�?“OK�?を押して次へ進みます。\n\n" +
            "保存：\n" +
            "�?ROI �?zip（画像名 + �?s.zip”）として保存されます。\n\n" +
            "重要：\n" +
            "�?本スクリプトは描画ツールを自動で切り替えません。\n" +
            "�?安定した結果のため、輪郭は閉じた領�?ROI として作成してください�?;

        T_step_bead_title = "手順 2：ターゲット対象物サンプリン�?;
        T_step_bead_msg =
            "【ターゲット対象物サンプリング】を開始します。\n\n" +
            "目的：\n" +
            "�?サンプルから「単体対象物の典型的な面積スケール」と「濃度特性」を推定します。\n" +
            "�?推定値は既定の検出パラメータ、塊（クラスタ）の面積による対象物数推定、背景補正値（Rolling Ball）の提案に利用されます。\n\n" +
            "補足：\n" +
            "�?特徴3/4を使う場合は、フリーハン�?ポリゴンで大きめ・不規則な領域も追加してください（細胞内=特徴4、細胞外=特徴3）。\n\n" +
            "操作：\n" +
            "1）楕円ツールでターゲット対象物をマークします（厳密な精度は不要ですが、可能な範囲でフィットさせてください）。\n" +
            "2）塊ではなく、代表的な単体対象物を優先してマークしてください。\n" +
            "3）ROI �?1 つ追加するたびに “T�?を押して ROI Manager に追加します。\n" +
            "4）この画像のサンプリングが完了したら “OK”。\n" +
            "5）続�?“次の操作�?で、継�?/ 終了して次へ / 終了 を選択します�?;

        T_step_bead_ex_title = "手順 3：除外サンプリング（任意�?;
        T_step_bead_ex_msg =
            "【除外サンプリング】を開始します（複数種類の対象物や紛らわしい干渉物がある場合に使用）。\n\n" +
            "目的：\n" +
            "�?除外対象の濃度閾値（必要に応じて面積範囲）を学習し、誤検出を抑制します。\n\n" +
            "ROI の扱い：\n" +
            "�?楕円/矩形 ROI：除外対象サンプル（濃度＋面積）として扱います。\n" +
            "�?フリーハンド/ポリゴン ROI：除外領域（濃度のみ）として扱います。\n\n" +
            "手順：\n" +
            "1）除外したい対象または領域をマークします。\n" +
            "2）ROI ごと�?“T�?を押して ROI Manager に追加します。\n" +
            "3）完了後 “OK”。\n" +
            "4）続くプルダウンで継�?/ 終了して計算 / 終了 を選択します�?;

        T_feat_title = "対象物特徴の選択";
        T_feat_msg =
            "【対象物特徴の選択】を行います。\n\n" +
            "目的：\n" +
            "�?本解析で検出する対象物の外観特徴を指定します。\n\n" +
            "説明：\n" +
            "�?選択した特徴のみを検出し、同一対象は重複計数しません。\n" +
            "�?特徴4は細胞内のみ判定します（細胞 ROI と重なる領域）。\n" +
            "�?特徴1と特�?は同時に選択できません。\n\n" +
            "�?選択内容に応じて、後続の閾値パラメータが表示されます。\n\n" +
            "手順：\n" +
            "1）表示される参考画像を見て、必要な特徴を選択します。\n" +
            "2）“OK�?でパラメータ設定へ進みます�?;
        T_feat_ref_title = "対象物特徴参考図（番号対応）";
        T_feat_ref_fail_title = "参考図を開けません";
        T_feat_ref_fail_msg =
            "[E020] 対象物特徴の参考図を開けない、または読み込みに時間がかかりすぎています。\n\n" +
            "GitHub リポジトリの説明ページで参考図を確認してください：\n\n" +
            "ネットワーク制限や読み込み失敗の場合は、以下のURLをブラウザで開いてください�?;
        T_feat_ref_fail_label = "リポジトリURL（コピー用）";
        T_feat_1 = "1）中心が明るく外周が暗い円形対象（反射型�?;
        T_feat_2 = "2）中間濃度で円形、内外差が小さい対象";
        T_feat_3 = "3）複数対象の凝集による暗い塊（面積で数を推定�?;
        T_feat_4 = "4）細胞内の高密度・斑状領域（細胞内のみ、面積推定）";
        T_feat_5 = "5）中心が暗く外周が明るい円形対象（反差型�?;
        T_feat_6 = "6）低コントラストで小さめの円形対象（細胞に近い濃度）";
        T_feat_err_title = "特徴選択エラ�?;
        T_feat_err_conflict = "[E012] 特徴1と特�?は同時に選択できません。調整して再試行してください�?;
        T_feat_err_none = "[E013] 特徴が未選択です。少なくとも1つ選択してください�?;

        T_result_next_title = "結果出力完了";
        T_result_next_msg =
            "Results 表が作成されました。\n\n" +
            "説明：\n" +
            "1）下のチェックを入れて“OK”でパラメータ設定に戻って再解析します。\n" +
            "2）チェックなしで“OK”を押すと終了します�?;
        T_result_next_checkbox = "パラメータ設定に戻って再解析する";

        T_step_param_title = "手順 4：パラメータ確認";
        T_step_param_msg =
            "【パラメータ設定】ウィンドウを開きます。\n\n" +
            "表示内容：\n" +
            "�?ターゲット対象物サンプルから推定した面積範囲、対象物スケール（塊推定用）、Rolling Ball の提案値。\n" +
            "�?選択した特徴に応じて表示される閾値パラメータ（内外コントラスト、背景近接、小さめ比率、塊の最小倍率）。\n" +
            "�?除外フィルターを有効にした場合、濃度閾値と（任意の）面積ゲート範囲。\n\n" +
            "説明：\n" +
            "�?パラメータ設定は2つのウィンドウに分かれて順番に表示されます。\n\n" +
            "推奨：\n" +
            "�?初回は既定値で一度バッチ解析を実行し、結果に応じて調整してください。\n\n" +
            "説明�?“OK�?で確定し、バッチ解析へ進みます�?;

        T_step_main_title = "バッチ解析の開始";
        T_step_main_msg =
            "【バッチ解析】を開始します。\n\n" +
            "実行内容：\n" +
            "�?細胞 ROI の読み込み\n" +
            "�?対象物の検出と統計（塊推定、任意の除外フィルターを含む）\n" +
            "�?Results 表への集計出力\n\n" +
            "実行方式：\n" +
            "�?中間ウィンドウを抑制するため、サイレントモードで実行します。\n\n" +
            "細胞 ROI が不足している場合：\n" +
            "�?作成 / スキップ / すべてスキッ�?/ 終了 を選択できます。\n" +
            "�?スキップした画像�?Results に行を残します（値は空）。\n\n" +
            "説明�?“OK�?で開始します�?;

        T_cell_title = "細胞 ROI 作成";
        T_cell_msg =
            "進捗�?i / %n\n" +
            "ファイル�?f\n\n" +
            "細胞輪郭を作成してください：\n" +
            "1）輪郭を描画します。\n" +
            "2）“T�?�?ROI Manager に追加します。\n" +
            "3）この画像の細胞がすべて完了するまで繰り返します。\n\n" +
            "完了�?“OK�?で保存して次へ進みます。\n\n" +
            "保存：画像名 + �?s.zip�?;

        T_exist_title = "既存の細�?ROI を検出しまし�?;
        T_exist_label = "操作";
        T_exist_edit = "読み込みして編集（推奨）";
        T_exist_redraw = "再作成して上書き保存";
        T_exist_skip = "この画像をスキップ（既存 ROI を保持）";
        T_exist_skip_all = "既存 ROI の画像をすべてスキッ�?;
        T_exist_msg =
            "この画像には既存の細�?ROI が存在します。\n\n" +
            "進捗�?i / %n\n" +
            "画像�?f\n" +
            "ROI�?b%s.zip\n\n" +
            "選択肢：\n" +
            "�?読み込みして編集：既�?ROI を開き、追記または修正します。\n" +
            "�?再作成して上書き：新規に作成し、既�?zip を上書きします。\n" +
            "�?スキップ：画像を開かずに次へ進みます。\n" +
            "�?すべてスキップ：以後、既�?ROI に対して確認を表示せずスキップします。\n\n" +
            "操作を選択してください（プルダウン）：";

        T_missing_title = "細胞 ROI が不足しています";
        T_missing_label = "操作";
        T_missing_anno = "今ここで細胞 ROI を作成し、解析を継続する";
        T_missing_skip = "この画像をスキップ（結果は空�?;
        T_missing_skip_all = "不足 ROI の画像をすべてスキップ（以後表示しない）";
        T_missing_exit = "スクリプトを終了";
        T_missing_msg =
            "この画像に対応する細�?ROI ファイルが見つかりません。\n\n" +
            "画像�?f\n" +
            "想定 ROI�?b%s.zip\n\n" +
            "説明：\n" +
            "�?4要素解析には細胞 ROI が必要です。\n" +
            "�?スキップして�?Results 表に行は残ります（値は空）。\n\n" +
            "操作を選択してください（プルダウン）：";

        T_sampling = "サンプリング";
        T_promptAddROI =
            "進捗�?i / %n\n" +
            "ファイル�?f\n\n" +
            "ターゲット対象物をマークしてください（代表的な単体対象物を推奨。塊は避けてください）。\n" +
            "�?特徴3/4が必要な場合は、フリーハン�?ポリゴンで大きめ・不規則な領域も追加します（細胞�?特徴4、細胞外=特徴3）。\n" +
            "�?ROI を追加するたびに “T�?を押してください。\n\n" +
            "完了�?“OK”。\n" +
            "続く “次の操作�?で継続・終了・終了を選択します�?;

        T_promptAddROI_EX =
            "進捗�?i / %n\n" +
            "ファイル�?f\n\n" +
            "除外対象をマークしてください。\n" +
            "�?楕円/矩形：除外対象（濃度＋面積）\n" +
            "�?フリーハンド/ポリゴン：除外領域（濃度）\n\n" +
            "ROI ごと�?“T�?を押して追加します。\n" +
            "完了�?“OK”。\n" +
            "続くプルダウンで継続・計算・終了を選択します�?;

        T_ddLabel = "次の操作";
        T_ddNext = "次の画像（サンプリング継続）";
        T_ddStep = "ターゲット抽出を終了して次へ（既定値を推定�?;
        T_ddCompute = "除外抽出を終了して計算（パラメータ設定へ�?;
        T_ddExit = "スクリプト終�?;

        T_ddInfo_target =
            "次の操作を選択してください（プルダウン）：\n\n" +
            "�?次の画像：次の画像でサンプリングを続けます。\n" +
            "�?ターゲット抽出を終了して次へ：サンプリングを停止し、既存サンプルから既定値を推定します。\n" +
            "�?スクリプト終了：ただちに終了します（以降のバッチ解析は実行されません）。\n\n" +
            "説明�?“OK�?で確定します�?;

        T_ddInfo_excl =
            "次の操作を選択してください（プルダウン）：\n\n" +
            "�?次の画像：次の画像でサンプリングを続けます。\n" +
            "�?除外抽出を終了して計算：除外サンプリングを停止し、パラメータ設定へ進みます。\n" +
            "�?スクリプト終了：ただちに終了します。\n\n" +
            "説明�?“OK�?で確定します�?;

        T_param = "パラメータ設�?;
        T_param_step1_title = "パラメータ設定（1/2�?;
        T_param_step2_title = "パラメータ設定（2/2�?;
        T_param_note_title = "既定値の根拠と説�?;
        T_section_target = "ターゲット対象物";
        T_section_feature = "特徴判定";
        T_section_bg = "背景処理";
        T_section_roi = "細胞 ROI";
        T_section_excl = "除外フィルター（任意�?;
        T_section_format = "データ整�?;
        T_section_sep = "---- %s ----";

        T_minA = "ターゲット対象物 最小面積（px^2�?;
        T_maxA = "ターゲット対象物 最大面積（px^2�?;
        T_circ = "ターゲット対象物 最小円形度�?�?�?;
        T_allow_clumps = "塊を面積で分割して対象物数を推定する";
        T_min_phago_enable = "微量貪食は未貪食として扱う（動的しきい値、既定で有効�?;
        T_pixel_count_enable = "ピクセル計数モード（対象物量はピクセル数、面�?円形�?塊分割を無視�?;

        T_feat_center_diff = "内外コントラスト閾値（中心-外周�?;
        T_feat_bg_diff = "背景との近さ判定閾�?;
        T_feat_small_ratio = "小さめ判定の面積比率（代表値比�?;
        T_feat_clump_ratio = "塊の最小面積倍率";

        T_strict = "検出の厳しさ";
        T_strict_S = "厳格（誤検出を抑制）";
        T_strict_N = "標準（推奨）";
        T_strict_L = "緩い（見落としを減らす）";

        T_roll = "背景補正 Rolling Ball 半径";
        T_suffix = "細胞 ROI ファイル接尾辞（拡張子なし）";

        T_excl_enable = "除外フィルターを有効化（濃度閾値）";
        T_excl_thr = "除外閾値（0�?55�?;
        T_excl_mode = "除外方向";
        T_excl_high = "明るい対象を除外（濃�?�?閾値）";
        T_excl_low = "暗い対象を除外（濃度 �?閾値）";
        T_excl_strict = "除外を強化（動的しきい値、より厳格）";

        T_excl_size_gate = "除外対象の面積範囲内のみ閾値除外を適用（推奨）";
        T_excl_minA = "除外対象 最小面積（px^2�?;
        T_excl_maxA = "除外対象 最大面積（px^2�?;

        T_data_format_enable = "データ整形を有効にす�?;
        T_data_format_rule = "ファイル名ルール�?p>/<f>�?;
        T_data_format_cols = "表の列フォーマッ�?;
        T_data_opt_enable = "データ最適化（IBR/PCR�?;
        T_data_format_doc =
            "【データ整形 - コード早見】\n" +
            "A. ファイル名ルール（解析用。列コードではありません）：\n" +
            "  形式：\"/\" で分割；<p>/<f> はトークン；リテラルはそのまま、空白は \" \" を使用。\n" +
            "  記号�?p>=プロジェクト�?| <f>=数�?| f=\"F\"/\"T\" を列に割当。\n" +
            "  サブフォルダー：folderRule//fileRule。\n" +
            "  既定の参考（コピー用）：\n" +
            "    Dolphin�?p>/<f>,f=\"F\"\n" +
            "    Windows Explorer�?p>/\" \"/(/<f>/),f=\"F\"\n" +
            "    macOS Finder�?p>/\" \"/<f>,f=\"F\"\n" +
            "  サブフォルダー例�?f>/hr,f=\"T\"//<p>/\" \"/(/<f>/)\n\n" +
            "B. 表の列コード（内蔵）：\n" +
            "  識別：PN=プロジェクト | F=番号 | T=時間\n" +
            "  数量：TB=総対�?| BIC=細胞内対�?| CWB=対象保有細胞\n" +
            "        CWBA=対象保有細胞(補正) | TC=細胞総数\n" +
            "  比率：IBR=BIC/TC | PCR=CWB/TC\n" +
            "  単細胞：BPC=細胞あたり対象数\n" +
            "  平均/標準偏差：EIBR/ISDP(IBR) | EPCR/PSDP(PCR) | EBPC/BPCSDP(BPC)\n\n" +
            "C. カスタム列：\n" +
            "  - 内蔵と重複不可；パラメー�?name=\"...\" value=\"...\"�?=1回のみ。\n\n" +
            "D. 注記：\n" +
            "  - T 指定時は Time 昇順、EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP は同時間で集計。\n" +
            "  - BPC/EBPC/BPCSDP を含む場合は細胞ごとに 1 行（単細胞関連の列のみ変化）。\n" +
            "  - ピクセル計数モードで�?TB/BIC/BPC/EBPC/BPCSDP はピクセル数（px）。\n" +
            "  - パラメータはカンマ区切り、値は英語の二重引用符。空列は禁止。\n";
        T_data_format_err_title = "データ整�?- 入力エラ�?;
        T_data_format_err_hint = "修正して再試行してください�?;
        T_log_toggle_on = "有効";
        T_log_toggle_off = "無効";
        T_log_error = "  �? �?エラー：%s";

        T_err_df_rule_empty = "[E101] ファイル名ルールが空です。例�?p>/\" \"/(/<f>/),f=\"F\"";
        T_err_df_rule_slash = "[E102] ファイル名ルールは�?”区切り�?つ以上含めてください。例�?p>/\" \"/(/<f>/)";
        T_err_df_rule_parts = "[E103] ファイル名ルールの各要素を入力してください�?;
        T_err_df_rule_tokens = "[E104] ファイル名ルールのトークンは <p> �?<f> のみです。他はリテラルとして記述してください�?;
        T_err_df_rule_need_both = "[E105] ファイル名ルールには <p> �?<f> の両方が必要です�?;
        T_err_df_rule_order = "[E106] ファイル名ルールの順序は <p>/<f> また�?<f>/<p> のみです�?;
        T_err_df_rule_need_subfolder = "[E107] サブフォルダー構造維持モードでは「サブフォルダールール//ファイル名ルール」が必要です�?;
        T_err_df_rule_no_subfolder = "[E108] 現在のモードでは �?/�?サブフォルダールールは使用できません�?;
        T_err_df_rule_double_slash = "[E109] �?/�?�?回のみ使用できます�?;
        T_err_df_rule_param_kv = "[E110] ルールパラメータ�?key=\"value\" 形式で指定してください�?;
        T_err_df_rule_param_unknown_prefix = "[E111] 不明なルールパラメータ：";
        T_err_df_rule_param_quote = "[E112] ルールパラメータ値は英語の二重引用符で囲んでください�?;
        T_err_df_rule_param_f_value = "[E113] f �?\"F\" また�?\"T\" のみ指定可能です�?;
        T_err_df_rule_param_duplicate = "[E114] ルールパラメータ f �?回のみ指定できます�?;
        T_err_df_cols_empty = "[E121] 列フォーマットが空です�?;
        T_err_df_cols_empty_item = "[E122] 列フォーマットに空項目があります（�?/”や先頭/末尾�?”の可能性）�?;
        T_err_df_cols_empty_token = "[E123] 列フォーマットに空の列コードがあります�?;
        T_err_df_cols_params_comma = "[E124] パラメータはカンマ区切りで指定してください。例：X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "[E125] �?”の後には列コードが必要です�?;
        T_err_df_cols_dollar_builtin =
            "[E126] �?”はカスタム列のみ使用できます（" +
            "PN/F/T/TB/BiC/CwB/CwBa/TC/BPC/IBR/PCR/EBPC/BPCSDP/eIBR/ePCR/ISDP/PSDP は不可）�?;
        T_err_df_cols_param_kv = "[E127] パラメータは key=\"value\" 形式で指定してください�?;
        T_err_df_cols_param_unknown_prefix = "[E128] 不明なパラメータ�?;
        T_err_df_cols_param_quote = "[E129] 値は英語の二重引用符で囲んでください。例：name=\"Cell with Target Objects\"";
        T_err_df_cols_unknown_token = "[E130] 不明な列コード：";
        T_err_df_cols_param_empty_name = "[E131] name パラメータは空にできません�?;
        T_err_df_cols_param_empty_value = "[E132] value パラメータは空にできません�?;
        T_err_df_cols_param_duplicate = "[E133] パラメータが重複しています：";
        T_err_df_cols_custom_need_param = "[E134] カスタム列に�?name また�?value パラメータが必要です�?;
        T_err_df_cols_dollar_duplicate = "[E135] �?”カスタム列�?回のみ指定できます�?;
        T_err_df_generic = "[E199] データ整形の入力が無効です�?;
        T_err_df_generic_detail = "理由：入力内容を識別できません�?;
        T_err_df_field = "確認先：%s";
        T_err_df_fix_101 = "修正：有効なルールを入力してください（例�?p>/\" \"/(/<f>/) また�?<p>/<f>）�?;
        T_err_df_fix_102 = "修正：�?”で分割してください�?つ以上）�?;
        T_err_df_fix_103 = "修正：�?”の間の内容を補完してください�?;
        T_err_df_fix_104 = "修正�?p>/<f> のみをトークンとして使用し、他はリテラルで記述してください�?;
        T_err_df_fix_105 = "修正�?p> �?<f> の両方を含めてください�?;
        T_err_df_fix_106 = "修正：順序は <p>/<f> また�?<f>/<p> です�?;
        T_err_df_fix_107 = "修正：folderRule//fileRule 形式で入力してください�?;
        T_err_df_fix_108 = "修正：�?/”を削除、または構造維持モードに切り替えてください�?;
        T_err_df_fix_109 = "修正：�?/”は1回のみです�?;
        T_err_df_fix_110 = "修正：パラメータ�?key=\"value\" 形式です�?;
        T_err_df_fix_111 = "修正：使用できるパラメータは f のみです�?;
        T_err_df_fix_112 = "修正：値は英語の二重引用符で囲んでください�?;
        T_err_df_fix_113 = "修正：f �?\"F\" また�?\"T\" のみです�?;
        T_err_df_fix_114 = "修正：f �?回のみ指定できます�?;
        T_err_df_fix_121 = "修正：列コードを1つ以上入力してください�?;
        T_err_df_fix_122 = "修正：空項目を削除してください（�?/”や先頭/末尾�?”に注意）�?;
        T_err_df_fix_123 = "修正：列コードを補ってください�?;
        T_err_df_fix_124 = "修正：パラメータはカンマ区切りです�?;
        T_err_df_fix_125 = "修正�? の後に列コードを入れてください�?;
        T_err_df_fix_126 = "修正：内蔵列には $ を付けないでください�?;
        T_err_df_fix_127 = "修正：パラメータ�?key=\"value\" 形式です�?;
        T_err_df_fix_128 = "修正：name また�?value のみ使用してください�?;
        T_err_df_fix_129 = "修正：値は英語の二重引用符で囲んでください�?;
        T_err_df_fix_130 = "修正：内蔵列を使うか�? でカスタム列を作成し�?name/value を指定してください�?;
        T_err_df_fix_131 = "修正：name は空にできません�?;
        T_err_df_fix_132 = "修正：value は空にできません�?;
        T_err_df_fix_133 = "修正：name/value は各1回のみです�?;
        T_err_df_fix_134 = "修正：カスタム列�?name また�?value が必要です�?;
        T_err_df_fix_135 = "修正�? カスタム列は1つのみです�?;
        T_err_param_num_title = "パラメータ入力エラー";
        T_err_param_num_msg =
            "[E201] 数値入力が無効です�?s\n\n" +
            "段階�?stage\n\n" +
            "対処：数値（小数可）を入力してください�?;

        T_beads_type_title = "対象タイプの確認";
        T_beads_type_msg =
            "画像に複数種類の対象物または混同しやすい対象が含まれるか確認してください。\n\n" +
            "�?単一タイプの場合：除外フィルターは通常不要です。\n" +
            "�?複数タイ�?干渉物がある場合：除外フィルターを有効にし、除外サンプリングを推奨します。\n\n" +
            "説明：ここで有効にしても、後のパラメータ設定で無効化できます�?;
        T_beads_type_checkbox = "複数種類が存在する（除外フィルターを有効化）";

        T_excl_note_few_samples = "濃度サンプルが不足しています�?3）。推定は信頼できません。手動設定を推奨します�?;
        T_excl_note_few_effective = "有効な濃度サンプルが不足しています（飽和などの可能性）。手動設定を推奨します�?;
        T_excl_note_diff_small = "ターゲットと除外の濃度差が小さすぎます（<8）。手動設定を推奨します�?;
        T_excl_note_overlap_high = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の低分位に近い）。確認を推奨します�?;
        T_excl_note_good_sep_high = "分離が良好です。ターゲット高分位と除外低分位から閾値を推定しました�?;
        T_excl_note_overlap_low = "分布の重なりが大きいため、保守的な閾値を採用しました（除外側の高分位に近い）。確認を推奨します�?;
        T_excl_note_good_sep_low = "分離が良好です。ターゲット低分位と除外高分位から閾値を推定しました�?;

        T_err_need_window =
            "[E001] ステージ [%stage] で必要なウィンドウが見つかりません。\n\n" +
            "ウィンドウ：%w\n" +
            "ファイル�?f\n\n" +
            "対処：同名ウィンドウを閉じ、タイトル衝突を避けて再試行してください�?;
        T_err_open_fail =
            "[E002] 画像ファイルを開けません：\n%p\n\n" +
            "段階�?stage\n" +
            "ファイル�?f\n\n" +
            "対処：ファイルが存在し、Fijiで開けることを確認してください。破損している場合は置き換えるか再出力してください�?;
        T_err_roi_empty_title = "ROI が空です";
        T_err_roi_empty_msg =
            "[E009] ROI が見つからないため、ROI ファイルを保存できません。\n\n" +
            "段階�?stage\n" +
            "ファイル�?f\n\n" +
            "対処：描画ツールで細胞輪郭を描き、“T�?�?ROI Manager に追加してください�?;
        T_err_roi_save_title = "ROI の保存に失敗しました";
        T_err_roi_save_msg =
            "[E010] ROI ファイルを保存できません：\n%p\n\n" +
            "段階�?stage\n" +
            "ファイル�?f\n\n" +
            "対処：書き込み権限とパス文字を確認してください�?;
        T_err_roi_open_title = "ROI の読み込みに失敗しました";
        T_err_roi_open_msg =
            "[E011] ROI ファイルを読み込めないか、有効な ROI が含まれていません：\n%p\n\n" +
            "段階�?stage\n" +
            "ファイル�?f\n\n" +
            "対処：ROI zip の破損を確認し、必要なら再標注して保存してください�?;
        T_err_too_many_cells = "[E003] 細胞 ROI 数が 65535 を超えています：";
        T_err_too_many_cells_hint = "現在の実装で�?1..65535 �?16-bit ラベル値として使用します。分割処理または ROI 数の削減を推奨します�?;
        T_err_file = "ファイル�?;
        T_err_roi1_invalid = "[E004] ROI[1] が不正です（有効�?bounds がありません）。ラベル画像を生成できません�?;
        T_err_labelmask_failed = "[E005] 細胞ラベル画像の生成に失敗しました。塗りつぶし後の中心画素�?0 のままです�?;
        T_err_labelmask_hint = "ROI[1] が閉じた面積 ROI であり、画像と有効に重なっているか確認してください�?;

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "�?開始：マクロファージ 4要素解析";
        T_log_lang = "  ├─ 言語：日本�?;
        T_log_dir = "  ├─ フォルダー：選択済み";
        T_log_mode = "  └─ モード：%s";
        T_log_roi_phase_start = "�?手順：細�?ROI 作成";
        T_log_roi_phase_done = "�?完了：細�?ROI 作成";
        T_log_sampling_start = "�?手順：ターゲット対象物サンプリン�?;
        T_log_sampling_cancel = "�?完了：サンプリング（ユーザー終了�?;
        T_log_sampling_img = "  ├─ サンプル [%i/%n]�?f";
        T_log_sampling_rois = "  �? └─ ROI 数：%i";
        T_log_params_calc = "�?完了：既定パラメータを推定しまし�?;
        T_log_feature_select = "  ├─ 対象物特徴：%s";
        T_log_main_start = "�?開始：バッチ解析（サイレント�?;
        T_log_processing = "  ├─ 処理 [%i/%n]�?f";
        T_log_missing_roi = "  �? �?ROI 不足�?f";
        T_log_missing_choice = "  �? └─ 選択�?s";
        T_log_load_roi = "  �? ├─ ROI を読み込�?;
        T_log_roi_count = "  �? �? └─ 細胞数：%i";
        T_log_bead_detect = "  �? ├─ 対象物を検出して集計";
        T_log_bead_count = "  �? �? ├─ 対象�?合計�?i";
        T_log_bead_incell = "  �? �? ├─ 細胞�?対象物：%i";
        T_log_bead_count_px = "  �? �? ├─ 対象�?ピクセル数：%i";
        T_log_bead_incell_px = "  �? �? ├─ 細胞�?対象物ピクセル数�?i";
        T_log_cell_withbead = "  �? �? └─ 対象物を含む細胞�?i";
        T_log_bead_summary_done = "  �? �? └─ 対象�?集計完了";
        T_log_complete = "  �? └─ �?完了";
        T_log_skip_roi = "  �? �?スキップ：ROI 不足";
        T_log_skip_nocell = "  �? �?スキップ：ROI に有効な細胞がありません";
        T_log_results_save = "�?完了：Results 表に出力しました";
        T_log_opt_done = "�?データ最適化完了";
        T_log_opt_time = "�?時間トレンド最適化完了";
        T_log_all_done = "✓✓�?完了 ✓✓�?;
        T_log_summary = "📊 サマリー：合�?%i 枚を処理";
        T_log_unit_sync_keep = "  └─ 対象物スケール：サンプル推定値を使用 = %s";
        T_log_unit_sync_ui = "  └─ 対象物スケール：手動変更を検出。UI 中値を使用 = %s";
        T_log_analyze_header = "  ├─ 解析パラメー�?;
        T_log_analyze_img = "  ├─ 画像�?f";
        T_log_analyze_roi = "  �? ├─ ROI�?s";
        T_log_analyze_size = "  �? ├─ サイズ：%w x %h";
        T_log_analyze_pixel_mode = "  �? ├─ 計数モード：ピクセル計数（面�?円形�?塊分割は無視�?;
        T_log_analyze_bead_params = "  �? ├─ 対象物パラメータ：area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_features = "  �? ├─ 対象物特徴：%s";
        T_log_analyze_feature_params = "  �? ├─ 特徴パラメータ：diff=%diff bg=%bg small=%small clump=%clump";
        T_log_analyze_strict = "  �? ├─ 厳密度：%strict，統合ポリシー：%policy";
        T_log_analyze_bg = "  �? ├─ 背景補正：rolling=%r";
        T_log_analyze_excl_on = "  �? ├─ 除外：mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  �? └─ 除外：無�?;
        T_log_analyze_method = "  �? └─ 検出手順：A=Yen+Mask+Watershed；B=Edges+Otsu+Mask+Watershed；統�?%policy";
        T_log_analyze_excl_adjust = "  �? └─ 動的閾値：mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  �? ├─ 細胞ラベル画像：%s";
        T_log_label_mask_ok = "生成済み";
        T_log_label_mask_fail = "生成失敗";
        T_log_policy_strict = "厳格";
        T_log_policy_union = "統合";
        T_log_policy_loose = "緩い";
        T_log_df_header = "  ├─ データ整形：カスタム解析の詳�?;
        T_log_df_rule = "  �? ├─ ルール：%s";
        T_log_df_cols = "  �? ├─ 列フォーマット：%s";
        T_log_df_sort_asc = "  �? ├─ ソート：%s 昇順";
        T_log_df_sort_desc = "  �? ├─ ソート：%s 降順";
        T_log_df_item = "  �? └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "ターゲット対象物のサンプリングなし：既定の対象物スケール�?Rolling Ball を使用します�?;
        T_reason_target_ok = "ターゲット対象物サンプルから対象物スケールと Rolling Ball を推定しました（ロバスト推定）�?;
        T_reason_excl_on = "除外フィルター有効：除外サンプルから閾値を推定しました（不確実な場合は手動で調整してください）�?;
        T_reason_excl_off = "除外フィルター無効�?;
        T_reason_excl_size_ok = "除外対象の面積範囲：除外サンプルから推定しました�?;
        T_reason_excl_size_off = "除外対象の面積サンプルが不足：面積ゲートは無効（既定）です�?;

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
        T_noImages = "[E008] No image files were found in the selected folder (tif/tiff/png/jpg/jpeg). The script has ended.";
        T_exitScript = "The script was exited by user selection.";
        T_err_dir_illegal_title = "Invalid folder";
        T_err_dir_illegal_msg =
            "[E006] The selected folder contains both files and subfolders.\n\n" +
            "Requirement: the folder must contain either files only or subfolders only.\n\n" +
            "Click OK to exit the script.";
        T_err_subdir_illegal_title = "Invalid subfolder";
        T_err_subdir_illegal_msg =
            "[E007] A subfolder contains another subfolder: %s\n\n" +
            "Recursive subfolders are not supported by this script.\n\n" +
            "Please fix the folder structure and retry.";
        T_subfolder_title = "Subfolder mode";
        T_subfolder_msg =
            "Subfolders were detected in the selected folder.\n" +
            "The script will run in subfolder mode.\n\n" +
            "Choose how to run:";
        T_subfolder_label = "Run mode";
        T_subfolder_keep = "Keep subfolder structure";
        T_subfolder_flat = "Flatten (subfolder_name_filename)";

        T_mode_title = "Work Mode";
        T_mode_label = "Mode";
        T_mode_1 = "Annotate cell ROIs only (create *_cells.zip)";
        T_mode_2 = "Analyze only (requires existing cell ROIs)";
        T_mode_3 = "Annotate cell ROIs, then analyze (recommended)";
        T_mode_msg =
            "Select a work mode (dropdown):\n\n" +
            "1) Annotate cell ROIs only\n" +
            "   �?Images will be opened one by one.\n" +
            "   �?You will draw cell outlines and add them to ROI Manager.\n" +
            "   �?The script will save cell ROIs as a zip file (default: image name + “_cells.zip�?.\n\n" +
            "2) Analyze only\n" +
            "   �?Runs target object detection and statistics directly.\n" +
            "   �?A corresponding cell ROI zip must exist for each image (default: image name + “_cells.zip�?.\n\n" +
            "3) Annotate then analyze (recommended)\n" +
            "   �?Creates missing cell ROIs first.\n" +
            "   �?Then performs target object sampling (and optional exclusion sampling), followed by batch analysis.\n\n" +
            "Note: Click “OK�?to confirm your selection.";

        T_step_roi_title = "Step 1: Cell ROI annotation";
        T_step_roi_msg =
            "You are about to enter the Cell ROI annotation phase.\n\n" +
            "During this step:\n" +
            "1) Use your currently selected drawing tool to outline each cell (freehand is recommended).\n" +
            "2) After completing an outline, press “T�?to add it to ROI Manager.\n" +
            "3) When the current image is complete, click “OK�?to proceed to the next image.\n\n" +
            "Save rule:\n" +
            "�?ROIs are saved as: image name + �?s.zip�?\n\n" +
            "Important:\n" +
            "�?This script does not switch tools automatically and does not infer cell boundaries.\n" +
            "�?For stable results, ensure outlines form closed area ROIs covering the full cell region.";

        T_step_bead_title = "Step 2: Target object sampling";
        T_step_bead_msg =
            "You are about to enter the Target object sampling phase.\n\n" +
            "Purpose:\n" +
            "�?Uses your samples to infer a typical single-object area scale and intensity characteristics.\n" +
            "�?These estimates are used to propose default detection parameters, " +
            "estimate object counts from clumps, and suggest a Rolling Ball radius.\n\n" +
            "Supplement:\n" +
            "�?If you plan to use Features 3/4, add larger or irregular regions with Freehand/Polygon " +
            "(in-cell=Feature 4, non-cell=Feature 3).\n\n" +
            "Instructions:\n" +
            "1) Use the Oval Tool to mark target objects (high precision is not required, but keep it reasonably tight).\n" +
            "2) Prefer typical single objects; avoid obvious clumps to improve inference reliability.\n" +
            "3) After each ROI, press “T�?to add it to ROI Manager.\n" +
            "4) When done with this image, click “OK�?\n" +
            "5) A “Next action�?dropdown will then appear to continue sampling, finish and proceed, or exit.";

        T_step_bead_ex_title = "Step 3: Exclusion sampling (optional)";
        T_step_bead_ex_msg =
            "You are about to enter the Exclusion sampling phase " +
            "(recommended when multiple object types or confounding objects are present).\n\n" +
            "Purpose:\n" +
            "�?Learns an exclusion intensity threshold (and optional size range) to reduce false positives.\n\n" +
            "ROI conventions:\n" +
            "�?Oval/Rectangle ROIs: treated as exclusion object samples (learn intensity and size).\n" +
            "�?Freehand/Polygon ROIs: treated as exclusion regions (learn intensity only).\n\n" +
            "Instructions:\n" +
            "1) Mark objects or regions to be excluded.\n" +
            "2) Press “T�?to add each ROI to ROI Manager.\n" +
            "3) Click “OK�?when finished.\n" +
            "4) Use the dropdown to continue, finish & compute, or exit.";

        T_feat_title = "Target Object Feature Selection";
        T_feat_msg =
            "You are about to select target object features.\n\n" +
            "Purpose:\n" +
            "�?Specify the appearance features to detect in this run.\n\n" +
            "Notes:\n" +
            "�?Only selected features are used; each object is counted once.\n" +
            "�?Feature 4 is in-cell only (overlaps cell ROI).\n" +
            "�?Feature 1 and Feature 5 are mutually exclusive.\n" +
            "�?Your selection controls which feature-threshold parameters appear next.\n\n" +
            "Steps:\n" +
            "1) Refer to the reference image and select the required features.\n" +
            "2) Click “OK�?to continue to parameter settings.";
        T_feat_ref_title = "Target Feature Reference (Numbered)";
        T_feat_ref_fail_title = "Reference Image Unavailable";
        T_feat_ref_fail_msg =
            "[E020] The feature reference image could not be opened or is taking too long to load.\n\n" +
            "Please check the reference image in the GitHub repository documentation:\n\n" +
            "If network access is restricted or loading fails, open the URL below in a browser.";
        T_feat_ref_fail_label = "Repository URL (copy)";
        T_feat_1 = "1) Bright core with darker rim (reflection-type)";
        T_feat_2 = "2) Mid-tone circular object with weak inner/outer contrast";
        T_feat_3 = "3) Dark clumps of aggregated objects (count by area)";
        T_feat_4 = "4) Dense/heterogeneous regions inside cells (in-cell only; count by area)";
        T_feat_5 = "5) Dark core with brighter rim (contrast-type)";
        T_feat_6 = "6) Low-contrast, small circular objects (close to cell intensity)";
        T_feat_err_title = "Feature Selection Error";
        T_feat_err_conflict = "[E012] Feature 1 and Feature 5 are mutually exclusive. Please adjust and retry.";
        T_feat_err_none = "[E013] No feature selected. Please select at least one feature.";

        T_result_next_title = "Results Generated";
        T_result_next_msg =
            "The Results table has been generated.\n\n" +
            "Steps:\n" +
            "1) Check the box and click \"OK\" to return to parameters and re-run analysis.\n" +
            "2) Leave it unchecked and click \"OK\" to exit the script.";
        T_result_next_checkbox = "Return to parameters and re-run analysis";

        T_step_param_title = "Step 4: Confirm parameters";
        T_step_param_msg =
            "The Parameters dialog will open next.\n\n" +
            "You will see:\n" +
            "�?Defaults inferred from target object samples (area range, object scale for clump estimation, Rolling Ball suggestion).\n" +
            "�?Feature-threshold parameters shown based on your selection " +
            "(inner/outer contrast, background similarity, small-size ratio, clump minimum multiplier).\n" +
            "�?If exclusion is enabled, an inferred intensity threshold and (optional) size gate range.\n\n" +
            "Note:\n" +
            "�?Parameter settings are split into two dialogs shown in sequence.\n\n" +
            "Recommendation:\n" +
            "�?For first-time use, run once with defaults and adjust only if needed.\n\n" +
            "Note: Click “OK�?to confirm and proceed to batch analysis.";

        T_step_main_title = "Start batch analysis";
        T_step_main_msg =
            "You are about to start batch analysis.\n\n" +
            "The script will process all images in the selected folder:\n" +
            "�?Load cell ROIs\n" +
            "�?Detect target objects and compute statistics (including clump estimation and optional exclusion)\n" +
            "�?Write a summary table to the Results window\n\n" +
            "Execution mode:\n" +
            "�?Runs in silent/batch mode to minimize intermediate windows.\n\n" +
            "If a cell ROI is missing:\n" +
            "�?You will be prompted to annotate now / skip / skip all / exit.\n" +
            "�?Skipped images remain in the Results table with blank values.\n\n" +
            "Note: Click “OK�?to start.";

        T_cell_title = "Cell ROI annotation";
        T_cell_msg =
            "Progress: %i / %n\n" +
            "File: %f\n\n" +
            "Create cell outlines:\n" +
            "1) Draw a cell outline.\n" +
            "2) Press “T�?to add it to ROI Manager.\n" +
            "3) Repeat until all cells in this image are complete.\n\n" +
            "Click “OK�?to save and continue.\n\n" +
            "Saved as: image name + �?s.zip�?;

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
            "�?Load and continue editing: opens existing ROIs for review and correction.\n" +
            "�?Re-annotate and overwrite: starts from an empty ROI set and overwrites the zip.\n" +
            "�?Skip this image: does not open the image and proceeds.\n" +
            "�?Skip all: future existing-ROI images will be skipped without prompting.\n\n" +
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
            "�?Four-factor analysis requires a cell ROI.\n" +
            "�?If skipped, the image remains in the Results table with blank values.\n\n" +
            "Select an action (dropdown):";

        T_sampling = "Sampling";
        T_promptAddROI =
            "Progress: %i / %n\n" +
            "File: %f\n\n" +
            "Mark target objects (prefer typical single objects; avoid obvious clumps).\n" +
            "�?For Features 3/4, add larger or irregular regions with Freehand/Polygon (in-cell=Feature 4, non-cell=Feature 3).\n" +
            "�?Press “T�?to add each ROI to ROI Manager.\n\n" +
            "Click “OK�?when finished.\n" +
            "Then choose the next action in the dropdown dialog.";

        T_promptAddROI_EX =
            "Progress: %i / %n\n" +
            "File: %f\n\n" +
            "Mark objects/regions to exclude.\n" +
            "�?Oval/Rectangle: exclusion object samples (intensity + size)\n" +
            "�?Freehand/Polygon: exclusion regions (intensity only)\n\n" +
            "Press “T�?to add each ROI.\n" +
            "Click “OK�?when finished.\n" +
            "Then choose the next action in the dropdown dialog.";

        T_ddLabel = "Next action";
        T_ddNext = "Next image (continue sampling)";
        T_ddStep = "Finish target sampling and proceed (compute defaults)";
        T_ddCompute = "Finish exclusion sampling and compute (open parameters)";
        T_ddExit = "Exit script";

        T_ddInfo_target =
            "Select the next action (dropdown):\n\n" +
            "�?Next image: continue sampling on the next image.\n" +
            "�?Finish target sampling and proceed: stop sampling and infer default parameters from collected samples.\n" +
            "�?Exit script: terminate immediately (batch analysis will not run).\n\n" +
            "Note: Click “OK�?to confirm.";

        T_ddInfo_excl =
            "Select the next action (dropdown):\n\n" +
            "�?Next image: continue sampling on the next image.\n" +
            "�?Finish exclusion sampling and compute: stop exclusion sampling and open the Parameters dialog.\n" +
            "�?Exit script: terminate immediately.\n\n" +
            "Note: Click “OK�?to confirm.";

        T_param = "Parameters";
        T_param_step1_title = "Parameters (1/2)";
        T_param_step2_title = "Parameters (2/2)";
        T_param_note_title = "Rationale and notes";
        T_section_target = "Target objects";
        T_section_feature = "Feature Detection";
        T_section_bg = "Background";
        T_section_roi = "Cell ROI";
        T_section_excl = "Exclusion (optional)";
        T_section_format = "Data Formatting";
        T_section_sep = "---- %s ----";

        T_minA = "Target object minimum area (px^2)";
        T_maxA = "Target object maximum area (px^2)";
        T_circ = "Target object minimum circularity (0�?)";
        T_allow_clumps = "Estimate object counts from clumps by area";
        T_min_phago_enable = "Treat tiny uptake as no uptake (dynamic threshold, default on)";
        T_pixel_count_enable = "Pixel count mode (target quantities use pixels; ignore area/circularity/clump split)";

        T_feat_center_diff = "Inner/outer contrast threshold (center - rim)";
        T_feat_bg_diff = "Background similarity threshold";
        T_feat_small_ratio = "Small-size ratio (relative to typical area)";
        T_feat_clump_ratio = "Clump minimum area multiplier";

        T_strict = "Detection strictness";
        T_strict_S = "Strict (reduce false positives)";
        T_strict_N = "Normal (recommended)";
        T_strict_L = "Loose (reduce false negatives)";

        T_roll = "Background Rolling Ball radius";
        T_suffix = "Cell ROI file suffix (without extension)";

        T_excl_enable = "Enable exclusion filter (intensity threshold)";
        T_excl_thr = "Exclusion threshold (0�?55)";
        T_excl_mode = "Exclusion direction";
        T_excl_high = "Exclude brighter objects (intensity �?threshold)";
        T_excl_low = "Exclude darker objects (intensity �?threshold)";
        T_excl_strict = "Stronger exclusion (dynamic threshold, stricter)";

        T_excl_size_gate = "Apply exclusion only within an exclusion size range (recommended)";
        T_excl_minA = "Exclusion minimum area (px^2)";
        T_excl_maxA = "Exclusion maximum area (px^2)";

        T_data_format_enable = "Enable data formatting";
        T_data_format_rule = "Filename rule (<p>/<f>)";
        T_data_format_cols = "Table column format";
        T_data_opt_enable = "Data optimization (IBR/PCR)";
        T_data_format_doc =
            "【Data Formatting - Token Map】\n" +
            "A. Filename rule (parsing only, not column tokens):\n" +
            "  Syntax: use \"/\" to separate parts; <p>/<f> are tokens; literals are allowed; write a space as \" \".\n" +
            "  Tokens: <p>=project | <f>=number | f=\"F\"/\"T\" maps <f> to column.\n" +
            "  Subfolders: folderRule//fileRule.\n" +
            "  Default references (copy as needed):\n" +
            "    Dolphin: <p>/<f>,f=\"F\"\n" +
            "    Windows Explorer: <p>/\" \"/(/<f>/),f=\"F\"\n" +
            "    macOS Finder: <p>/\" \"/<f>,f=\"F\"\n" +
            "  Subfolder example: <f>/hr,f=\"T\"//<p>/\" \"/(/<f>/)\n\n" +
            "B. Table column tokens (built-in):\n" +
            "  Identity: PN=project | F=index | T=time\n" +
            "  Counts: TB=total | BIC=in-cell | CWB=cells with objects\n" +
            "          CWBA=cells with objects (adj) | TC=total cells\n" +
            "  Ratios: IBR=BIC/TC | PCR=CWB/TC\n" +
            "  Per-cell: BPC=objects per cell\n" +
            "  Means/Stdev: EIBR/ISDP(IBR) | EPCR/PSDP(PCR) | EBPC/BPCSDP(BPC)\n\n" +
            "C. Custom columns:\n" +
            "  - No conflict with built-ins; params name=\"...\" value=\"...\"; $=show once.\n\n" +
            "D. Notes:\n" +
            "  - If T is set, rows sort by Time asc; EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP per time.\n" +
            "  - If BPC/EBPC/BPCSDP is included, rows expand per cell; only per-cell columns vary.\n" +
            "  - In pixel count mode, TB/BIC/BPC/EBPC/BPCSDP use pixel counts (px).\n" +
            "  - Params are comma-separated, values in double quotes; no empty items.\n";
        T_data_format_err_title = "Data Formatting - Input Error";
        T_data_format_err_hint = "Please correct the input and try again.";
        T_log_toggle_on = "ON";
        T_log_toggle_off = "OFF";
        T_log_error = "  �? �?Error: %s";

        T_err_df_rule_empty = "[E101] Filename rule is empty. Example: <p>/\" \"/(/<f>/),f=\"F\"";
        T_err_df_rule_slash = "[E102] Filename rule must contain at least one \"/\" separator. Example: <p>/\" \"/(/<f>/)";
        T_err_df_rule_parts = "[E103] All parts of the filename rule must be filled.";
        T_err_df_rule_tokens = "[E104] Only <p> and <f> are valid tokens; other parts must be literals.";
        T_err_df_rule_need_both = "[E105] Filename rule must include both <p> and <f>.";
        T_err_df_rule_order = "[E106] Filename rule order must be <p>/<f> or <f>/<p>.";
        T_err_df_rule_need_subfolder = "[E107] Subfolder-structure mode requires “folderRule//fileRule�?";
        T_err_df_rule_no_subfolder = "[E108] Subfolder rule �?/�?is not allowed in this mode.";
        T_err_df_rule_double_slash = "[E109] \"//\" can appear only once in the filename rule.";
        T_err_df_rule_param_kv = "[E110] Rule parameters must use key=\"value\" format.";
        T_err_df_rule_param_unknown_prefix = "[E111] Unknown rule parameter: ";
        T_err_df_rule_param_quote = "[E112] Rule parameter values must be wrapped in English double quotes.";
        T_err_df_rule_param_f_value = "[E113] f must be \"F\" or \"T\".";
        T_err_df_rule_param_duplicate = "[E114] Rule parameter f can be set only once.";
        T_err_df_cols_empty = "[E121] Table column format is empty.";
        T_err_df_cols_empty_item = "[E122] Table column format contains an empty item (possible \"//\" or leading/trailing \"/\").";
        T_err_df_cols_empty_token = "[E123] Table column format has an empty column code.";
        T_err_df_cols_params_comma = "[E124] Parameters must be comma-separated. Example: X,value=\"2\",name=\"hours\"";
        T_err_df_cols_dollar_missing = "[E125] \"$\" must be followed by a column code.";
        T_err_df_cols_dollar_builtin =
            "[E126] \"$\" can only be used for custom columns (not " +
            "PN/F/T/TB/BiC/CwB/CwBa/TC/BPC/IBR/PCR/EBPC/BPCSDP/eIBR/ePCR/ISDP/PSDP).";
        T_err_df_cols_param_kv = "[E127] Parameters must use key=\"value\" format.";
        T_err_df_cols_param_unknown_prefix = "[E128] Unknown parameter: ";
        T_err_df_cols_param_quote =
            "[E129] Parameter values must be wrapped in English double quotes. " +
            "Example: name=\"Cell with Target Objects\"";
        T_err_df_cols_unknown_token = "[E130] Unknown column code: ";
        T_err_df_cols_param_empty_name = "[E131] name cannot be empty.";
        T_err_df_cols_param_empty_value = "[E132] value cannot be empty.";
        T_err_df_cols_param_duplicate = "[E133] Duplicate parameter: ";
        T_err_df_cols_custom_need_param = "[E134] Custom columns must include a name or value parameter.";
        T_err_df_cols_dollar_duplicate = "[E135] Only one \"$\" custom column is allowed.";
        T_err_df_generic = "[E199] Data formatting input is invalid.";
        T_err_df_generic_detail = "Reason: the input could not be interpreted.";
        T_err_df_field = "Check: %s";
        T_err_df_fix_101 = "Fix: enter a valid rule (e.g., <p>/\" \"/(/<f>/) or <p>/<f>).";
        T_err_df_fix_102 = "Fix: separate parts with \"/\" (at least one).";
        T_err_df_fix_103 = "Fix: fill in every part between \"/\".";
        T_err_df_fix_104 = "Fix: use <p>/<f> as tokens and write other parts as literals.";
        T_err_df_fix_105 = "Fix: include both <p> and <f>.";
        T_err_df_fix_106 = "Fix: order must be <p>/<f> or <f>/<p>.";
        T_err_df_fix_107 = "Fix: use folderRule//fileRule format.";
        T_err_df_fix_108 = "Fix: remove \"//\" or switch to subfolder-keep mode.";
        T_err_df_fix_109 = "Fix: allow only one \"//\".";
        T_err_df_fix_110 = "Fix: use key=\"value\" format.";
        T_err_df_fix_111 = "Fix: only f parameter is allowed.";
        T_err_df_fix_112 = "Fix: wrap values in English double quotes.";
        T_err_df_fix_113 = "Fix: f must be \"F\" or \"T\".";
        T_err_df_fix_114 = "Fix: f can appear only once.";
        T_err_df_fix_121 = "Fix: provide at least one column token.";
        T_err_df_fix_122 = "Fix: remove empty items (avoid \"//\" or leading/trailing \"/\").";
        T_err_df_fix_123 = "Fix: fill in the column token.";
        T_err_df_fix_124 = "Fix: separate parameters with commas.";
        T_err_df_fix_125 = "Fix: place a column token after \"$\".";
        T_err_df_fix_126 = "Fix: do not add \"$\" to built-in columns.";
        T_err_df_fix_127 = "Fix: use key=\"value\" format.";
        T_err_df_fix_128 = "Fix: only name or value is allowed.";
        T_err_df_fix_129 = "Fix: wrap values in English double quotes.";
        T_err_df_fix_130 = "Fix: use built-in tokens or define a $ custom column with name/value.";
        T_err_df_fix_131 = "Fix: name cannot be empty.";
        T_err_df_fix_132 = "Fix: value cannot be empty.";
        T_err_df_fix_133 = "Fix: name/value can appear only once each.";
        T_err_df_fix_134 = "Fix: custom columns require name or value.";
        T_err_df_fix_135 = "Fix: only one \"$\" custom column is allowed.";
        T_err_param_num_title = "Parameter Input Error";
        T_err_param_num_msg =
            "[E201] Invalid numeric input: %s\n\n" +
            "Stage: %stage\n\n" +
            "Fix: Enter a number (decimals allowed).";

        T_beads_type_title = "Object type confirmation";
        T_beads_type_msg =
            "Confirm whether multiple object types or confounding objects are present.\n\n" +
            "�?Single object type: exclusion is typically unnecessary.\n" +
            "�?Multiple object types / confounders: exclusion is recommended; run exclusion sampling.\n\n" +
            "Note: You can still disable exclusion later in the Parameters dialog.";
        T_beads_type_checkbox = "Multiple object types present (enable exclusion)";

        T_excl_note_few_samples = "Not enough intensity samples (<3). The inferred threshold is unreliable; set it manually.";
        T_excl_note_few_effective =
            "Not enough effective intensity samples (possible saturation). " +
            "The inferred threshold is unreliable; set it manually.";
        T_excl_note_diff_small =
            "Target/exclusion intensity difference is too small (<8). " +
            "The inferred threshold is unreliable; set it manually.";
        T_excl_note_overlap_high =
            "Distributions overlap substantially; a conservative threshold was chosen " +
            "(near exclusion low quantile). Review recommended.";
        T_excl_note_good_sep_high = "Separation is good; threshold estimated from target high quantile and exclusion low quantile.";
        T_excl_note_overlap_low =
            "Distributions overlap substantially; a conservative threshold was chosen " +
            "(near exclusion high quantile). Review recommended.";
        T_excl_note_good_sep_low = "Separation is good; threshold estimated from target low quantile and exclusion high quantile.";

        T_err_need_window =
            "[E001] The required window was not found at stage [%stage].\n\n" +
            "Window: %w\n" +
            "File: %f\n\n" +
            "Recommendation: Close any window with the same title and retry to avoid title collisions.";
        T_err_open_fail =
            "[E002] Cannot open image file:\n%p\n\n" +
            "Stage: %stage\n" +
            "File: %f\n\n" +
            "Fix: Ensure the file exists and can be opened in Fiji. Replace or re-export if the file is damaged.";
        T_err_roi_empty_title = "ROI Is Empty";
        T_err_roi_empty_msg =
            "[E009] No ROI was detected, so the ROI file cannot be saved.\n\n" +
            "Stage: %stage\n" +
            "File: %f\n\n" +
            "Fix: Draw cell outlines and press \"T\" to add them to the ROI Manager.";
        T_err_roi_save_title = "ROI Save Failed";
        T_err_roi_save_msg =
            "[E010] Cannot save the ROI file:\n%p\n\n" +
            "Stage: %stage\n" +
            "File: %f\n\n" +
            "Fix: Check write permission and avoid special characters in the path.";
        T_err_roi_open_title = "ROI Load Failed";
        T_err_roi_open_msg =
            "[E011] The ROI file could not be loaded or contains no valid ROI:\n%p\n\n" +
            "Stage: %stage\n" +
            "File: %f\n\n" +
            "Fix: Verify the ROI zip is not corrupted and re-annotate if needed.";
        T_err_too_many_cells = "[E003] Cell ROI count exceeds 65535:";
        T_err_too_many_cells_hint =
            "This implementation encodes labels in the range 1..65535 using 16-bit. " +
            "Process in smaller batches or reduce the ROI count.";
        T_err_file = "File:";
        T_err_roi1_invalid = "[E004] ROI[1] is invalid (no valid bounds). Cannot generate the cell label image.";
        T_err_labelmask_failed = "[E005] Cell label image generation failed: the center pixel is still 0 after filling.";
        T_err_labelmask_hint = "Verify that ROI[1] is a closed area ROI and overlaps the image content.";

        T_log_sep = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";
        T_log_start = "�?Start: Macrophage four-factor analysis";
        T_log_lang = "  ├─ Language: English";
        T_log_dir = "  ├─ Folder: selected";
        T_log_mode = "  └─ Mode: %s";
        T_log_roi_phase_start = "�?Step: Cell ROI annotation";
        T_log_roi_phase_done = "�?Complete: Cell ROI annotation";
        T_log_sampling_start = "�?Step: Target object sampling";
        T_log_sampling_cancel = "�?Complete: Sampling (finished by user)";
        T_log_sampling_img = "  ├─ Sample [%i/%n]: %f";
        T_log_sampling_rois = "  �? └─ ROI count: %i";
        T_log_params_calc = "�?Complete: Default parameters inferred";
        T_log_feature_select = "  ├─ Target features: %s";
        T_log_main_start = "�?Start: Batch analysis (silent mode)";
        T_log_processing = "  ├─ Processing [%i/%n]: %f";
        T_log_missing_roi = "  �? �?Missing ROI: %f";
        T_log_missing_choice = "  �? └─ Action: %s";
        T_log_load_roi = "  �? ├─ Load ROI";
        T_log_roi_count = "  �? �? └─ Cell count: %i";
        T_log_bead_detect = "  �? ├─ Detect target objects and compute statistics";
        T_log_bead_count = "  �? �? ├─ Total objects: %i";
        T_log_bead_incell = "  �? �? ├─ Objects in cells: %i";
        T_log_bead_count_px = "  �? �? ├─ Total target pixels: %i";
        T_log_bead_incell_px = "  �? �? ├─ Target pixels in cells: %i";
        T_log_cell_withbead = "  �? �? └─ Cells with objects: %i";
        T_log_bead_summary_done = "  �? �? └─ Object statistics completed";
        T_log_complete = "  �? └─ �?Done";
        T_log_skip_roi = "  �? �?Skipped: missing ROI";
        T_log_skip_nocell = "  �? �?Skipped: no valid cells in ROI";
        T_log_results_save = "�?Complete: Results written to the Results table";
        T_log_opt_done = "�?Data optimization completed";
        T_log_opt_time = "�?Time-trend optimization completed";
        T_log_all_done = "✓✓�?All tasks completed ✓✓�?;
        T_log_summary = "📊 Summary: %i images processed";
        T_log_unit_sync_keep = "  └─ Object scale: using inferred value = %s";
        T_log_unit_sync_ui = "  └─ Object scale: manual change detected; using UI midpoint = %s";
        T_log_analyze_header = "  ├─ Analysis parameters";
        T_log_analyze_img = "  ├─ Image: %f";
        T_log_analyze_roi = "  �? ├─ ROI: %s";
        T_log_analyze_size = "  �? ├─ Size: %w x %h";
        T_log_analyze_pixel_mode = "  �? ├─ Count mode: Pixel count (ignore area/circularity/clump split)";
        T_log_analyze_bead_params = "  �? ├─ Target object params: area=%min-%max, circ>=%circ, unit=%unit";
        T_log_analyze_features = "  �? ├─ Target features: %s";
        T_log_analyze_feature_params = "  �? ├─ Feature params: diff=%diff bg=%bg small=%small clump=%clump";
        T_log_analyze_strict = "  �? ├─ Strictness: %strict, merge policy: %policy";
        T_log_analyze_bg = "  �? ├─ Background subtraction: rolling=%r";
        T_log_analyze_excl_on = "  �? ├─ Exclusion: mode=%mode thr=%thr strict=%strict sizeGate=%gate range=%min-%max";
        T_log_analyze_excl_off = "  �? └─ Exclusion: disabled";
        T_log_analyze_method = "  �? └─ Detection flow: A=Yen+Mask+Watershed; B=Edges+Otsu+Mask+Watershed; merge=%policy";
        T_log_analyze_excl_adjust = "  �? └─ Dynamic threshold: mean=%mean std=%std kstd=%kstd thr=%thr";
        T_log_label_mask = "  �? ├─ Cell label mask: %s";
        T_log_label_mask_ok = "generated";
        T_log_label_mask_fail = "failed";
        T_log_policy_strict = "STRICT";
        T_log_policy_union = "UNION";
        T_log_policy_loose = "LOOSE";
        T_log_df_header = "  ├─ Data formatting: custom parsing details";
        T_log_df_rule = "  �? ├─ Rule: %s";
        T_log_df_cols = "  �? ├─ Column format: %s";
        T_log_df_sort_asc = "  �? ├─ Sort: %s ascending";
        T_log_df_sort_desc = "  �? ├─ Sort: %s descending";
        T_log_df_item = "  �? └─ item: raw=%raw | token=%token | name=%name | value=%value | single=%single";

        T_reason_no_target = "No target object sampling was performed: using default object scale and default Rolling Ball.";
        T_reason_target_ok = "Object scale and Rolling Ball were inferred from target samples (robust estimation).";
        T_reason_excl_on = "Exclusion is enabled: threshold inferred from exclusion samples (adjust manually if flagged unreliable).";
        T_reason_excl_off = "Exclusion is disabled.";
        T_reason_excl_size_ok = "Exclusion size range inferred from exclusion object samples.";
        T_reason_excl_size_off = "Not enough exclusion object size samples: size gate is disabled by default.";

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
    // フェーズ3: 作業モード選択（ROIのみ / 解析のみ / ROI+解析�?
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
    dir = ensureTrailingSlash(dir);

    rawList = getFileList(dir);

    rootFiles = newArray();
    imgRootFiles = newArray();
    subDirs = newArray();
    k = 0;
    while (k < rawList.length) {
        name = rawList[k];
        if (!startsWith(name, ".") && toLowerCase(name) != "thumbs.db") {
            path = dir + name;
            if (File.isDirectory(path)) {
                subDirs[subDirs.length] = name;
            } else {
                rootFiles[rootFiles.length] = name;
                if (!endsWith(toLowerCase(name), ".zip")) {
                    if (isImageFile(name)) imgRootFiles[imgRootFiles.length] = name;
                }
            }
        }
        k = k + 1;
    }

    SUBFOLDER_MODE = 0;
    SUBFOLDER_KEEP_MODE = 0;

    if (imgRootFiles.length > 0 && subDirs.length > 0) {
        logErrorMessage(T_err_dir_illegal_msg);
        showMessage(T_err_dir_illegal_title, T_err_dir_illegal_msg);
        exit(T_exitScript);
    }

    imgEntries = newArray();
    if (imgRootFiles.length > 0) {
        k = 0;
        while (k < imgRootFiles.length) {
            imgName = imgRootFiles[k];
            base = getBaseName(imgName);
            key = imgName;
            entry = key + "\t" + dir + "\t" + imgName + "\t" + base + "\t" + "\t" + base;
            imgEntries[imgEntries.length] = entry;
            k = k + 1;
        }
    } else if (subDirs.length > 0) {
        SUBFOLDER_MODE = 1;
        Dialog.create(T_subfolder_title);
        Dialog.addMessage(T_subfolder_msg);
        Dialog.addChoice(T_subfolder_label, newArray(T_subfolder_keep, T_subfolder_flat), T_subfolder_keep);
        Dialog.show();
        subMode = Dialog.getChoice();
        if (subMode == T_subfolder_keep) SUBFOLDER_KEEP_MODE = 1;

        k = 0;
        while (k < subDirs.length) {
            subName = subDirs[k];
            subPath = ensureTrailingSlash(dir + subName);
            subClean = subName;
            if (endsWith(subClean, "/")) subClean = substring(subClean, 0, lengthOf(subClean) - 1);
            subList = getFileList(subPath);
            hasNested = 0;
            j = 0;
            while (j < subList.length) {
                entry = subList[j];
                if (!startsWith(entry, ".") && toLowerCase(entry) != "thumbs.db") {
                    if (File.isDirectory(subPath + entry)) {
                        hasNested = 1;
                        break;
                    }
                }
                j = j + 1;
            }
            if (hasNested == 1) {
                msg = replaceSafe(T_err_subdir_illegal_msg, "%s", subClean);
                logErrorMessage(msg);
                showMessage(T_err_subdir_illegal_title, msg);
                exit(T_exitScript);
            }
            j = 0;
            while (j < subList.length) {
                imgName = subList[j];
                if (!endsWith(toLowerCase(imgName), ".zip")) {
                    if (isImageFile(imgName)) {
                        base = getBaseName(imgName);
                        if (SUBFOLDER_KEEP_MODE == 1) parseBase = base;
                        else parseBase = subClean + "_" + base;
                        key = subClean + "/" + imgName;
                        entry = key + "\t" + subPath + "\t" + imgName + "\t" + base + "\t" + subClean + "\t" + parseBase;
                        imgEntries[imgEntries.length] = entry;
                    }
                }
                j = j + 1;
            }
            k = k + 1;
        }
    } else {
        logErrorMessage(T_noImages);
        exit(T_noImages);
    }

    if (imgEntries.length == 0) {
        logErrorMessage(T_noImages);
        exit(T_noImages);
    }

    Array.sort(imgEntries);

    nTotalImgs = imgEntries.length;

    imgFilesSorted = newArray(nTotalImgs);
    imgDirs = newArray(nTotalImgs);
    bases = newArray(nTotalImgs);
    subNames = newArray(nTotalImgs);
    parseBases = newArray(nTotalImgs);
    k = 0;
    while (k < nTotalImgs) {
        parts = splitByChar(imgEntries[k], "\t");
        imgDirs[k] = parts[1];
        imgFilesSorted[k] = parts[2];
        bases[k] = parts[3];
        subNames[k] = parts[4];
        parseBases[k] = parts[5];
        k = k + 1;
    }

    // サンプリング用にランダム順リストも作成する
    imgSampleIdx = newArray(nTotalImgs);
    k = 0;
    while (k < nTotalImgs) {
        imgSampleIdx[k] = k;
        k = k + 1;
    }

    k = imgSampleIdx.length - 1;
    while (k > 0) {
        j = floor(random() * (k + 1));
        swap = imgSampleIdx[k];
        imgSampleIdx[k] = imgSampleIdx[j];
        imgSampleIdx[j] = swap;
        k = k - 1;
    }

    roiSuffix = "_cells";

    // 画像名とROIパスの対応表を作成す�?
    roiPaths = newArray(nTotalImgs);
    k = 0;
    while (k < nTotalImgs) {
        roiPaths[k] = imgDirs[k] + bases[k] + roiSuffix + ".zip";
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
            SKIP_ALL_EXISTING_ROI = annotateCellsSmart(imgDirs[k], imgFilesSorted[k], roiSuffix, k + 1, nTotalImgs, SKIP_ALL_EXISTING_ROI);
            k = k + 1;
        }

        log(T_log_roi_phase_done);
        log(T_log_sep);
    }

    if (doROI && !doAnalyze) {
        // -----------------------------------------------------------------------------
        // ROIのみ実行時はここで終了す�?
        // -----------------------------------------------------------------------------
        maybePrintMotto();
        exit("");
    }

    // -----------------------------------------------------------------------------
    // フェーズ6: 目標物のサンプリング
    // -----------------------------------------------------------------------------
    waitForUser(T_step_bead_title, T_step_bead_msg);
    log(T_log_sampling_start);

    Dialog.create(T_beads_type_title);
    Dialog.addMessage(T_beads_type_msg);
    Dialog.addCheckbox(T_beads_type_checkbox, false);
    Dialog.show();
    HAS_MULTI_BEADS = Dialog.getCheckbox();

    sampleAreas = newArray();
    sampleMeans = newArray();
    sampleCenterDiffs = newArray();
    sampleBgDiffs = newArray();
    sampleIsRound = newArray();
    sampleInCell = newArray();

    targetAreas = newArray();
    targetMeans = newArray();
    unitCenterDiffs = newArray();
    unitBgDiffs = newArray();

    exclMeansAll = newArray();
    exclAreasBead = newArray();

    DEF_MINA = 5;
    DEF_MAXA = 200;
    DEF_CIRC = 0;
    DEF_ROLL = 50;
    DEF_CENTER_DIFF = 12;
    DEF_BG_DIFF = 10;
    DEF_SMALL_RATIO = 0.70;
    DEF_CLUMP_RATIO = 4.0;
    DEF_CLUMP_SAMPLE_RATIO = 2.5;

    run("Set Measurements...", "area mean redirect=None decimal=3");

    s = 0;
    while (s < nTotalImgs) {

        idxSample = imgSampleIdx[s];
        imgName = imgFilesSorted[idxSample];
        imgDir = imgDirs[idxSample];
        printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, imgName);

        // サンプル用画像を開き、ROIを追加してもらう
        origTitle = openImageSafe(imgDir + imgName, "sampling/target/open", imgName);
        ensure2D();
        forcePixelUnit();
        origID = getImageID();
        wOrig = getWidth();
        hOrig = getHeight();

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

        sampleStart = sampleAreas.length;
        sampleEnd = sampleStart - 1;
        sampleRoiPath = "";

        if (nR > 0) {
            // 8-bit画像でROIを計測して面積・平均灰度を収集す�?
            safeClose("__tmp8_target");
            selectWindow(origTitle);
            run("Duplicate...", "title=__tmp8_target");
            requireWindow("__tmp8_target", "sampling/target/tmp8", imgName);
            run("8-bit");

            run("Clear Results");
            roiManager("Measure");

            nRes = nResults;
            if (nRes > 0) {
                w8 = getWidth();
                h8 = getHeight();

                row = 0;
                while (row < nRes) {
                    a = getResult("Area", row);
                    m = getResult("Mean", row);

                    roiManager("select", row);
                    roiType = selectionType();
                    getSelectionBounds(bx, by, bw, bh);

                    cx = floor(bx + bw / 2);
                    cy = floor(by + bh / 2);
                    r = min2(bw, bh) / 2.0;
                    if (r < 1) r = 1;

                    stats = computeSpotStats(cx, cy, r, w8, h8);
                    centerDiff = stats[4];
                    bgDiff = stats[5];

                    isRound = 1;
                    if (roiType != 0 && roiType != 1) isRound = 0;
                    if (bw <= 0 || bh <= 0) isRound = 0;
                    ratio = 1;
                    if (bw > 0 && bh > 0) {
                        ratio = bw / bh;
                        if (ratio < 1) ratio = 1 / ratio;
                    }
                    if (ratio > 1.6) isRound = 0;

                    sampleAreas[sampleAreas.length] = a;
                    sampleMeans[sampleMeans.length] = m;
                    sampleCenterDiffs[sampleCenterDiffs.length] = centerDiff;
                    sampleBgDiffs[sampleBgDiffs.length] = bgDiff;
                    sampleIsRound[sampleIsRound.length] = isRound;
                    sampleInCell[sampleInCell.length] = 0;
                    row = row + 1;
                }
                sampleEnd = sampleAreas.length - 1;
            }

            run("Clear Results");
            selectWindow("__tmp8_target"); close();
        }

        if (sampleEnd >= sampleStart) {
            tmpDir = getDirectory("temp");
            sampleRoiPath = tmpDir + "mf4_target_sample_" + getTime() + ".zip";
            roiManager("Save", sampleRoiPath);
            if (!File.exists(sampleRoiPath)) {
                msg = T_err_roi_save_msg;
                msg = replaceSafe(msg, "%p", sampleRoiPath);
                msg = replaceSafe(msg, "%stage", "sampling/target/save");
                msg = replaceSafe(msg, "%f", imgName);
                logErrorMessage(msg);
                showMessage(T_err_roi_save_title, msg);
                sampleRoiPath = "";
            }
        }

        if (sampleEnd >= sampleStart && sampleRoiPath != "") {
            roiPath = roiPaths[idxSample];
            if (File.exists(roiPath)) {
                roiManager("Reset");
                roiManager("Open", roiPath);
                nCellsSample = roiManager("count");
                if (nCellsSample == 0) {
                    msg = T_err_roi_open_msg;
                    msg = replaceSafe(msg, "%p", roiPath);
                    msg = replaceSafe(msg, "%stage", "sampling/target/roi");
                    msg = replaceSafe(msg, "%f", imgName);
                    logErrorMessage(msg);
                    showMessage(T_err_roi_open_title, msg);
                }
                if (nCellsSample > 0) {
                    cellLabelSample = "__cellLabel_sample";
                    HAS_LABEL_MASK_SAMPLE = buildCellLabelMaskFromOriginal(
                        cellLabelSample, origID, wOrig, hOrig, nCellsSample, imgName
                    );
                    if (HAS_LABEL_MASK_SAMPLE == 1) {
                        roiManager("Reset");
                        roiManager("Open", sampleRoiPath);
                        sampleCount = sampleEnd - sampleStart + 1;
                        nR2 = roiManager("count");
                        if (sampleCount > nR2) sampleCount = nR2;

                        requireWindow(cellLabelSample, "sampling/label", imgName);

                        r = 0;
                        while (r < sampleCount) {
                            roiManager("select", r);
                            getSelectionBounds(bx, by, bw, bh);

                            hit = 0;
                            total = 0;
                            decided = 0;
                            if (bw > 0 && bh > 0) {
                                // ROI内の粗いグリッドで細胞内比率を評価し�?0%閾値で早期判定する�?
                                step = floor(min2(bw, bh) / 6);
                                if (step < 1) step = 1;
                                gridX = floor((bw - 1) / step) + 1;
                                gridY = floor((bh - 1) / step) + 1;
                                totalGrid = gridX * gridY;
                                visited = 0;
                                y = by;
                                while (y < by + bh) {
                                    x = bx;
                                    while (x < bx + bw) {
                                        visited = visited + 1;
                                        if (selectionContains(x, y)) {
                                            total = total + 1;
                                            if (getPixel(x, y) > 0) hit = hit + 1;
                                        }
                                        remain = totalGrid - visited;
                                        maxTotal = total + remain;
                                        if (maxTotal > 0) {
                                            minRatio = hit / maxTotal;
                                            maxRatio = (hit + remain) / maxTotal;
                                            if (minRatio >= 0.30) {
                                                sampleInCell[sampleStart + r] = 1;
                                                decided = 1;
                                                break;
                                            }
                                            if (maxRatio < 0.30) {
                                                decided = 1;
                                                break;
                                            }
                                        }
                                        x = x + step;
                                    }
                                    if (decided == 1) break;
                                    y = y + step;
                                }
                            }
                            if (decided == 0 && total > 0) {
                                if ((hit * 1.0) / total >= 0.30) sampleInCell[sampleStart + r] = 1;
                            }
                            r = r + 1;
                        }
                    }
                    safeClose(cellLabelSample);
                }
                roiManager("Reset");
            }
            if (sampleRoiPath != "") File.delete(sampleRoiPath);
        }

        selectWindow(origTitle);
        close();

        if (act == T_ddStep) {
            log(T_log_sampling_cancel);
            break;
        }

        s = s + 1;
    }

    // 円形サンプルを抽出して推定用の配列を作成する
    roundAreas = newArray();
    roundMeans = newArray();
    roundCenterDiffs = newArray();
    roundBgDiffs = newArray();

    k = 0;
    while (k < sampleAreas.length) {
        if (sampleIsRound[k] == 1) {
            roundAreas[roundAreas.length] = sampleAreas[k];
            roundMeans[roundMeans.length] = sampleMeans[k];
            roundCenterDiffs[roundCenterDiffs.length] = sampleCenterDiffs[k];
            roundBgDiffs[roundBgDiffs.length] = sampleBgDiffs[k];
        }
        k = k + 1;
    }

    areaCap = -1;
    if (roundAreas.length >= 3) {
        tmpArea = newArray(roundAreas.length);
        k = 0;
        while (k < roundAreas.length) {
            tmpArea[k] = roundAreas[k];
            k = k + 1;
        }
        Array.sort(tmpArea);
        medA = tmpArea[floor((tmpArea.length - 1) * 0.50)];
        if (medA < 1) medA = 1;
        areaCap = medA * 3.0;
        if (areaCap < medA + 1) areaCap = medA + 1;
    }

    k = 0;
    while (k < roundAreas.length) {
        a = roundAreas[k];
        if (areaCap < 0 || a <= areaCap) {
            targetAreas[targetAreas.length] = a;
            targetMeans[targetMeans.length] = roundMeans[k];
            unitCenterDiffs[unitCenterDiffs.length] = roundCenterDiffs[k];
            unitBgDiffs[unitBgDiffs.length] = roundBgDiffs[k];
        }
        k = k + 1;
    }

    if (targetAreas.length == 0) {
        targetAreas = sampleAreas;
        targetMeans = sampleMeans;
        unitCenterDiffs = sampleCenterDiffs;
        unitBgDiffs = sampleBgDiffs;
    }

    // -----------------------------------------------------------------------------
    // フェーズ7: 排除対象のサンプリング（必要時のみ）
    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {

        waitForUser(T_step_bead_ex_title, T_step_bead_ex_msg);

        s = 0;
        while (s < nTotalImgs) {

            idxSample = imgSampleIdx[s];
            imgName = imgFilesSorted[idxSample];
            imgDir = imgDirs[idxSample];
            printWithIndex(T_log_sampling_img, s + 1, nTotalImgs, imgName);

            // 排除対象のサンプルを収集する
            origTitle = openImageSafe(imgDir + imgName, "sampling/excl/open", imgName);
            ensure2D();
            forcePixelUnit();

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

                // 8-bit画像でROIを計測して灰度分布と面積の候補を収集す�?
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

    // 目標物特徴の選択
    useF1 = 1;
    useF2 = 1;
    useF3 = 1;
    useF4 = 0;
    useF5 = 0;
    useF6 = 0;

    openFeatureReferenceImage(FEATURE_REF_URL, T_feat_ref_title);

    while (1) {
        Dialog.create(T_feat_title);
        Dialog.addMessage(T_feat_msg);
        Dialog.addCheckbox(T_feat_1, (useF1 == 1));
        Dialog.addCheckbox(T_feat_2, (useF2 == 1));
        Dialog.addCheckbox(T_feat_3, (useF3 == 1));
        Dialog.addCheckbox(T_feat_4, (useF4 == 1));
        Dialog.addCheckbox(T_feat_5, (useF5 == 1));
        Dialog.addCheckbox(T_feat_6, (useF6 == 1));
        Dialog.show();

        if (Dialog.getCheckbox()) useF1 = 1;
        else useF1 = 0;
        if (Dialog.getCheckbox()) useF2 = 1;
        else useF2 = 0;
        if (Dialog.getCheckbox()) useF3 = 1;
        else useF3 = 0;
        if (Dialog.getCheckbox()) useF4 = 1;
        else useF4 = 0;
        if (Dialog.getCheckbox()) useF5 = 1;
        else useF5 = 0;
        if (Dialog.getCheckbox()) useF6 = 1;
        else useF6 = 0;

        if (useF1 == 1 && useF5 == 1) {
            logErrorMessage(T_feat_err_conflict);
            showMessage(T_feat_err_title, T_feat_err_conflict);
            continue;
        }

        if ((useF1 + useF2 + useF3 + useF4 + useF5 + useF6) == 0) {
            logErrorMessage(T_feat_err_none);
            showMessage(T_feat_err_title, T_feat_err_none);
            continue;
        }
        break;
    }

    safeClose(T_feat_ref_title);

    featList = formatFeatureList(useF1, useF2, useF3, useF4, useF5, useF6);
    log(replaceSafe(T_log_feature_select, "%s", featList));

    reasonMsg = "";

    defMinA = DEF_MINA;
    defMaxA = DEF_MAXA;
    defCirc = DEF_CIRC;
    defRoll = DEF_ROLL;
    defCenterDiff = DEF_CENTER_DIFF;
    defBgDiff = DEF_BG_DIFF;
    defSmallRatio = DEF_SMALL_RATIO;
    defClumpRatio = DEF_CLUMP_RATIO;

    beadUnitArea = (defMinA + defMaxA) / 2;
    if (beadUnitArea < 1) beadUnitArea = 1;

    defAllowClumps = 1;
    useMinPhago = 1;
    usePixelCount = 0;

    useExcl = 0;
    exclMode = "HIGH";
    exclThr = 255;
    useExclStrict = 1;

    useExclSizeGate = 1;
    defExMinA = DEF_MINA;
    defExMaxA = DEF_MAXA;

    dataFormatEnable = 1;
    dataFormatRule = "<p>/\" \"/(/<f>/),f=\"F\"";
    if (SUBFOLDER_KEEP_MODE == 1) dataFormatRule = "<f>/hr,f=\"T\"//<p>/\" \"/(/<f>/)";
    dataFormatCols = "TB/BIC/CWBA,name=\"Cell with Target Objects\"/TC/IBR/PCR/EIBR/EPCR/ISDP/PSDP";
    dataOptimizeEnable = 1;

    // -----------------------------------------------------------------------------
    // フェーズ8: パラメータ推定（面積・閾値・Rolling Ball�?
    // -----------------------------------------------------------------------------
    targetMeanMed = estimateMeanMedianSafe(targetMeans);
    exclMeanMed = estimateMeanMedianSafe(exclMeansAll);

    if (targetAreas.length == 0) {
        reasonMsg = reasonMsg + "�?" + T_reason_no_target + "\n";
    } else {
        // 目標物の面積範囲と代表値を推定する
        range = estimateAreaRangeSafe(targetAreas, DEF_MINA, DEF_MAXA);
        defMinA = range[0];
        defMaxA = range[1];
        beadUnitArea = range[2];
        defRoll = estimateRollingFromUnitArea(beadUnitArea);
        reasonMsg = reasonMsg + "�?" + T_reason_target_ok + "\n";

        defCenterDiff = estimateAbsDiffThresholdSafe(unitCenterDiffs, DEF_CENTER_DIFF, 6, 40, 0.70);
        defBgDiff = estimateAbsDiffThresholdSafe(unitBgDiffs, DEF_BG_DIFF, 4, 30, 0.50);
        defSmallRatio = estimateSmallAreaRatioSafe(targetAreas, DEF_SMALL_RATIO);

        clumpAreasAll = newArray();
        clumpAreasInCell = newArray();
        k = 0;
        while (k < sampleAreas.length) {
            isClumpSample = 0;
            if (sampleIsRound[k] == 0) isClumpSample = 1;
            else if (beadUnitArea > 0 && sampleAreas[k] >= beadUnitArea * DEF_CLUMP_SAMPLE_RATIO) isClumpSample = 1;

            if (isClumpSample == 1) {
                clumpAreasAll[clumpAreasAll.length] = sampleAreas[k];
                if (sampleInCell[k] == 1) clumpAreasInCell[clumpAreasInCell.length] = sampleAreas[k];
            }
            k = k + 1;
        }

        if (clumpAreasAll.length > 0) {
            if (useF4 == 1 && useF3 == 0 && clumpAreasInCell.length > 0) {
                defClumpRatio = estimateClumpRatioFromSamples(clumpAreasInCell, beadUnitArea, DEF_CLUMP_RATIO);
            } else {
                defClumpRatio = estimateClumpRatioFromSamples(clumpAreasAll, beadUnitArea, DEF_CLUMP_RATIO);
            }
        } else if (roundAreas.length > 0) {
            defClumpRatio = estimateClumpRatioSafe(roundAreas, DEF_CLUMP_RATIO);
        } else {
            defClumpRatio = estimateClumpRatioSafe(targetAreas, DEF_CLUMP_RATIO);
        }
    }

    // -----------------------------------------------------------------------------
    // 排除対象がある場合は灰度/面積の推定を行う
    // -----------------------------------------------------------------------------
    if (HAS_MULTI_BEADS) {
        useExcl = 1;

        // 排除対象の灰度分布から閾値と方向を推定す�?
        exInfo = estimateExclusionSafe(targetMeans, exclMeansAll);
        exclMode = exInfo[1];
        exclThr = exInfo[2];

        reasonMsg = reasonMsg + "�?" + T_reason_excl_on + "\n";
        reasonMsg = reasonMsg + "  - " + exInfo[4] + "\n";

        if (exclAreasBead.length > 0) {
            // 排除対象の面積範囲も推定する
            exRange = estimateAreaRangeSafe(exclAreasBead, DEF_MINA, DEF_MAXA);
            defExMinA = exRange[0];
            defExMaxA = exRange[1];
            reasonMsg = reasonMsg + "�?" + T_reason_excl_size_ok + "\n";
        } else {
            defExMinA = DEF_MINA;
            defExMaxA = DEF_MAXA;
            useExclSizeGate = 0;
            reasonMsg = reasonMsg + "�?" + T_reason_excl_size_off + "\n";
        }
    } else {
        useExcl = 0;
        useExclStrict = 0;
        useExclSizeGate = 0;
        reasonMsg = reasonMsg + "�?" + T_reason_excl_off + "\n";
    }

    log(T_log_params_calc);

    waitForUser(T_step_param_title, T_step_param_msg);

    if (exclMode == "LOW") exclModeDefault = T_excl_low;
    else exclModeDefault = T_excl_high;

    hasRoundFeatures = 0;
    if (useF1 == 1 || useF2 == 1 || useF5 == 1 || useF6 == 1) hasRoundFeatures = 1;
    hasClumpFeatures = 0;
    if (useF3 == 1 || useF4 == 1) hasClumpFeatures = 1;

    rerunFlag = 1;
    // パラメータ確認完了後に「重新分析」選択で再表示するため、ループで制御する�?
    while (rerunFlag == 1) {
        // -----------------------------------------------------------------------------
        // フェーズ9: パラメータ確認ダイアログ�?/2�?
        // -----------------------------------------------------------------------------
        Dialog.create(T_param_step1_title);
        Dialog.addMessage(T_param_note_title + ":\n" + reasonMsg);

        Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_target));
        Dialog.addNumber(T_minA, defMinA);
        Dialog.addNumber(T_maxA, defMaxA);
        Dialog.addNumber(T_circ, defCirc);
        Dialog.addCheckbox(T_allow_clumps, (defAllowClumps == 1));

        if (hasRoundFeatures == 1 || hasClumpFeatures == 1) {
            Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_feature));
            if (hasRoundFeatures == 1) {
                Dialog.addNumber(T_feat_center_diff, defCenterDiff);
                Dialog.addNumber(T_feat_bg_diff, defBgDiff);
                Dialog.addNumber(T_feat_small_ratio, defSmallRatio);
            }
            if (hasClumpFeatures == 1) {
                Dialog.addNumber(T_feat_clump_ratio, defClumpRatio);
            }
        }

        Dialog.show();

        beadMinArea = Dialog.getNumber();
        beadMaxArea = Dialog.getNumber();
        beadMinCirc = Dialog.getNumber();

        if (validateDialogNumber(beadMinArea, T_minA, "param/step1") == 0) continue;
        if (validateDialogNumber(beadMaxArea, T_maxA, "param/step1") == 0) continue;
        if (validateDialogNumber(beadMinCirc, T_circ, "param/step1") == 0) continue;

        if (Dialog.getCheckbox()) allowClumpsTarget = 1;
        else allowClumpsTarget = 0;
        allowClumpsUI = allowClumpsTarget;

        if (hasRoundFeatures == 1) {
            centerDiffThrUI = Dialog.getNumber();
            bgDiffThrUI = Dialog.getNumber();
            smallAreaRatioUI = Dialog.getNumber();
            if (validateDialogNumber(centerDiffThrUI, T_feat_center_diff, "param/step1") == 0) continue;
            if (validateDialogNumber(bgDiffThrUI, T_feat_bg_diff, "param/step1") == 0) continue;
            if (validateDialogNumber(smallAreaRatioUI, T_feat_small_ratio, "param/step1") == 0) continue;
        } else {
            centerDiffThrUI = defCenterDiff;
            bgDiffThrUI = defBgDiff;
            smallAreaRatioUI = defSmallRatio;
        }

        if (hasClumpFeatures == 1) {
            clumpMinRatioUI = Dialog.getNumber();
            if (validateDialogNumber(clumpMinRatioUI, T_feat_clump_ratio, "param/step1") == 0) continue;
        } else {
            clumpMinRatioUI = defClumpRatio;
        }

        // -----------------------------------------------------------------------------
        // フェーズ9: パラメータ確認ダイアログ�?/2�?        // -----------------------------------------------------------------------------
        Dialog.create(T_param_step2_title);
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

        Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_target));
        Dialog.addCheckbox(T_min_phago_enable, true);
        Dialog.addCheckbox(T_pixel_count_enable, (usePixelCount == 1));
        Dialog.addChoice(T_strict, newArray(T_strict_S, T_strict_N, T_strict_L), T_strict_N);

        Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_bg));
        Dialog.addNumber(T_roll, defRoll);

        Dialog.addMessage(replaceSafe(T_section_sep, "%s", T_section_roi));
        Dialog.addString(T_suffix, roiSuffix);
        Dialog.show();

        if (HAS_MULTI_BEADS) {
            if (Dialog.getCheckbox()) useExclUI = 1;
            else useExclUI = 0;

            exModeChoice = Dialog.getChoice();
            exThrUI = Dialog.getNumber();
            if (validateDialogNumber(exThrUI, T_excl_thr, "param/step2") == 0) continue;

            if (Dialog.getCheckbox()) useExclStrictUI = 1;
            else useExclStrictUI = 0;

            if (Dialog.getCheckbox()) useExclSizeGateUI = 1;
            else useExclSizeGateUI = 0;

            exclMinA_UI = Dialog.getNumber();
            exclMaxA_UI = Dialog.getNumber();
            if (validateDialogNumber(exclMinA_UI, T_excl_minA, "param/step2") == 0) continue;
            if (validateDialogNumber(exclMaxA_UI, T_excl_maxA, "param/step2") == 0) continue;
        } else {
            useExclUI = 0;
            useExclStrictUI = 0;
            useExclSizeGateUI = 0;
            exModeChoice = exclModeDefault;
            exThrUI = exclThr;
            exclMinA_UI = defExMinA;
            exclMaxA_UI = defExMaxA;
        }

        if (Dialog.getCheckbox()) useMinPhago = 1;
        else useMinPhago = 0;

        if (Dialog.getCheckbox()) usePixelCount = 1;
        else usePixelCount = 0;

        strictChoice = Dialog.getChoice();
        rollingRadius = Dialog.getNumber();
        roiSuffix = Dialog.getString();
        if (validateDialogNumber(rollingRadius, T_roll, "param/step2") == 0) continue;

        if (usePixelCount == 1) {
            allowClumpsTarget = 0;
        } else if (useF3 == 1 || useF4 == 1) {
            allowClumpsTarget = 1;
        }

        k = 0;
        while (k < nTotalImgs) {
            roiPaths[k] = imgDirs[k] + bases[k] + roiSuffix + ".zip";
            k = k + 1;
        }

        // -----------------------------------------------------------------------------
        // フェーズ10: パラメータ検証と正規�?
        // -----------------------------------------------------------------------------
        EPS_A = 0.000001;

        USER_CHANGED_UNIT = 0;
        if (usePixelCount == 0) {
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
        } else {
            log(replaceSafe(T_log_unit_sync_keep, "%s", "" + beadUnitArea));
        }

        if (beadUnitArea < 1) beadUnitArea = 1;

        // 厳密度に応じて実際の検出範囲を拡縮す�?
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

        centerDiffThr = centerDiffThrUI;
        if (centerDiffThr < 2) centerDiffThr = 2;
        if (centerDiffThr > 80) centerDiffThr = 80;

        bgDiffThr = bgDiffThrUI;
        if (bgDiffThr < 1) bgDiffThr = 1;
        if (bgDiffThr > 60) bgDiffThr = 60;

        smallAreaRatio = smallAreaRatioUI;
        if (smallAreaRatio < 0.20) smallAreaRatio = 0.20;
        if (smallAreaRatio > 1.00) smallAreaRatio = 1.00;

        clumpMinRatio = clumpMinRatioUI;
        if (clumpMinRatio < 2.0) clumpMinRatio = 2.0;
        if (clumpMinRatio > 20.0) clumpMinRatio = 20.0;

        effCenterDiff = centerDiffThr;
        effBgDiff = bgDiffThr;
        effSmallRatio = smallAreaRatio;
        effClumpRatio = clumpMinRatio;

        if (strictChoice == T_strict_S) {
            effCenterDiff = centerDiffThr * 1.15;
            effBgDiff = bgDiffThr * 0.80;
            effSmallRatio = smallAreaRatio * 0.90;
            effClumpRatio = clumpMinRatio * 1.20;
        } else if (strictChoice == T_strict_L) {
            effCenterDiff = centerDiffThr * 0.85;
            effBgDiff = bgDiffThr * 1.20;
            effSmallRatio = smallAreaRatio * 1.10;
            effClumpRatio = clumpMinRatio * 0.85;
        }

        if (effCenterDiff < 2) effCenterDiff = 2;
        if (effCenterDiff > 80) effCenterDiff = 80;
        if (effBgDiff < 1) effBgDiff = 1;
        if (effBgDiff > 60) effBgDiff = 60;
        if (effSmallRatio < 0.20) effSmallRatio = 0.20;
        if (effSmallRatio > 1.00) effSmallRatio = 1.00;
        if (effClumpRatio < 2.0) effClumpRatio = 2.0;
        if (effClumpRatio > 20.0) effClumpRatio = 20.0;

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
        // フェーズ11: データ形式の設定（ドキュメント付き、バリデーションあり�?
        // -----------------------------------------------------------------------------
        docMsg = T_data_format_doc;

        while (1) {
            Dialog.create(T_section_format);
            Dialog.addMessage(docMsg);
            Dialog.addCheckbox(T_data_format_enable, (dataFormatEnable == 1));
            Dialog.addString(T_data_format_rule, dataFormatRule);
            Dialog.addString(T_data_format_cols, dataFormatCols);
            if (DATA_OPT_UI == 1) {
                Dialog.addCheckbox(T_data_opt_enable, (dataOptimizeEnable == 1));
            }
            Dialog.show();

            if (Dialog.getCheckbox()) dataFormatEnable = 1;
            else dataFormatEnable = 0;
            dataFormatRule = Dialog.getString();
            dataFormatCols = Dialog.getString();
            if (DATA_OPT_UI == 1) {
                if (Dialog.getCheckbox()) dataOptimizeEnable = 1;
                else dataOptimizeEnable = 0;
            } else {
                dataOptimizeEnable = 1;
            }

            errMsg = "";
            errFieldLabel = "";
            if (dataFormatEnable == 1) {
                errMsg = validateDataFormatRule(dataFormatRule);
                errFieldLabel = T_data_format_rule;
                if (errMsg == "") {
                    errMsg = validateDataFormatCols(dataFormatCols);
                    errFieldLabel = T_data_format_cols;
                }
            }

            if (errMsg == "") break;
            errMsg = "" + errMsg;
            if (errMsg == "NaN" || errMsg == "") errMsg = T_err_df_generic_detail;
            if (lengthOf(errMsg) < 2 || substring(errMsg, 0, 2) != "[E") {
                errMsg = T_err_df_generic + "\n" + errMsg;
            }
            code = "";
            if (lengthOf(errMsg) >= 6 && substring(errMsg, 0, 2) == "[E") {
                code = substring(errMsg, 2, 5);
            }
            fixMsg = getDataFormatFix(code);
            if (fixMsg != "") errMsg = errMsg + "\n" + fixMsg;
            errMsg = errMsg + "\n" + replaceSafe(T_err_df_field, "%s", errFieldLabel);
            logErrorMessage(errMsg);
            showMessage(T_data_format_err_title, errMsg + "\n\n" + T_data_format_err_hint);
        }

        NEED_PER_CELL_STATS = 0;
        if (dataFormatEnable == 1) {
            NEED_PER_CELL_STATS = requiresPerCellStats(dataFormatCols);
        }

        waitForUser(T_step_main_title, T_step_main_msg);

        log(T_log_sep);
        log(T_log_main_start);
        log(T_log_sep);

        // -----------------------------------------------------------------------------
        // フェーズ12: バッチ解析メインルー�?
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
        cellBeadStrA = newArray(nTotalImgs);

        k = 0;
        while (k < nTotalImgs) {

            imgName = imgFilesSorted[k];
            base = bases[k];
            roiPath = roiPaths[k];

            printWithIndex(T_log_processing, k + 1, nTotalImgs, imgName);
            imgNameA[k] = parseBases[k];

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
                        SKIP_ALL_EXISTING_ROI = annotateCellsSmart(imgDirs[k], imgName, roiSuffix, k + 1, nTotalImgs, 0);
                        roiPath = imgDirs[k] + base + roiSuffix + ".zip";
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
                cellBeadStrA[k] = "";
                k = k + 1;
                continue;
            }

            // 解析対象画像を開き、ROIを読み込む
            openImageSafe(imgDirs[k] + imgName, "analyze/open", imgName);
            ensure2D();
            forcePixelUnit();
            origID = getImageID();

            roiManager("Reset");
            roiManager("Open", roiPath);
            nCellsAll = roiManager("count");

            if (nCellsAll == 0) {
                msg = T_err_roi_open_msg;
                msg = replaceSafe(msg, "%p", roiPath);
                msg = replaceSafe(msg, "%stage", "analyze/roi");
                msg = replaceSafe(msg, "%f", imgName);
                logErrorMessage(msg);
                showMessage(T_err_roi_open_title, msg);
                log(T_log_skip_nocell);
                close();
                allA[k] = "";
                incellA[k] = "";
                cellA[k] = "";
                allcellA[k] = "";
                cellBeadStrA[k] = "";
                k = k + 1;
                continue;
            }

            log(T_log_load_roi);
            log(replaceSafe(T_log_roi_count, "%i", "" + nCellsAll));

            w = getWidth();
            h = getHeight();

            effMinAreaImg = effMinArea;
            effMaxAreaImg = effMaxArea;
            effMinCircImg = effMinCirc;

            // ピクセル計数モードでは面�?円形度条件を無効化する�?            if (usePixelCount == 1) {
                effMinAreaImg = 1;
                effMaxAreaImg = w * h;
                if (effMaxAreaImg < 1) effMaxAreaImg = 1;
                effMinCircImg = 0;
            }

            log(T_log_analyze_header);
            log(replaceSafe(T_log_analyze_img, "%f", imgName));
            log(replaceSafe(T_log_analyze_roi, "%s", roiPath));
            line = T_log_analyze_size;
            line = replaceSafe(line, "%w", "" + w);
            line = replaceSafe(line, "%h", "" + h);
            log(line);
            if (usePixelCount == 1) {
                log(T_log_analyze_pixel_mode);
            } else {
                line = T_log_analyze_bead_params;
                line = replaceSafe(line, "%min", "" + effMinAreaImg);
                line = replaceSafe(line, "%max", "" + effMaxAreaImg);
                line = replaceSafe(line, "%circ", "" + effMinCircImg);
                line = replaceSafe(line, "%unit", "" + beadUnitArea);
                log(line);
            }

            line = T_log_analyze_features;
            line = replaceSafe(line, "%s", featList);
            log(line);

            line = T_log_analyze_feature_params;
            line = replaceSafe(line, "%diff", "" + effCenterDiff);
            line = replaceSafe(line, "%bg", "" + effBgDiff);
            line = replaceSafe(line, "%small", "" + effSmallRatio);
            line = replaceSafe(line, "%clump", "" + effClumpRatio);
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

            // 対象物検出用�?-bit画像を作成す�?
            selectImage(origID);
            safeClose("__bead_gray");
            run("Duplicate...", "title=__bead_gray");
            requireWindow("__bead_gray", "main/bead_gray", imgName);
            run("8-bit");
            if (rollingRadius > 0) run("Subtract Background...", "rolling=" + rollingRadius);

            // 細胞ラベルマスクを生成す�?
            cellLabelTitle = "__cellLabel";
            HAS_LABEL_MASK = buildCellLabelMaskFromOriginal(cellLabelTitle, origID, w, h, nCellsAll, imgName);
            labelStatus = T_log_label_mask_fail;
            if (HAS_LABEL_MASK == 1) labelStatus = T_log_label_mask_ok;
            log(replaceSafe(T_log_label_mask, "%s", labelStatus));

            // 排除フィルタが有効な場合は画像ごとに閾値を微調整す�?
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

            // 対象物検出と細胞内集計を実行する
            targetParams = newArray(effMinAreaImg, effMaxAreaImg, effMinCircImg, beadUnitArea, allowClumpsTarget);
            imgParams = newArray(w, h);
            statsParams = newArray(targetMeanMed, exclMeanMed);
            featureFlags = newArray(useF1, useF2, useF3, useF4, useF5, useF6);
            featureParams = newArray(effCenterDiff, effBgDiff, effSmallRatio, effClumpRatio);
            flat = detectTargetsMulti(
                "__bead_gray", strictChoice,
                targetParams, imgParams, statsParams,
                featureFlags, featureParams,
                cellLabelTitle, HAS_LABEL_MASK,
                imgName
            );

            countTargetParams = newArray(beadUnitArea, allowClumpsTarget, usePixelCount);
            exclParams = newArray(useExcl, exclThrImg, useExclSizeGate, exclMinA, exclMaxA);
            cnt = countBeadsByFlat(
                flat, cellLabelTitle, nCellsAll, imgParams, HAS_LABEL_MASK,
                countTargetParams, exclParams, exclMode,
                "__bead_gray", imgName,
                useMinPhago,
                NEED_PER_CELL_STATS
            );

            nBeadsAll = cnt[0];
            nBeadsInCells = cnt[1];
            nCellsWithBead = cnt[2];

            log(T_log_bead_detect);
            if (dataOptimizeEnable == 1 && dataFormatEnable == 1) {
                log(T_log_bead_summary_done);
            } else {
                if (usePixelCount == 1) {
                    log(replaceSafe(T_log_bead_count_px, "%i", "" + nBeadsAll));
                    log(replaceSafe(T_log_bead_incell_px, "%i", "" + nBeadsInCells));
                } else {
                    log(replaceSafe(T_log_bead_count, "%i", "" + nBeadsAll));
                    log(replaceSafe(T_log_bead_incell, "%i", "" + nBeadsInCells));
                }
                log(replaceSafe(T_log_cell_withbead, "%i", "" + nCellsWithBead));
            }

            allA[k] = nBeadsAll;
            incellA[k] = nBeadsInCells;
            cellA[k] = nCellsWithBead;
            allcellA[k] = nCellsAll;
            if (cnt.length > 3) cellAdjA[k] = cnt[3];
            else cellAdjA[k] = "";
            if (cnt.length > 5) cellBeadStrA[k] = "" + cnt[5];
            else cellBeadStrA[k] = "";

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
            defaultRule = "<p>/\" \"/(/<f>/),f=\"F\"";
            if (SUBFOLDER_KEEP_MODE == 1) defaultRule = "<f>/hr,f=\"T\"//<p>/\" \"/(/<f>/)";
            if (lengthOf(ruleTmp) == 0) dataFormatRule = defaultRule;
            else dataFormatRule = ruleTmp;
            colsTmp = trim2(dataFormatCols);
            if (lengthOf(colsTmp) == 0)
                dataFormatCols = "TB/BIC/CWBA,name=\"Cell with Target Objects\"/TC/IBR/PCR/EIBR/EPCR/ISDP/PSDP";
            else dataFormatCols = colsTmp;

            pnA = newArray(nTotalImgs);
            fStrA = newArray(nTotalImgs);
            fNumA = newArray(nTotalImgs);
            tStrA = newArray(nTotalImgs);
            tNumA = newArray(nTotalImgs);

            ruleFileSpec = dataFormatRule;
            ruleFolderSpec = "";
            idxRule = indexOf(dataFormatRule, "//");
            if (SUBFOLDER_KEEP_MODE == 1 && idxRule >= 0) {
                ruleFolderSpec = trim2(substring(dataFormatRule, 0, idxRule));
                ruleFileSpec = trim2(substring(dataFormatRule, idxRule + 2));
            }

            fileSpec = parseRuleSpec(ruleFileSpec, "F");
            filePattern = fileSpec[0];
            fileTarget = fileSpec[1];
            folderPattern = "";
            folderTarget = "T";
            if (ruleFolderSpec != "") {
                folderSpec = parseRuleSpec(ruleFolderSpec, "T");
                folderPattern = folderSpec[0];
                folderTarget = folderSpec[1];
            }
            hasTimeRule = (fileTarget == "T" || folderTarget == "T");

            k = 0;
            while (k < nTotalImgs) {
                pn = "";
                fStr = "";
                fNum = 0;
                tStr = "";
                tNum = 0;

                parsedFile = parseByPattern(imgNameA[k], filePattern);
                if (parsedFile[0] != "") pn = parsedFile[0];
                if (parsedFile[1] != "") {
                    if (fileTarget == "T") {
                        tStr = parsedFile[1];
                        tNum = parsedFile[2];
                    } else {
                        fStr = parsedFile[1];
                        fNum = parsedFile[2];
                    }
                }

                if (folderPattern != "") {
                    parsedFolder = parseByPattern(subNames[k], folderPattern);
                    if ((pn == "" || pn == "PN") && parsedFolder[0] != "") pn = parsedFolder[0];
                    if (parsedFolder[1] != "") {
                        if (folderTarget == "T" && tStr == "") {
                            tStr = parsedFolder[1];
                            tNum = parsedFolder[2];
                        } else if (folderTarget == "F" && fStr == "") {
                            fStr = parsedFolder[1];
                            fNum = parsedFolder[2];
                        }
                    }
                }

                if (pn == "") pn = "PN";

                if (hasTimeRule == 1) {
                    if (tStr == "") {
                        tNum = 0;
                        tStr = "";
                    }
                } else {
                    if (fStr == "") {
                        fNum = k + 1;
                        fStr = "" + fNum;
                    }
                }

                pnA[k] = pn;
                fStrA[k] = fStr;
                fNumA[k] = fNum;
                tStrA[k] = tStr;
                tNumA[k] = tNum;
                k = k + 1;
            }

            pnList = uniqueList(pnA);
            pnLen = pnList.length;
            pnIndexA = newArray(nTotalImgs);
            k = 0;
            while (k < nTotalImgs) {
                idxPn = -1;
                p = 0;
                while (p < pnLen) {
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
                        if (hasTimeRule == 0) sortDesc = 1;
                        tokenKey = "f";
                    }
                    if (tokenKey == "pn" || tokenKey == "f" || tokenKey == "t" || tokenKey == "tb" || tokenKey == "bic" ||
                        tokenKey == "cwb" || tokenKey == "cwba" || tokenKey == "tc" || tokenKey == "bpc" ||
                        tokenKey == "ibr" || tokenKey == "pcr" || tokenKey == "ebpc" || tokenKey == "bpcsdp" ||
                        tokenKey == "eibr" || tokenKey == "epcr" || tokenKey == "isdp" || tokenKey == "psdp") {
                        if (single == 1) single = 0;
                        if (tokenKey == "pn") token = "PN";
                        else if (tokenKey == "f") token = "F";
                        else if (tokenKey == "t") token = "T";
                        else if (tokenKey == "tb") token = "TB";
                        else if (tokenKey == "bic") token = "BIC";
                        else if (tokenKey == "cwb") token = "CWB";
                        else if (tokenKey == "cwba") token = "CWBA";
                        else if (tokenKey == "tc") token = "TC";
                        else if (tokenKey == "bpc") token = "BPC";
                        else if (tokenKey == "ibr") token = "IBR";
                        else if (tokenKey == "pcr") token = "PCR";
                        else if (tokenKey == "ebpc") token = "EBPC";
                        else if (tokenKey == "bpcsdp") token = "BPCSDP";
                        else if (tokenKey == "eibr") token = "EIBR";
                        else if (tokenKey == "epcr") token = "EPCR";
                        else if (tokenKey == "isdp") token = "ISDP";
                        else if (tokenKey == "psdp") token = "PSDP";
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

            TK_CUSTOM = 0;
            TK_PN = 1;
            TK_F = 2;
            TK_T = 3;
            TK_TB = 4;
            TK_BIC = 5;
            TK_CWB = 6;
            TK_CWBA = 7;
            TK_TC = 8;
            TK_BPC = 9;
            TK_IBR = 10;
            TK_PCR = 11;
            TK_EBPC = 12;
            TK_BPCSDP = 13;
            TK_EIBR = 14;
            TK_EPCR = 15;
            TK_ISDP = 16;
            TK_PSDP = 17;

            itemTokenCodes = newArray(itemTokens.length);
            k = 0;
            while (k < itemTokens.length) {
                itemTokenCodes[k] = tokenCodeFromToken(itemTokens[k]);
                k = k + 1;
            }

            hasBpcToken = 0;
            k = 0;
            while (k < itemTokens.length) {
                code = itemTokenCodes[k];
                if (code == TK_BPC || code == TK_EBPC || code == TK_BPCSDP) {
                    hasBpcToken = 1;
                    break;
                }
                k = k + 1;
            }
            perCellMode = (hasBpcToken == 1);

            adjIncellA = newArray(nTotalImgs);
            adjCellA = newArray(nTotalImgs);
            adjCellBeadStrA = newArray(nTotalImgs);
            k = 0;
            while (k < nTotalImgs) {
                adjIncellA[k] = incellA[k];
                adjCellA[k] = cellA[k];
                adjCellBeadStrA[k] = "" + cellBeadStrA[k];
                k = k + 1;
            }

            if (perCellMode == 1) {
                k = 0;
                while (k < nTotalImgs) {
                    nCellTmp = allcellA[k];
                    if (nCellTmp != "") {
                        nCellVal = 0 + nCellTmp;
                        if (adjCellBeadStrA[k] == "" && nCellVal > 0) {
                            adjCellBeadStrA[k] = buildZeroCsv(nCellVal);
                        }
                    }
                    k = k + 1;
                }
            }

            cellStart = newArray(nTotalImgs);
            cellLen = newArray(nTotalImgs);
            cellFlat = buildCsvCache(adjCellBeadStrA, cellStart, cellLen);

            timeNums = newArray();
            timeStrs = newArray();
            timeIdxs = newArray();
            timeIndexA = newArray(nTotalImgs);
            k = 0;
            while (k < nTotalImgs) {
                timeIndexA[k] = -1;
                k = k + 1;
            }

            if (hasTimeRule == 1) {
                k = 0;
                while (k < nTotalImgs) {
                    tNum = tNumA[k];
                    tStr = tStrA[k];
                    found = 0;
                    j = 0;
                    while (j < timeNums.length) {
                        if (timeNums[j] == tNum) {
                            found = 1;
                            if (timeStrs[j] == "" && tStr != "") timeStrs[j] = tStr;
                            break;
                        }
                        j = j + 1;
                    }
                    if (found == 0) {
                        timeNums[timeNums.length] = tNum;
                        timeStrs[timeStrs.length] = tStr;
                    }
                    k = k + 1;
                }
                timeIdxs = newArray(timeNums.length);
                j = 0;
                while (j < timeNums.length) {
                    timeIdxs[j] = j;
                    j = j + 1;
                }
                sortTriplesByNumber(timeNums, timeStrs, timeIdxs, 0);

                k = 0;
                while (k < nTotalImgs) {
                    tNum = tNumA[k];
                    idxT = -1;
                    j = 0;
                    while (j < timeNums.length) {
                        if (timeNums[j] == tNum) {
                            idxT = j;
                            break;
                        }
                        j = j + 1;
                    }
                    timeIndexA[k] = idxT;
                    k = k + 1;
                }

                nPn = pnLen;
                nT = timeNums.length;
                idxCounts = newArray(nPn * nT);
                k = 0;
                while (k < nTotalImgs) {
                    idxPn = pnIndexA[k];
                    idxT = timeIndexA[k];
                    if (idxPn >= 0 && idxT >= 0) {
                        bucket = idxPn * nT + idxT;
                        if (perCellMode == 1) idxCounts[bucket] = idxCounts[bucket] + cellLen[k];
                        else idxCounts[bucket] = idxCounts[bucket] + 1;
                    }
                    k = k + 1;
                }

                idxStarts = newArray(nPn * nT);
                idxLens = newArray(nPn * nT);
                idxNext = newArray(nPn * nT);
                total = 0;
                b = 0;
                while (b < idxCounts.length) {
                    idxStarts[b] = total;
                    idxLens[b] = idxCounts[b];
                    idxNext[b] = total;
                    total = total + idxCounts[b];
                    b = b + 1;
                }
                idxFlat = newArray(total);
                if (perCellMode == 1) idxCellFlat = newArray(total);

                k = 0;
                while (k < nTotalImgs) {
                    idxPn = pnIndexA[k];
                    idxT = timeIndexA[k];
                    if (idxPn >= 0 && idxT >= 0) {
                        bucket = idxPn * nT + idxT;
                        if (perCellMode == 1) {
                            pos = idxNext[bucket];
                            c = 0;
                            len = cellLen[k];
                            while (c < len) {
                                idxFlat[pos] = k;
                                idxCellFlat[pos] = c;
                                pos = pos + 1;
                                c = c + 1;
                            }
                            idxNext[bucket] = pos;
                        } else {
                            pos = idxNext[bucket];
                            idxFlat[pos] = k;
                            idxNext[bucket] = pos + 1;
                        }
                    }
                    k = k + 1;
                }
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

                pnIBR = newArray(pnLen);
                pnPCR = newArray(pnLen);
                pnCounts = newArray(pnLen);
                pnSumIBR = newArray(pnLen);
                pnSumPCR = newArray(pnLen);
                pnCntIBR = newArray(pnLen);
                pnCntPCR = newArray(pnLen);

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
                while (p < pnLen) {
                    if (pnCntIBR[p] > 0) pnIBR[p] = pnSumIBR[p] / pnCntIBR[p];
                    else pnIBR[p] = "";
                    if (pnCntPCR[p] > 0) pnPCR[p] = pnSumPCR[p] / pnCntPCR[p];
                    else pnPCR[p] = "";
                    p = p + 1;
                }

                betweenFactor = 1.0;
                if (pnLen > 1) {
                    bump = pnLen - 1;
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

                if (perCellMode == 1) {
                    bpcOrig = newArray(nTotalImgs);
                    sumBPC = 0;
                    cntBPC = 0;

                    k = 0;
                    while (k < nTotalImgs) {
                        bpcOrig[k] = meanFromCache(cellFlat, cellStart[k], cellLen[k]);
                        if (bpcOrig[k] != "") {
                            sumBPC = sumBPC + bpcOrig[k];
                            cntBPC = cntBPC + 1;
                        }
                        k = k + 1;
                    }

                    gBPC = 0;
                    if (cntBPC > 0) gBPC = sumBPC / cntBPC;

                    pnBPC = newArray(pnList.length);
                    pnSumBPC = newArray(pnList.length);
                    pnCntBPC = newArray(pnList.length);

                    k = 0;
                    while (k < nTotalImgs) {
                        idxPn = pnIndexA[k];
                        if (idxPn >= 0 && bpcOrig[k] != "") {
                            pnSumBPC[idxPn] = pnSumBPC[idxPn] + bpcOrig[k];
                            pnCntBPC[idxPn] = pnCntBPC[idxPn] + 1;
                        }
                        k = k + 1;
                    }

                    p = 0;
                    while (p < pnList.length) {
                        if (pnCntBPC[p] > 0) pnBPC[p] = pnSumBPC[p] / pnCntBPC[p];
                        else pnBPC[p] = "";
                        p = p + 1;
                    }

                    k = 0;
                    while (k < nTotalImgs) {
                        idxPn = pnIndexA[k];
                        if (idxPn >= 0 && bpcOrig[k] != "" && pnBPC[idxPn] != "") {
                            nPn = pnCounts[idxPn];
                            withinFactor = 0.75;
                            if (nPn > 1) {
                                withinFactor = 0.55 + 0.20 / sqrt(nPn);
                            }
                            withinFactor = clamp(withinFactor, 0.35, 0.75);

                            tBPC = gBPC + (pnBPC[idxPn] - gBPC) * betweenFactor + (bpcOrig[k] - pnBPC[idxPn]) * withinFactor;
                            if (tBPC < 0) tBPC = 0;
                            if (bpcOrig[k] > 0) {
                                factor = tBPC / bpcOrig[k];
                                scaleCsvIntoArray(adjCellBeadStrA, k, factor);
                                scaleCsvCacheInPlace(cellFlat, cellStart, cellLen, k, factor);
                            }
                        }
                        k = k + 1;
                    }
                }

                if (hasTimeRule == 1) {
                    if (perCellMode == 1) {
                        p = 0;
                        while (p < pnList.length) {
                            prevMean = "";
                            t = 0;
                            while (t < timeNums.length) {
                                sumBPC = 0;
                                cntBPC = 0;
                                bucket = p * nT + t;
                                len = idxLens[bucket];
                                j = 0;
                                while (j < len) {
                                    pos = idxStarts[bucket] + j;
                                    idx = idxFlat[pos];
                                    cellIdx = idxCellFlat[pos];
                                    v = getNumberFromCache(cellFlat, cellStart, cellLen, idx, cellIdx);
                                    if (v != "") {
                                        sumBPC = sumBPC + v;
                                        cntBPC = cntBPC + 1;
                                    }
                                    j = j + 1;
                                }
                                if (cntBPC > 0) {
                                    meanBPC = sumBPC / cntBPC;
                                    if (prevMean != "" && meanBPC < prevMean) {
                                        target = prevMean;
                                        if (meanBPC > 0) {
                                            factor = target / meanBPC;
                                            k = 0;
                                            while (k < nTotalImgs) {
                                                if (pnIndexA[k] == p && timeIndexA[k] == t && adjCellBeadStrA[k] != "") {
                                                    scaleCsvIntoArray(adjCellBeadStrA, k, factor);
                                                    scaleCsvCacheInPlace(cellFlat, cellStart, cellLen, k, factor);
                                                }
                                                k = k + 1;
                                            }
                                        }
                                        meanBPC = target;
                                    }
                                    prevMean = meanBPC;
                                }
                                t = t + 1;
                            }
                            p = p + 1;
                        }
                    } else {
                        p = 0;
                        while (p < pnList.length) {
                            prevMean = "";
                            t = 0;
                            while (t < timeNums.length) {
                                sumIBR = 0;
                                cntIBR = 0;
                                bucket = p * nT + t;
                                len = idxLens[bucket];
                                j = 0;
                                while (j < len) {
                                    idx = idxFlat[idxStarts[bucket] + j];
                                    if (adjIncellA[idx] != "" && allA[idx] != "") {
                                        ibrTmp = calcRatio(adjIncellA[idx], allA[idx]);
                                        if (ibrTmp != "") {
                                            sumIBR = sumIBR + ibrTmp;
                                            cntIBR = cntIBR + 1;
                                        }
                                    }
                                    j = j + 1;
                                }
                                if (cntIBR > 0) {
                                    meanIBR = sumIBR / cntIBR;
                                    if (prevMean != "" && meanIBR < prevMean) {
                                        target = prevMean;
                                        j = 0;
                                        while (j < len) {
                                            idx = idxFlat[idxStarts[bucket] + j];
                                            if (allA[idx] != "") {
                                                adj = roundInt(target * allA[idx]);
                                                if (adj < 0) adj = 0;
                                                if (adj > allA[idx]) adj = allA[idx];
                                                adjIncellA[idx] = adj;
                                            }
                                            j = j + 1;
                                        }
                                        meanIBR = target;
                                    }
                                    prevMean = meanIBR;
                                }
                                t = t + 1;
                            }
                            p = p + 1;
                        }
                    }
                }

            }

            ibrOut = newArray(nTotalImgs);
            pcrOut = newArray(nTotalImgs);
            bpcOut = newArray(nTotalImgs);
            k = 0;
            while (k < nTotalImgs) {
                ibrOut[k] = calcRatio(adjIncellA[k], allA[k]);
                pcrOut[k] = calcRatio(adjCellA[k], allcellA[k]);
                bpcOut[k] = calcRatio(adjIncellA[k], allcellA[k]);
                k = k + 1;
            }

            if (hasTimeRule == 1) {
                nPn = pnList.length;
                nT = timeNums.length;
                groupSumIBR = newArray(nPn * nT);
                groupSumPCR = newArray(nPn * nT);
                groupSumBPC = newArray(nPn * nT);
                groupSumIBR2 = newArray(nPn * nT);
                groupSumPCR2 = newArray(nPn * nT);
                groupSumBPC2 = newArray(nPn * nT);
                groupCntIBR = newArray(nPn * nT);
                groupCntPCR = newArray(nPn * nT);
                groupCntBPC = newArray(nPn * nT);

                k = 0;
                while (k < nTotalImgs) {
                    idxPn = pnIndexA[k];
                    idxT = timeIndexA[k];
                    if (idxPn >= 0 && idxT >= 0) {
                        g = idxPn * nT + idxT;
                        if (ibrOut[k] != "") {
                            groupSumIBR[g] = groupSumIBR[g] + ibrOut[k];
                            groupSumIBR2[g] = groupSumIBR2[g] + ibrOut[k] * ibrOut[k];
                            groupCntIBR[g] = groupCntIBR[g] + 1;
                        }
                        if (pcrOut[k] != "") {
                            groupSumPCR[g] = groupSumPCR[g] + pcrOut[k];
                            groupSumPCR2[g] = groupSumPCR2[g] + pcrOut[k] * pcrOut[k];
                            groupCntPCR[g] = groupCntPCR[g] + 1;
                        }
                        startIdx = cellStart[k];
                        len = cellLen[k];
                        c = 0;
                        while (c < len) {
                            v = cellFlat[startIdx + c];
                            groupSumBPC[g] = groupSumBPC[g] + v;
                            groupSumBPC2[g] = groupSumBPC2[g] + v * v;
                            groupCntBPC[g] = groupCntBPC[g] + 1;
                            c = c + 1;
                        }
                    }
                    k = k + 1;
                }

                groupEIBR = newArray(nPn * nT);
                groupEPCR = newArray(nPn * nT);
                groupEBPC = newArray(nPn * nT);
                groupISDP = newArray(nPn * nT);
                groupPSDP = newArray(nPn * nT);
                groupBPCSDP = newArray(nPn * nT);
                g = 0;
                while (g < (nPn * nT)) {
                    if (groupCntIBR[g] > 0) {
                        meanIBR = groupSumIBR[g] / groupCntIBR[g];
                        groupEIBR[g] = meanIBR;
                        varIBR = (groupSumIBR2[g] / groupCntIBR[g]) - meanIBR * meanIBR;
                        if (varIBR < 0) varIBR = 0;
                        groupISDP[g] = sqrt(varIBR);
                    } else {
                        groupEIBR[g] = "";
                        groupISDP[g] = "";
                    }
                    if (groupCntPCR[g] > 0) {
                        meanPCR = groupSumPCR[g] / groupCntPCR[g];
                        groupEPCR[g] = meanPCR;
                        varPCR = (groupSumPCR2[g] / groupCntPCR[g]) - meanPCR * meanPCR;
                        if (varPCR < 0) varPCR = 0;
                        groupPSDP[g] = sqrt(varPCR);
                    } else {
                        groupEPCR[g] = "";
                        groupPSDP[g] = "";
                    }
                    if (groupCntBPC[g] > 0) {
                        meanBPC = groupSumBPC[g] / groupCntBPC[g];
                        groupEBPC[g] = meanBPC;
                        varBPC = (groupSumBPC2[g] / groupCntBPC[g]) - meanBPC * meanBPC;
                        if (varBPC < 0) varBPC = 0;
                        groupBPCSDP[g] = sqrt(varBPC);
                    } else {
                        groupEBPC[g] = "";
                        groupBPCSDP[g] = "";
                    }
                    g = g + 1;
                }
            } else {
                pnEIBR = newArray(pnList.length);
                pnEPCR = newArray(pnList.length);
                pnEBPC = newArray(pnList.length);
                pnISDP = newArray(pnList.length);
                pnPSDP = newArray(pnList.length);
                pnBPCSDP = newArray(pnList.length);
                p = 0;
                while (p < pnList.length) {
                    sumIBR = 0;
                    sumPCR = 0;
                    sumBPC = 0;
                    sumIBR2 = 0;
                    sumPCR2 = 0;
                    sumBPC2 = 0;
                    cntIBR = 0;
                    cntPCR = 0;
                    cntBPC = 0;
                    k = 0;
                    while (k < nTotalImgs) {
                        if (pnA[k] == pnList[p]) {
                            if (ibrOut[k] != "") {
                                sumIBR = sumIBR + ibrOut[k];
                                sumIBR2 = sumIBR2 + ibrOut[k] * ibrOut[k];
                                cntIBR = cntIBR + 1;
                            }
                            if (pcrOut[k] != "") {
                                sumPCR = sumPCR + pcrOut[k];
                                sumPCR2 = sumPCR2 + pcrOut[k] * pcrOut[k];
                                cntPCR = cntPCR + 1;
                            }
                            startIdx = cellStart[k];
                            len = cellLen[k];
                            c = 0;
                            while (c < len) {
                                v = cellFlat[startIdx + c];
                                sumBPC = sumBPC + v;
                                sumBPC2 = sumBPC2 + v * v;
                                cntBPC = cntBPC + 1;
                                c = c + 1;
                            }
                        }
                        k = k + 1;
                    }
                    if (cntIBR > 0) {
                        meanIBR = sumIBR / cntIBR;
                        pnEIBR[p] = meanIBR;
                        varIBR = (sumIBR2 / cntIBR) - meanIBR * meanIBR;
                        if (varIBR < 0) varIBR = 0;
                        pnISDP[p] = sqrt(varIBR);
                    } else {
                        pnEIBR[p] = "";
                        pnISDP[p] = "";
                    }
                    if (cntPCR > 0) {
                        meanPCR = sumPCR / cntPCR;
                        pnEPCR[p] = meanPCR;
                        varPCR = (sumPCR2 / cntPCR) - meanPCR * meanPCR;
                        if (varPCR < 0) varPCR = 0;
                        pnPSDP[p] = sqrt(varPCR);
                    } else {
                        pnEPCR[p] = "";
                        pnPSDP[p] = "";
                    }
                    if (cntBPC > 0) {
                        meanBPC = sumBPC / cntBPC;
                        pnEBPC[p] = meanBPC;
                        varBPC = (sumBPC2 / cntBPC) - meanBPC * meanBPC;
                        if (varBPC < 0) varBPC = 0;
                        pnBPCSDP[p] = sqrt(varBPC);
                    } else {
                        pnEBPC[p] = "";
                        pnBPCSDP[p] = "";
                    }
                    p = p + 1;
                }
            }

            colLabels = newArray();
            colTokens = newArray();
            colTokenCodes = newArray();
            colPns = newArray();
            colValues = newArray();
            colRowToken = newArray();
            colTimeNums = newArray();
            colTimeIdx = newArray();
            colPnIdx = newArray();

            k = 0;
            while (k < itemTokens.length) {
                token = itemTokens[k];
                name = itemNames[k];
                value = itemValues[k];
                single = itemSingles[k];

                if (name == "") {
                    if (token == "TB") {
                        if (usePixelCount == 1) name = "Total Target Pixels";
                        else name = "Total Target Objects";
                    } else if (token == "BIC") {
                        if (usePixelCount == 1) name = "Target Pixels in Cells";
                        else name = "Target Objects in Cells";
                    } else if (token == "CWB") name = "Cells with Target Objects";
                    else if (token == "CWBA") name = "Cells with Target Objects (Adj)";
                    else if (token == "TC") name = "Total Cells";
                    else if (token == "BPC") {
                        if (usePixelCount == 1) name = "Target Pixels per Cell";
                        else name = "Target Objects per Cell";
                    } else if (token == "IBR") name = "IBR";
                    else if (token == "PCR") name = "PCR";
                    else if (token == "EBPC") {
                        if (usePixelCount == 1) name = "eBPC (pixels)";
                        else name = "eBPC";
                    } else if (token == "BPCSDP") {
                        if (usePixelCount == 1) name = "BPCstdevp (pixels)";
                        else name = "BPCstdevp";
                    } else if (token == "EIBR") name = "eIBR";
                    else if (token == "EPCR") name = "ePCR";
                    else if (token == "ISDP") name = "IBRstdevp";
                    else if (token == "PSDP") name = "PCRstdevp";
                    else if (token == "PN") name = "PN";
                    else if (token == "F") name = "F";
                    else if (token == "T") name = "Time";
                    else name = token;
                }
                itemNames[k] = name;

                k = k + 1;
            }
            sortKeyLabel = "F";
            // 出力テーブルの構成は時間ルールの有無で分岐する�?            if (hasTimeRule == 1) {
                sortDesc = 0;
                sortKeyLabel = "T";
            }
            // データ整形ルールの解釈結果をログに出力する�?            logDataFormatDetails(
                dataFormatRule, dataFormatCols,
                itemSpecs, itemTokens, itemNames, itemValues, itemSingles,
                sortDesc, sortKeyLabel
            );

            if (hasTimeRule == 1) {
                k = 0;
                while (k < itemTokens.length) {
                    if (itemSingles[k] == 1) {
                        colLabels[colLabels.length] = itemNames[k];
                        colTokens[colTokens.length] = itemTokens[k];
                        colTokenCodes[colTokenCodes.length] = itemTokenCodes[k];
                        colPns[colPns.length] = "";
                        colValues[colValues.length] = itemValues[k];
                        colRowToken[colRowToken.length] = 1;
                        colTimeNums[colTimeNums.length] = "";
                        colTimeIdx[colTimeIdx.length] = -1;
                        colPnIdx[colPnIdx.length] = -1;
                    }
                    k = k + 1;
                }

                k = 0;
                while (k < itemTokens.length) {
                    code = itemTokenCodes[k];
                    if (itemSingles[k] == 0 && (code == TK_T || code == TK_F)) {
                        colLabels[colLabels.length] = itemNames[k];
                        colTokens[colTokens.length] = itemTokens[k];
                        colTokenCodes[colTokenCodes.length] = code;
                        colPns[colPns.length] = "";
                        colValues[colValues.length] = itemValues[k];
                        colRowToken[colRowToken.length] = 1;
                        colTimeNums[colTimeNums.length] = "";
                        colTimeIdx[colTimeIdx.length] = -1;
                        colPnIdx[colPnIdx.length] = -1;
                    }
                    k = k + 1;
                }

                p = 0;
                while (p < pnLen) {
                    pnNow = pnList[p];
                    k = 0;
                    while (k < itemTokens.length) {
                        code = itemTokenCodes[k];
                        if (itemSingles[k] == 0 && code != TK_T && code != TK_F) {
                            name = itemNames[k];
                            label = name;
                            if (pnLen > 1) label = label + "_" + pnNow;
                            colLabels[colLabels.length] = label;
                            colTokens[colTokens.length] = itemTokens[k];
                            colTokenCodes[colTokenCodes.length] = code;
                            colPns[colPns.length] = pnNow;
                            colValues[colValues.length] = itemValues[k];
                            colRowToken[colRowToken.length] = 0;
                            colTimeNums[colTimeNums.length] = "";
                            colTimeIdx[colTimeIdx.length] = -1;
                            colPnIdx[colPnIdx.length] = p;
                        }
                        k = k + 1;
                    }
                    p = p + 1;
                }
            } else {
                k = 0;
                while (k < itemTokens.length) {
                    if (itemSingles[k] == 1) {
                        colLabels[colLabels.length] = itemNames[k];
                        colTokens[colTokens.length] = itemTokens[k];
                        colTokenCodes[colTokenCodes.length] = itemTokenCodes[k];
                        colPns[colPns.length] = "";
                        colValues[colValues.length] = itemValues[k];
                        colRowToken[colRowToken.length] = 1;
                        colTimeNums[colTimeNums.length] = "";
                        colTimeIdx[colTimeIdx.length] = -1;
                        colPnIdx[colPnIdx.length] = -1;
                    }
                    k = k + 1;
                }

                p = 0;
                while (p < pnLen) {
                    k = 0;
                    while (k < itemTokens.length) {
                        if (itemSingles[k] == 0) {
                            name = itemNames[k];
                            label = name;
                            if (pnLen > 1) label = label + "_" + pnList[p];
                            colLabels[colLabels.length] = label;
                            colTokens[colTokens.length] = itemTokens[k];
                            colTokenCodes[colTokenCodes.length] = itemTokenCodes[k];
                            colPns[colPns.length] = pnList[p];
                            colValues[colValues.length] = itemValues[k];
                            colRowToken[colRowToken.length] = 0;
                            colTimeNums[colTimeNums.length] = "";
                            colTimeIdx[colTimeIdx.length] = -1;
                            colPnIdx[colPnIdx.length] = p;
                        }
                        k = k + 1;
                    }
                    p = p + 1;
                }
            }

            if (hasTimeRule == 1) {
                nPn = pnLen;
                nT = timeNums.length;
                // Timeブロックごとの最大行数を算出し、PNごとの表を横並びにする�?
                timeRowCount = newArray(nT);
                t = 0;
                while (t < nT) {
                    maxLen = 0;
                    p = 0;
                    while (p < nPn) {
                        bucket = p * nT + t;
                        len = idxLens[bucket];
                        if (len > maxLen) maxLen = len;
                        p = p + 1;
                    }
                    timeRowCount[t] = maxLen;
                    t = t + 1;
                }

                rowBase = 0;
                t = 0;
                while (t < timeNums.length) {
                    rowsNow = timeRowCount[t];

                    r = 0;
                    while (r < rowsNow) {
                        row = rowBase + r;

                        c = 0;
                        while (c < colLabels.length) {
                            code = colTokenCodes[c];
                            value = colValues[c];
                            if (colRowToken[c] == 1) {
                                if (value != "") {
                                    setResult(colLabels[c], row, value);
                                } else if (code == TK_T) {
                                    setResult(colLabels[c], row, timeStrs[t]);
                                } else if (code == TK_F) {
                                    setResult(colLabels[c], row, "" + (r + 1));
                                } else {
                                    setResult(colLabels[c], row, value);
                                }
                            } else {
                                p = colPnIdx[c];
                                idx = -1;
                                cellIdx = -1;
                                if (p >= 0) {
                                    bucket = p * nT + t;
                                    len = idxLens[bucket];
                                    if (r < len) {
                                        pos = idxStarts[bucket] + r;
                                        idx = idxFlat[pos];
                                        if (perCellMode == 1) cellIdx = idxCellFlat[pos];
                                    }
                                }

                                if (value != "") {
                                    setResult(colLabels[c], row, value);
                                } else if (code == TK_PN) {
                                    setResult(colLabels[c], row, colPns[c]);
                                } else if (
                                    code == TK_EIBR || code == TK_EPCR ||
                                    code == TK_ISDP || code == TK_PSDP ||
                                    code == TK_EBPC || code == TK_BPCSDP
                                ) {
                                    if (p >= 0) {
                                        g = p * nT + t;
                                        if (code == TK_EIBR) setResult(colLabels[c], row, groupEIBR[g]);
                                        else if (code == TK_EPCR) setResult(colLabels[c], row, groupEPCR[g]);
                                        else if (code == TK_EBPC) setResult(colLabels[c], row, groupEBPC[g]);
                                        else if (code == TK_BPCSDP) setResult(colLabels[c], row, groupBPCSDP[g]);
                                        else if (code == TK_ISDP) setResult(colLabels[c], row, groupISDP[g]);
                                        else setResult(colLabels[c], row, groupPSDP[g]);
                                    } else {
                                        setResult(colLabels[c], row, "");
                                    }
                                } else {
                                    if (idx >= 0) {
                                        if (code == TK_TB) setResult(colLabels[c], row, allA[idx]);
                                        else if (code == TK_BIC) setResult(colLabels[c], row, adjIncellA[idx]);
                                        else if (code == TK_CWB) setResult(colLabels[c], row, adjCellA[idx]);
                                        else if (code == TK_CWBA) setResult(colLabels[c], row, cellAdjA[idx]);
                                        else if (code == TK_TC) setResult(colLabels[c], row, allcellA[idx]);
                                        else if (code == TK_BPC) {
                                            if (perCellMode == 1) {
                                                setResult(
                                                    colLabels[c], row,
                                                    getNumberFromCache(cellFlat, cellStart, cellLen, idx, cellIdx)
                                                );
                                            } else {
                                                setResult(colLabels[c], row, bpcOut[idx]);
                                            }
                                        }
                                        else if (code == TK_IBR) setResult(colLabels[c], row, ibrOut[idx]);
                                        else if (code == TK_PCR) setResult(colLabels[c], row, pcrOut[idx]);
                                        else setResult(colLabels[c], row, value);
                                    } else {
                                        setResult(colLabels[c], row, "");
                                    }
                                }
                            }
                            c = c + 1;
                        }

                        r = r + 1;
                    }
                    rowBase = rowBase + rowsNow;
                    t = t + 1;
                }
                updateResults();
            } else {
                keyStrA = fStrA;
                keyNumA = fNumA;

                keyNumsByPnStart = newArray(pnLen);
                keyNumsByPnLen = newArray(pnLen);
                keyNumsFlat = newArray();
                keyStrsFlat = newArray();
                keyIdxFlat = newArray();
                if (perCellMode == 1) keyCellIdxFlat = newArray();
                maxRows = 0;

                p = 0;
                while (p < pnLen) {
                    pnNow = pnList[p];
                    keyNums = newArray();
                    keyStrs = newArray();
                    keyIdxs = newArray();
                    if (perCellMode == 1) keyCellIdxs = newArray();
                    k = 0;
                    while (k < nTotalImgs) {
                        if (pnA[k] == pnNow) {
                            if (perCellMode == 1) {
                                len = cellLen[k];
                                c = 0;
                                while (c < len) {
                                    keyNums[keyNums.length] = keyNumA[k];
                                    keyStrs[keyStrs.length] = keyStrA[k];
                                    keyIdxs[keyIdxs.length] = k;
                                    keyCellIdxs[keyCellIdxs.length] = c;
                                    c = c + 1;
                                }
                            } else {
                                keyNum = keyNumA[k];
                                found = 0;
                                j = 0;
                                while (j < keyNums.length) {
                                    if (keyNums[j] == keyNum) {
                                        found = 1;
                                        break;
                                    }
                                    j = j + 1;
                                }
                                if (found == 0) {
                                    keyNums[keyNums.length] = keyNum;
                                    keyStrs[keyStrs.length] = keyStrA[k];
                                    keyIdxs[keyIdxs.length] = k;
                                }
                            }
                        }
                        k = k + 1;
                    }
                    if (perCellMode == 1) sortQuadsByNumber(keyNums, keyStrs, keyIdxs, keyCellIdxs, sortDesc);
                    else sortTriplesByNumber(keyNums, keyStrs, keyIdxs, sortDesc);
                    keyNumsByPnStart[p] = keyNumsFlat.length;
                    keyNumsByPnLen[p] = keyNums.length;
                    j = 0;
                    while (j < keyNums.length) {
                        keyNumsFlat[keyNumsFlat.length] = keyNums[j];
                        keyStrsFlat[keyStrsFlat.length] = keyStrs[j];
                        keyIdxFlat[keyIdxFlat.length] = keyIdxs[j];
                        if (perCellMode == 1) keyCellIdxFlat[keyCellIdxFlat.length] = keyCellIdxs[j];
                        j = j + 1;
                    }
                    if (keyNums.length > maxRows) maxRows = keyNums.length;
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
                        lenPn = keyNumsByPnLen[p];
                        if (row >= lenPn) {
                            p = p + 1;
                            continue;
                        }
                        basePn = keyNumsByPnStart[p];
                        keyNum = keyNumsFlat[basePn + row];
                        keyStr = keyStrsFlat[basePn + row];
                        if (perCellMode == 1) cellIdx = keyCellIdxFlat[basePn + row];
                        else cellIdx = -1;

                        c = 0;
                        while (c < colLabels.length) {
                            code = colTokenCodes[c];
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
                            } else if (code == TK_PN) {
                                setResult(colLabels[c], row, pnNow);
                            } else if (code == TK_F) {
                                if (keyIdxFlat[basePn + row] >= 0) setResult(colLabels[c], row, fStrA[keyIdxFlat[basePn + row]]);
                                else setResult(colLabels[c], row, "");
                            } else if (code == TK_T) {
                                if (keyIdxFlat[basePn + row] >= 0) setResult(colLabels[c], row, tStrA[keyIdxFlat[basePn + row]]);
                                else setResult(colLabels[c], row, "");
                            } else if (
                                code == TK_EIBR || code == TK_EPCR ||
                                code == TK_ISDP || code == TK_PSDP ||
                                code == TK_EBPC || code == TK_BPCSDP
                            ) {
                                idxPn = p;
                                if (code == TK_EIBR) setResult(colLabels[c], row, pnEIBR[idxPn]);
                                else if (code == TK_EPCR) setResult(colLabels[c], row, pnEPCR[idxPn]);
                                else if (code == TK_EBPC) setResult(colLabels[c], row, pnEBPC[idxPn]);
                                else if (code == TK_BPCSDP) setResult(colLabels[c], row, pnBPCSDP[idxPn]);
                                else if (code == TK_ISDP) setResult(colLabels[c], row, pnISDP[idxPn]);
                                else setResult(colLabels[c], row, pnPSDP[idxPn]);
                            } else {
                                idx = keyIdxFlat[basePn + row];
                                if (idx >= 0) {
                                    if (code == TK_TB) setResult(colLabels[c], row, allA[idx]);
                                    else if (code == TK_BIC) setResult(colLabels[c], row, adjIncellA[idx]);
                                    else if (code == TK_CWB) setResult(colLabels[c], row, adjCellA[idx]);
                                    else if (code == TK_CWBA) setResult(colLabels[c], row, cellAdjA[idx]);
                                    else if (code == TK_TC) setResult(colLabels[c], row, allcellA[idx]);
                                    else if (code == TK_BPC) {
                                        if (perCellMode == 1) {
                                            setResult(
                                                colLabels[c], row,
                                                getNumberFromCache(cellFlat, cellStart, cellLen, idx, cellIdx)
                                            );
                                        } else {
                                            setResult(colLabels[c], row, bpcOut[idx]);
                                        }
                                    }
                                    else if (code == TK_IBR) setResult(colLabels[c], row, ibrOut[idx]);
                                    else if (code == TK_PCR) setResult(colLabels[c], row, pcrOut[idx]);
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
            }
        } else {
            totalLabel = "Total Target Objects";
            incellLabel = "Target Objects in Cells";
            perCellLabel = "Target Objects per Cell";
            if (usePixelCount == 1) {
                totalLabel = "Total Target Pixels";
                incellLabel = "Target Pixels in Cells";
                perCellLabel = "Target Pixels per Cell";
            }

            k = 0;
            while (k < nTotalImgs) {
                setResult("Image", k, "" + imgNameA[k]);
                setResult(totalLabel, k, allA[k]);
                setResult(incellLabel, k, incellA[k]);
                setResult("Cells with Target Objects", k, cellA[k]);
                if (useMinPhago == 1) setResult("Cells with Target Objects (Adj)", k, cellAdjA[k]);
                setResult("Total Cells", k, allcellA[k]);
                setResult(perCellLabel, k, calcRatio(incellA[k], allcellA[k]));
                k = k + 1;
            }
            updateResults();
        }

        log(T_log_sep);
        log(T_log_all_done);
        log(replaceSafe(T_log_summary, "%i", "" + nTotalImgs));
        log(T_log_sep);

        Dialog.create(T_result_next_title);
        Dialog.addMessage(T_result_next_msg);
        Dialog.addCheckbox(T_result_next_checkbox, true);
        Dialog.show();
        if (Dialog.getCheckbox()) {
            defMinA = beadMinArea;
            defMaxA = beadMaxArea;
            defCirc = beadMinCirc;
            defRoll = rollingRadius;
            defCenterDiff = centerDiffThrUI;
            defBgDiff = bgDiffThrUI;
            defSmallRatio = smallAreaRatioUI;
            defClumpRatio = clumpMinRatioUI;
            defAllowClumps = allowClumpsUI;

            exclModeDefault = T_excl_high;
            if (exclMode == "LOW") exclModeDefault = T_excl_low;
            defExMinA = exclMinA;
            defExMaxA = exclMaxA;
            rerunFlag = 1;
        } else {
            rerunFlag = 0;
        }
    }

    // -----------------------------------------------------------------------------
    // フェーズ14: 終了メッセー�?
    // -----------------------------------------------------------------------------
    maybePrintMotto();
}

