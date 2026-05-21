#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/claude-usage-test"
TOOL=/run/current-system/sw/bin/kpackagetool6
ID=org.muddyblack.claudeusageTest

if [ ! -x "$TOOL" ]; then
    echo "kpackagetool6 not found at $TOOL" >&2
    exit 1
fi

rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cp -r "$HERE/metadata.json" "$HERE/contents" "$TEMP_DIR"

# Replace both the Id and Name properties
sed -i "s/org.muddyblack.claudeusage/$ID/g" "$TEMP_DIR/metadata.json"
sed -i 's/"Name": "Claude Usage"/"Name": "Claude Usage (Test)"/g' "$TEMP_DIR/metadata.json"

# Update the icon filename and references inside QML to match the test ID
mv "$TEMP_DIR/contents/icons/org.muddyblack.claudeusage.svg" "$TEMP_DIR/contents/icons/$ID.svg"
sed -i "s/org.muddyblack.claudeusage/$ID/g" "$TEMP_DIR/contents/ui/main.qml"

# Copy the icon to the local user theme so Widget Explorer can load it
mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
cp "$TEMP_DIR/contents/icons/$ID.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/$ID.svg"

echo "Installing test version of the widget..."
if "$TOOL" -t Plasma/Applet -l 2>/dev/null | grep -q "$ID"; then
    "$TOOL" -t Plasma/Applet -u "$TEMP_DIR" 2>/dev/null
    echo "Updated existing test install."
else
    "$TOOL" -t Plasma/Applet -i "$TEMP_DIR" 2>/dev/null
    echo "Installed fresh test widget."
fi

echo ""
echo "=== Done: Claude Usage (Test) ==="
echo "Add it to your desktop/panel, or restart plasmashell if already added:"
echo "  plasmashell --replace &"
echo ""
echo "To remove the test version:"
echo "  $TOOL -t Plasma/Applet -r $ID"
echo "  rm -f \$HOME/.local/share/icons/hicolor/scalable/apps/$ID.svg"
echo ""
