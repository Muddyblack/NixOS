# Source: https://github.com/Muddyblack/kde-audio-visualizer
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
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "Muddyblack";
    repo = "kde-audio-visualizer";
    rev = "v${version}";
    hash = "sha256-lWCyj9NkCyYs41uZCWMt04oVFO3CGS9l30/e/P2grjU=";
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
