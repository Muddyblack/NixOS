# Source: https://github.com/OpenHands/OpenHands-CLI
{
  lib,
  stdenv,
  callPackage,
  autoPatchelfHook,
  zlib,
}: let
  source = callPackage ./source.nix {} "openhands-cli";
in
  stdenv.mkDerivation {
    pname = "openhands-cli";
    inherit (source) version src;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [zlib];

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/openhands
      runHook postInstall
    '';

    meta = {
      description = "Official OpenHands terminal agent";
      homepage = "https://github.com/OpenHands/OpenHands-CLI";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "openhands";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
