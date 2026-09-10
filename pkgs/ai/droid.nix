# Source: https://factory.ai
#
# `droid` is a Bun single-file executable: the JS payload is appended past the
# ELF image at a hard-coded offset, so patchelf silently corrupts it (the
# binary then starts as a bare Bun runtime). It has to be wrapped, not patched.
{
  lib,
  stdenvNoCC,
  callPackage,
  buildFHSEnv,
}: let
  source = callPackage ./source.nix {} "droid";

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "droid-unwrapped";
    inherit (source) version src;

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
    inherit (source) version;

    # ripgrep backs the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl pkgs.ripgrep];

    runScript = "${unwrapped}/bin/droid";
    executableName = "droid";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Factory AI's official Droid coding agent CLI";
      homepage = "https://factory.ai";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      mainProgram = "droid";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
