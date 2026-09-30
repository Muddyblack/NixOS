# Source: https://github.com/XiaomiMiMo/MiMo-Code
{
  lib,
  stdenvNoCC,
  callPackage,
  buildFHSEnv,
}: let
  source = callPackage ./source.nix {} "mimo-code";

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "mimo-code-unwrapped";
    inherit (source) version src;

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/mimo $out/bin/mimo
      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    pname = "mimo-code";
    inherit (source) version;

    targetPkgs = pkgs: [pkgs.stdenv.cc.cc.lib pkgs.zlib pkgs.openssl pkgs.ripgrep];

    runScript = "${unwrapped}/bin/mimo";
    executableName = "mimo";

    passthru = {inherit unwrapped;};

    meta = {
      description = "Xiaomi MiMo Code CLI";
      homepage = "https://github.com/XiaomiMiMo/MiMo-Code";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "mimo";
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
