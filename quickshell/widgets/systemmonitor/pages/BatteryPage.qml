import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"
import "../../../theme"

/**
 * Enhanced Battery Stats page for System Monitor (v1.2).
 * Provides deep technical details and Android-inspired visuals.
 */
Flickable {
    id: root
    contentHeight: mainCol.implicitHeight + (100 * Appearance.effectiveScale)
    clip: true
    
    // Smooth value for battery bar
    property real displayPercentage: Battery.percentage
    Behavior on displayPercentage { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

    ColumnLayout {
        id: mainCol
        width: parent.width - (64 * Appearance.effectiveScale)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 32 * Appearance.effectiveScale
        spacing: 32 * Appearance.effectiveScale

        // ── 1. Hero Battery Visual ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 32 * Appearance.effectiveScale

            // Large Android-style Battery Icon (Matching Status Bar style)
            Item {
                id: batteryIconItem
                width: 100 * Appearance.effectiveScale
                height: 160 * Appearance.effectiveScale
                Layout.preferredWidth: width
                Layout.preferredHeight: height
                Layout.alignment: Qt.AlignVCenter

                // Main body
                Rectangle {
                    id: bodyRect
                    anchors.fill: parent
                    anchors.bottomMargin: 8 * Appearance.effectiveScale
                    radius: 16 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    border.width: 2 * Appearance.effectiveScale
                    border.color: fillContainer.fillColor

                    // Wavy Fill level
                    Item {
                        id: fillContainer
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 6 * Appearance.effectiveScale
                        height: (parent.height - (12 * Appearance.effectiveScale)) * root.displayPercentage
                        clip: true

                        property real phase: 0
                        NumberAnimation on phase {
                            from: 0
                            to: 2 * Math.PI
                            duration: 2000
                            loops: Animation.Infinite
                            running: true
                        }

                        property color fillColor: {
                            if (Battery.isCharging) return "#4caf50";
                            if (Battery.isCritical) return "#f44336";
                            if (Battery.isLow) return "#ffc107";
                            return Theme.primary;
                        }
                        
                        Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                        Behavior on fillColor { ColorAnimation { duration: 400 } }

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            property real phase: fillContainer.phase
                            onPhaseChanged: waveCanvas.requestPaint()
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.clearRect(0, 0, width, height);

                                var waveHeight = 8 * Appearance.effectiveScale;
                                
                                var radius = 10 * Appearance.effectiveScale;
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

                    // Custom Charging Bolt Overlay
                    Image {
                        id: chargingBolt
                        anchors.centerIn: parent
                        source: "file:///home/sawmer/.config/quickshell/assets/bolt.svg"
                        sourceSize.width: 40 * Appearance.effectiveScale
                        sourceSize.height: 40 * Appearance.effectiveScale
                        width: 40 * Appearance.effectiveScale
                        height: 40 * Appearance.effectiveScale
                        fillMode: Image.PreserveAspectFit
                        visible: Battery.isCharging
                        smooth: true
                        antialiasing: true

                        // Pulsing breathing animation
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: Battery.isCharging
                            
                            NumberAnimation {
                                from: 0.3
                                to: 1.0
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                from: 1.0
                                to: 0.3
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }

                // Battery Tip
                Rectangle {
                    anchors.horizontalCenter: bodyRect.horizontalCenter
                    anchors.bottom: bodyRect.top
                    anchors.bottomMargin: -6 * Appearance.effectiveScale
                    width: 32 * Appearance.effectiveScale
                    height: 8 * Appearance.effectiveScale
                    radius: 3 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    border.width: 2 * Appearance.effectiveScale
                    border.color: bodyRect.border.color
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                
                StyledText {
                    text: Math.round(root.displayPercentage * 100) + "%"
                    font.pixelSize: 64 * Appearance.effectiveScale // Keep this large and scaled
                    font.weight: Font.Black
                    color: "white"
                }

                StyledText {
                    text: Battery.isCharging ? "Charging" : (Battery.chargeState === 4 ? "Fully Charged" : "Discharging")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Theme.primary
                }

                StyledText {
                    text: {
                        if (Battery.isCharging && Battery.timeToFull > 0) return `${Math.round(Battery.timeToFull / 60)} mins until full`;
                        if (!Battery.isCharging && Battery.timeToEmpty > 0) return `${Math.round(Battery.timeToEmpty / 60)} mins remaining`;
                        return Battery.isPluggedIn ? "Power Source: AC Adapter" : "Power Source: Internal Battery";
                    }
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: "white"
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: mainCol.width < 450 * Appearance.effectiveScale ? 1 : (mainCol.width < 800 * Appearance.effectiveScale ? 2 : 4)
            columnSpacing: 16 * Appearance.effectiveScale
            rowSpacing: 16 * Appearance.effectiveScale

            StatCard {
                Layout.fillWidth: true
                title: "Health"
                value: Battery.health > 0 ? (Math.round(Battery.health) + "%") : "N/A"
                icon: "favorite"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Life cycle"
            }

            StatCard {
                Layout.fillWidth: true
                title: "Usage"
                value: Battery.energyRate > 0 ? (Battery.energyRate.toFixed(1) + " W") : "0.0 W"
                icon: "bolt"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Power rate"
            }

            StatCard {
                Layout.fillWidth: true
                title: "Voltage"
                value: Battery.voltage > 0 ? (Battery.voltage.toFixed(2) + " V") : "N/A"
                icon: "electric_bolt"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Current"
            }

            // Conservation Mode Toggler Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 120 * Appearance.effectiveScale
                radius: 24 * Appearance.effectiveScale
                color: Appearance.colors.colLayer1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 4 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        MaterialSymbol { 
                            text: "shield_moon"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Battery.conservationMode ? "#81C995" : "#FF8A65" 
                        }
                        StyledText { 
                            text: "Conservation Mode"
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Medium
                            color: "white"
                            Layout.fillWidth: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        
                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            StyledText {
                                text: Battery.conservationMode ? "Enabled" : "Disabled"
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: "white"
                            }
                            StyledText {
                                text: "Caps charge at 60%"
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                color: "white"
                                opacity: 0.5
                            }
                        }

                        // Material You Styled Switch Button (Matching Wifi Toggle style)
                        Item {
                            width: 52 * Appearance.effectiveScale
                            height: 32 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter
                            
                            Rectangle {
                                id: toggleTrack
                                anchors.fill: parent
                                radius: 16 * Appearance.effectiveScale
                                color: Battery.conservationMode ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                                border.width: Battery.conservationMode ? 0 : 2 * Appearance.effectiveScale
                                border.color: Qt.rgba(255, 255, 255, 0.2)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Rectangle {
                                id: toggleThumb
                                width: Battery.conservationMode ? 24 * Appearance.effectiveScale : 16 * Appearance.effectiveScale
                                height: width
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: Battery.conservationMode 
                                    ? toggleTrack.width - width - (4 * Appearance.effectiveScale) 
                                    : (6 * Appearance.effectiveScale)
                                color: Battery.conservationMode ? Appearance.colors.colLayer1 : Qt.rgba(255, 255, 255, 0.7)
                                
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on width { NumberAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                // Checkmark icon when ON
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "check"
                                    iconSize: 14 * Appearance.effectiveScale
                                    color: Theme.primary
                                    opacity: Battery.conservationMode ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Battery.toggleConservationMode();
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── 2.5 Power Profile Selection ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale
            visible: PowerProfiles.isAvailable

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                Layout.leftMargin: 4 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "speed"
                    iconSize: 18 * Appearance.effectiveScale
                    color: Theme.primary
                }
                StyledText {
                    text: "Power Profile"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 72 * Appearance.effectiveScale
                radius: 24 * Appearance.effectiveScale
                color: Appearance.colors.colLayer1
                border.width: 1 * Appearance.effectiveScale
                border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    Repeater {
                        model: ["power-saver", "balanced", "performance"]
                        
                        delegate: Rectangle {
                            id: btn
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 16 * Appearance.effectiveScale
                            
                            readonly property string profile: modelData
                            readonly property bool isActive: PowerProfiles.activeProfile === profile
                            
                            readonly property color profileColor: {
                                if (profile === "performance") return "#ef5350";
                                if (profile === "power-saver") return "#4caf50";
                                return "#ff9800";
                            }
                            
                            color: isActive ? Qt.rgba(profileColor.r, profileColor.g, profileColor.b, 0.15) : "transparent"
                            border.width: isActive ? 1.5 * Appearance.effectiveScale : 1 * Appearance.effectiveScale
                            border.color: isActive ? profileColor : Qt.rgba(255, 255, 255, 0.1)
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: PowerProfiles.getProfileIcon(profile)
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: btn.isActive ? btn.profileColor : Qt.rgba(255, 255, 255, 0.6)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                StyledText {
                                    text: PowerProfiles.getProfileLabel(profile)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: btn.isActive ? Font.Bold : Font.Normal
                                    color: btn.isActive ? btn.profileColor : Qt.rgba(255, 255, 255, 0.8)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                
                                onEntered: {
                                    if (!btn.isActive) {
                                        btn.color = Qt.rgba(255, 255, 255, 0.05);
                                    }
                                }
                                onExited: {
                                    if (!btn.isActive) {
                                        btn.color = "transparent";
                                    }
                                }
                                onClicked: {
                                    PowerProfiles.setProfile(profile);
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── 3. Technical Specifications ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                Layout.leftMargin: 4 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "info"
                    iconSize: 18 * Appearance.effectiveScale
                    color: Theme.primary
                }
                StyledText {
                    text: "Hardware Information"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: techGrid.implicitHeight + (40 * Appearance.effectiveScale)
                radius: 24 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                border.width: 1 * Appearance.effectiveScale
                border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

                GridLayout {
                    id: techGrid
                    anchors.fill: parent
                    anchors.margins: 24 * Appearance.effectiveScale
                    columns: parent.width < 350 * Appearance.effectiveScale ? 1 : 2
                    rowSpacing: 20 * Appearance.effectiveScale
                    columnSpacing: 40 * Appearance.effectiveScale

                    TechInfo { label: "Vendor"; value: Battery.vendor || "Unknown" }
                    TechInfo { label: "Model"; value: Battery.model || "Generic Battery" }
                    TechInfo { label: "Technology"; value: Battery.technology }
                    TechInfo { label: "Serial Number"; value: Battery.serial || "Not Available" }
                    TechInfo { label: "Design Capacity"; value: (Battery.energyFullDesign).toFixed(2) + " Wh" }
                    TechInfo { label: "Full Capacity"; value: (Battery.energyFull).toFixed(2) + " Wh" }
                }
            }
        }

        Item { Layout.preferredHeight: 20 * Appearance.effectiveScale }
    }

    // ── Internal Components ──

    component StatCard: Rectangle {
        id: cardRoot
        property string title
        property string value
        property string subtitle
        property string icon
        property color iconColor: Appearance.colors.colPrimary
        
        implicitHeight: 120 * Appearance.effectiveScale
        radius: 24 * Appearance.effectiveScale
        color: Appearance.colors.colLayer1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 4 * Appearance.effectiveScale

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol { text: cardRoot.icon; iconSize: 18 * Appearance.effectiveScale; color: cardRoot.iconColor }
                StyledText { 
                    text: cardRoot.title
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Medium
                    color: "white"
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            StyledText {
                text: cardRoot.value
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: "white"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                text: cardRoot.subtitle
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: "white"
                opacity: 0.7
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    component TechInfo: ColumnLayout {
        id: infoRoot
        property string label
        property string value
        spacing: 2 * Appearance.effectiveScale
        Layout.fillWidth: true

        StyledText {
            text: infoRoot.label
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.Medium
            color: "white"
        }
        StyledText {
            text: infoRoot.value
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: "white"
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
