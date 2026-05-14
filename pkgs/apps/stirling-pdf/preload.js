const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("api", {
  onHint:   (cb) => ipcRenderer.on("hint",   (_, m) => cb(m)),
  onStatus: (cb) => ipcRenderer.on("status", (_, m) => cb(m)),
  onOutput: (cb) => ipcRenderer.on("output", (_, m) => cb(m)),
  onError:  (cb) => ipcRenderer.on("error",  (_, m) => cb(m)),
  onDone:   (cb) => ipcRenderer.on("done",   ()      => cb()),
});
