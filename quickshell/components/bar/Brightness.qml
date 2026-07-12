import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

Item {
    id: root

    property var barWindow

    readonly property var matugen: Theme
    readonly property var brightness: Brightness
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property int percentage: brightness.percentage

    implicitWidth: brightnessRow.implicitWidth
    implicitHeight: 20

    RowLayout {
        id: brightnessRow
        anchors.centerIn: parent
        spacing: 3

        DankIcon {
            id: brightnessIcon
            name: {
                if (percentage >= 70) return "brightness_high"
                if (percentage >= 35) return "brightness_medium"
                return "brightness_low"
            }
            size: 14
            color: isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.85)
            scale: isHovered ? 1.08 : 1.0
            
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 120 } }
        }

        Text {
            id: brightnessText
            text: percentage
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: isHovered ? matugen.primary : Qt.rgba(1, 1, 1, 0.65)
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
            if (wheel.angleDelta.y > 0) brightness.increaseBrightness()
            else brightness.decreaseBrightness()
        }
    }
}
