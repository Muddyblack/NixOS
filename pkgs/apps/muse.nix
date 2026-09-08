# Source: https://dev.meta.ai
{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  version = "1.0.3-R2198.1";
  sources = {
    x86_64-linux = {
      url = "https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=${version}&file=muse-x86-linux";
      hash = "sha256-daaPmMQ339F9Jkcwxbxy1X5fHhjRBHKp9TJh/8wJE1I=";
    };
    aarch64-linux = {
      url = "https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=${version}&file=muse-aarch64-linux";
      hash = "sha256-T/z1X16wZoZD8wxf69kNGIuaLaZYWJGERNMfYEaUASA=";
    };
  };
in
  stdenvNoCC.mkDerivation {
    pname = "muse";
    inherit version;

    src = fetchurl (sources.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}"));

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
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "muse";
    };
  }
