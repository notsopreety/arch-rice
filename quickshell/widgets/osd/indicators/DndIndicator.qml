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
                    text: root.active ? "do_not_disturb_on" : "do_not_disturb_off"
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
                    font.family: Theme.font.family
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: root.active ? Theme.primary : "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Animated DND Shield & Pulse Aura Container ──
                Item {
                    id: dndContainer
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    opacity: 0

                    // Expanding Shield Aura Ring
                    Rectangle {
                        id: pulseRing
                        anchors.centerIn: parent
                        width: 22 * Appearance.effectiveScale
                        height: 22 * Appearance.effectiveScale
                        radius: width / 2
                        color: "transparent"
                        border.color: root.active ? Theme.primary : Theme.error
                        border.width: 2 * Appearance.effectiveScale
                        opacity: 0

                        transform: Scale {
                            id: ringScale
                            origin.x: pulseRing.width / 2
                            origin.y: pulseRing.height / 2
                            xScale: 1.0
                            yScale: 1.0
                        }
                    }

                    // Central DND Icon Symbol with Elastic Overshoot & Rotation
                    MaterialSymbol {
                        id: animDndSymbol
                        anchors.centerIn: parent
                        text: root.active ? "do_not_disturb_on" : "do_not_disturb_off"
                        iconSize: 22 * Appearance.effectiveScale
                        color: root.active ? Theme.primary : Theme.error

                        transform: [
                            Rotation {
                                id: symbolRotation
                                origin.x: animDndSymbol.width / 2
                                origin.y: animDndSymbol.height / 2
                                angle: 0
                            },
                            Scale {
                                id: dndScale
                                origin.x: animDndSymbol.width / 2
                                origin.y: animDndSymbol.height / 2
                                xScale: 1.0
                                yScale: 1.0
                            }
                        ]
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

    // ── DND Animation Sequence (Shield Spin & Expanding Pulse Aura) ──
    SequentialAnimation {
        id: dndAnim

        // 1. Wait for OSD window slide/fade
        PauseAnimation { duration: 280 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare initial states
        ParallelAnimation {
            PropertyAction { target: dndContainer; property: "opacity"; value: 1.0 }
            PropertyAction { target: dndScale; property: "xScale"; value: 0.3 }
            PropertyAction { target: dndScale; property: "yScale"; value: 0.3 }
            PropertyAction { target: symbolRotation; property: "angle"; value: root.active ? -90 : 90 }
            PropertyAction { target: ringScale; property: "xScale"; value: 0.5 }
            PropertyAction { target: ringScale; property: "yScale"; value: 0.5 }
            PropertyAction { target: pulseRing; property: "opacity"; value: 1.0 }
        }

        // 4. Elastic scale up & spin symbol
        ParallelAnimation {
            NumberAnimation { target: dndScale; property: "xScale"; to: 1.35; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: dndScale; property: "yScale"; to: 1.35; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: symbolRotation; property: "angle"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }

        // 5. Expand shield pulse aura ring outwards
        ParallelAnimation {
            NumberAnimation { target: ringScale; property: "xScale"; to: 2.2; duration: 400; easing.type: Easing.OutQuad }
            NumberAnimation { target: ringScale; property: "yScale"; to: 2.2; duration: 400; easing.type: Easing.OutQuad }
            NumberAnimation { target: pulseRing; property: "opacity"; to: 0.0; duration: 400; easing.type: Easing.OutQuad }
            // Settle symbol scale to 1.0
            NumberAnimation { target: dndScale; property: "xScale"; to: 1.0; duration: 250 }
            NumberAnimation { target: dndScale; property: "yScale"; to: 1.0; duration: 250 }
        }

        PauseAnimation { duration: 300 }

        // 6. Fade out anim container
        ParallelAnimation {
            NumberAnimation { target: dndContainer; property: "opacity"; to: 0.0; duration: 180 }
            NumberAnimation { target: dndScale; property: "xScale"; to: 0.7; duration: 180 }
            NumberAnimation { target: dndScale; property: "yScale"; to: 0.7; duration: 180 }
        }

        // 7. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
