import QtQuick
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../core"

Item {
    id: root

    property bool isActive: false

    // Fill the entire desktop canvas so each image can anchor to any corner
    anchors.fill: parent
    visible: root.isActive

    // ── Bottom Center: flowers.png ──────────────────────────────────────────
    Image {
        id: flowerImage
        source: "../../assets/flowers.png"
        fillMode: Image.PreserveAspectFit
        width: 800
        sourceSize.width: 800
        opacity: 1.0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }

    // ── Top Right: sakura.png ───────────────────────────────────────────────
    Image {
        id: sakuraImage
        source: "../../assets/sakura.png"
        fillMode: Image.PreserveAspectFit
        width: 350
        sourceSize.width: 350
        opacity: 1.0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 0
        anchors.rightMargin: 0
    }

    function loadSettings(data) {
        if (!data || data.trim() === "") return;
        try {
            let parsed = JSON.parse(data);
            if (parsed.flowersWidget && parsed.flowersWidget.isActive !== undefined) {
                root.isActive = parsed.flowersWidget.isActive;
            }
        } catch(e) {
            console.error("Failed to parse settings.json for FlowersWidget:", e);
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
