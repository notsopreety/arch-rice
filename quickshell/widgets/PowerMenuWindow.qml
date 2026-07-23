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

        property string confirmCommand: ""
        property string confirmName: ""
        
        function showConfirmation(name, cmd) {
            confirmName = name;
            confirmCommand = cmd;
        }
        
        function hideConfirmation() {
            confirmCommand = "";
        }
        
        function isSensitive(cmd) {
            return cmd === "reboot" || cmd === "logout" || cmd === "poweroff";
        }
        
        property string pendingKeyCmd: ""
        property string pendingKeyName: ""
        property bool keyLongPressed: false
        property var keyPressTime: 0
        Timer {
            id: keyHoldTimer
            interval: 800
            onTriggered: {
                menuContent.keyLongPressed = true;
                if (menuContent.pendingKeyCmd !== "") {
                    PowerMenuService.runCommand(menuContent.pendingKeyCmd);
                    menuContent.pendingKeyCmd = "";
                }
            }
        }

        // Escape to close and shortcut buttons
        Keys.onPressed: (event) => {
            if (event.isAutoRepeat) return;
            
            if (event.key === Qt.Key_Escape) {
                if (confirmCommand !== "") {
                    hideConfirmation();
                } else {
                    PowerMenuService.close();
                }
                return;
            }
            
            var cmd = "";
            var name = "";
            if (event.key === Qt.Key_L) { cmd = "lock"; name = "Lock"; }
            else if (event.key === Qt.Key_S) { cmd = "sleep"; name = "Sleep"; }
            else if (event.key === Qt.Key_Q) { cmd = "reload"; name = "Reload QML"; }
            else if (event.key === Qt.Key_R) { cmd = "reboot"; name = "Restart"; }
            else if (event.key === Qt.Key_X) { cmd = "logout"; name = "Log Out"; }
            else if (event.key === Qt.Key_P) { cmd = "poweroff"; name = "Power Off"; }
            
            if (cmd !== "") {
                if (isSensitive(cmd)) {
                    if (pendingKeyCmd !== cmd) {
                        pendingKeyCmd = cmd;
                        pendingKeyName = name;
                        keyLongPressed = false;
                        keyPressTime = Date.now();
                        keyHoldTimer.restart();
                    }
                } else {
                    PowerMenuService.runCommand(cmd);
                }
            }
        }
        
        Keys.onReleased: (event) => {
            if (event.isAutoRepeat) return;
            
            if (pendingKeyCmd !== "") {
                keyHoldTimer.stop();
                if (!keyLongPressed) {
                    // Only show confirmation if it was a quick tap (under 150ms)
                    // If they held it longer but released before 800ms, it's an aborted hold (do nothing)
                    if (Date.now() - keyPressTime < 150) {
                        showConfirmation(pendingKeyName, pendingKeyCmd);
                    }
                }
                pendingKeyCmd = "";
            }
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

                Item {
                    id: viewSwitcher
                    anchors.fill: parent

                    Row {
                        id: buttonsRow
                        anchors.centerIn: parent
                        spacing: Styling.spacingSmall * Appearance.effectiveScale
                        
                        opacity: menuContent.confirmCommand === "" ? 1.0 : 0.0
                        scale: menuContent.confirmCommand === "" ? 1.0 : 0.95
                        enabled: menuContent.confirmCommand === ""
                        
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

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

                                // Material You 3 Snake Stroke (Live Progress)
                                ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: modelData.isPrimary ? Theme.error : Theme.primary
                                    strokeWidth: 4 * Appearance.effectiveScale
                                    capStyle: ShapePath.RoundCap
                                    joinStyle: ShapePath.RoundJoin
                                    strokeStyle: ShapePath.DashLine
                                    property real perimeterUnits: 800 / (4 * Appearance.effectiveScale)
                                    dashPattern: [ perimeterUnits * btnDelegate.holdProgress, perimeterUnits ]
                                    dashOffset: 0

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

                            property real holdProgress: 0.0
                            property real lastHoldProgress: 0.0
                            NumberAnimation {
                                id: holdAnim
                                target: btnDelegate
                                property: "holdProgress"
                                from: 0.0
                                to: 1.0
                                duration: 800
                                running: (ma.pressed && menuContent.isSensitive(modelData.cmd)) || (menuContent.pendingKeyCmd === modelData.cmd)
                                onRunningChanged: {
                                    if (!running) {
                                        lastHoldProgress = holdProgress;
                                        holdProgress = 0.0;
                                    }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                property bool isHold: false
                                pressAndHoldInterval: 800
                                
                                onPressed: {
                                    isHold = false;
                                }
                                
                                onPressAndHold: {
                                    if (menuContent.isSensitive(modelData.cmd)) {
                                        isHold = true;
                                        PowerMenuService.runCommand(modelData.cmd);
                                    }
                                }
                                
                                onClicked: {
                                    if (isHold) return;
                                    
                                    // If user started holding but released midway (aborted hold), cancel the action entirely.
                                    if (btnDelegate.lastHoldProgress > 0.15) return;
                                    
                                    if (menuContent.isSensitive(modelData.cmd)) {
                                        menuContent.showConfirmation(modelData.name, modelData.cmd);
                                    } else {
                                        PowerMenuService.runCommand(modelData.cmd);
                                    }
                                }
                            }
                        }
                    }
                } // closes buttonsRow

                    // Material You 3 Confirmation View
                    Item {
                        id: confirmView
                        anchors.fill: parent
                        
                        opacity: menuContent.confirmCommand !== "" ? 1.0 : 0.0
                        scale: menuContent.confirmCommand !== "" ? 1.0 : 0.95
                        enabled: menuContent.confirmCommand !== ""
                        
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                        // Material 3 Icon for Confirmation in Top Right removed as requested

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12 * Appearance.effectiveScale

                            Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: menuContent.confirmName + "?"
                            font.family: Theme.font.family
                            font.pixelSize: 22 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Are you sure you want to proceed?"
                            font.family: Theme.font.family
                            font.pixelSize: 13 * Appearance.effectiveScale
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 16 * Appearance.effectiveScale
                            Layout.topMargin: 8 * Appearance.effectiveScale

                            // Material 3 Cancel Button (Surface Variant)
                            Rectangle {
                                id: cancelBtn
                                width: 120 * Appearance.effectiveScale
                                height: 40 * Appearance.effectiveScale
                                radius: cancelMa.containsMouse ? 20 * Appearance.effectiveScale : 8 * Appearance.effectiveScale
                                color: cancelMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.1)

                                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                transform: Scale {
                                    origin.x: cancelBtn.width / 2
                                    origin.y: cancelBtn.height / 2
                                    xScale: cancelMa.pressed ? 0.92 : 1.0
                                    yScale: xScale
                                    Behavior on xScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: "#ffffff"
                                    font.family: Theme.font.family
                                    font.pixelSize: 14 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: cancelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: menuContent.hideConfirmation()
                                }
                            }

                            // Material 3 Confirm Button (Primary)
                            Rectangle {
                                id: confirmBtn
                                width: 120 * Appearance.effectiveScale
                                height: 40 * Appearance.effectiveScale
                                radius: confirmMa.containsMouse ? 20 * Appearance.effectiveScale : 8 * Appearance.effectiveScale
                                color: confirmMa.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                                
                                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                transform: Scale {
                                    origin.x: confirmBtn.width / 2
                                    origin.y: confirmBtn.height / 2
                                    xScale: confirmMa.pressed ? 0.92 : 1.0
                                    yScale: xScale
                                    Behavior on xScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: menuContent.confirmName
                                    color: Theme.onPrimary
                                    font.family: Theme.font.family
                                    font.pixelSize: 14 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                }
                                MouseArea {
                                    id: confirmMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        PowerMenuService.runCommand(menuContent.confirmCommand);
                                        menuContent.hideConfirmation();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
