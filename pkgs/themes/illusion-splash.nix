# Source: https://github.com/dgudim/themes
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "illusion-splash";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "dgudim";
    repo = "themes";
    rev = "496cdec18fc5d89e9e9bbb93faca6d481a006b31";
    hash = "sha256-GGmsYDlalnSCrd4Mw/mCA2ghNm3wq/1LjaDdsYdKBcA=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/look-and-feel
    cp -r KDE-loginscreens/Illusion $out/share/plasma/look-and-feel/Illusion
    runHook postInstall
  '';

  meta = {
    description = "Illusion splash screen for KDE Plasma 6";
    homepage = "https://github.com/dgudim/themes";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
