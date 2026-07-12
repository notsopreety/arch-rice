import QtQuick
import Quickshell
import "../../theme"
import "../../components"

Flickable {
    id: root

    required property int length
    property int selectionStart: 0
    property int selectionEnd: 0
    property int cursorPosition: length

    property color shapeColor: Theme.primary
    property color selectedTextColor: Theme.onPrimaryColor
    property color selectionColor: Theme.primaryContainer

    property int charSize: 18

    // shapes pool
    readonly property var charShapes: [
        "arrow",
        "pill",
        "diamond",
        "clamshell",
        "pentagon",
        "cookie_4",
        "soft_burst"
    ]

    // Model management to prevent re-creation of items
    ListModel { id: charModel }

    function updateModel() {
        while (charModel.count > root.length) {
            charModel.remove(charModel.count - 1)
        }
        while (charModel.count < root.length) {
            charModel.append({ "shapeIdx": Math.floor(Math.random() * 7) })
        }
    }
    
    onLengthChanged: updateModel()
    Component.onCompleted: updateModel()

    property int spacing: 4
    property int leftPadding: 12

    contentWidth: dotsRow.implicitWidth + leftPadding * 2
    contentX: Math.max(contentWidth - width, 0)
    
    Behavior on contentX {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property bool active: true

    // Blinking cursor
    Rectangle {
        id: cursor
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: (root.charSize + root.spacing) * root.cursorPosition + root.leftPadding
        }
        color: root.shapeColor
        implicitWidth: 2
        implicitHeight: root.charSize
        opacity: root.active ? 1 : 0

        Behavior on anchors.leftMargin {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Row {
        id: dotsRow
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: root.leftPadding
        }
        spacing: root.spacing

        Repeater {
            model: charModel

            delegate: Rectangle {
                id: charItem
                required property int index
                required property int shapeIdx
                
                implicitWidth: root.charSize
                implicitHeight: root.charSize
                
                property bool selected: index >= root.selectionStart && index < root.selectionEnd
                color: selected ? root.selectionColor : "transparent"

                MaterialShape {
                    id: shape
                    anchors.centerIn: parent
                    shape: root.charShapes[shapeIdx]
                    width: root.charSize
                    height: root.charSize
                    color: root.shapeColor

                    property bool selected: charItem.selected
                    onSelectedChanged: color = selected ? root.selectedTextColor : root.shapeColor

                    Component.onCompleted: {
                        appearAnim.start()
                    }

                    ParallelAnimation {
                        id: appearAnim
                        NumberAnimation {
                            target: shape
                            properties: "opacity"
                            from: 0; to: 1
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: shape
                            properties: "scale"
                            from: 0.5; to: 1.0
                            duration: 250
                            easing.type: Easing.OutBack
                            easing.overshoot: 3.0
                        }
                    }
                }
            }
        }
    }
}
