{
  stdenvNoCC,
  lib,
  cava,
  util-linux,
  procps,
  runtimeShell,
}:
stdenvNoCC.mkDerivation {
  pname = "plasma-audio-wave-widget";
  version = "1.0";

  src = ./.;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    root=$out/share/plasma/plasmoids/Audio.Wave.Widget
    mkdir -p $root/contents/ui $out/bin

    install -Dm644 metadata.json $root/metadata.json
    install -Dm644 cava.conf     $root/cava.conf
    install -Dm644 contents/ui/main.qml       $root/contents/ui/main.qml
    install -Dm644 contents/ui/Visualizer.qml $root/contents/ui/Visualizer.qml

    install -Dm755 feeder.sh $out/bin/audio-wave-feeder
    substituteInPlace $out/bin/audio-wave-feeder \
      --replace-fail "@SHELL@"     "${runtimeShell}" \
      --replace-fail "@CAVA@"      "${cava}/bin/cava" \
      --replace-fail "@FLOCK@"     "${util-linux}/bin/flock" \
      --replace-fail "@CAVA_CONF@" "$root/cava.conf"

    substituteInPlace $root/contents/ui/Visualizer.qml \
      --replace-fail "@FEEDER@" "$out/bin/audio-wave-feeder" \
      --replace-fail "@PKILL@"  "${procps}/bin/pkill"

    runHook postInstall
  '';

  meta = {
    description = "Plasma 6 audio visualizer widget (cava-backed)";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
