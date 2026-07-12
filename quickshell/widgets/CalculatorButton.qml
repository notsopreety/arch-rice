import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: button

    // Label text (empty if using icon)
    property string text: ""
    // Material icon name (takes priority over text when set)
    property string iconName: ""
    property int iconSize: 20

    // Styling types
    property string colorType: "normal" // "normal", "operator", "primary", "error", "muted", "active"
    property bool active: false         // e.g. for 2nd / rad toggle highlight

    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitWidth: 44
    implicitHeight: 50
    radius: 14

    // Premium dark keyboard button palette
    readonly property color _colNormal:   "#212124"
    readonly property color _colOp:       Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
    readonly property color _colPrimary:  Theme.primary
    readonly property color _colError:    Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
    readonly property color _colMuted:    "#161619"
    readonly property color _colActive:   Theme.primaryContainer

    // Base color from type
    readonly property color _baseColor: {
        if (colorType === "primary") return _colPrimary
        if (colorType === "error")   return _colError
        if (colorType === "operator") return _colOp
        if (colorType === "muted")   return _colMuted
        if (colorType === "active" || active) return _colActive
        return _colNormal
    }

    color: {
        if (ma.pressed) {
            return colorType === "primary" ? Qt.darker(_baseColor, 1.25) : Qt.lighter(_baseColor, 1.3)
        }
        if (ma.containsMouse) {
            return colorType === "primary" ? Qt.lighter(_baseColor, 1.15) : Qt.lighter(_baseColor, 1.15)
        }
        return _baseColor
    }

    border.color: {
        if (ma.containsMouse) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
        if (active) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
        return Qt.rgba(1, 1, 1, 0.04)
    }
    border.width: 1

    scale: ma.pressed ? 0.94 : 1.0

    Behavior on color {
        ColorAnimation { duration: 120 }
    }
    Behavior on scale {
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: 120 }
    }

    // Icon rendering (Material Symbols)
    DankIcon {
        anchors.centerIn: parent
        name: button.iconName
        size: button.iconSize
        visible: button.iconName !== ""
        color: {
            if (button.colorType === "primary") return Theme.onPrimary
            if (button.colorType === "error")   return Theme.error
            if (button.colorType === "operator") return Theme.primary
            if (button.active) return Theme.primary
            return "white"
        }
    }

    // Text rendering
    Text {
        anchors.centerIn: parent
        text: button.text
        visible: button.iconName === ""
        font.family: Theme.font.family
        font.pixelSize: button.text.length > 3 ? 12 : (button.text.length > 2 ? 14 : 18)
        font.weight: Font.Medium
        color: {
            if (button.colorType === "primary") return Theme.onPrimary
            if (button.colorType === "error")   return Theme.error
            if (button.colorType === "operator") return Theme.primary
            if (button.active) return Theme.primary
            return "white"
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}

