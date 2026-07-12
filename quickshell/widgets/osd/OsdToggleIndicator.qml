import "../../core"
import "../../widgets"
import "../../core/functions" as Functions
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Refactored OSD Toggle Indicator (Power Mode/Layout/Charging)
 * Simplified structure to eliminate rendering noise.
 */
Item {
    id: root
    
    // Required properties
    property string icon: ""
    property string name: ""
    property string statusText: ""
    property var shape
    property bool continuousRotation: false
    
    // Root dimensions for the Loader/PanelWindow
    implicitWidth: 340 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale

    Rectangle {
        id: valueIndicator
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainer
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: 1

        RowLayout {
            id: valueRow
            anchors.fill: parent
            anchors.leftMargin: 12 * Appearance.effectiveScale
            anchors.rightMargin: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ── Slot Kiri: Icon Wrapper ──
            Item {
                id: iconWrapper
                Layout.preferredWidth: 32 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter

                MaterialShapeWrappedMaterialSymbol {
                    id: iconMain
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    
                    shapeString: {
                        if (typeof root.shape === "string" && root.shape !== "") return root.shape;
                        if (root.name.toLowerCase().includes("power")) return "Sunny";
                        if (root.name.toLowerCase().includes("battery") || root.name.toLowerCase().includes("charging")) return "Gem";
                        if (root.name.toLowerCase().includes("layout")) return "PuffyDiamond";
                        return "Ghostish";
                    }
                    
                    text: root.icon
                    iconSize: 18 * Appearance.effectiveScale
                    
                    color: Theme.primaryContainer
                    colSymbol: "#ffffff"
                }
            }

            // ── Slot Tengah: Main Content (Text Pill) ──
            Rectangle {
                id: textWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 16 * Appearance.effectiveScale
                color: Theme.surfaceVariant
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: root.statusText !== "" ? root.statusText : root.name
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            // ── Slot Kanan: Category Label (Centered Square) ──
            Rectangle {
                id: contextSlot
                Layout.preferredWidth: 44 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 12 * Appearance.effectiveScale
                color: Theme.secondaryContainer
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.name.substring(0, 2).toUpperCase()
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    opacity: 0.8
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    SequentialAnimation {
        id: iconBounceAnim
        NumberAnimation { target: iconWrapper; property: "scale"; from: 1.0; to: 1.25; duration: 150; easing.type: Easing.OutBack }
        NumberAnimation { target: iconWrapper; property: "scale"; from: 1.25; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }

    onIconChanged: iconBounceAnim.restart()

    // Continuous cookie rotation animation
    RotationAnimation {
        id: cookieRotationAnim
        target: iconMain
        property: "rotation"
        from: 0
        to: 360
        duration: 4000
        loops: Animation.Infinite
        running: root.continuousRotation

        onRunningChanged: {
            if (!running) {
                iconMain.rotation = 0;
            }
        }
    }

    // Up-to-down charging slide animation
    SequentialAnimation {
        id: chargingSlideAnim
        running: root.continuousRotation
        loops: Animation.Infinite
        
        ParallelAnimation {
            NumberAnimation { target: iconMain; property: "y"; from: -10; to: 0; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: iconMain; property: "opacity"; from: 0; to: 1; duration: 250 }
        }
        PauseAnimation { duration: 150 }
        ParallelAnimation {
            NumberAnimation { target: iconMain; property: "y"; from: 0; to: 10; duration: 500; easing.type: Easing.InCubic }
            NumberAnimation { target: iconMain; property: "opacity"; from: 1; to: 0; duration: 500 }
        }
        PauseAnimation { duration: 300 }

        onRunningChanged: {
            if (!running) {
                iconMain.y = 0;
                iconMain.opacity = 1;
            }
        }
    }
}
