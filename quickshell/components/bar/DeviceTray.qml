import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../widgets"
import "../../core"

Rectangle {
    id: root

    implicitHeight: 22
    height: 22
    radius: 11
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
    clip: true

    // Hide the tray item completely if no external devices are connected
    visible: UsbMonitorService.devicesList.length > 0

    implicitWidth: visible ? layout.implicitWidth + 14 : 0
    width: implicitWidth

    Behavior on width {
        NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
    }

    Row {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: {
                // Show sd_card if only SD cards are connected, otherwise default to usb icon
                let hasUsb = false;
                let hasSd = false;
                for (let i = 0; i < UsbMonitorService.devicesList.length; i++) {
                    let type = UsbMonitorService.devicesList[i].deviceType.toLowerCase();
                    if (type.includes("sd") || type.includes("card")) hasSd = true;
                    if (type.includes("usb")) hasUsb = true;
                }
                if (hasSd && !hasUsb) return "sd_card";
                return "usb";
            }
            iconSize: 12
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: UsbMonitorService.devicesList.length.toString()
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Bold
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    property bool menuActive: false

    HyprlandFocusGrab {
        id: focusGrab
        active: root.menuActive
        windows: [menuLoader.item]
        onCleared: {
            root.menuActive = false;
        }
    }

    Loader {
        id: menuLoader
        active: root.menuActive
        sourceComponent: DeviceTrayMenu {
            anchor {
                window: root.QsWindow.window
                rect: {
                    var pos = root.mapToItem(null, 0, 0); 
                    return Qt.rect(pos.x, pos.y + root.height + (4 * Appearance.effectiveScale), root.width, root.height);
                }
                edges: Edges.Top | Edges.Center
                gravity: Edges.Bottom
            }

            onMenuClosed: {
                root.menuActive = false;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.menuActive = !root.menuActive;
            } else {
                // Left click shows the latest device info in OSD overlay
                if (UsbMonitorService.lastDevice) {
                    UsbMonitorService.deviceEvent(UsbMonitorService.lastDevice);
                }
            }
        }
    }
}
