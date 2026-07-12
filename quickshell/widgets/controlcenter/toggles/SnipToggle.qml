import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Snip Tool"
    readonly property bool toggled: false
    
    readonly property string icon: "screenshot_region"
    readonly property string iconOff: "screenshot_region"
    
    readonly property string statusText: "Capture Screen"

    readonly property bool hasDetails: false

    property var delayTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            SnipService.capture()
        }
    }

    function action() {
        ControlCenterService.close()
        delayTimer.start()
    }
}
