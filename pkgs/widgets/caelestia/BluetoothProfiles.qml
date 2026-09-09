pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ColumnLayout {
    id: root

    property var cards: []
    property string errorText: ""
    property string queryError: ""
    property bool refreshPending: false

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    function refresh() {
        if (query.running || change.running) {
            refreshPending = true;
            return;
        }
        refreshPending = false;
        query.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 3000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["@pactl@", "--format=json", "list", "cards"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const cards = JSON.parse(text).filter(card => card.name.startsWith("bluez_card."));
                    root.queryError = "";
                    if (JSON.stringify(cards) !== JSON.stringify(root.cards))
                        root.cards = cards;
                } catch (error) {
                    root.cards = [];
                    root.queryError = qsTr("Could not read Bluetooth audio profiles.");
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.cards = [];
                root.queryError = qsTr("Could not connect to the audio service.");
            }
            if (root.refreshPending)
                Qt.callLater(root.refresh);
        }
    }

    Process {
        id: change
        onExited: (code, status) => {
            root.errorText = code === 0 ? "" : qsTr("Could not switch audio profile. Reconnect the device and try again.");
            root.refresh();
        }
    }

    Repeater {
        model: root.cards

        SelectRow {
            id: row

            required property var modelData
            required property int index

            first: index === 0
            last: index === root.cards.length - 1
            label: modelData.properties["device.description"] || modelData.name
            subtext: change.running ? qsTr("Switching…") : qsTr("Bluetooth profile / codec")
            enabled: !change.running
            menuItems: profiles.instances
            active: menuItems.find(item => item.modelData.name === row.modelData.active_profile) ?? null
            fallbackText: modelData.active_profile
            fallbackIcon: "bluetooth"
            onSelected: item => {
                Qt.callLater(() => {
                    row.active = Qt.binding(() => row.menuItems.find(entry => entry.modelData.name === row.modelData.active_profile) ?? null);
                });
                if (item.modelData.name === row.modelData.active_profile || change.running)
                    return;
                root.errorText = "";
                change.command = ["@pactl@", "set-card-profile", row.modelData.name, item.modelData.name];
                change.running = true;
            }

            Variants {
                id: profiles
                model: Object.entries(row.modelData.profiles || {}).filter(([name, profile]) => profile.available !== "no" || name === row.modelData.active_profile).map(([name, profile]) => ({
                            name: name,
                            description: profile.description
                        }))

                MenuItem {
                    required property var modelData
                    text: modelData.description || modelData.name
                    icon: modelData.name === row.modelData.active_profile ? "check" : "bluetooth"
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: text.length > 0
        text: root.queryError || root.errorText
        wrapMode: Text.Wrap
        color: Colours.palette.m3error
        font: Tokens.font.body.small
    }
}
