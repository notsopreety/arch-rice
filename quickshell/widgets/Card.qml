import QtQuick
import "../theme"

Rectangle {
    id: card

    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    property int pad: 12

    radius: Theme.rounding.normal
    color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
    border.color: Theme.outlineVariant
    border.width: 1

    default property alias content: contentItem.data

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: card.pad
    }
}
