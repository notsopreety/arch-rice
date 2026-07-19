import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import "../theme"
import "../components"
import "../core"

Rectangle {
    id: root

    property bool isActive: false
    property string title: ""
    property string statusText: ""
    property string iconName: ""
    property string iconOffName: ""
    property string tooltipText: ""

    signal clicked()

    // Hover Scaling Animation
    HoverHandler { id: hoverHandler }
    scale: hoverHandler.hovered ? 1.02 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // Dynamic morphing radius (Pill to Curvy Border Rectangle)
    radius: isActive ? 16 * Appearance.effectiveScale : height / 2
    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Layout.fillWidth: true
    Layout.preferredHeight: 64 * Appearance.effectiveScale

    // Theme responsive background & borders
    color: {
        if (isActive) {
            return hoverHandler.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary;
        } else {
            return hoverHandler.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05);
        }
    }
    border.color: isActive ? "transparent" : (hoverHandler.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15))
    border.width: 1 * Appearance.effectiveScale

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    QQC.ToolTip {
        visible: hoverHandler.hovered && tooltipText !== ""
        delay: 200
        y: -height - 4 * Appearance.effectiveScale
        contentItem: Text {
            text: root.tooltipText
            font.family: Theme.font.family
            font.pixelSize: 11 * Appearance.effectiveScale
            font.weight: Font.Medium
            color: Theme.primary
        }
        background: Rectangle {
            color: Theme.surfaceContainer
            border.color: Theme.outline
            border.width: 1 * Appearance.effectiveScale
            radius: 8 * Appearance.effectiveScale
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16 * Appearance.effectiveScale
        anchors.rightMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()

            RowLayout {
                anchors.fill: parent
                spacing: 12 * Appearance.effectiveScale

                DankIcon {
                    name: root.isActive ? root.iconName : (root.iconOffName || root.iconName)
                    size: 24 * Appearance.effectiveScale
                    filled: root.isActive
                    color: root.isActive ? "#000000" : "white"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: root.title
                        font.family: Theme.font.family
                        font.pixelSize: 14 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: root.isActive ? "#000000" : "white"
                    }

                    Text {
                        text: root.statusText
                        font.family: Theme.font.family
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: root.isActive ? Qt.rgba(0,0,0,0.6) : Qt.rgba(1,1,1,0.6)
                    }
                }
            }
        }
    }
}
