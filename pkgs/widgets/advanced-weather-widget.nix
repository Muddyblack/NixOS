# Source: https://github.com/pnedyalkov91/advanced-weather-widget
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "advanced-weather-widget";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "pnedyalkov91";
    repo = "advanced-weather-widget";
    rev = "e6cf1e926dc23debc9069b1cf40c2598ad250701";
    hash = "sha256-xQ8nN4406b+gJ3ZZMQ3lT4YrzVHVNZclaTcpMpH8lQY=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/org.kde.plasma.advanced-weather-widget
    cp metadata.json $out/share/plasma/plasmoids/org.kde.plasma.advanced-weather-widget/
    cp -r contents $out/share/plasma/plasmoids/org.kde.plasma.advanced-weather-widget/
    runHook postInstall
  '';

  meta = {
    description = "Advanced KDE Plasma 6 weather widget with detailed popup, forecast and radar";
    homepage = "https://github.com/pnedyalkov91/advanced-weather-widget";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
