pragma Singleton;

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property string currentLyric: ""
    property bool isSynced: false
    property string backendStatus: "idle" // idle, loading, synced, plain, missing, error
    
    Component.onCompleted: {
        lyricsProc.running = true;
    }

    Process {
        id: lyricsProc
        command: ["python3", Quickshell.shellPath("scripts/lyrics_daemon.py")]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                try {
                    if (line.trim() === "") return;
                    let data = JSON.parse(line.trim());
                    if (data.type === "line") {
                        root.currentLyric = data.text;
                        root.isSynced = data.synced;
                    } else if (data.type === "status") {
                        root.backendStatus = data.status;
                        if (data.status === "loading" || data.status === "idle" || data.status === "missing") {
                            root.currentLyric = "";
                            root.isSynced = false;
                        }
                    }
                } catch (e) {
                    // Ignore parse errors from random stdout noise
                }
            }
        }
        
        onExited: function(exitCode) {
            console.warn("lyrics_daemon.py exited. Restarting...");
            root.backendStatus = "error";
            restartTimer.start();
        }
    }
    
    Timer {
        id: restartTimer
        interval: 3000
        onTriggered: {
            lyricsProc.running = true;
        }
    }
}
