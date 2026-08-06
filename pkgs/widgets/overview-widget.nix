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
    rev = "030224751ad7114e695297c9f0822b668baee5f9";
    hash = "sha256-forQDX7vLRMscrt9DeyLtqH1CfOTX/Z/QIOQyi1oDqM=";
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
