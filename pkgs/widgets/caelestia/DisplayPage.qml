pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// Fills the "Display / Output configuration" slot upstream reserved but left
// commented out in PageRegistry.qml. Hyprland has no display manager of its
// own: arrangement lives in `monitor=` lines, so this page edits those. Apply
// pushes the layout live via `hyprctl keyword` (transient, gone on reload);
// Save writes ~/.config/hypr/{monitors,workspaces}.conf and reloads, which is
// what makes it stick — hyprland.nix sources both files after its own
// `monitor=` default, so the sourced lines win.
PageBase {
    id: root

    // Snap distance in logical pixels: how close an edge has to be dragged to
    // a neighbour's edge before it locks flush against it.
    readonly property int snapDist: 60

    readonly property string hyprDir: `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/hypr`

    // Working copies of every output, enabled or not. Deliberately *not*
    // re-read on a timer: a poll would overwrite a half-finished arrangement
    // mid-drag. Only a change in the set of connected outputs reloads it.
    property var outputs: []
    property int selectedIdx: 0
    property bool dirty
    property string status
    property bool statusIsError

    readonly property int monitorCount: Hypr.monitors?.values.length ?? 0
    readonly property var selected: outputs[selectedIdx] ?? null

    // Hyprland reports mode sizes in physical pixels but positions outputs in
    // logical ones, so every geometry comparison has to divide by scale first.
    function logicalW(o: var): int {
        return Math.round(o.w / o.scale);
    }

    function logicalH(o: var): int {
        return Math.round(o.h / o.scale);
    }

    function enabledOutputs(): var {
        return outputs.filter(o => !o.disabled);
    }

    // Bounding box of the arrangement, used to fit it into the canvas.
    readonly property var bounds: {
        const en = enabledOutputs();
        if (en.length === 0)
            return {
                x: 0,
                y: 0,
                w: 1,
                h: 1
            };

        let x0 = Infinity;
        let y0 = Infinity;
        let x1 = -Infinity;
        let y1 = -Infinity;
        for (const o of en) {
            x0 = Math.min(x0, o.x);
            y0 = Math.min(y0, o.y);
            x1 = Math.max(x1, o.x + logicalW(o));
            y1 = Math.max(y1, o.y + logicalH(o));
        }
        return {
            x: x0,
            y: y0,
            w: Math.max(1, x1 - x0),
            h: Math.max(1, y1 - y0)
        };
    }

    // outputs holds plain JS objects, so mutating a field raises no change
    // signal. Reassigning a shallow copy re-evaluates the bindings that read it.
    function touch(): void {
        dirty = true;
        outputs = outputs.slice();
    }

    function parseMode(mode: string): var {
        const m = mode.match(/^(\d+)x(\d+)@([\d.]+)/);
        if (!m)
            return null;
        return {
            w: parseInt(m[1]),
            h: parseInt(m[2]),
            refresh: m[3]
        };
    }

    function modeLabel(o: var): string {
        return `${o.w}x${o.h}@${Math.round(parseFloat(o.refresh))}`;
    }

    // Trim trailing zeroes: Hyprland accepts "1.333333" but writing "1.33" for
    // a scale it derived itself would make it reject the line as having no
    // clean divisor.
    function fmtNum(n: real): string {
        return String(Math.round(n * 1000000) / 1000000);
    }

    function transformLabel(t: int): string {
        return [qsTr("None"), qsTr("90°"), qsTr("180°"), qsTr("270°")][t] ?? qsTr("None");
    }

    // Menu assigns `active` on the row itself when an item is picked, which
    // drops whatever binding the row declared. Any row whose selection is
    // derived from state has to put that binding back, or it stops following
    // the state (most visibly: picking an output on the canvas would no
    // longer move the rows below it).
    function rebind(row: var, fn: var): void {
        Qt.callLater(() => row.active = Qt.binding(fn));
    }

    function moveTo(idx: int, nx: real, ny: real): void {
        const o = outputs[idx];
        if (!o)
            return;
        o.x = Math.round(nx);
        o.y = Math.round(ny);
        touch();
    }

    // Lock the dragged output's edges to its neighbours': for each axis try
    // flush-after, flush-before and same-edge alignment, nearest wins.
    function snap(idx: int): void {
        const o = outputs[idx];
        if (!o || o.disabled)
            return;

        const ow = logicalW(o);
        const oh = logicalH(o);
        let bestX = null;
        let bestY = null;

        for (let i = 0; i < outputs.length; i++) {
            if (i === idx)
                continue;
            const p = outputs[i];
            if (p.disabled)
                continue;

            const pw = logicalW(p);
            const ph = logicalH(p);

            for (const cand of [p.x + pw, p.x - ow, p.x, p.x + pw - ow]) {
                const d = Math.abs(cand - o.x);
                if (d <= snapDist && (!bestX || d < bestX.d))
                    bestX = {
                        v: cand,
                        d
                    };
            }
            for (const cand of [p.y + ph, p.y - oh, p.y, p.y + ph - oh]) {
                const d = Math.abs(cand - o.y);
                if (d <= snapDist && (!bestY || d < bestY.d))
                    bestY = {
                        v: cand,
                        d
                    };
            }
        }

        if (bestX)
            o.x = bestX.v;
        if (bestY)
            o.y = bestY.v;
    }

    // Hyprland is happiest with the arrangement anchored at 0x0.
    function normalise(): void {
        const en = enabledOutputs();
        if (en.length === 0)
            return;
        const dx = Math.min(...en.map(o => o.x));
        const dy = Math.min(...en.map(o => o.y));
        if (dx === 0 && dy === 0)
            return;
        for (const o of en) {
            o.x -= dx;
            o.y -= dy;
        }
    }

    function monitorLine(o: var): string {
        if (o.disabled)
            return `${o.name},disable`;
        const res = o.w > 0 && o.h > 0 ? `${o.w}x${o.h}@${o.refresh}` : "preferred";
        const transform = o.transform ? `,transform,${o.transform}` : "";
        return `${o.name},${res},${o.x}x${o.y},${fmtNum(o.scale)}${transform}`;
    }

    function apply(): void {
        if (outputs.length === 0)
            return;
        status = "";
        // --batch splits on ";", so the whole layout lands in one atomic-ish
        // call instead of N reconfigures that each shuffle windows around.
        applyProc.command = ["hyprctl", "--batch", outputs.map(o => `keyword monitor ${monitorLine(o)}`).join(" ; ")];
        applyProc.running = true;
    }

    function save(): void {
        if (outputs.length === 0)
            return;
        status = "";

        const monitors = ["# Written by caelestia Nexus → Display. Sourced from hyprland.conf.", ...outputs.map(o => `monitor = ${monitorLine(o)}`), ""].join("\n");

        const rules = Object.entries(wsAssign).filter(([, mon]) => mon).map(([ws, mon]) => `workspace = ${ws}, monitor:${mon}`);
        const workspaces = ["# Written by caelestia Nexus → Display. Sourced from hyprland.conf.", ...rules, ""].join("\n");

        monitorsFile.setText(monitors);
        workspacesFile.setText(workspaces);
        // Reload rather than replay keywords: it is the only way the workspace
        // rules take effect, and it proves the written files actually parse.
        reloadProc.running = true;
    }

    // Workspace → monitor rules, keyed by workspace id. Empty value = no rule
    // (Hyprland's own default, i.e. wherever it lands).
    property var wsAssign: ({})

    function setWsAssign(ws: int, mon: string): void {
        const next = Object.assign({}, wsAssign);
        if (mon)
            next[ws] = mon;
        else
            delete next[ws];
        wsAssign = next;
        dirty = true;
    }

    title: qsTr("Display")

    onMonitorCountChanged: query.running = true
    Component.onCompleted: query.running = true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // `monitors all` includes outputs currently disabled by config, which the
        // plain `monitors` list omits — without them there would be no way to
        // switch one back on.
        Process {
            id: query

            command: ["hyprctl", "-j", "monitors", "all"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const parsed = JSON.parse(text);
                        root.outputs = parsed.map(m => {
                            // Monitors routinely advertise the same mode twice
                        // (different pixel clocks, identical geometry), which
                        // Variants rejects as duplicate model entries.
                        const modes = [...new Set((m.availableModes ?? []).map(s => s.replace(/Hz$/, "")))];
                            // A never-enabled output reports 0x0; fall back to its
                            // first advertised mode so it has a size to draw.
                            const fallback = root.parseMode(modes[0] ?? "");
                            return {
                                name: m.name,
                                description: m.description ?? "",
                                x: m.x ?? 0,
                                y: m.y ?? 0,
                                w: m.width > 0 ? m.width : (fallback?.w ?? 0),
                                h: m.height > 0 ? m.height : (fallback?.h ?? 0),
                                refresh: m.refreshRate > 0 ? String(m.refreshRate.toFixed(2)) : (fallback?.refresh ?? ""),
                                scale: m.scale > 0 ? m.scale : 1,
                                transform: (m.transform ?? 0) % 4,
                                disabled: !!m.disabled,
                                modes
                            };
                        });
                        root.selectedIdx = Math.min(root.selectedIdx, Math.max(0, root.outputs.length - 1));
                        root.dirty = false;
                        root.status = "";
                    } catch (e) {
                        root.outputs = [];
                        root.statusIsError = true;
                        root.status = qsTr("Could not read the monitor list from Hyprland.");
                    }
                }
            }
        }

        Process {
            id: applyProc

            stdout: StdioCollector {
                onStreamFinished: {
                    // hyprctl exits 0 even when it rejects a keyword; the refusal
                    // only shows up in its output.
                    const t = text.trim();
                    const bad = t && !/^(ok\s*)+$/.test(t);
                    root.statusIsError = bad;
                    root.status = bad ? t.split("\n")[0] : qsTr("Applied. Not saved yet — it reverts on reload.");
                }
            }
        }

        Process {
            id: reloadProc

            command: ["hyprctl", "reload"]
            onExited: code => {
                root.statusIsError = code !== 0;
                root.status = code === 0 ? qsTr("Saved to %1 and reloaded.").arg(Paths.shortenHome(`${root.hyprDir}/monitors.conf`)) : qsTr("Saved, but reloading Hyprland failed.");
                if (code === 0)
                    root.dirty = false;
            }
        }

        FileView {
            id: monitorsFile

            path: `${root.hyprDir}/monitors.conf`
            // Only ever written, never read; before the first save (or a
            // home-manager switch) it legitimately does not exist yet.
            printErrors: false
            atomicWrites: true
        }

        FileView {
            id: workspacesFile

            path: `${root.hyprDir}/workspaces.conf`
            preload: true
            printErrors: false
            atomicWrites: true
            // Seed the picker from whatever rules are already on disk.
            onLoaded: {
                const next = {};
                for (const line of text().split("\n")) {
                    const m = line.match(/^\s*workspace\s*=\s*(\d+)\s*,\s*monitor:\s*(\S+?)\s*$/);
                    if (m)
                        next[m[1]] = m[2];
                }
                root.wsAssign = next;
            }
        }

        // Arrangement canvas
        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: Math.max(180, root.width * 0.34)

            Item {
                id: canvas

                anchors.fill: parent
                anchors.margins: Tokens.padding.large

                // Fit the whole arrangement with a little breathing room, so
                // dragging an output outwards does not instantly clip it.
                readonly property real f: Math.min(width / root.bounds.w, height / root.bounds.h) * 0.82
                readonly property real offX: (width - root.bounds.w * f) / 2
                readonly property real offY: (height - root.bounds.h * f) / 2

                StyledText {
                    anchors.centerIn: parent
                    visible: root.outputs.length === 0
                    text: qsTr("No outputs detected")
                    color: Colours.palette.m3outlineVariant
                }

                Repeater {
                    model: root.outputs.length

                    StyledRect {
                        id: tile

                        required property int index

                        readonly property var out: root.outputs[index]
                        readonly property bool isSelected: root.selectedIdx === index

                        visible: out && !out.disabled
                        x: out ? (out.x - root.bounds.x) * canvas.f + canvas.offX : 0
                        y: out ? (out.y - root.bounds.y) * canvas.f + canvas.offY : 0
                        width: out ? root.logicalW(out) * canvas.f : 0
                        height: out ? root.logicalH(out) * canvas.f : 0

                        radius: Tokens.rounding.small
                        color: isSelected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHighest
                        border.width: isSelected ? 2 : 1
                        border.color: isSelected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - Tokens.padding.small * 2
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.out?.name ?? ""
                                color: tile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                visible: tile.height > implicitHeight * 3
                                text: tile.out ? `${tile.out.w}x${tile.out.h}` : ""
                                color: tile.isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            property bool dragging
                            // Anchor the drag in canvas coordinates: the tile
                            // itself moves under the cursor, so item-relative
                            // deltas would feed back on themselves.
                            property real startPX
                            property real startPY
                            property int startOX
                            property int startOY

                            onPressed: e => {
                                root.selectedIdx = tile.index;
                                const p = mapToItem(canvas, e.x, e.y);
                                startPX = p.x;
                                startPY = p.y;
                                startOX = tile.out.x;
                                startOY = tile.out.y;
                                dragging = true;
                            }
                            onPositionChanged: e => {
                                if (!dragging || canvas.f <= 0)
                                    return;
                                const p = mapToItem(canvas, e.x, e.y);
                                root.moveTo(tile.index, startOX + (p.x - startPX) / canvas.f, startOY + (p.y - startPY) / canvas.f);
                            }
                            onReleased: {
                                if (!dragging)
                                    return;
                                dragging = false;
                                root.snap(tile.index);
                                root.normalise();
                                root.touch();
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("Drag an output to place it. Edges snap to their neighbours.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        // Per-output settings
        SectionHeader {
            text: qsTr("Output")
        }

        SelectRow {
            id: outputRow

            first: true
            label: qsTr("Output")
            subtext: root.selected?.description ?? ""
            menuItems: outputItems.instances
            active: menuItems[root.selectedIdx] ?? null
            fallbackText: root.selected?.name ?? qsTr("None")
            fallbackIcon: "monitor"
            onSelected: item => {
                root.rebind(outputRow, () => outputRow.menuItems[root.selectedIdx] ?? null);
                root.selectedIdx = menuItems.indexOf(item);
            }

            Variants {
                id: outputItems

                model: root.outputs

                MenuItem {
                    required property var modelData
                    text: modelData.name
                    icon: modelData.disabled ? "visibility_off" : "monitor"
                }
            }
        }

        SelectRow {
            id: modeRow

            readonly property string currentMode: `${root.selected?.w}x${root.selected?.h}@${root.selected?.refresh}`

            label: qsTr("Resolution")
            subtext: qsTr("Mode and refresh rate")
            enabled: !!root.selected && root.selected.modes.length > 0
            menuItems: modeItems.instances
            active: menuItems.find(i => i.modelData === currentMode) ?? null
            fallbackText: root.selected ? root.modeLabel(root.selected) : ""
            fallbackIcon: "aspect_ratio"
            onSelected: item => {
                root.rebind(modeRow, () => modeRow.menuItems.find(i => i.modelData === modeRow.currentMode) ?? null);
                const mode = root.parseMode(item.modelData);
                const o = root.selected;
                if (!mode || !o)
                    return;
                o.w = mode.w;
                o.h = mode.h;
                o.refresh = mode.refresh;
                root.normalise();
                root.touch();
            }

            Variants {
                id: modeItems

                model: root.selected?.modes ?? []

                MenuItem {
                    required property var modelData
                    text: modelData
                    icon: "aspect_ratio"
                }
            }
        }

        SliderRow {
            icon: "zoom_in"
            label: qsTr("Scale")
            enabled: !!root.selected
            // 0.5x–3.0x in twentieths: Hyprland rejects a scale that does not
            // divide the mode into whole pixels, and coarse steps hit far
            // fewer of those than a free-running slider does.
            value: root.selected ? (root.selected.scale - 0.5) / 2.5 : 0
            valueLabel: root.selected ? root.fmtNum(root.selected.scale) : ""
            onMoved: v => {
                const o = root.selected;
                if (!o)
                    return;
                o.scale = Math.round((0.5 + v * 2.5) * 20) / 20;
                root.normalise();
                root.touch();
            }
        }

        SelectRow {
            id: rotationRow

            label: qsTr("Rotation")
            enabled: !!root.selected
            menuItems: transformItems.instances
            active: menuItems[root.selected?.transform ?? 0] ?? null
            fallbackText: qsTr("None")
            fallbackIcon: "screen_rotation"
            onSelected: item => {
                root.rebind(rotationRow, () => rotationRow.menuItems[root.selected?.transform ?? 0] ?? null);
                const o = root.selected;
                const t = menuItems.indexOf(item);
                if (!o || t < 0)
                    return;
                // A quarter turn swaps the logical footprint, so the tile in
                // the canvas has to change shape with it.
                if ((o.transform % 2) !== (t % 2)) {
                    const w = o.w;
                    o.w = o.h;
                    o.h = w;
                }
                o.transform = t;
                root.normalise();
                root.touch();
            }

            Variants {
                id: transformItems

                model: [0, 1, 2, 3]

                MenuItem {
                    required property var modelData
                    text: root.transformLabel(modelData)
                    icon: "screen_rotation"
                }
            }
        }

        ToggleRow {
            id: enabledToggle

            last: true
            text: qsTr("Enabled")
            subtext: qsTr("Turn this output off entirely")
            // Refuse to switch off the last one standing: with every output
            // disabled there is no surface left to switch it back on from.
            disabled: !root.selected || (!root.selected.disabled && root.enabledOutputs().length < 2)
            checked: !!root.selected && !root.selected.disabled
            onToggled: {
                const o = root.selected;
                const on = checked;
                // Switch assigns checked itself, which drops the binding
                // above — restore it or the toggle stops tracking whichever
                // output is selected.
                Qt.callLater(() => {
                    enabledToggle.checked = Qt.binding(() => !!root.selected && !root.selected.disabled);
                });
                if (!o)
                    return;
                o.disabled = !on;
                root.normalise();
                root.touch();
            }
        }

        // Workspaces
        SectionHeader {
            text: qsTr("Workspaces")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.extraSmall
            Layout.leftMargin: Tokens.padding.small
            text: qsTr("Pin a workspace to an output. Takes effect on save.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: 10

            SelectRow {
                id: wsRow

                required property int index
                readonly property int ws: index + 1

                first: index === 0
                last: index === 9
                label: qsTr("Workspace %1").arg(ws)
                menuItems: wsItems.instances
                active: menuItems.find(i => i.modelData === (root.wsAssign[wsRow.ws] ?? "")) ?? null
                fallbackText: qsTr("Automatic")
                fallbackIcon: "auto_awesome"
                menuOnTop: index > 6
                onSelected: item => {
                    root.rebind(wsRow, () => wsRow.menuItems.find(i => i.modelData === (root.wsAssign[wsRow.ws] ?? "")) ?? null);
                    root.setWsAssign(wsRow.ws, item.modelData);
                }

                Variants {
                    id: wsItems

                    model: ["", ...root.outputs.map(o => o.name)]

                    MenuItem {
                        required property var modelData
                        text: modelData || qsTr("Automatic")
                        icon: modelData ? "monitor" : "auto_awesome"
                    }
                }
            }
        }

        // Actions
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.largeIncreased
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.small
                visible: root.status || root.dirty
                text: root.status || qsTr("Unsaved changes")
                color: root.statusIsError && root.status ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            TextButton {
                type: TextButton.Tonal
                isRound: true
                horizontalPadding: Tokens.padding.largeIncreased
                verticalPadding: Tokens.padding.medium
                text: qsTr("Apply")
                disabled: root.outputs.length === 0
                onClicked: root.apply()
            }

            TextButton {
                type: TextButton.Filled
                isRound: true
                horizontalPadding: Tokens.padding.largeIncreased
                verticalPadding: Tokens.padding.medium
                text: qsTr("Save to config")
                disabled: root.outputs.length === 0
                onClicked: root.save()
            }
        }
    }
}
