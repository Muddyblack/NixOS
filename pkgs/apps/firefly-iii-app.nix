# Source: https://www.firefly-iii.org
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  firefly-iii,
  systemd,
  copyDesktopItems,
  makeDesktopItem,
  writeText,
}: let
  # The service stack is on demand (modules/nixos/features/firefly-iii.nix), so
  # the window has to start it and wait for the port instead of loading straight
  # into a refused connection. Starting nginx pulls the PHP-FPM pool and the
  # setup unit with it; polkit lets wheel do that without a password prompt.
  mainJs = writeText "main.js" ''
    const { app, BrowserWindow, session, shell } = require('electron');
    const { spawn } = require('child_process');
    const http = require('http');

    const SYSTEMCTL = process.env.FIREFLY_SYSTEMCTL;
    const TARGET = 'http://localhost:8083';

    app.setName('Firefly III');
    app.setDesktopName('firefly-iii.desktop');

    let mainWindow;

    function notice(text) {
      mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(
        '<body style="background:#1f2937;color:#e5e7eb;margin:0;height:100vh;' +
        'display:flex;align-items:center;justify-content:center;text-align:center;' +
        'font:15px/1.6 system-ui,sans-serif"><div>' + text + '</div></body>'));
    }

    function probe(triesLeft) {
      const req = http.get(TARGET, (res) => {
        res.resume();
        if (res.statusCode < 500) mainWindow.loadURL(TARGET);
        else again(triesLeft);
      });
      req.on('error', () => again(triesLeft));
      req.setTimeout(2000, () => req.destroy());
    }

    function again(triesLeft) {
      if (triesLeft <= 0) {
        notice('Firefly III kam nicht hoch.<br><br>' +
               'systemctl status nginx phpfpm-firefly-iii');
        return;
      }
      setTimeout(() => probe(triesLeft - 1), 500);
    }

    function createWindow() {
      session.fromPartition('persist:firefly-iii');

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

      mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
      });

      notice('Firefly III wird gestartet...');

      const proc = spawn(SYSTEMCTL, ['--system', 'start', 'nginx.service']);
      let err = "";
      proc.stderr.on('data', (d) => { err += d.toString(); });
      proc.on('error', (e) => notice('systemctl liess sich nicht starten: ' + e.message));
      proc.on('close', (code) => {
        if (code !== 0) notice('systemctl start nginx schlug fehl:<br><br>' + err.trim());
        else probe(60);
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
        --set FIREFLY_SYSTEMCTL "${systemd}/bin/systemctl" \
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
