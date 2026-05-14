# Source: https://github.com/ddh4r4m/Iridescent
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "iridescent-plasma-style";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "ddh4r4m";
    repo = "Iridescent";
    rev = "main";
    sha256 = "0xlpf26j3ib8jvgy31wphb1gqka70zwqvnv4w4cvxbj1jmscz68h";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/desktoptheme
    cp -r plasma/desktoptheme/* $out/share/plasma/desktoptheme/
    runHook postInstall
  '';

  meta = {
    description = "Iridescent-round Plasma style for KDE Plasma 6";
    homepage = "https://github.com/ddh4r4m/Iridescent";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
