import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"
import "../core"

PanelWindow {
    id: window

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); window.glassmorphism = true; } catch(e) { window.glassmorphism = false; } }
        onLoaded: window.glassmorphism = true
        onLoadFailed: window.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    readonly property color cBg: window.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
    readonly property color cCard: window.glassmorphism ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4) : Theme.surfaceContainerHigh
    readonly property color cCardBorder: window.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
    readonly property color cTextPrimary: "#ffffff"
    readonly property color cTextSecondary: "#e2e8f0"
    readonly property color cTextMuted: Qt.rgba(255, 255, 255, 0.45)
    readonly property color cAccent: Theme.primary
    readonly property color cError: Theme.error

    property real displayPercentage: Battery.percentage
    Behavior on displayPercentage { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

    property real wavePhase: 0
    NumberAnimation on wavePhase {
        from: 0
        to: 2 * Math.PI
        duration: 2000
        loops: Animation.Infinite
        running: true
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-battery-center"
    
    WlrLayershell.keyboardFocus: BatteryCenterService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: false // Managed dynamically via transitions

    // Connections to handle custom in/out transitions before setting visibility
    Connections {
        target: BatteryCenterService
        function onVisibleChanged() {
            if (BatteryCenterService.visible) {
                window.visible = true;
                openAnimation.restart();
            } else {
                closeAnimation.restart();
            }
        }
    }

    // Smooth entrance – uses elementMoveEnter (400ms, emphasizedDecel: fast start, gentle land)
    ParallelAnimation {
        id: openAnimation
        NumberAnimation {
            target: card; property: "opacity"; from: 0.0; to: 1.0
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
        NumberAnimation {
            target: container; property: "y"
            from: 26 * Appearance.effectiveScale; to: 46 * Appearance.effectiveScale
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Appearance.animation.elementMoveEnter.type
            easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
        }
    }

    // Smooth exit – uses elementMoveExit (200ms, emphasizedAccel: snappy retract)
    ParallelAnimation {
        id: closeAnimation
        NumberAnimation {
            target: card; property: "opacity"; from: 1.0; to: 0.0
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
        NumberAnimation {
            target: container; property: "y"
            from: 46 * Appearance.effectiveScale; to: 26 * Appearance.effectiveScale
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Appearance.animation.elementMoveExit.type
            easing.bezierCurve: Appearance.animation.elementMoveExit.bezierCurve
        }
        onFinished: {
            window.visible = false;
        }
    }

    FocusScope {
        id: dashContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                BatteryCenterService.close();
                event.accepted = true;
            }
        }

        // Transparent backdrop clicking closes the window
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: BatteryCenterService.close()
            }
        }

        // Floating Card Container positioned under the battery pill in the status bar
        Item {
            id: container
            width: 330 * Appearance.effectiveScale
            height: Math.min(540 * Appearance.effectiveScale, mainColumn.implicitHeight + 36 * Appearance.effectiveScale)
            anchors.right: parent.right
            anchors.rightMargin: 40 * Appearance.effectiveScale
            y: 46 * Appearance.effectiveScale

            // Matching Drop Shadow
            DropShadow {
                anchors.fill: card
                source: card
                verticalOffset: 16 * Appearance.effectiveScale
                radius: 48 * Appearance.effectiveScale
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.4)
                transparentBorder: true
            }

            // Glassmorphic Panel Card
            Rectangle {
                id: card
                anchors.fill: parent
                radius: 24 * Appearance.effectiveScale
                color: window.cBg
                border.color: window.cCardBorder
                border.width: 1
                clip: true
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Glossy reflection overlay
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: window.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.14) }
                        GradientStop { position: 0.4; color: Qt.rgba(255, 255, 255, 0.03) }
                        GradientStop { position: 0.42; color: Qt.rgba(255, 255, 255, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
                    }
                    border.color: "transparent"
                }

                ColumnLayout {
                    id: mainColumn
                    anchors.fill: parent
                    anchors.margins: 18 * Appearance.effectiveScale
                    spacing: 14 * Appearance.effectiveScale

                    // ── HEADER (Close button removed for seamless bar integration) ──
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Battery & Power"
                            font.family: "Inter"
                            font.pixelSize: 18 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: window.cTextPrimary
                            Layout.fillWidth: true
                        }
                    }

                    // ── SECTION 1: Status & Progress Card (System Monitor Style) ──
                    Rectangle {
                        id: progressCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 126 * Appearance.effectiveScale
                        radius: 18 * Appearance.effectiveScale
                        color: window.cCard
                        border.color: window.cCardBorder
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 400 } }
                        Behavior on border.color { ColorAnimation { duration: 400 } }

                        // Hover effect scale
                        scale: statusMouseArea.containsMouse ? 1.015 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        MouseArea {
                            id: statusMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            // Large Android-style Battery Icon
                            Item {
                                id: batteryIconItem
                                width: 56 * Appearance.effectiveScale
                                height: 96 * Appearance.effectiveScale
                                Layout.preferredWidth: width
                                Layout.preferredHeight: height
                                Layout.alignment: Qt.AlignVCenter

                                // Main body
                                Rectangle {
                                    id: bodyRect
                                    anchors.fill: parent
                                    anchors.bottomMargin: 5 * Appearance.effectiveScale
                                    radius: 12 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.05)
                                    border.width: 1.5 * Appearance.effectiveScale
                                    border.color: window.cCardBorder

                                    // Wavy Fill level
                                    Item {
                                        id: fillContainer
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 4 * Appearance.effectiveScale
                                        height: (parent.height - (8 * Appearance.effectiveScale)) * window.displayPercentage
                                        clip: true

                                        property color fillColor: {
                                            if (Battery.percentage < 0.1 && !Battery.isCharging) return Theme.error;
                                            if (Battery.percentage < 0.2 && !Battery.isCharging) return "#ffc107";
                                            return Battery.isCharging ? "#4caf50" : Theme.primary;
                                        }
                                        
                                        Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                                        Behavior on fillColor { ColorAnimation { duration: 400 } }

                                        Canvas {
                                            id: waveCanvas
                                            anchors.fill: parent
                                            property real phase: window.wavePhase
                                            onPhaseChanged: waveCanvas.requestPaint()
                                            
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.reset();
                                                ctx.clearRect(0, 0, width, height);

                                                var waveHeight = 6 * Appearance.effectiveScale;
                                                var radius = 8 * Appearance.effectiveScale;
                                                ctx.fillStyle = fillContainer.fillColor;
                                                ctx.beginPath();
                                                ctx.moveTo(0, waveHeight);
                                                for (var x = 0; x <= width; x += 1) {
                                                    var y = waveHeight / 2 + (waveHeight / 2) * Math.sin(2 * Math.PI * x / width + waveCanvas.phase);
                                                    ctx.lineTo(x, y);
                                                }
                                                ctx.lineTo(width, height - radius);
                                                ctx.arcTo(width, height, width - radius, height, radius);
                                                ctx.lineTo(radius, height);
                                                ctx.arcTo(0, height, 0, height - radius, radius);
                                                ctx.closePath();
                                                ctx.fill();
                                            }
                                            
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                        }
                                    }

                                    // Charging Bolt Overlay
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "bolt"
                                        iconSize: 26 * Appearance.effectiveScale
                                        fill: 1
                                        color: "#ffffff"
                                        visible: Battery.isCharging
                                        opacity: 0.9
                                    }
                                }

                                // Battery Tip
                                Rectangle {
                                    anchors.horizontalCenter: bodyRect.horizontalCenter
                                    anchors.bottom: bodyRect.top
                                    anchors.bottomMargin: -3 * Appearance.effectiveScale
                                    width: 18 * Appearance.effectiveScale
                                    height: 5 * Appearance.effectiveScale
                                    radius: 2 * Appearance.effectiveScale
                                    color: bodyRect.color
                                    border.width: 1.5 * Appearance.effectiveScale
                                    border.color: bodyRect.border.color
                                }
                            }

                            // Details column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: Math.round(window.displayPercentage * 100) + "%"
                                        font.family: "Inter"
                                        font.pixelSize: 34 * Appearance.effectiveScale
                                        font.weight: Font.Black
                                        color: "white"
                                        Layout.fillWidth: true
                                    }

                                    // Live Wattage Draw Badge (Glassmorphic Accent)
                                    Rectangle {
                                        Layout.preferredHeight: 22 * Appearance.effectiveScale
                                        Layout.preferredWidth: 54 * Appearance.effectiveScale
                                        radius: 11 * Appearance.effectiveScale
                                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: Math.abs(Battery.energyRate).toFixed(1) + " W"
                                            font.family: "Inter"
                                            font.pixelSize: 10 * Appearance.effectiveScale
                                            font.weight: Font.Bold
                                            color: Theme.primary
                                        }
                                    }
                                }

                                Text {
                                    text: Battery.isCharging ? "Charging" : (Battery.chargeState === 4 ? "Fully Charged" : "Discharging")
                                    font.family: "Inter"
                                    font.pixelSize: 13 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }

                                Text {
                                    text: {
                                        const secs = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                                        if (!secs || secs <= 0) return "Calculating remaining time...";
                                        const h = Math.floor(secs / 3600);
                                        const m = Math.floor((secs % 3600) / 60);
                                        return (Battery.isCharging ? "Time to full: " : "Time remaining: ") + (h > 0 ? h + "h " + m + "m" : m + "m");
                                    }
                                    font.family: "Inter"
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    color: window.cTextSecondary
                                }

                                Text {
                                    text: Battery.isPluggedIn ? "Power Source: AC Adapter" : "Power Source: Internal Battery"
                                    font.family: "Inter"
                                    font.pixelSize: 9 * Appearance.effectiveScale
                                    color: window.cTextMuted
                                }
                            }
                        }
                    }

                    // ── SECTION 2: Power Profiles Selector ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale

                        Text {
                            text: "Power Mode"
                            font.family: "Inter"
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: window.cTextMuted
                            Layout.leftMargin: 2 * Appearance.effectiveScale
                        }

                        // M3 Segmented Pill (Long pill with sliding indicator)
                        Rectangle {
                            id: segmentedPill
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38 * Appearance.effectiveScale
                            radius: 19 * Appearance.effectiveScale
                            color: window.cCard
                            border.color: window.cCardBorder
                            border.width: 1
                            clip: true

                            readonly property var profiles: ["power-saver", "balanced", "performance"]
                            readonly property var labels: ["Saver", "Balanced", "Performance"]
                            readonly property var icons: ["eco", "balance", "speed"]
                            readonly property int activeIndex: PowerProfiles.activeProfile === "power-saver" ? 0 : (PowerProfiles.activeProfile === "balanced" ? 1 : 2)

                            function getProfileColor(idx) {
                                if (idx === 0) return "#4caf50";
                                if (idx === 1) return Theme.primary;
                                if (idx === 2) return "#ff5722";
                                return Theme.primary;
                            }

                            function getProfileTint(idx) {
                                if (idx === 0) return Qt.rgba(76/255, 175/255, 80/255, 0.22);
                                if (idx === 1) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22);
                                if (idx === 2) return Qt.rgba(255/255, 87/255, 34/255, 0.22);
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22);
                            }

                            // Sliding highlight indicator
                            Rectangle {
                                id: sliderIndicator
                                height: parent.height - 8 * Appearance.effectiveScale
                                width: (parent.width - 8 * Appearance.effectiveScale) / 3
                                y: 4 * Appearance.effectiveScale
                                radius: 15 * Appearance.effectiveScale
                                color: segmentedPill.getProfileTint(segmentedPill.activeIndex)
                                border.color: segmentedPill.getProfileColor(segmentedPill.activeIndex)
                                border.width: 1

                                x: 4 * Appearance.effectiveScale + segmentedPill.activeIndex * width

                                Behavior on x {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: 200 }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                Repeater {
                                    model: 3
                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        readonly property bool isActive: segmentedPill.activeIndex === index

                                        RippleButton {
                                            id: profileBtn
                                            anchors.fill: parent
                                            colBackground: "transparent"
                                            colBackgroundHover: "transparent"
                                            colBackgroundToggled: "transparent"
                                            
                                            onClicked: {
                                                PowerProfiles.setProfile(segmentedPill.profiles[index]);
                                            }

                                            MouseArea {
                                                id: buttonMouseArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: profileBtn.clicked()
                                            }

                                            contentItem: RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 5 * Appearance.effectiveScale

                                                MaterialSymbol {
                                                    text: segmentedPill.icons[index]
                                                    iconSize: 14 * Appearance.effectiveScale
                                                    color: isActive ? segmentedPill.getProfileColor(index) : window.cTextSecondary
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }

                                                Text {
                                                    text: segmentedPill.labels[index]
                                                    font.family: "Inter"
                                                    font.pixelSize: 11 * Appearance.effectiveScale
                                                    font.weight: Font.Bold
                                                    color: isActive ? segmentedPill.getProfileColor(index) : window.cTextSecondary
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── SECTION 3: Detailed Battery Stats ──
                    GridLayout {
                        id: statsGrid
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 10 * Appearance.effectiveScale
                        columnSpacing: 10 * Appearance.effectiveScale

                        readonly property var titles: ["Capacity Health", "Charge Cycles", "Battery Voltage", "Battery Tech"]
                        readonly property var values: [
                            Battery.health > 0 ? Math.round(Battery.health) + "%" : "N/A",
                            Battery.cycles > 0 ? Battery.cycles.toString() : "0",
                            Battery.voltage > 0 ? Battery.voltage.toFixed(2) + " V" : "N/A",
                            Battery.technology || "Li-Polymer"
                        ]
                        readonly property var icons: ["favorite", "sync", "electric_bolt", "memory"]

                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52 * Appearance.effectiveScale
                                radius: 14 * Appearance.effectiveScale
                                color: window.cCard
                                border.color: window.cCardBorder
                                border.width: 1

                                scale: statMouse.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                MouseArea {
                                    id: statMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12 * Appearance.effectiveScale
                                    anchors.rightMargin: 12 * Appearance.effectiveScale
                                    spacing: 8 * Appearance.effectiveScale

                                    Rectangle {
                                        Layout.preferredWidth: 26 * Appearance.effectiveScale
                                        Layout.preferredHeight: 26 * Appearance.effectiveScale
                                        radius: 13 * Appearance.effectiveScale
                                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: statsGrid.icons[index]
                                            iconSize: 13 * Appearance.effectiveScale
                                            color: Theme.primary
                                        }
                                    }

                                    ColumnLayout {
                                        spacing: 1 * Appearance.effectiveScale
                                        Layout.fillWidth: true

                                        Text {
                                            text: statsGrid.titles[index]
                                            font.family: "Inter"
                                            font.pixelSize: 9 * Appearance.effectiveScale
                                            font.weight: Font.Bold
                                            color: window.cTextMuted
                                        }
                                        Text {
                                            text: statsGrid.values[index]
                                            font.family: "Inter"
                                            font.pixelSize: 13 * Appearance.effectiveScale
                                            font.weight: Font.Bold
                                            color: window.cTextPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── SECTION 4: Conservation Mode ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52 * Appearance.effectiveScale
                        radius: 18 * Appearance.effectiveScale
                        color: window.cCard
                        border.color: window.cCardBorder
                        border.width: 1

                        scale: consMouse.containsMouse ? 1.015 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }

                        MouseArea {
                            id: consMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14 * Appearance.effectiveScale
                            anchors.rightMargin: 14 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "battery_saver"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Battery.conservationMode ? "#4caf50" : window.cTextSecondary
                            }

                            ColumnLayout {
                                spacing: 1 * Appearance.effectiveScale
                                Layout.fillWidth: true
                                Layout.leftMargin: 6 * Appearance.effectiveScale

                                Text {
                                    text: "Conservation Mode"
                                    font.family: "Inter"
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: window.cTextPrimary
                                }

                                Text {
                                    text: "Limits charge to 80% to protect lifespan"
                                    font.family: "Inter"
                                    font.pixelSize: 9 * Appearance.effectiveScale
                                    color: window.cTextMuted
                                }
                            }

                            // Custom M3 Switch Pill (Using System Monitor Battery Service state)
                            Item {
                                id: conservationSwitch
                                Layout.preferredWidth: 52 * Appearance.effectiveScale
                                Layout.preferredHeight: 32 * Appearance.effectiveScale

                                Rectangle {
                                    id: toggleTrack
                                    anchors.fill: parent
                                    radius: 16 * Appearance.effectiveScale
                                    color: Battery.conservationMode ? Theme.primary : Qt.rgba(255, 255, 255, 0.12)
                                    border.width: Battery.conservationMode ? 0 : 1.5
                                    border.color: Battery.conservationMode ? "transparent" : Qt.rgba(255, 255, 255, 0.25)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                Rectangle {
                                    id: toggleThumb
                                    width: 24 * Appearance.effectiveScale
                                    height: 24 * Appearance.effectiveScale
                                    radius: 12 * Appearance.effectiveScale
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Battery.conservationMode ? toggleTrack.width - width - 4 * Appearance.effectiveScale : 4 * Appearance.effectiveScale
                                    color: "#ffffff"
                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                    // Checkmark icon when ON
                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: "check"
                                        size: 14 * Appearance.effectiveScale
                                        color: Theme.primary
                                        opacity: Battery.conservationMode ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Battery.toggleConservationMode()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
