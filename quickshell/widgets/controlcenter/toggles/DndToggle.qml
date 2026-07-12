import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Do Not Disturb"
    readonly property bool toggled: Notifs.dnd
    
    readonly property string icon: "do_not_disturb_on"
    readonly property string iconOff: "do_not_disturb_off"
    
    readonly property string statusText: Notifs.dnd ? "On" : "Off"

    readonly property bool hasDetails: false

    function action() {
        Notifs.dnd = !Notifs.dnd
    }
}
