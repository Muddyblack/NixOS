const { app, BrowserWindow, shell, ipcMain } = require("electron");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

app.setName("Stirling-PDF");
app.setDesktopName("stirling-pdf-ui.desktop");

const TARGET     = "http://localhost:8080";
const SERVICE    = "podman-stirling-pdf";
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

function stopJournal() {
  if (journal && !journal.killed) journal.kill();
  journal = null;
}

function startService() {
  send("hint", "Starting Stirling-PDF — first run downloads ~2 GB…");
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
  }

  check();
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
