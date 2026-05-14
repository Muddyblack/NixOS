# Source: https://github.com/L4ki/Slot-Plasma-Themes
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "slot-icon-theme";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "L4ki";
    repo = "Slot-Plasma-Themes";
    rev = "4dd93ad62cf47307d85e3a624eacba34578bf1fe";
    hash = "sha256-M2jCyPLPDqhF2KnovRIrsISOECpFgaR4TUI0N++P8ho=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/Slot-Dark-Icons
    cp -r "Slot Icons Themes/Slot-Dark-Icons/"* $out/share/icons/Slot-Dark-Icons/

    # Fix broken symlinks
    find -L $out/share/icons/Slot-Dark-Icons -type l -delete

    runHook postInstall
  '';

  meta = {
    description = "Slot Dark Icons from Slot Plasma Themes";
    homepage = "https://github.com/L4ki/Slot-Plasma-Themes";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
