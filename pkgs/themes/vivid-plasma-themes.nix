# Source: https://github.com/L4ki/Vivid-Plasma-Themes
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "vivid-plasma-themes";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "L4ki";
    repo = "Vivid-Plasma-Themes";
    rev = "598e24d41b1a040620e81e971020e32fa9480944";
    hash = "sha256-Qr3NYqtjdlULRPzPw0N8ff6feAGpN63/PB2hm+srylM=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r "Vivid Icons Themes/Vivid-Dark-Icons" $out/share/icons/
    mkdir -p $out/share/plasma/look-and-feel
    cp -r "Vivid Global Themes/Vivid-Dark-Global-6" $out/share/plasma/look-and-feel/
    # The global theme itself is never applied (see plasma-settings.nix), but its
    # colour scheme is set by name, so the .colors files have to be on the path.
    mkdir -p $out/share/color-schemes
    cp "Vivid Color Schemes"/*.colors $out/share/color-schemes/
    runHook postInstall
  '';

  meta = {
    description = "Vivid Dark Icons, Colour Schemes and Global Theme for KDE Plasma";
    homepage = "https://github.com/L4ki/Vivid-Plasma-Themes";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
