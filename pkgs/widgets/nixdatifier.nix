# Source: https://github.com/Muddyblack/kde-nixdatifier
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kde-nixdatifier";
  version = "1.0.2";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-nixdatifier";
    rev = "refs/tags/v${version}";
    hash = "sha256-dRhdbkkL8HvFz+zJGwnRgxfqSrqsgXAvK/R0cyans/E=";
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
