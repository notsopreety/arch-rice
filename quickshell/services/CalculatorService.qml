pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var history: []

    // File reader/writer for calculator history
    property FileView historyFile: FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.config/quickshell/calculator_history.json"
        preload: true
        watchChanges: false
        blockLoading: true

        onLoaded: {
            try {
                let txt = text();
                if (txt && txt.trim() !== "") {
                    root.history = JSON.parse(txt);
                }
            } catch (e) {
                console.error("Failed to parse calculator history:", e);
            }
        }
    }

    Component.onCompleted: {
        historyFile.reload();
    }

    function saveHistory() {
        historyFile.setText(JSON.stringify(root.history));
    }

    function addEntry(expr, res) {
        let updated = [...root.history];
        updated.unshift({ "expr": expr, "res": res, "time": "Just Now" });
        if (updated.length > 50) updated = updated.slice(0, 50);
        root.history = updated;
        saveHistory();
    }

    function deleteEntry(index) {
        let updated = [...root.history];
        updated.splice(index, 1);
        root.history = updated;
        saveHistory();
    }

    function clearHistory() {
        root.history = [];
        saveHistory();
    }
}
