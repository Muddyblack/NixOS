# Source: https://github.com/Muddyblack/audio-wave-visualizer
{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  gnugrep,
  util-linux,
  quickshell,
  plasma-audio-visualizer,
  audioVisualizerSrc,
}:
# Upstream only exports the plasmoid, so the Quickshell frontend is assembled
# here. package/ is taken from that plasmoid build rather than the raw source:
# its feeder and helper scripts are already wrapped with cava, python and
# pipewire on PATH.
stdenvNoCC.mkDerivation {
  pname = "audio-visualizer-hyprland";
  inherit (plasma-audio-visualizer) version;
  src = audioVisualizerSrc;

  nativeBuildInputs = [makeWrapper];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    root=$out/share/audio-wave-visualizer
    mkdir -p "$root"
    # hyprland/ imports ../package/..., so shell.qml, hyprland/ and package/
    # have to share one directory: it becomes the Quickshell sandbox root.
    cp -r hyprland shell.qml "$root/"
    cp -r ${plasma-audio-visualizer}/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer "$root/package"
    chmod -R u+w "$root"
    makeWrapper ${bash}/bin/bash $out/bin/audio-visualizer-hyprland \
      --add-flags "$root/hyprland/run.sh" \
      --prefix PATH : ${lib.makeBinPath [quickshell bash coreutils gnugrep util-linux]}
    runHook postInstall
  '';

  meta = {
    description = "Hyprland/Quickshell frontend of the audio visualizer widget";
    homepage = "https://github.com/Muddyblack/audio-wave-visualizer";
    mainProgram = "audio-visualizer-hyprland";
    platforms = lib.platforms.linux;
  };
}
