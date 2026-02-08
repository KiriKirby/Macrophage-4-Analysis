// =============================================================================
// Batch X40 Green Scale Bar
// =============================================================================
// Purpose: Recursively add a green scale bar to all images in a folder.
// Notes:
// - Uses current image calibration for scale bar units.
// - If calibration is missing, uses user-provided microns-per-pixel.
// - Overwrites the original files after drawing.
// =============================================================================

macro "Batch X40 Scale Bar" {
    inputDir = getDirectory("Select a folder with images");
    if (inputDir == "") {
        exit();
    }

    Dialog.create("X40 Scale Bar");
    Dialog.addMessage("Scale bar length is auto-calculated from image size.\nIf calibration is missing, microns-per-pixel is used.");
    Dialog.addNumber("Microns per pixel (used if no calibration)", 0.1);
    Dialog.addChoice("Scale bar location", newArray("Lower Right", "Lower Left", "Upper Right", "Upper Left"), "Lower Right");
    Dialog.show();

    umPerPxFallback = Dialog.getNumber();
    barLoc = Dialog.getChoice();

    imgPaths = collectImagesRecursive(inputDir);
    if (imgPaths.length == 0) {
        exit();
    }

    for (i = 0; i < imgPaths.length; i++) {
        path = imgPaths[i];
        open(path);
        title = getTitle();

        drawAutoScaleBar(barLoc, umPerPxFallback);

        saveAs(getSaveFormat(path), path);

        close();
    }

    showMessage("Done", "Processing finished.");
}

// -----------------------------------------------------------------------------
// 関数: collectImagesRecursive
// 概要: フォルダ内の画像パスを再帰的に収集する。
// 引数: dir (string)
// 戻り値: 画像パス配列 (array)
// -----------------------------------------------------------------------------
function collectImagesRecursive(dir) {
    list = getFileList(dir);
    paths = newArray(0);
    for (i = 0; i < list.length; i++) {
        name = list[i];
        full = dir + name;
        if (endsWith(name, "/")) {
            sub = collectImagesRecursive(full);
            if (sub.length > 0) {
                paths = Array.concat(paths, sub);
            }
        } else {
            if (isImageFile(name)) {
                paths = Array.concat(paths, newArray(full));
            }
        }
    }
    return paths;
}

// -----------------------------------------------------------------------------
// 関数: isImageFile
// 概要: 拡張子で画像ファイルかどうかを判定する。
// 引数: name (string)
// 戻り値: 1/0
// -----------------------------------------------------------------------------
function isImageFile(name) {
    lower = toLowerCase(name);
    if (endsWith(lower, ".tif")) return 1;
    if (endsWith(lower, ".tiff")) return 1;
    if (endsWith(lower, ".png")) return 1;
    if (endsWith(lower, ".jpg")) return 1;
    if (endsWith(lower, ".jpeg")) return 1;
    if (endsWith(lower, ".bmp")) return 1;
    if (endsWith(lower, ".gif")) return 1;
    return 0;
}

// -----------------------------------------------------------------------------
// 関数: drawAutoScaleBar
// 概要: 画像サイズからスケールバーと文字を自動配置する。
// 引数: location (string), umPerPxFallback (number)
// 戻り値: なし
// -----------------------------------------------------------------------------
function drawAutoScaleBar(location, umPerPxFallback) {
    w = getWidth();
    h = getHeight();

    getPixelSize(unit, pw, ph, pd);
    if (lengthOf(unit) == 0 || pw == 0) {
        unit = "micron";
        pw = umPerPxFallback;
    }

    unit = normalizeUnit(unit);
    if (unit == "in") {
        pw = pw * 25400;
        unit = "um";
    } else if (unit == "mm") {
        pw = pw * 1000;
        unit = "um";
    } else if (unit == "cm") {
        pw = pw * 10000;
        unit = "um";
    } else if (unit == "micron") {
        unit = "um";
    }

    barLenUnitFixed = 50;
    barLenPx = max2(20, round(barLenUnitFixed / pw));
    barHeightPx = max2(4, round(h * 0.02));
    margin = max2(10, round(w * 0.02));
    fontSize = max2(12, round(h * 0.03));

    barLenUnit = barLenUnitFixed;
    barLenLabel = "" + barLenUnitFixed + " " + unit;

    if (indexOf(location, "Lower") != -1) {
        y0 = h - margin;
    } else {
        y0 = margin + barHeightPx;
    }

    if (indexOf(location, "Right") != -1) {
        x0 = w - margin - barLenPx;
    } else {
        x0 = margin;
    }

    setColor("green");
    setLineWidth(barHeightPx);
    makeLine(x0, y0, x0 + barLenPx, y0);
    run("Draw");

    setFont("SansSerif", fontSize, "bold");
    textX = x0;
    if (startsWith(location, "Lower")) {
        textY = y0 - max2(4, round(fontSize * 0.3));
    } else {
        textY = y0 + max2(4, round(fontSize * 1.2));
    }
    drawString(barLenLabel, textX, textY);
}

// 関数: formatScaleLength
// 概要: スケールバー表示文字列を作成する。
// 引数: len (number), unit (string)
// 戻り値: string
// -----------------------------------------------------------------------------
function formatScaleLength(len, unit) {
    if (unit == "pixel") {
        unit = "px";
    }

    if (len >= 10) {
        val = round(len);
        return "" + val + " " + unit;
    }
    if (len >= 1) {
        val = round(len * 10) / 10;
        return "" + val + " " + unit;
    }
    val = round(len * 100) / 100;
    return "" + val + " " + unit;
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
// 関数: normalizeUnit
// 概要: 単位文字列を正規化する。
// 引数: unit (string)
// 戻り値: string
// -----------------------------------------------------------------------------
function normalizeUnit(unit) {
    lower = toLowerCase(unit);
    if (lower == "inch") return "in";
    if (lower == "inches") return "in";
    if (lower == "mm") return "mm";
    if (lower == "cm") return "cm";
    if (lower == "um") return "um";
    if (lower == "micron") return "micron";
    if (lower == "microns") return "micron";
    if (lower == "pixel") return "pixel";
    if (lower == "pixels") return "pixel";
    return lower;
}

// -----------------------------------------------------------------------------
// 関数: getSaveFormat
// 概要: 既存拡張子に合わせた保存形式名を返す。
// 引数: path (string)
// 戻り値: string
// -----------------------------------------------------------------------------
function getSaveFormat(path) {
    lower = toLowerCase(path);
    if (endsWith(lower, ".tif")) return "Tiff";
    if (endsWith(lower, ".tiff")) return "Tiff";
    if (endsWith(lower, ".png")) return "PNG";
    if (endsWith(lower, ".jpg")) return "Jpeg";
    if (endsWith(lower, ".jpeg")) return "Jpeg";
    if (endsWith(lower, ".bmp")) return "BMP";
    if (endsWith(lower, ".gif")) return "Gif";
    return "Tiff";
}

