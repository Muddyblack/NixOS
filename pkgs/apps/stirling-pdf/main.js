const { app, BrowserWindow, shell, ipcMain } = require("electron");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

app.setName("Stirling-PDF");
app.setDesktopName("stirling-pdf-ui.desktop");

// Stirling-PDF and Paperless both ship a desktop build alongside the web one,
// and a frontend that sniffs "Electron/<version>" out of the user agent can
// switch to a native-bridge code path that never resolves here — the page then
// sits on its own loading spinner forever while the same URL renders fine in a
// normal browser. Presenting a plain Chrome UA keeps us on the web path.
app.userAgentFallback = app.userAgentFallback.replace(/\s?Electron\/[\d.]+/, "");

const TARGET     = "http://localhost:8080";
const SERVICE    = "stirling-pdf";
const UNITS      = [SERVICE];
const SYSTEMCTL  = process.env.STIRLING_SYSTEMCTL;
const JOURNALCTL = process.env.STIRLING_JOURNALCTL;

let mainWindow;
let journal;

function send(channel, msg) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, msg);
  }
}

function followJournal() {
  if (!JOURNALCTL || journal) return;
  journal = spawn(JOURNALCTL, ["--system", "-fu", SERVICE, "-n", "0", "-o", "cat"]);
  journal.stdout.on("data", (d) => send("output", d.toString()));
  journal.stderr.on("data", (d) => send("output", d.toString()));
  journal.on("error", () => {});
}

// `systemctl start` returns success as soon as the job is queued, and a unit
// with a restart policy stays "activating" while it crash-loops. Polling the
// unit state alongside the HTTP probe is what stops the splash from spinning
// on "Waiting for service…" forever after the service has already given up.
function unitFailed(cb) {
  const proc = spawn(SYSTEMCTL, ["--system", "is-failed"].concat(UNITS));
  let out = "";
  proc.stdout.on("data", (d) => { out += d.toString(); });
  proc.on("error", () => cb(false));
  proc.on("close", () => {
    cb(out.split("\n").some((l) => l.trim() === "failed"));
  });
}

function stopJournal() {
  if (journal && !journal.killed) journal.kill();
  journal = null;
}

function startService() {
  send("hint", "Starting Stirling-PDF — LibreOffice makes the first start slow…");
  send("status", "$ systemctl --system start " + SERVICE);
  followJournal();

  const proc = spawn(SYSTEMCTL, ["--system", "start", SERVICE]);
  let err = "";
  proc.stderr.on("data", (d) => { err += d.toString(); });
  proc.on("error", (e) => { stopJournal(); send("error", "Failed to spawn systemctl: " + e.message); });
  proc.on("close", (code) => {
    if (code !== 0) {
      stopJournal();
      send("error", err.trim() || ("systemctl exited with code " + code));
      return;
    }
    send("status", "Service started — waiting for UI…");
    waitForService(() => {
      stopJournal();
      send("done");
      mainWindow.loadURL(TARGET);
    });
  });
}

function waitForService(cb) {
  let attempts = 0;
  let done = false;

  function retry() {
    if (done) return;
    setTimeout(check, 1500);
  }

  function check() {
    if (done) return;
    attempts++;

    unitFailed((failed) => {
      if (done) return;
      if (failed) {
        done = true;
        stopJournal();
        send("error", "The service failed to start — see the log above.");
        return;
      }

      send("hint", "Waiting for service…");
      send("status", "GET " + TARGET + "  (attempt " + attempts + ")");

      const req = http.get(TARGET, (res) => {
        res.resume();
        if (done) return;
        done = true;
        req.destroy();
        cb();
      });
      req.on("error", retry);
      req.setTimeout(1000, () => { req.destroy(); retry(); });
    });
  }

  check();
}

// Renderer console, load failures and crashes go to stdout, and F12 /
// Ctrl+Shift+I opens devtools. When a wrapped web app misbehaves the evidence
// lives in the renderer process, and without this the window just sits there
// with nothing in the journal to explain it.
function attachDiagnostics(win) {
  const wc = win.webContents;

  wc.on("console-message", (...args) => {
    const e = args[0];
    if (e && typeof e === "object" && "message" in e) {
      console.log("[renderer] " + e.message + "  (" + (e.sourceId || "") + ":" + (e.lineNumber || 0) + ")");
    } else {
      console.log("[renderer] " + args[2] + "  (" + args[4] + ":" + args[3] + ")");
    }
  });
  wc.on("did-fail-load", (_e, code, desc, url) => {
    console.log("[did-fail-load] " + code + " " + desc + " " + url);
  });
  wc.on("render-process-gone", (_e, details) => {
    console.log("[render-process-gone] " + JSON.stringify(details));
  });
  wc.on("unresponsive", () => console.log("[unresponsive] renderer stopped answering"));

  wc.on("before-input-event", (event, input) => {
    const devtools =
      input.key === "F12" ||
      (input.control && input.shift && String(input.key).toLowerCase() === "i");
    if (devtools) {
      wc.toggleDevTools();
      event.preventDefault();
    }
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 1000,
    backgroundColor: "#0a0a12",
    icon: path.join(__dirname, "icon.png"),
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false,
      preload: path.join(__dirname, "preload.js"),
      partition: "persist:stirlingpdf",
    },
  });

  attachDiagnostics(mainWindow);

  mainWindow.webContents.setWindowOpenHandler((ev) => {
    shell.openExternal(ev.url);
    return { action: "deny" };
  });

  mainWindow.loadFile(path.join(__dirname, "index.html"));

  ipcMain.once("renderer-ready", () => startService());
}

app.whenReady().then(createWindow);
app.on("window-all-closed", () => {
  stopJournal();
  if (process.platform !== "darwin") app.quit();
});
