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
import "clocks/RoundedRectRay.js" as Ray

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property int clockStyle: 0 // 0: Organic Cookie, 1: Material Dial, 2: California, 3: Type Stacked
    property bool interactive: true
    property real baseWinSize: -1

    property real customWidth: -1
    property real customHeight: -1

    readonly property bool glassmorphism: Glassmorphism.enabled

    readonly property var styleDefinitions: [
        { name: "Organic Cookie", naturalW: 270, naturalH: 270, square: true },
        { name: "Material Dial",  naturalW: 240, naturalH: 240, square: true },
        { name: "California",     naturalW: 240, naturalH: 240, square: true },
        { name: "Type Stacked",   naturalW: 200, naturalH: 340, square: false },
        { name: "Split Dual",     naturalW: 240, naturalH: 240, square: true }
    ]

    readonly property var currentStyleDef: styleDefinitions[clockStyle % styleDefinitions.length]

    readonly property real baseWidth: baseWinSize > 0 ? baseWinSize : (currentStyleDef.naturalW * Appearance.effectiveScale)
    readonly property real baseHeight: baseWinSize > 0 ? (currentStyleDef.square ? baseWinSize : baseWinSize * (currentStyleDef.naturalH / currentStyleDef.naturalW)) : (currentStyleDef.naturalH * Appearance.effectiveScale)

    width: (baseWinSize > 0) ? baseWidth : (customWidth > 0 ? (customWidth * Appearance.effectiveScale) : baseWidth)
    height: (baseWinSize > 0) ? baseHeight : (customHeight > 0 ? (customHeight * Appearance.effectiveScale) : baseHeight)

    x: root.interactive ? (settingsX >= 0 ? settingsX : 60 * Appearance.effectiveScale) : 0
    y: root.interactive ? (settingsY >= 0 ? settingsY : 200 * Appearance.effectiveScale) : 0
    visible: root.interactive ? root.isActive : true

    Behavior on width { enabled: root.interactive && (typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true); NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.interactive && (typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true); NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    scale: root.interactive ? (dragArea.pressed ? 0.98 : (dragArea.containsMouse ? 1.015 : 1.0)) : 1.0
    Behavior on scale { enabled: root.interactive; NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // ── Settings Persistence (using centralized Config service) ──
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let s = data.clockWidget || data.clock || {};
            if (s.isActive !== undefined) root.isActive = s.isActive;
            if (s.x !== undefined) root.settingsX = s.x;
            if (s.y !== undefined) root.settingsY = s.y;
            if (s.width !== undefined && s.width > 0) root.customWidth = s.width;
            if (s.height !== undefined && s.height > 0) root.customHeight = s.height;
            if (s.style !== undefined) {
                if (typeof s.style === "number") {
                    root.clockStyle = s.style % styleDefinitions.length;
                } else {
                    let map = { "cookie": 0, "dial": 1, "california": 2, "stack": 3, "split": 4 };
                    root.clockStyle = map[s.style] ?? 0;
                }
            }
        } catch(e) {}
    }

    Timer { id: reloadTimer; interval: 150; running: false; repeat: false; onTriggered: settingsFile.reload() }
    FileView { id: settingsFile; path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"; watchChanges: true; preload: true; onLoaded: root.loadSettings(text()); onFileChanged: reloadTimer.restart() }

    function saveSettings(newX, newY, newStyle, newW, newH) {
        let obj = {};
        if (newX !== undefined) obj.x = Math.round(newX);
        if (newY !== undefined) obj.y = Math.round(newY);
        if (newStyle !== undefined) obj.style = newStyle;
        if (newW !== undefined && newW > 0) obj.width = Math.round(newW);
        else if (newW === -1) obj.width = null;
        if (newH !== undefined && newH > 0) obj.height = Math.round(newH);
        else if (newH === -1) obj.height = null;
        Config.setSection("clockWidget", obj);
    }

    function cycleNextStyle() {
        root.customWidth = -1;
        root.customHeight = -1;
        root.clockStyle = (root.clockStyle + 1) % styleDefinitions.length;
        root.saveSettings(root.x, root.y, root.clockStyle, -1, -1);
    }

    // Dynamic Material You (M3) Color Palette matching WeatherWidget (shapeMode 2) & Glassmorphism
    readonly property color colBg: root.glassmorphism
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.40)
        : Theme.surfaceContainer
    readonly property color colCardBg: root.glassmorphism
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.40)
        : Theme.surfaceContainer
    readonly property color colTextPrimary: Theme.primary
    readonly property color colTextSecondary: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.70)
    readonly property color colAccent: Theme.primary
    readonly property color colAccentContainer: Qt.rgba(Theme.primary.r * 0.45 + Theme.surfaceContainer.r * 0.55, Theme.primary.g * 0.45 + Theme.surfaceContainer.g * 0.55, Theme.primary.b * 0.45 + Theme.surfaceContainer.b * 0.55, 0.95)
    readonly property color colOnAccentContainer: "#ffffff"
    readonly property color colSecondary: Theme.secondary
    readonly property color colSecondaryContainer: Qt.rgba(Theme.primary.r * 0.45 + Theme.surfaceContainer.r * 0.55, Theme.primary.g * 0.45 + Theme.surfaceContainer.g * 0.55, Theme.primary.b * 0.45 + Theme.surfaceContainer.b * 0.55, 0.95)
    readonly property color colOnSecondaryContainer: "#ffffff"
    readonly property color colPillFill: Qt.rgba(Theme.primary.r * 0.45 + Theme.surfaceContainer.r * 0.55, Theme.primary.g * 0.45 + Theme.surfaceContainer.g * 0.55, Theme.primary.b * 0.45 + Theme.surfaceContainer.b * 0.55, 0.95)
    readonly property color colPillText: "#ffffff"
    readonly property color colBorder: root.glassmorphism ? Qt.rgba(1, 1, 1, 0.32) : Theme.outline

    // Real-time smooth timer for hands
    property real smoothSeconds: 0
    property real smoothMinutes: 0
    property real smoothHours: 0

    Timer {
        id: smoothTimer
        interval: 33
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            let ms = now.getMilliseconds();
            let s = now.getSeconds() + ms / 1000.0;
            let m = now.getMinutes() + s / 60.0;
            let h = (now.getHours() % 12) + m / 60.0;
            root.smoothSeconds = s;
            root.smoothMinutes = m;
            root.smoothHours = h;
        }
    }

    // ── Mouse Drag & Style Switching ──
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root.interactive ? root : null
        drag.axis: Drag.XAndYAxis
        hoverEnabled: root.interactive
        enabled: root.interactive
        visible: root.interactive
        cursorShape: drag.active ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 50

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.cycleNextStyle();
            }
        }
        onReleased: {
            if (drag.active) {
                root.saveSettings(root.x, root.y, root.clockStyle, root.customWidth, root.customHeight);
            }
        }
    }

    // ══════════════════════════════════════════════════════════════════
    // CLOCK STYLES CONTAINER
    // ══════════════════════════════════════════════════════════════════
    Item {
        id: clockDisplay
        anchors.fill: parent

        // ──────────────────────────────────────────────────────────────
        // STYLE 0: ORGANIC COOKIE CLOCK (Continuous Wave Rotation + Orbit Dot)
        // ──────────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.clockStyle === 0

            Canvas {
                id: cookieBgCanvas
                anchors.fill: parent
                antialiasing: true

                RotationAnimation on rotation {
                    running: root.visible && root.clockStyle === 0
                    duration: 120000
                    from: 360; to: 0
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width / 2;
                    var cy = height / 2;
                    var rOuter = Math.min(cx, cy) - 4;
                    var rInner = rOuter * 0.78;
                    var lobes = 9;

                    ctx.beginPath();
                    for (var a = 0; a <= 360; a += 1) {
                        var rad = a * Math.PI / 180;
                        var wave = (Math.cos(lobes * rad) + 1.0) / 2.0;
                        var r = rInner + (rOuter - rInner) * Math.pow(wave, 0.7);
                        var x = cx + r * Math.sin(rad);
                        var y = cy - r * Math.cos(rad);
                        if (a === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }
                    ctx.closePath();
                    ctx.fillStyle = root.colBg;
                    ctx.fill();
                    ctx.strokeStyle = root.glassmorphism ? "rgba(255, 255, 255, 0.2)" : Theme.outlineVariant;
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                }
            }

            // ─── Fixed Top-Left Day Pentagon Badge ───
            Item {
                x: parent.width * 0.12
                y: parent.height * 0.08
                width: Math.max(38, parent.width * 0.18)
                height: width

                Canvas {
                    id: pentagonCanvas
                    anchors.fill: parent
                    antialiasing: true
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width * 0.45;
                        ctx.beginPath();
                        for (var i = 0; i < 5; i++) {
                            var angle = (i * 72 - 90) * Math.PI / 180;
                            var px = cx + r * Math.cos(angle);
                            var py = cy + r * Math.sin(angle);
                            if (i === 0) ctx.moveTo(px, py);
                            else ctx.lineTo(px, py);
                        }
                        ctx.closePath();
                        ctx.fillStyle = root.colSecondaryContainer;
                        ctx.fill();
                        ctx.strokeStyle = root.colBorder;
                        ctx.lineWidth = 1.2;
                        ctx.stroke();
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Text {
                    anchors.centerIn: parent
                    text: DateTime.dayOfMonth
                    color: root.colOnSecondaryContainer
                    font.pixelSize: Math.round(parent.width * 0.36)
                    font.bold: true
                    font.family: Theme.font.family
                }
            }

            // ─── Fixed Bottom-Right Month Capsule Badge ───
            Rectangle {
                x: parent.width * 0.70
                y: parent.height * 0.78
                width: Math.max(46, parent.width * 0.22)
                height: Math.max(26, parent.height * 0.13)
                radius: height / 2
                color: root.colSecondaryContainer
                border.color: root.colBorder
                border.width: 1.2
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: DateTime.dayNameShort.toUpperCase()
                    color: root.colOnSecondaryContainer
                    font.pixelSize: Math.round(parent.height * 0.44)
                    font.bold: true
                    font.family: Theme.font.family
                }
            }

            // Fixed Cardinal Numerals (12, 3, 6, 9) in Material You Muted OnSurfaceVariant
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.13
                text: "12"
                color: root.colTextSecondary
                font.pixelSize: Math.round(parent.height * 0.20)
                font.bold: true
                font.family: Theme.font.family
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.12
                text: "3"
                color: root.colTextSecondary
                font.pixelSize: Math.round(parent.height * 0.20)
                font.bold: true
                font.family: Theme.font.family
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.13
                text: "6"
                color: root.colTextSecondary
                font.pixelSize: Math.round(parent.height * 0.20)
                font.bold: true
                font.family: Theme.font.family
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.12
                text: "9"
                color: root.colTextSecondary
                font.pixelSize: Math.round(parent.height * 0.20)
                font.bold: true
                font.family: Theme.font.family
            }

            // Hands + Seconds Orbit Dot
            Item {
                anchors.fill: parent

                // Orbiting Seconds Dot
                Item {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    rotation: root.smoothSeconds * 6

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.15
                        width: Math.max(10, parent.width * 0.055)
                        height: width
                        radius: width / 2
                        color: root.colAccent
                        border.color: Theme.onPrimary
                        border.width: 1.5
                        antialiasing: true
                    }
                }

                // Hour Hand Pill (Material You primaryContainer with onPrimaryContainer)
                Item {
                    anchors.centerIn: parent
                    width: Math.max(14, parent.width * 0.08)
                    height: parent.height
                    rotation: root.smoothHours * 30
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -parent.width / 2
                        width: parent.width
                        height: parent.height * 0.27
                        radius: width / 2
                        color: root.colAccentContainer
                        border.color: root.colAccent
                        border.width: 1.5
                        antialiasing: true
                    }
                }

                // Minute Hand Pill (Material You primary accent with onPrimary)
                Item {
                    anchors.centerIn: parent
                    width: Math.max(10, parent.width * 0.055)
                    height: parent.height
                    rotation: root.smoothMinutes * 6
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -parent.width / 2
                        width: parent.width
                        height: parent.height * 0.38
                        radius: width / 2
                        color: root.colAccent
                        border.color: Theme.onPrimary
                        border.width: 1.5
                        antialiasing: true
                    }
                }

                // Center Cap Dot
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(12, parent.width * 0.05)
                    height: width
                    radius: width / 2
                    color: root.colAccent
                    border.color: root.colBg
                    border.width: 2
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // STYLE 1: MATERIAL DIAL CLOCK (Concentric Circular Dial + Radial Ticks)
        // ──────────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.clockStyle === 1

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: root.colBg
                border.color: root.glassmorphism ? "rgba(255, 255, 255, 0.2)" : Theme.outlineVariant
                border.width: 1.5
                clip: true

                // Radial Ticks (120 divisions)
                Canvas {
                    id: dialTicks
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = root.colTextSecondary;
                        ctx.lineWidth = 1.2;
                        var cx = width / 2;
                        var cy = height / 2;
                        var r = cx - 10;
                        for (var i = 0; i < 60; i++) {
                            var angle = (i * 6) * Math.PI / 180;
                            var tickLen = (i % 5 === 0) ? 9 : 4;
                            ctx.beginPath();
                            ctx.moveTo(cx + (r - tickLen) * Math.cos(angle), cy + (r - tickLen) * Math.sin(angle));
                            ctx.lineTo(cx + r * Math.cos(angle), cy + r * Math.sin(angle));
                            ctx.stroke();
                        }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // Dial Numerals (12, 3, 6, 9)
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: parent.height * 0.06
                    text: "12"
                    font.family: Theme.font.family
                    font.pixelSize: Math.round(parent.height * 0.22)
                    font.bold: true
                    color: root.colTextSecondary
                    opacity: 0.7
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.height * 0.06
                    text: "6"
                    font.family: Theme.font.family
                    font.pixelSize: Math.round(parent.height * 0.22)
                    font.bold: true
                    color: root.colTextSecondary
                    opacity: 0.7
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: parent.width * 0.08
                    text: "3"
                    font.family: Theme.font.family
                    font.pixelSize: Math.round(parent.height * 0.22)
                    font.bold: true
                    color: root.colTextSecondary
                    opacity: 0.7
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.08
                    text: "9"
                    font.family: Theme.font.family
                    font.pixelSize: Math.round(parent.height * 0.22)
                    font.bold: true
                    color: root.colTextSecondary
                    opacity: 0.7
                }

                // Dial Hands
                Item {
                    anchors.fill: parent
                    // Hour Hand
                    Item {
                        anchors.centerIn: parent
                        width: parent.width * 0.07
                        height: parent.height
                        rotation: root.smoothHours * 30
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            width: parent.width
                            height: parent.height * 0.28
                            radius: width / 2
                            color: root.colAccent
                        }
                    }
                    // Minute Hand
                    Item {
                        anchors.centerIn: parent
                        width: parent.width * 0.04
                        height: parent.height
                        rotation: root.smoothMinutes * 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            width: parent.width
                            height: parent.height * 0.38
                            radius: width / 2
                            color: root.colTextPrimary
                        }
                    }
                    // Second Hand Needle
                    Item {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        rotation: root.smoothSeconds * 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: -parent.height * 0.08
                            width: 2
                            height: parent.height * 0.48
                            color: Theme.tertiary
                        }
                    }
                    // Pivot
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.04
                        height: width
                        radius: width / 2
                        color: Theme.tertiary
                    }
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // STYLE 2: CALIFORNIA CLOCK (Roman Top, Arabic Bottom, Ray Edge)
        // ──────────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.clockStyle === 2

            Rectangle {
                id: caliCard
                anchors.fill: parent
                radius: Math.min(width, height) * 0.22
                color: root.colBg
                border.color: root.glassmorphism ? "rgba(255, 255, 255, 0.2)" : Theme.outlineVariant
                border.width: 1.5

                readonly property real dSize: Math.min(width, height)
                readonly property real cRadius: radius
                readonly property var numerals: ["XII", "I", "II", "3", "4", "5", "6", "7", "8", "9", "X", "XI"]

                // 60-second perimeter track
                Repeater {
                    model: 60
                    Rectangle {
                        required property int index
                        readonly property bool major: index % 5 === 0
                        readonly property real angle: index * 6
                        readonly property real reach: Ray.distance(angle, caliCard.dSize / 2 - 8, caliCard.cRadius - 8)
                        readonly property real centreDist: reach - height / 2

                        width: major ? 2.5 : 1.5
                        height: major ? 8 : 5
                        radius: width / 2
                        color: major ? root.colTextPrimary : root.colTextSecondary
                        x: caliCard.width / 2 + Math.sin(angle * Math.PI / 180) * centreDist - width / 2
                        y: caliCard.height / 2 - Math.cos(angle * Math.PI / 180) * centreDist - height / 2
                        rotation: angle
                        antialiasing: true
                    }
                }

                // 12 Upright Numerals
                Repeater {
                    model: 12
                    Text {
                        required property int index
                        readonly property point spot: Ray.point(index * 30, caliCard.dSize / 2 - 28, caliCard.cRadius - 28, caliCard.dSize / 2)
                        text: caliCard.numerals[index]
                        color: root.colTextPrimary
                        font.family: Theme.font.family
                        font.pixelSize: Math.round(caliCard.dSize * 0.12)
                        font.bold: true
                        x: (caliCard.width / 2 - caliCard.dSize / 2) + spot.x - width / 2
                        y: (caliCard.height / 2 - caliCard.dSize / 2) + spot.y - height / 2
                    }
                }

                // Date complication
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: caliCard.dSize * 0.18
                    spacing: 4

                    Text {
                        text: DateTime.dayNameShort.toUpperCase()
                        color: root.colAccent
                        font.pixelSize: Math.round(caliCard.dSize * 0.055)
                        font.bold: true
                        font.family: Theme.font.family
                    }
                    Text {
                        text: DateTime.dayOfMonth
                        color: root.colTextPrimary
                        font.pixelSize: Math.round(caliCard.dSize * 0.055)
                        font.bold: true
                        font.family: Theme.font.family
                    }
                }

                // Hands
                Item {
                    anchors.fill: parent
                    // Hour Hand
                    Item {
                        anchors.centerIn: parent
                        width: 8
                        height: parent.height
                        rotation: root.smoothHours * 30
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            width: 8
                            height: caliCard.dSize * 0.26
                            radius: 4
                            color: root.colTextPrimary
                        }
                    }
                    // Minute Hand
                    Item {
                        anchors.centerIn: parent
                        width: 6
                        height: parent.height
                        rotation: root.smoothMinutes * 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            width: 6
                            height: caliCard.dSize * 0.38
                            radius: 3
                            color: root.colTextPrimary
                        }
                    }
                    // Second Hand
                    Item {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        rotation: root.smoothSeconds * 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.verticalCenter
                            anchors.bottomMargin: -caliCard.dSize * 0.08
                            width: 2
                            height: caliCard.dSize * 0.44
                            radius: 1
                            color: root.colAccent
                        }
                    }
                    // Pivot
                    Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 10
                        radius: 5
                        color: root.colAccent
                    }
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // STYLE 3: TYPE STACKED CLOCK (Vertical 4-Digit Stack with Divider Band)
        // ──────────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.clockStyle === 3

            Rectangle {
                anchors.fill: parent
                radius: 28 * Appearance.effectiveScale
                color: root.colBg
                border.color: root.glassmorphism ? "rgba(255, 255, 255, 0.2)" : Theme.outlineVariant
                border.width: 1.5

                readonly property string dAll: (DateTime.hours % 12 || 12).toString().padStart(2, "0") + DateTime.minutes.toString().padStart(2, "0")

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 0

                    // Digit 0 (Hour 1)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.dAll.charAt(0)
                        font.family: Theme.font.family
                        font.pixelSize: Math.round(parent.height * 0.19)
                        font.bold: true
                        color: root.colAccent
                    }

                    // Digit 1 (Hour 2)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.dAll.charAt(1)
                        font.family: Theme.font.family
                        font.pixelSize: Math.round(parent.height * 0.19)
                        font.bold: true
                        color: root.colAccent
                    }

                    // Divider Band
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 28 * Appearance.effectiveScale
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 6 * Appearance.effectiveScale
                            Layout.preferredHeight: 6 * Appearance.effectiveScale
                            radius: 3 * Appearance.effectiveScale
                            color: root.colAccent
                        }

                        Text {
                            text: Qt.formatDate(DateTime.clock.date, "ddd d").toUpperCase()
                            font.family: Theme.font.monospace
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: root.colTextSecondary
                            font.bold: true
                        }

                        Text {
                            text: DateTime.hours >= 12 ? "PM" : "AM"
                            font.family: Theme.font.monospace
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: root.colAccent
                            font.bold: true
                        }
                    }

                    // Digit 2 (Minute 1)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.dAll.charAt(2)
                        font.family: Theme.font.family
                        font.pixelSize: Math.round(parent.height * 0.19)
                        font.bold: true
                        color: root.colTextPrimary
                    }

                    // Digit 3 (Minute 2)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.parent.dAll.charAt(3)
                        font.family: Theme.font.family
                        font.pixelSize: Math.round(parent.height * 0.19)
                        font.bold: true
                        color: root.colTextPrimary
                    }
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // STYLE 4: SPLIT DUAL CLOCK (Digital Left, Analog Hands & Donut Right)
        // ──────────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            visible: root.clockStyle === 4

            Rectangle {
                id: splitCard
                anchors.fill: parent
                radius: Math.round(Math.min(width, height) * 0.17)
                color: root.colBg
                border.color: root.colBorder
                border.width: 1.5
                clip: true

                readonly property real panelW: width * 0.44
                readonly property real pivotX: width * 0.72
                readonly property real pivotY: height * 0.50

                // ── Analog Dial Hands & Donut Layer (Placed on the right, under the left panel) ──
                Item {
                    anchors.fill: parent

                    // Minute Hand (Sleek Rod Line, rotates smoothMinutes * 6)
                    Item {
                        x: splitCard.pivotX
                        y: splitCard.pivotY
                        width: 0
                        height: 0
                        rotation: root.smoothMinutes * 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: splitCard.height * 0.05
                            width: Math.max(3, Math.round(splitCard.width * 0.016))
                            height: Math.round(splitCard.height * 0.38)
                            radius: width / 2
                            color: root.colTextSecondary
                            antialiasing: true
                        }
                    }

                    // Hour Hand (Material Accent Capsule Pill, rotates smoothHours * 30)
                    Item {
                        x: splitCard.pivotX
                        y: splitCard.pivotY
                        width: 0
                        height: 0
                        rotation: root.smoothHours * 30

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top
                            anchors.bottomMargin: splitCard.height * 0.05
                            width: Math.max(12, Math.round(splitCard.width * 0.065))
                            height: Math.round(splitCard.height * 0.16)
                            radius: width / 2
                            color: root.colAccent
                            antialiasing: true
                        }
                    }

                    // Center Donut Pivot Ring (Outer secondary accent, inner hole matching colBg)
                    Rectangle {
                        x: splitCard.pivotX - width / 2
                        y: splitCard.pivotY - height / 2
                        width: Math.round(splitCard.height * 0.24)
                        height: width
                        radius: width / 2
                        color: root.colSecondaryContainer
                        antialiasing: true

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.38)
                            height: width
                            radius: width / 2
                            color: root.colBg
                            antialiasing: true
                        }
                    }
                }

                // ── Left Digital Panel (Covers left 44%, clips hands, shows HH / MM) ──
                Rectangle {
                    id: leftPanel
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: splitCard.panelW
                    radius: splitCard.radius
                    color: root.colAccentContainer

                    // Straighten the right side corners so it cleanly cuts vertically
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: leftPanel.radius
                        color: leftPanel.color
                    }

                    // Digits Container (Hours on top, Minutes on bottom)
                    Column {
                        anchors.centerIn: parent
                        spacing: 4 * Appearance.effectiveScale

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (DateTime.hours % 12 || 12).toString().padStart(2, "0")
                            font.family: Theme.font.family
                            font.pixelSize: Math.round(splitCard.height * 0.26)
                            font.bold: true
                            color: root.colOnAccentContainer
                            renderType: Text.NativeRendering
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: DateTime.minutes.toString().padStart(2, "0")
                            font.family: Theme.font.family
                            font.pixelSize: Math.round(splitCard.height * 0.26)
                            font.bold: true
                            color: root.colOnAccentContainer
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }
    }

    // ── Resizing Handle & Edit Mode Frame ──
    WidgetResizeFrame {
        id: resizeFrame
        visible: root.interactive
        enabled: root.interactive
        target: root
        widgetName: "Clock (" + root.currentStyleDef.name + ")"
        lockAspectRatio: root.currentStyleDef.square
        minWidth: 140 * Appearance.effectiveScale
        minHeight: 140 * Appearance.effectiveScale
        maxWidth: 700 * Appearance.effectiveScale
        maxHeight: 700 * Appearance.effectiveScale

        onResized: (newW, newH) => {
            root.customWidth = Math.round(newW / Appearance.effectiveScale);
            root.customHeight = Math.round(newH / Appearance.effectiveScale);
            cookieBgCanvas.requestPaint();
            dialTicks.requestPaint();
        }
        onResizeEnded: (finalW, finalH) => {
            root.customWidth = Math.round(finalW / Appearance.effectiveScale);
            root.customHeight = Math.round(finalH / Appearance.effectiveScale);
            root.saveSettings(root.x, root.y, root.clockStyle, root.customWidth, root.customHeight);
        }
        onResetRequested: {
            root.customWidth = -1;
            root.customHeight = -1;
            root.saveSettings(root.x, root.y, root.clockStyle, -1, -1);
        }
    }
}
