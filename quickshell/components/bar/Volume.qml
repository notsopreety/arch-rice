import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"

Item {
    id: root

    property var barWindow

    readonly property var matugen: Theme
    readonly property var audio: Audio
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isMuted: audio.muted
    readonly property int percentage: audio.percentage

    implicitWidth: volumeRow.implicitWidth
    implicitHeight: 20 * Appearance.effectiveScale

    RowLayout {
        id: volumeRow
        anchors.centerIn: parent
        spacing: 3 * Appearance.effectiveScale

        DankIcon {
            id: volumeIcon
            name: {
                if (isMuted) return "volume_off"
                if (percentage >= 70) return "volume_up"
                if (percentage >= 30) return "volume_down"
                return "volume_mute"
            }
            size: 14 * Appearance.effectiveScale
            color: isMuted
                ? Qt.rgba(1, 1, 1, 0.3)
                : isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.85)
            scale: isHovered ? 1.08 : 1.0
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120 } }
        }

        Text {
            id: volumeText
            text: percentage
            font.family: "Inter"
            font.pixelSize: 10 * Appearance.effectiveScale
            font.weight: Font.Medium
            color: isMuted
                ? Qt.rgba(1, 1, 1, 0.3)
                : isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.65)
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) audio.increaseVolume()
            else audio.decreaseVolume()
        }
        onClicked: audio.toggleMute()
    }
}
