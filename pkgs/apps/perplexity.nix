# Source: https://www.perplexity.ai
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  icon = ../../assets/icons/perplexity.png;

  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session } = require('electron');

    app.setName('Perplexity');
    app.setDesktopName('perplexity.desktop');

    let mainWindow;

    function createWindow() {
      const part = session.fromPartition('persist:perplexity');

      mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        backgroundColor: '#0f0f0f',
        autoHideMenuBar: true,
        webPreferences: {
          nodeIntegration: false,
          contextIsolation: true,
          partition: 'persist:perplexity',
          sandbox: true
        }
      });

      mainWindow.loadURL('https://www.perplexity.ai');

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
    pname = "perplexity";
    version = "2024.11";

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [makeWrapper copyDesktopItems];

    desktopItems = [
      (makeDesktopItem {
        name = "perplexity";
        desktopName = "Perplexity";
        genericName = "AI Search Engine";
        comment = "Perplexity AI (Native Electron)";
        exec = "perplexity";
        icon = "perplexity";
        categories = ["Network" "Utility"];
        startupWMClass = "perplexity";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/perplexity
      cp ${mainJs} $out/lib/perplexity/main.js

      mkdir -p $out/bin
      makeWrapper ${electron}/bin/electron $out/bin/perplexity \
        --add-flags "$out/lib/perplexity/main.js" \
        --add-flags "--class=perplexity" \
        --add-flags "--name=perplexity" \
        --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
        --set-default ELECTRON_APP_NAME "Perplexity" \
        --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon} $out/share/icons/hicolor/512x512/apps/perplexity.png

      runHook postInstall
    '';

    meta = {
      description = "Perplexity AI – Native Electron Wrapper";
      homepage = "https://www.perplexity.ai";
      platforms = lib.platforms.linux;
      license = lib.licenses.unfree;
      mainProgram = "perplexity";
    };
  }
