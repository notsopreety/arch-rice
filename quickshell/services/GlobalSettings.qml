pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property bool floatingBar: false
    property bool autoHideBar: false
    property bool showBS: true

    FileView {
        id: configFile
        path: Quickshell.shellPath("settings.json")
        blockLoading: true
        blockWrites: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                let content = configFile.text().trim();
                if (content.length > 0) {
                    let obj = JSON.parse(content);
                    if (obj) {
                        let global = obj.global || {};
                        if (global.floatingBar !== undefined) {
                            root.floatingBar = global.floatingBar;
                        }
                        if (global.autoHideBar !== undefined) {
                            root.autoHideBar = global.autoHideBar;
                        }
                        if (global.showBS !== undefined) {
                            root.showBS = global.showBS;
                        }
                    }
                }
            } catch (e) {
                console.log("[GlobalSettings] Failed to parse settings.json: " + e);
            }
        }
    }

    function saveSettings() {
        Config.setSection("global", {
            floatingBar: root.floatingBar,
            autoHideBar: root.autoHideBar,
            showBS: root.showBS
        });
    }

    onFloatingBarChanged: saveSettings()
    onAutoHideBarChanged: saveSettings()
    onShowBSChanged: saveSettings()
}
