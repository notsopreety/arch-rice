pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Shared read of ~/.config/hypr/.glassmorphism_enabled. Stays false until the file loads.
    readonly property bool enabled: _enabled
    readonly property bool ready: _ready
    property bool _enabled: false
    property bool _ready: false

    FileView {
        id: glassmorphismFlagFile
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassmorphismReloadTimer.restart()
        Component.onCompleted: { try { glassmorphismFlagFile.reload(); } catch(e) {} }
        onLoaded: { root._enabled = true; root._ready = true; }
        onLoadFailed: { root._enabled = false; root._ready = true; }
    }

    Timer {
        id: glassmorphismReloadTimer
        interval: 200
        repeat: false
        onTriggered: { try { glassmorphismFlagFile.reload(); } catch(e) {} }
    }
}
