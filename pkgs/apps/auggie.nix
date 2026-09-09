# Source: https://github.com/augmentcode/auggie
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  nodejs,
}: let
  version = "0.36.0";
in
  stdenvNoCC.mkDerivation {
    pname = "auggie";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/@augmentcode/auggie/-/auggie-${version}.tgz";
      hash = "sha512-jb4kq97pGzG0i5UyISc//LjTVlFzIywwD+VfPemiSIl58KjLfxry3KDgxWYnr1vmV8yUkySVzjLnj4ewUEbT/Q==";
    };

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
