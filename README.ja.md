AI編集時の注意：変更前に本リポジトリの `AGENTS.md` を必ず確認してください。
# マクロファージ画像4要素解析
言語： [中文](README.zh-CN.md) | [English](README.en.md) | [日本語](README.ja.md)

Fiji 専用の ImageJ マクロで、マクロファージ画像中の対象物（beads）を半自動で定量します。ROI 標注、サンプリング、検出、出力までを対話式で実行します。

主な機能
- 細胞 ROI 標注と検証、ラベルマスクによる高速判定
- 対象物サンプリングによる面積スケール、コントラスト閾値、背景補正の推定
- 二系統の円形検出（閾値 + エッジ）と厳密度ポリシー
- 塊検出と面積ベースの数推定
- 排除フィルタ（灰度閾値 + 面積ゲート）
- 四要素統計と微量貪食の補正
- PN/F/T 解析、単細胞展開

## 概要
- 主スクリプト：`Macrophage Image Four-Factor Analysis_3.0.0.ijm`
- 特徴参照画像：`sample.png`
- 実行環境：Fiji 専用（ImageJ 単体では動作しません）。
- 対応形式：tif/tiff/png/jpg/jpeg

## クイックスタート
推奨実行方法（非英語文字化けを回避）：
1. Fiji を起動。
2. `Macrophage Image Four-Factor Analysis_3.0.0.ijm` を Fiji にドラッグ＆ドロップ。
3. Macro Editor が開いたら Run。

## 四要素モデルと主要指標
「四要素」は画像ごとの計数値です：
- TB：対象物総数（塊推定を有効化した場合は推定数）。
- BIC：細胞内対象物数（塊推定を有効化した場合は推定数）。
- CWB：対象物を含む細胞数。
- TC：細胞数（ROI 数）。

派生指標：
- CWBA：微量貪食補正後の CWB（任意）。
- IBR = BIC / TB
- PCR = CWB / TC
- BPC = BIC / TC（細胞あたり平均対象物数）

フォーマット出力の要約指標：
- eIBR/ePCR/eBPC：PN（時間解析時は PN+時間）での平均値。
- ISDP/PSDP/BPCSDP：同一グループ内の比率の母標準偏差。

## ワークフロー（フェーズ）
1. 言語選択。
2. モード選択：ROI のみ、解析のみ、標注＋解析。
3. フォルダ選択（ファイルモードまたはサブフォルダモード）。
4. 細胞 ROI 標注（必要時）。
5. 対象物サンプリング。
6. 排除サンプリング（任意）。
7. パラメータ推定と確認。
8. バッチ解析と結果出力。

## 画像処理の原理と実装（詳細）

### 1）サンプリングと推定
対象物サンプリングは 8-bit コピー画像上で行います。
各サンプル ROI で記録するもの：
- 面積と平均濃度。
- 局所コントラスト指標：
  - centerMean：ROI 中心 3x3 平均。
  - ringMean：半径 0.75r 上の 8 点平均。
  - outerMean：半径 1.35r 上の 8 点平均。
  - centerDiff = centerMean - ringMean
  - bgDiff = abs(((centerMean + ringMean)/2) - outerMean)

円形サンプルと塊サンプルの判定：
- ROI が楕円または矩形で、縦横比 <= 1.6 の場合は円形サンプル。
- 非円形または極端に細長い ROI は塊サンプル。
- 細胞 ROI がある場合は細胞内判定を行う：
  - ROI 内を粗いグリッドでサンプリング。
  - >= 30% が細胞ラベルマスクに重なれば細胞内サンプル。

面積範囲のロバスト推定（estimateAreaRangeSafe）：
- サンプル < 3：中央値 m、min = 0.45*m、max = 2.50*m。
- サンプル >= 3：5-95% を採用し q10/q90/q25/q75/IQR を算出。
- padding = max(IQR*1.20, m*0.35)
- marginFactor = 1.60（n < 6）、1.35（n < 15）、それ以外は 1.15
- minA = floor((q10 - padding) / marginFactor)
- maxA = ceil((q90 + padding) * marginFactor)
- maxA は max(20*m, 6*q90) で上限制御。

