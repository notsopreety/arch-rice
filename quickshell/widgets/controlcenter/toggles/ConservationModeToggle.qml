import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Conservation"
    readonly property bool toggled: ConservationMode.active
    readonly property bool available: ConservationMode.available
    
    readonly property string icon: "battery_charging_80"
    readonly property string iconOff: "battery_charging_full"
    
    readonly property string statusText: ConservationMode.active ? "On" : "Off"

    readonly property bool hasDetails: false
    readonly property string tooltipText: "Lenovo Battery Conservation Mode"

    function action() {
        ConservationMode.toggle()
    }
}
