# Source: https://web.whatsapp.com
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/whatsapp.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('WhatsApp');
    app.setDesktopName('whatsapp.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:whatsapp');

      mainWindow = new BrowserWindow({
        width: 1280,
        height: 900,
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:whatsapp',
          sandbox: true
        }
      });

      mainWindow.webContents.setUserAgent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");

      mainWindow.loadURL('https://web.whatsapp.com');

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
    pname = "whatsapp";
    version = "2025.7";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "whatsapp";
        desktopName = "WhatsApp";
        genericName = "Messenger";
        comment = "WhatsApp Web (Electron)";
        exec = "whatsapp";
        icon = "whatsapp";
        categories = ["Network" "InstantMessaging" "Chat"];
        startupWMClass = "whatsapp";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/whatsapp
      cp ${mainJs} $out/lib/whatsapp/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/whatsapp \
        --add-flags "$out/lib/whatsapp/main.js" \
        --add-flags "--class=whatsapp" \
        --add-flags "--name=whatsapp" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "WhatsApp" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/whatsapp.png

      runHook postInstall
    '';

    meta = {
      description = "WhatsApp Web – Native Electron Wrapper";
      homepage = "https://web.whatsapp.com";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "whatsapp";
    };
  }
