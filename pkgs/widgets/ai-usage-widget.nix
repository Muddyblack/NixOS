# Source: https://github.com/Muddyblack/kde-ai-usage
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ai-usage-widget";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-ai-usage";
    rev = "refs/tags/v${version}";
    hash = "sha256-Q/4VVh8LBuzIp/3SIHDJX029jcudca7VJXBp8P/gRZk=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    root=$out/share/plasma/plasmoids/org.muddyblack.aiUsageWidget
    mkdir -p "$root"
    cp -r package/. "$root/"
    mkdir -p "$out/share/icons/hicolor/scalable/apps"
    cp package/contents/icons/org.muddyblack.aiUsageWidget.svg "$out/share/icons/hicolor/scalable/apps/org.muddyblack.aiUsageWidget.svg"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma 6 session & weekly token usage widget (currently supports Claude)";
    homepage = "https://github.com/Muddyblack/kde-ai-usage";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
