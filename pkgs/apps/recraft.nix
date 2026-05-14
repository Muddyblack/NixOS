# Source: https://www.recraft.ai
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/recraft.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('Recraft');
    app.setDesktopName('recraft.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:recraft');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        backgroundColor: '#0f0f0f',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:recraft',
          sandbox: true
        }
      });

      mainWindow.loadURL('https://www.recraft.ai/app');

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
    pname = "recraft";
    version = "2026.3";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "recraft";
        desktopName = "Recraft";
        genericName = "AI Image Generator";
        comment = "Recraft AI (Native Electron)";
        exec = "recraft";
        icon = "recraft";
        categories = ["Graphics" "2DGraphics"];
        startupWMClass = "recraft";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/recraft
      cp ${mainJs} $out/lib/recraft/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/recraft \
        --add-flags "$out/lib/recraft/main.js" \
        --add-flags "--class=recraft" \
        --add-flags "--name=recraft" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "Recraft" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/recraft.png

      runHook postInstall
    '';

    meta = {
      description = "Recraft AI – Native Electron Wrapper";
      homepage = "https://www.recraft.ai";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "recraft";
    };
  }
