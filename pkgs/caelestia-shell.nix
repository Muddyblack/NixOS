# Source: https://github.com/caelestia-dots/shell
{
  caelestia-shell,
  pulseaudio,
  wireplumber,
}:
caelestia-shell.overrideAttrs (old: {
  postInstall =
    (old.postInstall or "")
    + ''
      install -m644 ${./widgets/caelestia/BluetoothProfiles.qml} \
        $out/share/caelestia-shell/modules/nexus/common/BluetoothProfiles.qml
      substituteInPlace $out/share/caelestia-shell/modules/nexus/common/BluetoothProfiles.qml \
        --replace-fail '@pactl@' '${pulseaudio}/bin/pactl'
      substituteInPlace $out/share/caelestia-shell/modules/nexus/pages/AudioPage.qml \
        --replace-fail '// Input' 'BluetoothProfiles { Layout.topMargin: Tokens.spacing.large }
          // Input'

      # Quickshell's preferredDefault* only writes a metadata hint that
      # WirePlumber's stored default (e.g. a stale Bluetooth speaker) overrides,
      # so Bluetooth sinks like the Galaxy Buds never became the output.
      # Set the default through wpctl instead.
      substituteInPlace $out/share/caelestia-shell/services/Audio.qml \
        --replace-fail 'Pipewire.preferredDefaultAudioSink = newSink;' \
          'Quickshell.execDetached(["${wireplumber}/bin/wpctl", "set-default", String(newSink.id)]);' \
        --replace-fail 'Pipewire.preferredDefaultAudioSource = newSource;' \
          'Quickshell.execDetached(["${wireplumber}/bin/wpctl", "set-default", String(newSource.id)]);'
    '';
})
