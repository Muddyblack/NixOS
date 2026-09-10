# Source: https://github.com/cline/cline
#
# Bun single-file executable -- see the note in droid.nix: patchelf corrupts
# the appended payload, so this is wrapped rather than patched.
{
  lib,
  stdenvNoCC,
  callPackage,
  buildFHSEnv,
}: let
  source = callPackage ./source.nix {} "cline";

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "cline-unwrapped";
    inherit (source) version src;

    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/cline $out/bin/cline
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    pname = "cline";
    inherit (source) version;

    # ripgrep backs the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl pkgs.ripgrep];

    runScript = "${unwrapped}/bin/cline";
    executableName = "cline";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Autonomous coding agent CLI";
      homepage = "https://github.com/cline/cline";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "cline";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
