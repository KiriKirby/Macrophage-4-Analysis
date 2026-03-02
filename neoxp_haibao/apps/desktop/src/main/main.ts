import { app, BrowserWindow, dialog, ipcMain, Menu, nativeImage, nativeTheme, shell } from "electron";
import { existsSync, promises as fs } from "node:fs";
import { extname, join, relative } from "node:path";
import { parseByPreset, parseTimeToken } from "@neoxp/parser";
import type { FilePreset } from "@neoxp/contracts";
import * as UTIF from "utif";
import { DEFAULT_LOCALE, createTranslator } from "../i18n";

const t = createTranslator(DEFAULT_LOCALE);
const IMAGE_EXTS = new Set([".tif", ".tiff", ".png", ".jpg", ".jpeg", ".bmp", ".gif"]);
const DEFAULT_FLUO_PREFIXES = ["#", "fluo_", "fluo-", "fluo ", "f_"];

interface WorkspaceScanPayload {
  rootPath: string;
  preset: FilePreset;
  fluoPrefix?: string;
  fluoEnabled?: boolean;
  roiSuffix?: string;
}

interface ImageSlot {
  path: string;
  name: string;
  hasRoi: boolean;
  roiPath: string;
  roiName: string;
}

interface PairBucket {
  id: string;
  relativeDir: string;
  project: string;
  timeLabel: string;
  timeValue: number;
  normal?: ImageSlot;
  fluo?: ImageSlot;
}

interface WorkspacePair {
  id: string;
  relativeDir: string;
  project: string;
  timeLabel: string;
  timeValue: number;
  normalPath: string;
  normalName: string;
  normalHasRoi: boolean;
  normalRoiPath: string;
  normalRoiName: string;
  fluoPath: string;
  fluoName: string;
  fluoHasRoi: boolean;
}

interface WorkspaceScanResult {
  rootPath: string;
  totalImages: number;
  totalPairs: number;
  pairs: WorkspacePair[];
}

function resolveSampleImage(): Electron.NativeImage {
  let appPath = "";
  try {
    appPath = app.getAppPath();
  } catch {
    appPath = "";
  }

  const iconCandidates = [
    join(process.cwd(), "sample.png"),
    join(process.cwd(), "..", "..", "sample.png"),
    join(__dirname, "..", "..", "..", "sample.png"),
    join(__dirname, "..", "..", "..", "..", "sample.png")
  ];
  if (appPath) {
    iconCandidates.push(join(appPath, "sample.png"));
    iconCandidates.push(join(appPath, "..", "sample.png"));
  }

  for (const candidate of iconCandidates) {
    if (!existsSync(candidate)) continue;
    const image = nativeImage.createFromPath(candidate);
    if (!image.isEmpty()) return image;
  }

  return nativeImage.createEmpty();
}

const SAMPLE_IMAGE = resolveSampleImage();
const SAMPLE_IMAGE_DATA_URL = SAMPLE_IMAGE.isEmpty() ? "" : SAMPLE_IMAGE.toDataURL();

async function createMainWindow(): Promise<BrowserWindow> {
  const options: Electron.BrowserWindowConstructorOptions = {
    width: 1080,
    height: 620,
    minWidth: 520,
    minHeight: 400,
    show: true,
    backgroundColor: "#0c0f14",
    autoHideMenuBar: true,
    frame: false,
    thickFrame: true,
    webPreferences: {
      preload: join(__dirname, "preload.cjs"),
      contextIsolation: true,
      nodeIntegration: false
    }
  };
  const window = new BrowserWindow(options);

  const devUrl = process.env.VITE_DEV_SERVER_URL;
  if (devUrl) {
    window.loadURL(devUrl).catch((error: unknown) => {
      console.error("Failed to load dev server URL.", error);
    });
    if (process.env.NEOXP_OPEN_DEVTOOLS === "1") {
      window.webContents.openDevTools({ mode: "detach" });
    }
  } else {
    const indexPath = join(__dirname, "../dist/index.html");
    window.loadFile(indexPath).catch((error: unknown) => {
      console.error("Failed to load packaged renderer.", error);
    });
  }

  const emitWindowMaximizedState = (): void => {
    if (window.isDestroyed()) return;
    window.webContents.send("window:maximized-changed", { maximized: window.isMaximized() });
  };

  window.on("maximize", emitWindowMaximizedState);
  window.on("unmaximize", emitWindowMaximizedState);
  window.on("enter-full-screen", emitWindowMaximizedState);
  window.on("leave-full-screen", emitWindowMaximizedState);
  window.once("ready-to-show", emitWindowMaximizedState);
  window.webContents.on("did-finish-load", emitWindowMaximizedState);

  return window;
}

