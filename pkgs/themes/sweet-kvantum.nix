# Source: https://github.com/EliverLara/Sweet (nova branch)
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sweet-kvantum";
  version = "unstable-2024";

  src = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet";
    rev = "4ccbedf5f6566bf6863766e7b14163d94e7a2f0a";
    hash = "sha256-LWPyLMauAv/Slmg3W4v3jTpo3Lo/7H2n2htXfhKxy2M=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/Kvantum
    if [ -d "kde/Kvantum" ]; then
      cp -r kde/Kvantum/* $out/share/Kvantum/
    elif [ -d "kde/kvantum" ]; then
      cp -r kde/kvantum/* $out/share/Kvantum/
    fi
    runHook postInstall
  '';

  meta = {
    description = "Sweet Kvantum theme - pink/purple neon dark";
    homepage = "https://github.com/EliverLara/Sweet";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
