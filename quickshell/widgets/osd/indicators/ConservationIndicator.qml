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

    readonly property bool active: ConservationMode.active

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
                    text: root.active ? "battery_saver" : "battery_std"
                    iconSize: 18 * Appearance.effectiveScale

                    color: root.active ? Theme.primaryContainer : Qt.rgba(255, 255, 255, 0.1)
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
                    text: (root.active ? "Battery Protected" : "Charge to 100%") + " • " + Math.round(Battery.percentage * 100) + "%"
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Expanding Force Field Ring ──
                Rectangle {
                    id: forceField
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    radius: width / 2
                    color: "transparent"
                    border.color: "#2ecc71"
                    border.width: 2 * Appearance.effectiveScale
                    opacity: 0
                    scale: 0.5
                }

                // ── Shield Protection Icon ──
                MaterialSymbol {
                    id: shieldIcon
                    anchors.centerIn: parent
                    text: "shield"
                    iconSize: 20 * Appearance.effectiveScale
                    color: root.active ? "#2ecc71" : "#ffffff"
                    opacity: 0
                    scale: 0.6
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
                    text: "CON"
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

    // ── Animation Sequence ──
    SequentialAnimation {
        id: anim

        // 1. Wait for OSD window slide/fade
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare actor
        ParallelAnimation {
            PropertyAction { target: shieldIcon; property: "opacity"; value: 1.0 }
            PropertyAction { target: shieldIcon; property: "scale"; value: 0.6 }
            PropertyAction { target: forceField; property: "opacity"; value: 0.0 }
            PropertyAction { target: forceField; property: "scale"; value: 0.5 }
        }

        // 4. Scale up the shield
        NumberAnimation { target: shieldIcon; property: "scale"; to: 1.25; duration: 250; easing.type: Easing.OutBack }

        // 5. If ON: Trigger expanding force field rings, If OFF: Quick spin away
        ScriptAction {
            script: {
                if (root.active) {
                    forceFieldAnim.start();
                } else {
                    spinAwayAnim.start();
                }
            }
        }

        // Wait for the force field / spin animation to finish
        PauseAnimation { duration: 600 }

        // 6. Fade out shield
        NumberAnimation { target: shieldIcon; property: "opacity"; to: 0.0; duration: 150 }

        // 7. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }

    // ON force field sequence
    SequentialAnimation {
        id: forceFieldAnim
        ParallelAnimation {
            NumberAnimation { target: forceField; property: "scale"; from: 0.5; to: 2.2; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: forceField; property: "opacity"; from: 0.7; to: 0.0; duration: 450 }
        }
        ParallelAnimation {
            NumberAnimation { target: forceField; property: "scale"; from: 0.5; to: 2.2; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: forceField; property: "opacity"; from: 0.7; to: 0.0; duration: 450 }
        }
    }

    // OFF spin away sequence
    ParallelAnimation {
        id: spinAwayAnim
        NumberAnimation { target: shieldIcon; property: "scale"; to: 0.2; duration: 400; easing.type: Easing.InBack }
        RotationAnimation { target: shieldIcon; property: "rotation"; from: 0; to: -180; duration: 400; easing.type: Easing.InOutQuad }
    }
}
