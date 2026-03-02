export interface DebugFlagSet {
  bootManualEnterAfterReady: boolean;
  runSimulateSlowProgress: boolean;
  runProgressStep: number;
  runProgressIntervalMs: number;
  runVerboseLogs: boolean;
}

const DEFAULT_DEBUG_FLAGS: Readonly<DebugFlagSet> = {
  bootManualEnterAfterReady: false,
  runSimulateSlowProgress: true,
  runProgressStep: 4,
  runProgressIntervalMs: 90,
  runVerboseLogs: false
};

const DEBUG_FLAG_PROFILES: Readonly<Record<string, Partial<DebugFlagSet>>> = {
  default: {},
  localDebug: {
    bootManualEnterAfterReady: true,
    runSimulateSlowProgress: true,
    runProgressStep: 2,
    runProgressIntervalMs: 160,
    runVerboseLogs: true
  }
};

// NOTE: default profile keeps production behavior (auto enter after boot).
const ACTIVE_DEBUG_PROFILE = "default";
const DEBUG_FLAG_STORAGE_KEY = "neoxp.desktop.debugFlags.v1";

function sanitizeStoredFlags(raw: unknown): Partial<DebugFlagSet> {
  if (!raw || typeof raw !== "object") return {};
  const input = raw as Partial<DebugFlagSet>;
  const next: Partial<DebugFlagSet> = {};

  if (typeof input.bootManualEnterAfterReady === "boolean") next.bootManualEnterAfterReady = input.bootManualEnterAfterReady;
  if (typeof input.runSimulateSlowProgress === "boolean") next.runSimulateSlowProgress = input.runSimulateSlowProgress;
  if (typeof input.runVerboseLogs === "boolean") next.runVerboseLogs = input.runVerboseLogs;
  if (typeof input.runProgressStep === "number" && Number.isFinite(input.runProgressStep) && input.runProgressStep > 0) {
    next.runProgressStep = Math.max(1, Math.round(input.runProgressStep * 100) / 100);
  }
  if (
    typeof input.runProgressIntervalMs === "number" &&
    Number.isFinite(input.runProgressIntervalMs) &&
    input.runProgressIntervalMs > 0
  ) {
    next.runProgressIntervalMs = Math.max(16, Math.round(input.runProgressIntervalMs));
  }
  return next;
}

function readStoredFlags(): Partial<DebugFlagSet> {
  if (typeof window === "undefined") return {};
  try {
    const raw = window.localStorage.getItem(DEBUG_FLAG_STORAGE_KEY);
    if (!raw) return {};
    const parsed = JSON.parse(raw) as unknown;
    return sanitizeStoredFlags(parsed);
  } catch {
    return {};
  }
}

export function persistDebugFlags(next: Partial<DebugFlagSet>): void {
  if (typeof window === "undefined") return;
  try {
    const normalized = sanitizeStoredFlags(next);
    window.localStorage.setItem(DEBUG_FLAG_STORAGE_KEY, JSON.stringify(normalized));
  } catch {
    // ignore write failures in debug storage
  }
}

export class DebugFlagCenter {
  private readonly flags: DebugFlagSet;

  constructor(profile: string) {
    const profileFlags = DEBUG_FLAG_PROFILES[profile] ?? {};
    const storedFlags = readStoredFlags();
    this.flags = {
      ...DEFAULT_DEBUG_FLAGS,
      ...profileFlags,
      ...storedFlags
    };
  }

  public get<K extends keyof DebugFlagSet>(key: K): DebugFlagSet[K] {
    return this.flags[key];
  }

  public snapshot(): Readonly<DebugFlagSet> {
    return this.flags;
  }
}

export const debugFlagCenter = new DebugFlagCenter(ACTIVE_DEBUG_PROFILE);
export const debugFlags = debugFlagCenter.snapshot();
