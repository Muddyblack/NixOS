import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    toolTipMainText: "Claude API Usage"
    toolTipSubText: {
        var lines = []
        var fReset = root.sessionResetTime ? " · resets " + root.sessionResetTime : ""
        var sReset = root.weeklyResetTime  ? " · resets " + root.weeklyResetTime  : ""
        lines.push("5 Hours: " + Math.round(root.sessionPct) + "%" + fReset)
        lines.push("7 Days:  " + Math.round(root.weeklyPct)  + "%" + sReset)
        if (root.errorMsg !== "")
            lines.push("⚠ " + root.errorMsg)
        else if (root.lastUpdate !== "")
            lines.push("Updated " + root.lastUpdate + (root.stale ? " (stale)" : ""))
        return lines.join("\n")
    }

    // ── Data ─────────────────────────────────────────────────────────────────
    property real   sessionPct:       0
    property string sessionResetTime: ""
    property real   weeklyPct:        0
    property string weeklyResetTime:  ""
    property string errorMsg:         ""
    property bool   stale:            false
    property string lastUpdate:       ""
    property int    backoffMs:        0

    property string _token: ""

    // Claude brand palette
    readonly property color claudeOrange:    "#cc785c"
    readonly property color sessionColor:    "#e05252"
    readonly property color weeklyColor:     "#f5a623"
    readonly property color warningColor:    "#ffa64d"
    readonly property color dangerColor:     "#ff4d4d"

    // ── Credentials ──────────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: credSource
        engine: "executable"
        connectedSources: []
        onNewData: function(src, data) {
            disconnectSource(src)
            try {
                var creds = JSON.parse((data["stdout"] || "").trim())
                root._token = (creds.claudeAiOauth || {}).accessToken || ""
                if (root._token) fetchUsage()
                else             root.errorMsg = "Not logged in"
            } catch(_) { root.errorMsg = "Not logged in" }
        }
    }

    function loadCreds() {
        credSource.connectSource("cat $HOME/.claude/.credentials.json 2>/dev/null")
    }

    // ── API fetch ────────────────────────────────────────────────────────────
    function fetchUsage() {
        if (root.backoffMs > 0) return
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://api.anthropic.com/api/oauth/usage")
        xhr.setRequestHeader("Authorization",  "Bearer " + root._token)
        xhr.setRequestHeader("anthropic-beta", "oauth-2025-04-20")
        xhr.setRequestHeader("User-Agent",     "claude-code/2.1.0")
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText)
                    var f = d.five_hour || {}
                    var s = d.seven_day  || {}
                    root.sessionPct  = f.utilization || 0
                    root.weeklyPct   = s.utilization || 0
                    var fReset = new Date(f.resets_at || "")
                    root.sessionResetTime = !isNaN(fReset) ? Qt.formatTime(fReset, "hh:mm") : ""
                    var sReset = new Date(s.resets_at || "")
                    root.weeklyResetTime  = !isNaN(sReset) ? Qt.formatDateTime(sReset, "MMM d, hh:mm") : ""
                    root.errorMsg   = ""
                    root.stale      = false
                    root.lastUpdate = Qt.formatTime(new Date(), "hh:mm")
                } catch(_) { root.errorMsg = "parse error" }
            } else if (xhr.status === 429) {
                var retryAfter = parseInt(xhr.getResponseHeader("retry-after") || "0")
                root.backoffMs = retryAfter > 0 ? retryAfter * 1000 : 300000
                backoffTimer.restart()
                root.errorMsg = "rate limited"
            } else if (xhr.status === 401) {
                root.errorMsg = "token expired"
            } else {
                root.errorMsg = "err " + xhr.status
            }
        }
        xhr.send()
    }

    function refresh() { loadCreds() }

    // ── Timers ───────────────────────────────────────────────────────────────
    Timer {
        interval: 300000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer {
        id: backoffTimer
        interval: root.backoffMs; running: false; repeat: false
        onTriggered: { root.backoffMs = 0; root.errorMsg = ""; root.refresh() }
    }
    Timer {
        interval: 600000; running: root.lastUpdate !== ""; repeat: true
        onTriggered: root.stale = (root.errorMsg !== "")
    }

    // ── Compact (panel) ──────────────────────────────────────────────────────
    compactRepresentation: Item {
        id: compactRoot

        implicitWidth:  compactRow.implicitWidth + 18
        implicitHeight: Kirigami.Units.iconSizes.medium

        Layout.preferredWidth:  implicitWidth
        Layout.minimumWidth:    implicitWidth
        Layout.maximumWidth:    implicitWidth
        Layout.preferredHeight: implicitHeight
        Layout.minimumHeight:   implicitHeight

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
            hoverEnabled: true
            id: compactMouse

            Rectangle {
                anchors.fill: parent
                radius: Math.min(height / 2, 8)
                color: compactMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                visible: root.errorMsg !== ""
                width: 6; height: 6; radius: 3
                color: root.dangerColor
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.errorMsg !== ""
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            PanelSlot {
                pct:       root.sessionPct
                iconColor: root.sessionColor
                stale:     root.stale
            }

            Rectangle {
                width: 1; height: 14
                color: Qt.rgba(1, 1, 1, 0.16)
                anchors.verticalCenter: parent.verticalCenter
            }

            PanelSlot {
                pct:       root.weeklyPct
                iconColor: root.weeklyColor
                stale:     root.stale
            }
        }
    }

    // ── Popup ────────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        Layout.minimumWidth:   Kirigami.Units.gridUnit * 22
        Layout.minimumHeight:  Kirigami.Units.gridUnit * 11
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing + 4
            spacing: Kirigami.Units.largeSpacing

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    width: 22; height: 22
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        source: Qt.resolvedUrl("../icons/org.muddyblack.claudeusage.svg")
                        isMask: true
                        color: root.claudeOrange
                        opacity: 0.25
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        source: Qt.resolvedUrl("../icons/org.muddyblack.claudeusage.svg")
                        isMask: true
                        color: root.claudeOrange
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents.Label {
                        text: "Claude Usage"
                        font.bold: true
                        font.pixelSize: 15
                        color: Kirigami.Theme.textColor
                    }
                    PlasmaComponents.Label {
                        text: "API quota tracking"
                        font.pixelSize: 10
                        opacity: 0.5
                        color: Kirigami.Theme.textColor
                    }
                }

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    onClicked: root.refresh()
                    opacity: hovered ? 1.0 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            // ── Divider ──
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ── Usage rows ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                PopupRow {
                    label:    "5 Hours"
                    subtitle: root.sessionResetTime ? "resets " + root.sessionResetTime : ""
                    value:    root.sessionPct
                    barColor: root.sessionColor
                }
                PopupRow {
                    label:    "7 Days"
                    subtitle: root.weeklyResetTime ? "resets " + root.weeklyResetTime : ""
                    value:    root.weeklyPct
                    barColor: root.weeklyColor
                }
            }

            Item { Layout.fillHeight: true }

            // ── Footer ──
            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    visible: root.errorMsg !== ""
                    width: 6; height: 6; radius: 3
                    color: root.dangerColor
                    Layout.alignment: Qt.AlignVCenter
                }

                PlasmaComponents.Label {
                    visible: root.errorMsg !== ""
                    text: root.errorMsg
                    color: root.dangerColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    visible: root.lastUpdate !== "" && root.errorMsg === ""
                    text: "updated " + root.lastUpdate + (root.stale ? " · stale" : "")
                    opacity: 0.45
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
        }
    }

    // ── Panel slot ───────────────────────────────────────────────────────────
    component PanelSlot: RowLayout {
        id: slot
        property real   pct:       0
        property color  iconColor: "#cc785c"
        property bool   stale:     false

        spacing: 5
        opacity: stale ? 0.55 : 1.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Item {
            width: 16; height: 16
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 16; height: 16
                source: Qt.resolvedUrl("../icons/org.muddyblack.claudeusage.svg")
                isMask: true
                color: slot.iconColor
                opacity: 0.22
            }
            Kirigami.Icon {
                anchors.centerIn: parent
                width: 12; height: 12
                source: Qt.resolvedUrl("../icons/org.muddyblack.claudeusage.svg")
                isMask: true
                color: slot.iconColor
                opacity: 1.0
            }
        }

        PlasmaComponents.Label {
            text: Math.round(slot.pct) + "%"
            font.pixelSize: 12
            font.bold: true
            color: {
                if (slot.pct >= 90) return root.dangerColor
                if (slot.pct >= 70) return root.warningColor
                return Kirigami.Theme.textColor
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Popup row (segmented bar) ────────────────────────────────────────────
    component PopupRow: ColumnLayout {
        id: row
        property string label:    ""
        property string subtitle: ""
        property real   value:    0
        property color  barColor: Kirigami.Theme.positiveTextColor

        readonly property int segmentCount: 20

        Layout.fillWidth: true
        spacing: 6

        // Top row: label + percentage
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            PlasmaComponents.Label {
                text: row.label
                font.bold: true
                font.pixelSize: 13
                color: Kirigami.Theme.textColor
            }

            PlasmaComponents.Label {
                visible: row.subtitle !== ""
                text: "· " + row.subtitle
                font.pixelSize: 11
                opacity: 0.5
                color: Kirigami.Theme.textColor
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Label {
                text: Math.round(row.value) + "%"
                font.bold: true
                font.pixelSize: 14
                color: {
                    if (row.value >= 90) return root.dangerColor
                    if (row.value >= 70) return root.warningColor
                    return row.barColor
                }
            }
        }

        // Segmented bar (Antigravity style)
        Item {
            Layout.fillWidth: true
            height: 8

            Row {
                anchors.fill: parent
                spacing: 3

                Repeater {
                    model: row.segmentCount

                    Rectangle {
                        width: (row.width - (row.segmentCount - 1) * 3) / row.segmentCount
                        height: parent.height
                        radius: 2

                        readonly property real segmentThreshold: (index + 1) * (100 / row.segmentCount)
                        readonly property real prevThreshold:    index * (100 / row.segmentCount)
                        readonly property real fillRatio: {
                            if (row.value >= segmentThreshold) return 1.0
                            if (row.value <= prevThreshold)    return 0.0
                            return (row.value - prevThreshold) / (100 / row.segmentCount)
                        }
                        readonly property bool isFilled: fillRatio > 0

                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 1
                            width: Math.max(0, (parent.width - 2) * parent.fillRatio)
                            radius: 1.5

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.lighter(row.barColor, 1.15) }
                                GradientStop { position: 1.0; color: row.barColor }
                            }

                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
