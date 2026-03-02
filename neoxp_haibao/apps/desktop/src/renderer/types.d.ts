import type { FilePreset } from "@neoxp/contracts";

export interface WorkspacePair {
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

export interface WorkspaceScanResult {
  rootPath: string;
  totalImages: number;
  totalPairs: number;
  pairs: WorkspacePair[];
}

declare global {
  interface Window {
    electronAPI: {
      getAppVersion: () => Promise<string>;
      getWindowIconDataUrl: () => Promise<string>;
      getDefaultPreviewPlaceholderDataUrl: () => Promise<string>;
      minimizeWindow: () => Promise<{ ok: boolean }>;
      toggleMaximizeWindow: () => Promise<{ ok: boolean; maximized: boolean }>;
      getWindowMaximized: () => Promise<{ ok: boolean; maximized: boolean }>;
      onWindowMaximizedChanged: (handler: (payload: { maximized: boolean }) => void) => () => void;
      closeWindow: () => Promise<{ ok: boolean }>;
      selectFolder: () => Promise<string>;
      parseSampleName: (payload: {
        preset: FilePreset;
        baseName: string;
      }) => Promise<{
        pn: string;
        fStr: string;
        fNum: number;
        ok: boolean;
        detail: string;
      }>;
      scanWorkspace: (payload: {
        rootPath: string;
        preset: FilePreset;
        fluoPrefix?: string;
        fluoEnabled?: boolean;
        roiSuffix?: string;
      }) => Promise<WorkspaceScanResult>;
      readImageDataUrl: (payload: { filePath: string }) => Promise<{
        ok: boolean;
        dataUrl: string;
        error: string;
      }>;
      openExternalFile: (payload: { filePath: string }) => Promise<{
        ok: boolean;
        error: string;
      }>;
    };
  }
}

export {};


