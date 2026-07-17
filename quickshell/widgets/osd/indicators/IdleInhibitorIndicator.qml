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

    readonly property bool active: OsdService.idleInhibited

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
                    text: root.active ? "coffee" : "bedtime"
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
                    text: "Caffeine Mode • " + (root.active ? "On" : "Off")
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Animated Caffeine / Sleep Container ──
                Item {
                    id: visualContainer
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    opacity: 0

                    MaterialSymbol {
                        id: animIcon
                        anchors.centerIn: parent
                        text: root.active ? "coffee" : "bedtime"
                        iconSize: 18 * Appearance.effectiveScale
                        color: root.active ? "#ffca28" : "#90caf9" // Gold coffee or soft blue moon

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

                    // Rising Steam Lines (Active/Caffeine ON)
                    Repeater {
                        model: 3
                        Rectangle {
                            id: steamLine
                            width: 1.2 * Appearance.effectiveScale
                            height: 5 * Appearance.effectiveScale
                            radius: width / 2
                            color: "#ffca28"
                            opacity: 0
                            x: (visualContainer.width / 2) - 5 + index * 4.5
                            y: (visualContainer.height / 2) - 2

                            SequentialAnimation {
                                loops: Animation.Infinite
                                running: visualContainer.opacity > 0.1 && root.active

                                PauseAnimation { duration: index * 180 }
                                ParallelAnimation {
                                    NumberAnimation { target: steamLine; property: "y"; from: (visualContainer.height / 2) - 2; to: (visualContainer.height / 2) - 13; duration: 550; easing.type: Easing.OutSine }
                                    NumberAnimation { target: steamLine; property: "opacity"; from: 0; to: 0.8; duration: 150 }
                                    NumberAnimation { target: steamLine; property: "x"; from: (visualContainer.width / 2) - 5 + index * 4.5; to: (visualContainer.width / 2) - 5 + index * 4.5 + (index === 1 ? -2 : 2); duration: 550 }
                                }
                                NumberAnimation { target: steamLine; property: "opacity"; to: 0; duration: 120 }
                            }
                        }
                    }

                    // Floating Sleep Z's (Inactive/Caffeine OFF)
                    Repeater {
                        model: 2
                        Text {
                            id: zText
                            text: "z"
                            font.family: "Inter"
                            font.pixelSize: (index === 0 ? 8 : 11) * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#90caf9"
                            opacity: 0
                            x: (visualContainer.width / 2) + 4 + index * 3
                            y: (visualContainer.height / 2)

                            SequentialAnimation {
                                loops: Animation.Infinite
                                running: visualContainer.opacity > 0.1 && !root.active

                                PauseAnimation { duration: index * 350 }
                                ParallelAnimation {
                                    NumberAnimation { target: zText; property: "y"; from: (visualContainer.height / 2); to: (visualContainer.height / 2) - 12; duration: 750; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: zText; property: "opacity"; from: 0; to: 0.9; duration: 180 }
                                    ScaleAnimator { target: zText; from: 0.6; to: 1.1; duration: 750 }
                                }
                                NumberAnimation { target: zText; property: "opacity"; to: 0; duration: 180 }
                            }
                        }
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
                    text: "CAF"
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
            PropertyAction { target: visualContainer; property: "opacity"; value: 1.0 }
            PropertyAction { target: iconScale; property: "xScale"; value: 0.5 }
            PropertyAction { target: iconScale; property: "yScale"; value: 0.5 }
            PropertyAction { target: iconRotation; property: "angle"; value: root.active ? -25 : 25 }
        }

        // 4. Scale and tilt cup / moon
        ParallelAnimation {
            NumberAnimation { target: iconScale; property: "xScale"; to: 1.25; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: iconScale; property: "yScale"; to: 1.25; duration: 300; easing.type: Easing.OutBack }
            NumberAnimation { target: iconRotation; property: "angle"; to: 0; duration: 350; easing.type: Easing.OutBack }
        }

        // 5. Let steam/Z's cycle in center
        PauseAnimation { duration: 1200 }

        // 6. Scale down and fade out
        ParallelAnimation {
            NumberAnimation { target: visualContainer; property: "opacity"; to: 0.0; duration: 180 }
            NumberAnimation { target: iconScale; property: "xScale"; to: 0.7; duration: 180 }
            NumberAnimation { target: iconScale; property: "yScale"; to: 0.7; duration: 180 }
        }

        // 7. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
