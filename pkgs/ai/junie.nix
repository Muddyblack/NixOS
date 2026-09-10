# Source: https://github.com/JetBrains/junie
{
  lib,
  stdenv,
  callPackage,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  fontconfig,
  freetype,
  zlib,
}: let
  source = callPackage ./source.nix {} "junie";
in
  stdenv.mkDerivation {
    pname = "junie";
    inherit (source) version src;

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
      platforms = ["x86_64-linux"];
      mainProgram = "junie";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
