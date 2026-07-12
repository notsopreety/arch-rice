import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../core"

Item {
    id: root

    property bool isActive: true

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 50 * Appearance.effectiveScale
    anchors.bottomMargin: 50 * Appearance.effectiveScale

    width: col.implicitWidth
    height: col.implicitHeight
    visible: root.isActive

    Column {
        id: col
        spacing: 2 * Appearance.effectiveScale

        Text {
            text: "Activate Linux"
            font.pointSize: 22 * Appearance.effectiveScale
            font.weight: Font.Light
            color: "#ffffff"
            opacity: 0.4
        }

        Text {
            text: "Go to Settings to activate Linux."
            font.pointSize: 14 * Appearance.effectiveScale
            color: "#ffffff"
            opacity: 0.4
        }
    }

    function loadSettings(data) {
        if (!data || data.trim() === "") return;
        try {
            let parsed = JSON.parse(data);
            if (parsed.activateLinux && parsed.activateLinux.isActive !== undefined) {
                root.isActive = parsed.activateLinux.isActive;
            }
        } catch(e) {
            console.error("Failed to parse settings.json for ActivateLinuxWatermark:", e);
        }
    }

    Timer {
        id: reloadTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: settingsFile.reload()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true
        
        onLoaded: root.loadSettings(text())
        onFileChanged: reloadTimer.restart()
    }
}