function toPosixPath(value: string): string {
  return value.replaceAll("\\", "/");
}

function isImageFile(name: string): boolean {
  return IMAGE_EXTS.has(extname(name).toLowerCase());
}

function mimeByExt(filePath: string): string {
  const ext = extname(filePath).toLowerCase();
  if (ext === ".png") return "image/png";
  if (ext === ".jpg" || ext === ".jpeg") return "image/jpeg";
  if (ext === ".bmp") return "image/bmp";
  if (ext === ".gif") return "image/gif";
  if (ext === ".tif" || ext === ".tiff") return "image/tiff";
  return "application/octet-stream";
}

function decodeTiffToDataUrl(raw: Buffer): string {
  try {
    const ifds = UTIF.decode(raw);
    if (!ifds || ifds.length === 0) return "";
    UTIF.decodeImage(raw, ifds[0]);
    const ifd = ifds[0] as { width?: number; height?: number; t256?: number; t257?: number };
    const width = Number(ifd.width ?? ifd.t256 ?? 0);
    const height = Number(ifd.height ?? ifd.t257 ?? 0);
    if (width <= 0 || height <= 0) return "";

    const rgba = UTIF.toRGBA8(ifd as never);
    if (!rgba || rgba.length !== width * height * 4) return "";
    const image = nativeImage.createFromBitmap(Buffer.from(rgba), { width, height });
    if (image.isEmpty()) return "";
    return image.toDataURL();
  } catch {
    return "";
  }
}

function resolveTimeFromRelativeDir(relativeDir: string): { label: string; value: number } {
  if (!relativeDir) return { label: "", value: 0 };

  const segments = toPosixPath(relativeDir)
    .split("/")
    .map((segment) => segment.trim())
    .filter((segment) => segment.length > 0);

  const parentFolder = segments[segments.length - 1];
  const out = parseTimeToken(parentFolder);
  if (out.ok && out.source === "hr") {
    return { label: `${out.tStr}hr`, value: out.tNum };
  }

  return { label: "", value: 0 };
}

function buildRoiSuffixCandidates(roiSuffixRaw: string): string[] {
  const token = roiSuffixRaw.trim().toLowerCase();
  const normalized = token.length > 0 ? token : "_cells";
  const withZip = normalized.endsWith(".zip") ? normalized : `${normalized}.zip`;
  return [withZip];
}

function findRoiName(fileMap: Map<string, string>, candidates: string[], roiSuffix: string): string {
  const normalized = new Set<string>();
  const suffixes = buildRoiSuffixCandidates(roiSuffix);

  for (const candidateRaw of candidates) {
    const candidate = candidateRaw.trim();
    if (!candidate) continue;
    const lowerBase = candidate.toLowerCase();
    if (normalized.has(lowerBase)) continue;
    normalized.add(lowerBase);
    for (const suffix of suffixes) {
      const roiName = fileMap.get(`${lowerBase}${suffix.toLowerCase()}`);
      if (roiName) {
        return roiName;
      }
    }
  }
  return "";
}

function getPairKey(baseName: string, fluoPrefix: string, fluoEnabled: boolean): { pairKey: string; isFluo: boolean } {
  if (!fluoEnabled) {
    return { pairKey: baseName.trim(), isFluo: false };
  }
  const normalized = baseName.trim();
  const prefixes = [...DEFAULT_FLUO_PREFIXES];
  const customPrefix = fluoPrefix.trim();
  if (customPrefix.length > 0 && !prefixes.includes(customPrefix)) {
    prefixes.unshift(customPrefix);
  }

  const lower = normalized.toLowerCase();
  for (const prefix of prefixes) {
    const token = prefix.trim();
    if (!token) continue;
    const lowerToken = token.toLowerCase();
    if (lower.startsWith(lowerToken)) {
      const cut = normalized.slice(token.length).trim();
      if (cut.length > 0) {
        return { pairKey: cut, isFluo: true };
      }
    }
  }

  return { pairKey: normalized, isFluo: false };
}

