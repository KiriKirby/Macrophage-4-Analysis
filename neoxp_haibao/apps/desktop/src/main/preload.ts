import { contextBridge, ipcRenderer } from "electron";
import type { FilePreset } from "@neoxp/contracts";

interface ParseSamplePayload {
  preset: FilePreset;
  baseName: string;
}

interface WorkspaceScanPayload {
  rootPath: string;
  preset: FilePreset;
  fluoPrefix?: string;
  fluoEnabled?: boolean;
  roiSuffix?: string;
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

contextBridge.exposeInMainWorld("electronAPI", {
  getAppVersion: (): Promise<string> => ipcRenderer.invoke("app:getVersion"),
  getWindowIconDataUrl: (): Promise<string> => ipcRenderer.invoke("app:getWindowIconDataUrl"),
  getDefaultPreviewPlaceholderDataUrl: (): Promise<string> =>
    ipcRenderer.invoke("app:getDefaultPreviewPlaceholderDataUrl"),
  minimizeWindow: (): Promise<{ ok: boolean }> => ipcRenderer.invoke("window:minimize"),
  toggleMaximizeWindow: (): Promise<{ ok: boolean; maximized: boolean }> =>
    ipcRenderer.invoke("window:toggleMaximize"),
  getWindowMaximized: (): Promise<{ ok: boolean; maximized: boolean }> =>
    ipcRenderer.invoke("window:getMaximized"),
  onWindowMaximizedChanged: (
    handler: (payload: { maximized: boolean }) => void
  ): (() => void) => {
    const listener = (_event: unknown, payload: { maximized: boolean }): void => {
      handler(payload);
    };
    ipcRenderer.on("window:maximized-changed", listener);
    return () => {
      ipcRenderer.removeListener("window:maximized-changed", listener);
    };
  },
  closeWindow: (): Promise<{ ok: boolean }> => ipcRenderer.invoke("window:close"),
  selectFolder: (): Promise<string> => ipcRenderer.invoke("dialog:selectFolder"),
  parseSampleName: (payload: ParseSamplePayload): Promise<{
    pn: string;
    fStr: string;
    fNum: number;
    ok: boolean;
    detail: string;
  }> => ipcRenderer.invoke("parser:parseSampleName", payload),
  scanWorkspace: (payload: WorkspaceScanPayload): Promise<WorkspaceScanResult> =>
    ipcRenderer.invoke("files:scanWorkspace", payload),
  readImageDataUrl: (payload: { filePath: string }): Promise<{ ok: boolean; dataUrl: string; error: string }> =>
    ipcRenderer.invoke("files:readImageDataUrl", payload),
  openExternalFile: (payload: { filePath: string }): Promise<{ ok: boolean; error: string }> =>
    ipcRenderer.invoke("files:openExternal", payload)
});


