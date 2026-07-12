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

    readonly property bool active: OsdService.nightLightActive

    property bool isReady: false

    Component.onCompleted: {
        anim.restart();
        isReady = true;
    }

    onActiveChanged: {
        if (isReady) {
            anim.restart();
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

        // Glossy glare reflection
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
                    text: root.active ? "nightlight" : "sunny"
                    iconSize: 18 * Appearance.effectiveScale

                    color: root.active ? Qt.rgba(255/255, 140/255, 0/255, 0.25) : Qt.rgba(255, 255, 255, 0.1)
                    colSymbol: "#ffffff"
                }
            }

            // ── Center Slot: Glassmorphic Status Pill ──
            Rectangle {
                id: textWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 16 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.20)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                clip: true

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: "Night Light • " + (root.active ? "On (4000K)" : "Off")
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Expanding Warmth Aura ──
                Rectangle {
                    id: warmthRing
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    radius: width / 2
                    color: "transparent"
                    border.color: root.active ? "#ff8c00" : "#00b0ff" // Orange or blue/white
                    border.width: 1.5 * Appearance.effectiveScale
                    opacity: 0
                    scale: 0.5
                }

                // ── Animated Sun/Moon Actor ──
                MaterialSymbol {
                    id: animIcon
                    anchors.centerIn: parent
                    text: root.active ? "sunny" : "nightlight"
                    iconSize: 18 * Appearance.effectiveScale
                    color: "#ffffff"
                    opacity: 0

                    transform: [
                        Rotation {
                            id: iconRotation
                            origin.x: animIcon.width / 2
                            origin.y: animIcon.height / 2
                            angle: 0
                        },
                        Scale {
                            id: iconScale
                            origin.x: animIcon.width / 2
                            origin.y: animIcon.height / 2
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
                color: root.active ? Qt.rgba(255/255, 140/255, 0/255, 0.25) : Theme.secondaryContainer
                border.color: root.active ? Qt.rgba(255/255, 140/255, 0/255, 0.4) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "LGT"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: root.active ? "#ff8c00" : "#ffffff"
                    opacity: 0.9

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    // ── Animation Sequence ──
    SequentialAnimation {
        id: anim

        // 1. Wait for OSD window slide/fade
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare initial state of morph actor
        ScriptAction {
            script: {
                animIcon.text = root.active ? "sunny" : "nightlight";
                animIcon.color = root.active ? "#ffffff" : "#ffca28";
            }
        }
        ParallelAnimation {
            PropertyAction { target: animIcon; property: "opacity"; value: 1.0 }
            PropertyAction { target: iconScale; property: "xScale"; value: 0.6 }
            PropertyAction { target: iconScale; property: "yScale"; value: 0.6 }
            PropertyAction { target: iconRotation; property: "angle"; value: 0 }
            PropertyAction { target: warmthRing; property: "opacity"; value: 0.0 }
            PropertyAction { target: warmthRing; property: "scale"; value: 0.5 }
        }

        // 4. Spin and scale sun/moon up
        ParallelAnimation {
            NumberAnimation { target: iconScale; property: "xScale"; to: 1.3; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: iconScale; property: "yScale"; to: 1.3; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: iconRotation; property: "angle"; from: 0; to: root.active ? 180 : -180; duration: 400; easing.type: Easing.OutCubic }
        }

        // 5. Morph the symbol icon mid-spin
        ScriptAction {
            script: {
                animIcon.text = root.active ? "nightlight" : "sunny";
                animIcon.color = root.active ? "#ffca28" : "#00b0ff";
            }
        }

        // 6. Complete the spin, settle down, and pulse ring
        ParallelAnimation {
            NumberAnimation { target: iconScale; property: "xScale"; to: 1.0; duration: 300 }
            NumberAnimation { target: iconScale; property: "yScale"; to: 1.0; duration: 300 }
            NumberAnimation { target: iconRotation; property: "angle"; to: root.active ? 360 : -360; duration: 350; easing.type: Easing.OutQuad }
            
            // Expand warmth ring
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: warmthRing; property: "scale"; from: 0.5; to: 2.2; duration: 450; easing.type: Easing.OutQuad }
                    NumberAnimation { target: warmthRing; property: "opacity"; from: 0.8; to: 0.0; duration: 450 }
                }
            }
        }

        PauseAnimation { duration: 350 }

        // 7. Scale down and fade out actor
        ParallelAnimation {
            NumberAnimation { target: animIcon; property: "opacity"; to: 0.0; duration: 180 }
            NumberAnimation { target: iconScale; property: "xScale"; to: 0.7; duration: 180 }
            NumberAnimation { target: iconScale; property: "yScale"; to: 0.7; duration: 180 }
        }

        // 8. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
