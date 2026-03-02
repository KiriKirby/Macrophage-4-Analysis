# apps/desktop

Electron + React desktop shell.

## Local run

From repository root:

1. `cd neoxp_haibao`
2. `npm install`
3. `npm run dev`

If Electron is forced into Node mode in your shell and crashes with `app.whenReady` errors:

1. PowerShell: `Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue`
2. cmd.exe: `set ELECTRON_RUN_AS_NODE=`
3. Then run `npm run dev` again.

## Build

1. `cd neoxp_haibao`
2. `npm run build`
3. `npm run preview --workspace=@neoxp/desktop`
