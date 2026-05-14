# Source: https://github.com/EliverLara/Sweet
{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sweet-theme";
  version = "4.0";

  src = fetchFromGitHub {
    owner = "EliverLara";
    repo = "Sweet";
    rev = "f1fbdd8c8b670895bd8026b2fabadcf5964433b1";
    hash = "sha256-gOUR/3gXjtsnQ+Z+vshxwkZti2e/liKIUGPDMcHGBZc=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Sweet
    cp -r * $out/share/themes/Sweet/
    if [ -d "kde/kvantum" ]; then
      mkdir -p $out/share/Kvantum
      cp -r kde/kvantum/* $out/share/Kvantum/
    elif [ -d "kvantum" ]; then
      mkdir -p $out/share/Kvantum
      cp -r kvantum/* $out/share/Kvantum/
    fi
    runHook postInstall
  '';

  meta = {
    description = "Sweet Dark GTK and Kvantum theme";
    homepage = "https://github.com/EliverLara/Sweet";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
}
