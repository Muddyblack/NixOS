# Source: https://github.com/L4ki/Colorful-Plasma-Themes
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "colorful-icon-theme";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "L4ki";
    repo = "Colorful-Plasma-Themes";
    rev = "67fe0058dc44c3b86898fee1c930d718fcc834dc";
    hash = "sha256-bC4uAHnR4xZ50nEmG4Xyr0APvgL2r0BMD6b4a8UJbD0=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/Colorful-Dark-Icons
    cp -r "Colorful Icons Themes/Colorful-Dark-Icons/"* $out/share/icons/Colorful-Dark-Icons/

    # Fix broken symlinks
    find -L $out/share/icons/Colorful-Dark-Icons -type l -delete

    runHook postInstall
  '';

  meta = {
    description = "Colorful Dark Icons from Colorful Plasma Themes";
    homepage = "https://github.com/L4ki/Colorful-Plasma-Themes";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
