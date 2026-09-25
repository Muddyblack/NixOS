// Quickshell port of prayag2's Modern Clock plasmoid (the one the Plasma
// desktop uses), so both sessions show the same clock. Values match that
// widget's main.xml defaults. The fonts come from the plasmoid package and
// are passed in through MODERN_CLOCK_FONTS.
//
// With MODERN_CLOCK_WALLPAPER_COLORS=1 the text takes Caelestia's Material
// You palette (the colours its own desktop clock uses) instead of plain
// white, and fades to the new palette whenever the wallpaper changes.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string fontDir: Quickshell.env("MODERN_CLOCK_FONTS") || ""
    readonly property bool wallpaperColors: Quickshell.env("MODERN_CLOCK_WALLPAPER_COLORS") === "1"
    // Center of the clock as a fraction of screen height. The Plasma widget
    // sits at y 288..544 on a 1080p screen.
    readonly property real verticalCenter: 0.385
    readonly property bool use24Hour: false
    readonly property string timeCharacter: "-"
    readonly property string dateFormat: "dd MMM yyyy"

    // Caelestia writes the generated scheme here; the same file drives its
    // own clock. Missing or unreadable means plain white, like Plasma.
    property var scheme: null
    readonly property bool useScheme: wallpaperColors && scheme !== null
    // Like Caelestia's clock: the lighter container tones in light mode.
    readonly property bool lightMode: useScheme && scheme.mode === "light"
    readonly property color primary: schemeColor(lightMode ? "primaryContainer" : "primary")
    readonly property color secondary: schemeColor(lightMode ? "secondaryContainer" : "secondary")
    readonly property color tertiary: schemeColor(lightMode ? "tertiaryContainer" : "tertiary")

    function schemeColor(name: string): color {
        const hex = useScheme ? scheme.colours[name] : undefined;
        return hex ? "#" + hex : "#ffffff";
    }

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/caelestia/scheme.json"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.scheme = JSON.parse(text());
            } catch (e) {
                root.scheme = null;
            }
        }
        onLoadFailed: root.scheme = null
    }

    FontLoader {
        id: anurati
        source: "file://" + root.fontDir + "/Anurati.otf"
    }
    FontLoader {
        id: poppins
        source: "file://" + root.fontDir + "/Poppins.ttf"
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Text filled with a horizontal gradient: the text is only the mask.
    component GradientText: Item {
        id: gt

        property alias text: label.text
        property alias font: label.font
        property color from: "#ffffff"
        property color via: "#ffffff"
        property color to: "#ffffff"

        implicitWidth: label.implicitWidth
        implicitHeight: label.implicitHeight

        Behavior on from { ColorAnimation { duration: 600 } }
        Behavior on via { ColorAnimation { duration: 600 } }
        Behavior on to { ColorAnimation { duration: 600 } }

        Text {
            id: label
            anchors.fill: parent
            visible: false
            layer.enabled: true
        }
        Rectangle {
            id: fill
            anchors.fill: parent
            visible: false
            layer.enabled: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: gt.from }
                GradientStop { position: 0.5; color: gt.via }
                GradientStop { position: 1.0; color: gt.to }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: fill
            maskEnabled: true
            maskSource: label
            // Keep the glyphs' antialiased edges instead of a hard cutoff. A
            // threshold of 0 would let transparent pixels through as well.
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "modern-clock"
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            // Click-through: an empty mask lets input fall to the desktop.
            mask: Region {}

            anchors.top: true
            margins.top: Math.round(modelData.height * root.verticalCenter - implicitHeight / 2)
            implicitWidth: container.implicitWidth + 80
            implicitHeight: container.implicitHeight + 40

            Column {
                id: container
                anchors.centerIn: parent
                spacing: 5
                // Plasma draws this widget with ShadowBackground; a soft shadow
                // keeps the text readable on bright wallpapers.
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000"
                    shadowBlur: 0.6
                    shadowVerticalOffset: 2
                }

                GradientText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "dddd").toUpperCase()
                    font.family: anurati.name
                    font.pixelSize: 72
                    font.letterSpacing: 17
                    from: root.primary
                    via: root.tertiary
                    to: root.secondary
                }
                GradientText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, root.dateFormat).toUpperCase()
                    font.family: poppins.name
                    font.pixelSize: 19
                    font.letterSpacing: 3
                    from: root.secondary
                    via: root.secondary
                    to: root.secondary
                }
                GradientText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.timeCharacter + " " + Qt.formatTime(clock.date, root.use24Hour ? "hh:mm" : "hh:mm AP") + " " + root.timeCharacter
                    font.family: poppins.name
                    font.pixelSize: 19
                    font.letterSpacing: 3
                    from: root.primary
                    via: root.primary
                    to: root.primary
                }
            }
        }
    }
}
