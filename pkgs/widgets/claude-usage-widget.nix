{stdenvNoCC}:
stdenvNoCC.mkDerivation {
  pname = "claude-usage-widget";
  version = "1.0.0";

  src = ./claude-usage-widget;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.muddyblack.claudeusage
    cp metadata.json $out/share/plasma/plasmoids/org.muddyblack.claudeusage/
    cp -r contents    $out/share/plasma/plasmoids/org.muddyblack.claudeusage/

    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp contents/icons/org.muddyblack.claudeusage.svg $out/share/icons/hicolor/scalable/apps/
    runHook postInstall
  '';

  meta.description = "Minimal Claude Code usage widget for KDE Plasma";
}
