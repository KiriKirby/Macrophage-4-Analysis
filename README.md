# 巨噬细胞图像四元素值分析  
**Macrophage Image Four-Factor Analysis**

---

## 一、项目简介

本项目是一个基于 **Fiji / ImageJ（ImageJ Macro Language）** 的图像分析宏，用于对显微镜图像中的**巨噬细胞与磁珠（beads）**进行半自动定量分析。

该宏支持：
- 手动标注细胞 ROI
- 自动检测磁珠（支持亮珠、暗珠及团聚情况）
- 统计每张图像的“四要素”指标
- 多语言界面（中文 / English / 日本語）
- 高性能批量处理
- 可控的严格程度与调试模式

项目设计目标是：  
**在保证分析结果可解释、可控的前提下，最大限度提高自动化与处理效率。**

---

## 二、功能概览

### 1) 工作模式
启动后可通过下拉菜单选择三种模式：

1. **仅标画细胞 ROI**  
   - 逐张打开图像  
   - 手动勾画细胞轮廓  
   - 保存为 `*_cells.zip`  
   - 不进行磁珠分析  

2. **仅分析四要素**  
   - 直接对已有细胞 ROI 的图像进行分析  
   - 若缺少 ROI，可选择补标注或跳过  

3. **标画细胞 ROI 后分析四要素（推荐）**  
   - 完整工作流  
   - 先标注细胞，再进行磁珠抽样与批量分析  

---

### 2) 输出的“四要素”
对每一张图像，宏会在 Results 表中输出一行，包含：

| 字段名 | 含义 |
|------|------|
| Image | 图像文件名（不含扩展名） |
| Total Beads | 检测到的磁珠总数（含团聚估算） |
| Beads in Cells | 位于细胞 ROI 内的磁珠数量 |
| Cells with Beads | 至少包含 ≥1 个磁珠的细胞数量 |
| Total Cells | 该图像中的细胞总数 |

即使某张图像因缺少 ROI 被跳过，结果表中也会保留一行（值为空），以保证数据对齐。

---

## 三、使用方法

### 1) 环境要求
- Fiji（推荐最新版本）或 ImageJ  
- 支持的图像格式：  
  `.tif / .tiff / .png / .jpg / .jpeg`（大小写不敏感）

---

### 2) 运行宏（推荐方式，避免乱码）
⚠ 不推荐使用：

- 打开 Fiji  
- `Plugins → Macros → Run...`  
- 选择本项目的 `.ijm` 宏文件  

原因是：在部分系统与 Fiji 版本中，这种方式可能导致**非英文字符（中文/日文）乱码**。

✅ 推荐方式（可稳定保留 UTF-8 编码）：

1. 打开 Fiji  
2. **将 `.ijm` 宏文件直接拖入 Fiji 主窗口**  
3. Fiji 会自动打开 **Macro Editor（宏编辑器）**  
4. 在宏编辑器中点击 **Run** 按钮运行  

---

## 四、核心原理详解

### 1) 设计思想：分离“细胞 ROI”和“磁珠检测”

显微图像中：
- 细胞边界复杂、变化大、对焦与染色差异明显 → 全自动分割往往不稳定
- 磁珠形态相对一致（近似圆形、尺寸范围有限） → 更适合自动检测

因此本宏采用：
- **细胞：人工标注 ROI（高可靠性、可解释）**
- **磁珠：自动检测 + 规则筛选（高效率、可调参数）**

这是在生物图像定量中常见且稳健的半自动工作流。

---

## 五、参数与微调

- **Bead Minimum / Maximum Area**：磁珠面积过滤范围（像素²）
- **Circularity**：磁珠圆形度下限
- **Strictness（严格 / 正常 / 宽松）**：整体判定宽松程度
- **Rolling Ball Radius**：背景扣除半径
- **Debug Mode**：保留中间图像并标出磁珠位置

---

## 六、本地化与多语言

- 所有 UI 文本集中在脚本前部定义
- 新增语言只需复制并翻译对应语言块
- 不影响核心算法逻辑

---

## 七、许可证建议

- 推荐：MIT License  
- 若要求修改后必须开源：GPL-3.0

---

# Macrophage Image Four-Factor Analysis  
**README (English Version)**

---

## 1. Overview

This project is a **Fiji / ImageJ macro** for semi-automatic quantitative analysis of **macrophage images with beads**.

It provides:
- Manual cell ROI annotation
- Automated bead detection (bright beads, dark beads, and clusters)
- Per-image four-factor statistics
- High-performance batch processing
- Multilingual UI (Chinese / English / Japanese)

The goal is to maximize automation and performance while keeping results interpretable and controllable.

---

## 2. How to Run (Recommended)

⚠ Not recommended:

```
Fiji → Plugins → Macros → Run...
```

This method may cause **non-English characters to appear as garbled text** on some systems.

✅ Recommended method:

1. Open Fiji
2. **Drag and drop the `.ijm` macro file into the Fiji window**
3. Fiji opens the **Macro Editor**
4. Click **Run** to execute

---

## 3. Core Principles

### Manual cell ROIs + automated bead detection
Cell boundaries are complex and highly variable, making fully automatic segmentation unreliable. Beads have more consistent morphology and size constraints.

Thus:
- Cells are annotated manually
- Beads are detected automatically

---

## 4. License

MIT License is recommended unless copyleft (GPL) is required.

