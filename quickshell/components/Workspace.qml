import Quickshell
import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property int workspaceId: 1
    property bool isActive: false
    property bool isOccupied: false
    property var windows: []

    signal clicked()

    implicitWidth: 20
    implicitHeight: 20

    // Detailed background capsule for each workspace button
    Rectangle {
        id: pillBg
        anchors.fill: parent
        radius: width / 2
        
        color: {
            if (root.isActive) return "transparent";
            if (root.isOccupied) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12);
            return mouseArea.containsMouse ? Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.08) : Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.04);
        }
        
        border.width: 1
        border.color: {
            if (root.isActive) return "transparent";
            if (mouseArea.containsMouse) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3);
            if (root.isOccupied) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2);
            return Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.06);
        }

        scale: mouseArea.containsMouse ? 1.08 : 1.0

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // Text component showing the workspace number
    Text {
        anchors.centerIn: parent
        text: root.workspaceId.toString()
        font.family: Theme.font.family
        font.pixelSize: 10
        font.weight: root.isActive ? Font.Bold : Font.Normal
        
        color: {
            if (root.isActive) return Theme.onPrimaryColor;
            if (root.isOccupied) return Theme.primary;
            return Theme.onSurfaceColor;
        }
        
        opacity: {
            if (root.isActive) return 1.0;
            if (root.isOccupied) return 0.9;
            return 0.45;
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
