import QtQuick
import "../core"
import "../theme"
import "../components"

MaterialShape {
    id: root
    property alias text: symbol.name
    property alias iconSize: symbol.size
    property alias colSymbol: symbol.color
    property alias fill: symbol.fill
    property string shapeString: "circle"
    property real padding: 6 * Appearance.effectiveScale

    color: Appearance.m3colors.m3secondaryContainer
    colSymbol: Appearance.m3colors.m3onSecondaryContainer
    shape: shapeString
    implicitWidth: Math.max(symbol.implicitWidth, symbol.implicitHeight) + padding * 2
    implicitHeight: implicitWidth

    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    Behavior on scale {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
    }

    DankIcon {
        id: symbol
        anchors.centerIn: parent
        color: root.colSymbol
        rotation: 360 - root.rotation
    }
}
