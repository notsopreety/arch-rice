import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import "../../../core"
import "../../../theme"
import "../../../services"
import "../../"

Item {
    id: root

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); root.glassmorphism = true; } catch(e) { root.glassmorphism = false; } }
        onLoaded: root.glassmorphism = true
        onLoadFailed: root.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    // Required by OSD loader interface
    readonly property bool isSliderPressed: false

    implicitWidth: 340 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale

    readonly property bool active: OsdService.dndActive

    property bool isReady: false

    Component.onCompleted: {
        // Trigger initial animation when OSD loads
        dndAnim.restart();
        isReady = true;
    }

    onActiveChanged: {
        if (isReady) {
            dndAnim.restart();
        }
    }

    // Main Glassmorphic Container
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: height / 2
        color: root.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
        border.color: root.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        // Glossy glare reflection
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.45
            radius: parent.radius
            visible: root.glassmorphism
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
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
                    text: root.active ? "notifications_off" : "notifications_active"
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
                    text: "Do Not Disturb • " + (root.active ? "On" : "Off")
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Animated Bell & Slash Overlay Container ──
                Item {
                    id: bellContainer
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    opacity: 0

                    MaterialSymbol {
                        id: animBell
                        anchors.centerIn: parent
                        text: "notifications"
                        iconSize: 18 * Appearance.effectiveScale
                        color: root.active ? Theme.error : "#ffffff"

                        transform: [
                            Rotation {
                                id: bellRotation
                                origin.x: animBell.width / 2
                                origin.y: 0 // Swing from the top hook of the bell
                                angle: 0
                            },
                            Scale {
                                id: bellScale
                                origin.x: animBell.width / 2
                                origin.y: animBell.height / 2
                                xScale: 1.0
                                yScale: 1.0
                            }
                        ]
                    }

                    // The slashing line that cuts the bell when active is true
                    Rectangle {
                        id: slashLine
                        anchors.centerIn: parent
                        height: 2 * Appearance.effectiveScale
                        width: 0 // Animated
                        color: Theme.error
                        rotation: -45
                        radius: 1
                    }
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
                    text: "DND"
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

    // ── DND Anim Sequence ──
    SequentialAnimation {
        id: dndAnim

        // 1. Wait for OSD window slide/fade
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare initial state of the animation container
        ParallelAnimation {
            PropertyAction { target: bellContainer; property: "opacity"; value: 1.0 }
            PropertyAction { target: bellScale; property: "xScale"; value: 0.5 }
            PropertyAction { target: bellScale; property: "yScale"; value: 0.5 }
            PropertyAction { target: bellRotation; property: "angle"; value: 0 }
            PropertyAction { target: slashLine; property: "width"; value: root.active ? 0 : 20 * Appearance.effectiveScale }
        }

        // 4. Scale up the bell
        ParallelAnimation {
            NumberAnimation { target: bellScale; property: "xScale"; to: 1.2; duration: 250; easing.type: Easing.OutBack }
            NumberAnimation { target: bellScale; property: "yScale"; to: 1.2; duration: 250; easing.type: Easing.OutBack }
        }

        // 5. Ring/Swing the bell
        SequentialAnimation {
            NumberAnimation { target: bellRotation; property: "angle"; from: 0; to: -15; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { target: bellRotation; property: "angle"; from: -15; to: 15; duration: 150; easing.type: Easing.InOutQuad }
            NumberAnimation { target: bellRotation; property: "angle"; from: 15; to: -10; duration: 130; easing.type: Easing.InOutQuad }
            NumberAnimation { target: bellRotation; property: "angle"; from: -10; to: 10; duration: 110; easing.type: Easing.InOutQuad }
            NumberAnimation { target: bellRotation; property: "angle"; from: 10; to: 0; duration: 90; easing.type: Easing.InQuad }
        }

        // 6. Draw slash (if ON) or erase slash (if OFF)
        ParallelAnimation {
            NumberAnimation {
                target: slashLine
                property: "width"
                to: root.active ? 20 * Appearance.effectiveScale : 0
                duration: 350
                easing.type: Easing.InOutCubic
            }
            // Settle bell scale to 1.0
            NumberAnimation { target: bellScale; property: "xScale"; to: 1.0; duration: 250 }
            NumberAnimation { target: bellScale; property: "yScale"; to: 1.0; duration: 250 }
        }

        PauseAnimation { duration: 350 }

        // 7. Fade out anim container
        ParallelAnimation {
            NumberAnimation { target: bellContainer; property: "opacity"; to: 0.0; duration: 180 }
            NumberAnimation { target: bellScale; property: "xScale"; to: 0.7; duration: 180 }
            NumberAnimation { target: bellScale; property: "yScale"; to: 0.7; duration: 180 }
        }

        // 8. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
