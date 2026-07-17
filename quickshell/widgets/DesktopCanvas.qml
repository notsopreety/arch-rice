import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "desktopWidget"

PanelWindow {
    id: canvasWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    // Main Canvas area hosting floating widgets
    Item {
        anchors.fill: parent

        Clock {
            id: clockWidget
        }

        PhotoFrameWidget {
            id: photoFrameWidget
        }

        ActivateLinuxWatermark {
            id: activateLinuxWatermark
        }

        FlowersWidget {
            id: flowersWidget
        }
    }
}
