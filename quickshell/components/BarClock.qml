import QtQuick
import QtQuick.Layouts
import "../theme"
import "../core"

RowLayout {
    id: root
    spacing: 6 * Appearance.effectiveScale

    property var date: new Date()

    Text {
        text: date.toLocaleTimeString(Qt.locale(), "hh:mm AP")
        font.family: Theme.font.family
        font.pixelSize: 12 * Appearance.effectiveScale
        font.weight: Font.Bold
        color: Theme.onSurfaceColor
    }

    Text {
        text: "•"
        font.family: Theme.font.family
        font.pixelSize: 10 * Appearance.effectiveScale
        color: Theme.outlineVariant
    }

    Text {
        text: date.toLocaleDateString(Qt.locale(), "ddd d")
        font.family: Theme.font.family
        font.pixelSize: 11 * Appearance.effectiveScale
        font.weight: Font.Medium
        color: Theme.primary
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.date = new Date()
    }
}
