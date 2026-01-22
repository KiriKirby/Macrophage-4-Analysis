AI 编辑提示：修改前请先阅读本仓库的 `AGENTS.md`。
# 巨噬细胞图像四元素值分析
语言： [中文](README.zh-CN.md) | [English](README.en.md) | [日本語](README.ja.md)

Fiji 专用 ImageJ 宏，用于对巨噬细胞图像中的目标物（beads）进行半自动定量。脚本为交互式流程，覆盖 ROI 标注、采样、检测与结果输出。

主要能力
- 细胞 ROI 标注与校验，使用标签图加速归属判定
- 目标物采样推断面积尺度、对比度阈值与背景扣除参数
- 双通道圆形目标物检测（阈值 + 边缘）与严格度策略
- 团块检测与面积估算数量
- 可选排除过滤（灰度阈值 + 面积门控）
- 四要素统计与可选微量吞噬修正
- 灵活的 PN/F/T 解析、按细胞展开与数据优化

## 概览
- 主脚本：`Macrophage Image Four-Factor Analysis_2.2.3.ijm`
- 特征参考图：`sample.png`
- 运行环境：仅支持 Fiji（ImageJ 单体无法运行）。
- 支持格式：tif/tiff/png/jpg/jpeg

## 快速开始
推荐运行方式（避免非英文界面乱码）：
1. 打开 Fiji。
2. 将 `Macrophage Image Four-Factor Analysis_2.2.3.ijm` 拖入 Fiji 窗口。
3. Macro Editor 打开后点击 Run。

## 四要素模型与核心指标
“四要素”是每张图像的计数类量：
- TB：目标物总数（若启用团块估算，则按估算数计）。
- BIC：细胞内目标物数（若启用团块估算，则按估算数计）。
- CWB：含目标物的细胞数。
- TC：细胞总数（ROI 数量）。

派生指标：
- CWBA：微量吞噬修正后的 CWB（可选）。
- IBR = BIC / TB
- PCR = CWB / TC
- BPC = BIC / TC（每细胞平均目标物数）

格式化输出的汇总指标：
- eIBR/ePCR/eBPC：按 PN（若启用时间解析则按 PN+时间）统计的平均值。
- ISDP/PSDP/BPCSDP：同一分组内比值的总体标准差。

## 工作流程（按阶段）
1. 语言选择。
2. 模式选择：仅 ROI、仅分析、标注后分析。
3. 文件夹选择（文件模式或子文件夹模式）。
4. 细胞 ROI 标注（如启用）。
5. 目标物采样。
6. 排除对象采样（可选）。
7. 参数推断与确认。
8. 批量分析与结果输出。

## 图像处理原理与实现（硬核）

### 1）采样与推断
目标物采样在 8-bit 复制图像上进行。
每个采样 ROI 会记录：
- 面积与平均灰度。
- 局部对比度特征：
  - centerMean：ROI 中心 3x3 平均灰度。
  - ringMean：半径 0.75r 上 8 个点的平均灰度。
  - outerMean：半径 1.35r 上 8 个点的平均灰度。
  - centerDiff = centerMean - ringMean
  - bgDiff = abs(((centerMean + ringMean)/2) - outerMean)

圆形样本与团块样本判定：
- ROI 类型为椭圆或矩形，且长宽比 <= 1.6，则判为圆形样本。
- 非圆形或过度拉伸的 ROI 视为团块样本。
- 若存在细胞 ROI，则判断采样是否位于细胞内：
  - 在 ROI 内以粗网格采样。
  - 若 >= 30% 采样点落在细胞标签图内，则标记为细胞内样本。

面积范围鲁棒推断（estimateAreaRangeSafe）：
- 样本 < 3：取中位数 m，min = 0.45*m，max = 2.50*m。
- 样本 >= 3：先截取 5-95%，计算 q10/q90/q25/q75/IQR。
- padding = max(IQR*1.20, m*0.35)
- marginFactor = 1.60（n < 6），1.35（n < 15），否则 1.15
- minA = floor((q10 - padding) / marginFactor)
- maxA = ceil((q90 + padding) * marginFactor)
- maxA 上限为 max(20*m, 6*q90)

