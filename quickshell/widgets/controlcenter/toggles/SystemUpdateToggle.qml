import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Updates"
    readonly property bool toggled: SystemUpdateService.updateCount > 0
    readonly property bool available: SystemUpdateService.available
    
    readonly property string icon: "system_update_alt"
    readonly property string iconOff: "system_update_alt"
    
    readonly property string statusText: {
        if (SystemUpdateService.scanning) return "Checking...";
        if (SystemUpdateService.updating) return "Updating...";
        if (SystemUpdateService.updateCount > 0) {
            let parts = [];
            if (SystemUpdateService.pacmanCount > 0) parts.push(SystemUpdateService.pacmanCount + " pac");
            if (SystemUpdateService.aurCount > 0) parts.push(SystemUpdateService.aurCount + " aur");
            if (SystemUpdateService.flatpakCount > 0) parts.push(SystemUpdateService.flatpakCount + " flat");
            if (SystemUpdateService.snapCount > 0) parts.push(SystemUpdateService.snapCount + " snap");
            return parts.length > 0 ? parts.join(" · ") : SystemUpdateService.updateCount + " pending";
        }
        return "Up to date ✓";
    }

    readonly property bool hasDetails: false
    readonly property string tooltipText: "Check and install system updates"

    function action() {
        SystemUpdateService.triggerUpdate()
    }
}
