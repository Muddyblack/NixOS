# Source: https://dev.meta.ai
{
  lib,
  stdenvNoCC,
  callPackage,
}: let
  source = callPackage ./source.nix {} "muse";
in
  stdenvNoCC.mkDerivation {
    pname = "muse";
    inherit (source) version src;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 $src $out/bin/muse
      runHook postInstall
    '';

    meta = {
      description = "Meta's terminal-native AI coding agent";
      homepage = "https://dev.meta.ai";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "muse";
    };
  }
