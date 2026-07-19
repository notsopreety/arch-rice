pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool floatingBar: false
    property bool autoHideBar: false

    FileView {
        id: configFile
        path: Quickshell.shellPath("settings.json")
        blockLoading: true
        blockWrites: true
        watchChanges: true
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
                    }
                }
            } catch (e) {
                console.log("[GlobalSettings] Failed to parse settings.json: " + e);
            }
        }
    }

    function saveSettings() {
        try {
            let obj = {};
            try {
                let currentContent = configFile.text().trim();
                if (currentContent.length > 0) {
                    obj = JSON.parse(currentContent);
                }
            } catch (e) {}
            
            let global = obj.global || {};
            if (global.floatingBar !== floatingBar || global.autoHideBar !== autoHideBar) {
                global.floatingBar = floatingBar;
                global.autoHideBar = autoHideBar;
                obj.global = global;
                configFile.setText(JSON.stringify(obj, null, 2));
            }
        } catch (e) {
            console.log("[GlobalSettings] Failed to write settings.json: " + e);
        }
    }

    onFloatingBarChanged: saveSettings()
    onAutoHideBarChanged: saveSettings()
}
