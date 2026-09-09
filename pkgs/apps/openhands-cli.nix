# Source: https://github.com/OpenHands/OpenHands-CLI
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
}: let
  version = "1.16.0";
  sources = {
    x86_64-linux = {
      url = "https://github.com/OpenHands/OpenHands-CLI/releases/download/${version}/openhands-linux-x86_64";
      hash = "sha256-ywTuLakcaYcz1SAcVcvAjYHczJ1ktmYnWr9opODFkOM=";
    };
    aarch64-linux = {
      url = "https://github.com/OpenHands/OpenHands-CLI/releases/download/${version}/openhands-linux-arm64";
      hash = "sha256-Z8XPuU5f1MQSDrA2Cw8jM32jH2SnDoSWvPAI5Mrupq8=";
    };
  };
in
  stdenv.mkDerivation {
    pname = "openhands-cli";
    inherit version;

    src = fetchurl (sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}"));

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
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "openhands";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
