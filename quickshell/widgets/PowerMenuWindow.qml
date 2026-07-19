import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../services"
import "../components"
import "../core"

PanelWindow {
    id: powermenuWindow

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); powermenuWindow.glassmorphism = true; } catch(e) { powermenuWindow.glassmorphism = false; } }
        onLoaded: powermenuWindow.glassmorphism = true
        onLoadFailed: powermenuWindow.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }


    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-powermenu"
    
    // Grab keyboard focus exclusively only when visible to intercept shortcut keys
    WlrLayershell.keyboardFocus: PowerMenuService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: PowerMenuService.visible

    onVisibleChanged: {
        if (visible) {
            menuContent.forceActiveFocus();
            openAnim.restart();
        }
    }

    FocusScope {
        id: menuContent
        anchors.fill: parent
        focus: true

        // Escape to close and shortcut buttons
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape)
                PowerMenuService.close();
            else if (event.key === Qt.Key_L)
                PowerMenuService.runCommand("lock");
            else if (event.key === Qt.Key_S)
                PowerMenuService.runCommand("sleep");
            else if (event.key === Qt.Key_Q)
                PowerMenuService.runCommand("reload");
            else if (event.key === Qt.Key_R)
                PowerMenuService.runCommand("reboot");
            else if (event.key === Qt.Key_X)
                PowerMenuService.runCommand("logout");
            else if (event.key === Qt.Key_P)
                PowerMenuService.runCommand("poweroff");
        }

        // Dim backdrop - clicking outside closes the powermenu
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: powermenuWindow.visible ? 0.55 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.anim.durationShort
                    easing.bezierCurve: Theme.anim.curve
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuService.close()
            }
        }

        // Menu container centered in parent
        Item {
            id: menuContainer
            anchors.centerIn: parent
            width: buttonsRow.implicitWidth + 56 * Appearance.effectiveScale
            height: buttonsRow.implicitHeight + 56 * Appearance.effectiveScale

            ParallelAnimation {
                id: openAnim
                NumberAnimation { target: menuContainer; property: "scale"; from: 0.9; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                NumberAnimation { target: menuContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
            }

            // Premium drop shadow behind card
            DropShadow {
                anchors.fill: menuCard
                source: menuCard
                verticalOffset: 16 * Appearance.effectiveScale
                horizontalOffset: 0
                radius: 48 * Appearance.effectiveScale
                samples: 65
                spread: 0.04
                color: Qt.rgba(0, 0, 0, 0.5)
                transparentBorder: true
                cached: true
            }

            Rectangle {
                id: menuCard
                anchors.fill: parent
                radius: Theme.rounding.extraLarge

                // Dynamic Material You surface container with glassmorphic transparency
                color: powermenuWindow.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.5) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
                // High contrast white highlight border for glass effect
                border.color: powermenuWindow.glassmorphism ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Glossy reflection overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: powermenuWindow.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.12) }
                        GradientStop { position: 0.4; color: Qt.rgba(255, 255, 255, 0.03) }
                        GradientStop { position: 0.42; color: Qt.rgba(255, 255, 255, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
                    }
                    border.color: "transparent"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {} // Block clicks from passing through
                }

                Row {
                    id: buttonsRow
                    anchors.centerIn: parent
                    spacing: Styling.spacingSmall * Appearance.effectiveScale

                    Repeater {
                        model: [
                            { name: "Lock",             icon: "lock",               key: "L", cmd: "lock",    isPrimary: false, isFirst: true,  isLast: false },
                            { name: "Sleep",            icon: "bedtime",            key: "S", cmd: "sleep",   isPrimary: false, isFirst: false, isLast: false },
                            { name: "Reload QML",       icon: "autorenew",          key: "Q", cmd: "reload",  isPrimary: false, isFirst: false, isLast: false },
                            { name: "Restart",          icon: "restart_alt",        key: "R", cmd: "reboot",  isPrimary: false, isFirst: false, isLast: false },
                            { name: "Log Out",          icon: "logout",             key: "X", cmd: "logout",  isPrimary: false, isFirst: false, isLast: false },
                            { name: "Power Off",        icon: "power_settings_new", key: "P", cmd: "poweroff",isPrimary: true,  isFirst: false, isLast: true  }
                        ]

                        delegate: Item {
                            id: btnDelegate
                            width: 120 * Appearance.effectiveScale
                            height: 140 * Appearance.effectiveScale

                            // Pressed down scaling
                            transform: Scale {
                                origin.x: btnDelegate.width / 2
                                origin.y: btnDelegate.height / 2
                                xScale: ma.pressed ? 0.92 : 1.0
                                yScale: xScale
                                Behavior on xScale {
                                    NumberAnimation {
                                        duration: 80
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            // GPU-accelerated Shape for morphing button backgrounds
                            Shape {
                                id: btnShape
                                anchors.fill: parent

                                property real defaultR: 16 * Appearance.effectiveScale
                                property real hoverR: 56 * Appearance.effectiveScale

                                property real tlr: ma.containsMouse ? hoverR : (modelData.isFirst ? 28 * Appearance.effectiveScale : defaultR)
                                property real trr: ma.containsMouse ? hoverR : (modelData.isLast  ? 28 * Appearance.effectiveScale : defaultR)
                                property real blr: ma.containsMouse ? hoverR : (modelData.isFirst ? 28 * Appearance.effectiveScale : defaultR)
                                property real brr: ma.containsMouse ? hoverR : (modelData.isLast  ? 28 * Appearance.effectiveScale : defaultR)

                                Behavior on tlr { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on trr { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on blr { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on brr { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                property color fillColor: {
                                    if (modelData.isPrimary)
                                        return ma.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.35) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18);
                                    return ma.containsMouse
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                                        : Qt.rgba(1, 1, 1, 0.05);
                                }
                                property color strokeColor: {
                                    if (modelData.isPrimary)
                                        return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, ma.containsMouse ? 0.5 : 0.25);
                                    return ma.containsMouse
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45)
                                        : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15);
                                }

                                Behavior on fillColor   { ColorAnimation { duration: 180 } }
                                Behavior on strokeColor  { ColorAnimation { duration: 180 } }

                                layer.enabled: true
                                layer.samples: 4
                                layer.smooth: true

                                ShapePath {
                                    fillColor: btnShape.fillColor
                                    strokeColor: btnShape.strokeColor
                                    strokeWidth: 1
                                    capStyle: ShapePath.RoundCap
                                    joinStyle: ShapePath.RoundJoin

                                    startX: btnShape.tlr
                                    startY: 0

                                    PathLine { x: btnShape.width - btnShape.trr; y: 0 }
                                    PathArc { x: btnShape.width; y: btnShape.trr; radiusX: btnShape.trr; radiusY: btnShape.trr }
                                    PathLine { x: btnShape.width; y: btnShape.height - btnShape.brr }
                                    PathArc { x: btnShape.width - btnShape.brr; y: btnShape.height; radiusX: btnShape.brr; radiusY: btnShape.brr }
                                    PathLine { x: btnShape.blr; y: btnShape.height }
                                    PathArc { x: 0; y: btnShape.height - btnShape.blr; radiusX: btnShape.blr; radiusY: btnShape.blr }
                                    PathLine { x: 0; y: btnShape.tlr }
                                    PathArc { x: btnShape.tlr; y: 0; radiusX: btnShape.tlr; radiusY: btnShape.tlr }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8 * Appearance.effectiveScale

                                // Circular icon wrapper
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 52 * Appearance.effectiveScale
                                    height: 52 * Appearance.effectiveScale

                                                                    MaterialShape {
                                        id: hoverShape
                                        anchors.centerIn: parent
                                        width: 52 * Appearance.effectiveScale
                                        height: 52 * Appearance.effectiveScale
                                        color: {
                                            if (modelData.isPrimary)
                                                return ma.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.45) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25);
                                            return ma.containsMouse
                                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                                                : Qt.rgba(1, 1, 1, 0.08);
                                        }

                                        Behavior on color { ColorAnimation { duration: 200 } }

                                        shape: ma.containsMouse ? hoverShapeName : "circle"

                                        property string hoverShapeName: "circle"

                                        readonly property var allowedShapes: [
                                            "sunny", "very_sunny", 
                                            "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                                            "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                                        ]

                                        Connections {
                                            target: ma
                                            function onContainsMouseChanged() {
                                                if (ma.containsMouse) {
                                                    var idx = Math.floor(Math.random() * hoverShape.allowedShapes.length);
                                                    hoverShape.hoverShapeName = hoverShape.allowedShapes[idx];
                                                }
                                            }
                                        }

                                        // Spin animation on hover
                                        RotationAnimation on rotation {
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 2200
                                            running: ma.containsMouse
                                        }
                                    }

                                    // Icon with wobble & scale animations
                                    Item {
                                        anchors.centerIn: parent
                                        width: 36 * Appearance.effectiveScale; height: 36 * Appearance.effectiveScale

                                        transform: [
                                            Rotation {
                                                id: iconWobble
                                                origin.x: 18 * Appearance.effectiveScale; origin.y: 18 * Appearance.effectiveScale
                                                angle: 0
                                            },
                                            Scale {
                                                origin.x: 18 * Appearance.effectiveScale; origin.y: 18 * Appearance.effectiveScale
                                                xScale: ma.containsMouse ? 1.15 : 1.0
                                                yScale: xScale
                                                Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            }
                                        ]

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: modelData.icon
                                            size: 26 * Appearance.effectiveScale
                                            color: {
                                                if (modelData.isPrimary)
                                                    return ma.containsMouse ? Theme.error : Qt.rgba(Theme.error.r + 0.1, Theme.error.g + 0.1, Theme.error.b + 0.1, 0.9);
                                                return ma.containsMouse ? Theme.primary : Theme.onSurface;
                                            }
                                            Behavior on color { ColorAnimation { duration: 180 } }
                                        }

                                        // Icon wiggle animation on hover
                                        SequentialAnimation {
                                            running: ma.containsMouse
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: 1200 }
                                            NumberAnimation { target: iconWobble; property: "angle"; to: -12; duration: 70; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: iconWobble; property: "angle"; to: 12;  duration: 70; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: iconWobble; property: "angle"; to: -8;  duration: 60; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: iconWobble; property: "angle"; to: 8;   duration: 60; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: iconWobble; property: "angle"; to: 0;   duration: 60; easing.type: Easing.InOutQuad }
                                            onRunningChanged: { if (!running) iconWobble.angle = 0; }
                                        }
                                    }
                                }

                                // Text Label
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    horizontalAlignment: Text.AlignHCenter
                                    font.family: Theme.font.family
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    lineHeight: 1.2
                                    color: {
                                        if (modelData.isPrimary)
                                            return ma.containsMouse ? "#ffffff" : Qt.rgba(1, 0.8, 0.8, 0.9);
                                        return ma.containsMouse ? Theme.primary : Theme.onSurfaceVariant;
                                    }
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                // Keybind indicator badge
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 22 * Appearance.effectiveScale; height: 22 * Appearance.effectiveScale
                                    radius: 6 * Appearance.effectiveScale
                                    color: {
                                        if (modelData.isPrimary)
                                            return ma.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1);
                                        return ma.containsMouse
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                                            : Qt.rgba(1, 1, 1, 0.05);
                                    }
                                    border.color: {
                                        if (modelData.isPrimary)
                                            return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, ma.containsMouse ? 0.5 : 0.25);
                                        return ma.containsMouse
                                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                                            : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15);
                                    }
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    Behavior on border.color { ColorAnimation { duration: 180 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.key
                                        font.family: Theme.font.family
                                        font.pixelSize: 10 * Appearance.effectiveScale
                                        font.weight: Font.Bold
                                        color: {
                                            if (modelData.isPrimary)
                                                return ma.containsMouse ? Theme.error : Qt.rgba(Theme.error.r + 0.1, Theme.error.g + 0.1, Theme.error.b + 0.1, 0.7);
                                            return ma.containsMouse ? Theme.primary : Qt.rgba(1, 1, 1, 0.4);
                                        }
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerMenuService.runCommand(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
