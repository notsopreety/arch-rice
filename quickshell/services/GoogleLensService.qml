pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Google Lens Visual Search Service
// Opens the frozen-screen overlay for region selection
Singleton {
    id: root

    property var overlayWindow: null

    function capture() {
        QsServices.Logger.info("GoogleLens", "Opening Google Lens overlay...")
        if (overlayWindow) {
            overlayWindow.open()
        } else {
            QsServices.Logger.error("GoogleLens", "GoogleLensWindow reference not set!")
        }
    }
}