Rolling Ball 推断：
- unitArea = 目标物面积中位数。
- 直径 d = 2*sqrt(unitArea/PI)
- 半径 = round(d*10)（d < 8），round(d*7)（d < 20），否则 round(d*5)
- 限制在 [20, 220]

特征阈值推断：
- centerDiffThr = abs(centerDiff) 的 70% 分位，限制在 [6, 40]。
- bgDiffThr = abs(bgDiff) 的 50% 分位，限制在 [4, 30]。
- smallAreaRatio = clamp(q25/median, 0.45, 0.90)。
- clumpMinRatio = clumpArea/unitArea 的 25% 分位，限制在 [2.5, 20]。

采样启发式与过滤：
- 圆形样本面积上限：当圆形样本 >= 3 时，仅使用 area <= 3.0 * median 的圆形样本进行目标面积推断。
- 团块样本判定：ROI 非圆形或 area >= unitArea * 2.5 时视为团块样本。
- 排除面积采样过滤：排除采样时，仅将 area < unitAreaGuess * 20 的 ROI 作为对象型样本参与面积范围推断（unitAreaGuess 为目标面积代表值；无样本时取默认中点）。

### 2）目标物特征（F1-F6）
特征含义（对应参考图编号）：
- F1：中心高亮、外圈偏暗的圆形目标（反光型）
- F2：中等灰度、内外反差较小的圆形目标
- F3：多个目标物聚集形成的深色团块（按面积估算）
- F4：细胞内高密度/杂纹区域（仅细胞内，按面积估算）
- F5：中心偏暗、外圈偏亮的圆形目标（反差型）
- F6：低对比度、小尺寸圆形目标（接近细胞灰度）

规则：
- F4 仅在细胞内判定（需与细胞 ROI 重合）。
- F1 与 F5 互斥。
- 选择的特征决定后续阈值参数是否出现。

### 3）逐图像预处理
每张图像执行：
- 强制 2D（若为 Z 栈则固定第 1 层），并强制像素单位。
- 复制为 8-bit 用于检测与采样。
- 可选 Rolling Ball 背景扣除。

### 4）圆形目标物检测（F1/F2/F5/F6）
采用双通道检测生成圆形候选。

阈值极性选择：
- 若目标与排除的灰度中位数可用：
  - targetMedian <= exclusionMedian 时用 DARK，否则用 LIGHT。
- 若仅 targetMedian 可用：
  - 与图像均值比较决定 DARK/LIGHT。
- 若仅选择 F1，则强制 DARK；仅选择 F5，则强制 LIGHT。

通道 A：Yen 阈值
1. 可选中值滤波（radius=1，宽松模式除外）。
2. 自动阈值（Yen dark/light/auto）。
3. 转为二值并填孔。
4. 开运算（严格模式执行两次）。
5. 严格模式下执行 Watershed。
6. Analyze Particles，按面积与圆形度筛选。

通道 B：边缘 + Otsu
1. Find Edges。
2. 自动阈值（Otsu dark/light/auto）。
3. 转为二值并填孔。
4. 开运算（宽松模式除外）。
5. 严格模式下执行 Watershed。
6. Analyze Particles，按面积与圆形度筛选。

候选融合：
- mergeDist = max(2, 0.8 * sqrt(unitArea/PI))。
- mergeDist 内的候选合并，保留面积更大的候选。
- 严格策略仅保留：
  - 两通道同时命中的候选，或
  - 面积 >= 1.25 * unitArea 的候选。
- 正常策略取并集；宽松策略过滤最少。

### 5）圆形候选的特征判定
对每个融合候选：
- r = sqrt(area/PI)
- 按采样方式计算 centerDiff 与 bgDiff。
- 判定逻辑：
  - 若 abs(centerDiff) >= centerDiffThr：
    - centerDiff >= thr 且启用 F1 -> 保留（F1）
    - centerDiff <= -thr 且启用 F5 -> 保留（F5）
  - 否则：
    - isSmall：area <= unitArea * smallAreaRatio
    - isBgLike：bgDiff <= bgDiffThr
    - 若启用 F6 且 (isSmall 或 isBgLike) -> 保留（F6）
    - 否则若启用 F2 -> 保留（F2）

### 6）团块检测（F3/F4）
团块候选基于掩膜检测。

