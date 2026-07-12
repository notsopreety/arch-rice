pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Snip Tool Service
// Coordinates triggering the Snip Window overlay
Singleton {
    id: root

    property var overlayWindow: null

    function capture() {
        QsServices.Logger.info("SnipTool", "Opening Snip Tool overlay...")
        if (overlayWindow) {
            overlayWindow.open()
        } else {
            QsServices.Logger.error("SnipTool", "SnipWindow reference not set!")
        }
    }
}
