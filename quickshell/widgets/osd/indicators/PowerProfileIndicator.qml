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

    readonly property string profile: OsdService.powerProfile

    property bool isReady: false

    Component.onCompleted: {
        anim.restart();
        isReady = true;
    }

    onProfileChanged: {
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
                    text: root.profile === "performance" ? "speed" : (root.profile === "power-saver" ? "eco" : "balance")
                    iconSize: 18 * Appearance.effectiveScale

                    color: root.profile === "performance" ? Qt.rgba(255/255, 71/255, 87/255, 0.25) : 
                           (root.profile === "power-saver" ? Qt.rgba(46/255, 204/255, 113/255, 0.25) : Theme.primaryContainer)
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
                    text: "Power Mode • " + (root.profile === "performance" ? "Performance" : (root.profile === "power-saver" ? "Power Saver" : "Balanced"))
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Performance Burst Aura ──
                Rectangle {
                    id: speedRing
                    anchors.centerIn: parent
                    width: 24 * Appearance.effectiveScale
                    height: 24 * Appearance.effectiveScale
                    radius: width / 2
                    color: "transparent"
                    border.color: "#ff4757"
                    border.width: 1.5 * Appearance.effectiveScale
                    opacity: 0
                    scale: 0.5
                }

                // ── Power Saver Swaying Leaf ──
                MaterialSymbol {
                    id: leafDrift
                    text: "spa"
                    iconSize: 10 * Appearance.effectiveScale
                    color: "#2ed573"
                    opacity: 0
                    x: (textWrapper.width / 2) + 6
                    y: (textWrapper.height / 2) - 8
                }

                // ── Animated Profile Actor ──
                MaterialSymbol {
                    id: animIcon
                    anchors.centerIn: parent
                    text: root.profile === "performance" ? "speed" : (root.profile === "power-saver" ? "eco" : "balance")
                    iconSize: 18 * Appearance.effectiveScale
                    color: root.profile === "performance" ? "#ff4757" : 
                           (root.profile === "power-saver" ? "#2ed573" : "#54a0ff")
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
                color: root.profile === "performance" ? Qt.rgba(255/255, 71/255, 87/255, 0.25) : 
                       (root.profile === "power-saver" ? Qt.rgba(46/255, 204/255, 113/255, 0.25) : Theme.secondaryContainer)
                border.color: root.profile === "performance" ? Qt.rgba(255/255, 71/255, 87/255, 0.4) : 
                              (root.profile === "power-saver" ? Qt.rgba(46/255, 204/255, 113/255, 0.4) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1))
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "PWR"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: root.profile === "performance" ? "#ff4757" : 
                           (root.profile === "power-saver" ? "#2ed573" : "#ffffff")
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
            PropertyAction { target: animIcon; property: "opacity"; value: 1.0 }
            PropertyAction { target: iconScale; property: "xScale"; value: 0.5 }
            PropertyAction { target: iconScale; property: "yScale"; value: 0.5 }
            PropertyAction { target: iconRotation; property: "angle"; value: 0 }
            PropertyAction { target: speedRing; property: "opacity"; value: 0.0 }
            PropertyAction { target: speedRing; property: "scale"; value: 0.5 }
            PropertyAction { target: leafDrift; property: "opacity"; value: 0.0 }
        }

        // 4. Scale up with bounce
        ParallelAnimation {
            NumberAnimation { target: iconScale; property: "xScale"; to: 1.3; duration: 250; easing.type: Easing.OutBack }
            NumberAnimation { target: iconScale; property: "yScale"; to: 1.3; duration: 250; easing.type: Easing.OutBack }
        }

        // 5. Trigger mode-specific flourish
        ScriptAction {
            script: {
                if (root.profile === "performance") {
                    performanceFlourish.start();
                } else if (root.profile === "power-saver") {
                    powersaveFlourish.start();
                } else {
                    balancedFlourish.start();
                }
            }
        }

        // Wait for specific flourish to finish
        PauseAnimation { duration: 800 }

        // 6. Scale down and fade out actor
        ParallelAnimation {
            NumberAnimation { target: animIcon; property: "opacity"; to: 0.0; duration: 180 }
            NumberAnimation { target: iconScale; property: "xScale"; to: 0.7; duration: 180 }
            NumberAnimation { target: iconScale; property: "yScale"; to: 0.7; duration: 180 }
        }

        // 7. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }

    // A: Performance Flourish (High speed needle shake + red rings)
    SequentialAnimation {
        id: performanceFlourish
        ParallelAnimation {
            // Speedometer engine shake
            SequentialAnimation {
                NumberAnimation { target: iconRotation; property: "angle"; from: 0; to: -15; duration: 70 }
                NumberAnimation { target: iconRotation; property: "angle"; from: -15; to: 15; duration: 70 }
                NumberAnimation { target: iconRotation; property: "angle"; from: 15; to: -10; duration: 70 }
                NumberAnimation { target: iconRotation; property: "angle"; from: -10; to: 10; duration: 70 }
                NumberAnimation { target: iconRotation; property: "angle"; from: 10; to: 0; duration: 70 }
            }
            // Expanding speed rings
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: speedRing; property: "scale"; from: 0.5; to: 2.2; duration: 400; easing.type: Easing.OutQuad }
                    NumberAnimation { target: speedRing; property: "opacity"; from: 0.8; to: 0.0; duration: 400 }
                }
                ParallelAnimation {
                    NumberAnimation { target: speedRing; property: "scale"; from: 0.5; to: 2.2; duration: 400; easing.type: Easing.OutQuad }
                    NumberAnimation { target: speedRing; property: "opacity"; from: 0.8; to: 0.0; duration: 400 }
                }
            }
        }
    }

    // B: Power Saver Flourish (Swaying leaf + drifting little leaf)
    ParallelAnimation {
        id: powersaveFlourish
        SequentialAnimation {
            NumberAnimation { target: iconRotation; property: "angle"; from: 0; to: -18; duration: 180; easing.type: Easing.OutSine }
            NumberAnimation { target: iconRotation; property: "angle"; from: -18; to: 18; duration: 250; easing.type: Easing.InOutSine }
            NumberAnimation { target: iconRotation; property: "angle"; from: 18; to: 0; duration: 200; easing.type: Easing.InSine }
        }
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: leafDrift; property: "opacity"; from: 0; to: 1.0; duration: 150 }
                NumberAnimation { target: leafDrift; property: "y"; from: (textWrapper.height / 2) - 8; to: (textWrapper.height / 2) + 12; duration: 600; easing.type: Easing.OutSine }
                NumberAnimation { target: leafDrift; property: "x"; from: (textWrapper.width / 2) + 6; to: (textWrapper.width / 2) + 16; duration: 600; easing.type: Easing.OutSine }
            }
            NumberAnimation { target: leafDrift; property: "opacity"; to: 0.0; duration: 150 }
        }
    }

    // C: Balanced Flourish (Scale sway + soft aura fade)
    SequentialAnimation {
        id: balancedFlourish
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: iconRotation; property: "angle"; from: 0; to: -10; duration: 200; easing.type: Easing.InOutQuad }
                NumberAnimation { target: iconRotation; property: "angle"; from: -10; to: 10; duration: 300; easing.type: Easing.InOutQuad }
                NumberAnimation { target: iconRotation; property: "angle"; from: 10; to: 0; duration: 200; easing.type: Easing.InOutQuad }
            }
            SequentialAnimation {
                ScaleAnimator { target: animIcon; from: 1.3; to: 1.45; duration: 350; easing.type: Easing.InOutQuad }
                ScaleAnimator { target: animIcon; from: 1.45; to: 1.3; duration: 350; easing.type: Easing.InOutQuad }
            }
        }
    }
}
