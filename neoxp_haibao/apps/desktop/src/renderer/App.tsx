import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type FocusEvent as ReactFocusEvent,
  type MouseEvent as ReactMouseEvent,
  type WheelEvent as ReactWheelEvent
} from "react";
import {
  Accordion,
  AccordionHeader,
  AccordionItem,
  AccordionPanel,
  Button,
  Checkbox,
  ColorArea,
  ColorPicker,
  ColorSlider,
  Divider,
  Dropdown,
  Field,
  Input,
  Menu,
  MenuDivider,
  MenuItem,
  MenuList,
  MenuPopover,
  MenuTrigger,
  Popover,
  PopoverSurface,
  PopoverTrigger,
  ProgressBar,
  Radio,
  RadioGroup,
  Spinner,
  Switch,
  Textarea,
  Tree,
  TreeItem,
  TreeItemLayout,
  Option
} from "@fluentui/react-components";
import {
  ArrowDown24Regular,
  ArrowReset24Regular,
  ArrowUp24Regular,
  CircleFilled,
  ChevronRight24Regular,
  Code24Regular,
  Clock24Regular,
  DismissCircleFilled,
  Dismiss24Regular,
  Folder24Regular,
  FolderOpen24Regular,
  Home24Regular,
  MoreHorizontal24Regular,
  Open24Regular,
  Play24Regular,
  Square24Regular,
  SquareMultiple24Regular,
  Subtract24Regular,
  Tag24Regular,
  WarningFilled,
  ZoomIn24Regular,
  ZoomOut24Regular
} from "@fluentui/react-icons";
import type { FilePreset } from "@neoxp/contracts";
import { useI18n } from "./i18n";
import type { MessageKey } from "../i18n";
import type { WorkspacePair, WorkspaceScanResult } from "./types";
import { debugFlags, persistDebugFlags } from "./debugFlags";

type PanelKey = "files" | "settings" | "logs";
type TopMenuKey = "file" | "edit" | "view" | "window" | "help";
type DragMode = "left" | "center" | null;
type CollapseReason = "manual" | "auto";
type ExpandReason = "manual" | "auto";
type PreviewSide = "normal" | "fluo";
type StrictMode = "S" | "N" | "L";
type ExclusionMode = "bright" | "dark";
type FeatureKey = "f1" | "f2" | "f3" | "f5" | "f6";
type RgbFieldKey = "targetRgb" | "nearRgb" | "exclRgb";
type SubfolderMode = "keep" | "flat";
type NamingProjectRule = "filename" | "folder";
type NamingTimeRule = "folder" | "filename";
type OperationSectionKey =
  | "files"
  | "cellRoi"
  | "target"
  | "exclusion"
  | "fluorescence"
  | "data"
  | "debug";

interface StatusState {
  key: MessageKey;
}

interface TreeNode {
  id: string;
  label: string;
  children: TreeNode[];
  pairIds: string[];
}

type NodeRole = "time" | "project";
type RoiUsageMode = "none" | "native" | "auto";
type TextMenuAction = "undo" | "redo" | "cut" | "copy" | "paste" | "selectAll";

interface PairUiState {
  ignored: boolean;
  roiMode: RoiUsageMode;
}

interface TextMenuState {
  open: boolean;
  x: number;
  y: number;
  target: HTMLInputElement | HTMLTextAreaElement | null;
}

interface OperationHeaderMenuState {
  open: boolean;
  x: number;
  y: number;
}

interface TreeBuildResult {
  roots: TreeNode[];
  pairNodePathMap: Map<string, string[]>;
  defaultNodeRoles: Map<string, NodeRole>;
}

interface Size2D {
  width: number;
  height: number;
}

interface BootTask {
  run: () => Promise<void>;
}

interface HsvColorValue {
  h: number;
  s: number;
  v: number;
}

interface ExclusionConfig {
  enabled: boolean;
  mode: ExclusionMode;
  threshold: string;
  strict: boolean;
  sizeGate: boolean;
  minArea: string;
  maxArea: string;
}

interface FluorescenceConfig {
  enabled: boolean;
  prefix: string;
  targetRgb: string;
  nearRgb: string;
  tolerance: string;
  exclEnabled: boolean;
  exclRgb: string;
  exclTolerance: string;
}

interface DataConfig {
  formatColumns: string;
  autoNoiseOptimize: boolean;
  groupByTime: boolean;
  expandPerCell: boolean;
}

interface RuntimeDebugConfig {
  bootManualEnterAfterReady: boolean;
  runSimulateSlowProgress: boolean;
  runProgressStep: string;
  runProgressIntervalMs: string;
  runVerboseLogs: boolean;
}

const RESIZER_WIDTH = 6;
const COLLAPSED_BAR_WIDTH = 34;

const FILE_MIN_WIDTH = 180;
const SETTINGS_MIN_WIDTH = 340;
const LOG_MIN_WIDTH = 180;

const FILE_COLLAPSE_TRIGGER = 56;
const FILE_RESTORE_TRIGGER = 132;
const SETTINGS_COLLAPSE_TRIGGER = 88;
const SETTINGS_RESTORE_TRIGGER = 188;
const LOG_COLLAPSE_TRIGGER = 56;
const LOG_RESTORE_TRIGGER = 132;
const DEFAULT_OPERATION_OPEN_SECTIONS: OperationSectionKey[] = [
  "files",
  "cellRoi",
  "target",
  "exclusion",
  "fluorescence",
  "data"
];
const ALL_OPERATION_SECTIONS: OperationSectionKey[] = [
  "files",
  "cellRoi",
  "target",
  "exclusion",
  "fluorescence",
  "data",
  "debug"
];
const SETTINGS_TOOLBAR_COMPACT_AT = 920;

const FILE_SPLIT_RESIZER_HEIGHT = 5;
const FILE_BROWSER_MIN_HEIGHT = 170;
const PREVIEW_MIN_HEIGHT = 150;
const PREVIEW_COLLAPSE_TRIGGER = 64;
const PREVIEW_RESTORE_TRIGGER = 136;
const PREVIEW_BAR_HEIGHT = 30;
const PREVIEW_SELECTION_SETTLE_MS = 260;

const TAG_LIST_RESIZER_HEIGHT = 4;
const TAG_MIN_HEIGHT = 80;
const LIST_MIN_HEIGHT = 96;
const TAG_COLLAPSE_TRIGGER = 44;
const TAG_RESTORE_TRIGGER = 118;
const LIST_COLLAPSE_TRIGGER = 48;
const LIST_RESTORE_TRIGGER = 118;
const TAG_BAR_HEIGHT = 26;
const LIST_BAR_HEIGHT = 26;

const COLUMN_MIN_ROI = 54;
const COLUMN_TIME_WIDTH = 92;
const COLUMN_PROJECT_WIDTH = 128;
const COLUMN_MIN_NORMAL = 110;
const COLUMN_FLUO_WIDTH = 180;
const COLUMN_MIN_FLUO = 110;
const COLUMN_MIN_TIME = 72;
const COLUMN_MIN_PROJECT = 100;
const TREE_EXPAND_SLOT_WIDTH = 16;
const SETTINGS_CONFIG_STORAGE_KEY = "neoxp.desktop.config.v2";

const ALL_NODE_ID = "__all__";

const ZOOM_MIN = 0.25;
const ZOOM_MAX = 6;

function findEditableTarget(source: HTMLElement): HTMLInputElement | HTMLTextAreaElement | null {
  const direct = source.closest("input, textarea");
  if (direct instanceof HTMLInputElement || direct instanceof HTMLTextAreaElement) {
    return direct;
  }

  const fluentHost = source.closest(".fui-Input, .fui-Textarea, .fui-Combobox");
  if (fluentHost instanceof HTMLElement) {
    const inner = fluentHost.querySelector("input, textarea");
    if (inner instanceof HTMLInputElement || inner instanceof HTMLTextAreaElement) {
      return inner;
    }
  }

  return null;
}

function clamp(value: number, min: number, max: number): number {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

function buildOrganicBlobPath(
  cx: number,
  cy: number,
  rx: number,
  ry: number,
  circularity: number,
  seed: number
): string {
  const points = 28;
  const amp = clamp((1 - circularity) * 0.24, 0, 0.24);
  const out: string[] = [];
  for (let i = 0; i < points; i += 1) {
    const t = (i / points) * Math.PI * 2;
    const noise =
      (Math.sin((t * 3) + seed) * 0.56) +
      (Math.sin((t * 5) + (seed * 1.9)) * 0.27) +
      (Math.cos((t * 7) + (seed * 0.8)) * 0.17);
    const scale = 1 + (amp * noise);
    const x = cx + (Math.cos(t) * rx * scale);
    const y = cy + (Math.sin(t) * ry * scale);
    out.push(`${x.toFixed(2)},${y.toFixed(2)}`);
  }
  return `M ${out[0]} L ${out.slice(1).join(" L ")} Z`;
}

function rgbDistance(
  a: { r: number; g: number; b: number } | null,
  b: { r: number; g: number; b: number } | null
): number | null {
  if (!a || !b) return null;
  const dr = a.r - b.r;
  const dg = a.g - b.g;
  const db = a.b - b.b;
  return Math.sqrt((dr * dr) + (dg * dg) + (db * db));
}

function normalizeFeatureFlagSet(
  input: Record<FeatureKey, boolean>,
  preferred?: "f1" | "f5"
): Record<FeatureKey, boolean> {
  const next = { ...input };
  if (next.f1 && next.f5) {
    if (preferred === "f1") {
      next.f5 = false;
    } else if (preferred === "f5") {
      next.f1 = false;
    } else {
      next.f5 = false;
    }
  }
  return next;
}

function parsePositiveIntOr(value: string, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  const rounded = Math.round(parsed);
  return rounded > 0 ? rounded : fallback;
}

function parsePositiveFloatOr(value: string, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return parsed > 0 ? parsed : fallback;
}

function parseTimeLabelFromText(source: string): { label: string; value: number } {
  const text = source.trim();
  const hrMatch = text.match(/(\d+(?:\.\d+)?)\s*hr/i);
  if (hrMatch) {
    const token = hrMatch[1];
    return {
      label: `${token}hr`,
      value: Number(token)
    };
  }

  const firstNumber = text.match(/(\d+(?:\.\d+)?)/);
  if (firstNumber) {
    const token = firstNumber[1];
    return {
      label: token,
      value: Number(token)
    };
  }

  return { label: "", value: 0 };
}

function parseRgbText(input: string): { r: number; g: number; b: number } | null {
  const text = input.trim();
  if (!text) return null;
  const parts = text.split(",").map((part) => part.trim());
  if (parts.length !== 3) return null;
  const r = Number(parts[0]);
  const g = Number(parts[1]);
  const b = Number(parts[2]);
  if (!Number.isFinite(r) || !Number.isFinite(g) || !Number.isFinite(b)) return null;
  if (r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) return null;
  return {
    r: Math.round(r),
    g: Math.round(g),
    b: Math.round(b)
  };
}

function formatRgbText(rgb: { r: number; g: number; b: number }): string {
  return `${rgb.r},${rgb.g},${rgb.b}`;
}

function rgbToHex(rgb: { r: number; g: number; b: number }): string {
  const r = rgb.r.toString(16).padStart(2, "0");
  const g = rgb.g.toString(16).padStart(2, "0");
  const b = rgb.b.toString(16).padStart(2, "0");
  return `#${r}${g}${b}`;
}

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const text = hex.trim();
  const match = text.match(/^#?([a-fA-F0-9]{6})$/);
  if (!match) return null;
  const token = match[1];
  return {
    r: parseInt(token.slice(0, 2), 16),
    g: parseInt(token.slice(2, 4), 16),
    b: parseInt(token.slice(4, 6), 16)
  };
}

function rgbToHsv(rgb: { r: number; g: number; b: number }): HsvColorValue {
  const r = rgb.r / 255;
  const g = rgb.g / 255;
  const b = rgb.b / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;
  let h = 0;

  if (delta !== 0) {
    if (max === r) {
      h = 60 * ((((g - b) / delta) + 6) % 6);
    } else if (max === g) {
      h = 60 * (((b - r) / delta) + 2);
    } else {
      h = 60 * (((r - g) / delta) + 4);
    }
  }

  const s = max === 0 ? 0 : delta / max;
  const v = max;
  return { h, s, v };
}

function hsvToRgb(hsv: HsvColorValue): { r: number; g: number; b: number } {
  const h = ((hsv.h % 360) + 360) % 360;
  const s = clamp(hsv.s, 0, 1);
  const v = clamp(hsv.v, 0, 1);
  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;
  let rp = 0;
  let gp = 0;
  let bp = 0;

  if (h < 60) {
    rp = c;
    gp = x;
  } else if (h < 120) {
    rp = x;
    gp = c;
  } else if (h < 180) {
    gp = c;
    bp = x;
  } else if (h < 240) {
    gp = x;
    bp = c;
  } else if (h < 300) {
    rp = x;
    bp = c;
  } else {
    rp = c;
    bp = x;
  }

  return {
    r: Math.round((rp + m) * 255),
    g: Math.round((gp + m) * 255),
    b: Math.round((bp + m) * 255)
  };
}

function canCollapse(currentCollapsed: boolean, collapsedGroup: boolean[]): boolean {
  if (currentCollapsed) return true;
  let expanded = 0;
  for (const isCollapsed of collapsedGroup) {
    if (!isCollapsed) expanded += 1;
  }
  return expanded > 1;
}

function stableSerializeIdSet(source: Set<string>): string {
  return Array.from(source).sort((a, b) => a.localeCompare(b)).join("|");
}

function stableSerializeNodeRoleOverrides(source: Record<string, NodeRole | undefined>): string {
  return Object.entries(source)
    .filter((entry): entry is [string, NodeRole] => !!entry[1])
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([id, role]) => `${id}:${role}`)
    .join("|");
}

function stableSerializePairUiStateMap(source: Record<string, PairUiState>): string {
  return Object.entries(source)
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([id, state]) => `${id}:${state.ignored ? "1" : "0"}:${state.roiMode}`)
    .join("|");
}

function nowText(): string {
  const d = new Date();
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  const ss = String(d.getSeconds()).padStart(2, "0");
  return `${hh}:${mm}:${ss}`;
}

function buildTreeNodes(pairs: WorkspacePair[], emptyLabel: string): TreeBuildResult {
  const roots: TreeNode[] = [];
  const nodeMap = new Map<string, TreeNode>();
  const pairNodePathMap = new Map<string, string[]>();
  const defaultNodeRoles = new Map<string, NodeRole>();

  for (const pair of pairs) {
    const dirSegments = pair.relativeDir
      .split("/")
      .map((segment) => segment.trim())
      .filter((segment) => segment.length > 0);
    const path = [...dirSegments];
    if (pair.project.trim()) {
      path.push(pair.project.trim());
    }
    if (path.length === 0) {
      path.push(emptyLabel);
    }

    let parentId = "root";
    let siblings = roots;
    const nodePathIds: string[] = [];

    for (const segment of path) {
      const label = segment.trim() || emptyLabel;
      const id = `${parentId}/${label}`;
      let node = nodeMap.get(id);

      if (!node) {
        node = { id, label, children: [], pairIds: [] };
        nodeMap.set(id, node);
        siblings.push(node);
      }

      if (!node.pairIds.includes(pair.id)) {
        node.pairIds.push(pair.id);
      }

      nodePathIds.push(id);
      parentId = id;
      siblings = node.children;
    }

    pairNodePathMap.set(pair.id, nodePathIds);
    if (dirSegments.length > 0 && pair.timeLabel.trim()) {
      const timeNodeId = nodePathIds[dirSegments.length - 1];
      if (timeNodeId && !defaultNodeRoles.has(timeNodeId)) {
        defaultNodeRoles.set(timeNodeId, "time");
      }
    }
    if (pair.project.trim()) {
      const projectNodeId = nodePathIds[nodePathIds.length - 1];
      if (projectNodeId) {
        defaultNodeRoles.set(projectNodeId, "project");
      }
    }
  }

  const sortFn = (a: TreeNode, b: TreeNode): number => {
    const ta = a.label.match(/^(\d+(?:\.\d+)?)\s*hr$/i);
    const tb = b.label.match(/^(\d+(?:\.\d+)?)\s*hr$/i);
    if (ta && tb) return Number(ta[1]) - Number(tb[1]);
    if (ta) return -1;
    if (tb) return 1;
    return a.label.localeCompare(b.label, "zh-CN");
  };

  const sortRecursive = (list: TreeNode[]): void => {
    list.sort(sortFn);
    for (const node of list) {
      sortRecursive(node.children);
    }
  };

  sortRecursive(roots);
  return {
    roots,
    pairNodePathMap,
    defaultNodeRoles
  };
}

function flattenNodes(nodes: TreeNode[]): TreeNode[] {
  const out: TreeNode[] = [];
  const walk = (list: TreeNode[]): void => {
    for (const n of list) {
      out.push(n);
      if (n.children.length > 0) walk(n.children);
    }
  };
  walk(nodes);
  return out;
}

function clampPan(x: number, y: number, zoom: number, natural: Size2D, viewport: Size2D): { x: number; y: number } {
  if (zoom <= 1 || natural.width <= 0 || natural.height <= 0 || viewport.width <= 0 || viewport.height <= 0) {
    return { x: 0, y: 0 };
  }
  const maxX = Math.max(0, (natural.width * zoom - viewport.width) / 2);
  const maxY = Math.max(0, (natural.height * zoom - viewport.height) / 2);
  return {
    x: clamp(x, -maxX, maxX),
    y: clamp(y, -maxY, maxY)
  };
}

