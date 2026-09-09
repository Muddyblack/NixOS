# Source: https://factory.ai
#
# `droid` is a Bun single-file executable: the JS payload is appended past the
# ELF image at a hard-coded offset, so patchelf silently corrupts it (the
# binary then starts as a bare Bun runtime). It has to be wrapped, not patched.
{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
}: let
  version = "0.215.1";
  sources = {
    x86_64-linux = {
      url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64/droid";
      hash = "sha256-/QuZWKyAnH1bcK+YQoo87HyoOaM4HHEfJVYXxrjMr5A=";
    };
    aarch64-linux = {
      url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/arm64/droid";
      hash = "sha256-AGILns9EjOCH65FUtf7xq/TP7NF34aEtoCu8Rfi2iE0=";
    };
  };

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "droid-unwrapped";
    inherit version;

    src = fetchurl (sources.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}"));

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/droid
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    pname = "droid";
    inherit version;

    # ripgrep backs the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl pkgs.ripgrep];

    runScript = "${unwrapped}/bin/droid";
    executableName = "droid";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Factory AI's official Droid coding agent CLI";
      homepage = "https://factory.ai";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "droid";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
