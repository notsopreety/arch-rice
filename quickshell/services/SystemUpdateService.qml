pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int updateCount: 0
    property bool scanning: false
    property bool updating: false
    property bool available: true

    property int pacmanCount: 0
    property int aurCount: 0
    property int flatpakCount: 0
    property int snapCount: 0

    Process {
        id: countProc
        command: ["/home/sawmer/.config/quickshell/scripts/update_system.sh", "--check"]
        running: false
        
        onRunningChanged: {
            if (running) root.scanning = true;
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    let json = JSON.parse(data.trim());
                    root.updateCount = json.total || 0;
                    root.pacmanCount = json.pacman || 0;
                    root.aurCount = json.aur || 0;
                    root.flatpakCount = json.flatpak || 0;
                    root.snapCount = json.snap || 0;
                } catch(e) {
                    console.error("Failed to parse update check JSON:", e);
                }
                root.scanning = false;
            }
        }
        
        onExited: (exitCode) => {
            root.scanning = false;
        }
    }

    Process {
        id: updateProc
        command: ["kitty", "-e", "/home/sawmer/.config/quickshell/scripts/update_system.sh"]
        running: false
        
        onRunningChanged: {
            root.updating = running;
        }
        
        onExited: (exitCode) => {
            root.updating = false;
            // Trigger check after update terminal closes
            countProc.running = true;
        }
    }

    function checkUpdates() {
        if (!countProc.running) {
            countProc.running = true;
        }
    }

    function triggerUpdate() {
        if (!updateProc.running) {
            updateProc.running = true;
        }
    }

    // Auto-scan on load
    Component.onCompleted: {
        checkUpdates();
    }

    // Periodically check every 2 hours
    Timer {
        interval: 7200000 
        running: true
        repeat: true
        onTriggered: root.checkUpdates()
    }
}
