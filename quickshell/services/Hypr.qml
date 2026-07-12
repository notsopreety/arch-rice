pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    property int revision: 0

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: var): var {
        return Hyprland.monitorFor(screen);
    }

    // Get occupied workspaces (workspaces with windows)
    function getOccupiedWorkspaces(): var {
        const occupied = {};
        for (const ws of workspaces.values) {
            occupied[ws.id] = (ws.lastIpcObject?.windows ?? 0) > 0;
        }
        return occupied;
    }

    // Get window classes for a given workspace
    function getWorkspaceWindows(wsId: int): var {
        const windows = [];
        if (typeof toplevels.values !== 'undefined') {
            for (const tl of toplevels.values) {
                const tlWsId = (tl.workspace && typeof tl.workspace === 'object') ? tl.workspace.id : tl.workspace;
                const winClass = tl.lastIpcObject ? (tl.lastIpcObject.class ?? tl.lastIpcObject.initialClass ?? "") : "";
                if (tlWsId === wsId) {
                    windows.push({
                        class: winClass,
                        title: tl.title ?? ""
                    });
                }
            }
        } else {
            for (var i = 0; i < toplevels.count; i++) {
                const tl = toplevels.get(i);
                if (tl) {
                    const tlWsId = (tl.workspace && typeof tl.workspace === 'object') ? tl.workspace.id : tl.workspace;
                    const winClass = tl.lastIpcObject ? (tl.lastIpcObject.class ?? tl.lastIpcObject.initialClass ?? "") : "";
                    if (tlWsId === wsId) {
                        windows.push({
                            class: winClass,
                            title: tl.title ?? ""
                        });
                    }
                }
            }
        }
        return windows;
    }

    // Refresh timer to ensure updates when events are missed
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            Hyprland.refreshWorkspaces();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: var): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            root.revision++;

            // More aggressive refresh for workspace changes
            if (["workspace", "moveworkspace", "activespecial", "focusedmon", "activewindow"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window")) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            }
        }
    }

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.revision++; }
    }
}
