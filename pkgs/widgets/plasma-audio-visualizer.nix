# Source: https://github.com/Muddyblack/plasma-audio-visualizer
{
  stdenvNoCC,
  lib,
  fetchFromGitHub,
  cava,
  util-linux,
  procps,
  makeWrapper,
}:
stdenvNoCC.mkDerivation rec {
  pname = "plasma-audio-visualizer";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "plasma-audio-visualizer";
    rev = "v${version}";
    hash = "sha256-F98iXFBTma5tZVepajadQGh+FvKyII6G2p+MOm5H5dc=";
  };

  nativeBuildInputs = [makeWrapper];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    root=$out/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer
    mkdir -p "$root"
    cp -r package/. "$root/"
    chmod +x "$root/contents/code/feeder.sh"
    wrapProgram "$root/contents/code/feeder.sh" \
      --prefix PATH : ${lib.makeBinPath [cava util-linux procps]}
    runHook postInstall
  '';

  meta = {
    description = "Plasma 6 audio visualizer widget (cava-backed)";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
