import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../core"
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property int styleMode: 1 // 1: Small, 2: Medium, 3: Large
    property int shapeMode: 1 // 1: Diagonal Organic Pebble, 2: Horizontal Pill Stadium

    // ── Glassmorphism Toggle ─────────────────────────────────────────────
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

    // Responsive Dimensions based on shapeMode and styleMode
    width: shapeMode === 1 
        ? (styleMode === 1 ? (185 * Appearance.effectiveScale) : (styleMode === 2 ? (235 * Appearance.effectiveScale) : (285 * Appearance.effectiveScale)))
        : (shapeMode === 3 
            ? (styleMode === 1 ? (340 * Appearance.effectiveScale) : (styleMode === 2 ? (410 * Appearance.effectiveScale) : (480 * Appearance.effectiveScale)))
            : (styleMode === 1 ? (220 * Appearance.effectiveScale) : (styleMode === 2 ? (270 * Appearance.effectiveScale) : (330 * Appearance.effectiveScale))))

    height: shapeMode === 1 
        ? (styleMode === 1 ? (165 * Appearance.effectiveScale) : (styleMode === 2 ? (215 * Appearance.effectiveScale) : (265 * Appearance.effectiveScale)))
        : (shapeMode === 3 
            ? (styleMode === 1 ? (105 * Appearance.effectiveScale) : (styleMode === 2 ? (130 * Appearance.effectiveScale) : (160 * Appearance.effectiveScale)))
            : (styleMode === 1 ? (115 * Appearance.effectiveScale) : (styleMode === 2 ? (140 * Appearance.effectiveScale) : (170 * Appearance.effectiveScale))))

    x: settingsX >= 0 ? settingsX : 260
    y: settingsY >= 0 ? settingsY : (Appearance.sizes.screen.height - height - 120)

    visible: isActive

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // Dynamic Matugen Theme Colors & Glassmorphism UI Support (Matching ScreenTimeWidget & Clock)
    property color containerBg: root.glassmorphism 
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.40) 
        : Theme.surfaceContainer

    property color strokeColor: root.glassmorphism 
        ? Qt.rgba(1, 1, 1, 0.32) 
        : Theme.outline

    property color textColor: Theme.primary

    Behavior on containerBg { ColorAnimation { duration: 400 } }
    Behavior on strokeColor { ColorAnimation { duration: 400 } }
    Behavior on textColor { ColorAnimation { duration: 400 } }

    // Load Settings from settings.json
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let w = data.weatherWidget || data.weather || {};
            if (w.isActive !== undefined) root.isActive = w.isActive;
            if (w.winX !== undefined) root.settingsX = w.winX;
            else if (w.weatherX !== undefined) root.settingsX = w.weatherX;
            
            if (w.winY !== undefined) root.settingsY = w.winY;
            else if (w.weatherY !== undefined) root.settingsY = w.weatherY;
            
            if (w.styleMode !== undefined) root.styleMode = w.styleMode;
            if (w.shapeMode !== undefined) root.shapeMode = w.shapeMode;
        } catch(e) {
            console.log("[WeatherWidget] Error loading settings:", e);
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

    function saveSettings(newX, newY, newStyle, newShape, newActive) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "w = data.setdefault('weatherWidget', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("w['winX'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("w['winY'] = " + Math.round(newY));
        if (newStyle !== undefined) updates.push("w['styleMode'] = " + Math.round(newStyle));
        if (newShape !== undefined) updates.push("w['shapeMode'] = " + Math.round(newShape));
        if (newActive !== undefined) updates.push("w['isActive'] = " + (newActive ? "True" : "False"));
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; " +
               "f = open(tmp, 'w'); " +
               "json.dump(data, f, indent=2); " +
               "f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    Process {
        id: openWeatherProc
        command: ["quickshell", "ipc", "call", "quickshell", "run", "weather"]
        running: false
    }

    // 1-Minute Auto-Update Timer
    Timer {
        id: autoUpdateTimer
        interval: 1 * 60 * 1000 // 1 minute
        running: true
        repeat: true
        onTriggered: {
            WeatherService.updateWeather();
        }
    }

    // Refresh Rotation Animation Helper
    property bool isRefreshing: false
    function refreshData() {
        root.isRefreshing = true;
        WeatherService.updateWeather();
        refreshStopTimer.restart();
    }

    Timer {
        id: refreshStopTimer
        interval: 1200
        repeat: false
        onTriggered: root.isRefreshing = false
    }

    // Drag Scale Dynamics
    scale: dragArea.pressed ? 0.97 : (dragArea.containsMouse ? 1.03 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    // ── Shape 1: Rotated Capsule Path Generator (Diagonal Pebble) ──
    function generateRotatedCapsulePath(w, h) {
        if (w <= 0 || h <= 0) return "";
        let cx = w / 2;
        let cy = h / 2;
        let size = Math.min(w, h);
        
        let R = size * 0.38; // Radius of circular ends
        let d = size * 0.12; // Distance between end circle centers
        
        let angle = Math.PI / 4; // 45 degrees
        let cosA = Math.cos(angle);
        let sinA = Math.sin(angle);
        
        // Circle 1 center (Top-Right end)
        let c1x = cx + d * cosA;
        let c1y = cy - d * sinA;
        
        // Circle 2 center (Bottom-Left end)
        let c2x = cx - d * cosA;
        let c2y = cy + d * sinA;
        
        // Perpendicular offsets
        let px = R * sinA;
        let py = R * cosA;
        
        let p1x = c1x - px, p1y = c1y - py;
        let p2x = c1x + px, p2y = c1y + py;
        let p3x = c2x + px, p3y = c2y + py;
        let p4x = c2x - px, p4y = c2y - py;
        
        return "M " + p1x + " " + p1y +
               " A " + R + " " + R + " 0 1 1 " + p2x + " " + p2y +
               " L " + p3x + " " + p3y +
               " A " + R + " " + R + " 0 1 1 " + p4x + " " + p4y +
               " Z";
    }

    // ── Shape 2: Horizontal Pill Stadium Path Generator ──
    function generateHorizontalPillPath(w, h) {
        if (w <= 0 || h <= 0) return "";
        let pr = h * 0.46;
        return "M " + pr + " " + (h * 0.04) +
               " H " + (w - pr) +
               " A " + pr + " " + pr + " 0 0 1 " + (w - pr) + " " + (h * 0.96) +
               " H " + pr +
               " A " + pr + " " + pr + " 0 0 1 " + pr + " " + (h * 0.04) +
               " Z";
    }

    // ── Vector Shape Container ──
    Item {
        id: container
        anchors.fill: parent

        // Dynamic Vector Shape Background
        Shape {
            id: blobShape
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

            ShapePath {
                fillColor: root.containerBg
                strokeColor: "transparent"
                strokeWidth: 0
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    path: {
                        let w = blobShape.width;
                        let h = blobShape.height;
                        if (w <= 0 || h <= 0) return "";
                        return root.shapeMode === 1 
                            ? root.generateRotatedCapsulePath(w, h) 
                            : root.generateHorizontalPillPath(w, h);
                    }
                }
            }
        }

        // Glassmorphic Glossy Reflection Sheen Overlay (Matching ScreenTimeWidget & Clock)
        Shape {
            anchors.fill: parent
            visible: root.glassmorphism
            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

            ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillGradient: LinearGradient {
                    x1: 0; y1: 0; x2: 0; y2: blobShape.height
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
                    GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.04) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }

                PathSvg {
                    path: {
                        let w = blobShape.width;
                        let h = blobShape.height;
                        if (w <= 0 || h <= 0) return "";
                        return root.shapeMode === 1 
                            ? root.generateRotatedCapsulePath(w, h) 
                            : root.generateHorizontalPillPath(w, h);
                    }
                }
            }
        }

        // ── Main Responsive Content Area: Shape 1 (Diagonal Pebble) ──
        Item {
            anchors.fill: parent
            visible: root.shapeMode === 1

            // Temperature Text Display (Google Sans / Inter Typography)
            Text {
                id: tempText
                anchors {
                    top: parent.top
                    topMargin: Math.round(root.height * 0.12)
                    right: parent.right
                    rightMargin: Math.round(root.width * 0.16)
                }

                text: Math.round(WeatherService.temp) + "°"
                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                font.pixelSize: Math.round(root.height * 0.34)
                font.weight: Font.Normal
                color: root.textColor

                renderType: Text.NativeRendering
            }

            // Weather Condition Icon (Google Weather Icon)
            Image {
                id: weatherIcon
                anchors {
                    left: parent.left
                    leftMargin: Math.round(root.width * 0.14)
                    bottom: parent.bottom
                    bottomMargin: Math.round(root.height * 0.12)
                }

                width: Math.round(root.height * 0.38)
                height: Math.round(root.height * 0.38)
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true

                source: {
                    let iconName = WeatherService.googleIcon;
                    if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                    return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                }
            }
        }

        // ── Main Responsive Content Area: Shape 2 (Horizontal Pill / Stadium) ──
        Item {
            anchors.fill: parent
            visible: root.shapeMode === 2

            // Left Side: Large Weather Icon (Matching 2nd Reference Image)
            Image {
                id: pillIcon
                anchors {
                    left: parent.left
                    leftMargin: Math.round(root.width * 0.07)
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -Math.round(root.height * 0.03)
                }

                width: Math.round(root.height * 0.72)
                height: Math.round(root.height * 0.72)
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true

                source: {
                    let iconName = WeatherService.googleIcon;
                    if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                    return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                }
            }

            // Right Side: Current Temp & High/Low Temps Block (Matching 2nd Reference Image)
            ColumnLayout {
                anchors {
                    left: pillIcon.right
                    leftMargin: Math.round(root.width * 0.06)
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -Math.round(root.height * 0.03)
                }
                spacing: -4

                // Current Temperature (Matching 2nd Reference Image Typography)
                Text {
                    text: Math.round(WeatherService.temp) + "°"
                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                    font.pixelSize: Math.round(root.height * 0.44)
                    font.weight: Font.DemiBold
                    color: root.textColor
                    renderType: Text.NativeRendering
                    Layout.alignment: Qt.AlignLeft
                }

                // High / Low Temperature Row (Live Today High / Low e.g. 27°  20° left-aligned)
                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignLeft

                    Text {
                        text: (WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 4)) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(root.height * 0.15)
                        font.weight: Font.Medium
                        color: root.textColor
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: (WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp + 3)) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(root.height * 0.15)
                        font.weight: Font.Normal
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.60)
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Bottom Footer Text (Real Data Source: open-meteo.com)
            Text {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: Math.round(root.height * 0.05)
                }
                text: "Source: open-meteo.com"
                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                font.pixelSize: Math.round(root.height * 0.08)
                font.italic: true
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.45)
                renderType: Text.NativeRendering
            }
        }

        // ── Main Responsive Content Area: Shape 3 (Horizontal Pill + Material Cookie Badge) ──
        Item {
            anchors.fill: parent
            visible: root.shapeMode === 3

            // Right Block: Material Cookie Badge Accent (cookie_12 Shape)
            Item {
                id: cookieBadge
                anchors {
                    right: parent.right
                    rightMargin: Math.round(root.height * 0.14)
                    verticalCenter: parent.verticalCenter
                }
                width: Math.round(root.height * 0.72)
                height: Math.round(root.height * 0.72)

                MaterialShape {
                    id: cookieShapeItem
                    anchors.fill: parent
                    shape: "cookie_12"
                    color: Qt.rgba(Theme.primary.r * 0.45 + Theme.surfaceContainer.r * 0.55, Theme.primary.g * 0.45 + Theme.surfaceContainer.g * 0.55, Theme.primary.b * 0.45 + Theme.surfaceContainer.b * 0.55, 0.95)
                    borderWidth: 0
                    borderColor: "transparent"

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 18000
                        loops: Animation.Infinite
                        running: root.visible && root.shapeMode === 3
                    }
                }

                // Content inside Material Cookie Badge
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        width: Math.round(cookieBadge.height * 0.30)
                        height: Math.round(cookieBadge.height * 0.30)
                        sourceSize.width: Math.round(cookieBadge.height * 0.30)
                        sourceSize.height: Math.round(cookieBadge.height * 0.30)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(WeatherService.temp) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(cookieBadge.height * 0.18)
                        font.weight: Font.Normal
                        color: "#ffffff"
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Center Divider: Smooth Bar Pill Divider Line
            Rectangle {
                id: dividerLine
                anchors {
                    right: cookieBadge.left
                    rightMargin: Math.round(root.width * 0.04)
                    verticalCenter: parent.verticalCenter
                }
                width: Math.max(1, Math.round(2 * Appearance.effectiveScale))
                height: Math.round(root.height * 0.38)
                radius: width / 2
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.25)
            }

            // Left Block: High/Low Temperatures + Weather Condition (Clean & Non-Bold)
            ColumnLayout {
                anchors {
                    left: parent.left
                    leftMargin: Math.round(root.height * 0.38)
                    right: dividerLine.left
                    rightMargin: Math.round(root.width * 0.03)
                    verticalCenter: parent.verticalCenter
                }
                spacing: Math.round(root.height * 0.03)

                // Top Line: "Today 20° / 27°" (Low° / High°, No bold text, simple clean font)
                Text {
                    text: "Today " + (WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 4)) + "° / " + (WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp + 3)) + "°"
                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                    font.pixelSize: Math.round(root.height * 0.14)
                    font.weight: Font.Normal
                    color: root.textColor
                    renderType: Text.NativeRendering
                    Layout.alignment: Qt.AlignLeft
                }

                // Bottom Line: Small Condition Icon + Condition Text (Matching 2nd reference image exact sizes)
                RowLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignLeft

                    Image {
                        width: Math.round(root.height * 0.12)
                        height: Math.round(root.height * 0.12)
                        Layout.preferredWidth: Math.round(root.height * 0.12)
                        Layout.preferredHeight: Math.round(root.height * 0.12)
                        sourceSize.width: Math.round(root.height * 0.12)
                        sourceSize.height: Math.round(root.height * 0.12)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        Layout.alignment: Qt.AlignVCenter
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Text {
                        text: WeatherService.condition || "Mostly cloudy"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(root.height * 0.13)
                        font.weight: Font.Normal
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.85)
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // Drag, Click & Direct Mouse Controls Area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        drag.target: root

        onReleased: {
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive);
        }

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                // Middle Click: Cycle Size Style (Small -> Medium -> Large)
                root.styleMode = (root.styleMode % 3) + 1;
                root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive);
            } else if (mouse.button === Qt.RightButton) {
                // Right Click: Cycle Shape (Diagonal Pebble -> Pill -> Cookie Pill)
                root.shapeMode = (root.shapeMode % 3) + 1;
                root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive);
            } else if (mouse.button === Qt.LeftButton) {
                // Left Click: Open Weather App
                openWeatherProc.running = true;
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.styleMode = Math.min(3, root.styleMode + 1);
            } else if (wheel.angleDelta.y < 0) {
                root.styleMode = Math.max(1, root.styleMode - 1);
            }
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive);
        }
    }
}
