# Source: https://github.com/HimDek/Utterly-Round-Plasma-Style
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "utterly-round-plasma-style";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "HimDek";
    repo = "Utterly-Round-Plasma-Style";
    rev = "master";
    sha256 = "160hyj5wadmvn7bg4nlzfi4i4vw6vhn8pqlm1qybg14dqlmmh4is";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/aurorae/themes
    cp -r aurorae/dark/translucent $out/share/aurorae/themes/Utterly-Round-Dark
    cp -r aurorae/dark/solid $out/share/aurorae/themes/Utterly-Round-Dark-Solid
    cp -r aurorae/light/translucent $out/share/aurorae/themes/Utterly-Round-Light
    cp -r aurorae/light/solid $out/share/aurorae/themes/Utterly-Round-Light-Solid
    runHook postInstall
  '';

  meta = {
    description = "Utterly Round Aurorae window decorations for KDE Plasma 6";
    homepage = "https://github.com/HimDek/Utterly-Round-Plasma-Style";
    license = [{spdxId = "GPL-2.0";}];
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
