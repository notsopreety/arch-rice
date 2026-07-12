import QtQuick 6.10
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

// Network pill — expand completes fully, then text fades in cleanly
Item {
    id: root

    property var barWindow
    property var bar

    readonly property var matugen: Theme
    readonly property var network: Network
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isConnected: network.isWired || network.active !== null
    readonly property bool isEnabled: network.isWired || network.wifiEnabled
    readonly property int signalStrength: network.active ? network.active.strength : 0
    readonly property string networkName: network.isWired ? network.wiredConnectionName : (network.active ? network.active.ssid : "")

    // Gap baked into labelBox so implicitWidth = icon + labelBox with no jumps
    readonly property int expandedLabelWidth: 58  // includes left gap

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
            if (network.isWired) return "lan"
            if (!isEnabled || !isConnected) return "wifi_off"
            if (signalStrength >= 75) return "network_wifi"
            if (signalStrength >= 50) return "network_wifi_3_bar"
            if (signalStrength >= 25) return "network_wifi_2_bar"
            return "network_wifi_1_bar"
        }
        size: 14

        color: {
            if (!isEnabled)    return isHovered ? Theme.error    : Qt.rgba(1, 1, 1, 0.35)
            if (!isConnected)  return isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.5)
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

        // ── Off / disconnected: static text ──────────────────────────────────
        Text {
            id: staticLabel
            visible: !isConnected
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Normal
            text: !isEnabled ? "Off" : "No WiFi"

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
            visible: isConnected
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            text: networkName

            opacity: root.textReady ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            color: isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.8)
            Behavior on color { ColorAnimation { duration: 150 } }

            // Start marquee only once textReady and box is fully open
            SequentialAnimation on x {
                running: isConnected && root.textReady
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
            WifiCenterService.toggle()
        }
    }
}
