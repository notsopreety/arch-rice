import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../services"
import "../../widgets"
import "../../core"

PopupWindow {
    id: root

    signal menuClosed()

    color: "transparent"

    // Calculate dimensions dynamically based on children (devicesList)
    implicitWidth: 200 * Appearance.effectiveScale
    implicitHeight: menuLayout.implicitHeight + (8 * Appearance.effectiveScale)

    onVisibleChanged: {
        if (!visible) menuClosed();
    }

    Component.onDestruction: menuClosed()

    Rectangle {
        id: popupBackground
        anchors.fill: parent
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: 1
        radius: Appearance.rounding.small
        clip: true

        opacity: 0
        scale: 0.9

        ParallelAnimation {
            id: enterAnim
            running: true
            NumberAnimation { target: popupBackground; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: popupBackground; property: "scale"; from: 0.9; to: 1; duration: 150; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            id: menuLayout
            anchors {
                fill: parent
                margins: 4 * Appearance.effectiveScale
            }
            spacing: 0

            // Title
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28 * Appearance.effectiveScale
                color: "transparent"

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8 * Appearance.effectiveScale
                    text: "CONNECTED DEVICES"
                    font.family: "Inter"
                    font.pixelSize: 9 * Appearance.effectiveScale
                    font.weight: Font.Black
                    color: Theme.primary
                    font.letterSpacing: 1.0
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.2)
            }

            // Spacing
            Item {
                Layout.preferredHeight: 4 * Appearance.effectiveScale
            }

            // Devices list repeater
            Repeater {
                model: UsbMonitorService.devicesList

                delegate: Rectangle {
                    id: entryRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32 * Appearance.effectiveScale
                    radius: 6 * Appearance.effectiveScale
                    color: hoverHandler.hovered ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                    HoverHandler {
                        id: hoverHandler
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8 * Appearance.effectiveScale
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "eject"
                            iconSize: 12 * Appearance.effectiveScale
                            color: hoverHandler.hovered ? Theme.primary : "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.displayName + (modelData.sizeHuman ? " (" + modelData.sizeHuman + ")" : "")
                            font.family: "Inter"
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: hoverHandler.hovered ? Theme.primary : "#ffffff"
                            elide: Text.ElideRight
                            width: 160 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            UsbMonitorService.ejectDevice(modelData.device);
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: visible = true
}
