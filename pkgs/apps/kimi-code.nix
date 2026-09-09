# Source: https://github.com/MoonshotAI/kimi-code
#
# Bun single-file executable -- see the note in droid.nix: patchelf corrupts
# the appended payload (the binary segfaults), so this is wrapped, not patched.
{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
}: let
  version = "0.42.0";
  # The tag embeds the scoped npm name, so both "@" have to stay percent-encoded.
  releaseUrl = file: "https://github.com/MoonshotAI/kimi-code/releases/download/%40moonshot-ai/kimi-code%40${version}/${file}";
  sources = {
    x86_64-linux = {
      url = releaseUrl "kimi-code-linux-x64.tar.gz";
      hash = "sha256-YSHQvP6zn+JK4qVBl9NB+AeKp8FRcEOiyP1bVFz9l/w=";
    };
    aarch64-linux = {
      url = releaseUrl "kimi-code-linux-arm64.tar.gz";
      hash = "sha256-d5dmbWjJ5e8+9v+npPQLEyOQwekkwGFkkvaQlSwVc1s=";
    };
  };

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "kimi-code-unwrapped";
    inherit version;

    src = fetchurl (sources.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}"));

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
    inherit version;

    # ripgrep and fd back the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.ripgrep pkgs.fd];

    runScript = "${unwrapped}/bin/kimi";
    executableName = "kimi";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Moonshot AI's official Kimi Code CLI";
      homepage = "https://github.com/MoonshotAI/kimi-code";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "kimi";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
