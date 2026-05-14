# Source: https://github.com/EliverLara/Sweet
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sweet-cursors";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet";
    rev = "9450c5c633887acd20f0b953fa533cc51079c319";
    hash = "sha256-LAO0kLswTVBXnwEyb70EyfzFsb0oQ7YKR1s5kSH0ux8=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r kde/cursors/Sweet-cursors $out/share/icons/
    runHook postInstall
  '';

  meta = {
    description = "Sweet cursor theme for KDE Plasma";
    homepage = "https://github.com/EliverLara/Sweet";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
