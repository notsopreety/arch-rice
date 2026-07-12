pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "." as QsServices

Singleton {
    id: root
    
    property bool inhibited: false
    property int inhibitorPid: -1

    onInhibitedChanged: {
        QsServices.OsdService.idleInhibited = inhibited;
        if (QsServices.OsdService.isStartupDone) {
            QsServices.OsdService.idleInhibitorTriggered(inhibited);
        }
    }
    
    function toggle() {
        if (inhibited) {
            disableInhibitor();
            inhibited = false;
        } else {
            enableInhibitor();
            inhibited = true;
        }
    }

    function setInhibited(val) {
        if (val !== inhibited) {
            if (val) {
                enableInhibitor();
                inhibited = true;
            } else {
                disableInhibitor();
                inhibited = false;
            }
        }
    }
    
    function enableInhibitor() {
        QsServices.Logger.info("CaffeineService", "Enabling")
        enableProcess.running = false
        enableProcess.running = true
    }
    
    function disableInhibitor() {
        QsServices.Logger.info("CaffeineService", "Disabling")
        disableProcess.running = false
        disableProcess.running = true
    }
    
    // Enable idle inhibitor using systemd-inhibit
    Process {
        id: enableProcess
        command: ["/bin/sh", "-c", "systemd-inhibit --what=idle --who=QuickShell --why='Caffeine mode enabled' sleep infinity & echo $!"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const pid = parseInt(data.trim())
                if (!isNaN(pid) && pid > 0) {
                    root.inhibitorPid = pid
                    QsServices.Logger.debug("CaffeineService", `Started PID=${pid}`)
                }
            }
        }
    }
    
    // Disable idle inhibitor
    Process {
        id: disableProcess
        command: ["/bin/sh", "-c", root.inhibitorPid > 0 ? 
                  `kill ${root.inhibitorPid} 2>/dev/null || pkill -f 'systemd-inhibit.*QuickShell'` :
                  "pkill -f 'systemd-inhibit.*QuickShell'"]
        running: false
        
        onExited: {
            root.inhibitorPid = -1
            QsServices.Logger.debug("CaffeineService", "Stopped")
        }
    }

    Timer {
        id: watcherTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkProcess.running = false
            checkProcess.running = true
        }
    }

    Process {
        id: checkProcess
        command: ["sh", "-c", "pgrep -f '^(.*/)?systemd-inhibit.*[i]dle' >/dev/null || pgrep -x 'wayland-idle-inhibitor' >/dev/null || pgrep -x 'hyprland-idle-inhibitor' >/dev/null"]
        running: false
        onExited: code => {
            var isSystemInhibited = (code === 0);
            if (root.inhibited !== isSystemInhibited) {
                root.inhibited = isSystemInhibited;
            }
        }
    }
    
    Component.onCompleted: {
        QsServices.Logger.debug("CaffeineService", "Service loaded")
    }
}
