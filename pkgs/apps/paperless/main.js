const { app, BrowserWindow, shell, ipcMain } = require("electron");
const http = require("http");
const path = require("path");
const { spawn } = require("child_process");

app.setName("Paperless-ngx");
app.setDesktopName("paperless-ngx-ui.desktop");

const TARGET     = "http://localhost:28981";
// All four are started together: the web UI alone renders, but documents
// dropped into the consume dir would sit there untouched without the
// consumer, and scheduled/queued tasks would never run.
const SERVICES   = [
  "paperless-web",
  "paperless-consumer",
  "paperless-scheduler",
  "paperless-task-queue",
];
const SYSTEMCTL  = process.env.PAPERLESS_SYSTEMCTL;
const JOURNALCTL = process.env.PAPERLESS_JOURNALCTL;

let mainWindow;
let journal;

function send(channel, msg) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, msg);
  }
}

function followJournal() {
  if (!JOURNALCTL || journal) return;
  const args = ["--system", "-f", "-n", "0", "-o", "cat"];
  for (const unit of SERVICES) args.push("-u", unit);
  journal = spawn(JOURNALCTL, args);
  journal.stdout.on("data", (d) => send("output", d.toString()));
  journal.stderr.on("data", (d) => send("output", d.toString()));
  journal.on("error", () => {});
}

function stopJournal() {
  if (journal && !journal.killed) journal.kill();
  journal = null;
}

function startServices() {
  send("hint", "Starting Paperless-ngx — first run migrates the database…");
  send("status", "$ systemctl --system start " + SERVICES.join(" "));
  followJournal();

  const proc = spawn(SYSTEMCTL, ["--system", "start"].concat(SERVICES));
  let err = "";
  proc.stderr.on("data", (d) => { err += d.toString(); });
  proc.on("error", (e) => { stopJournal(); send("error", "Failed to spawn systemctl: " + e.message); });
  proc.on("close", (code) => {
    if (code !== 0) {
      stopJournal();
      send("error", err.trim() || ("systemctl exited with code " + code));
      return;
    }
    send("status", "Units started — waiting for UI…");
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
    backgroundColor: "#0a0f0a",
    icon: path.join(__dirname, "icon.png"),
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false,
      preload: path.join(__dirname, "preload.js"),
      partition: "persist:paperless",
    },
  });

  mainWindow.webContents.setWindowOpenHandler((ev) => {
    shell.openExternal(ev.url);
    return { action: "deny" };
  });

  mainWindow.loadFile(path.join(__dirname, "index.html"));

  ipcMain.once("renderer-ready", () => startServices());
}

app.whenReady().then(createWindow);
app.on("window-all-closed", () => {
  stopJournal();
  if (process.platform !== "darwin") app.quit();
});