F3：暗色团块掩膜
- 中值滤波（宽松模式除外）。
- Yen dark 阈值，转二值并填孔。
- 开运算：严格两次、正常一次、宽松不执行。

F4：细胞内团块掩膜
- 需要细胞标签图。
- 对灰度图做方差滤波：
  - varRadius = round(0.45 * sqrt(unitArea/PI))，限制 1..6
  - 严格 +1，宽松 -1
- 转 8-bit，Otsu light 阈值，填孔。
- 严格模式做开运算。
- 与细胞掩膜 AND，仅保留细胞内高方差区域。

组合与检测：
- 同时启用 F3 与 F4 时掩膜取 OR。
- Analyze Particles 检测团块：
  - min area = unitArea * clumpMinRatio
  - max area = 图像面积

为避免重复计数，落在团块掩膜中的圆形候选会被剔除。

### 7）排除过滤（可选）
排除是检测后的过滤，不会新增候选。

基于采样的阈值推断（estimateExclusionSafe）：
- 过滤饱和值（<=1 或 >=254）。
- 目标与排除样本各自截取 5-95%。
- 中位数过近（<8）时使用保守阈值 255。
- 若排除中位数 > 目标中位数：
  - HIGH 模式（排除亮目标）
  - 比较 t90 与 e10；若重叠则 thr = e10，否则 thr = (t90 + e10)/2
- 若排除中位数 < 目标中位数：
  - LOW 模式（排除暗目标）
  - 比较 t10 与 e90；若重叠则 thr = e90，否则 thr = (t10 + e90)/2

面积门控（可选）：
- 若排除样本包含“对象型”ROI，则推断排除面积范围，仅在该范围内应用灰度过滤。

逐图像严格调整：
- 在检测用 8-bit 图上计算均值与标准差。
- kstd = clamp(std/mean, 0.10, 0.60)
- HIGH：thr = min(userThr, mean + std*kstd)
- LOW：thr = max(userThr, mean - std*kstd)

候选判定：
- 使用候选中心 3x3 均值灰度。
- HIGH：mean >= thr 则排除；LOW：mean <= thr 则排除。

### 8）计数与团块估算
对每个候选：
- 若允许团块估算且 area > unitArea*1.35：
  - est = round(area / unitArea)，限制在 [1, 80]
- TB 累加所有候选的 est。
- BIC 仅在候选中心位于细胞内时累加 est。

细胞归属：
- 有标签图：直接读取中心像素值。
- 无标签图：ROI 包含性判定（较慢）。

### 9）微量吞噬修正（可选）
降低边缘性吞噬带来的噪声：
- 统计每个细胞的计数（>0）。
- q50 为中位数，q75 为 75% 分位。
- minPhagoThr = round((q50 + q75)/2)，最小为 1。
- CWBA 统计 目标物数 >= minPhagoThr 的细胞。

## 参数逻辑与严格度
严格度会改变检测范围与特征阈值。

面积与圆形度缩放：
- 严格：minA*0.85，maxA*1.20，circ+0.08
- 正常：minA*0.65，maxA*1.60，circ-0.06
- 宽松：minA*0.50，maxA*2.10，circ-0.14

特征阈值缩放：
- 严格：centerDiff*1.15，bgDiff*0.80，smallRatio*0.90，clumpRatio*1.20
- 宽松：centerDiff*0.85，bgDiff*1.20，smallRatio*1.10，clumpRatio*0.85

限制范围：
- centerDiff 2..80，bgDiff 1..60，smallRatio 0.20..1.00，clumpRatio 2..20
- effMinArea 向下取整，effMaxArea 向上取整。

若用户在 UI 中修改面积范围，则 unitArea 会同步为新范围的中点。

默认参数（v2.2.3）：
- ROI 后缀：_cells
- 目标面积默认范围：minA=5, maxA=200, circ=0
- 背景 Rolling Ball 默认半径：50
- 特征阈值默认：centerDiff=12, bgDiff=10, smallRatio=0.70, clumpRatio=4.0
- 团块样本比率阈值：2.5（用于将较大样本视为团块）
- 默认特征选择：F1/F2/F3 启用，F4/F5/F6 关闭
- 默认严格度：Normal
- 团块估算：开启
- 微量吞噬修正：开启
- 排除：默认关闭；启用时默认模式 HIGH、阈值 255、严格调节开启、面积门控仅在存在对象型样本时开启
- 数据格式化：默认开启；默认规则 `<p>/<f>,f="F"`，子文件夹保持模式下为 `<f>/hr,f="T"//<p>/<f>`
- 默认列：`TB/BIC/CWBA,name="Cell with Target Objects"/TC/IBR/PCR/EIBR/EPCR/ISDP/PSDP`
- 数据优化：默认开启