async function scanWorkspace(payload: WorkspaceScanPayload): Promise<WorkspaceScanResult> {
  const rootPath = payload.rootPath.trim();
  if (!rootPath) {
    return { rootPath: "", totalImages: 0, totalPairs: 0, pairs: [] };
  }

  const stats = await fs.stat(rootPath);
  if (!stats.isDirectory()) {
    return { rootPath, totalImages: 0, totalPairs: 0, pairs: [] };
  }

  const map = new Map<string, PairBucket>();
  let totalImages = 0;

  const scanDir = async (absDir: string): Promise<void> => {
    const entries = await fs.readdir(absDir, { withFileTypes: true });
    const fileNameMap = new Map(
      entries
        .filter((entry) => entry.isFile())
        .map((entry) => [entry.name.toLowerCase(), entry.name] as const)
    );

    for (const entry of entries) {
      if (entry.isDirectory()) {
        await scanDir(join(absDir, entry.name));
      }
    }

    for (const entry of entries) {
      if (!entry.isFile() || !isImageFile(entry.name)) continue;

      const fullPath = join(absDir, entry.name);
      const relDir = toPosixPath(relative(rootPath, absDir));
      const ext = extname(entry.name);
      const baseName = entry.name.slice(0, entry.name.length - ext.length);
      const pairType = getPairKey(baseName, payload.fluoPrefix ?? "", payload.fluoEnabled !== false);
      const parse = parseByPreset(pairType.pairKey, payload.preset);
      const time = resolveTimeFromRelativeDir(relDir);
      const project = parse.ok && parse.pn.trim() ? parse.pn.trim() : "";
      const bucketKey = `${relDir}::${pairType.pairKey.toLowerCase()}`;
      const roiName = findRoiName(fileNameMap, [baseName, pairType.pairKey], payload.roiSuffix ?? "_cells");
      const roiPath = roiName ? join(absDir, roiName) : "";

      const slot: ImageSlot = {
        path: fullPath,
        name: entry.name,
        hasRoi: roiPath.length > 0,
        roiPath,
        roiName
      };

      let bucket = map.get(bucketKey);
      if (!bucket) {
        bucket = {
          id: bucketKey,
          relativeDir: relDir,
          project,
          timeLabel: time.label,
          timeValue: time.value
        };
        map.set(bucketKey, bucket);
      }

      if (pairType.isFluo) {
        if (!bucket.fluo) {
          bucket.fluo = slot;
        } else {
          const uniqueKey = `${bucketKey}::fluo::${slot.name.toLowerCase()}`;
          map.set(uniqueKey, {
            ...bucket,
            id: uniqueKey,
            fluo: slot
          });
        }
      } else if (!bucket.normal) {
        bucket.normal = slot;
      } else {
        const uniqueKey = `${bucketKey}::normal::${slot.name.toLowerCase()}`;
        map.set(uniqueKey, {
          ...bucket,
          id: uniqueKey,
          normal: slot
        });
      }

      totalImages += 1;
    }
  };

  await scanDir(rootPath);

  const pairs: WorkspacePair[] = [...map.values()].map((bucket) => {
    return {
      id: bucket.id,
      relativeDir: bucket.relativeDir,
      project: bucket.project,
      timeLabel: bucket.timeLabel,
      timeValue: bucket.timeValue,
      normalPath: bucket.normal?.path ?? "",
      normalName: bucket.normal?.name ?? "",
      normalHasRoi: bucket.normal?.hasRoi ?? false,
      normalRoiPath: bucket.normal?.roiPath ?? "",
      normalRoiName: bucket.normal?.roiName ?? "",
      fluoPath: bucket.fluo?.path ?? "",
      fluoName: bucket.fluo?.name ?? "",
      fluoHasRoi: bucket.normal?.hasRoi ?? false
    };
  });

  pairs.sort((a, b) => {
    if (a.timeValue !== b.timeValue) return a.timeValue - b.timeValue;

    const dirCmp = a.relativeDir.localeCompare(b.relativeDir);
    if (dirCmp !== 0) return dirCmp;

    const projectCmp = a.project.localeCompare(b.project);
    if (projectCmp !== 0) return projectCmp;

    const fileA = a.normalName || a.fluoName;
    const fileB = b.normalName || b.fluoName;
    return fileA.localeCompare(fileB);
  });

  return {
    rootPath,
    totalImages,
    totalPairs: pairs.length,
    pairs
  };
}

