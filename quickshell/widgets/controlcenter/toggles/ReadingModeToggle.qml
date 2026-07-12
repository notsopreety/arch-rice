import QtQuick
import Quickshell
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Night Light"
    readonly property bool toggled: OsdService.nightLightActive
    
    readonly property string icon: "sunny"
    readonly property string iconOff: "nightlight"
    
    readonly property string statusText: toggled ? "On" : "Off"

    readonly property bool hasDetails: false

    function action() {
        OsdService.toggleNightLight()
    }
}
