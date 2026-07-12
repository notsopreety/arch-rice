import QtQuick 6.10
import Quickshell
import Quickshell.Bluetooth
import "../../theme"
import "../../services"
import "../../components"

// Bluetooth pill — expand completes fully, then text fades in cleanly
Item {
    id: root

    property var barWindow
    property var bar

    readonly property var matugen: Theme
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property bool hasConnection: connectedDevices.length > 0
    readonly property bool isEnabled: adapter?.enabled ?? false
    readonly property string deviceName: {
        if (!hasConnection) return ""
        const d = connectedDevices[0]
        const name = d?.name ?? "Device"
        return connectedDevices.length > 1 ? name + " +" + (connectedDevices.length - 1) : name
    }

    // Gap baked into labelBox so implicitWidth = icon + labelBox with no jumps
    readonly property int expandedLabelWidth: 62  // includes left gap

    // textReady: flips true only after the expand animation fully completes
    property bool textReady: false

    onIsHoveredChanged: {
        if (!isHovered) {
            textReady = false
            showTimer.stop()
        }
    }

    Timer {
        id: showTimer
        interval: 280   // expand duration (260ms) + 20ms buffer
        running: isHovered
        onTriggered: root.textReady = true
    }

    // implicitWidth tracks labelBox.width live — no Behavior needed here
    implicitWidth: iconText.implicitWidth + labelBox.width
    implicitHeight: 20

    // ── Icon ─────────────────────────────────────────────────────────────────
    DankIcon {
        id: iconText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        name: {
            if (!isEnabled)    return "bluetooth_disabled"
            if (hasConnection) return "bluetooth_connected"
            return "bluetooth"
        }
        size: 14

        color: {
            if (!isEnabled)    return isHovered ? Theme.error    : Qt.rgba(1, 1, 1, 0.35)
            if (!hasConnection) return isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.5)
            return isHovered   ? matugen.primary : Qt.rgba(1, 1, 1, 0.85)
        }
        Behavior on color { ColorAnimation { duration: 150 } }

        scale: isHovered ? 1.08 : 1.0
        Behavior on scale { NumberAnimation { duration: 150 } }
    }

    // ── Clipped label box — single width animation drives the whole expand ──
    Item {
        id: labelBox
        anchors.left: iconText.right
        anchors.verticalCenter: parent.verticalCenter
        height: 16
        clip: true

        // Collapse immediately on hover-out for a snappy feel
        width: isHovered ? expandedLabelWidth : 0
        Behavior on width {
            NumberAnimation { duration: 260; easing.type: Easing.InOutCubic }
        }

        // ── Off / no device: static text ─────────────────────────────────────
        Text {
            id: staticLabel
            visible: !hasConnection
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Normal
            text: !isEnabled ? "Off" : "No Device"

            opacity: root.textReady ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            color: {
                if (!isEnabled) return isHovered ? Theme.error   : Qt.rgba(1, 1, 1, 0.4)
                return isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.65)
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // ── Connected: marquee scrolling right → left ─────────────────────
        Text {
            id: marqueeLabel
            visible: hasConnection
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            text: deviceName

            opacity: root.textReady ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            color: isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.8)
            Behavior on color { ColorAnimation { duration: 150 } }

            // Start marquee only once textReady and box is fully open
            SequentialAnimation on x {
                running: hasConnection && root.textReady
                loops: Animation.Infinite

                PropertyAction { value: labelBox.width }
                NumberAnimation {
                    to: -marqueeLabel.contentWidth
                    duration: Math.max(1500, (marqueeLabel.contentWidth + labelBox.width) * 25)
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 700 }
            }
        }
    }

    // ── Mouse ──────────────────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            BluetoothCenterService.toggle()
        }
    }
}
