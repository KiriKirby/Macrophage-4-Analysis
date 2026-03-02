# Migration Architecture (Recommended)

## Product Direction

1. Electron front-end for non-linear workflow.
2. Deterministic backend pipelines with explicit phase state.
3. Dual-engine runtime during migration:
   - `fiji-adapter` for baseline validation.
   - `native-engine` for long-term ownership.

## Layered Design

1. `apps/desktop`
   - phase navigation
   - task execution controls
   - logs/errors/result preview
2. `packages/workflow`
   - phase definitions
   - transition policy
   - checkpoint and rollback model
3. `packages/contracts`
   - shared types
   - error code definitions
   - param spec key schema
4. `packages/parser`
   - filename preset parsing
   - time extraction behavior
5. `packages/engine-adapter-fiji`
   - execute compatibility pipeline
   - produce normalized output contracts
6. `packages/engine-native`
   - native compute implementation
   - parity-tested module replacement

## Migration Sequence

1. Lock parser and output layout behavior.
2. Build project-state workflow shell in Electron.
3. Integrate `fiji-adapter` so app is usable early.
4. Replace algorithm modules one by one:
   - threshold + binary ops
   - feature candidate detection
   - counting and in-cell assignment
   - fluorescence counting
5. Keep parity tests as release gates.

## Regression Policy

For each image set compare at least:

1. `TB`, `BIC`, `CWB`, `TC`
2. `TPC`, `ETPC`, `TPCSEM`
3. fluorescence paired metrics when enabled

Deviation outside accepted tolerance blocks module promotion.

