pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Central state management for all quickshell panels.
 * Controls visibility of the status bar, notification center, and quick settings.
 */
Singleton {
    id: root

    property bool notificationCenterOpen: false
    property bool quickSettingsOpen: false
    property bool dashboardOpen: false
    property bool systemMonitorOpen: false
    property bool overviewOpen: false
    property bool mediaNotchOpen: false
    property var activeMediaNotchScreen: null
    property var activeTrayItem: null
    property var activeScreen: Quickshell.screens.length ? Quickshell.screens[0] : null

    // --- Media Notch Timing Logic ---
    property alias mediaNotchTimer: mediaNotchTimer
    Timer { 
        id: mediaNotchTimer
        interval: 2000 // Popup persists for 2 seconds
        onTriggered: {
            mediaNotchOpen = false;
            activeMediaNotchScreen = null;
        }
    }

    function openMediaNotch(screen = null) {
        mediaNotchTimer.stop();
        if (screen !== null) activeMediaNotchScreen = screen;
        mediaNotchOpen = true;
    }

    function stopMediaNotchTimer() {
        mediaNotchTimer.stop();
    }
    // ---------------------------------

    // System Monitor Navigation
    property int systemMonitorIndex: 0
    property int performanceSubIndex: 0

    onNotificationCenterOpenChanged: {
        if (notificationCenterOpen) {
            quickSettingsOpen = false
            dashboardOpen = false
        }
    }

    onQuickSettingsOpenChanged: {
        if (quickSettingsOpen) {
            notificationCenterOpen = false
            dashboardOpen = false
        }
    }

    onDashboardOpenChanged: {
        if (dashboardOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
        }
    }

    onSystemMonitorOpenChanged: {
        if (systemMonitorOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            dashboardOpen = false
        }
    }

    onOverviewOpenChanged: {
        if (overviewOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            dashboardOpen = false
            systemMonitorOpen = false
        }
    }

    function activateSystemMonitor() {
        const moveCmd = Hyprland.usingLua
            ? "hyprctl dispatch \"hl.dsp.window.move({ workspace = \\\"name:$CUR_WS\\\", window = \\\"address:$ADDR\\\", follow = false })\""
            : "hyprctl dispatch movetoworkspacesilent name:$CUR_WS, address:$ADDR";
        const focusCmd = Hyprland.usingLua
            ? "hyprctl dispatch \"hl.dsp.focus({ window = \\\"address:$ADDR\\\" })\""
            : "hyprctl dispatch focuswindow address:$ADDR";
        const cmd = `
            # Find System Monitor window address
            ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "System Monitor" and .class == "org.quickshell") | .address')
            
            if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
                # Not open, so open it
                quickshell ipc call systemmonitor open_direct
                exit 0
            fi

            # Check if it's already the active window
            ACTIVE_ADDR=$(hyprctl activewindow -j | jq -r .address)
            
            if [ "$ADDR" = "$ACTIVE_ADDR" ]; then
                # Already focused here, so close it
                quickshell ipc call systemmonitor close
            else
                # Pull it here! Get current workspace name
                CUR_WS=$(hyprctl activeworkspace -j | jq -r .name)
                
                # Move window to current workspace silently
                ${moveCmd}
                
                # Micro-delay
                sleep 0.05
                ${focusCmd}
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }
}