function registerIpcHandlers(): void {
  ipcMain.handle("app:getVersion", () => app.getVersion());
  ipcMain.handle("app:getWindowIconDataUrl", () => "");
  ipcMain.handle("app:getDefaultPreviewPlaceholderDataUrl", () => SAMPLE_IMAGE_DATA_URL);
  ipcMain.handle("window:minimize", (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win) return { ok: false };
    win.minimize();
    return { ok: true };
  });
  ipcMain.handle("window:toggleMaximize", (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win) return { ok: false, maximized: false };
    if (win.isMaximized()) {
      win.unmaximize();
    } else {
      win.maximize();
    }
    return { ok: true, maximized: win.isMaximized() };
  });
  ipcMain.handle("window:getMaximized", (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win) return { ok: false, maximized: false };
    return { ok: true, maximized: win.isMaximized() };
  });
  ipcMain.handle("window:close", (event) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (!win) return { ok: false };
    win.close();
    return { ok: true };
  });

  ipcMain.handle("dialog:selectFolder", async () => {
    const result = await dialog.showOpenDialog({
      title: t("main.dialog.selectFolderTitle"),
      properties: ["openDirectory", "createDirectory"]
    });
    if (result.canceled || result.filePaths.length === 0) {
      return "";
    }
    return result.filePaths[0];
  });

  ipcMain.handle("parser:parseSampleName", (_event, payload: { preset: FilePreset; baseName: string }) => {
    return parseByPreset(payload.baseName, payload.preset);
  });

  ipcMain.handle("files:scanWorkspace", async (_event, payload: WorkspaceScanPayload) => {
    return scanWorkspace(payload);
  });

  ipcMain.handle("files:readImageDataUrl", async (_event, payload: { filePath: string }) => {
    try {
      const filePath = payload.filePath.trim();
      if (!filePath) {
        return { ok: false, dataUrl: "", error: "empty_path" };
      }
      const ext = extname(filePath).toLowerCase();

      const decoded = nativeImage.createFromPath(filePath);
      if (!decoded.isEmpty()) {
        return { ok: true, dataUrl: decoded.toDataURL(), error: "" };
      }

      const raw = await fs.readFile(filePath);
      if (ext === ".tif" || ext === ".tiff") {
        const tiffDataUrl = decodeTiffToDataUrl(raw);
        if (tiffDataUrl) {
          return { ok: true, dataUrl: tiffDataUrl, error: "" };
        }
      }

      const mime = mimeByExt(filePath);
      const base64 = raw.toString("base64");
      return { ok: true, dataUrl: `data:${mime};base64,${base64}`, error: "" };
    } catch (error) {
      return {
        ok: false,
        dataUrl: "",
        error: error instanceof Error ? error.message : "read_failed"
      };
    }
  });

  ipcMain.handle("files:openExternal", async (_event, payload: { filePath: string }) => {
    const filePath = payload.filePath.trim();
    if (!filePath) {
      return { ok: false, error: "empty_path" };
    }

    const out = await shell.openPath(filePath);
    if (out) {
      return { ok: false, error: out };
    }
    return { ok: true, error: "" };
  });
}

app.whenReady().then(() => {
  nativeTheme.themeSource = "dark";
  Menu.setApplicationMenu(null);
  registerIpcHandlers();
  void createMainWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      void createMainWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});















