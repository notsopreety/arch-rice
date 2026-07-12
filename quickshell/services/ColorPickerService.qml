pragma Singleton

import QtQuick
import Quickshell
import "." as QsServices

Singleton {
    id: root

    property var delayTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["hyprpicker", "-a"])
        }
    }

    function pickColor() {
        QsServices.Logger.info("ColorPicker", "Triggering color picker after delay...")
        QsServices.ControlCenterService.close()
        delayTimer.start()
    }
}
