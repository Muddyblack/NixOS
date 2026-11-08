# Source: https://github.com/storytold
{
  lib,
  stdenvNoCC,
  callPackage,
  autoPatchelfHook,
  makeWrapper,
  bubblewrap,
  gcc-unwrapped,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libGL,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxcb,
  fontconfig,
  alsa-lib,
  name,
}: let
  source = callPackage ./source.nix {} name;
  libs = [
    wayland
    libxkbcommon
    vulkan-loader
    libGL
    libx11
    libxcursor
    libxi
    libxrandr
    libxcb
    fontconfig
    alsa-lib
  ];
in
  stdenvNoCC.mkDerivation {
    pname = name;
    inherit (source) version src;

    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    buildInputs = [gcc-unwrapped.lib] ++ libs;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r bin share $out/
      mkdir -p $out/libexec
      for f in $out/bin/*; do
        wrapProgram $f --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}:/run/opengl-driver/lib
        mv $f $out/libexec/$(basename $f)
        makeWrapper ${bubblewrap}/bin/bwrap $f \
          --add-flags "--bind / / --dev-bind /dev /dev --unshare-net --die-with-parent $out/libexec/$(basename $f)"
      done
      runHook postInstall
    '';

    meta = {
      homepage = "https://getartcraft.com/apps/${name}";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = name;
    };
  }
