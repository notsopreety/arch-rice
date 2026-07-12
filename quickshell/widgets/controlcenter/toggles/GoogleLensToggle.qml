import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Google Lens"
    readonly property bool toggled: false
    
    readonly property string icon: "image_search"
    readonly property string iconOff: "image_search"
    
    readonly property string statusText: "Visual Search"

    readonly property bool hasDetails: false

    property var delayTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            GoogleLensService.capture()
        }
    }

    function action() {
        ControlCenterService.close()
        delayTimer.start()
    }
}
