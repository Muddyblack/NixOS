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
    rev = "5c86f0f23d2646be7e9872fc5e769bdce259af92";
    hash = "sha256-+FqTNdMbWXp27ZdfcgQvLE+yr2z6KxXbIIPpQTffEIE=";
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