Rolling Ball 推定：
- unitArea = 対象物面積の中央値。
- 直径 d = 2*sqrt(unitArea/PI)
- 半径 = round(d*10)（d < 8）、round(d*7)（d < 20）、それ以外は round(d*5)
- [20, 220] にクランプ。

特徴閾値の推定：
- centerDiffThr = abs(centerDiff) の 70% 分位（[6, 40]）。
- bgDiffThr = abs(bgDiff) の 50% 分位（[4, 30]）。
- smallAreaRatio = clamp(q25/median, 0.45, 0.90)。
- clumpMinRatio = clumpArea/unitArea の 25% 分位（[2.5, 20]）。

サンプリングのヒューリスティックとフィルタ：
- 円形サンプルの面積上限：円形サンプルが 3 件以上ある場合、area <= 3.0 * median の円形サンプルのみを対象面積推定に使用。
- 塊サンプル判定：ROI が非円形、または area >= unitArea * 2.5 の場合は塊サンプルとみなす。
- 排除サイズ推定のフィルタ：排除サンプリングでは area < unitAreaGuess * 20 の ROI のみをサイズ推定に使用（unitAreaGuess は対象面積の代表値。サンプル不足時はデフォルト中点）。

### 2）対象物特徴（F1-F6）
特徴の意味（参照画像に対応）：
- F1：中心が明るく外周が暗い円形（反射型）
- F2：中間濃度で内外差が小さい円形
- F3：対象物が集まった暗い塊（面積で数推定）
- F4：細胞内の高密度・不均一領域（細胞内限定、面積推定）
- F5：中心が暗く外周が明るい円形（コントラスト型）
- F6：低コントラストかつ小型の円形（細胞濃度に近い）

ルール：
- F4 は細胞内のみ（細胞 ROI と重なる必要あり）。
- F1 と F5 は同時選択不可。
- 選択した特徴が表示される閾値パラメータを決定。

### 3）画像ごとの前処理
各画像で：
- 2D 化（Z スタックなら 1 枚目）、ピクセル単位固定。
- 8-bit へ複製して検出とサンプリングに使用。
- 必要に応じて Rolling Ball で背景補正。

### 4）円形対象物検出（F1/F2/F5/F6）
二系統で円形候補を抽出。

閾値極性の選択：
- 目標/排除の中央値がある場合：
  - targetMedian <= exclusionMedian なら DARK、それ以外は LIGHT。
- targetMedian のみ利用可能：
  - 画像平均との比較で DARK/LIGHT を決定。
- F1 のみ選択時は DARK、F5 のみ選択時は LIGHT を強制。

経路 A：Yen 閾値
1. 中値フィルタ（radius=1、Loose を除く）。
2. 自動閾値（Yen dark/light/auto）。
3. 二値化して穴埋め。
4. 開演算（Strict は 2 回）。
5. Strict で Watershed。
6. Analyze Particles（面積と円形度で抽出）。

経路 B：エッジ + Otsu
1. Find Edges。
2. 自動閾値（Otsu dark/light/auto）。
3. 二値化して穴埋め。
4. 開演算（Loose を除く）。
5. Strict で Watershed。
6. Analyze Particles（面積と円形度で抽出）。

融合と重複排除：
- mergeDist = max(2, 0.8 * sqrt(unitArea/PI))。
- mergeDist 内は統合し、面積が大きい方を残す。
- Strict は以下のみ残す：
  - 両経路で検出された候補、または
  - 面積 >= 1.25 * unitArea の候補。
- Normal は両経路の和集合、Loose は最小限のフィルタ。