export function App(): JSX.Element {
  const { t } = useI18n();

  const presetOptions: Array<{ label: string; value: FilePreset }> = useMemo(() => {
    return [
      { label: t("preset.windows"), value: "WINDOWS" },
      { label: t("preset.dolphin"), value: "DOLPHIN" },
      { label: t("preset.macos"), value: "MACOS" }
    ];
  }, [t]);
  const presetLabelByValue = useMemo(() => {
    const map: Record<FilePreset, string> = {
      WINDOWS: t("preset.windows"),
      DOLPHIN: t("preset.dolphin"),
      MACOS: t("preset.macos")
    };
    return map;
  }, [t]);

  const [appVersion, setAppVersion] = useState<string>("...");
  const [windowIconDataUrl, setWindowIconDataUrl] = useState<string>("");
  const [defaultPreviewPlaceholder, setDefaultPreviewPlaceholder] = useState<string>("");
  const [bootReady, setBootReady] = useState<boolean>(false);
  const [bootCompleted, setBootCompleted] = useState<boolean>(false);
  const [projectFolder, setProjectFolder] = useState<string>("");
  const [folderInput, setFolderInput] = useState<string>("");
  const [workspaceScan, setWorkspaceScan] = useState<WorkspaceScanResult | null>(null);
  const [scanBusy, setScanBusy] = useState<boolean>(false);

  const [preset, setPreset] = useState<FilePreset>("WINDOWS");

  const [mode, setMode] = useState<string>("M1");
  const [subfolderMode, setSubfolderMode] = useState<SubfolderMode>("keep");
  const [namingCustomEnabled, setNamingCustomEnabled] = useState<boolean>(false);
  const [projectNamingRule, setProjectNamingRule] = useState<NamingProjectRule>("filename");
  const [timeNamingRule, setTimeNamingRule] = useState<NamingTimeRule>("folder");
  const [minArea, setMinArea] = useState<string>("15");
  const [maxArea, setMaxArea] = useState<string>("300");
  const [circularity, setCircularity] = useState<string>("0.35");
  const [allowClumpsTarget, setAllowClumpsTarget] = useState<boolean>(true);
  const [centerDiffThreshold, setCenterDiffThreshold] = useState<string>("16");
  const [bgDiffThreshold, setBgDiffThreshold] = useState<string>("12");
  const [smallAreaRatio, setSmallAreaRatio] = useState<string>("0.38");
  const [clumpMinRatio, setClumpMinRatio] = useState<string>("1.65");
  const [useMinPhago, setUseMinPhago] = useState<boolean>(true);
  const [usePixelCount, setUsePixelCount] = useState<boolean>(true);
  const [strictMode, setStrictMode] = useState<StrictMode>("N");
  const [rollingRadius, setRollingRadius] = useState<string>("30");
  const [autoCellArea, setAutoCellArea] = useState<string>("160");
  const [roiSuffix, setRoiSuffix] = useState<string>("_cells");
  const [featureFlags, setFeatureFlags] = useState<Record<FeatureKey, boolean>>({
    f1: true,
    f2: true,
    f3: true,
    f5: false,
    f6: false
  });
  const [targetUseRoundFilter, setTargetUseRoundFilter] = useState<boolean>(true);
  const [targetMinContrast, setTargetMinContrast] = useState<string>("0.15");

  const [operationOpenSections, setOperationOpenSections] = useState<OperationSectionKey[]>(
    DEFAULT_OPERATION_OPEN_SECTIONS
  );

  const [exclusionConfig, setExclusionConfig] = useState<ExclusionConfig>({
    enabled: false,
    mode: "bright",
    threshold: "0.5",
    strict: false,
    sizeGate: true,
    minArea: "12",
    maxArea: "320"
  });
  const [exclusionDraft, setExclusionDraft] = useState<ExclusionConfig>({
    enabled: false,
    mode: "bright",
    threshold: "0.5",
    strict: false,
    sizeGate: true,
    minArea: "12",
    maxArea: "320"
  });

  const [fluorescenceConfig, setFluorescenceConfig] = useState<FluorescenceConfig>({
    enabled: true,
    prefix: "#",
    targetRgb: "0,255,0",
    nearRgb: "45,255,45",
    tolerance: "22",
    exclEnabled: false,
    exclRgb: "",
    exclTolerance: "18"
  });
  const [fluorescenceDraft, setFluorescenceDraft] = useState<FluorescenceConfig>({
    enabled: true,
    prefix: "#",
    targetRgb: "0,255,0",
    nearRgb: "45,255,45",
    tolerance: "22",
    exclEnabled: false,
    exclRgb: "",
    exclTolerance: "18"
  });
  const [fluorescenceAutoInitialized, setFluorescenceAutoInitialized] = useState<boolean>(false);

  const [dataConfig, setDataConfig] = useState<DataConfig>({
    formatColumns: "P,T,F,TB,TPC,ETPC,TPCSEM",
    autoNoiseOptimize: false,
    groupByTime: true,
    expandPerCell: true
  });
  const [dataDraft, setDataDraft] = useState<DataConfig>({
    formatColumns: "P,T,F,TB,TPC,ETPC,TPCSEM",
    autoNoiseOptimize: false,
    groupByTime: true,
    expandPerCell: true
  });

  const [debugConfig, setDebugConfig] = useState<RuntimeDebugConfig>({
    bootManualEnterAfterReady: debugFlags.bootManualEnterAfterReady,
    runSimulateSlowProgress: debugFlags.runSimulateSlowProgress,
    runProgressStep: String(debugFlags.runProgressStep),
    runProgressIntervalMs: String(debugFlags.runProgressIntervalMs),
    runVerboseLogs: debugFlags.runVerboseLogs
  });
  const [debugDraft, setDebugDraft] = useState<RuntimeDebugConfig>({
    bootManualEnterAfterReady: debugFlags.bootManualEnterAfterReady,
    runSimulateSlowProgress: debugFlags.runSimulateSlowProgress,
    runProgressStep: String(debugFlags.runProgressStep),
    runProgressIntervalMs: String(debugFlags.runProgressIntervalMs),
    runVerboseLogs: debugFlags.runVerboseLogs
  });

  const [isRunning, setIsRunning] = useState<boolean>(false);
  const [runProgress, setRunProgress] = useState<number>(0);
  const [settingsToolbarCompact, setSettingsToolbarCompact] = useState<boolean>(false);

  const [activePanel, setActivePanel] = useState<PanelKey | null>("settings");
  const [openTopMenu, setOpenTopMenu] = useState<TopMenuKey | null>(null);
  const [isWindowMaximized, setIsWindowMaximized] = useState<boolean>(false);
  const [hoverHelp, setHoverHelp] = useState<string>("");
  const [statusState, setStatusState] = useState<StatusState>({ key: "status.ready" });
  const [logs, setLogs] = useState<string[]>([
    `${nowText()} ${t("log.appStarted")}`,
    `${nowText()} ${t("log.workspaceMode")}`
  ]);
  const logText = useMemo(() => {
    if (logs.length === 0) return t("log.empty");
    return logs.join("\n");
  }, [logs, t]);

  const workspaceRef = useRef<HTMLDivElement | null>(null);
  const logBodyRef = useRef<HTMLTextAreaElement | null>(null);
  const scanTokenRef = useRef<number>(0);
  const previewReadTokenRef = useRef<number>(0);
  const resizeCommitTimerRef = useRef<number | null>(null);
  const pendingWorkspaceWidthRef = useRef<number>(1080);
  const windowResizeActiveRef = useRef<boolean>(false);
  const previewLoadDebounceRef = useRef<number | null>(null);
  const runTimerRef = useRef<number | null>(null);
  const settingsToolbarRef = useRef<HTMLDivElement | null>(null);
  const splitHostHeightCommitTimerRef = useRef<number | null>(null);
  const browserAreaHeightCommitTimerRef = useRef<number | null>(null);
  const pendingSplitHostHeightRef = useRef<number>(500);
  const pendingBrowserAreaHeightRef = useRef<number>(300);

  const [workspaceWidth, setWorkspaceWidth] = useState<number>(() => {
    if (typeof window !== "undefined" && Number.isFinite(window.innerWidth)) {
      return Math.max(0, Math.floor(window.innerWidth));
    }
    return 1080;
  });
  const [leftWidth, setLeftWidth] = useState<number>(320);
  const [centerWidth, setCenterWidth] = useState<number>(500);
  const [rightWidth, setRightWidth] = useState<number>(280);
  const [windowResizeActive, setWindowResizeActive] = useState<boolean>(false);

  const [fileCollapsed, setFileCollapsed] = useState<boolean>(false);
  const [settingsCollapsed, setSettingsCollapsed] = useState<boolean>(false);
  const [logCollapsed, setLogCollapsed] = useState<boolean>(false);
  const [fileCollapsedAuto, setFileCollapsedAuto] = useState<boolean>(false);
  const [logCollapsedAuto, setLogCollapsedAuto] = useState<boolean>(false);

  const rememberedWidthRef = useRef<{ files: number; settings: number; logs: number }>({
    files: 320,
    settings: 500,
    logs: 280
  });

  const [dragMode, setDragMode] = useState<DragMode>(null);
  const [paneSnapAnimating, setPaneSnapAnimating] = useState<boolean>(false);
  const paneSnapTimerRef = useRef<number | null>(null);
  const paneDragSnapLockRef = useRef<boolean>(false);
  const paneDragSnapLockTimerRef = useRef<number | null>(null);
  const dragStartRef = useRef<{ x: number; left: number; center: number; right: number }>({
    x: 0,
    left: 320,
    center: 500,
    right: 280
  });
  const liveLayoutRef = useRef<{ left: number; center: number; right: number }>({
    left: 320,
    center: 500,
    right: 280
  });

  const [selectedTreeId, setSelectedTreeId] = useState<string>("");
  const [openTreeItems, setOpenTreeItems] = useState<Set<string>>(new Set());
  const [ignoredNodeIds, setIgnoredNodeIds] = useState<Set<string>>(new Set());
  const [nodeRoleOverrides, setNodeRoleOverrides] = useState<Record<string, NodeRole | undefined>>({});
  const [selectedPairId, setSelectedPairId] = useState<string>("");
  const [selectedSide, setSelectedSide] = useState<PreviewSide>("normal");
  const [pairUiStateMap, setPairUiStateMap] = useState<Record<string, PairUiState>>({});
  const filesAppliedSignatureRef = useRef<string | null>(null);
  const cellRoiAppliedSignatureRef = useRef<string | null>(null);

  const splitHostRef = useRef<HTMLDivElement | null>(null);
  const browserAreaRef = useRef<HTMLDivElement | null>(null);
  const imageListWrapRef = useRef<HTMLDivElement | null>(null);
  const previewViewportRef = useRef<HTMLDivElement | null>(null);

  const [splitHostHeight, setSplitHostHeight] = useState<number>(500);
  const [browserHeight, setBrowserHeight] = useState<number>(320);
  const [previewCollapsed, setPreviewCollapsed] = useState<boolean>(false);
  const previewRememberHeightRef = useRef<number>(220);
  const [fileSplitDragging, setFileSplitDragging] = useState<boolean>(false);
  const [fileSplitSnapAnimating, setFileSplitSnapAnimating] = useState<boolean>(false);
  const fileSplitSnapTimerRef = useRef<number | null>(null);
  const fileSplitDragSnapLockRef = useRef<boolean>(false);
  const fileSplitDragSnapLockTimerRef = useRef<number | null>(null);
  const fileSplitStartRef = useRef<{ y: number; browser: number }>({ y: 0, browser: 320 });

  const [browserAreaHeight, setBrowserAreaHeight] = useState<number>(300);
  const [tagHeight, setTagHeight] = useState<number>(140);
  const [tagCollapsed, setTagCollapsed] = useState<boolean>(false);
  const [listCollapsed, setListCollapsed] = useState<boolean>(false);
  const [tagListDragging, setTagListDragging] = useState<boolean>(false);
  const [tagListSnapAnimating, setTagListSnapAnimating] = useState<boolean>(false);
  const tagListSnapTimerRef = useRef<number | null>(null);
  const tagListDragSnapLockRef = useRef<boolean>(false);
  const tagListDragSnapLockTimerRef = useRef<number | null>(null);
  const tagListStartRef = useRef<{ y: number; tag: number }>({ y: 0, tag: 140 });
  const tagRememberHeightRef = useRef<number>(140);
  const listRememberHeightRef = useRef<number>(180);

  const [tableRoiWidth, setTableRoiWidth] = useState<number>(64);
  const [tableNormalWidth, setTableNormalWidth] = useState<number>(180);
  const [tableFluoWidth, setTableFluoWidth] = useState<number>(COLUMN_FLUO_WIDTH);
  const [tableTimeWidth, setTableTimeWidth] = useState<number>(COLUMN_TIME_WIDTH);
  const [tableProjectWidth, setTableProjectWidth] = useState<number>(COLUMN_PROJECT_WIDTH);
  const [tableColDragging, setTableColDragging] = useState<"roi" | "normal" | "fluo" | "time" | "project" | null>(null);
  const tableColStartRef = useRef<{ x: number; roi: number; normal: number; fluo: number; time: number; project: number }>({
    x: 0,
    roi: 64,
    normal: 180,
    fluo: COLUMN_FLUO_WIDTH,
    time: COLUMN_TIME_WIDTH,
    project: COLUMN_PROJECT_WIDTH
  });
  const [dataPreviewColWidths, setDataPreviewColWidths] = useState<number[]>([140, 100, 92, 124, 132, 132, 140, 160]);
  const [dataPreviewColDragging, setDataPreviewColDragging] = useState<number | null>(null);
  const dataPreviewColStartRef = useRef<{ x: number; widths: number[] }>({
    x: 0,
    widths: [140, 100, 92, 124, 132, 132, 140, 160]
  });

  const [previewViewport, setPreviewViewport] = useState<Size2D>({ width: 0, height: 0 });
  const [previewNatural, setPreviewNatural] = useState<Size2D>({ width: 0, height: 0 });
  const [previewZoom, setPreviewZoom] = useState<number>(1);
  const [previewPanX, setPreviewPanX] = useState<number>(0);
  const [previewPanY, setPreviewPanY] = useState<number>(0);
  const [previewDragging, setPreviewDragging] = useState<boolean>(false);
  const previewDragStartRef = useRef<{ x: number; y: number; panX: number; panY: number }>({
    x: 0,
    y: 0,
    panX: 0,
    panY: 0
  });

  const [previewSrc, setPreviewSrc] = useState<string>("");
  const [previewLoadPath, setPreviewLoadPath] = useState<string>("");
  const [previewLoading, setPreviewLoading] = useState<boolean>(false);
  const [previewError, setPreviewError] = useState<string>("");
  const previewCacheRef = useRef<Map<string, string>>(new Map());
  const previewPrefetchingRef = useRef<Set<string>>(new Set());
  const [textMenu, setTextMenu] = useState<TextMenuState>({
    open: false,
    x: 0,
    y: 0,
    target: null
  });
  const [operationHeaderMenu, setOperationHeaderMenu] = useState<OperationHeaderMenuState>({
    open: false,
    x: 0,
    y: 0
  });

  const setStatus = (key: MessageKey): void => {
    setStatusState({ key });
  };

  const appendLog = (line: string): void => {
    const tagged = `${nowText()} ${line}`;
    setLogs((prev) => {
      const next = [...prev, tagged];
      if (next.length > 600) return next.slice(next.length - 600);
      return next;
    });
  };

  const renderMenuGlyph = (glyph?: string): JSX.Element => {
    return <span className={`menu-glyph${glyph ? "" : " is-empty"}`}>{glyph || " "}</span>;
  };

  const renderRoiIcon = (mode: RoiUsageMode, colored = false): JSX.Element => {
    if (mode === "native") {
      return (
        <span className={`roi-icon${colored ? " is-colored is-native" : " is-native"}`}>
          <CircleFilled />
        </span>
      );
    }
    if (mode === "auto") {
      return (
        <span className={`roi-icon${colored ? " is-colored is-auto" : " is-auto"}`}>
          <WarningFilled />
        </span>
      );
    }
    return (
      <span className={`roi-icon${colored ? " is-colored is-none" : " is-none"}`}>
        <DismissCircleFilled />
      </span>
    );
  };

  const applyFluoRgbByKey = (
    key: "targetRgb" | "nearRgb" | "exclRgb",
    color: HsvColorValue
  ): void => {
    const nextText = formatRgbText(hsvToRgb(color));
    setFluorescenceDraft((prev) => ({
      ...prev,
      [key]: nextText
    }));
  };

  const renderRgbFieldWithPicker = (
    key: RgbFieldKey,
    labelKey: MessageKey,
    value: string,
    disabled: boolean
  ): JSX.Element => {
    const parsed = parseRgbText(value);
    const hsv = parsed ? rgbToHsv(parsed) : { h: 0, s: 0, v: 0 };
    const swatchColor = parsed ? rgbToHex(parsed) : "#000000";
    return (
      <Field label={t(labelKey)} size="small">
        <div className="rgb-input-row">
          <Popover positioning="below" withArrow>
            <PopoverTrigger disableButtonEnhancement>
              <div
                className={`rgb-input-popover-anchor${disabled ? " is-disabled" : ""}`}
                aria-disabled={disabled}
              >
                <Input
                  value={value}
                  onChange={(_, data) =>
                    setFluorescenceDraft((prev) => ({
                      ...prev,
                      [key]: data.value
                    }))
                  }
                  disabled={disabled}
                  aria-label={t(labelKey)}
                  contentAfter={
                    <span
                      className="rgb-input-chip"
                      style={{
                        background: swatchColor
                      }}
                    />
                  }
                />
              </div>
            </PopoverTrigger>
            <PopoverSurface>
              <div className="color-picker-popover">
                <ColorPicker
                  className="rgb-color-picker"
                  color={hsv}
                  onColorChange={(_, data) => {
                    applyFluoRgbByKey(key, data.color as HsvColorValue);
                  }}
                >
                  <ColorArea className="rgb-color-area" />
                  <ColorSlider className="rgb-color-slider" channel="hue" />
                </ColorPicker>
              </div>
            </PopoverSurface>
          </Popover>
        </div>
      </Field>
    );
  };

  const patchPairUiState = (pairId: string, patch: Partial<PairUiState>): void => {
    setPairUiStateMap((prev) => {
      const current = prev[pairId] ?? { ignored: false, roiMode: "none" as RoiUsageMode };
      return {
        ...prev,
        [pairId]: {
          ...current,
          ...patch
        }
      };
    });
  };

  const refreshWorkspace = async (rootPath: string): Promise<void> => {
    const path = rootPath.trim();
    if (!path) {
      setWorkspaceScan(null);
      return;
    }

    const token = scanTokenRef.current + 1;
    scanTokenRef.current = token;

    setScanBusy(true);
    setStatus("status.scanStarted");

    try {
      const out = await window.electronAPI.scanWorkspace({
        rootPath: path,
        preset,
        fluoPrefix: fluorescenceConfig.prefix,
        fluoEnabled: fluorescenceConfig.enabled,
        roiSuffix
      });
      if (token !== scanTokenRef.current) return;

      setWorkspaceScan(out);
      if (out.totalImages === 0) {
        setStatus("status.scanEmpty");
        appendLog(t("log.scanEmpty", { folder: path }));
      } else {
        setStatus("status.scanDone");
        appendLog(
          t("log.scanDone", {
            folder: path,
            images: out.totalImages,
            pairs: out.totalPairs
          })
        );
      }
    } catch (error) {
      if (token !== scanTokenRef.current) return;
      setWorkspaceScan(null);
      setStatus("status.scanFailed");
      appendLog(
        t("log.scanFailed", {
          error: error instanceof Error ? error.message : "scan_failed"
        })
      );
    } finally {
      if (token === scanTokenRef.current) {
        setScanBusy(false);
      }
    }
  };

  useEffect(() => {
    let disposed = false;

    const runBootstrap = async (): Promise<void> => {
      await new Promise<void>((resolve) => {
        window.requestAnimationFrame(() => resolve());
      });

      const tasks: BootTask[] = [
        {
          run: async (): Promise<void> => {
            const out = await window.electronAPI.getWindowMaximized().catch(() => ({ ok: false, maximized: false }));
            if (!disposed && out.ok) {
              setIsWindowMaximized(out.maximized);
            }
          }
        },
        {
          run: async (): Promise<void> => {
            const version = await window.electronAPI.getAppVersion().catch(() => "unknown");
            if (!disposed) {
              setAppVersion(version || "unknown");
            }
          }
        },
        {
          run: async (): Promise<void> => {
            const [iconDataUrl, placeholderDataUrl] = await Promise.all([
              window.electronAPI.getWindowIconDataUrl().catch(() => ""),
              window.electronAPI.getDefaultPreviewPlaceholderDataUrl().catch(() => "")
            ]);
            if (!disposed) {
              setWindowIconDataUrl(iconDataUrl || "");
              setDefaultPreviewPlaceholder(placeholderDataUrl || "");
            }
          }
        },
        {
          run: async (): Promise<void> => {
            await Promise.resolve();
          }
        }
      ];

      for (let i = 0; i < tasks.length; i += 1) {
        if (disposed) return;
        await tasks[i].run();
        if (disposed) return;
      }

      if (disposed) return;
      setBootCompleted(true);
      if (debugFlags.bootManualEnterAfterReady) {
        return;
      }

      window.setTimeout(() => {
        if (!disposed) {
          setBootReady(true);
        }
      }, 30);
    };

    void runBootstrap();
    return () => {
      disposed = true;
    };
  }, []);

  useEffect(() => {
    return () => {
      if (runTimerRef.current !== null) {
        window.clearInterval(runTimerRef.current);
        runTimerRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    const host = settingsToolbarRef.current;
    if (!host) return;

    const updateCompact = (width: number): void => {
      setSettingsToolbarCompact(width < SETTINGS_TOOLBAR_COMPACT_AT);
    };

    updateCompact(host.clientWidth);
    const observer = new ResizeObserver((entries) => {
      const width = entries[0]?.contentRect.width ?? host.clientWidth;
      updateCompact(width);
    });
    observer.observe(host);

    return () => {
      observer.disconnect();
    };
  }, [bootReady, settingsCollapsed, workspaceWidth, centerWidth]);

  useEffect(() => {
    persistDebugFlags({
      bootManualEnterAfterReady: debugConfig.bootManualEnterAfterReady,
      runSimulateSlowProgress: debugConfig.runSimulateSlowProgress,
      runVerboseLogs: debugConfig.runVerboseLogs,
      runProgressStep: parsePositiveFloatOr(debugConfig.runProgressStep, debugFlags.runProgressStep),
      runProgressIntervalMs: parsePositiveIntOr(
        debugConfig.runProgressIntervalMs,
        debugFlags.runProgressIntervalMs
      )
    });
  }, [debugConfig]);

  useEffect(() => {
    const unsubscribe = window.electronAPI.onWindowMaximizedChanged((payload) => {
      setIsWindowMaximized(!!payload.maximized);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    const el = workspaceRef.current;
    if (!el) return;
    const flushWidthCommit = (): void => {
      const next = pendingWorkspaceWidthRef.current;
      setWorkspaceWidth((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
      if (resizeCommitTimerRef.current !== null) {
        window.clearTimeout(resizeCommitTimerRef.current);
        resizeCommitTimerRef.current = null;
      }
      if (windowResizeActiveRef.current) {
        windowResizeActiveRef.current = false;
        setWindowResizeActive(false);
      }
    };

    const observer = new ResizeObserver((entries) => {
      const next = Math.max(0, Math.floor(entries[0].contentRect.width));
      pendingWorkspaceWidthRef.current = next;
      if (!windowResizeActiveRef.current) {
        windowResizeActiveRef.current = true;
        setWindowResizeActive(true);
      }
      if (resizeCommitTimerRef.current !== null) {
        window.clearTimeout(resizeCommitTimerRef.current);
      }
      resizeCommitTimerRef.current = window.setTimeout(() => {
        flushWidthCommit();
      }, 150);
    });

    const onMouseUp = (): void => {
      flushWidthCommit();
    };

    window.addEventListener("mouseup", onMouseUp);
    observer.observe(el);
    return () => {
      window.removeEventListener("mouseup", onMouseUp);
      observer.disconnect();
      if (resizeCommitTimerRef.current !== null) {
        window.clearTimeout(resizeCommitTimerRef.current);
        resizeCommitTimerRef.current = null;
      }
      windowResizeActiveRef.current = false;
      setWindowResizeActive(false);
    };
  }, []);

  useEffect(() => {
    pendingWorkspaceWidthRef.current = Math.max(0, window.innerWidth);
    if (!windowResizeActiveRef.current) {
      windowResizeActiveRef.current = true;
      setWindowResizeActive(true);
    }
    if (resizeCommitTimerRef.current !== null) {
      window.clearTimeout(resizeCommitTimerRef.current);
    }
    resizeCommitTimerRef.current = window.setTimeout(() => {
      const next = pendingWorkspaceWidthRef.current;
      setWorkspaceWidth((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
      windowResizeActiveRef.current = false;
      setWindowResizeActive(false);
      resizeCommitTimerRef.current = null;
    }, 150);
  }, [isWindowMaximized]);

  useEffect(() => {
    const logBody = logBodyRef.current;
    if (!logBody) return;
    logBody.scrollTop = logBody.scrollHeight;
  }, [logs]);

  useEffect(() => {
    if (!projectFolder) return;
    void refreshWorkspace(projectFolder);
  }, [preset, fluorescenceConfig.enabled, fluorescenceConfig.prefix]);

  useEffect(() => {
    if (!workspaceScan || fluorescenceAutoInitialized) return;
    const hasFluo = workspaceScan.pairs.some((pair) => pair.fluoPath.length > 0);
    setFluorescenceDraft((prev) => {
      if (prev.enabled === hasFluo) return prev;
      return {
        ...prev,
        enabled: hasFluo
      };
    });
    setFluorescenceAutoInitialized(true);
  }, [workspaceScan, fluorescenceAutoInitialized]);

  useEffect(() => {
    const pairs = workspaceScan?.pairs ?? [];
    setPairUiStateMap((prev) => {
      const next: Record<string, PairUiState> = {};
      for (const pair of pairs) {
        const old = prev[pair.id];
        const defaultMode: RoiUsageMode = pair.normalHasRoi ? "native" : "none";
        const nextMode =
          old?.roiMode === "auto"
            ? "auto"
            : old?.roiMode === "native" && pair.normalHasRoi
              ? "native"
              : defaultMode;
        next[pair.id] = {
          ignored: old?.ignored ?? false,
          roiMode: nextMode
        };
      }
      return next;
    });
  }, [workspaceScan]);

  useEffect(() => {
    previewCacheRef.current.clear();
    previewPrefetchingRef.current.clear();
  }, [workspaceScan?.rootPath]);

  useEffect(() => {
    const el = splitHostRef.current;
    if (!el) return;
    const flushSplitHostHeightCommit = (): void => {
      const next = pendingSplitHostHeightRef.current;
      setSplitHostHeight((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
      if (splitHostHeightCommitTimerRef.current !== null) {
        window.clearTimeout(splitHostHeightCommitTimerRef.current);
        splitHostHeightCommitTimerRef.current = null;
      }
    };
    const observer = new ResizeObserver((entries) => {
      const next = Math.floor(entries[0].contentRect.height);
      if (fileCollapsed || next <= 0) return;
      pendingSplitHostHeightRef.current = next;
      if (!windowResizeActiveRef.current) {
        setSplitHostHeight((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
        return;
      }
      if (splitHostHeightCommitTimerRef.current !== null) {
        window.clearTimeout(splitHostHeightCommitTimerRef.current);
      }
      splitHostHeightCommitTimerRef.current = window.setTimeout(() => {
        flushSplitHostHeightCommit();
      }, 150);
    });
    observer.observe(el);
    return () => {
      observer.disconnect();
      if (splitHostHeightCommitTimerRef.current !== null) {
        window.clearTimeout(splitHostHeightCommitTimerRef.current);
        splitHostHeightCommitTimerRef.current = null;
      }
    };
  }, [fileCollapsed]);

  useEffect(() => {
    const el = browserAreaRef.current;
    if (!el) return;
    const flushBrowserAreaHeightCommit = (): void => {
      const next = pendingBrowserAreaHeightRef.current;
      setBrowserAreaHeight((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
      if (browserAreaHeightCommitTimerRef.current !== null) {
        window.clearTimeout(browserAreaHeightCommitTimerRef.current);
        browserAreaHeightCommitTimerRef.current = null;
      }
    };
    const observer = new ResizeObserver((entries) => {
      const next = Math.floor(entries[0].contentRect.height);
      if (fileCollapsed || next <= 0) return;
      pendingBrowserAreaHeightRef.current = next;
      if (!windowResizeActiveRef.current) {
        setBrowserAreaHeight((prev) => (Math.abs(prev - next) >= 1 ? next : prev));
        return;
      }
      if (browserAreaHeightCommitTimerRef.current !== null) {
        window.clearTimeout(browserAreaHeightCommitTimerRef.current);
      }
      browserAreaHeightCommitTimerRef.current = window.setTimeout(() => {
        flushBrowserAreaHeightCommit();
      }, 150);
    });
    observer.observe(el);
    return () => {
      observer.disconnect();
      if (browserAreaHeightCommitTimerRef.current !== null) {
        window.clearTimeout(browserAreaHeightCommitTimerRef.current);
        browserAreaHeightCommitTimerRef.current = null;
      }
    };
  }, [fileCollapsed]);

  useEffect(() => {
    const el = previewViewportRef.current;
    if (!el) return;
    const observer = new ResizeObserver((entries) => {
      const r = entries[0].contentRect;
      setPreviewViewport({ width: Math.floor(r.width), height: Math.floor(r.height) });
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const helpProbe = (event: ReactMouseEvent<HTMLElement> | ReactFocusEvent<HTMLElement>): void => {
    const target = event.target as HTMLElement;
    const withHelp = target.closest("[data-help]") as HTMLElement | null;
    setHoverHelp(withHelp?.dataset.help ?? "");
  };

  const closeTextMenu = (): void => {
    setTextMenu({
      open: false,
      x: 0,
      y: 0,
      target: null
    });
  };

  const triggerPaneSnapAnimation = (): void => {
    setPaneSnapAnimating(true);
    if (paneSnapTimerRef.current !== null) {
      window.clearTimeout(paneSnapTimerRef.current);
    }
    paneSnapTimerRef.current = window.setTimeout(() => {
      setPaneSnapAnimating(false);
      paneSnapTimerRef.current = null;
    }, 240);
  };

  const lockPaneDragDuringSnap = (): void => {
    paneDragSnapLockRef.current = true;
    if (paneDragSnapLockTimerRef.current !== null) {
      window.clearTimeout(paneDragSnapLockTimerRef.current);
    }
    paneDragSnapLockTimerRef.current = window.setTimeout(() => {
      paneDragSnapLockRef.current = false;
      paneDragSnapLockTimerRef.current = null;
    }, 200);
  };

  const triggerFileSplitSnapAnimation = (): void => {
    setFileSplitSnapAnimating(true);
    if (fileSplitSnapTimerRef.current !== null) {
      window.clearTimeout(fileSplitSnapTimerRef.current);
    }
    fileSplitSnapTimerRef.current = window.setTimeout(() => {
      setFileSplitSnapAnimating(false);
      fileSplitSnapTimerRef.current = null;
    }, 240);
  };

  const lockFileSplitDragDuringSnap = (): void => {
    fileSplitDragSnapLockRef.current = true;
    if (fileSplitDragSnapLockTimerRef.current !== null) {
      window.clearTimeout(fileSplitDragSnapLockTimerRef.current);
    }
    fileSplitDragSnapLockTimerRef.current = window.setTimeout(() => {
      fileSplitDragSnapLockRef.current = false;
      fileSplitDragSnapLockTimerRef.current = null;
    }, 200);
  };

  const triggerTagListSnapAnimation = (): void => {
    setTagListSnapAnimating(true);
    if (tagListSnapTimerRef.current !== null) {
      window.clearTimeout(tagListSnapTimerRef.current);
    }
    tagListSnapTimerRef.current = window.setTimeout(() => {
      setTagListSnapAnimating(false);
      tagListSnapTimerRef.current = null;
    }, 240);
  };

  const lockTagListDragDuringSnap = (): void => {
    tagListDragSnapLockRef.current = true;
    if (tagListDragSnapLockTimerRef.current !== null) {
      window.clearTimeout(tagListDragSnapLockTimerRef.current);
    }
    tagListDragSnapLockTimerRef.current = window.setTimeout(() => {
      tagListDragSnapLockRef.current = false;
      tagListDragSnapLockTimerRef.current = null;
    }, 200);
  };

  const openTextMenu = (event: ReactMouseEvent<HTMLElement>): void => {
    const target = event.target as HTMLElement;
    const editable = findEditableTarget(target);
    if (!editable) return;
    event.preventDefault();
    setTextMenu({
      open: true,
      x: event.clientX,
      y: event.clientY,
      target: editable
    });
  };

  const closeOperationHeaderMenu = (): void => {
    setOperationHeaderMenu((prev) => (prev.open ? { ...prev, open: false } : prev));
  };

  const openOperationHeaderMenu = (event: ReactMouseEvent<HTMLElement>): void => {
    event.preventDefault();
    event.stopPropagation();
    setOperationHeaderMenu({
      open: true,
      x: event.clientX,
      y: event.clientY
    });
  };

  const expandAllOperationSections = (): void => {
    setOperationOpenSections(ALL_OPERATION_SECTIONS);
    setStatus("status.operationExpandedAll");
    appendLog(t("log.operationExpandedAll"));
    closeOperationHeaderMenu();
  };

  const collapseAllOperationSections = (): void => {
    setOperationOpenSections([]);
    setStatus("status.operationCollapsedAll");
    appendLog(t("log.operationCollapsedAll"));
    closeOperationHeaderMenu();
  };

  const applyTextMenuAction = async (action: TextMenuAction): Promise<void> => {
    const target = textMenu.target;
    if (!target) {
      closeTextMenu();
      return;
    }

    target.focus();

    if (action === "selectAll") {
      target.select();
      closeTextMenu();
      return;
    }

    let handled = false;
    try {
      handled = document.execCommand(action);
    } catch {
      handled = false;
    }

    if (action === "paste" && !handled) {
      try {
        const clip = await navigator.clipboard.readText();
        const start = target.selectionStart ?? target.value.length;
        const end = target.selectionEnd ?? target.value.length;
        target.setRangeText(clip, start, end, "end");
        target.dispatchEvent(new Event("input", { bubbles: true }));
      } catch {
      }
    }

    closeTextMenu();
  };

  const collapseFiles = (reason: CollapseReason): void => {
    if (!canCollapse(fileCollapsed, [fileCollapsed, settingsCollapsed, logCollapsed])) {
      return;
    }
    if (!fileCollapsed) {
      rememberedWidthRef.current.files = Math.max(FILE_MIN_WIDTH, leftWidth);
      setFileCollapsed(true);
    }
    setFileCollapsedAuto(reason === "auto");
  };

  const expandFiles = (preferred?: number, _reason: ExpandReason = "manual"): void => {
    const next = Math.max(FILE_MIN_WIDTH, preferred ?? rememberedWidthRef.current.files);
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));
    const centerFloor = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
    if (logCollapsed) {
      if (available - next - COLLAPSED_BAR_WIDTH < centerFloor) {
        return;
      }
    } else {
      const maxRight = available - next - centerFloor;
      if (maxRight < LOG_MIN_WIDTH) {
        return;
      }
      const clampedRight = clamp(Math.max(LOG_MIN_WIDTH, rightWidth), LOG_MIN_WIDTH, maxRight);
      rememberedWidthRef.current.logs = clampedRight;
      setRightWidth((prev) => (Math.abs(clampedRight - prev) >= 1 ? clampedRight : prev));
    }
    setLeftWidth(next);
    setFileCollapsedAuto(false);
    setFileCollapsed(false);
  };

  const collapseSettings = (): void => {
    if (!canCollapse(settingsCollapsed, [fileCollapsed, settingsCollapsed, logCollapsed])) {
      return;
    }
    if (!settingsCollapsed) {
      rememberedWidthRef.current.settings = Math.max(SETTINGS_MIN_WIDTH, liveLayoutRef.current.center);
      setSettingsCollapsed(true);
    }
  };

  const expandSettings = (preferred?: number): void => {
    const next = Math.max(SETTINGS_MIN_WIDTH, preferred ?? rememberedWidthRef.current.settings);
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));
    const leftNow = fileCollapsed ? COLLAPSED_BAR_WIDTH : Math.max(FILE_MIN_WIDTH, leftWidth);
    const rightNow = logCollapsed ? COLLAPSED_BAR_WIDTH : Math.max(LOG_MIN_WIDTH, rightWidth);
    if (available - leftNow - rightNow < SETTINGS_MIN_WIDTH) {
      return;
    }
    setSettingsCollapsed(false);
    setCenterWidth(next);
  };

  const collapseLog = (reason: CollapseReason = "manual"): void => {
    if (!canCollapse(logCollapsed, [fileCollapsed, settingsCollapsed, logCollapsed])) {
      return;
    }
    if (!logCollapsed) {
      const nextRemembered = Math.max(LOG_MIN_WIDTH, liveLayoutRef.current.right);
      rememberedWidthRef.current.logs = nextRemembered;
      setRightWidth(nextRemembered);
      setLogCollapsed(true);
    }
    setLogCollapsedAuto(reason === "auto");
  };

  const expandLog = (preferred?: number, _reason: ExpandReason = "manual"): void => {
    const targetRight = Math.max(LOG_MIN_WIDTH, preferred ?? rememberedWidthRef.current.logs);
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));
    const centerFloor = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
    if (fileCollapsed) {
      if (available - COLLAPSED_BAR_WIDTH - targetRight < centerFloor) {
        return;
      }
    } else {
      const maxLeft = available - targetRight - centerFloor;
      if (maxLeft < FILE_MIN_WIDTH) {
        return;
      }
      const clampedLeft = clamp(Math.max(FILE_MIN_WIDTH, leftWidth), FILE_MIN_WIDTH, maxLeft);
      setLeftWidth((prev) => (Math.abs(clampedLeft - prev) >= 1 ? clampedLeft : prev));
    }
    rememberedWidthRef.current.logs = targetRight;
    setRightWidth(targetRight);
    setLogCollapsedAuto(false);
    setLogCollapsed(false);
  };

  const forceExpandPane = (target: PanelKey): void => {
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));

    let nextFileCollapsed = fileCollapsed;
    let nextSettingsCollapsed = settingsCollapsed;
    let nextLogCollapsed = logCollapsed;

    if (target === "files") nextFileCollapsed = false;
    if (target === "settings") nextSettingsCollapsed = false;
    if (target === "logs") nextLogCollapsed = false;

    const minNeed = (): number =>
      (nextFileCollapsed ? COLLAPSED_BAR_WIDTH : FILE_MIN_WIDTH) +
      (nextSettingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH) +
      (nextLogCollapsed ? COLLAPSED_BAR_WIDTH : LOG_MIN_WIDTH);

    const collapseOrder: PanelKey[] =
      target === "files"
        ? ["settings", "logs"]
        : target === "settings"
          ? ["logs", "files"]
          : ["settings", "files"];

    for (const pane of collapseOrder) {
      if (minNeed() <= available) break;
      if (pane === "files") nextFileCollapsed = true;
      if (pane === "settings") nextSettingsCollapsed = true;
      if (pane === "logs") nextLogCollapsed = true;
    }

    let nextLeft = nextFileCollapsed
      ? COLLAPSED_BAR_WIDTH
      : Math.max(FILE_MIN_WIDTH, target === "files" ? rememberedWidthRef.current.files : leftWidth);
    let nextRight = nextLogCollapsed
      ? COLLAPSED_BAR_WIDTH
      : Math.max(LOG_MIN_WIDTH, target === "logs" ? rememberedWidthRef.current.logs : rightWidth);
    let nextCenter = nextSettingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;

    if (nextSettingsCollapsed) {
      const sideAvailable = Math.max(0, available - COLLAPSED_BAR_WIDTH);
      if (nextFileCollapsed && !nextLogCollapsed) {
        nextLeft = COLLAPSED_BAR_WIDTH;
        nextRight = Math.max(LOG_MIN_WIDTH, sideAvailable - nextLeft);
      } else if (!nextFileCollapsed && nextLogCollapsed) {
        nextRight = COLLAPSED_BAR_WIDTH;
        nextLeft = Math.max(FILE_MIN_WIDTH, sideAvailable - nextRight);
      } else if (!nextFileCollapsed && !nextLogCollapsed) {
        const maxLeft = Math.max(FILE_MIN_WIDTH, sideAvailable - LOG_MIN_WIDTH);
        nextLeft = clamp(nextLeft, FILE_MIN_WIDTH, maxLeft);
        nextRight = Math.max(LOG_MIN_WIDTH, sideAvailable - nextLeft);
      } else {
        nextLeft = COLLAPSED_BAR_WIDTH;
        nextRight = Math.max(COLLAPSED_BAR_WIDTH, sideAvailable - nextLeft);
      }
      nextCenter = COLLAPSED_BAR_WIDTH;
    } else {
      const leftFloor = nextFileCollapsed ? COLLAPSED_BAR_WIDTH : FILE_MIN_WIDTH;
      const rightFloor = nextLogCollapsed ? COLLAPSED_BAR_WIDTH : LOG_MIN_WIDTH;

      if (!nextFileCollapsed) {
        const maxLeft = Math.max(FILE_MIN_WIDTH, available - SETTINGS_MIN_WIDTH - rightFloor);
        nextLeft = clamp(nextLeft, FILE_MIN_WIDTH, maxLeft);
      }
      if (!nextLogCollapsed) {
        const maxRight = Math.max(LOG_MIN_WIDTH, available - SETTINGS_MIN_WIDTH - leftFloor);
        nextRight = clamp(nextRight, LOG_MIN_WIDTH, maxRight);
      }

      nextCenter = available - nextLeft - nextRight;
      if (nextCenter < SETTINGS_MIN_WIDTH) {
        let deficit = SETTINGS_MIN_WIDTH - nextCenter;
        if (!nextLogCollapsed && nextRight > LOG_MIN_WIDTH) {
          const cut = Math.min(deficit, nextRight - LOG_MIN_WIDTH);
          nextRight -= cut;
          deficit -= cut;
        }
        if (deficit > 0 && !nextFileCollapsed && nextLeft > FILE_MIN_WIDTH) {
          const cut = Math.min(deficit, nextLeft - FILE_MIN_WIDTH);
          nextLeft -= cut;
          deficit -= cut;
        }
        nextCenter = Math.max(SETTINGS_MIN_WIDTH, available - nextLeft - nextRight);
      }
    }

    if (!nextFileCollapsed) {
      rememberedWidthRef.current.files = Math.max(FILE_MIN_WIDTH, nextLeft);
      setLeftWidth(nextLeft);
    }
    if (!nextSettingsCollapsed) {
      rememberedWidthRef.current.settings = Math.max(SETTINGS_MIN_WIDTH, nextCenter);
      setCenterWidth(nextCenter);
    } else {
      setCenterWidth(COLLAPSED_BAR_WIDTH);
    }
    if (!nextLogCollapsed) {
      rememberedWidthRef.current.logs = Math.max(LOG_MIN_WIDTH, nextRight);
      setRightWidth(nextRight);
    }

    setFileCollapsed(nextFileCollapsed);
    setSettingsCollapsed(nextSettingsCollapsed);
    setLogCollapsed(nextLogCollapsed);
    setFileCollapsedAuto(false);
    setLogCollapsedAuto(false);
  };

  useEffect(() => {
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));
    const centerFloor = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
    const fileExpandedWidth = Math.max(FILE_MIN_WIDTH, fileCollapsed ? rememberedWidthRef.current.files : leftWidth);
    const logExpandedWidth = Math.max(LOG_MIN_WIDTH, logCollapsed ? rememberedWidthRef.current.logs : rightWidth);

    if (!fileCollapsed) {
      const required = fileExpandedWidth + (logCollapsed ? COLLAPSED_BAR_WIDTH : logExpandedWidth) + centerFloor;
      if (available < required) {
        collapseFiles("auto");
        setStatus("status.windowNarrowed");
        return;
      }
    }

    if (fileCollapsed && !logCollapsed) {
      const required = COLLAPSED_BAR_WIDTH + logExpandedWidth + centerFloor;
      if (available < required) {
        collapseLog("auto");
        return;
      }
    }

    if (logCollapsed && logCollapsedAuto) {
      const required = (fileCollapsed ? COLLAPSED_BAR_WIDTH : fileExpandedWidth) + logExpandedWidth + centerFloor;
      if (available >= required) {
        expandLog(undefined, "auto");
        return;
      }
    }

    if (fileCollapsed && fileCollapsedAuto && !logCollapsed) {
      const required = fileExpandedWidth + logExpandedWidth + centerFloor;
      if (available >= required) {
        expandFiles(undefined, "auto");
        setStatus("status.windowRestored");
      }
    }
  }, [
    workspaceWidth,
    fileCollapsed,
    fileCollapsedAuto,
    logCollapsed,
    logCollapsedAuto,
    leftWidth,
    rightWidth,
    settingsCollapsed
  ]);

  useEffect(() => {
    if (fileCollapsed && settingsCollapsed && logCollapsed) {
      setSettingsCollapsed(false);
      setCenterWidth((prev) => Math.max(SETTINGS_MIN_WIDTH, prev || rememberedWidthRef.current.settings));
    }
  }, [fileCollapsed, settingsCollapsed, logCollapsed]);

  const handleSelectFolder = async (): Promise<void> => {
    const folder = await window.electronAPI.selectFolder();
    if (!folder) {
      setStatus("status.folderCanceled");
      appendLog(t("log.folderCanceled"));
      return;
    }

    setProjectFolder(folder);
    setFolderInput(folder);
    setFluorescenceAutoInitialized(false);
    setStatus("status.folderSelected");
    appendLog(t("log.folderSelected", { folder }));
    await refreshWorkspace(folder);
  };

  const handleApplyFolderInput = async (): Promise<void> => {
    const path = folderInput.trim();
    if (!path) {
      setStatus("status.scanNeedFolder");
      return;
    }
    setProjectFolder(path);
    setFluorescenceAutoInitialized(false);
    setStatus("status.folderSelected");
    appendLog(t("log.folderFromAddress", { folder: path }));
    await refreshWorkspace(path);
  };

  const filesApplySignature = useMemo(() => {
    return [
      folderInput.trim(),
      preset,
      subfolderMode,
      namingCustomEnabled ? "1" : "0",
      projectNamingRule,
      timeNamingRule,
      stableSerializeIdSet(ignoredNodeIds),
      stableSerializeNodeRoleOverrides(nodeRoleOverrides)
    ].join("||");
  }, [
    folderInput,
    preset,
    subfolderMode,
    namingCustomEnabled,
    projectNamingRule,
    timeNamingRule,
    ignoredNodeIds,
    nodeRoleOverrides
  ]);

  const cellRoiApplySignature = useMemo(() => {
    return [
      minArea.trim(),
      maxArea.trim(),
      circularity.trim(),
      autoCellArea.trim(),
      roiSuffix.trim(),
      stableSerializePairUiStateMap(pairUiStateMap)
    ].join("||");
  }, [minArea, maxArea, circularity, autoCellArea, roiSuffix, pairUiStateMap]);

  useEffect(() => {
    if (filesAppliedSignatureRef.current === null) {
      filesAppliedSignatureRef.current = filesApplySignature;
    }
    if (cellRoiAppliedSignatureRef.current === null) {
      cellRoiAppliedSignatureRef.current = cellRoiApplySignature;
    }
  }, [filesApplySignature, cellRoiApplySignature]);

  const applyFilesSection = async (): Promise<void> => {
    const path = folderInput.trim();
    if (path) {
      setProjectFolder(path);
      setFluorescenceAutoInitialized(false);
      await refreshWorkspace(path);
    }
    filesAppliedSignatureRef.current = filesApplySignature;
    setStatus("status.sectionApplied");
    appendLog(
      t("log.sectionApplied", {
        section: t("op.section.files")
      })
    );
  };

  const applyCellRoiSection = async (): Promise<void> => {
    const path = folderInput.trim();
    if (path) {
      setProjectFolder(path);
      await refreshWorkspace(path);
    }
    cellRoiAppliedSignatureRef.current = cellRoiApplySignature;
    setStatus("status.sectionApplied");
    appendLog(
      t("log.sectionApplied", {
        section: t("op.section.cellRoi")
      })
    );
  };

  const handleLearnFluorescenceParams = (): void => {
    setStatus("status.sectionApplied");
    appendLog(
      t("log.sectionApplied", {
        section: t("field.fluoLearnParams")
      })
    );
  };

  const handleLearnFluorescenceRoi = (pair: WorkspacePair): void => {
    const name = pair.fluoName || pair.normalName || pair.id;
    appendLog(
      t("log.sectionApplied", {
        section: `${t("menu.image.learnFluoRoi")} (${name})`
      })
    );
  };

  const applyDataDraft = (): void => {
    setDataConfig(dataDraft);
    setStatus("status.sectionApplied");
    appendLog(
      t("log.sectionApplied", {
        section: t("op.section.data")
      })
    );
  };

  const applyDebugDraft = (): void => {
    const normalized: RuntimeDebugConfig = {
      bootManualEnterAfterReady: debugDraft.bootManualEnterAfterReady,
      runSimulateSlowProgress: debugDraft.runSimulateSlowProgress,
      runProgressStep: String(parsePositiveFloatOr(debugDraft.runProgressStep, debugFlags.runProgressStep)),
      runProgressIntervalMs: String(
        parsePositiveIntOr(debugDraft.runProgressIntervalMs, debugFlags.runProgressIntervalMs)
      ),
      runVerboseLogs: debugDraft.runVerboseLogs
    };
    setDebugDraft(normalized);
    setDebugConfig(normalized);
    setStatus("status.sectionApplied");
    appendLog(
      t("log.sectionApplied", {
        section: t("op.section.debug")
      })
    );
  };

  useEffect(() => {
    setExclusionConfig(exclusionDraft);
  }, [exclusionDraft]);

  useEffect(() => {
    const normalized: FluorescenceConfig = {
      enabled: fluorescenceDraft.enabled,
      prefix: fluorescenceDraft.prefix.trim() || "#",
      targetRgb: fluorescenceDraft.targetRgb.trim(),
      nearRgb: fluorescenceDraft.nearRgb.trim(),
      tolerance: fluorescenceDraft.tolerance,
      exclEnabled: fluorescenceDraft.exclEnabled,
      exclRgb: fluorescenceDraft.exclRgb.trim(),
      exclTolerance: fluorescenceDraft.exclTolerance
    };
    setFluorescenceConfig((prev) => {
      if (
        prev.enabled === normalized.enabled &&
        prev.prefix === normalized.prefix &&
        prev.targetRgb === normalized.targetRgb &&
        prev.nearRgb === normalized.nearRgb &&
        prev.tolerance === normalized.tolerance &&
        prev.exclEnabled === normalized.exclEnabled &&
        prev.exclRgb === normalized.exclRgb &&
        prev.exclTolerance === normalized.exclTolerance
      ) {
        return prev;
      }
      return normalized;
    });
  }, [fluorescenceDraft]);

  const saveWorkbenchConfig = (): void => {
    try {
      const payload = {
        folderInput,
        preset,
        mode,
        subfolderMode,
        namingCustomEnabled,
        projectNamingRule,
        timeNamingRule,
        minArea,
        maxArea,
        circularity,
        allowClumpsTarget,
        centerDiffThreshold,
        bgDiffThreshold,
        smallAreaRatio,
        clumpMinRatio,
        useMinPhago,
        usePixelCount,
        strictMode,
        rollingRadius,
        autoCellArea,
        roiSuffix,
        featureFlags,
        targetUseRoundFilter,
        targetMinContrast,
        exclusionDraft,
        fluorescenceDraft,
        dataDraft,
        debugDraft
      };
      window.localStorage.setItem(SETTINGS_CONFIG_STORAGE_KEY, JSON.stringify(payload));
      setStatus("status.configSaved");
      appendLog(t("log.configSaved"));
    } catch (error) {
      setStatus("status.configSaveFailed");
      appendLog(
        t("log.configSaveFailed", {
          error: error instanceof Error ? error.message : "save_failed"
        })
      );
    }
  };

  const loadWorkbenchConfig = async (): Promise<void> => {
    try {
      const raw = window.localStorage.getItem(SETTINGS_CONFIG_STORAGE_KEY);
      if (!raw) {
        setStatus("status.configNotFound");
        appendLog(t("log.configNotFound"));
        return;
      }

      const parsed = JSON.parse(raw) as Partial<{
        folderInput: string;
        preset: FilePreset;
        mode: string;
        subfolderMode: SubfolderMode;
        namingCustomEnabled: boolean;
        projectNamingRule: NamingProjectRule;
        timeNamingRule: NamingTimeRule;
        minArea: string;
        maxArea: string;
        circularity: string;
        allowClumpsTarget: boolean;
        centerDiffThreshold: string;
        bgDiffThreshold: string;
        smallAreaRatio: string;
        clumpMinRatio: string;
        useMinPhago: boolean;
        usePixelCount: boolean;
        strictMode: StrictMode;
        rollingRadius: string;
        autoCellArea: string;
        roiSuffix: string;
        featureFlags: Record<FeatureKey, boolean>;
        targetUseRoundFilter: boolean;
        targetMinContrast: string;
        exclusionDraft: ExclusionConfig;
        fluorescenceDraft: FluorescenceConfig;
        dataDraft: DataConfig;
        debugDraft: RuntimeDebugConfig;
        runtimeDebugConfig: RuntimeDebugConfig;
      }>;

      if (typeof parsed.folderInput === "string") {
        setFolderInput(parsed.folderInput);
        setProjectFolder(parsed.folderInput);
      }
      if (parsed.preset === "WINDOWS" || parsed.preset === "DOLPHIN" || parsed.preset === "MACOS") {
        setPreset(parsed.preset);
      }
      if (typeof parsed.mode === "string") setMode(parsed.mode);
      if (parsed.subfolderMode === "keep" || parsed.subfolderMode === "flat") setSubfolderMode(parsed.subfolderMode);
      if (typeof parsed.namingCustomEnabled === "boolean") setNamingCustomEnabled(parsed.namingCustomEnabled);
      if (parsed.projectNamingRule === "filename" || parsed.projectNamingRule === "folder") {
        setProjectNamingRule(parsed.projectNamingRule);
      }
      if (parsed.timeNamingRule === "folder" || parsed.timeNamingRule === "filename") {
        setTimeNamingRule(parsed.timeNamingRule);
      }
      if (typeof parsed.minArea === "string") setMinArea(parsed.minArea);
      if (typeof parsed.maxArea === "string") setMaxArea(parsed.maxArea);
      if (typeof parsed.circularity === "string") setCircularity(parsed.circularity);
      if (typeof parsed.allowClumpsTarget === "boolean") setAllowClumpsTarget(parsed.allowClumpsTarget);
      if (typeof parsed.centerDiffThreshold === "string") setCenterDiffThreshold(parsed.centerDiffThreshold);
      if (typeof parsed.bgDiffThreshold === "string") setBgDiffThreshold(parsed.bgDiffThreshold);
      if (typeof parsed.smallAreaRatio === "string") setSmallAreaRatio(parsed.smallAreaRatio);
      if (typeof parsed.clumpMinRatio === "string") setClumpMinRatio(parsed.clumpMinRatio);
      if (typeof parsed.useMinPhago === "boolean") setUseMinPhago(parsed.useMinPhago);
      if (typeof parsed.usePixelCount === "boolean") setUsePixelCount(parsed.usePixelCount);
      if (parsed.strictMode === "S" || parsed.strictMode === "N" || parsed.strictMode === "L") setStrictMode(parsed.strictMode);
      if (typeof parsed.rollingRadius === "string") setRollingRadius(parsed.rollingRadius);
      if (typeof parsed.autoCellArea === "string") setAutoCellArea(parsed.autoCellArea);
      if (typeof parsed.roiSuffix === "string") setRoiSuffix(parsed.roiSuffix);
      if (parsed.featureFlags) {
        setFeatureFlags(normalizeFeatureFlagSet({
          f1: !!parsed.featureFlags.f1,
          f2: !!parsed.featureFlags.f2,
          f3: !!parsed.featureFlags.f3,
          f5: !!parsed.featureFlags.f5,
          f6: !!parsed.featureFlags.f6
        }));
      }
      if (typeof parsed.targetUseRoundFilter === "boolean") setTargetUseRoundFilter(parsed.targetUseRoundFilter);
      if (typeof parsed.targetMinContrast === "string") setTargetMinContrast(parsed.targetMinContrast);

      if (parsed.exclusionDraft) {
        const loadedMode = String((parsed.exclusionDraft as { mode?: string }).mode ?? "");
        const normalizedExclusion: ExclusionConfig = {
          enabled: !!parsed.exclusionDraft.enabled,
          mode: loadedMode === "low" || loadedMode === "dark" ? "dark" : "bright",
          threshold: parsed.exclusionDraft.threshold ?? "0.5",
          strict: !!parsed.exclusionDraft.strict,
          sizeGate: parsed.exclusionDraft.sizeGate ?? true,
          minArea: parsed.exclusionDraft.minArea ?? "12",
          maxArea: parsed.exclusionDraft.maxArea ?? "320"
        };
        setExclusionDraft(normalizedExclusion);
        setExclusionConfig(normalizedExclusion);
      }
      if (parsed.fluorescenceDraft) {
        const normalized: FluorescenceConfig = {
          enabled: !!parsed.fluorescenceDraft.enabled,
          prefix: parsed.fluorescenceDraft.prefix?.trim() || "#",
          targetRgb: parsed.fluorescenceDraft.targetRgb || "0,255,0",
          nearRgb: parsed.fluorescenceDraft.nearRgb || "45,255,45",
          tolerance: parsed.fluorescenceDraft.tolerance || "22",
          exclEnabled: !!parsed.fluorescenceDraft.exclEnabled,
          exclRgb: parsed.fluorescenceDraft.exclRgb || "",
          exclTolerance: parsed.fluorescenceDraft.exclTolerance || "18"
        };
        setFluorescenceDraft(normalized);
        setFluorescenceConfig(normalized);
      }
      if (parsed.dataDraft) {
        const normalizedData: DataConfig = {
          formatColumns: parsed.dataDraft.formatColumns ?? "P,T,F,TB,TPC,ETPC,TPCSEM",
          autoNoiseOptimize: parsed.dataDraft.autoNoiseOptimize ?? false,
          groupByTime: parsed.dataDraft.groupByTime ?? true,
          expandPerCell: parsed.dataDraft.expandPerCell ?? true
        };
        setDataDraft(normalizedData);
        setDataConfig(normalizedData);
      }
      const loadedDebug = parsed.debugDraft ?? parsed.runtimeDebugConfig;
      if (loadedDebug) {
        const normalized: RuntimeDebugConfig = {
          bootManualEnterAfterReady: !!loadedDebug.bootManualEnterAfterReady,
          runSimulateSlowProgress: !!loadedDebug.runSimulateSlowProgress,
          runProgressStep: loadedDebug.runProgressStep || String(debugFlags.runProgressStep),
          runProgressIntervalMs: loadedDebug.runProgressIntervalMs || String(debugFlags.runProgressIntervalMs),
          runVerboseLogs: !!loadedDebug.runVerboseLogs
        };
        setDebugDraft(normalized);
        setDebugConfig(normalized);
      }

      setStatus("status.configLoaded");
      appendLog(t("log.configLoaded"));

      const nextFolder = typeof parsed.folderInput === "string" ? parsed.folderInput.trim() : "";
      if (nextFolder) {
        await refreshWorkspace(nextFolder);
      }
    } catch (error) {
      setStatus("status.configLoadFailed");
      appendLog(
        t("log.configLoadFailed", {
          error: error instanceof Error ? error.message : "load_failed"
        })
      );
    }
  };

  const handleRun = (): void => {
    if (!projectFolder) {
      setStatus("status.runNeedFolder");
      return;
    }
    if (isRunning) {
      return;
    }

    setStatus("status.runAccepted");
    appendLog(t("log.runClicked"));
    appendLog(
      t("log.config", {
        mode,
        preset,
        minA: minArea,
        maxA: maxArea,
        circ: circularity
      })
    );
    appendLog(
      t("log.runFlags", {
        exclusion: exclusionConfig.enabled ? "ON" : "OFF",
        fluo: fluorescenceConfig.enabled ? "ON" : "OFF",
        data: dataConfig.expandPerCell ? "per-cell" : "summary"
      })
    );
    if (debugConfig.runVerboseLogs) {
      appendLog(
        t("log.debugFlags", {
          splashPause: debugConfig.bootManualEnterAfterReady ? "ON" : "OFF",
          slowRun: debugConfig.runSimulateSlowProgress ? "ON" : "OFF",
          step: debugConfig.runProgressStep,
          tick: debugConfig.runProgressIntervalMs
        })
      );
    }
    appendLog(t("log.uiOnly"));

    setIsRunning(true);
    setRunProgress(0);
    const progressStep = parsePositiveFloatOr(debugConfig.runProgressStep, debugFlags.runProgressStep);
    const progressIntervalMs = parsePositiveIntOr(debugConfig.runProgressIntervalMs, debugFlags.runProgressIntervalMs);
    const runSimulateSlow = debugConfig.runSimulateSlowProgress;
    if (runTimerRef.current !== null) {
      window.clearInterval(runTimerRef.current);
    }
    if (!runSimulateSlow) {
      setRunProgress(100);
      setIsRunning(false);
      setStatus("status.runDone");
      appendLog(t("log.runDone"));
      return;
    }
    runTimerRef.current = window.setInterval(() => {
      setRunProgress((prev) => {
        const next = Math.min(100, prev + progressStep);
        if (next >= 100) {
          if (runTimerRef.current !== null) {
            window.clearInterval(runTimerRef.current);
            runTimerRef.current = null;
          }
          setIsRunning(false);
          setStatus("status.runDone");
          appendLog(t("log.runDone"));
        }
        return next;
      });
    }, progressIntervalMs);
  };

  const beginDrag = (mode: DragMode, clientX: number): void => {
    if (!mode) return;
    const currentLayout = liveLayoutRef.current;
    dragStartRef.current = {
      x: clientX,
      left: currentLayout.left,
      center: currentLayout.center,
      right: currentLayout.right
    };
    setDragMode(mode);
    setActivePanel(mode === "left" ? "files" : "settings");
  };

  useEffect(() => {
    if (!dragMode) return;

    const onMove = (event: MouseEvent): void => {
      if (paneDragSnapLockRef.current) return;
      const total = Math.max(0, workspaceWidth);
      const available = Math.max(0, total - (2 * RESIZER_WIDTH));
      const delta = event.clientX - dragStartRef.current.x;

      if (dragMode === "left") {
        const rightFixed = dragStartRef.current.right;
        const desiredLeft = dragStartRef.current.left + delta;

        if (fileCollapsed) {
          const restoreTarget = Math.max(FILE_MIN_WIDTH, rememberedWidthRef.current.files);
          const centerFloorNow = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
          if (desiredLeft >= FILE_RESTORE_TRIGGER && (available - restoreTarget - rightFixed >= centerFloorNow)) {
            triggerPaneSnapAnimation();
            lockPaneDragDuringSnap();
            expandFiles(restoreTarget, "manual");
          }
          return;
        }

        if (desiredLeft <= FILE_COLLAPSE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          collapseFiles("manual");
          return;
        }

        const desiredCenterRaw = available - rightFixed - desiredLeft;
        if (!settingsCollapsed && desiredCenterRaw <= SETTINGS_COLLAPSE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          collapseSettings();
          const maxLeftCollapsed = Math.max(FILE_MIN_WIDTH, available - rightFixed - COLLAPSED_BAR_WIDTH);
          const nextLeftCollapsed = clamp(desiredLeft, FILE_MIN_WIDTH, maxLeftCollapsed);
          setLeftWidth((prev) => (Math.abs(nextLeftCollapsed - prev) >= 1 ? nextLeftCollapsed : prev));
          setCenterWidth(COLLAPSED_BAR_WIDTH);
          return;
        }

        if (settingsCollapsed && desiredCenterRaw >= SETTINGS_RESTORE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          const maxLeftExpanded = Math.max(FILE_MIN_WIDTH, available - rightFixed - SETTINGS_MIN_WIDTH);
          const nextLeftExpanded = clamp(
            desiredLeft,
            FILE_MIN_WIDTH,
            maxLeftExpanded
          );
          const nextCenterExpanded = Math.max(SETTINGS_MIN_WIDTH, available - rightFixed - nextLeftExpanded);
          expandSettings(nextCenterExpanded);
          setLeftWidth((prev) => (Math.abs(nextLeftExpanded - prev) >= 1 ? nextLeftExpanded : prev));
          return;
        }

        if (settingsCollapsed) {
          const minLeft = FILE_MIN_WIDTH;
          const maxLeft = Math.max(minLeft, available - COLLAPSED_BAR_WIDTH - (logCollapsed ? COLLAPSED_BAR_WIDTH : LOG_MIN_WIDTH));
          const nextLeft = clamp(desiredLeft, minLeft, maxLeft);
          setLeftWidth((prev) => (Math.abs(nextLeft - prev) >= 1 ? nextLeft : prev));
          setCenterWidth(COLLAPSED_BAR_WIDTH);
          return;
        }

        const centerFloor = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
        const maxLeft = Math.max(FILE_MIN_WIDTH, available - rightFixed - centerFloor);
        const nextLeft = clamp(desiredLeft, FILE_MIN_WIDTH, maxLeft);
        const nextCenter = Math.max(0, available - rightFixed - nextLeft);
        setLeftWidth((prev) => (Math.abs(nextLeft - prev) >= 1 ? nextLeft : prev));
        setCenterWidth((prev) => (Math.abs(nextCenter - prev) >= 1 ? nextCenter : prev));
        return;
      }

      if (dragMode === "center") {
        const leftFixed = dragStartRef.current.left;
        const desiredRight = dragStartRef.current.right - delta;
        const desiredCenterRaw = available - leftFixed - desiredRight;

        if (logCollapsed) {
          const restoreTarget = Math.max(LOG_MIN_WIDTH, rememberedWidthRef.current.logs);
          const centerFloorNow = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
          if (desiredRight >= LOG_RESTORE_TRIGGER && (available - leftFixed - restoreTarget >= centerFloorNow)) {
            triggerPaneSnapAnimation();
            lockPaneDragDuringSnap();
            expandLog(restoreTarget, "manual");
          }
          return;
        }
        if (desiredRight <= LOG_COLLAPSE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          collapseLog("manual");
          return;
        }

        if (!settingsCollapsed && desiredCenterRaw <= SETTINGS_COLLAPSE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          collapseSettings();
          const maxRightCollapsed = Math.max(LOG_MIN_WIDTH, available - leftFixed - COLLAPSED_BAR_WIDTH);
          const nextRightCollapsed = clamp(desiredRight, LOG_MIN_WIDTH, maxRightCollapsed);
          rememberedWidthRef.current.logs = nextRightCollapsed;
          setRightWidth((prev) => (Math.abs(nextRightCollapsed - prev) >= 1 ? nextRightCollapsed : prev));
          setCenterWidth(COLLAPSED_BAR_WIDTH);
          return;
        }

        if (settingsCollapsed && desiredCenterRaw >= SETTINGS_RESTORE_TRIGGER) {
          triggerPaneSnapAnimation();
          lockPaneDragDuringSnap();
          const maxRightExpanded = Math.max(LOG_MIN_WIDTH, available - leftFixed - SETTINGS_MIN_WIDTH);
          const nextRightExpanded = clamp(desiredRight, LOG_MIN_WIDTH, maxRightExpanded);
          rememberedWidthRef.current.logs = nextRightExpanded;
          setRightWidth((prev) => (Math.abs(nextRightExpanded - prev) >= 1 ? nextRightExpanded : prev));
          const nextCenterExpanded = Math.max(SETTINGS_MIN_WIDTH, available - leftFixed - nextRightExpanded);
          expandSettings(nextCenterExpanded);
          return;
        }

        if (settingsCollapsed) {
          const leftFloor = fileCollapsed ? COLLAPSED_BAR_WIDTH : FILE_MIN_WIDTH;
          const maxRight = Math.max(LOG_MIN_WIDTH, available - leftFloor - COLLAPSED_BAR_WIDTH);
          const nextRight = clamp(desiredRight, LOG_MIN_WIDTH, maxRight);
          rememberedWidthRef.current.logs = nextRight;
          setRightWidth((prev) => (Math.abs(nextRight - prev) >= 1 ? nextRight : prev));
          if (!fileCollapsed) {
            const nextLeft = Math.max(FILE_MIN_WIDTH, available - COLLAPSED_BAR_WIDTH - nextRight);
            setLeftWidth((prev) => (Math.abs(nextLeft - prev) >= 1 ? nextLeft : prev));
          }
          setCenterWidth(COLLAPSED_BAR_WIDTH);
          return;
        }

        const centerFloor = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;
        const maxRight = Math.max(LOG_MIN_WIDTH, available - leftFixed - centerFloor);
        const nextRight = clamp(desiredRight, LOG_MIN_WIDTH, maxRight);
        rememberedWidthRef.current.logs = nextRight;
        setRightWidth((prev) => (Math.abs(nextRight - prev) >= 1 ? nextRight : prev));
        const nextCenter = Math.max(0, available - leftFixed - nextRight);
        setCenterWidth((prev) => (Math.abs(nextCenter - prev) >= 1 ? nextCenter : prev));
      }
    };

    const onUp = (): void => {
      setDragMode(null);
      paneDragSnapLockRef.current = false;
      if (paneDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(paneDragSnapLockTimerRef.current);
        paneDragSnapLockTimerRef.current = null;
      }
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [dragMode, workspaceWidth, fileCollapsed, settingsCollapsed, logCollapsed, leftWidth, rightWidth]);
  const layout = useMemo(() => {
    const total = Math.max(0, workspaceWidth);
    const available = Math.max(0, total - (2 * RESIZER_WIDTH));
    const leftFloor = fileCollapsed ? COLLAPSED_BAR_WIDTH : FILE_MIN_WIDTH;
    const rightFloor = logCollapsed ? COLLAPSED_BAR_WIDTH : LOG_MIN_WIDTH;
    let left = fileCollapsed ? COLLAPSED_BAR_WIDTH : Math.max(FILE_MIN_WIDTH, leftWidth);
    let right = logCollapsed ? COLLAPSED_BAR_WIDTH : Math.max(LOG_MIN_WIDTH, rightWidth);
    let center = settingsCollapsed ? COLLAPSED_BAR_WIDTH : SETTINGS_MIN_WIDTH;

    if (settingsCollapsed) {
      const sideAvailable = Math.max(0, available - COLLAPSED_BAR_WIDTH);
      if (fileCollapsed && !logCollapsed) {
        left = COLLAPSED_BAR_WIDTH;
        right = Math.max(LOG_MIN_WIDTH, sideAvailable - left);
      } else if (!fileCollapsed && logCollapsed) {
        right = COLLAPSED_BAR_WIDTH;
        left = Math.max(FILE_MIN_WIDTH, sideAvailable - right);
      } else if (!fileCollapsed && !logCollapsed) {
        const maxLeft = Math.max(leftFloor, sideAvailable - rightFloor);
        left = clamp(left, leftFloor, maxLeft);
        right = Math.max(rightFloor, sideAvailable - left);
        if (right < rightFloor) {
          right = rightFloor;
          left = Math.max(leftFloor, sideAvailable - right);
        }
      } else {
        left = COLLAPSED_BAR_WIDTH;
        right = Math.max(0, sideAvailable - left);
      }
      center = COLLAPSED_BAR_WIDTH;
    } else {
      center = Math.max(SETTINGS_MIN_WIDTH, available - left - right);
      const required = left + right + center;
      if (required > available) {
        let overflow = required - available;
        if (!logCollapsed && right > LOG_MIN_WIDTH) {
          const cut = Math.min(overflow, right - LOG_MIN_WIDTH);
          right -= cut;
          overflow -= cut;
        }
        if (overflow > 0 && !fileCollapsed && left > FILE_MIN_WIDTH) {
          const cut = Math.min(overflow, left - FILE_MIN_WIDTH);
          left -= cut;
          overflow -= cut;
        }
        center = Math.max(0, available - left - right);
      } else {
        center = Math.max(0, available - left - right);
      }
    }

    return {
      left,
      center,
      right,
      template: `${left}px ${RESIZER_WIDTH}px ${center}px ${RESIZER_WIDTH}px ${right}px`
    };
  }, [workspaceWidth, leftWidth, centerWidth, rightWidth, fileCollapsed, settingsCollapsed, logCollapsed]);

  useEffect(() => {
    liveLayoutRef.current = {
      left: layout.left,
      center: layout.center,
      right: layout.right
    };
  }, [layout.left, layout.center, layout.right]);

  useEffect(() => {
    if (logCollapsed) return;
    if (Math.abs(layout.right - rightWidth) < 1) return;
    const synced = Math.max(LOG_MIN_WIDTH, layout.right);
    rememberedWidthRef.current.logs = synced;
    setRightWidth(synced);
  }, [layout.right, logCollapsed, rightWidth]);

  const treeModel = useMemo(() => {
    return buildTreeNodes(workspaceScan?.pairs ?? [], t("file.treeEmptyProject"));
  }, [workspaceScan, t]);
  const treeNodes = treeModel.roots;
  const pairNodePathMap = treeModel.pairNodePathMap;
  const defaultNodeRoles = treeModel.defaultNodeRoles;

  const allNodes = useMemo(() => flattenNodes(treeNodes), [treeNodes]);

  const treeNodeMap = useMemo(() => {
    const map = new Map<string, TreeNode>();
    for (const n of allNodes) {
      map.set(n.id, n);
    }
    return map;
  }, [allNodes]);

  useEffect(() => {
    const valid = new Set<string>(allNodes.map((node) => node.id));
    setIgnoredNodeIds((prev) => new Set([...prev].filter((id) => valid.has(id))));
    setNodeRoleOverrides((prev) => {
      const next: Record<string, NodeRole | undefined> = {};
      for (const [id, role] of Object.entries(prev)) {
        if (role && valid.has(id)) {
          next[id] = role;
        }
      }
      return next;
    });

    if (allNodes.length === 0) {
      setSelectedTreeId("");
      setOpenTreeItems(new Set());
      return;
    }

    if (!selectedTreeId || (selectedTreeId !== ALL_NODE_ID && !treeNodeMap.has(selectedTreeId))) {
      setSelectedTreeId(ALL_NODE_ID);
    }

    const branches = new Set<string>();
    for (const node of allNodes) {
      if (node.children.length > 0) {
        branches.add(node.id);
      }
    }
    setOpenTreeItems((prev) => {
      if (prev.size === 0) return branches;
      const next = new Set<string>();
      for (const id of prev) {
        if (branches.has(id)) {
          next.add(id);
        }
      }
      return next.size > 0 ? next : branches;
    });
  }, [allNodes, selectedTreeId, treeNodeMap]);

  const pairDerivedMetaMap = useMemo(() => {
    const out = new Map<
      string,
      {
        ignoredByTag: boolean;
        timeLabel: string;
        projectLabel: string;
      }
    >();
    const pairs = workspaceScan?.pairs ?? [];

    for (const pair of pairs) {
      const path = pairNodePathMap.get(pair.id) ?? [];
      let ignoredByTag = false;
      let projectLabel = "";
      if (projectNamingRule === "filename") {
        projectLabel = pair.project || "";
      } else {
        const dirSegments = pair.relativeDir
          .split("/")
          .map((segment) => segment.trim())
          .filter((segment) => segment.length > 0);
        projectLabel = dirSegments[dirSegments.length - 1] ?? pair.project ?? "";
      }

      let timeLabel = "";
      if (timeNamingRule === "folder") {
        const fromTimeLabel = parseTimeLabelFromText(pair.timeLabel || "");
        if (fromTimeLabel.label) {
          timeLabel = fromTimeLabel.label;
        } else {
          const dirSegments = pair.relativeDir
            .split("/")
            .map((segment) => segment.trim())
            .filter((segment) => segment.length > 0);
          const folderName = dirSegments[dirSegments.length - 1] ?? "";
          timeLabel = parseTimeLabelFromText(folderName).label;
        }
      } else {
        const fileName = pair.normalName || pair.fluoName || "";
        const dot = fileName.lastIndexOf(".");
        const baseName = dot > 0 ? fileName.slice(0, dot) : fileName;
        timeLabel = parseTimeLabelFromText(baseName).label;
      }

      for (const nodeId of path) {
        if (ignoredNodeIds.has(nodeId)) {
          ignoredByTag = true;
        }
        if (!namingCustomEnabled) {
          continue;
        }

        const role = nodeRoleOverrides[nodeId] ?? defaultNodeRoles.get(nodeId);
        if (!role) continue;
        const label = treeNodeMap.get(nodeId)?.label ?? "";
        if (!label) continue;
        if (role === "time") {
          timeLabel = label;
        } else {
          projectLabel = label;
        }
      }

      out.set(pair.id, {
        ignoredByTag,
        timeLabel,
        projectLabel
      });
    }
    return out;
  }, [
    workspaceScan,
    pairNodePathMap,
    ignoredNodeIds,
    nodeRoleOverrides,
    defaultNodeRoles,
    treeNodeMap,
    namingCustomEnabled,
    projectNamingRule,
    timeNamingRule
  ]);

  const namingStats = useMemo(() => {
    const pairs = workspaceScan?.pairs ?? [];
    const timeSet = new Set<string>();
    const projectSet = new Set<string>();
    let noTime = 0;
    let noProject = 0;

    for (const pair of pairs) {
      const derived = pairDerivedMetaMap.get(pair.id);
      const time = (derived?.timeLabel ?? "").trim();
      const project = (derived?.projectLabel ?? "").trim();
      if (time) {
        timeSet.add(time);
      } else {
        noTime += 1;
      }
      if (project) {
        projectSet.add(project);
      } else {
        noProject += 1;
      }
    }

    return {
      timeKinds: timeSet.size,
      projectKinds: projectSet.size,
      noTime,
      noProject
    };
  }, [workspaceScan, pairDerivedMetaMap]);

  const presetExamples = useMemo(() => {
    if (preset === "WINDOWS") {
      return ["example project (1).tif", "example project (2).tif", "example project (3).tif"];
    }
    if (preset === "DOLPHIN") {
      return ["exampleProject1.tif", "exampleProject2.tif", "exampleProject3.tif"];
    }
    return ["example project 1.tif", "example project 2.tif", "example project 3.tif"];
  }, [preset]);

  const dataFormatTokens = useMemo(() => {
    return dataDraft.formatColumns
      .split(",")
      .map((token) => token.trim().toUpperCase())
      .filter((token) => token.length > 0);
  }, [dataDraft.formatColumns]);

  const hasPerCellColumns = useMemo(() => {
    return dataFormatTokens.some((token) => token === "TPC" || token === "ETPC" || token === "TPCSEM");
  }, [dataFormatTokens]);

  const canGroupByTime = useMemo(() => {
    const pairs = workspaceScan?.pairs ?? [];
    if (pairs.length === 0) return false;
    const dirSet = new Set<string>();
    for (const pair of pairs) {
      const dir = pair.relativeDir.trim();
      if (dir.length > 0) {
        dirSet.add(dir);
      }
    }
    return dirSet.size > 1;
  }, [workspaceScan]);

  useEffect(() => {
    setDataDraft((prev) => {
      const nextGroupByTime = canGroupByTime ? prev.groupByTime : false;
      const nextExpandPerCell = hasPerCellColumns ? true : prev.expandPerCell;
      if (nextGroupByTime === prev.groupByTime && nextExpandPerCell === prev.expandPerCell) {
        return prev;
      }
      return {
        ...prev,
        groupByTime: nextGroupByTime,
        expandPerCell: nextExpandPerCell
      };
    });
  }, [canGroupByTime, hasPerCellColumns]);

  const roiPreviewModel = useMemo(() => {
    const min = Math.max(1, Number(minArea) || 1);
    const max = Math.max(min, Number(maxArea) || min);
    const circ = clamp(Number(circularity) || 0, 0, 1);
    const ratio = clamp(Math.sqrt(min / max), 0.04, 1);
    const maxRadius = 52;
    const minRadius = clamp(maxRadius * ratio, 7, maxRadius - 5);
    const eccentricity = clamp(1 - ((1 - circ) * 0.22), 0.78, 1);
    const maxRx = maxRadius * (1 + ((1 - circ) * 0.08));
    const maxRy = maxRadius * eccentricity;
    const minRx = minRadius * (1 + ((1 - circ) * 0.08));
    const minRy = minRadius * eccentricity;
    const cx = 108;
    const cy = 70;
    const minDiameterValue = 2 * Math.sqrt(min / Math.PI);
    const maxDiameterValue = 2 * Math.sqrt(max / Math.PI);
    const maxPath = buildOrganicBlobPath(cx, cy, maxRx, maxRy, circ, 0.65);
    const minPath = buildOrganicBlobPath(cx, cy, minRx, minRy, circ, 1.8);
    return {
      circularityValue: circ,
      maxPath,
      minPath,
      cx,
      cy,
      minRx,
      minRy,
      maxRy,
      minDiameterValue,
      maxDiameterValue
    };
  }, [minArea, maxArea, circularity]);

  const targetPreviewModel = useMemo(() => {
    const centerDiff = clamp(Number(centerDiffThreshold) || 0, 0, 40);
    const bgDiff = clamp(Number(bgDiffThreshold) || 0, 0, 40);
    const smallRatio = clamp(Number(smallAreaRatio) || 0, 0, 1);
    const clumpRatio = clamp(Number(clumpMinRatio) || 1, 1, 3);
    const contrast = clamp(Number(targetMinContrast) || 0, 0, 1);
    return {
      centerDiff,
      bgDiff,
      smallRatio,
      clumpRatio,
      contrast
    };
  }, [centerDiffThreshold, bgDiffThreshold, smallAreaRatio, clumpMinRatio, targetMinContrast]);

  const setFeatureChecked = (key: FeatureKey, checked?: boolean): void => {
    setFeatureFlags((prev) => {
      const nextChecked = typeof checked === "boolean" ? checked : !prev[key];
      const next = {
        ...prev,
        [key]: nextChecked
      };
      if (nextChecked && key === "f1") {
        next.f5 = false;
      }
      if (nextChecked && key === "f5") {
        next.f1 = false;
      }
      return normalizeFeatureFlagSet(next, key === "f1" || key === "f5" ? key : undefined);
    });
  };

  useEffect(() => {
    setFeatureFlags((prev) => {
      const normalized = normalizeFeatureFlagSet(prev);
      if (
        normalized.f1 === prev.f1 &&
        normalized.f2 === prev.f2 &&
        normalized.f3 === prev.f3 &&
        normalized.f5 === prev.f5 &&
        normalized.f6 === prev.f6
      ) {
        return prev;
      }
      return normalized;
    });
  }, [featureFlags.f1, featureFlags.f5]);

  const renderFeatureIllustration = (key: FeatureKey): JSX.Element => {
    if (key === "f1") {
      return (
        <svg viewBox="0 0 96 72" className="feature-preview-svg" role="img" aria-label={t("field.feature1")}>
          <defs>
            <radialGradient id="feature-f1-gradient" cx="50%" cy="50%" r="52%">
              <stop offset="0%" stopColor="rgba(255,255,255,0.92)" />
              <stop offset={`${48 + targetPreviewModel.centerDiff}%`} stopColor="rgba(178,205,255,0.34)" />
              <stop offset="100%" stopColor="rgba(30,44,66,0.92)" />
            </radialGradient>
          </defs>
          <circle cx="48" cy="36" r={16 + (targetPreviewModel.smallRatio * 10)} fill="url(#feature-f1-gradient)" />
        </svg>
      );
    }

    if (key === "f2") {
      return (
        <svg viewBox="0 0 96 72" className="feature-preview-svg" role="img" aria-label={t("field.feature2")}>
          <circle
            cx="48"
            cy="36"
            r="20"
            fill={`rgba(176,182,188,${0.35 + targetPreviewModel.contrast})`}
            stroke="rgba(218,224,230,0.66)"
            strokeWidth={2}
          />
        </svg>
      );
    }

    if (key === "f3") {
      return (
        <svg viewBox="0 0 96 72" className="feature-preview-svg" role="img" aria-label={t("field.feature3")}>
          <path
            d={`M${22 - (targetPreviewModel.clumpRatio * 1.6)} 20
                C36 8, 65 8, 78 22
                C90 ${31 + (targetPreviewModel.clumpRatio * 2.4)}, 88 51, 72 60
                C55 69, 30 67, 20 54
                C10 42, 12 28, ${22 - (targetPreviewModel.clumpRatio * 1.6)} 20Z`}
            fill="rgba(16,18,22,0.96)"
            stroke="rgba(72,80,92,0.44)"
            strokeWidth={1.2}
          />
        </svg>
      );
    }

    if (key === "f5") {
      return (
        <svg viewBox="0 0 96 72" className="feature-preview-svg" role="img" aria-label={t("field.feature5")}>
          <defs>
            <radialGradient id="feature-f5-gradient" cx="50%" cy="50%" r="58%">
              <stop offset="0%" stopColor="rgba(22,26,34,0.9)" />
              <stop offset={`${42 + targetPreviewModel.bgDiff}%`} stopColor="rgba(94,116,160,0.38)" />
              <stop offset="100%" stopColor="rgba(230,236,248,0.9)" />
            </radialGradient>
          </defs>
          <circle cx="48" cy="36" r={18 + (targetPreviewModel.smallRatio * 6)} fill="url(#feature-f5-gradient)" />
        </svg>
      );
    }

    return (
      <svg viewBox="0 0 96 72" className="feature-preview-svg" role="img" aria-label={t("field.feature6")}>
        <circle
          cx="48"
          cy="36"
          r={12 + (targetPreviewModel.smallRatio * 8)}
          fill="rgba(168,176,188,0.5)"
          stroke="rgba(222,226,234,0.6)"
          strokeWidth="2"
        />
      </svg>
    );
  };

  const fluoTargetColor = useMemo(() => parseRgbText(fluorescenceDraft.targetRgb), [fluorescenceDraft.targetRgb]);
  const fluoNearColor = useMemo(() => parseRgbText(fluorescenceDraft.nearRgb), [fluorescenceDraft.nearRgb]);
  const fluoExclColor = useMemo(() => parseRgbText(fluorescenceDraft.exclRgb), [fluorescenceDraft.exclRgb]);
  const fluoDistanceMax = Math.sqrt(3 * (255 * 255));
  const fluoTolerancePreviewModel = useMemo(() => {
    const tolerance = Math.max(0, Number(fluorescenceDraft.tolerance) || 0);
    const dist = rgbDistance(fluoTargetColor, fluoNearColor);
    const tolerancePct = clamp(tolerance / fluoDistanceMax, 0, 1) * 100;
    const nearPct = dist === null ? null : clamp(dist / fluoDistanceMax, 0, 1) * 100;
    return {
      tolerance,
      tolerancePct,
      nearDistance: dist,
      nearPct,
      nearWithinTolerance: dist !== null && dist <= tolerance
    };
  }, [fluorescenceDraft.tolerance, fluoTargetColor, fluoNearColor, fluoDistanceMax]);
  const fluoExclPreviewModel = useMemo(() => {
    const tolerance = Math.max(0, Number(fluorescenceDraft.exclTolerance) || 0);
    const dist = rgbDistance(fluoExclColor, fluoTargetColor);
    const tolerancePct = clamp(tolerance / fluoDistanceMax, 0, 1) * 100;
    const targetPct = dist === null ? null : clamp(dist / fluoDistanceMax, 0, 1) * 100;
    return {
      tolerance,
      tolerancePct,
      targetDistance: dist,
      targetPct,
      targetWithinTolerance: dist !== null && dist <= tolerance
    };
  }, [fluorescenceDraft.exclTolerance, fluoExclColor, fluoTargetColor, fluoDistanceMax]);
  const dataPreviewHeaders = useMemo(
    () => ["P", "T", "F", "TB", "TPC", "ETPC", "TPCSEM", "#TPC"],
    []
  );
  const dataPreviewRows = useMemo(
    () => [
      ["pGb", "0hr", "1", "14", "8", "57.1", "2.3", "6"],
      ["pGb", "24hr", "2", "19", "11", "57.9", "2.7", "9"],
      ["pGb", "48hr", "3", "17", "10", "58.8", "2.5", "8"]
    ],
    []
  );

  const visiblePairs = useMemo(() => {
    const all = workspaceScan?.pairs ?? [];
    if (!selectedTreeId || selectedTreeId === ALL_NODE_ID) return all;
    const node = treeNodeMap.get(selectedTreeId);
    if (!node) return all;
    const set = new Set(node.pairIds);
    return all.filter((pair) => set.has(pair.id));
  }, [workspaceScan, selectedTreeId, treeNodeMap]);

  useEffect(() => {
    if (visiblePairs.length === 0) {
      setSelectedPairId("");
      return;
    }

    if (visiblePairs.some((pair) => pair.id === selectedPairId)) {
      return;
    }

    const first = visiblePairs[0];
    setSelectedPairId(first.id);
    setSelectedSide(first.normalPath ? "normal" : "fluo");
  }, [visiblePairs, selectedPairId]);

  const selectedPair = useMemo(() => {
    if (!selectedPairId) return null;
    return visiblePairs.find((pair) => pair.id === selectedPairId) ?? null;
  }, [visiblePairs, selectedPairId]);

  useEffect(() => {
    if (!selectedPair) return;
    if (selectedSide === "normal" && !selectedPair.normalPath && selectedPair.fluoPath) {
      setSelectedSide("fluo");
      return;
    }
    if (selectedSide === "fluo" && !selectedPair.fluoPath && selectedPair.normalPath) {
      setSelectedSide("normal");
    }
  }, [selectedPair, selectedSide]);

  const selectedPreviewPath = useMemo(() => {
    if (!selectedPair) return "";
    if (selectedSide === "normal") return selectedPair.normalPath || "";
    return selectedPair.fluoPath || "";
  }, [selectedPair, selectedSide]);

  const hasAnyPreviewSource = useMemo(() => {
    return visiblePairs.some((pair) => pair.normalPath.length > 0 || pair.fluoPath.length > 0);
  }, [visiblePairs]);

  useEffect(() => {
    if (previewLoadDebounceRef.current !== null) {
      window.clearTimeout(previewLoadDebounceRef.current);
      previewLoadDebounceRef.current = null;
    }
    if (!selectedPreviewPath) {
      setPreviewLoadPath("");
      setPreviewLoading(false);
      return;
    }
    if (selectedPreviewPath === previewLoadPath) {
      setPreviewLoading(false);
      return;
    }
    setPreviewLoading(true);
    previewLoadDebounceRef.current = window.setTimeout(() => {
      setPreviewLoadPath(selectedPreviewPath);
      previewLoadDebounceRef.current = null;
    }, PREVIEW_SELECTION_SETTLE_MS);
  }, [selectedPreviewPath, previewLoadPath]);

  useEffect(() => {
    const token = previewReadTokenRef.current + 1;
    previewReadTokenRef.current = token;

    const resetPreviewView = (): void => {
      setPreviewNatural({ width: 0, height: 0 });
      setPreviewZoom(1);
      setPreviewPanX(0);
      setPreviewPanY(0);
    };

    if (!previewLoadPath) {
      const fallbackPreview = hasAnyPreviewSource ? "" : (defaultPreviewPlaceholder || "");
      resetPreviewView();
      setPreviewError("");
      setPreviewSrc(fallbackPreview);
      setPreviewLoading(false);
      return;
    }

    const cached = previewCacheRef.current.get(previewLoadPath);
    if (cached) {
      resetPreviewView();
      setPreviewError("");
      setPreviewSrc(cached);
      setPreviewLoading(false);
      return;
    }

    setPreviewError("");
    setPreviewLoading(true);

    window.electronAPI
      .readImageDataUrl({ filePath: previewLoadPath })
      .then((out) => {
        if (token !== previewReadTokenRef.current) return;
        if (!out.ok) {
          setPreviewLoading(false);
          setPreviewError(out.error || t("status.previewLoadFailed"));
          return;
        }
        previewCacheRef.current.set(previewLoadPath, out.dataUrl);
        resetPreviewView();
        setPreviewError("");
        setPreviewLoading(false);
        setPreviewSrc(out.dataUrl);
      })
      .catch((error: unknown) => {
        if (token !== previewReadTokenRef.current) return;
        setPreviewLoading(false);
        setPreviewError(error instanceof Error ? error.message : "preview_load_failed");
      });
  }, [previewLoadPath, defaultPreviewPlaceholder, hasAnyPreviewSource, t]);

  useEffect(() => {
    if (!previewLoadPath || visiblePairs.length <= 1) return;
    const index = visiblePairs.findIndex((pair) => pair.normalPath === previewLoadPath || pair.fluoPath === previewLoadPath);
    if (index < 0) return;

    const resolvePath = (pair: WorkspacePair): string => {
      if (selectedSide === "normal") {
        return pair.normalPath || pair.fluoPath || "";
      }
      return pair.fluoPath || pair.normalPath || "";
    };

    const candidates = [
      resolvePath(visiblePairs[(index + 1) % visiblePairs.length]),
      resolvePath(visiblePairs[(index - 1 + visiblePairs.length) % visiblePairs.length])
    ].filter((item) => item.length > 0);

    for (const path of candidates) {
      if (previewCacheRef.current.has(path)) continue;
      if (previewPrefetchingRef.current.has(path)) continue;
      previewPrefetchingRef.current.add(path);
      void window.electronAPI
        .readImageDataUrl({ filePath: path })
        .then((out) => {
          if (out.ok && out.dataUrl) {
            previewCacheRef.current.set(path, out.dataUrl);
          }
        })
        .finally(() => {
          previewPrefetchingRef.current.delete(path);
        });
    }
  }, [previewLoadPath, selectedSide, visiblePairs]);

  useEffect(() => {
    const clamped = clampPan(previewPanX, previewPanY, previewZoom, previewNatural, previewViewport);
    if (Math.abs(clamped.x - previewPanX) >= 1) setPreviewPanX(clamped.x);
    if (Math.abs(clamped.y - previewPanY) >= 1) setPreviewPanY(clamped.y);
  }, [previewZoom, previewNatural, previewViewport]);

  const canCollapseInner = (target: "tag" | "list" | "preview"): boolean => {
    if (target === "tag") {
      return canCollapse(tagCollapsed, [tagCollapsed, listCollapsed, previewCollapsed]);
    }
    if (target === "list") {
      return canCollapse(listCollapsed, [tagCollapsed, listCollapsed, previewCollapsed]);
    }
    return canCollapse(previewCollapsed, [tagCollapsed, listCollapsed, previewCollapsed]);
  };

  const restorePreviewPane = (): void => {
    const total = Math.max(splitHostHeight, 200);
    const maxPreview = Math.max(PREVIEW_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - FILE_BROWSER_MIN_HEIGHT);
    const targetPreview = clamp(previewRememberHeightRef.current, PREVIEW_MIN_HEIGHT, maxPreview);
    setPreviewCollapsed(false);
    setBrowserHeight(total - FILE_SPLIT_RESIZER_HEIGHT - targetPreview);
  };

  const collapsePreviewPane = (): void => {
    if (!canCollapseInner("preview")) {
      return;
    }
    const total = Math.max(splitHostHeight, 200);
    const preview = total - FILE_SPLIT_RESIZER_HEIGHT - browserHeight;
    previewRememberHeightRef.current = Math.max(PREVIEW_MIN_HEIGHT, preview);
    setPreviewCollapsed(true);
  };

  useEffect(() => {
    const total = Math.max(splitHostHeight, 200);

    if (previewCollapsed) {
      const maxBrowser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_BAR_HEIGHT);
      if (browserHeight > maxBrowser) {
        setBrowserHeight(maxBrowser);
      }
      return;
    }

    const maxBrowser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_MIN_HEIGHT);
    if (browserHeight > maxBrowser) {
      setBrowserHeight(maxBrowser);
      return;
    }

    const preview = total - FILE_SPLIT_RESIZER_HEIGHT - browserHeight;
    if (preview <= PREVIEW_COLLAPSE_TRIGGER && canCollapseInner("preview")) {
      previewRememberHeightRef.current = Math.max(PREVIEW_MIN_HEIGHT, preview);
      setPreviewCollapsed(true);
    }
  }, [splitHostHeight, previewCollapsed, browserHeight, tagCollapsed, listCollapsed]);
  useEffect(() => {
    if (!fileSplitDragging) return;

    const onMove = (event: MouseEvent): void => {
      if (fileSplitDragSnapLockRef.current) return;
      const total = Math.max(splitHostHeight, 200);
      const desiredBrowser = fileSplitStartRef.current.browser + (event.clientY - fileSplitStartRef.current.y);
      const desiredPreview = total - FILE_SPLIT_RESIZER_HEIGHT - desiredBrowser;

      if (previewCollapsed) {
        if (desiredPreview >= PREVIEW_RESTORE_TRIGGER) {
          triggerFileSplitSnapAnimation();
          lockFileSplitDragDuringSnap();
          setPreviewCollapsed(false);
          const maxBrowser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_MIN_HEIGHT);
          setBrowserHeight(clamp(desiredBrowser, FILE_BROWSER_MIN_HEIGHT, maxBrowser));
        }
        return;
      }

      if (desiredPreview <= PREVIEW_COLLAPSE_TRIGGER && canCollapseInner("preview")) {
        triggerFileSplitSnapAnimation();
        lockFileSplitDragDuringSnap();
        previewRememberHeightRef.current = Math.max(PREVIEW_MIN_HEIGHT, desiredPreview);
        setPreviewCollapsed(true);
        return;
      }

      const maxBrowser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_MIN_HEIGHT);
      setBrowserHeight(clamp(desiredBrowser, FILE_BROWSER_MIN_HEIGHT, maxBrowser));
    };

    const onUp = (): void => {
      setFileSplitDragging(false);
      fileSplitDragSnapLockRef.current = false;
      if (fileSplitDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(fileSplitDragSnapLockTimerRef.current);
        fileSplitDragSnapLockTimerRef.current = null;
      }
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [fileSplitDragging, splitHostHeight, previewCollapsed, tagCollapsed, listCollapsed]);

  const tagListLayout = useMemo(() => {
    const total = Math.max(browserAreaHeight, 120);
    const available = total - TAG_LIST_RESIZER_HEIGHT;

    if (tagCollapsed && !listCollapsed) {
      return {
        tag: TAG_BAR_HEIGHT,
        list: Math.max(0, available - TAG_BAR_HEIGHT),
        template: `${TAG_BAR_HEIGHT}px ${TAG_LIST_RESIZER_HEIGHT}px minmax(0, 1fr)`
      };
    }

    if (listCollapsed && !tagCollapsed) {
      return {
        tag: Math.max(0, available - LIST_BAR_HEIGHT),
        list: LIST_BAR_HEIGHT,
        template: `minmax(0, 1fr) ${TAG_LIST_RESIZER_HEIGHT}px ${LIST_BAR_HEIGHT}px`
      };
    }

    const maxTag = Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT);
    const tag = clamp(tagHeight, TAG_MIN_HEIGHT, maxTag);
    const list = Math.max(0, available - tag);
    return {
      tag,
      list,
      template: `${tag}px ${TAG_LIST_RESIZER_HEIGHT}px minmax(0, 1fr)`
    };
  }, [browserAreaHeight, tagCollapsed, listCollapsed, tagHeight]);

  useEffect(() => {
    if (tagCollapsed && listCollapsed) {
      setListCollapsed(false);
    }
  }, [tagCollapsed, listCollapsed]);

  useEffect(() => {
    if (tagCollapsed && listCollapsed && previewCollapsed) {
      setListCollapsed(false);
    }
  }, [tagCollapsed, listCollapsed, previewCollapsed]);

  useEffect(() => {
    if (!tagListDragging) return;

    const onMove = (event: MouseEvent): void => {
      if (tagListDragSnapLockRef.current) return;
      const total = Math.max(browserAreaHeight, 120);
      const available = total - TAG_LIST_RESIZER_HEIGHT;
      const desiredTag = tagListStartRef.current.tag + (event.clientY - tagListStartRef.current.y);
      const desiredList = available - desiredTag;

      if (tagCollapsed) {
        if (desiredTag >= TAG_RESTORE_TRIGGER) {
          triggerTagListSnapAnimation();
          lockTagListDragDuringSnap();
          const restoredTag = clamp(desiredTag, TAG_MIN_HEIGHT, Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT));
          setTagCollapsed(false);
          setTagHeight(restoredTag);
          tagListStartRef.current = {
            y: event.clientY,
            tag: restoredTag
          };
        }
        return;
      }

      if (listCollapsed) {
        if (desiredList >= LIST_RESTORE_TRIGGER) {
          triggerTagListSnapAnimation();
          lockTagListDragDuringSnap();
          const restoredTag = clamp(desiredTag, TAG_MIN_HEIGHT, Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT));
          setListCollapsed(false);
          setTagHeight(restoredTag);
          tagListStartRef.current = {
            y: event.clientY,
            tag: restoredTag
          };
        }
        return;
      }

      if (desiredTag <= TAG_COLLAPSE_TRIGGER && canCollapseInner("tag")) {
        triggerTagListSnapAnimation();
        lockTagListDragDuringSnap();
        tagRememberHeightRef.current = Math.max(TAG_MIN_HEIGHT, tagListLayout.tag);
        setTagCollapsed(true);
        tagListStartRef.current = {
          y: event.clientY,
          tag: TAG_BAR_HEIGHT
        };
        return;
      }

      if (desiredList <= LIST_COLLAPSE_TRIGGER && canCollapseInner("list")) {
        triggerTagListSnapAnimation();
        lockTagListDragDuringSnap();
        listRememberHeightRef.current = Math.max(LIST_MIN_HEIGHT, desiredList);
        setListCollapsed(true);
        const collapsedTag = Math.max(TAG_MIN_HEIGHT, available - LIST_BAR_HEIGHT);
        setTagHeight(collapsedTag);
        tagListStartRef.current = {
          y: event.clientY,
          tag: collapsedTag
        };
        return;
      }

      setTagHeight(clamp(desiredTag, TAG_MIN_HEIGHT, Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT)));
    };

    const onUp = (): void => {
      setTagListDragging(false);
      tagListDragSnapLockRef.current = false;
      if (tagListDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(tagListDragSnapLockTimerRef.current);
        tagListDragSnapLockTimerRef.current = null;
      }
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [tagListDragging, browserAreaHeight, tagCollapsed, listCollapsed, previewCollapsed, tagListLayout.tag]);

  useEffect(() => {
    if (!tableColDragging) return;

    const onMove = (event: MouseEvent): void => {
      const delta = event.clientX - tableColStartRef.current.x;

      if (tableColDragging === "roi") {
        setTableRoiWidth(Math.max(COLUMN_MIN_ROI, tableColStartRef.current.roi + delta));
        return;
      }
      if (tableColDragging === "normal") {
        setTableNormalWidth(Math.max(COLUMN_MIN_NORMAL, tableColStartRef.current.normal + delta));
        return;
      }
      if (tableColDragging === "fluo") {
        setTableFluoWidth(Math.max(COLUMN_MIN_FLUO, tableColStartRef.current.fluo + delta));
        return;
      }
      if (tableColDragging === "time") {
        setTableTimeWidth(Math.max(COLUMN_MIN_TIME, tableColStartRef.current.time + delta));
        return;
      }
      setTableProjectWidth(Math.max(COLUMN_MIN_PROJECT, tableColStartRef.current.project + delta));
    };

    const onUp = (): void => {
      setTableColDragging(null);
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [tableColDragging]);

  useEffect(() => {
    if (dataPreviewColDragging === null) return;

    const onMove = (event: MouseEvent): void => {
      const delta = event.clientX - dataPreviewColStartRef.current.x;
      setDataPreviewColWidths((prev) => {
        const next = [...prev];
        const base = dataPreviewColStartRef.current.widths[dataPreviewColDragging] ?? prev[dataPreviewColDragging] ?? 120;
        next[dataPreviewColDragging] = Math.max(76, base + delta);
        return next;
      });
    };

    const onUp = (): void => {
      setDataPreviewColDragging(null);
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [dataPreviewColDragging]);

  useEffect(() => {
    if (!previewDragging) return;

    const onMove = (event: MouseEvent): void => {
      const next = clampPan(
        previewDragStartRef.current.panX + (event.clientX - previewDragStartRef.current.x),
        previewDragStartRef.current.panY + (event.clientY - previewDragStartRef.current.y),
        previewZoom,
        previewNatural,
        previewViewport
      );
      setPreviewPanX(next.x);
      setPreviewPanY(next.y);
    };

    const onUp = (): void => {
      setPreviewDragging(false);
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);

    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [previewDragging, previewZoom, previewNatural, previewViewport]);

  const splitLayout = useMemo(() => {
    const total = Math.max(splitHostHeight, 200);
    if (previewCollapsed) {
      const browser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_BAR_HEIGHT);
      return {
        browser,
        template: `${browser}px ${FILE_SPLIT_RESIZER_HEIGHT}px ${PREVIEW_BAR_HEIGHT}px`
      };
    }

    const maxBrowser = Math.max(FILE_BROWSER_MIN_HEIGHT, total - FILE_SPLIT_RESIZER_HEIGHT - PREVIEW_MIN_HEIGHT);
    const browser = clamp(browserHeight, FILE_BROWSER_MIN_HEIGHT, maxBrowser);
    const preview = total - FILE_SPLIT_RESIZER_HEIGHT - browser;
    return {
      browser,
      preview,
      template: `${browser}px ${FILE_SPLIT_RESIZER_HEIGHT}px ${preview}px`
    };
  }, [splitHostHeight, previewCollapsed, browserHeight]);

  const hasFluoColumn = useMemo(() => {
    return visiblePairs.some((pair) => pair.fluoPath.length > 0);
  }, [visiblePairs]);

  const tableTemplate = useMemo(() => {
    const roi = Math.max(COLUMN_MIN_ROI, tableRoiWidth);
    const normal = Math.max(COLUMN_MIN_NORMAL, tableNormalWidth);
    const fluo = Math.max(COLUMN_MIN_FLUO, tableFluoWidth);
    const time = Math.max(COLUMN_MIN_TIME, tableTimeWidth);
    const project = Math.max(COLUMN_MIN_PROJECT, tableProjectWidth);
    const parts: string[] = [`${roi}px`, "4px", `${normal}px`, "4px"];
    if (hasFluoColumn) {
      parts.push(`${fluo}px`, "4px");
    }
    parts.push(`${time}px`, "4px", `${project}px`, "4px");
    return {
      roi,
      normal,
      fluo,
      time,
      project,
      hasFluo: hasFluoColumn,
      template: parts.join(" ")
    };
  }, [tableRoiWidth, tableNormalWidth, tableFluoWidth, tableTimeWidth, tableProjectWidth, hasFluoColumn]);

  const pairHasSidePath = (pair: WorkspacePair, side: PreviewSide): boolean => {
    if (side === "normal") return pair.normalPath.length > 0;
    return pair.fluoPath.length > 0;
  };

  const moveSelectionInColumn = (direction: -1 | 1): void => {
    if (!selectedPairId) return;
    const start = visiblePairs.findIndex((pair) => pair.id === selectedPairId);
    if (start < 0) return;
    for (let i = start + direction; i >= 0 && i < visiblePairs.length; i += direction) {
      const candidate = visiblePairs[i];
      if (!pairHasSidePath(candidate, selectedSide)) continue;
      setSelectedPairId(candidate.id);
      return;
    }
  };

  const canMoveSelectionInColumn = (direction: -1 | 1): boolean => {
    if (!selectedPairId) return false;
    const start = visiblePairs.findIndex((pair) => pair.id === selectedPairId);
    if (start < 0) return false;
    for (let i = start + direction; i >= 0 && i < visiblePairs.length; i += direction) {
      if (pairHasSidePath(visiblePairs[i], selectedSide)) {
        return true;
      }
    }
    return false;
  };

  const handlePreviewPrev = (): void => {
    moveSelectionInColumn(-1);
  };

  const handlePreviewNext = (): void => {
    moveSelectionInColumn(1);
  };

  const handlePreviewOpenExternal = async (): Promise<void> => {
    if (!selectedPreviewPath) return;
    const out = await window.electronAPI.openExternalFile({ filePath: selectedPreviewPath });
    if (!out.ok) {
      setStatus("status.previewOpenFailed");
      appendLog(t("log.previewOpenFailed", { error: out.error || "open_failed" }));
      return;
    }
    setStatus("status.previewOpened");
    appendLog(t("log.previewOpened", { file: selectedPreviewPath }));
  };

  const openPathBySystem = async (filePath: string): Promise<void> => {
    const path = filePath.trim();
    if (!path) return;
    const out = await window.electronAPI.openExternalFile({ filePath: path });
    if (!out.ok) {
      setStatus("status.previewOpenFailed");
      appendLog(t("log.previewOpenFailed", { error: out.error || "open_failed" }));
      return;
    }
    setStatus("status.previewOpened");
    appendLog(t("log.previewOpened", { file: path }));
  };

  const resolvePairUi = (pair: WorkspacePair): PairUiState => {
    const defaultMode: RoiUsageMode = pair.normalHasRoi ? "native" : "none";
    const current = pairUiStateMap[pair.id];
    if (!current) {
      return {
        ignored: false,
        roiMode: defaultMode
      };
    }
    return {
      ignored: current.ignored,
      roiMode: current.roiMode === "native" && !pair.normalHasRoi ? "none" : current.roiMode
    };
  };

  const mutatePairsRoiState = (
    pairs: WorkspacePair[],
    mutator: (pair: WorkspacePair, current: PairUiState) => PairUiState | null
  ): void => {
    setPairUiStateMap((prev) => {
      const next = { ...prev };
      for (const pair of pairs) {
        const current = next[pair.id] ?? {
          ignored: false,
          roiMode: "none" as RoiUsageMode
        };
        const updated = mutator(pair, current);
        if (!updated) continue;
        next[pair.id] = updated;
      }
      return next;
    });
  };

  const setNoRoiAsAutoForPairs = (pairs: WorkspacePair[]): void => {
    mutatePairsRoiState(pairs, (pair, current) => {
      if (pair.normalHasRoi) return null;
      return {
        ...current,
        roiMode: "auto"
      };
    });
  };

  const setAutoAsNoRoiForPairs = (pairs: WorkspacePair[]): void => {
    mutatePairsRoiState(pairs, (_pair, current) => {
      if (current.roiMode !== "auto") return null;
      return {
        ...current,
        roiMode: "none"
      };
    });
  };

  const preferNativeRoiForPairs = (pairs: WorkspacePair[]): void => {
    mutatePairsRoiState(pairs, (pair, current) => {
      if (!pair.normalHasRoi) return null;
      return {
        ...current,
        roiMode: "native"
      };
    });
  };

  const setVisibleNoRoiAsAuto = (): void => {
    setNoRoiAsAutoForPairs(visiblePairs);
  };

  const setVisibleAutoAsNoRoi = (): void => {
    setAutoAsNoRoiForPairs(visiblePairs);
  };

  const setVisiblePreferNativeRoi = (): void => {
    preferNativeRoiForPairs(visiblePairs);
  };

  const setGlobalNoRoiAsAuto = (): void => {
    setNoRoiAsAutoForPairs(workspaceScan?.pairs ?? []);
  };

  const setGlobalPreferNativeRoi = (): void => {
    preferNativeRoiForPairs(workspaceScan?.pairs ?? []);
  };

  const setNodeRole = (nodeId: string, role: NodeRole): void => {
    setNamingCustomEnabled(true);
    setNodeRoleOverrides((prev) => {
      return {
        ...prev,
        [nodeId]: role
      };
    });
  };

  const toggleNodeIgnore = (nodeId: string): void => {
    setIgnoredNodeIds((prev) => {
      const next = new Set(prev);
      if (next.has(nodeId)) {
        next.delete(nodeId);
      } else {
        next.add(nodeId);
      }
      return next;
    });
  };

  const handlePreviewWheel = (event: ReactWheelEvent<HTMLDivElement>): void => {
    if (!previewSrc) return;
    event.preventDefault();

    const rect = previewViewportRef.current?.getBoundingClientRect();
    if (!rect) return;
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const pointerX = event.clientX - centerX;
    const pointerY = event.clientY - centerY;
    const factor = Math.exp(-event.deltaY * 0.0031);

    setPreviewZoom((prevZoom) => {
      const nextZoom = clamp(Number((prevZoom * factor).toFixed(4)), ZOOM_MIN, ZOOM_MAX);
      if (Math.abs(nextZoom - prevZoom) < 0.0001) {
        return prevZoom;
      }

      const contentX = (pointerX - previewPanX) / prevZoom;
      const contentY = (pointerY - previewPanY) / prevZoom;
      const rawPanX = pointerX - (contentX * nextZoom);
      const rawPanY = pointerY - (contentY * nextZoom);
      const clamped = clampPan(rawPanX, rawPanY, nextZoom, previewNatural, previewViewport);
      setPreviewPanX(clamped.x);
      setPreviewPanY(clamped.y);
      return nextZoom;
    });
  };

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent): void => {
      const target = event.target as HTMLElement | null;
      const tag = target?.tagName.toLowerCase();
      if (target?.isContentEditable || tag === "input" || tag === "textarea" || tag === "select") {
        return;
      }

      if (event.key === "ArrowUp") {
        event.preventDefault();
        moveSelectionInColumn(-1);
        return;
      }
      if (event.key === "ArrowDown") {
        event.preventDefault();
        moveSelectionInColumn(1);
        return;
      }
      if (event.key === "ArrowLeft") {
        if (!selectedPair) return;
        if (selectedSide === "fluo" && selectedPair.normalPath) {
          event.preventDefault();
          setSelectedSide("normal");
        }
        return;
      }
      if (event.key === "ArrowRight") {
        if (!selectedPair || !hasFluoColumn) return;
        if (selectedSide === "normal" && selectedPair.fluoPath) {
          event.preventDefault();
          setSelectedSide("fluo");
        }
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [selectedPair, selectedPairId, selectedSide, hasFluoColumn, visiblePairs]);

  useEffect(() => {
    return () => {
      if (paneSnapTimerRef.current !== null) {
        window.clearTimeout(paneSnapTimerRef.current);
      }
      if (fileSplitSnapTimerRef.current !== null) {
        window.clearTimeout(fileSplitSnapTimerRef.current);
      }
      if (tagListSnapTimerRef.current !== null) {
        window.clearTimeout(tagListSnapTimerRef.current);
      }
      if (paneDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(paneDragSnapLockTimerRef.current);
      }
      if (fileSplitDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(fileSplitDragSnapLockTimerRef.current);
      }
      if (tagListDragSnapLockTimerRef.current !== null) {
        window.clearTimeout(tagListDragSnapLockTimerRef.current);
      }
      if (previewLoadDebounceRef.current !== null) {
        window.clearTimeout(previewLoadDebounceRef.current);
      }
      if (splitHostHeightCommitTimerRef.current !== null) {
        window.clearTimeout(splitHostHeightCommitTimerRef.current);
      }
      if (browserAreaHeightCommitTimerRef.current !== null) {
        window.clearTimeout(browserAreaHeightCommitTimerRef.current);
      }
    };
  }, []);

  const renderTree = (node: TreeNode, ancestorIgnored: boolean, depth: number): JSX.Element => {
    const isSelected = selectedTreeId === node.id;
    const isBranch = node.children.length > 0;
    const isOpen = openTreeItems.has(node.id);
    const selfIgnored = ignoredNodeIds.has(node.id);
    const isIgnored = ancestorIgnored || selfIgnored;
    const role = nodeRoleOverrides[node.id] ?? defaultNodeRoles.get(node.id);
    const className =
      `${isSelected ? "file-tree-item is-selected" : "file-tree-item"}` +
      `${isIgnored ? " is-ignored" : ""}` +
      `${isBranch ? " is-branch" : " is-leaf"}`;
    const indentPx = 4 + (Math.max(0, depth) * 14) + (isBranch ? 0 : TREE_EXPAND_SLOT_WIDTH);

    const nodeIcon =
      role === "time"
        ? <Clock24Regular className="tree-role-icon" />
        : role === "project"
          ? <Tag24Regular className="tree-role-icon" />
          : isBranch && isOpen
            ? <FolderOpen24Regular className="tree-folder-icon" />
            : <Folder24Regular className="tree-folder-icon" />;

    return (
      <TreeItem key={node.id} itemType={isBranch ? "branch" : "leaf"} value={node.id}>
        <Menu openOnContext>
          <MenuTrigger disableButtonEnhancement>
            <TreeItemLayout
              className={className}
              style={{ paddingInlineStart: `${indentPx}px` }}
              iconBefore={<span className="tree-folder-icon-wrap">{nodeIcon}</span>}
              onClick={() => setSelectedTreeId(node.id)}
            >
              {node.label}
            </TreeItemLayout>
          </MenuTrigger>
          <MenuPopover>
            <MenuList>
              <MenuItem icon={renderMenuGlyph()} onClick={() => toggleNodeIgnore(node.id)}>
                {selfIgnored ? t("menu.tag.unignore") : t("menu.tag.ignore")}
              </MenuItem>
              <MenuItem icon={<Clock24Regular />} onClick={() => setNodeRole(node.id, "time")}>
                {t("menu.tag.setTime")}
              </MenuItem>
              <MenuItem icon={<Tag24Regular />} onClick={() => setNodeRole(node.id, "project")}>
                {t("menu.tag.setProject")}
              </MenuItem>
            </MenuList>
          </MenuPopover>
        </Menu>
        {isBranch ? <Tree>{node.children.map((child) => renderTree(child, isIgnored, depth + 1))}</Tree> : null}
      </TreeItem>
    );
  };

  const handleWindowMinimize = (): void => {
    void window.electronAPI.minimizeWindow();
  };

  const handleWindowToggleMaximize = (): void => {
    void window.electronAPI.toggleMaximizeWindow().then((out) => {
      if (out.ok) {
        setIsWindowMaximized(out.maximized);
      }
    }).catch(() => {
      // ignore
    });
  };

  const handleWindowClose = (): void => {
    void window.electronAPI.closeWindow();
  };

  const handleTopMenuOpenChange = (menu: TopMenuKey, open: boolean): void => {
    setOpenTopMenu((prev) => {
      if (open) return menu;
      if (prev === menu) return null;
      return prev;
    });
  };

  const handleTopMenuTriggerEnter = (menu: TopMenuKey): void => {
    setOpenTopMenu((prev) => {
      if (prev && prev !== menu) return menu;
      return prev;
    });
  };

  const exclusionDirty =
    exclusionDraft.enabled !== exclusionConfig.enabled ||
    exclusionDraft.mode !== exclusionConfig.mode ||
    exclusionDraft.threshold !== exclusionConfig.threshold ||
    exclusionDraft.strict !== exclusionConfig.strict ||
    exclusionDraft.sizeGate !== exclusionConfig.sizeGate ||
    exclusionDraft.minArea !== exclusionConfig.minArea ||
    exclusionDraft.maxArea !== exclusionConfig.maxArea;
  const fluorescenceDirty =
    fluorescenceDraft.enabled !== fluorescenceConfig.enabled ||
    fluorescenceDraft.prefix.trim() !== fluorescenceConfig.prefix.trim() ||
    fluorescenceDraft.targetRgb !== fluorescenceConfig.targetRgb ||
    fluorescenceDraft.nearRgb !== fluorescenceConfig.nearRgb ||
    fluorescenceDraft.tolerance !== fluorescenceConfig.tolerance ||
    fluorescenceDraft.exclEnabled !== fluorescenceConfig.exclEnabled ||
    fluorescenceDraft.exclRgb !== fluorescenceConfig.exclRgb ||
    fluorescenceDraft.exclTolerance !== fluorescenceConfig.exclTolerance;
  const filesDirty =
    filesAppliedSignatureRef.current !== null &&
    filesAppliedSignatureRef.current !== filesApplySignature;
  const cellRoiDirty =
    cellRoiAppliedSignatureRef.current !== null &&
    cellRoiAppliedSignatureRef.current !== cellRoiApplySignature;
  const debugDirty =
    debugDraft.bootManualEnterAfterReady !== debugConfig.bootManualEnterAfterReady ||
    debugDraft.runSimulateSlowProgress !== debugConfig.runSimulateSlowProgress ||
    String(debugDraft.runProgressStep).trim() !== String(debugConfig.runProgressStep).trim() ||
    String(debugDraft.runProgressIntervalMs).trim() !== String(debugConfig.runProgressIntervalMs).trim() ||
    debugDraft.runVerboseLogs !== debugConfig.runVerboseLogs;
  const dataDirty =
    dataDraft.formatColumns !== dataConfig.formatColumns ||
    dataDraft.autoNoiseOptimize !== dataConfig.autoNoiseOptimize ||
    dataDraft.groupByTime !== dataConfig.groupByTime ||
    dataDraft.expandPerCell !== dataConfig.expandPerCell;
  const configButtonWidth = useMemo(() => {
    const a = t("button.loadConfig");
    const b = t("button.saveConfig");
    const maxLen = Math.max(a.length, b.length);
    return `${maxLen + 4}ch`;
  }, [t]);

  const bottomMessage = hoverHelp || t(statusState.key);
  const structuralResizing = dragMode !== null || fileSplitDragging || tagListDragging || windowResizeActive;
  const subfolderModeLabel = subfolderMode === "flat" ? t("field.subfolderFlat") : t("field.subfolderKeep");
  const presetLabel = presetLabelByValue[preset] || "";

  return (
    <div
      className={`app-shell${bootReady ? "" : " is-booting"}`}
      onMouseOver={helpProbe}
      onFocusCapture={helpProbe}
      onMouseLeave={() => setHoverHelp("")}
      onContextMenuCapture={openTextMenu}
    >
      {bootReady ? (
      <header className="app-menubar" data-help={t("help.menuBar")}>
        <div className="menu-app-mark" aria-hidden>
          {windowIconDataUrl ? (
            <img src={windowIconDataUrl} alt="" className="menu-app-icon" draggable={false} />
          ) : (
            <Code24Regular />
          )}
        </div>
        <div className="menu-cluster">
          <Menu
            open={openTopMenu === "file"}
            onOpenChange={(_, data) => handleTopMenuOpenChange("file", data.open)}
          >
            <MenuTrigger disableButtonEnhancement>
              <Button
                className={`menu-bar-btn ${openTopMenu === "file" ? "is-open" : ""}`}
                size="small"
                appearance="transparent"
                onMouseEnter={() => handleTopMenuTriggerEnter("file")}
              >
                {t("main.menu.file")}
              </Button>
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem
                  onClick={() => {
                    void handleSelectFolder();
                  }}
                >
                  {t("button.selectFolder")}
                </MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
          <Menu
            open={openTopMenu === "edit"}
            onOpenChange={(_, data) => handleTopMenuOpenChange("edit", data.open)}
          >
            <MenuTrigger disableButtonEnhancement>
              <Button
                className={`menu-bar-btn ${openTopMenu === "edit" ? "is-open" : ""}`}
                size="small"
                appearance="transparent"
                onMouseEnter={() => handleTopMenuTriggerEnter("edit")}
              >
                {t("main.menu.edit")}
              </Button>
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem disabled>{t("menu.text.undo")}</MenuItem>
                <MenuItem disabled>{t("menu.text.redo")}</MenuItem>
                <MenuDivider />
                <MenuItem disabled>{t("menu.text.cut")}</MenuItem>
                <MenuItem disabled>{t("menu.text.copy")}</MenuItem>
                <MenuItem disabled>{t("menu.text.paste")}</MenuItem>
                <MenuItem disabled>{t("menu.text.selectAll")}</MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
          <Menu
            open={openTopMenu === "view"}
            onOpenChange={(_, data) => handleTopMenuOpenChange("view", data.open)}
          >
            <MenuTrigger disableButtonEnhancement>
              <Button
                className={`menu-bar-btn ${openTopMenu === "view" ? "is-open" : ""}`}
                size="small"
                appearance="transparent"
                onMouseEnter={() => handleTopMenuTriggerEnter("view")}
              >
                {t("main.menu.view")}
              </Button>
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem disabled>{t("main.menu.view")}</MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
          <Menu
            open={openTopMenu === "window"}
            onOpenChange={(_, data) => handleTopMenuOpenChange("window", data.open)}
          >
            <MenuTrigger disableButtonEnhancement>
              <Button
                className={`menu-bar-btn ${openTopMenu === "window" ? "is-open" : ""}`}
                size="small"
                appearance="transparent"
                onMouseEnter={() => handleTopMenuTriggerEnter("window")}
              >
                {t("main.menu.window")}
              </Button>
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem disabled>{t("main.menu.window")}</MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
          <Menu
            open={openTopMenu === "help"}
            onOpenChange={(_, data) => handleTopMenuOpenChange("help", data.open)}
          >
            <MenuTrigger disableButtonEnhancement>
              <Button
                className={`menu-bar-btn ${openTopMenu === "help" ? "is-open" : ""}`}
                size="small"
                appearance="transparent"
                onMouseEnter={() => handleTopMenuTriggerEnter("help")}
              >
                {t("main.menu.help")}
              </Button>
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem>{t("main.menu.helpAppName")}</MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
        </div>
        <div className="menu-drag-region" aria-hidden />
        <div className="window-controls" data-help={t("help.menuBar")}>
          <Button
            className="window-control-btn"
            appearance="transparent"
            icon={<Subtract24Regular />}
            onClick={handleWindowMinimize}
            aria-label="Minimize"
          />
          <Button
            className="window-control-btn"
            appearance="transparent"
            icon={isWindowMaximized ? <SquareMultiple24Regular /> : <Square24Regular />}
            onClick={handleWindowToggleMaximize}
            aria-label="Maximize or Restore"
          />
          <Button
            className="window-control-btn window-control-close"
            appearance="transparent"
            icon={<Dismiss24Regular />}
            onClick={handleWindowClose}
            aria-label="Close"
          />
        </div>
      </header>
      ) : (
      <header className="app-bootbar" data-help={t("help.menuBar")}>
        <div className="boot-drag-region" aria-hidden />
        <div className="window-controls">
          <Button
            className="window-control-btn"
            appearance="transparent"
            icon={<Subtract24Regular />}
            onClick={handleWindowMinimize}
            aria-label="Minimize"
          />
          <Button
            className="window-control-btn"
            appearance="transparent"
            icon={isWindowMaximized ? <SquareMultiple24Regular /> : <Square24Regular />}
            onClick={handleWindowToggleMaximize}
            aria-label="Maximize or Restore"
          />
          <Button
            className="window-control-btn window-control-close"
            appearance="transparent"
            icon={<Dismiss24Regular />}
            onClick={handleWindowClose}
            aria-label="Close"
          />
        </div>
      </header>
      )}

      <main
        className={`workspace workspace-main adaptive-scope${structuralResizing ? " is-structural-resizing" : ""}${bootReady ? "" : " workspace-main-standby"}`}
        ref={workspaceRef}
      >
        <div
          className={`panes-row${dragMode ? " is-resizing" : ""}${paneSnapAnimating ? " is-snap-animating" : ""}`}
          style={{ gridTemplateColumns: layout.template }}
        >
          <section
            className={`pane pane-files ${activePanel === "files" ? "is-active" : ""} ${fileCollapsed ? "is-collapsed" : ""}`}
            data-pane-tone="files"
            onMouseEnter={() => setActivePanel("files")}
            onFocus={() => setActivePanel("files")}
            data-help={t("help.fileArea")}
          >
            <div
              className="pane-header"
              onDoubleClick={() => {
                if (fileCollapsed) {
                  forceExpandPane("files");
                  setStatus("status.filePanelRestored");
                } else {
                  collapseFiles("manual");
                  setStatus("status.filePanelCollapsed");
                }
              }}
              data-help={fileCollapsed ? t("help.fileHeaderRestore") : t("help.fileHeaderCollapse")}
            >
              <div className="pane-header-title-switch">
                <span className="pane-header-title-h">{t("panel.files")}</span>
                <span className="pane-header-title-v" aria-hidden>
                  {t("panel.files")}
                </span>
              </div>
            </div>

            <div className="pane-body pane-body-files">
              <div className="file-workbench">
                <div className="file-top-controls">
                  <div className="file-address-row">
                    <div className="address-input-shell" data-help={t("help.folderAddress")}>
                      <Input
                        className="address-input"
                        value={folderInput}
                        onChange={(_, data) => setFolderInput(data.value)}
                        onKeyDown={(event) => {
                          if (event.key === "Enter") {
                            void handleApplyFolderInput();
                          }
                        }}
                        placeholder={t("placeholder.folderAddress")}
                      />
                      <Button
                        className="address-read-inline-btn"
                        appearance="transparent"
                        icon={<ChevronRight24Regular />}
                        onClick={() => {
                          void handleApplyFolderInput();
                        }}
                        aria-label={t("button.openAddress")}
                        data-help={t("help.addressApply")}
                      />
                    </div>
                    <Button
                      appearance="primary"
                      icon={<FolderOpen24Regular />}
                      onClick={() => {
                        void handleSelectFolder();
                      }}
                      data-help={t("help.selectFolder")}
                    >
                      {t("button.selectFolder")}
                    </Button>
                  </div>
                </div>

                <div
                  className={`file-split-host${fileSplitDragging ? " is-resizing" : ""}${fileSplitSnapAnimating ? " is-snap-animating" : ""}`}
                  ref={splitHostRef}
                  style={{ gridTemplateRows: splitLayout.template }}
                >
                  <div className="file-browser-area" ref={browserAreaRef}>
                    {!projectFolder ? (
                      <div className="empty-block" data-help={t("help.fileAreaPreImport")}>
                        <div>{t("file.preImportHint")}</div>
                      </div>
                    ) : (
                      <div
                        className={`file-browser-stack${tagListDragging ? " is-resizing" : ""}${tagListSnapAnimating ? " is-snap-animating" : ""}`}
                        style={{ gridTemplateRows: tagListLayout.template }}
                      >
                        <div className={`tag-browser fade-switch ${tagCollapsed ? "is-collapsed" : ""}`}>
                          <button
                            type="button"
                            className="section-collapsed-bar fade-switch-collapsed"
                            onClick={() => {
                              setTagCollapsed(false);
                              setTagHeight(Math.max(TAG_MIN_HEIGHT, tagRememberHeightRef.current));
                            }}
                            onDoubleClick={() => {
                              setTagCollapsed(false);
                              setTagHeight(Math.max(TAG_MIN_HEIGHT, tagRememberHeightRef.current));
                            }}
                            data-help={t("help.fileTree")}
                          >
                            {t("file.treeTitle")}
                          </button>
                          <div className="browser-card-body fade-switch-expanded">
                            {scanBusy ? (
                              <div className="empty-block compact">{t("file.scanning")}</div>
                            ) : treeNodes.length === 0 ? (
                              <div className="empty-block compact">{t("file.treeEmpty")}</div>
                            ) : (
                              <Tree
                                className="file-tree"
                                openItems={Array.from(openTreeItems)}
                                onOpenChange={(_, data) => {
                                  const next = new Set<string>();
                                  for (const item of data.openItems) {
                                    next.add(String(item));
                                  }
                                  setOpenTreeItems(next);
                                }}
                                data-help={t("help.fileTree")}
                              >
                                <TreeItem itemType="leaf" value={ALL_NODE_ID}>
                                  <TreeItemLayout
                                    className={selectedTreeId === ALL_NODE_ID ? "file-tree-item is-selected is-leaf" : "file-tree-item is-leaf"}
                                    style={{ paddingInlineStart: `${4 + TREE_EXPAND_SLOT_WIDTH}px` }}
                                    iconBefore={
                                      <span className="tree-folder-icon-wrap">
                                        <Home24Regular className="tree-role-icon" />
                                      </span>
                                    }
                                    onClick={() => setSelectedTreeId(ALL_NODE_ID)}
                                  >
                                    {t("file.allImages")}
                                  </TreeItemLayout>
                                </TreeItem>
                                {treeNodes.map((node) => renderTree(node, false, 0))}
                              </Tree>
                            )}
                          </div>
                        </div>

                        <div
                          className="tag-list-resizer"
                          role="separator"
                          aria-orientation="horizontal"
                          onMouseDown={(event) => {
                            tagListStartRef.current = {
                              y: event.clientY,
                              tag: tagListLayout.tag
                            };
                            setTagListDragging(true);
                          }}
                          onDoubleClick={() => {
                            if (!tagCollapsed && canCollapseInner("tag")) {
                              tagRememberHeightRef.current = Math.max(TAG_MIN_HEIGHT, tagListLayout.tag);
                              setTagCollapsed(true);
                              return;
                            }
                            setTagCollapsed(false);
                            setTagHeight(Math.max(TAG_MIN_HEIGHT, tagRememberHeightRef.current));
                          }}
                          data-help={t("help.previewResizer")}
                        />

                        <div className={`image-browser fade-switch ${listCollapsed ? "is-collapsed" : ""}`}>
                          <button
                            type="button"
                            className="section-collapsed-bar fade-switch-collapsed"
                            onClick={() => {
                              setListCollapsed(false);
                              const available = Math.max(browserAreaHeight, 120) - TAG_LIST_RESIZER_HEIGHT;
                              const maxTag = Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT);
                              const restoreList = Math.max(LIST_MIN_HEIGHT, listRememberHeightRef.current);
                              setTagHeight(clamp(available - restoreList, TAG_MIN_HEIGHT, maxTag));
                            }}
                            onDoubleClick={() => {
                              setListCollapsed(false);
                              const available = Math.max(browserAreaHeight, 120) - TAG_LIST_RESIZER_HEIGHT;
                              const maxTag = Math.max(TAG_MIN_HEIGHT, available - LIST_MIN_HEIGHT);
                              const restoreList = Math.max(LIST_MIN_HEIGHT, listRememberHeightRef.current);
                              setTagHeight(clamp(available - restoreList, TAG_MIN_HEIGHT, maxTag));
                            }}
                            data-help={t("help.filePairBrowser")}
                          >
                            {t("file.listTitle")}
                          </button>
                          <div className="image-list-wrap fade-switch-expanded" ref={imageListWrapRef} data-help={t("help.filePairBrowser")}>
                            <div className="image-table-scroller">
                              <div className="image-table-head-sticky">
                                <div
                                  className="image-table-head"
                                  style={{
                                    gridTemplateColumns: tableTemplate.template
                                  }}
                                >
                                  <div className="image-head-cell">ROI</div>
                                  <div
                                    className="image-col-resizer"
                                    role="separator"
                                    aria-orientation="vertical"
                                    onMouseDown={(event) => {
                                      tableColStartRef.current = {
                                        x: event.clientX,
                                        roi: tableTemplate.roi,
                                        normal: tableTemplate.normal,
                                        fluo: tableTemplate.fluo,
                                        time: tableTemplate.time,
                                        project: tableTemplate.project
                                      };
                                      setTableColDragging("roi");
                                    }}
                                  />
                                  <div className="image-head-cell">{t("file.normalColumn")}</div>
                                  <div
                                    className="image-col-resizer"
                                    role="separator"
                                    aria-orientation="vertical"
                                    onMouseDown={(event) => {
                                      tableColStartRef.current = {
                                        x: event.clientX,
                                        roi: tableTemplate.roi,
                                        normal: tableTemplate.normal,
                                        fluo: tableTemplate.fluo,
                                        time: tableTemplate.time,
                                        project: tableTemplate.project
                                      };
                                      setTableColDragging("normal");
                                    }}
                                  />
                                  {tableTemplate.hasFluo ? (
                                    <>
                                      <div className="image-head-cell">{t("file.fluoColumn")}</div>
                                      <div
                                        className="image-col-resizer"
                                        role="separator"
                                        aria-orientation="vertical"
                                        onMouseDown={(event) => {
                                          tableColStartRef.current = {
                                            x: event.clientX,
                                            roi: tableTemplate.roi,
                                            normal: tableTemplate.normal,
                                            fluo: tableTemplate.fluo,
                                            time: tableTemplate.time,
                                            project: tableTemplate.project
                                          };
                                          setTableColDragging("fluo");
                                        }}
                                      />
                                    </>
                                  ) : null}
                                  <div className="image-head-cell">{t("file.timeColumn")}</div>
                                  <div
                                    className="image-col-resizer"
                                    role="separator"
                                    aria-orientation="vertical"
                                    onMouseDown={(event) => {
                                      tableColStartRef.current = {
                                        x: event.clientX,
                                        roi: tableTemplate.roi,
                                        normal: tableTemplate.normal,
                                        fluo: tableTemplate.fluo,
                                        time: tableTemplate.time,
                                        project: tableTemplate.project
                                      };
                                      setTableColDragging("time");
                                    }}
                                  />
                                  <div className="image-head-cell">{t("file.projectColumn")}</div>
                                  <div
                                    className="image-col-resizer"
                                    role="separator"
                                    aria-orientation="vertical"
                                    onMouseDown={(event) => {
                                      tableColStartRef.current = {
                                        x: event.clientX,
                                        roi: tableTemplate.roi,
                                        normal: tableTemplate.normal,
                                        fluo: tableTemplate.fluo,
                                        time: tableTemplate.time,
                                        project: tableTemplate.project
                                      };
                                      setTableColDragging("project");
                                    }}
                                  />
                                </div>
                              </div>

                              <div className="image-table-body">
                                {visiblePairs.length === 0 ? (
                                  <div className="empty-block compact">{t("file.listEmpty")}</div>
                                ) : (
                                  visiblePairs.map((pair) => {
                                    const pairMeta = pairDerivedMetaMap.get(pair.id);
                                    const pairUi = resolvePairUi(pair);
                                    const ignoredRow = pairUi.ignored || (pairMeta?.ignoredByTag ?? false);
                                    const roiModeForRender: RoiUsageMode =
                                      pairUi.roiMode === "native" && !pair.normalHasRoi ? "none" : pairUi.roiMode;
                                    const roiIcon = ignoredRow ? renderMenuGlyph() : renderRoiIcon(roiModeForRender, true);

                                    const rowActive = selectedPairId === pair.id;
                                    const normalActive = rowActive && selectedSide === "normal";
                                    const fluoActive = rowActive && selectedSide === "fluo";
                                    const rowPath = pair.normalPath || pair.fluoPath || "";
                                    const rowTime = pairMeta?.timeLabel ?? "";
                                    const rowProject = pairMeta?.projectLabel ?? "";

                                    return (
                                    <Menu key={pair.id} openOnContext>
                                      <MenuTrigger disableButtonEnhancement>
                                        <div
                                          className={`image-table-row ${rowActive ? "is-row-active" : ""}${ignoredRow ? " is-ignored" : ""}`}
                                          style={{
                                            gridTemplateColumns: tableTemplate.template
                                          }}
                                        >
                                          <button
                                            type="button"
                                            className="image-cell roi-cell"
                                            onClick={() => {
                                              setSelectedPairId(pair.id);
                                              setSelectedSide(pair.normalPath ? "normal" : "fluo");
                                            }}
                                          >
                                            {roiIcon}
                                          </button>
                                          <div className="image-col-sep" />
                                          <button
                                            type="button"
                                            className={`image-cell file-cell ${normalActive ? "is-cell-active" : ""}`}
                                            disabled={!pair.normalPath}
                                            onClick={() => {
                                              if (!pair.normalPath) return;
                                              setSelectedPairId(pair.id);
                                              setSelectedSide("normal");
                                            }}
                                            data-help={
                                              pair.normalPath
                                                ? t("help.fileRow", { name: pair.normalName || t("file.slotEmpty") })
                                                : t("help.fileRowEmpty")
                                            }
                                          >
                                            {pair.normalName || t("file.slotEmpty")}
                                          </button>
                                          <div className="image-col-sep" />
                                          {tableTemplate.hasFluo ? (
                                            <>
                                              <button
                                                type="button"
                                                className={`image-cell file-cell ${fluoActive ? "is-cell-active" : ""}`}
                                                disabled={!pair.fluoPath}
                                                onClick={() => {
                                                  if (!pair.fluoPath) return;
                                                  setSelectedPairId(pair.id);
                                                  setSelectedSide("fluo");
                                                }}
                                                data-help={
                                                  pair.fluoPath
                                                    ? t("help.fileRow", { name: pair.fluoName || t("file.slotEmpty") })
                                                    : t("help.fileRowEmpty")
                                                }
                                              >
                                                {pair.fluoName || t("file.slotEmpty")}
                                              </button>
                                              <div className="image-col-sep" />
                                            </>
                                          ) : null}
                                          <div className="image-cell meta-cell">{rowTime}</div>
                                          <div className="image-col-sep" />
                                          <div className="image-cell meta-cell">{rowProject}</div>
                                          <div className="image-col-sep" />
                                        </div>
                                      </MenuTrigger>
                                      <MenuPopover>
                                        <MenuList>
                                          <MenuItem
                                            icon={renderMenuGlyph()}
                                            disabled={!rowPath}
                                            onClick={() => {
                                              void openPathBySystem(rowPath);
                                            }}
                                          >
                                            {t("menu.image.openExternal")}
                                          </MenuItem>
                                          <MenuItem
                                            icon={renderMenuGlyph()}
                                            disabled={!pair.normalRoiPath}
                                            onClick={() => {
                                              void openPathBySystem(pair.normalRoiPath);
                                            }}
                                          >
                                            {t("menu.image.editRoi")}
                                          </MenuItem>
                                          <MenuItem
                                            icon={renderMenuGlyph()}
                                            onClick={() => {
                                              patchPairUiState(pair.id, { ignored: !pairUi.ignored });
                                            }}
                                          >
                                            {pairUi.ignored ? t("menu.image.unignore") : t("menu.image.ignore")}
                                          </MenuItem>
                                          <MenuItem
                                            icon={renderRoiIcon("native", true)}
                                            disabled={!pair.normalRoiPath}
                                            onClick={() => {
                                              patchPairUiState(pair.id, { roiMode: "native" });
                                            }}
                                          >
                                            {t("menu.image.useNativeRoi")}
                                          </MenuItem>
                                          <MenuItem
                                            icon={renderRoiIcon("auto", true)}
                                            onClick={() => {
                                              patchPairUiState(pair.id, { roiMode: "auto" });
                                            }}
                                          >
                                            {t("menu.image.useAutoRoi")}
                                          </MenuItem>
                                          <MenuDivider />
                                          <MenuItem icon={renderRoiIcon("auto", true)} onClick={setVisibleNoRoiAsAuto}>
                                            {t("menu.image.setNoRoiToAuto")}
                                          </MenuItem>
                                          <MenuItem icon={renderRoiIcon("native", true)} onClick={setVisiblePreferNativeRoi}>
                                            {t("menu.image.preferAllNativeRoi")}
                                          </MenuItem>
                                          <MenuItem icon={renderRoiIcon("none", true)} onClick={setVisibleAutoAsNoRoi}>
                                            {t("menu.image.setAutoToNoRoi")}
                                          </MenuItem>
                                          {pair.fluoPath ? <MenuDivider /> : null}
                                          {pair.fluoPath ? (
                                            <MenuItem
                                              icon={renderMenuGlyph()}
                                              onClick={() => {
                                                handleLearnFluorescenceRoi(pair);
                                              }}
                                            >
                                              {t("menu.image.learnFluoRoi")}
                                            </MenuItem>
                                          ) : null}
                                        </MenuList>
                                      </MenuPopover>
                                    </Menu>
                                    );
                                  })
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  <div
                    className="file-h-resizer"
                    role="separator"
                    aria-orientation="horizontal"
                    onMouseDown={(event) => {
                      fileSplitStartRef.current = {
                        y: event.clientY,
                        browser: splitLayout.browser
                      };
                      setFileSplitDragging(true);
                    }}
                    onDoubleClick={() => {
                      if (previewCollapsed) {
                        restorePreviewPane();
                      } else {
                        collapsePreviewPane();
                      }
                    }}
                    data-help={t("help.previewResizer")}
                  />
                  <div className={`file-preview-area fade-switch ${previewCollapsed ? "is-collapsed" : ""}`}>
                    <button
                      type="button"
                      className="preview-collapsed-bar fade-switch-collapsed"
                      onClick={restorePreviewPane}
                      onDoubleClick={restorePreviewPane}
                      data-help={t("help.previewCollapsedBar")}
                    >
                      {t("file.previewTitle")}
                    </button>
                    <div className="preview-stage fade-switch-expanded">
                      <div className="preview-canvas" ref={previewViewportRef} onWheel={handlePreviewWheel} aria-busy={previewLoading}>
                          {previewSrc ? (
                            <img
                              src={previewSrc}
                              alt={selectedPair?.normalName || selectedPair?.fluoName || "preview"}
                              className={previewZoom > 1 ? "preview-image is-zoomed" : "preview-image"}
                              draggable={false}
                              onLoad={(event) => {
                                const img = event.currentTarget;
                                setPreviewNatural({ width: img.naturalWidth, height: img.naturalHeight });
                              }}
                              onMouseDown={(event) => {
                                if (previewZoom <= 1) return;
                                event.preventDefault();
                                previewDragStartRef.current = {
                                  x: event.clientX,
                                  y: event.clientY,
                                  panX: previewPanX,
                                  panY: previewPanY
                                };
                                setPreviewDragging(true);
                              }}
                              style={{
                                transform: `translate(${previewPanX}px, ${previewPanY}px) scale(${previewZoom})`
                              }}
                            />
                          ) : previewError ? (
                            <div className="empty-block compact">{previewError}</div>
                          ) : (
                            <div className="empty-block compact">{t("file.previewEmpty")}</div>
                          )}

                          {previewLoading ? (
                            <div className="preview-loading-overlay" role="status" aria-live="polite">
                              <Spinner size="small" label={t("file.previewLoading")} />
                            </div>
                          ) : null}

                        <div className="preview-overlay" data-help={t("help.previewToolbar")}>
                            <Button
                              size="small"
                              appearance="secondary"
                              icon={<ArrowUp24Regular />}
                              onClick={handlePreviewPrev}
                              disabled={!canMoveSelectionInColumn(-1)}
                              aria-label={t("button.prev")}
                            />
                            <Button
                              size="small"
                              appearance="secondary"
                              icon={<ArrowDown24Regular />}
                              onClick={handlePreviewNext}
                              disabled={!canMoveSelectionInColumn(1)}
                              aria-label={t("button.next")}
                            />
                            <Button
                              size="small"
                              appearance="secondary"
                              icon={<ZoomOut24Regular />}
                              onClick={() => {
                                setPreviewZoom((prev) => clamp(Number((prev / 1.2).toFixed(4)), ZOOM_MIN, ZOOM_MAX));
                              }}
                              disabled={!previewSrc}
                              aria-label={t("button.zoomOut")}
                            />
                            <Button
                              size="small"
                              appearance="secondary"
                              icon={<ZoomIn24Regular />}
                              onClick={() => {
                                setPreviewZoom((prev) => clamp(Number((prev * 1.2).toFixed(4)), ZOOM_MIN, ZOOM_MAX));
                              }}
                              disabled={!previewSrc}
                              aria-label={t("button.zoomIn")}
                            />
                            <Button
                              size="small"
                              appearance="secondary"
                              icon={<ArrowReset24Regular />}
                              onClick={() => {
                                setPreviewZoom(1);
                                setPreviewPanX(0);
                                setPreviewPanY(0);
                              }}
                              disabled={!previewSrc}
                              aria-label={t("button.zoomReset")}
                            />
                            <Button
                              size="small"
                              appearance="primary"
                              icon={<Open24Regular />}
                              onClick={() => {
                                void handlePreviewOpenExternal();
                              }}
                              disabled={!selectedPreviewPath}
                              aria-label={t("button.openExternal")}
                            />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <div
            className="resizer"
            role="separator"
            aria-orientation="vertical"
            onMouseDown={(e) => beginDrag("left", e.clientX)}
            onDoubleClick={() => {
              if (fileCollapsed) {
                forceExpandPane("files");
              } else {
                collapseFiles("manual");
              }
            }}
            data-help={t("help.resizerLeft")}
          />

          <section
            className={`pane pane-settings ${activePanel === "settings" ? "is-active" : ""} ${settingsCollapsed ? "is-collapsed" : ""}`}
            data-pane-tone="settings"
            onMouseEnter={() => setActivePanel("settings")}
            onFocus={() => setActivePanel("settings")}
            data-help={t("help.settingsArea")}
          >
            <div
              className="pane-header"
              onDoubleClick={() => {
                if (settingsCollapsed) {
                  forceExpandPane("settings");
                  setStatus("status.settingsPanelRestored");
                } else {
                  collapseSettings();
                  setStatus("status.settingsPanelCollapsed");
                }
              }}
              data-help={settingsCollapsed ? t("help.settingsHeaderRestore") : t("help.settingsHeaderCollapse")}
            >
              <div className="pane-header-title-switch">
                <span className="pane-header-title-h">{t("panel.settings")}</span>
                <span className="pane-header-title-v" aria-hidden>
                  {t("panel.settings")}
                </span>
              </div>
            </div>

            <div className="pane-body pane-body-settings">
              <div className="settings-scroll">
                <Accordion
                  multiple
                  collapsible
                  openItems={operationOpenSections}
                  onToggle={(_, data) => {
                    const next = (data.openItems as OperationSectionKey[]) ?? [];
                    setOperationOpenSections(next);
                  }}
                  className="operation-accordion"
                >
                  <AccordionItem value="files">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("files") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      <span className="operation-header-title-row">
                        <span className="operation-header-title-text">{t("op.section.files")}</span>
                        {operationOpenSections.includes("files") ? (
                          <Button
                                                        appearance={filesDirty ? "primary" : "secondary"}
                            className="operation-header-apply-btn"
                            onClick={(event) => {
                              event.preventDefault();
                              event.stopPropagation();
                              void applyFilesSection();
                            }}
                          >
                            {t("button.apply")}
                          </Button>
                        ) : null}
                      </span>
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.files")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.reading")}</div>
                          <Field label={t("field.folderPath")} size="small">
                            <Input
                              value={folderInput}
                              onChange={(_, data) => setFolderInput(data.value)}
                              onKeyDown={(event) => {
                                if (event.key === "Enter") {
                                  void handleApplyFolderInput();
                                }
                              }}
                              data-help={t("help.folderAddress")}
                            />
                          </Field>
                          <div className="button-row button-row-adaptive">
                            <Button appearance="secondary" onClick={() => void handleSelectFolder()} data-help={t("help.selectFolder")}>
                              {t("button.selectFolder")}
                            </Button>
                            <Button appearance="secondary" onClick={() => void handleApplyFolderInput()} data-help={t("help.addressApply")}>
                              {t("button.openAddress")}
                            </Button>
                          </div>
                        </div>

                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.parseAndGroup")}</div>
                          <Field label={t("field.filenamePreset")} size="small">
                            <Dropdown
                              value={presetLabel}
                              selectedOptions={[preset]}
                              onOptionSelect={(_, data) => {
                                const next = data.optionValue;
                                if (next === "WINDOWS" || next === "DOLPHIN" || next === "MACOS") {
                                  setPreset(next);
                                }
                              }}
                              data-help={t("help.filenamePreset")}
                            >
                              {presetOptions.map((item) => (
                                <Option key={item.value} value={item.value}>
                                  {item.label}
                                </Option>
                              ))}
                            </Dropdown>
                          </Field>
                          <div className="preset-example-wrap" aria-hidden>
                            <div className="preset-example-title">{t("field.filenamePresetExample")}</div>
                            <div className="preset-example-list">
                              {presetExamples.map((item) => (
                                <div key={item} className="preset-example-item">
                                  {item}
                                </div>
                              ))}
                            </div>
                          </div>
                          <Field label={t("field.subfolderMode")} size="small">
                            <Dropdown
                              value={subfolderModeLabel}
                              selectedOptions={[subfolderMode]}
                              onOptionSelect={(_, data) => {
                                const next = data.optionValue;
                                if (next === "keep" || next === "flat") {
                                  setSubfolderMode(next);
                                }
                              }}
                            >
                              <Option value="keep">{t("field.subfolderKeep")}</Option>
                              <Option value="flat">{t("field.subfolderFlat")}</Option>
                            </Dropdown>
                          </Field>
                          <div className="inline-note">
                            {subfolderMode === "keep" ? t("field.subfolderKeepDesc") : t("field.subfolderFlatDesc")}
                          </div>
                          <div className="meta-line">
                            {t("op.fileStats", {
                              images: workspaceScan?.totalImages ?? 0,
                              pairs: workspaceScan?.totalPairs ?? 0
                            })}
                          </div>
                        </div>

                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.nameRules")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.namingCustom")}
                              labelPosition="after"
                              checked={namingCustomEnabled}
                              onChange={(_, data) => setNamingCustomEnabled(data.checked)}
                            />
                          </div>
                          <div className="settings-grid settings-grid-flow">
                            <Field label={t("field.projectNamingRule")} size="small">
                              <Dropdown
                                value={
                                  projectNamingRule === "filename"
                                    ? t("field.projectNamingRuleFilename")
                                    : t("field.projectNamingRuleFolder")
                                }
                                selectedOptions={[projectNamingRule]}
                                disabled={namingCustomEnabled}
                                onOptionSelect={(_, data) => {
                                  const next = data.optionValue;
                                  if (next === "filename" || next === "folder") {
                                    setProjectNamingRule(next);
                                  }
                                }}
                              >
                                <Option value="filename">{t("field.projectNamingRuleFilename")}</Option>
                                <Option value="folder">{t("field.projectNamingRuleFolder")}</Option>
                              </Dropdown>
                            </Field>
                            <Field label={t("field.timeNamingRule")} size="small">
                              <Dropdown
                                value={
                                  timeNamingRule === "folder"
                                    ? t("field.timeNamingRuleFolder")
                                    : t("field.timeNamingRuleFilename")
                                }
                                selectedOptions={[timeNamingRule]}
                                disabled={namingCustomEnabled}
                                onOptionSelect={(_, data) => {
                                  const next = data.optionValue;
                                  if (next === "folder" || next === "filename") {
                                    setTimeNamingRule(next);
                                  }
                                }}
                              >
                                <Option value="folder">{t("field.timeNamingRuleFolder")}</Option>
                                <Option value="filename">{t("field.timeNamingRuleFilename")}</Option>
                              </Dropdown>
                            </Field>
                          </div>
                          <div className="meta-line">
                            {t("op.namingStats", {
                              times: namingStats.timeKinds,
                              projects: namingStats.projectKinds,
                              noTime: namingStats.noTime,
                              noProject: namingStats.noProject
                            })}
                          </div>
                        </div>

                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="cellRoi">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("cellRoi") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      <span className="operation-header-title-row">
                        <span className="operation-header-title-text">{t("op.section.cellRoi")}</span>
                        {operationOpenSections.includes("cellRoi") ? (
                          <Button
                                                        appearance={cellRoiDirty ? "primary" : "secondary"}
                            className="operation-header-apply-btn"
                            onClick={(event) => {
                              event.preventDefault();
                              event.stopPropagation();
                              void applyCellRoiSection();
                            }}
                          >
                            {t("button.apply")}
                          </Button>
                        ) : null}
                      </span>
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.cellRoi")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.roiThresholds")}</div>
                          <div className="settings-grid settings-grid-numeric">
                            <Field label={t("field.minArea")} size="small">
                              <Input
                                type="number"
                                value={minArea}
                                step={1}
                                min={0}
                                onChange={(_, data) => setMinArea(data.value)}
                                data-help={t("help.minArea")}
                              />
                            </Field>

                            <Field label={t("field.maxArea")} size="small">
                              <Input
                                type="number"
                                value={maxArea}
                                step={5}
                                min={0}
                                onChange={(_, data) => setMaxArea(data.value)}
                                data-help={t("help.maxArea")}
                              />
                            </Field>

                            <Field label={t("field.circularity")} size="small">
                              <Input
                                type="number"
                                value={circularity}
                                step={0.01}
                                min={0}
                                max={1}
                                onChange={(_, data) => setCircularity(data.value)}
                                data-help={t("help.circularity")}
                              />
                            </Field>
                            <Field label={t("field.autoCellArea")} size="small">
                              <Input
                                type="number"
                                value={autoCellArea}
                                step={5}
                                min={1}
                                onChange={(_, data) => setAutoCellArea(data.value)}
                              />
                            </Field>
                          </div>
                          <Field label={t("field.roiSuffix")} size="small">
                            <Input value={roiSuffix} onChange={(_, data) => setRoiSuffix(data.value)} />
                          </Field>
                          <div className="roi-preview-card">
                            <div className="roi-preview-title">{t("field.roiPreviewTitle")}</div>
                            <svg viewBox="0 0 260 140" className="roi-preview-svg" role="img" aria-label={t("field.roiPreviewTitle")}>
                              <rect x="1" y="1" width="258" height="138" className="roi-preview-bg" />
                              <path d={roiPreviewModel.maxPath} className="roi-preview-max" />
                              <path d={roiPreviewModel.minPath} className="roi-preview-min" />
                              <line x1={40} y1={roiPreviewModel.cy - roiPreviewModel.minRy} x2={40} y2={roiPreviewModel.cy + roiPreviewModel.minRy} className="roi-preview-bracket" />
                              <line x1={40} y1={roiPreviewModel.cy - roiPreviewModel.minRy} x2={56} y2={roiPreviewModel.cy - roiPreviewModel.minRy} className="roi-preview-bracket" />
                              <line x1={40} y1={roiPreviewModel.cy + roiPreviewModel.minRy} x2={56} y2={roiPreviewModel.cy + roiPreviewModel.minRy} className="roi-preview-bracket" />
                              <line x1={232} y1={roiPreviewModel.cy - roiPreviewModel.maxRy} x2={232} y2={roiPreviewModel.cy + roiPreviewModel.maxRy} className="roi-preview-bracket" />
                              <line x1={232} y1={roiPreviewModel.cy - roiPreviewModel.maxRy} x2={216} y2={roiPreviewModel.cy - roiPreviewModel.maxRy} className="roi-preview-bracket" />
                              <line x1={232} y1={roiPreviewModel.cy + roiPreviewModel.maxRy} x2={216} y2={roiPreviewModel.cy + roiPreviewModel.maxRy} className="roi-preview-bracket" />
                              <text x={32} y={roiPreviewModel.cy + 4} className="roi-preview-diameter-label" textAnchor="end">
                                {`${t("field.minArea")} ${roiPreviewModel.minDiameterValue.toFixed(1)}`}
                              </text>
                              <text x={240} y={roiPreviewModel.cy + 4} className="roi-preview-diameter-label">
                                {`${t("field.maxArea")} ${roiPreviewModel.maxDiameterValue.toFixed(1)}`}
                              </text>
                            </svg>
                            <div className="inline-note">
                              {t("field.roiPreviewHint")}
                            </div>
                          </div>
                        </div>

                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.roiPolicy")}</div>
                          <div className="inline-note">{t("field.roiPolicyScopeAll")}</div>
                          <div className="button-row button-row-adaptive">
                            <Button appearance="secondary" onClick={setGlobalNoRoiAsAuto}>
                              {t("field.roiSetNoRoiToAutoAll")}
                            </Button>
                            <Button appearance="secondary" onClick={setGlobalPreferNativeRoi}>
                              {t("field.roiPreferNativeAll")}
                            </Button>
                          </div>
                        </div>

                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="target">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("target") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      {t("op.section.target")}
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.target")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.targetFeatures")}</div>
                          <Field label={t("field.targetFeatures")} size="small">
                            <div className="feature-grid">
                              <Checkbox
                                id="feature-checkbox-f1"
                                checked={featureFlags.f1}
                                label={t("field.feature1")}
                                onChange={() => setFeatureChecked("f1")}
                              />
                              <Checkbox
                                id="feature-checkbox-f2"
                                checked={featureFlags.f2}
                                label={t("field.feature2")}
                                onChange={() => setFeatureChecked("f2")}
                              />
                              <Checkbox
                                id="feature-checkbox-f3"
                                checked={featureFlags.f3}
                                label={t("field.feature3")}
                                onChange={() => setFeatureChecked("f3")}
                              />
                              <Divider className="feature-divider" />
                              <Checkbox
                                id="feature-checkbox-f5"
                                checked={featureFlags.f5}
                                label={t("field.feature5")}
                                onChange={() => setFeatureChecked("f5")}
                              />
                              <Checkbox
                                id="feature-checkbox-f6"
                                checked={featureFlags.f6}
                                label={t("field.feature6")}
                                onChange={() => setFeatureChecked("f6")}
                              />
                            </div>
                          </Field>
                          <div className="feature-preview-wrap" role="group" aria-label={t("field.targetFeatures")}>
                            <div className="feature-preview-legend">
                              <div className={`feature-preview-card feature-preview-card-f1${featureFlags.f1 ? " is-active" : ""}`}>
                                <div className="feature-preview-name">F1</div>
                                <div className="feature-preview-stage">{renderFeatureIllustration("f1")}</div>
                              </div>
                              <div className={`feature-preview-card feature-preview-card-f2${featureFlags.f2 ? " is-active" : ""}`}>
                                <div className="feature-preview-name">F2</div>
                                <div className="feature-preview-stage">{renderFeatureIllustration("f2")}</div>
                              </div>
                              <div className={`feature-preview-card feature-preview-card-f3${featureFlags.f3 ? " is-active" : ""}`}>
                                <div className="feature-preview-name">F3</div>
                                <div className="feature-preview-stage">{renderFeatureIllustration("f3")}</div>
                              </div>
                              <div className="feature-preview-h-divider" aria-hidden />
                              <div className="feature-preview-v-divider" aria-hidden />
                              <div className={`feature-preview-card feature-preview-card-f5${featureFlags.f5 ? " is-active" : ""}`}>
                                <div className="feature-preview-name">F5</div>
                                <div className="feature-preview-stage">{renderFeatureIllustration("f5")}</div>
                              </div>
                              <div className={`feature-preview-card feature-preview-card-f6${featureFlags.f6 ? " is-active" : ""}`}>
                                <div className="feature-preview-name">F6</div>
                                <div className="feature-preview-stage">{renderFeatureIllustration("f6")}</div>
                              </div>
                            </div>
                          </div>
                        </div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.targetThresholds")}</div>
                          <div className="settings-grid settings-grid-numeric">
                            <Field label={t("field.targetMinContrast")} size="small">
                              <Input
                                type="number"
                                value={targetMinContrast}
                                step={0.01}
                                min={0}
                                onChange={(_, data) => setTargetMinContrast(data.value)}
                                data-help={t("help.targetMinContrast")}
                              />
                            </Field>
                            <Field label={t("field.featureCenterDiff")} size="small">
                              <Input
                                type="number"
                                value={centerDiffThreshold}
                                step={1}
                                min={0}
                                onChange={(_, data) => setCenterDiffThreshold(data.value)}
                              />
                            </Field>
                            <Field label={t("field.featureBgDiff")} size="small">
                              <Input
                                type="number"
                                value={bgDiffThreshold}
                                step={1}
                                min={0}
                                onChange={(_, data) => setBgDiffThreshold(data.value)}
                              />
                            </Field>
                            <Field label={t("field.featureSmallRatio")} size="small">
                              <Input
                                type="number"
                                value={smallAreaRatio}
                                step={0.01}
                                min={0}
                                onChange={(_, data) => setSmallAreaRatio(data.value)}
                              />
                            </Field>
                            <Field label={t("field.featureClumpRatio")} size="small">
                              <Input
                                type="number"
                                value={clumpMinRatio}
                                step={0.01}
                                min={0}
                                onChange={(_, data) => setClumpMinRatio(data.value)}
                              />
                            </Field>
                            <Field label={t("field.rollingRadius")} size="small">
                              <Input
                                type="number"
                                value={rollingRadius}
                                step={1}
                                min={0}
                                onChange={(_, data) => setRollingRadius(data.value)}
                              />
                            </Field>
                          </div>
                        </div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.targetPolicy")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.targetUseRoundFilter")}
                              labelPosition="after"
                              checked={targetUseRoundFilter}
                              onChange={(_, data) => setTargetUseRoundFilter(data.checked)}
                              aria-label={t("field.targetUseRoundFilter")}
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.allowClumps")}
                              labelPosition="after"
                              checked={allowClumpsTarget}
                              onChange={(_, data) => setAllowClumpsTarget(data.checked)}
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.useMinPhago")}
                              labelPosition="after"
                              checked={useMinPhago}
                              onChange={(_, data) => setUseMinPhago(data.checked)}
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.usePixelCount")}
                              labelPosition="after"
                              checked={usePixelCount}
                              onChange={(_, data) => setUsePixelCount(data.checked)}
                            />
                          </div>
                          <Field label={t("field.strictMode")} size="small">
                            <RadioGroup
                              value={strictMode}
                              onChange={(_, data) => {
                                const next = String(data.value ?? "");
                                if (next === "S" || next === "N" || next === "L") {
                                  setStrictMode(next);
                                }
                              }}
                              layout="horizontal"
                              className="choice-strip choice-strip-3"
                              aria-label={t("field.strictMode")}
                            >
                              <Radio
                                value="S"
                                label={t("field.strictS")}
                              />
                              <Radio
                                value="N"
                                label={t("field.strictN")}
                              />
                              <Radio
                                value="L"
                                label={t("field.strictL")}
                              />
                            </RadioGroup>
                          </Field>
                        </div>
                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="exclusion">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("exclusion") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      {t("op.section.exclusion")}
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.exclusion")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.exclusionCore")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.exclusionEnabled")}
                              labelPosition="after"
                              checked={exclusionDraft.enabled}
                              onChange={(_, data) =>
                                setExclusionDraft((prev) => ({ ...prev, enabled: data.checked }))
                              }
                              aria-label={t("field.exclusionEnabled")}
                            />
                          </div>
                          <Field label={t("field.exclusionMode")} size="small">
                            <RadioGroup
                              value={exclusionDraft.mode}
                              onChange={(_, data) => {
                                const next = String(data.value ?? "");
                                if (next === "bright" || next === "dark") {
                                  setExclusionDraft((prev) => ({ ...prev, mode: next }));
                                }
                              }}
                              layout="horizontal"
                              className="choice-strip choice-strip-2"
                              aria-label={t("field.exclusionMode")}
                            >
                              <Radio
                                value="bright"
                                disabled={!exclusionDraft.enabled}
                                label={t("field.exclusionModeBright")}
                              />
                              <Radio
                                value="dark"
                                disabled={!exclusionDraft.enabled}
                                label={t("field.exclusionModeDark")}
                              />
                            </RadioGroup>
                          </Field>
                          <div className="settings-grid settings-grid-numeric">
                            <Field label={t("field.exclusionThreshold")} size="small">
                              <Input
                                type="number"
                                value={exclusionDraft.threshold}
                                step={0.01}
                                min={0}
                                max={1}
                                onChange={(_, data) =>
                                  setExclusionDraft((prev) => ({ ...prev, threshold: data.value }))
                                }
                                disabled={!exclusionDraft.enabled}
                              />
                            </Field>
                            <Field label={t("field.exclusionMinArea")} size="small">
                              <Input
                                type="number"
                                value={exclusionDraft.minArea}
                                step={1}
                                min={0}
                                onChange={(_, data) =>
                                  setExclusionDraft((prev) => ({ ...prev, minArea: data.value }))
                                }
                                disabled={!exclusionDraft.enabled || !exclusionDraft.sizeGate}
                              />
                            </Field>
                            <Field label={t("field.exclusionMaxArea")} size="small">
                              <Input
                                type="number"
                                value={exclusionDraft.maxArea}
                                step={1}
                                min={0}
                                onChange={(_, data) =>
                                  setExclusionDraft((prev) => ({ ...prev, maxArea: data.value }))
                                }
                                disabled={!exclusionDraft.enabled || !exclusionDraft.sizeGate}
                              />
                            </Field>
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.exclusionStrict")}
                              labelPosition="after"
                              checked={exclusionDraft.strict}
                              disabled={!exclusionDraft.enabled}
                              onChange={(_, data) => setExclusionDraft((prev) => ({ ...prev, strict: data.checked }))}
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.exclusionSizeGate")}
                              labelPosition="after"
                              checked={exclusionDraft.sizeGate}
                              disabled={!exclusionDraft.enabled}
                              onChange={(_, data) => setExclusionDraft((prev) => ({ ...prev, sizeGate: data.checked }))}
                            />
                          </div>
                        </div>
                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="fluorescence">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("fluorescence") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      {t("op.section.fluorescence")}
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.fluorescence")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.fluorescenceCore")}</div>
                          <div className="switch-action-row">
                            <Switch
                              label={t("field.fluorescenceEnabled")}
                              labelPosition="after"
                              checked={fluorescenceDraft.enabled}
                              onChange={(_, data) =>
                                setFluorescenceDraft((prev) => ({ ...prev, enabled: data.checked }))
                              }
                              aria-label={t("field.fluorescenceEnabled")}
                            />
                            <Button
                              appearance="secondary"
                              disabled={!fluorescenceDraft.enabled}
                              onClick={handleLearnFluorescenceParams}
                            >
                              {t("field.fluoLearnParams")}
                            </Button>
                          </div>
                          <div className="settings-grid">
                            <Field label={t("field.fluoPrefix")} size="small">
                              <Input
                                value={fluorescenceDraft.prefix}
                                onChange={(_, data) =>
                                  setFluorescenceDraft((prev) => ({ ...prev, prefix: data.value }))
                                }
                                disabled={!fluorescenceDraft.enabled}
                              />
                            </Field>
                            {renderRgbFieldWithPicker(
                              "targetRgb",
                              "field.fluoTargetRgb",
                              fluorescenceDraft.targetRgb,
                              !fluorescenceDraft.enabled
                            )}
                            {renderRgbFieldWithPicker(
                              "nearRgb",
                              "field.fluoNearRgb",
                              fluorescenceDraft.nearRgb,
                              !fluorescenceDraft.enabled
                            )}
                            <Field label={t("field.fluoTolerance")} size="small">
                              <Input
                                type="number"
                                value={fluorescenceDraft.tolerance}
                                step={1}
                                min={0}
                                onChange={(_, data) =>
                                  setFluorescenceDraft((prev) => ({ ...prev, tolerance: data.value }))
                                }
                                disabled={!fluorescenceDraft.enabled}
                              />
                            </Field>
                          </div>
                          <div className="tolerance-preview">
                            <div className="tolerance-preview-title">{t("field.fluoTolerancePreview")}</div>
                            <div className="tolerance-preview-rail">
                              <div
                                className="tolerance-preview-range"
                                style={{
                                  width: `${fluoTolerancePreviewModel.tolerancePct}%`
                                }}
                              />
                              <div
                                className="tolerance-preview-color target"
                                style={{
                                  left: "1px",
                                  background: fluoTargetColor ? rgbToHex(fluoTargetColor) : "#1f2a36"
                                }}
                              />
                              <div
                                className={`tolerance-preview-color near${fluoTolerancePreviewModel.nearWithinTolerance ? " is-inside" : " is-outside"}`}
                                style={{
                                  left: `${fluoTolerancePreviewModel.nearPct ?? 0}%`,
                                  background: fluoNearColor ? rgbToHex(fluoNearColor) : "#223245"
                                }}
                              />
                            </div>
                            <div className="tolerance-preview-scale">
                              <span>0</span>
                              <span>{fluoDistanceMax.toFixed(1)}</span>
                            </div>
                            <div className="inline-note">
                              {t("field.fluoTolerancePreviewStats", {
                                dist: fluoTolerancePreviewModel.nearDistance === null
                                  ? t("field.notAvailableShort")
                                  : fluoTolerancePreviewModel.nearDistance.toFixed(1),
                                tol: fluoTolerancePreviewModel.tolerance.toFixed(1)
                              })}
                            </div>
                          </div>
                        </div>

                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.fluorescenceExclusion")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.fluoExclEnabled")}
                              labelPosition="after"
                              checked={fluorescenceDraft.exclEnabled}
                              disabled={!fluorescenceDraft.enabled}
                              onChange={(_, data) =>
                                setFluorescenceDraft((prev) => ({ ...prev, exclEnabled: data.checked }))
                              }
                            />
                          </div>
                          <div className="settings-grid">
                            {renderRgbFieldWithPicker(
                              "exclRgb",
                              "field.fluoExclRgb",
                              fluorescenceDraft.exclRgb,
                              !fluorescenceDraft.enabled || !fluorescenceDraft.exclEnabled
                            )}
                            <Field label={t("field.fluoExclTolerance")} size="small">
                              <Input
                                type="number"
                                value={fluorescenceDraft.exclTolerance}
                                step={1}
                                min={0}
                                onChange={(_, data) =>
                                  setFluorescenceDraft((prev) => ({ ...prev, exclTolerance: data.value }))
                                }
                                disabled={!fluorescenceDraft.enabled || !fluorescenceDraft.exclEnabled}
                              />
                            </Field>
                          </div>
                          <div className="tolerance-preview">
                            <div className="tolerance-preview-title">{t("field.fluoExclTolerancePreview")}</div>
                            <div className="tolerance-preview-rail">
                              <div
                                className="tolerance-preview-range exclusion"
                                style={{
                                  width: `${fluoExclPreviewModel.tolerancePct}%`
                                }}
                              />
                              <div
                                className="tolerance-preview-color exclusion"
                                style={{
                                  left: "1px",
                                  background: fluoExclColor ? rgbToHex(fluoExclColor) : "#3b2b2d"
                                }}
                              />
                              <div
                                className={`tolerance-preview-color target${fluoExclPreviewModel.targetWithinTolerance ? " is-inside" : " is-outside"}`}
                                style={{
                                  left: `${fluoExclPreviewModel.targetPct ?? 0}%`,
                                  background: fluoTargetColor ? rgbToHex(fluoTargetColor) : "#1f2a36"
                                }}
                              />
                            </div>
                            <div className="tolerance-preview-scale">
                              <span>0</span>
                              <span>{fluoDistanceMax.toFixed(1)}</span>
                            </div>
                            <div className="inline-note">
                              {t("field.fluoExclTolerancePreviewStats", {
                                dist: fluoExclPreviewModel.targetDistance === null
                                  ? t("field.notAvailableShort")
                                  : fluoExclPreviewModel.targetDistance.toFixed(1),
                                tol: fluoExclPreviewModel.tolerance.toFixed(1)
                              })}
                            </div>
                          </div>
                        </div>
                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="data">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("data") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      <span className="operation-header-title-row">
                        <span className="operation-header-title-text">{t("op.section.data")}</span>
                        {operationOpenSections.includes("data") ? (
                          <Button
                                                        appearance={dataDirty ? "primary" : "secondary"}
                            className="operation-header-apply-btn"
                            onClick={(event) => {
                              event.preventDefault();
                              event.stopPropagation();
                              applyDataDraft();
                            }}
                          >
                            {t("button.apply")}
                          </Button>
                        ) : null}
                      </span>
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.data")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.dataFormat")}</div>
                          <Field label={t("field.dataFormatColumns")} size="small">
                            <Textarea
                              value={dataDraft.formatColumns}
                              resize="vertical"
                              onChange={(_, data) => setDataDraft((prev) => ({ ...prev, formatColumns: data.value }))}
                            />
                          </Field>
                          <div className="switch-line">
                            <Switch
                              label={t("field.dataGroupByTime")}
                              labelPosition="after"
                              checked={dataDraft.groupByTime}
                              disabled={!canGroupByTime}
                              onChange={(_, data) => setDataDraft((prev) => ({ ...prev, groupByTime: data.checked }))}
                              aria-label={t("field.dataGroupByTime")}
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.dataExpandPerCell")}
                              labelPosition="after"
                              checked={dataDraft.expandPerCell}
                              disabled={hasPerCellColumns}
                              onChange={(_, data) => setDataDraft((prev) => ({ ...prev, expandPerCell: data.checked }))}
                              aria-label={t("field.dataExpandPerCell")}
                            />
                          </div>
                          {!canGroupByTime ? <div className="inline-note">{t("field.dataGroupByTimeDisabledHint")}</div> : null}
                          {hasPerCellColumns ? <div className="inline-note">{t("field.dataExpandPerCellAutoHint")}</div> : null}
                          <div className="data-preview-wrap" aria-label={t("field.dataPreviewTitle")}>
                            <div className="data-preview-title">{t("field.dataPreviewTitle")}</div>
                            <div className="data-preview-scroller">
                              <div
                                className="data-preview-table"
                                style={{
                                  gridTemplateColumns: dataPreviewColWidths.map((width) => `${width}px 4px`).join(" ")
                                }}
                              >
                                {dataPreviewHeaders.map((header, index) => (
                                  <div key={`h-${header}`} className="data-preview-pair">
                                    <div className="data-preview-head-cell">
                                      {header}
                                    </div>
                                    <div
                                      className="data-preview-col-resizer"
                                      role="separator"
                                      aria-orientation="vertical"
                                      onMouseDown={(event) => {
                                        dataPreviewColStartRef.current = {
                                          x: event.clientX,
                                          widths: [...dataPreviewColWidths]
                                        };
                                        setDataPreviewColDragging(index);
                                      }}
                                    />
                                  </div>
                                ))}
                                {dataPreviewRows.map((row, rowIndex) =>
                                  row.map((cell, colIndex) => (
                                    <div key={`r-${rowIndex}-${colIndex}`} className="data-preview-pair">
                                      <div className="data-preview-cell">
                                        {cell}
                                      </div>
                                      <div className="data-preview-sep" />
                                    </div>
                                  ))
                                )}
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.dataOutput")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.autoNoiseOptimize")}
                              labelPosition="after"
                              checked={dataDraft.autoNoiseOptimize}
                              onChange={(_, data) => setDataDraft((prev) => ({ ...prev, autoNoiseOptimize: data.checked }))}
                            />
                          </div>
                        </div>

                      </div>
                    </AccordionPanel>
                  </AccordionItem>

                  <AccordionItem value="debug">
                    <AccordionHeader
                      size="small"
                      className={`operation-accordion-header${operationOpenSections.includes("debug") ? " is-sticky" : ""}`}
                      onContextMenu={openOperationHeaderMenu}
                    >
                      <span className="operation-header-title-row">
                        <span className="operation-header-title-text">{t("op.section.debug")}</span>
                        {operationOpenSections.includes("debug") ? (
                          <Button
                                                        appearance={debugDirty ? "primary" : "secondary"}
                            className="operation-header-apply-btn"
                            onClick={(event) => {
                              event.preventDefault();
                              event.stopPropagation();
                              applyDebugDraft();
                            }}
                          >
                            {t("button.apply")}
                          </Button>
                        ) : null}
                      </span>
                    </AccordionHeader>
                    <AccordionPanel>
                      <div className="box-group operation-group">
                        <div className="section-description">{t("op.desc.debug")}</div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.debugRuntime")}</div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.debugBootPause")}
                              labelPosition="after"
                              checked={debugDraft.bootManualEnterAfterReady}
                              onChange={(_, data) =>
                                setDebugDraft((prev) => ({ ...prev, bootManualEnterAfterReady: data.checked }))
                              }
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.debugRunSlow")}
                              labelPosition="after"
                              checked={debugDraft.runSimulateSlowProgress}
                              onChange={(_, data) =>
                                setDebugDraft((prev) => ({ ...prev, runSimulateSlowProgress: data.checked }))
                              }
                            />
                          </div>
                          <div className="switch-line">
                            <Switch
                              label={t("field.debugVerbose")}
                              labelPosition="after"
                              checked={debugDraft.runVerboseLogs}
                              onChange={(_, data) =>
                                setDebugDraft((prev) => ({ ...prev, runVerboseLogs: data.checked }))
                              }
                            />
                          </div>
                        </div>
                        <div className="operation-subgroup">
                          <div className="operation-subgroup-title">{t("op.group.debugProgress")}</div>
                          <div className="settings-grid settings-grid-numeric">
                            <Field label={t("field.debugRunStep")} size="small">
                              <Input
                                type="number"
                                value={debugDraft.runProgressStep}
                                min={1}
                                step={1}
                                disabled={!debugDraft.runSimulateSlowProgress}
                                onChange={(_, data) =>
                                  setDebugDraft((prev) => ({ ...prev, runProgressStep: data.value }))
                                }
                              />
                            </Field>
                            <Field label={t("field.debugRunTick")} size="small">
                              <Input
                                type="number"
                                value={debugDraft.runProgressIntervalMs}
                                min={20}
                                step={10}
                                disabled={!debugDraft.runSimulateSlowProgress}
                                onChange={(_, data) =>
                                  setDebugDraft((prev) => ({ ...prev, runProgressIntervalMs: data.value }))
                                }
                              />
                            </Field>
                          </div>
                        </div>
                      </div>
                    </AccordionPanel>
                  </AccordionItem>
                </Accordion>
              </div>

              <div className={`settings-toolbar${settingsToolbarCompact ? " is-compact" : ""}`} ref={settingsToolbarRef}>
                {settingsToolbarCompact ? (
                  <Menu>
                    <MenuTrigger disableButtonEnhancement>
                      <Button appearance="secondary" icon={<MoreHorizontal24Regular />} aria-label={t("button.moreActions")} />
                    </MenuTrigger>
                    <MenuPopover>
                      <MenuList>
                        <MenuItem onClick={() => void loadWorkbenchConfig()}>{t("button.loadConfig")}</MenuItem>
                        <MenuItem onClick={saveWorkbenchConfig}>{t("button.saveConfig")}</MenuItem>
                      </MenuList>
                    </MenuPopover>
                  </Menu>
                ) : (
                  <>
                    <Button
                      appearance="secondary"
                      onClick={() => void loadWorkbenchConfig()}
                      data-help={t("help.loadConfig")}
                      style={{ minWidth: configButtonWidth }}
                    >
                      {t("button.loadConfig")}
                    </Button>
                    <Button
                      appearance="secondary"
                      onClick={saveWorkbenchConfig}
                      data-help={t("help.saveConfig")}
                      style={{ minWidth: configButtonWidth }}
                    >
                      {t("button.saveConfig")}
                    </Button>
                  </>
                )}
                <div className="operation-progress-slot">
                  {isRunning ? (
                    <div className="operation-progress-wrap">
                      <ProgressBar value={runProgress / 100} />
                      <span className="operation-progress-text">{t("status.runningProgress", { progress: runProgress })}</span>
                    </div>
                  ) : (
                    <span className="operation-progress-idle">{t("status.progressIdle")}</span>
                  )}
                </div>
                <Button appearance="primary" icon={<Play24Regular />} onClick={handleRun} data-help={t("help.runButton")} disabled={isRunning}>
                  {isRunning ? t("button.running") : t("button.run")}
                </Button>
              </div>
            </div>
          </section>

          <div
            className="resizer"
            role="separator"
            aria-orientation="vertical"
            onMouseDown={(e) => beginDrag("center", e.clientX)}
            onDoubleClick={() => {
              if (logCollapsed) {
                forceExpandPane("logs");
              } else {
                collapseLog();
              }
            }}
            data-help={t("help.resizerCenter")}
          />

          <section
            className={`pane pane-logs ${activePanel === "logs" ? "is-active" : ""} ${logCollapsed ? "is-collapsed" : ""}`}
            data-pane-tone="logs"
            onMouseEnter={() => setActivePanel("logs")}
            onFocus={() => setActivePanel("logs")}
            data-help={t("help.logArea")}
          >
            <div
              className="pane-header"
              onDoubleClick={() => {
                if (logCollapsed) {
                  forceExpandPane("logs");
                  setStatus("status.logPanelRestored");
                } else {
                  collapseLog();
                  setStatus("status.logPanelCollapsed");
                }
              }}
              data-help={logCollapsed ? t("help.logHeaderRestore") : t("help.logHeaderCollapse")}
            >
              <div className="pane-header-title-switch">
                <span className="pane-header-title-h">{t("panel.logs")}</span>
                <span className="pane-header-title-v" aria-hidden>
                  {t("panel.logs")}
                </span>
              </div>
            </div>

            <div className="pane-body pane-body-log">
              <div className="button-row">
                <Button appearance="primary" onClick={() => setLogs([])} data-help={t("help.clearLogs")}>
                  {t("button.clearLogs")}
                </Button>
              </div>
              <Textarea className="log-body mono" ref={logBodyRef} value={logText} readOnly resize="none" />
            </div>
          </section>
        </div>
      </main>

      {!bootReady ? (
        <div className="boot-overlay">
          <div className="startup-screen">
            <div className="startup-card">
              <div className="startup-icon-wrap" aria-hidden>
                {windowIconDataUrl ? (
                  <img src={windowIconDataUrl} alt="" className="startup-icon" draggable={false} />
                ) : (
                  <Code24Regular />
                )}
              </div>
              <div className="startup-title">{t("main.menu.helpAppName")}</div>
              <div className="startup-row">
                <Spinner size="tiny" />
                <span>{t("startup.loadingLabel")}</span>
              </div>
              {debugFlags.bootManualEnterAfterReady && bootCompleted ? (
                <div className="startup-actions">
                  <Button
                    appearance="primary"
                    size="small"
                    onClick={() => {
                      setBootReady(true);
                    }}
                  >
                    {t("startup.enterWorkbench")}
                  </Button>
                </div>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}

      {operationHeaderMenu.open ? (
        <div className="text-menu-anchor" style={{ left: `${operationHeaderMenu.x}px`, top: `${operationHeaderMenu.y}px` }}>
          <Menu
            open
            onOpenChange={(_, data) => {
              if (!data.open) closeOperationHeaderMenu();
            }}
          >
            <MenuTrigger disableButtonEnhancement>
              <button type="button" className="text-menu-trigger" />
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem onClick={expandAllOperationSections}>{t("menu.operation.expandAll")}</MenuItem>
                <MenuItem onClick={collapseAllOperationSections}>{t("menu.operation.collapseAll")}</MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
        </div>
      ) : null}

      {textMenu.open ? (
        <div className="text-menu-anchor" style={{ left: `${textMenu.x}px`, top: `${textMenu.y}px` }}>
          <Menu
            open
            onOpenChange={(_, data) => {
              if (!data.open) closeTextMenu();
            }}
          >
            <MenuTrigger disableButtonEnhancement>
              <button type="button" className="text-menu-trigger" />
            </MenuTrigger>
            <MenuPopover>
              <MenuList>
                <MenuItem
                  disabled={!!textMenu.target?.readOnly}
                  onClick={() => {
                    void applyTextMenuAction("undo");
                  }}
                >
                  {t("menu.text.undo")}
                </MenuItem>
                <MenuItem
                  disabled={!!textMenu.target?.readOnly}
                  onClick={() => {
                    void applyTextMenuAction("redo");
                  }}
                >
                  {t("menu.text.redo")}
                </MenuItem>
                <MenuDivider />
                <MenuItem
                  disabled={!!textMenu.target?.readOnly}
                  onClick={() => {
                    void applyTextMenuAction("cut");
                  }}
                >
                  {t("menu.text.cut")}
                </MenuItem>
                <MenuItem
                  onClick={() => {
                    void applyTextMenuAction("copy");
                  }}
                >
                  {t("menu.text.copy")}
                </MenuItem>
                <MenuItem
                  disabled={!!textMenu.target?.readOnly}
                  onClick={() => {
                    void applyTextMenuAction("paste");
                  }}
                >
                  {t("menu.text.paste")}
                </MenuItem>
                <MenuItem
                  onClick={() => {
                    void applyTextMenuAction("selectAll");
                  }}
                >
                  {t("menu.text.selectAll")}
                </MenuItem>
              </MenuList>
            </MenuPopover>
          </Menu>
        </div>
      ) : null}

      {bootReady ? (
      <footer className="status-strip" data-help={t("help.statusStrip")}>
        {bottomMessage || t("help.default")}
      </footer>
      ) : null}
    </div>
  );
}





