# Source: https://github.com/Stirling-Tools/Stirling-PDF
{
  lib,
  stdenvNoCC,
  makeWrapper,
  electron,
  copyDesktopItems,
  makeDesktopItem,
  systemd,
}:
stdenvNoCC.mkDerivation {
  pname = "stirling-pdf-ui";
  version = "2024.11";

  src = ./stirling-pdf;

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [makeWrapper copyDesktopItems];

  desktopItems = [
    (makeDesktopItem {
      name = "stirling-pdf-ui";
      desktopName = "Stirling-PDF";
      genericName = "PDF Tools";
      comment = "Local PDF manipulation tools (Electron)";
      exec = "stirling-pdf-ui";
      icon = "stirlingpdf";
      categories = ["Office" "Utility"];
      startupWMClass = "stirling-pdf-ui";
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/stirlingpdf
    cp main.js preload.js index.html $out/lib/stirlingpdf/
    cp ${../../assets/icons/stirlingpdf.png} $out/lib/stirlingpdf/icon.png

    mkdir -p $out/bin
    makeWrapper ${electron}/bin/electron $out/bin/stirling-pdf-ui \
      --add-flags "$out/lib/stirlingpdf/main.js" \
      --add-flags "--class=stirling-pdf-ui" \
      --add-flags "--name=stirling-pdf-ui" \
      --set STIRLING_SYSTEMCTL  "${systemd}/bin/systemctl" \
      --set STIRLING_JOURNALCTL "${systemd}/bin/journalctl" \
      --set-default ELECTRON_FORCE_IS_PACKAGED "true" \
      --set-default ELECTRON_APP_NAME "Stirling-PDF" \
      --set-default ELECTRON_OZONE_PLATFORM_HINT "auto"

    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp ${../../assets/icons/stirlingpdf.png} $out/share/icons/hicolor/512x512/apps/stirlingpdf.png

    runHook postInstall
  '';

  meta = {
    description = "Stirling-PDF — Electron wrapper with live podman pull output";
    homepage = "http://localhost:8080";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
    mainProgram = "stirling-pdf-ui";
  };
}
