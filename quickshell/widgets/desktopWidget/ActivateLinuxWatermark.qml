import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../core"
import "../widgetCanvas"

Item {
    id: root

    property bool isActive: true
    property real customScale: 1.0

    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 50 * Appearance.effectiveScale
    anchors.bottomMargin: 50 * Appearance.effectiveScale

    width: col.implicitWidth * customScale
    height: col.implicitHeight * customScale
    visible: root.isActive

    Column {
        id: col
        spacing: 2 * Appearance.effectiveScale
        scale: root.customScale
        transformOrigin: Item.BottomRight

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

    WidgetResizeFrame {
        target: root
        widgetName: "Watermark"
        lockAspectRatio: true
        aspectRatio: col.implicitWidth / (col.implicitHeight > 0 ? col.implicitHeight : 1)
        minWidth: 80 * Appearance.effectiveScale
        minHeight: 30 * Appearance.effectiveScale
        maxWidth: 600 * Appearance.effectiveScale
        maxHeight: 300 * Appearance.effectiveScale

        onResized: (newW, newH) => {
            root.customScale = Math.max(0.4, Math.min(3.0, newW / col.implicitWidth));
        }
        onResizeEnded: (finalW, finalH) => {
            root.customScale = Math.max(0.4, Math.min(3.0, finalW / col.implicitWidth));
            root.saveSettings();
        }
    }

    function saveSettings() {
        Config.setSection("activateLinux", { scale: parseFloat(root.customScale.toFixed(2)) });
    }

    function loadSettings(data) {
        if (!data || data.trim() === "") return;
        try {
            let parsed = JSON.parse(data);
            if (parsed.activateLinux) {
                if (parsed.activateLinux.isActive !== undefined) {
                    root.isActive = parsed.activateLinux.isActive;
                }
                if (parsed.activateLinux.scale !== undefined) {
                    root.customScale = parsed.activateLinux.scale;
                }
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
