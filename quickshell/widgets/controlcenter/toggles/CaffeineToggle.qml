import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Caffeine"
    readonly property bool toggled: CaffeineService.inhibited
    
    readonly property string icon: "coffee"
    readonly property string iconOff: "coffee"
    
    readonly property string statusText: CaffeineService.inhibited ? "On" : "Off"

    readonly property bool hasDetails: false

    function action() {
        CaffeineService.toggle()
    }
}
