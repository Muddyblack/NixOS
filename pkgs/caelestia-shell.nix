# Source: https://github.com/caelestia-dots/shell
{
  caelestia-shell,
  pulseaudio,
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
    '';
})
