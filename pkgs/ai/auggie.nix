# Source: https://github.com/augmentcode/auggie
{
  lib,
  stdenvNoCC,
  callPackage,
  makeWrapper,
  nodejs,
}: let
  source = callPackage ./source.nix {} "auggie";
in
  stdenvNoCC.mkDerivation {
    pname = "auggie";
    inherit (source) version src;

    nativeBuildInputs = [makeWrapper];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/libexec/auggie" "$out/bin"
      cp -r . "$out/libexec/auggie/"
      makeWrapper "${nodejs}/bin/node" "$out/bin/auggie" \
        --add-flags "$out/libexec/auggie/augment.mjs"
      runHook postInstall
    '';

    meta = {
      description = "Auggie CLI client by Augment Code";
      homepage = "https://github.com/augmentcode/auggie";
      license = lib.licenses.unfree;
      platforms = lib.platforms.all;
      mainProgram = "auggie";
    };
  }
