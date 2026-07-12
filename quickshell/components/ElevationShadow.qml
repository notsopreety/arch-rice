import QtQuick
import QtQuick.Effects
import "../theme"

Item {
    id: root

    property color targetColor: "white"
    property real targetRadius: Theme.rounding.normal
    property color borderColor: "transparent"
    property real borderWidth: 0
    property bool shadowEnabled: true

    layer.enabled: shadowEnabled
    layer.effect: MultiEffect {
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowBlur: 0.4
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 4
        shadowColor: Qt.rgba(0, 0, 0, 0.4)
    }

    Rectangle {
        id: sourceRect
        anchors.fill: parent
        radius: root.targetRadius
        color: root.targetColor
        border.color: root.borderColor
        border.width: root.borderWidth
    }
}
