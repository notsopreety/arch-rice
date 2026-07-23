import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../core"
import "../../theme"
import "../../components"

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property int styleMode: 3 // 1: Minimal, 2: Vertical Badges, 3: Bubble Graph

    // ── Glassmorphism Toggle (Matching Clock.qml) ─────────────────────────
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

    property int totalTimeSeconds: 0
    property var topApps: []
    property var appsData: []

    // Snug widget dimensions removing all remaining useless padding
    width: styleMode === 1 ? (155 * Appearance.effectiveScale) : (styleMode === 2 ? (175 * Appearance.effectiveScale) : (210 * Appearance.effectiveScale))
    height: styleMode === 1 ? (135 * Appearance.effectiveScale) : (styleMode === 2 ? (185 * Appearance.effectiveScale) : (165 * Appearance.effectiveScale))

    x: settingsX >= 0 ? settingsX : (Appearance.sizes.screen.width - width - 40)
    y: settingsY >= 0 ? settingsY : 120

    visible: isActive

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // Dynamic Colors: Matugen Theme & Glassmorphism
    property color bgColor: root.glassmorphism 
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.45) 
        : Theme.surfaceContainer

    // FULLY OPAQUE Bubble Palette
    readonly property var bubbleColors: [
        Qt.rgba(0.96, 0.96, 0.98, 1.0), // Solid Opaque White/Off-White (#F5F5F9)
        Qt.rgba(Theme.primary.r * 0.45 + 0.55, Theme.primary.g * 0.45 + 0.55, Theme.primary.b * 0.45 + 0.55, 1.0), // Solid Opaque Muted Tint
        Theme.primary // Solid Opaque Primary Accent
    ]

    // Cycle Style (1 -> 2 -> 3 -> 1)
    function cycleNextStyle() {
        root.styleMode = (root.styleMode % 3) + 1;
        root.saveSettings(root.x, root.y, root.styleMode);
    }

    // Load Settings from settings.json
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let st = data.screentime || data.screentimeWidget || {};
            if (st.isActive !== undefined) root.isActive = st.isActive;
            if (st.screentimeX !== undefined) root.settingsX = st.screentimeX;
            else if (st.winX !== undefined) root.settingsX = st.winX;
            
            if (st.screentimeY !== undefined) root.settingsY = st.screentimeY;
            else if (st.winY !== undefined) root.settingsY = st.winY;
            
            if (st.screentimeStyle !== undefined) root.styleMode = st.screentimeStyle;
            else if (st.styleMode !== undefined) root.styleMode = st.styleMode;
        } catch(e) {
            console.log("[ScreenTimeWidget] Error loading settings:", e);
        }
    }

    Timer {
        id: reloadTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: settingsFile.reload()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true
        onLoaded: root.loadSettings(text())
        onFileChanged: reloadTimer.restart()
    }

    Process {
        id: saveSettingsProc
        running: false
    }

    // Atomic Save Settings to settings.json
    function saveSettings(newX, newY, newStyle) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "st = data.setdefault('screentime', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("st['screentimeX'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("st['screentimeY'] = " + Math.round(newY));
        if (newStyle !== undefined) updates.push("st['screentimeStyle'] = " + Math.round(newStyle));
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; " +
               "f = open(tmp, 'w'); " +
               "json.dump(data, f, indent=2); " +
               "f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    Process {
        id: forceSaveProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/screentime_daemon.py", "--flush"]
        running: false
    }

    Process {
        id: openWindowProc
        command: ["quickshell", "ipc", "call", "quickshell", "run", "screentime"]
        running: false
    }

    // App Friendly Name Mapping
    Process {
        id: appFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/get_apps.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.appsData = JSON.parse(text);
                    root.updateData();
                } catch(e) {}
            }
        }
    }

    // Today's Screen Time File Watcher
    FileView {
        id: screentimeDataFile
        path: Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json"
        watchChanges: true
        onLoaded: root.updateData()
    }

    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: {
            screentimeDataFile.path = Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json";
        }
    }

    function formatCompactTime(secs) {
        let m = Math.floor(secs / 60);
        let h = Math.floor(m / 60);
        let remainM = m % 60;
        if (h > 0) return h + "h " + remainM + "m";
        if (remainM > 0) return remainM + "m";
        return Math.floor(secs) + "s";
    }

    function updateData() {
        try {
            let txt = screentimeDataFile.text().trim();
            if (txt.length === 0) return;
            let obj = JSON.parse(txt);
            
            let arr = [];
            let total = 0;
            for (let k in obj) {
                let t = obj[k].time || 0;
                let name = k;
                let lowerK = k.toLowerCase();
                
                for (let i = 0; i < root.appsData.length; i++) {
                    let app = root.appsData[i];
                    if (app.id.toLowerCase().includes(lowerK) || app.name.toLowerCase().includes(lowerK) || app.cmd.toLowerCase().includes(lowerK)) {
                        name = app.name;
                        break;
                    }
                }
                if (lowerK === "org.quickshell") name = "Quickshell";
                
                arr.push({ rawName: k, name: name, time: t });
                total += t;
            }
            
            arr.sort((a, b) => b.time - a.time);
            root.totalTimeSeconds = total;
            root.topApps = arr.slice(0, 3);
        } catch(e) {
            console.log("[ScreenTimeWidget] Update error:", e);
        }
    }

    // Material Container / Glassmorphic Card
    Rectangle {
        id: card
        anchors.fill: parent
        color: root.bgColor
        radius: 20 * Appearance.effectiveScale
        border.color: root.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Theme.outlineVariant
        border.width: 1
        clip: true

        scale: dragArea.pressed ? 0.98 : (dragArea.containsMouse ? 1.01 : 1.0)
        Behavior on scale { NumberAnimation { duration: 150 } }

        // Glossy Reflection Overlay
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.45
            radius: parent.radius
            visible: root.glassmorphism
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            hoverEnabled: true
            cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    if (!drag.active) {
                        openWindowProc.running = true;
                    }
                } else if (mouse.button === Qt.RightButton) {
                    root.cycleNextStyle();
                }
            }
            onReleased: {
                if (drag.active) {
                    root.saveSettings(root.x, root.y, root.styleMode);
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 2 * Appearance.effectiveScale

                Text {
                    text: "Screen time"
                    font.family: Theme.font.family
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "white"
                    Layout.fillWidth: true
                }

                DankIcon {
                    id: refreshBtn
                    name: "refresh"
                    size: 15 * Appearance.effectiveScale
                    color: Qt.rgba(255, 255, 255, 0.8)
                    property bool spinning: false

                    RotationAnimation on rotation {
                        running: refreshBtn.spinning
                        from: 0; to: 360; duration: 1000
                        loops: Animation.Infinite
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            refreshBtn.spinning = true;
                            forceSaveProc.running = true;
                            screentimeDataFile.path = Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json";
                            refreshSpinTimer.restart();
                        }
                    }
                    Timer { id: refreshSpinTimer; interval: 1000; onTriggered: refreshBtn.spinning = false }
                }
            }

            // STYLE 1: Minimal Overall
            Item {
                visible: root.styleMode === 1
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: root.formatCompactTime(root.totalTimeSeconds)
                    font.family: Theme.font.family
                    font.pixelSize: 28 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: "white"
                }
            }

            // STYLE 2: Vertical List Badges
            ColumnLayout {
                visible: root.styleMode === 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6 * Appearance.effectiveScale

                Text {
                    text: root.formatCompactTime(root.totalTimeSeconds)
                    font.family: Theme.font.family
                    font.pixelSize: 24 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: "white"
                }

                Repeater {
                    model: root.topApps
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale

                        Rectangle {
                            width: 44 * Appearance.effectiveScale
                            height: 24 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: root.bubbleColors[index % 3]

                            Text {
                                anchors.centerIn: parent
                                text: root.formatCompactTime(modelData.time)
                                font.family: Theme.font.family
                                font.pixelSize: 10 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: "#121415"
                            }
                        }

                        Text {
                            text: modelData.name
                            font.family: Theme.font.family
                            font.pixelSize: 12 * Appearance.effectiveScale
                            color: "white"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }

            // STYLE 3: Bubble Graph (Perfectly Snug & Compact)
            RowLayout {
                visible: root.styleMode === 3
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Left Column: Total Time + Legend
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4 * Appearance.effectiveScale

                    Text {
                        text: root.formatCompactTime(root.totalTimeSeconds)
                        font.family: Theme.font.family
                        font.pixelSize: 24 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: "white"
                        Layout.bottomMargin: 2 * Appearance.effectiveScale
                    }

                    property var legendApps: {
                        if (root.topApps.length === 3) {
                            return [
                                { app: root.topApps[2], colorIndex: 2 },
                                { app: root.topApps[1], colorIndex: 1 },
                                { app: root.topApps[0], colorIndex: 0 }
                            ];
                        } else if (root.topApps.length === 2) {
                            return [
                                { app: root.topApps[1], colorIndex: 1 },
                                { app: root.topApps[0], colorIndex: 0 }
                            ];
                        } else if (root.topApps.length === 1) {
                            return [
                                { app: root.topApps[0], colorIndex: 0 }
                            ];
                        }
                        return [];
                    }

                    Repeater {
                        model: parent.legendApps
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6 * Appearance.effectiveScale

                            Rectangle {
                                width: 8 * Appearance.effectiveScale
                                height: 8 * Appearance.effectiveScale
                                radius: 4 * Appearance.effectiveScale
                                color: root.bubbleColors[modelData.colorIndex]
                            }

                            Text {
                                text: modelData.app.name
                                font.family: Theme.font.family
                                font.pixelSize: 12 * Appearance.effectiveScale
                                color: "white"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                }

                // Right Column (Snug Bubble Overlap Bounds)
                Item {
                    Layout.preferredWidth: 95 * Appearance.effectiveScale
                    Layout.fillHeight: true

                    // Bubble 3 (Top Left - #3 App, Smallest, Bright Cyan)
                    Rectangle {
                        visible: root.topApps.length > 2
                        width: 42 * Appearance.effectiveScale
                        height: 42 * Appearance.effectiveScale
                        radius: width / 2
                        color: root.bubbleColors[2]
                        z: 3
                        
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 36 * Appearance.effectiveScale
                        anchors.topMargin: -18 * Appearance.effectiveScale

                        Text {
                            anchors.centerIn: parent
                            text: root.topApps.length > 2 ? root.formatCompactTime(root.topApps[2].time) : ""
                            font.family: Theme.font.family
                            font.pixelSize: 10 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#121415"
                        }
                    }

                    // Bubble 2 (Middle - #2 App, Medium, Solid Muted Tint)
                    Rectangle {
                        visible: root.topApps.length > 1
                        width: 60 * Appearance.effectiveScale
                        height: 60 * Appearance.effectiveScale
                        radius: width / 2
                        color: root.bubbleColors[1]
                        z: 2
                        
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        anchors.topMargin: 16 * Appearance.effectiveScale

                        Text {
                            anchors.centerIn: parent
                            text: root.topApps.length > 1 ? root.formatCompactTime(root.topApps[1].time) : ""
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#121415"
                        }
                    }

                    // Bubble 1 (Bottom Right - #1 App, Largest, Solid White)
                    Rectangle {
                        visible: root.topApps.length > 0
                        width: 80 * Appearance.effectiveScale
                        height: 80 * Appearance.effectiveScale
                        radius: width / 2
                        color: root.bubbleColors[0]
                        z: 1
                        
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -6 * Appearance.effectiveScale
                        anchors.topMargin: 54 * Appearance.effectiveScale

                        Text {
                            anchors.centerIn: parent
                            text: root.topApps.length > 0 ? root.formatCompactTime(root.topApps[0].time) : ""
                            font.family: Theme.font.family
                            font.pixelSize: 12 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#121415"
                        }
                    }
                }
            }
        }
    }
}
