# Source: https://github.com/cline/cline
#
# Bun single-file executable -- see the note in droid.nix: patchelf corrupts
# the appended payload, so this is wrapped rather than patched.
{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
}: let
  version = "3.0.61";
  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@cline/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
      hash = "sha512-dsCg3/UVMl079e0GA8BUTszlZzHd9/JhZ6/23To9Zk/7JacGSThM731ygDEjJ19R3wi+JCXu1GBoLsg0HRiFBA==";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@cline/cli-linux-arm64/-/cli-linux-arm64-${version}.tgz";
      hash = "sha512-3dM+aNmOK4xqbIFJ75NhQ/PdepS4tCnleclXXuYsX12l5WIW4Fznqj8sntgrleI941TAe+Qi7Mr9x7RpbGGIhQ==";
    };
  };

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "cline-unwrapped";
    inherit version;

    src = fetchurl (sources.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}"));

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
    inherit version;

    # ripgrep backs the agent's file search.
    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl pkgs.ripgrep];

    runScript = "${unwrapped}/bin/cline";
    executableName = "cline";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Autonomous coding agent CLI";
      homepage = "https://github.com/cline/cline";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux" "aarch64-linux"];
      mainProgram = "cline";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