### 5）円形候補の特徴判定
各候補について：
- r = sqrt(area/PI)
- サンプリングと同様に centerDiff/bgDiff を計算。
- 判定ロジック：
  - abs(centerDiff) >= centerDiffThr の場合：
    - centerDiff >= thr かつ F1 有効 -> 保持（F1）
    - centerDiff <= -thr かつ F5 有効 -> 保持（F5）
  - それ以外：
    - isSmall：area <= unitArea * smallAreaRatio
    - isBgLike：bgDiff <= bgDiffThr
    - F6 有効かつ (isSmall または isBgLike) -> 保持（F6）
    - それ以外で F2 有効なら保持（F2）

### 6）塊検出（F3/F4）
塊候補はマスクから抽出。

F3：暗い塊マスク
- 中値フィルタ（Loose を除く）。
- Yen dark で二値化し穴埋め。
- 開演算：Strict は 2 回、Normal は 1 回、Loose は無し。

F4：細胞内塊マスク
- 細胞ラベルマスクが必要。
- 灰度画像に分散フィルタを適用：
  - varRadius = round(0.45 * sqrt(unitArea/PI))、1..6 に制限
  - Strict +1、Loose -1
- 8-bit 化し Otsu light で閾値化、穴埋め。
- Strict で開演算。
- 細胞マスクと AND して細胞内のみ残す。

統合と検出：
- F3 と F4 を同時に使う場合は OR で統合。
- Analyze Particles により塊検出：
  - min area = unitArea * clumpMinRatio
  - max area = 画像面積

重複防止のため、塊マスク内の円形候補は除外されます。

### 7）排除フィルタ（任意）
排除は検出後のフィルタであり、新しい候補は追加しません。

サンプリングからの閾値推定（estimateExclusionSafe）：
- 飽和値（<=1 または >=254）を除外。
- 目標/排除それぞれ 5-95% を使用。
- 中央値差が小さい（<8）場合は保守的に 255。
- 排除中央値 > 目標中央値：
  - HIGH（明るい対象を排除）
  - t90 と e10 が重なるなら thr = e10、離れていれば thr = (t90 + e10)/2
- 排除中央値 < 目標中央値：
  - LOW（暗い対象を排除）
  - t10 と e90 が重なるなら thr = e90、離れていれば thr = (t10 + e90)/2

面積ゲート（任意）：
- 排除サンプルに対象型 ROI がある場合、面積範囲を推定し、その範囲のみ灰度判定。

画像ごとの厳密調整：
- 検出用 8-bit 画像の平均と標準偏差を取得。
- kstd = clamp(std/mean, 0.10, 0.60)
- HIGH：thr = min(userThr, mean + std*kstd)
- LOW：thr = max(userThr, mean - std*kstd)

候補判定：
- 中心 3x3 の平均濃度を使用。
- HIGH：mean >= thr なら除外、LOW：mean <= thr なら除外。

### 8）計数と塊推定
各候補について：
- 塊推定が有効で area > unitArea*1.35 の場合：
  - est = round(area / unitArea)、[1, 80] に制限
- TB は全候補の est を合算。
- BIC は中心が細胞内にある候補のみ加算。

細胞への割当：
- ラベルマスクあり：中心ピクセル値で判定。
- ラベルマスクなし：ROI 包含判定（低速）。

### 9）微量貪食補正（任意）
境界的な取り込みを除外するため：
- 細胞ごとのカウント（>0）を集計。
- q50 = 中央値、q75 = 75% 分位。
- minPhagoThr = round((q50 + q75)/2)、最小 1。
- CWBA は 対象物数 >= minPhagoThr の細胞のみカウント。

## パラメータと厳密度
厳密度は検出範囲と特徴閾値を変更します。

面積と円形度のスケーリング：
- Strict：minA*0.85、maxA*1.20、circ+0.08
- Normal：minA*0.65、maxA*1.60、circ-0.06
- Loose：minA*0.50、maxA*2.10、circ-0.14

特徴閾値のスケーリング：
- Strict：centerDiff*1.15、bgDiff*0.80、smallRatio*0.90、clumpRatio*1.20
- Loose：centerDiff*0.85、bgDiff*1.20、smallRatio*1.10、clumpRatio*0.85

