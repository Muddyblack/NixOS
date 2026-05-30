const { app, BrowserWindow, shell, ipcMain } = require("electron");
const http = require("http");
const path = require("path");
const { spawn, spawnSync } = require("child_process");

app.setName("Stirling-PDF");
app.setDesktopName("stirling-pdf-ui.desktop");

const TARGET    = "http://localhost:8080";
const IMAGE     = "stirlingtools/stirling-pdf:latest-fat";
const SERVICE   = "podman-stirling-pdf";
const PODMAN    = process.env.STIRLING_PODMAN;
const SYSTEMCTL = process.env.STIRLING_SYSTEMCTL;

let mainWindow;

function send(channel, msg) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send(channel, msg);
  }
}

function imageExists() {
  return spawnSync(PODMAN, ["image", "exists", IMAGE]).status === 0;
}

function pullImage(cb) {
  send("hint", "Pulling image — first run downloads ~1 GB…");
  send("status", "$ podman pull " + IMAGE);

  const proc = spawn(PODMAN, ["pull", IMAGE], {
    env: Object.assign({}, process.env, { TERM: "xterm-256color" }),
  });

  proc.stdout.on("data", (d) => send("output", d.toString()));
  proc.stderr.on("data", (d) => send("output", d.toString()));

  proc.on("error", (e) => send("error", "Failed to spawn podman: " + e.message));

  proc.on("close", (code) => {
    if (code === 0) {
      send("status", "Pull complete.");
      setTimeout(cb, 300);
    } else {
      send("error", "podman pull exited with code " + code);
    }
  });
}

function startContainer(cb) {
  send("hint", "Starting container…");
  send("status", "$ systemctl --system start " + SERVICE);
  const r = spawnSync(SYSTEMCTL, ["--system", "start", SERVICE]);
  if (r.status !== 0) {
    const out = (r.stdout && r.stdout.toString().trim()) || "";
    const err = (r.stderr && r.stderr.toString().trim()) || "";
    send("error", (err || out || ("systemctl exit " + r.status)));
    return;
  }
  waitForService(cb);
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

  ipcMain.once("renderer-ready", () => {
    const proceed = () => {
      startContainer(() => {
        send("done");
        mainWindow.loadURL(TARGET);
      });
    };
    if (imageExists()) {
      send("hint", "Image already cached.");
      send("status", IMAGE + " — using local copy");
      proceed();
    } else {
      pullImage(proceed);
    }
  });
}

app.whenReady().then(createWindow);
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
