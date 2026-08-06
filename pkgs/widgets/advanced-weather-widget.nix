# Source: https://github.com/pnedyalkov91/advanced-weather-widget
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "advanced-weather-widget";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "pnedyalkov91";
    repo = "advanced-weather-widget";
    rev = version;
    hash = "sha256-KasBVXW24TnhW/1LqXHViO4y/MvPKpbNU8i/uMCnuL4=";
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
