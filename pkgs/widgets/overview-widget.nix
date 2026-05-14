# Source: https://github.com/HimDek/Overview-Widget-for-Plasma
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "overview-widget";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "HimDek";
    repo = "Overview-Widget-for-Plasma";
    rev = "master";
    sha256 = "18qfd0nwm44381zzcpwkyc4zb8dnign0szdvf8n16bgggq6x12ky";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/com.himdek.kde.plasma.overview
    cp -r * $out/share/plasma/plasmoids/com.himdek.kde.plasma.overview/
    runHook postInstall
  '';

  meta = {
    description = "Overview Widget for KDE Plasma by HimDek";
    homepage = "https://github.com/HimDek/Overview-Widget-for-Plasma";
  };
}
