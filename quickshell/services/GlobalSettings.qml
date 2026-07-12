pragma Singleton
import QtQuick
import QtCore

QtObject {
    id: root

    property Settings settings: Settings {
        category: {
            Qt.application.organization = "quickshell"
            Qt.application.domain = "quickshell.org"
            Qt.application.name = "quickshell"
            return "Global"
        }
        property bool floatingBar: false
        property bool autoHideBar: false
    }

    property bool floatingBar: settings.floatingBar
    property bool autoHideBar: settings.autoHideBar

    onFloatingBarChanged: {
        settings.floatingBar = floatingBar
    }

    onAutoHideBarChanged: {
        settings.autoHideBar = autoHideBar
    }
}
