# Source: https://github.com/prayag2/kde_modernclock
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "kde-modern-clock";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "prayag2";
    repo = "kde_modernclock";
    rev = "main";
    sha256 = "108hvwvl3sc343diaazsdjpv4krc5w274pwpxmv7ln8vscsr6npq";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/plasma/plasmoids/com.github.prayag2.modernclock
    cp -r package/* $out/share/plasma/plasmoids/com.github.prayag2.modernclock/
    runHook postInstall
  '';

  meta = {
    description = "Modern Clock widget for KDE Plasma";
    homepage = "https://github.com/prayag2/kde_modernclock";
  };
}
