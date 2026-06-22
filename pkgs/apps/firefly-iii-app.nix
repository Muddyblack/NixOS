# Source: https://www.firefly-iii.org
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  firefly-iii,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session, shell } = require('electron');

    app.setName('Firefly III');
    app.setDesktopName('firefly-iii.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:firefly-iii');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 1000,
        backgroundColor: '#1f2937',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:firefly-iii',
          sandbox: true
        }
      });

      mainWindow.loadURL('http://localhost:8083');

      mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
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
    pname = "firefly-iii-app";
    version = "1.0.0";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "firefly-iii";
        desktopName = "Firefly III";
        genericName = "Personal Finance Manager";
        comment = "Track spending, budgets, and accounts";
        exec = "firefly-iii";
        icon = "firefly-iii";
        categories = ["Office" "Finance"];
        keywords = [
          "finance"
          "money"
          "budget"
          "expenses"
          "accounting"
          "banking"
          "spending"
          "firefly"
        ];
        startupWMClass = "firefly-iii";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/firefly-iii
      cp ${mainJs} $out/lib/firefly-iii/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/firefly-iii \
        --add-flags "$out/lib/firefly-iii/main.js" \
        --add-flags "--class=firefly-iii" \
        --add-flags "--name=firefly-iii" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "Firefly III" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/scalable/apps
      cp ${firefly-iii}/public/maskable-icon.svg $out/share/icons/hicolor/scalable/apps/firefly-iii.svg

      runHook postInstall
    '';

    meta = {
      description = "Firefly III desktop wrapper";
      homepage = "https://www.firefly-iii.org";
      platforms = lib.platforms.linux;
      license = lib.licenses.agpl3Only;
      mainProgram = "firefly-iii";
    };
  }
