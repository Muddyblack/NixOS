# Source: https://github.com/caelestia-dots/shell
{
  caelestia-shell,
  pulseaudio,
  writeText,
}: let
  # Inserted verbatim after the "// Connectivity" marker in PageCompRegistry.qml,
  # i.e. immediately before upstream's Network component, so it lines up with
  # the Display entry that PageRegistry.qml lists first in that category.
  displayComp = writeText "caelestia-display-comp.qml" ''
    Component {
        // Display
        StackPage {
            Component {
                DisplayPage {}
            }
        }
    },
  '';
in
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

        # Upstream reserves a "Display" entry in the settings app but ships it
        # commented out with a TODO and no page behind it. Drop our own page in
        # and uncomment the entry.
        #
        # The two registries are index-mapped — a page added to one without the
        # other shifts every page after it — so both are patched here, at the
        # same position. sed rather than substituteInPlace because these are
        # multi-line edits, and a Nix indented string dedents a multi-line
        # --replace-fail pattern until it no longer matches the file.
        install -m644 ${./widgets/caelestia/DisplayPage.qml} \
          $out/share/caelestia-shell/modules/nexus/pages/DisplayPage.qml

        registry=$out/share/caelestia-shell/modules/nexus/PageRegistry.qml
        grep -q '^        // TODO$' "$registry" # fail the build if upstream reshuffled it
        sed -i \
          -e '\|^        // TODO$|d' \
          -e '\|^        // {$|,\|^        // },$|s|^        // |        |' \
          "$registry"

        comps=$out/share/caelestia-shell/modules/nexus/PageCompRegistry.qml
        grep -q '^        // Connectivity$' "$comps"
        sed -i -e '\|^        // Connectivity$|r ${displayComp}' "$comps"
      '';
  })
