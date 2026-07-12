import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../theme"

PanelWindow {
    id: workspaceWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-workspace"
    
    WlrLayershell.keyboardFocus: WorkspaceService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: WorkspaceService.visible

    onVisibleChanged: {
        if (visible) {
            overviewLayer.forceActiveFocus();
        }
    }

    // Process helper to update window positions/states
    HyprlandData {
        id: hyprlandData
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: WorkspaceService.close()
    }

    WorkspaceOverviewLayer {
        id: overviewLayer
        anchors.top: parent.top
        anchors.topMargin: Styling.barHeight + 8
        anchors.horizontalCenter: parent.horizontalCenter
        screen: workspaceWindow.screen
        hyprlandData: hyprlandData
        showCondition: workspaceWindow.visible
        focus: true

        onCloseRequested: {
            WorkspaceService.close();
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                WorkspaceService.close();
                event.accepted = true;
            }
        }
    }
}
