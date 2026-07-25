import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Silent Mode"
    readonly property bool toggled: Notifs.silent
    
    readonly property string icon: "notifications_off"
    readonly property string iconOff: "notifications"
    
    readonly property string statusText: Notifs.silent ? "On" : "Off"

    readonly property bool hasDetails: false

    function action() {
        Notifs.silent = !Notifs.silent
    }
}
