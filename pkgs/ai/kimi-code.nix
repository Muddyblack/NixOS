# Source: https://github.com/MoonshotAI/kimi-code
#
# Bun single-file executable -- see the note in droid.nix: patchelf corrupts
# the appended payload (the binary segfaults), so this is wrapped, not patched.
{
  lib,
  stdenvNoCC,
  callPackage,
  buildFHSEnv,
}: let
  source = callPackage ./source.nix {} "kimi-code";

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "kimi-code-unwrapped";
    inherit (source) version src;

    sourceRoot = ".";

    dontBuild = true;
    dontConfigure = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mapfile -t binaries < <(find . -type f -name kimi)
      test "''${#binaries[@]}" -eq 1
      install -Dm755 "''${binaries[0]}" $out/bin/kimi
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    pname = "kimi-code";
    inherit (source) version;

    # ripgrep and fd back the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.ripgrep pkgs.fd];

    runScript = "${unwrapped}/bin/kimi";
    executableName = "kimi";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Moonshot AI's official Kimi Code CLI";
      homepage = "https://github.com/MoonshotAI/kimi-code";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "kimi";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
