import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../theme"
import "../../../services"
import "../../"

Item {
    id: root

    // Required by OSD loader interface
    readonly property bool isSliderPressed: false

    implicitWidth: 340 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale

    readonly property bool active: OsdService.airplaneModeActive

    property bool isReady: false
    property real flightDirection: 1.0 // 1.0 for right, -1.0 for left

    Component.onCompleted: {
        // Trigger initial flight animation when OSD loads
        if (active) {
            root.flightDirection = 1.0;
            flyOnAnim.restart();
        } else {
            root.flightDirection = -1.0;
            flyOffAnim.restart();
        }
        isReady = true;
    }

    onActiveChanged: {
        if (!isReady) return;
        if (active) {
            root.flightDirection = 1.0;
            flyOnAnim.restart();
        } else {
            root.flightDirection = -1.0;
            flyOffAnim.restart();
        }
    }

    // Main Glassmorphic Container
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.18)
        border.width: 1

        // Glossy glare reflection overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.16) }
                GradientStop { position: 0.4; color: Qt.rgba(255, 255, 255, 0.04) }
                GradientStop { position: 0.42; color: Qt.rgba(255, 255, 255, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
            }
            border.color: "transparent"
        }

        // Content Row Layout
        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.leftMargin: 12 * Appearance.effectiveScale
            anchors.rightMargin: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ── Left Slot: Static Badge Wrapper ──
            Item {
                id: staticIconWrapper
                Layout.preferredWidth: 32 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter

                MaterialShapeWrappedMaterialSymbol {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height

                    shapeString: "Gem"
                    text: root.active ? "airplanemode_active" : "airplanemode_inactive"
                    iconSize: 18 * Appearance.effectiveScale

                    color: root.active ? Theme.primaryContainer : Qt.rgba(255, 255, 255, 0.1)
                    colSymbol: "#ffffff"
                }
            }

            // ── Center Slot: Glassmorphic Status Pill with Internal Flight ──
            Rectangle {
                id: textWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 16 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.20)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                clip: true // Keep airplane clipped inside center pill

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: "Airplane Mode • " + (root.active ? "On" : "Off")
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Simple & Clean Dash Lines Trail ──
                Repeater {
                    model: 4
                    Rectangle {
                        id: trailDash
                        width: (4 - index) * 3 * Appearance.effectiveScale
                        height: 1.5 * Appearance.effectiveScale
                        radius: 1
                        color: Qt.rgba(255, 255, 255, 0.45 - index * 0.09)
                        
                        // Calculated behind the flight actor to form dashed trail
                        x: (flightActor.x + (flightActor.width / 2)) - (root.flightDirection * index * 10 * flightScale.xScale) - (root.flightDirection * 12)
                        y: flightActor.y + (flightActor.height / 2) - (height / 2)
                        opacity: flightActor.opacity

                        visible: flightActor.opacity > 0.01
                    }
                }

                // ── Airplane Flight Actor (Size adjusted to fit without clipping) ──
                MaterialSymbol {
                    id: flightActor
                    x: 0
                    y: (parent.height - height) / 2
                    width: 20 * Appearance.effectiveScale
                    height: 20 * Appearance.effectiveScale

                    text: "flight"
                    iconSize: 16 * Appearance.effectiveScale
                    color: "#ffffff"
                    opacity: 0

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    transform: [
                        Rotation { 
                            id: flightRotation
                            origin.x: 10 * Appearance.effectiveScale
                            origin.y: 10 * Appearance.effectiveScale
                            angle: 90 // Face horizontal right
                        },
                        Scale {
                            id: flightScale
                            origin.x: 10 * Appearance.effectiveScale
                            origin.y: 10 * Appearance.effectiveScale
                            xScale: 1.0
                            yScale: 1.0
                        }
                    ]
                }
            }

            // ── Right Slot: Category Label ──
            Rectangle {
                id: contextSlot
                Layout.preferredWidth: 44 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 12 * Appearance.effectiveScale
                color: root.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : Theme.secondaryContainer
                border.color: root.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "AIR"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: root.active ? Theme.primary : "#ffffff"
                    opacity: 0.9

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    // ── Toggle ON Animation ──
    SequentialAnimation {
        id: flyOnAnim

        // 1. Wait for OSD window slide/fade entrance (so user sees entire flight)
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare actor
        ParallelAnimation {
            PropertyAction { target: flightActor; property: "x"; value: -30 }
            PropertyAction { target: flightRotation; property: "angle"; value: 90 }
            PropertyAction { target: flightScale; property: "xScale"; value: 0.7 }
            PropertyAction { target: flightScale; property: "yScale"; value: 0.7 }
            PropertyAction { target: flightActor; property: "opacity"; value: 0.0 }
        }

        // 4. Flight path across the center pill
        ParallelAnimation {
            NumberAnimation {
                target: flightActor
                property: "x"
                from: -30
                to: textWrapper.width + 30
                duration: 950
                easing.type: Easing.InOutQuad
            }

            // Safe scale peak inside 32px height constraint
            SequentialAnimation {
                NumberAnimation { target: flightScale; property: "xScale"; from: 0.7; to: 1.35; duration: 475; easing.type: Easing.OutSine }
                NumberAnimation { target: flightScale; property: "yScale"; from: 0.7; to: 1.35; duration: 475; easing.type: Easing.OutSine }
                NumberAnimation { target: flightScale; property: "xScale"; from: 1.35; to: 0.7; duration: 475; easing.type: Easing.InSine }
                NumberAnimation { target: flightScale; property: "yScale"; from: 1.35; to: 0.7; duration: 475; easing.type: Easing.InSine }
            }

            // Opacity fade in and out
            SequentialAnimation {
                NumberAnimation { target: flightActor; property: "opacity"; from: 0.0; to: 1.0; duration: 120 }
                PauseAnimation { duration: 710 }
                NumberAnimation { target: flightActor; property: "opacity"; from: 1.0; to: 0.0; duration: 120 }
            }
        }

        // 5. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }

    // ── Toggle OFF Animation ──
    SequentialAnimation {
        id: flyOffAnim

        // 1. Wait for OSD window slide/fade entrance (so user sees entire flight)
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare actor
        ParallelAnimation {
            PropertyAction { target: flightActor; property: "x"; value: textWrapper.width + 30 }
            PropertyAction { target: flightRotation; property: "angle"; value: -90 }
            PropertyAction { target: flightScale; property: "xScale"; value: 0.7 }
            PropertyAction { target: flightScale; property: "yScale"; value: 0.7 }
            PropertyAction { target: flightActor; property: "opacity"; value: 0.0 }
        }

        // 4. Flight path backward across the center pill
        ParallelAnimation {
            NumberAnimation {
                target: flightActor
                property: "x"
                from: textWrapper.width + 30
                to: -30
                duration: 950
                easing.type: Easing.InOutQuad
            }

            // Safe scale peak inside 32px height constraint
            SequentialAnimation {
                NumberAnimation { target: flightScale; property: "xScale"; from: 0.7; to: 1.35; duration: 475; easing.type: Easing.OutSine }
                NumberAnimation { target: flightScale; property: "yScale"; from: 0.7; to: 1.35; duration: 475; easing.type: Easing.OutSine }
                NumberAnimation { target: flightScale; property: "xScale"; from: 1.35; to: 0.7; duration: 475; easing.type: Easing.InSine }
                NumberAnimation { target: flightScale; property: "yScale"; from: 1.35; to: 0.7; duration: 475; easing.type: Easing.InSine }
            }

            // Opacity fade in and out
            SequentialAnimation {
                NumberAnimation { target: flightActor; property: "opacity"; from: 0.0; to: 1.0; duration: 120 }
                PauseAnimation { duration: 710 }
                NumberAnimation { target: flightActor; property: "opacity"; from: 1.0; to: 0.0; duration: 120 }
            }
        }

        // 5. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