## 数据格式化与结果布局
格式化输出默认开启，通过规则解析 PN/F/T。

### 规则语法
- 文件规则：`pattern, f="F"` 或 `pattern, f="T"`
- 子文件夹保持模式：`folderSpec//fileSpec`
- pattern 必须包含且仅包含一个 "/"，用于分隔 PN 与 F：
  - PN token：`<p>` 或 `<pn>`
  - F token：`<f>` 或 `<f1>`
- f="T" 表示将 F 解析为时间。
- 时间解析在文件规则或文件夹规则中设置 f="T" 时启用。
- 若为平铺模式（不保持子文件夹），时间只能从文件名规则解析，子文件夹名不参与解析。
- 若启用时间解析但无法解析到时间，则 time = 0。

### 列格式
列格式为 `col1/col2/...`。

内置 token：
- PN, F, T, TB, BIC, CWB, CWBA, TC, BPC, IBR, PCR, EBPC, BPCSDP, EIBR, EPCR, ISDP, PSDP

自定义列：
- 任意非内置 token，可带参数：
  - `name="Dose", value="10"`
- `$` 前缀表示该列只输出一次（不随 PN 扩展）。
- `-F` 或 `-f` 代表 F 逆序排序。

### 结果布局规则
- 每个 PN 为独立子表，按 PN 从左到右排列。
- 行数取 PN 表中的最大长度，较短的 PN 用空行补齐。
- 若启用时间解析：
  - 按时间升序分块。
  - 每个时间块的行数等于该时间下最长 PN 的长度。
  - 某 PN 在该时间无数据，则该时间块整块为空行。

按细胞展开：
- 若包含 BPC/EBPC/BPCSDP，则结果按细胞展开，每个细胞一行。
- 仅单细胞相关列随行变化，其余列重复。
- 汇总列（EIBR/EPCR/ISDP/PSDP/EBPC/BPCSDP）仍按 PN 与时间分组统计。

## 数据优化（IBR/PCR/BPC）
当启用数据优化（且启用格式化输出）时，按全局与 PN 平均进行平滑。

定义：
- IBR = BIC / TB
- PCR = CWB / TC
- BPC = BIC / TC

计算流程：
1. 计算每图像比值与全局均值（gIBR, gPCR, gBPC）。
2. 计算 PN 均值（pnIBR, pnPCR, pnBPC）。
3. 计算：
   - betweenFactor = 1.0（单 PN）或 1.15 + 0.05 * min(pnCount-1, 3)
   - withinFactor = clamp(0.55 + 0.20 / sqrt(nPn), 0.35, 0.75)，nPn>1；否则 0.75
4. 调整比值：
   - tIBR = gIBR + (pnIBR - gIBR)*betweenFactor + (ibrOrig - pnIBR)*withinFactor
   - tPCR 同理。
   - tBPC 在按细胞模式下同理。
5. 还原为计数：
   - adjBIC = round(tIBR * TB)
   - adjCWB = round(tPCR * TC)
   - 按细胞 BPC 用 factor = tBPC / bpcOrig 进行缩放。

时间单调调整：
- 若启用时间解析，则同一 PN 的平均 IBR 或 BPC 随时间强制非递减。
- 若后续时间段均值低于上一段，则提升到上一段均值。

## 实操建议与注意事项
- 采样时优先选择典型单个目标物，提高推断稳定性。
- F3/F4 的团块样本建议使用 Freehand/Polygon ROI。
- ROI 数量超过 65535 会报错，建议分批或减少每图像细胞数。
- 排除推断会过滤饱和值（<=1 或 >=254）。
- 缺失 ROI 时可现场补标注或跳过，跳过的图像仍会保留空行。
- 建议拖拽运行，避免非英文界面乱码。

## 许可证
推荐 MIT；需要强制开源可选 GPL-3.0。


