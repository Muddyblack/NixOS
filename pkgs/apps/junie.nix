# Source: https://github.com/JetBrains/junie
#
# Pinned to 3110.6 deliberately: it is the newest tag shipping a
# `junie-release-*` asset. Everything above it is `junie-nightly-*`.
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  fontconfig,
  freetype,
  zlib,
}: let
  version = "3110.6";
  sources = {
    x86_64-linux = {
      url = "https://github.com/JetBrains/junie/releases/download/${version}/junie-release-${version}-linux-amd64.zip";
      hash = "sha256-kjzEdEBbQ4SR+yrGLoyk6sPkRYpfpDjWh8HMPaiF+BM=";
    };
    aarch64-linux = {
      url = "https://github.com/JetBrains/junie/releases/download/${version}/junie-release-${version}-linux-aarch64.zip";
      hash = "sha256-jCCr2i9ibFxyB1vI0DGf8Ogi64hobazD8kNhwsNuNvs=";
    };
  };
in
  stdenv.mkDerivation {
    pname = "junie";
    inherit version;

    src = fetchurl (sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}"));

    sourceRoot = ".";

    dontBuild = true;
    dontConfigure = true;

    nativeBuildInputs = [unzip autoPatchelfHook makeWrapper];
    buildInputs = [alsa-lib fontconfig freetype stdenv.cc.cc.lib zlib];

    # The bundled JRE ships AWT and splash-screen libraries that a headless CLI
    # never dlopens; pulling X11 and Wayland in just to satisfy them would
    # roughly double the closure.
    autoPatchelfIgnoreMissingDeps = [
      "libX11.so.6"
      "libXext.so.6"
      "libXi.so.6"
      "libXrender.so.1"
      "libXtst.so.6"
      "libwayland-client.so.0"
      "libwayland-cursor.so.0"
    ];

    # The archive's top-level `junie` is a launcher that resolves
    # junie-app/bin/junie relative to its own directory, so it cannot be
    # symlinked into $out/bin -- wrap the jpackage launcher itself instead.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec
      cp -a . $out/libexec/junie
      makeWrapper $out/libexec/junie/junie-app/bin/junie $out/bin/junie
      runHook postInstall
    '';

    meta = {
      description = "JetBrains' official Junie coding agent CLI";
      homepage = "https://junie.jetbrains.com/";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "junie";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
