# Source: https://github.com/Muddyblack/kde-nixdatifier
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kde-nixdatifier";
  version = "0.0.2-beta";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-nixdatifier";
    rev = "67cb88ea312c354d80d0b8a4ec6de95da8a9abdc";
    hash = "sha256-+xen5m1Q9K2pUPl/cd5x62RJLmGaO8MBvg0ndUjJYaE=";
  };

  dontConfigure = true;
  dontBuild = true;

  pluginId = "org.muddyblack.nixosGenerationExplorer";

  installPhase = ''
    runHook preInstall
    plasmoid="$out/share/plasma/plasmoids/$pluginId"
    mkdir -p "$plasmoid"
    cp -r package/. "$plasmoid/"
    mkdir -p "$out/share/icons/hicolor/256x256/apps"
    cp package/icon.png "$out/share/icons/hicolor/256x256/apps/$pluginId.png"
    runHook postInstall
  '';

  meta.description = "KDE Plasma 6 widget for NixOS generations, package diffs, flake updates, and secrets";
}
