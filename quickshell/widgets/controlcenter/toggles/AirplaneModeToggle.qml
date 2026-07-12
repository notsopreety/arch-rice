import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Airplane Mode"
    readonly property bool toggled: OsdService.airplaneModeActive
    
    readonly property string icon: "airplanemode_active"
    readonly property string iconOff: "airplanemode_inactive"
    
    readonly property string statusText: OsdService.airplaneModeActive ? "On" : "Off"

    readonly property bool hasDetails: false

    function action() {
        OsdService.toggleAirplaneMode()
    }
}
