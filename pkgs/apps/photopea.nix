# Source: https://www.photopea.com
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/photopea.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('Photopea');
    app.setDesktopName('photopea.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:photopea');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 1000,
        backgroundColor: '#2e2e2e',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:photopea',
          sandbox: true
        }
      });

      mainWindow.loadURL('https://www.photopea.com');

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
    pname = "photopea";
    version = "2025.5";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "photopea";
        desktopName = "Photopea";
        genericName = "Image Editor";
        comment = "Advanced photo editor (Native Electron)";
        exec = "photopea";
        icon = "photopea";
        categories = ["Graphics" "2DGraphics" "RasterGraphics"];
        startupWMClass = "photopea";
        mimeTypes = ["image/png" "image/jpeg" "image/webp" "image/svg+xml" "image/bmp" "image/tiff" "image/gif"];
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/photopea
      cp ${mainJs} $out/lib/photopea/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/photopea \
        --add-flags "$out/lib/photopea/main.js" \
        --add-flags "--class=photopea" \
        --add-flags "--name=photopea" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "Photopea" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/photopea.png

      runHook postInstall
    '';

    meta = {
      description = "Photopea – Native Electron Wrapper";
      homepage = "https://www.photopea.com";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "photopea";
    };
  }
