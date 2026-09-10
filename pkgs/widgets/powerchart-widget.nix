# Source: https://github.com/jboero/kde-plasmoid-powerchart
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kde-plasmoid-powerchart";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "jboero";
    repo = "kde-plasmoid-powerchart";
    rev = "3ca2e9e29ef608c53e1518259fe5094b89a13c1f";
    hash = "sha256-h/6lfBBE4V3ETp4IOUVK8L1YYsqsD8rShFc9MNeAY3s=";
  };

  dontBuild = true;
  dontConfigure = true;

  # The poll script runs every second per widget instance and calls the Python
  # powerprofilesctl twice (~0.1 s CPU each), which alone kept plasmashell's
  # cgroup near 50% CPU with two instances. Take its gdbus fallback instead —
  # same D-Bus properties, same output, ~10x cheaper.
  postPatch = ''
    substituteInPlace contents/scripts/battery-poll.sh \
      --replace-fail 'if command -v powerprofilesctl >/dev/null 2>&1; then' 'if false; then'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.kde.plasma.batterymonitor-boero
    cp metadata.json $out/share/plasma/plasmoids/org.kde.plasma.batterymonitor-boero/
    cp -r contents $out/share/plasma/plasmoids/org.kde.plasma.batterymonitor-boero/
    # Make the poll script executable
    chmod +x $out/share/plasma/plasmoids/org.kde.plasma.batterymonitor-boero/contents/scripts/battery-poll.sh
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma widget for real-time battery level and power consumption graphing";
    homepage = "https://github.com/jboero/kde-plasmoid-powerchart";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