制限：
- centerDiff 2..80、bgDiff 1..60、smallRatio 0.20..1.00、clumpRatio 2..20
- effMinArea は切り捨て、effMaxArea は切り上げ。

UI で min/max を変更すると unitArea は新しい中点に同期されます。

デフォルトパラメータ（v3.0.0）：
- ROI 接尾辞：_cells
- 対象面積の既定範囲：minA=5, maxA=200, circ=0
- Rolling Ball 既定半径：50
- 特徴閾値の既定：centerDiff=12, bgDiff=10, smallRatio=0.70, clumpRatio=4.0
- 塊サンプル比率の閾値：2.5（大きいサンプルを塊として扱う）
- 既定の特徴選択：F1/F2/F3 有効、F4/F5/F6 無効
- 既定の厳密度：Normal
- 塊推定：有効
- 微量貪食補正：有効
- 排除：既定は無効。有効時は HIGH、閾値 255、厳密補正オン、サイズゲートは対象型サンプルがある場合のみオン。
- データフォーマット：既定は有効。既定ルールは `<p>/<f>,f="F"`、サブフォルダ保持時は `<f>/hr,f="T"//<p>/<f>`
- 既定の列：`TB/BIC/CWBA,name="Cell with Target Objects"/TC/IBR/PCR/EIBR/EPCR/ISDP/PSDP`

## データフォーマットと結果レイアウト
フォーマット出力は既定で有効で、PN/F/T をルールで解析します。

### ルール構文
- ファイルルール：`pattern, f="F"` または `pattern, f="T"`
- サブフォルダ保持モード：`folderSpec//fileSpec`
- pattern は必ず 1 つの "/" を含み、PN と F を分ける必要があります：
  - PN トークン：`<p>` または `<pn>`
  - F トークン：`<f>` または `<f1>`
- f="T" は F を時間として解釈します。
- f="T" をファイルルールまたはフォルダルールに指定すると時間解析が有効。
- サブフォルダ保持モードでない場合、時間はファイル名ルールからのみ解析され、サブフォルダ名は使用されない。
- 時間解析が有効でも時間が抽出できない場合は time = 0。

### 列仕様
列は `col1/col2/...` で指定します。

組み込みトークン：
- PN, F, T, TB, BIC, CWB, CWBA, TC, BPC, IBR, PCR, EBPC, BPCSDP, EIBR, EPCR, ISDP, PSDP

カスタム列：
- 非組み込みトークンにパラメータを付与：
  - `name="Dose", value="10"`
- `$` を付けると 1 回だけ出力（PN 展開しない）。
- `-F` または `-f` で F を降順ソート。

### レイアウト規則
- PN ごとに独立した表を作り、Results 内で左から右に並べます。
- 行数は最長 PN 表に合わせ、短い表は空行で埋めます。
- 時間解析が有効な場合：
  - 時間昇順でブロック化。
  - 各時間ブロックの行数はその時間の最長 PN に合わせる。
  - ある PN がその時間に無データの場合、ブロック全体が空行。

単細胞展開：
- BPC/EBPC/BPCSDP が含まれる場合、細胞ごとに 1 行。
- 単細胞列のみが行ごとに変化し、他の列は繰り返されます。
- 集計列（EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP）は PN と時間で集計。

## 実用的なヒントと注意点
- サンプリングは典型的な単一対象物を優先してください。
- F3/F4 の塊サンプルは Freehand/Polygon ROI を推奨します。
- ROI 数が 65535 を超える場合は分割してください。
- 排除推定では飽和値（<=1 または >=254）を除外します。
- ROI 欠損時はその場で標注するかスキップできます（空行は残ります）。
- 文字化け回避のためドラッグ＆ドロップ実行を推奨します。

## ライセンス
CC0 1.0 Universal（パブリックドメイン提供）。詳細は `LICENSE` を参照。
本リポジトリには第三者ソフトウェアおよびフォントが含まれています。各ライセンスに従います。`THIRD_PARTY_NOTICES.md` を参照してください。



