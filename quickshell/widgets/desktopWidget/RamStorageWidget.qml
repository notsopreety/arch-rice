import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../core"
import "../../theme"
import "../../components"
import "../../services"
import "../widgetCanvas"

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property int styleMode: 1 // 1: Combined Cards, 2: RAM Only, 3: Storage Only

    property real customWidth: -1
    property real customHeight: -1

    // ── Glassmorphism Toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); } catch(e) {} }
        onLoaded: root.glassmorphism = true
        onLoadFailed: root.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    readonly property real defaultWidth: 260 * Appearance.effectiveScale
    readonly property real defaultHeight: (root.styleMode === 1 ? 160 : 74) * Appearance.effectiveScale

    width: customWidth > 0 ? (customWidth * Appearance.effectiveScale) : defaultWidth
    height: customHeight > 0 ? (customHeight * Appearance.effectiveScale) : defaultHeight

    x: settingsX >= 0 ? settingsX : 40 * Appearance.effectiveScale
    y: settingsY >= 0 ? settingsY : 320 * Appearance.effectiveScale
    visible: isActive

    Behavior on width { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    scale: dragArea.pressed ? 0.98 : (dragArea.containsMouse ? 1.015 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // ── Settings Persistence ──
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let s = data.ramStorageWidget || data.ramStorage || {};
            if (s.isActive !== undefined) root.isActive = s.isActive;
            if (s.x !== undefined) root.settingsX = s.x;
            if (s.y !== undefined) root.settingsY = s.y;
            if (s.styleMode !== undefined) root.styleMode = s.styleMode;
            if (s.width !== undefined && s.width > 0) root.customWidth = s.width;
            if (s.height !== undefined && s.height > 0) root.customHeight = s.height;
        } catch(e) {}
    }

    Timer { id: reloadTimer; interval: 150; running: false; repeat: false; onTriggered: settingsFile.reload() }
    FileView { id: settingsFile; path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"; watchChanges: true; preload: true; onLoaded: root.loadSettings(text()); onFileChanged: reloadTimer.restart() }
    Process { id: saveSettingsProc }

    function saveSettings(newX, newY, newStyle, newW, newH) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "s = data.setdefault('ramStorageWidget', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("s['x'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("s['y'] = " + Math.round(newY));
        let sm = (newStyle !== undefined) ? newStyle : root.styleMode;
        updates.push("s['styleMode'] = " + sm);
        if (newW !== undefined && newW > 0) updates.push("s['width'] = " + Math.round(newW));
        else if (newW === -1) updates.push("s.pop('width', None)");
        if (newH !== undefined && newH > 0) updates.push("s['height'] = " + Math.round(newH));
        else if (newH === -1) updates.push("s.pop('height', None)");
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; f = open(tmp, 'w'); json.dump(data, f, indent=2); f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    function cycleNextStyle() {
        root.customWidth = -1;
        root.customHeight = -1;
        root.styleMode = (root.styleMode % 3) + 1;
        root.saveSettings(root.x, root.y, root.styleMode, -1, -1);
    }

    // ── Metric Values & Formatting ──
    readonly property real ramUsedGB: SystemUsage.memUsed / 1073741824
    readonly property real ramTotalGB: SystemUsage.memTotal > 0 ? (SystemUsage.memTotal / 1073741824) : 16
    readonly property real ramPerc: SystemUsage.memPerc > 0 ? SystemUsage.memPerc : (ramUsedGB / ramTotalGB)

    readonly property real diskUsedGB: SystemUsage.diskUsed / 1073741824
    readonly property real diskTotalGB: SystemUsage.diskTotal > 0 ? (SystemUsage.diskTotal / 1073741824) : 128
    readonly property real diskPerc: SystemUsage.diskPerc > 0 ? SystemUsage.diskPerc : (diskUsedGB / diskTotalGB)

    // ── Material You / Dynamic Theme Colors ──
    readonly property color cardBgColor: root.glassmorphism
        ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.45)
        : Theme.surfaceContainerHigh
    readonly property color pillBgColor: Theme.primary
    readonly property color pillTextColor: Theme.onPrimary
    readonly property color iconColor: Theme.primary

    // ── Drag & Click Area ──
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        hoverEnabled: true
        cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 10

        onReleased: {
            if (drag.active) {
                root.saveSettings(root.x, root.y, root.styleMode, root.customWidth, root.customHeight);
            }
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.cycleNextStyle();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14 * Appearance.effectiveScale

        // ══════════════════════════════════════════════════════════════════════
        // RAM Card: Left Pill (Right 2 edges rounded) & Right CPU/RAM Icon
        // ══════════════════════════════════════════════════════════════════════
        Item {
            id: ramCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.styleMode === 1 || root.styleMode === 2

            // Drop shadow
            Rectangle {
                anchors.fill: ramBg
                anchors.margins: -1
                anchors.verticalCenterOffset: 5 * Appearance.effectiveScale
                radius: ramBg.radius
                color: Qt.rgba(0, 0, 0, 0.35)
            }

            Rectangle {
                id: ramBg
                anchors.fill: parent
                radius: Math.min(22 * Appearance.effectiveScale, height * 0.32)
                color: root.cardBgColor
                border.color: "transparent"
                border.width: 0
                clip: true

                // Left Inner Pill (Right 2 corners rounded; connects flush to left edge)
                Item {
                    id: ramPillContainer
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height - (ramBg.radius * 2)
                    width: Math.max(ramText.implicitWidth + 36 * Appearance.effectiveScale, Math.min(parent.width - 64 * Appearance.effectiveScale, parent.width * Math.max(0.48, Math.min(0.80, root.ramPerc))))

                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root.pillBgColor

                        // Square overlay covering the left side so left edges remain completely flat
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.radius
                            color: root.pillBgColor
                        }

                        // Text with guaranteed padding inside pill
                        Text {
                            id: ramText
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -2 * Appearance.effectiveScale
                            text: Math.round(root.ramUsedGB) + " GB / " + Math.round(root.ramTotalGB) + " GB"
                            font.family: Theme.font.family
                            font.pixelSize: Math.max(11, Math.min(14 * Appearance.effectiveScale, parent.height * 0.38))
                            font.weight: Font.Bold
                            color: root.pillTextColor
                        }
                    }
                }

                // Right Icon (developer_board / memory)
                DankIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * Appearance.effectiveScale
                    anchors.verticalCenter: parent.verticalCenter
                    name: "developer_board"
                    size: Math.max(18, Math.round(parent.height * 0.34))
                    color: root.iconColor
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════════
        // Storage Card: Left Storage Icon & Right Pill (Left 2 edges rounded)
        // ══════════════════════════════════════════════════════════════════════
        Item {
            id: storageCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.styleMode === 1 || root.styleMode === 3

            // Drop shadow
            Rectangle {
                anchors.fill: storageBg
                anchors.margins: -1
                anchors.verticalCenterOffset: 5 * Appearance.effectiveScale
                radius: storageBg.radius
                color: Qt.rgba(0, 0, 0, 0.35)
            }

            Rectangle {
                id: storageBg
                anchors.fill: parent
                radius: Math.min(22 * Appearance.effectiveScale, height * 0.32)
                color: root.cardBgColor
                border.color: "transparent"
                border.width: 0
                clip: true

                // Left Storage Icon (storage / hdd)
                DankIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 18 * Appearance.effectiveScale
                    anchors.verticalCenter: parent.verticalCenter
                    name: "storage"
                    size: Math.max(18, Math.round(parent.height * 0.34))
                    color: root.iconColor
                }

                // Right Inner Pill (Left 2 corners rounded; connects flush to right edge)
                Item {
                    id: storagePillContainer
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height - (storageBg.radius * 2)
                    width: Math.max(storageText.implicitWidth + 36 * Appearance.effectiveScale, Math.min(parent.width - 64 * Appearance.effectiveScale, parent.width * Math.max(0.48, Math.min(0.80, root.diskPerc))))

                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: root.pillBgColor

                        // Square overlay covering the right side so right edges remain completely flat
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.radius
                            color: root.pillBgColor
                        }

                        // Text with guaranteed padding inside pill
                        Text {
                            id: storageText
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 2 * Appearance.effectiveScale
                            text: Math.round(root.diskUsedGB) + " GB / " + Math.round(root.diskTotalGB) + " GB"
                            font.family: Theme.font.family
                            font.pixelSize: Math.max(11, Math.min(14 * Appearance.effectiveScale, parent.height * 0.38))
                            font.weight: Font.Bold
                            color: root.pillTextColor
                        }
                    }
                }
            }
        }
    }

    WidgetResizeFrame {
        id: resizeFrame
        target: root
        widgetName: "RAM & Storage"
        minWidth: 220 * Appearance.effectiveScale
        minHeight: (root.styleMode === 1 ? 120 : 54) * Appearance.effectiveScale
        maxWidth: 700 * Appearance.effectiveScale
        maxHeight: 500 * Appearance.effectiveScale

        onResized: (newW, newH) => {
            root.customWidth = Math.round(newW / Appearance.effectiveScale);
            root.customHeight = Math.round(newH / Appearance.effectiveScale);
        }
        onResizeEnded: (finalW, finalH) => {
            root.customWidth = Math.round(finalW / Appearance.effectiveScale);
            root.customHeight = Math.round(finalH / Appearance.effectiveScale);
            root.saveSettings(root.x, root.y, root.styleMode, root.customWidth, root.customHeight);
        }
        onResetRequested: {
            root.customWidth = -1;
            root.customHeight = -1;
            root.saveSettings(root.x, root.y, root.styleMode, -1, -1);
        }
    }
}
