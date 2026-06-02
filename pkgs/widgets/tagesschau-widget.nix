# Source: https://github.com/Muddyblack/kde-tagesschau-rss-widget
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "tagesschau-widget";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-tagesschau-rss-widget";
    rev = "refs/tags/v${version}";
    hash = "sha256-3rYo/bj8Wd8Xq7Sh1TGDAYmVrt5T3niegLPO7TFKBGc=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    root=$out/share/plasma/plasmoids/org.muddyblack.tagesschauWidget
    mkdir -p "$root"
    cp -r package/. "$root/"
    mkdir -p "$out/share/icons/hicolor/scalable/apps"
    cp package/contents/icons/org.muddyblack.tagesschauWidget.svg "$out/share/icons/hicolor/scalable/apps/org.muddyblack.tagesschauWidget.svg"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma 6 widget for tracking German breaking news (Eilmeldungen), RSS feeds, and market prices";
    homepage = "https://github.com/Muddyblack/kde-tagesschau-rss-widget";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
