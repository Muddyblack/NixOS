# Source: https://github.com/paperless-ngx/paperless-ngx
#
# Desktop front-end for the on-demand Paperless-ngx stack in
# modules/nixos/features/paperless.nix — same shape as stirling-pdf.nix: the
# window opens on a splash that starts the units and streams their journal,
# then swaps itself for the web UI once it answers.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  paperless-ngx,
  systemd,
}:
stdenvNoCC.mkDerivation {
  pname = "paperless-ngx-ui";
  version = "1.0.0";

  src = ./paperless;

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [makeWrapper copyDesktopItems];

  desktopItems = [
    (makeDesktopItem {
      name = "paperless-ngx-ui";
      desktopName = "Paperless-ngx";
      genericName = "Document Archive";
      comment = "OCR'd, full-text searchable document archive";
      exec = "paperless-ngx-ui";
      icon = "paperless-ngx";
      categories = ["Office" "Utility"];
      keywords = [
        "documents"
        "scan"
        "ocr"
        "archive"
        "paperless"
        "dms"
      ];
      startupWMClass = "paperless-ngx-ui";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/paperless-ngx
    cp main.js preload.js index.html $out/lib/paperless-ngx/

    mkdir -p $out/bin
    makeWrapper ${electron}/bin/electron $out/bin/paperless-ngx-ui \
      --add-flags "$out/lib/paperless-ngx/main.js" \
      --add-flags "--class=paperless-ngx-ui" \
      --add-flags "--name=paperless-ngx-ui" \
      --set PAPERLESS_SYSTEMCTL  "${systemd}/bin/systemctl" \
      --set PAPERLESS_JOURNALCTL "${systemd}/bin/journalctl" \
      --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
      --set-default ELECTRON_APP_NAME "Paperless-ngx" \
      --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp ${paperless-ngx.frontend}/lib/paperless-ui/frontend/en-US/assets/logo-notext.svg \
      $out/share/icons/hicolor/scalable/apps/paperless-ngx.svg

    runHook postInstall
  '';

  meta = {
    description = "Paperless-ngx — Electron wrapper that starts the on-demand units";
    homepage = "http://localhost:28981";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl3Only;
    mainProgram = "paperless-ngx-ui";
  };
}
