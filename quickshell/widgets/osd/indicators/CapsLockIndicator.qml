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

    readonly property bool active: OsdService.capsLockState

    property bool isReady: false

    Component.onCompleted: {
        // Trigger initial animation when OSD loads
        morphAnim.restart();
        isReady = true;
    }

    onActiveChanged: {
        if (isReady) {
            morphAnim.restart();
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
                    text: root.active ? "keyboard_capslock" : "keyboard"
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
                    text: "Caps Lock • " + (root.active ? "On" : "Off")
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                // ── Morphing Text Actor ("a" <=> "A") ──
                Text {
                    id: morphText
                    anchors.centerIn: parent
                    text: root.active ? "a" : "A"
                    font.family: "Inter"
                    font.pixelSize: 18 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: Theme.primary
                    opacity: 0

                    transform: [
                        Rotation {
                            id: morphRotation
                            origin.x: morphText.width / 2
                            origin.y: morphText.height / 2
                            angle: 0
                        },
                        Scale {
                            id: morphScale
                            origin.x: morphText.width / 2
                            origin.y: morphText.height / 2
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
                    text: "CAP"
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

    // ── Morphing Animation Sequence ──
    SequentialAnimation {
        id: morphAnim

        // 1. Wait for OSD window slide/fade
        PauseAnimation { duration: 300 }

        // 2. Fade status label out
        NumberAnimation { target: statusLabel; property: "opacity"; to: 0.0; duration: 120 }

        // 3. Prepare initial state of morph actor
        ScriptAction {
            script: {
                morphText.text = root.active ? "a" : "A";
            }
        }
        ParallelAnimation {
            PropertyAction { target: morphRotation; property: "angle"; value: 0 }
            PropertyAction { target: morphScale; property: "xScale"; value: 0.6 }
            PropertyAction { target: morphScale; property: "yScale"; value: 0.6 }
            PropertyAction { target: morphText; property: "opacity"; value: 0.0 }
        }

        // 4. Perform spin, scale, and text morph
        ParallelAnimation {
            NumberAnimation { target: morphText; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
            NumberAnimation { target: morphScale; property: "xScale"; from: 0.6; to: 1.4; duration: 400; easing.type: Easing.OutBack }
            NumberAnimation { target: morphScale; property: "yScale"; from: 0.6; to: 1.4; duration: 400; easing.type: Easing.OutBack }
            NumberAnimation { target: morphRotation; property: "angle"; from: 0; to: root.active ? 180 : -180; duration: 450; easing.type: Easing.OutCubic }
        }

        // 5. Morph the text letter in mid-air
        ScriptAction {
            script: {
                morphText.text = root.active ? "A" : "a";
                morphText.color = root.active ? Theme.primary : "#ffffff";
            }
        }

        // 6. Complete the spin and scale down
        ParallelAnimation {
            NumberAnimation { target: morphScale; property: "xScale"; to: 1.0; duration: 350; easing.type: Easing.OutSine }
            NumberAnimation { target: morphScale; property: "yScale"; to: 1.0; duration: 350; easing.type: Easing.OutSine }
            NumberAnimation { target: morphRotation; property: "angle"; to: root.active ? 360 : -360; duration: 400; easing.type: Easing.OutQuad }
        }
        
        PauseAnimation { duration: 200 }

        // 7. Fade out morph actor
        NumberAnimation { target: morphText; property: "opacity"; to: 0.0; duration: 150 }

        // 8. Fade status label back in
        NumberAnimation { target: statusLabel; property: "opacity"; to: 1.0; duration: 200 }
    }
}
