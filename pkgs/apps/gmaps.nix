# Source: https://maps.google.com
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/gmaps.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('Google Maps');
    app.setDesktopName('gmaps.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:gmaps');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        backgroundColor: '#1a1a1a',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:gmaps',
          sandbox: true
        }
      });

      mainWindow.loadURL('https://www.google.com/maps');

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
    pname = "gmaps";
    version = "2024.11";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "gmaps";
        desktopName = "Google Maps";
        genericName = "Map & Navigation";
        comment = "Google Maps (Native Electron)";
        exec = "gmaps";
        icon = "gmaps";
        categories = ["Network" "Utility"];
        startupWMClass = "gmaps";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/gmaps
      cp ${mainJs} $out/lib/gmaps/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/gmaps \
        --add-flags "$out/lib/gmaps/main.js" \
        --add-flags "--class=gmaps" \
        --add-flags "--name=gmaps" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "Google Maps" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/gmaps.png

      runHook postInstall
    '';

    meta = {
      description = "Google Maps – Native Electron Wrapper";
      homepage = "https://maps.google.com";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "gmaps";
    };
  }
