# Source: https://github.com/Muddyblack/kde-glassy-system-monitor
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "glassy-system-monitor";
  version = "0.0.11-beta";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-glassy-system-monitor";
    rev = "refs/tags/v${version}";
    hash = "sha256-HLTLIoFnFW0KueCy+ABvJIaGH+FelOQOYLCDCqRZYgI=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    root=$out/share/plasma/plasmoids/org.muddyblack.glassySystemMonitor
    mkdir -p "$root"
    cp -r package/. "$root/"
    mkdir -p "$out/share/icons/hicolor/256x256/apps"
    cp package/icon.png "$out/share/icons/hicolor/256x256/apps/org.muddyblack.glassySystemMonitor.png"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma 6 glassy real-time system performance and network monitor widget";
    homepage = "https://github.com/Muddyblack/kde-glassy-system-monitor";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
