# Source: https://github.com/Muddyblack/kde-nixdatifier
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kde-nixdatifier";
  version = "0.0.1-beta";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-nixdatifier";
    rev = "efc74c1ad14ee75690651dc0ce82891b5db06e7f";
    hash = "sha256-IfndSHgfzjSAlRkZpqtHLk/dlEYUhMHC6Rq2M+7dPPo=";
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
