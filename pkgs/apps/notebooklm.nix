# Source: https://notebooklm.google.com
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/notebooklm-icon.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('NotebookLM');
    app.setDesktopName('notebooklm.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:notebooklm');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        backgroundColor: '#0f172a',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:notebooklm',
          sandbox: true
        }
      });

      mainWindow.loadURL('https://notebooklm.google.com');

      mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        require('electron').shell.openExternal(url);
        return { action: 'deny' };
      });
    }

    app.whenReady().then(createWindow);

    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') app.quit();
    });
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "notebooklm";
    version = "2024.11";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "notebooklm";
        desktopName = "NotebookLM";
        genericName = "AI Research Notebook";
        comment = "NotebookLM (Native Electron)";
        exec = "notebooklm";
        icon = "notebooklm";
        categories = ["Office" "Utility" "Education"];
        startupWMClass = "notebooklm";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/notebooklm
      cp ${mainJs} $out/lib/notebooklm/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/notebooklm \
        --add-flags "$out/lib/notebooklm/main.js" \
        --add-flags "--class=notebooklm" \
        --add-flags "--name=notebooklm" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "NotebookLM" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/notebooklm.png

      runHook postInstall
    '';

    meta = {
      description = "NotebookLM – Native Electron Wrapper";
      homepage = "https://notebooklm.google.com";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "notebooklm";
    };
  }
