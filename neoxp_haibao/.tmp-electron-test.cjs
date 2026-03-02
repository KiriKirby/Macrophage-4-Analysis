const e = require('electron');
console.log('electronType', typeof e, Array.isArray(e), typeof e.app, !!e.app?.commandLine);
if (e.app) {
  e.app.whenReady().then(() => { console.log('ready'); e.app.quit(); });
}
