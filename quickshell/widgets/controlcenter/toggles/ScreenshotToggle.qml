import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Screenshot"
    readonly property bool toggled: false
    
    readonly property string icon: "photo_camera"
    readonly property string iconOff: "photo_camera"
    
    readonly property string statusText: "Fullscreen"

    readonly property bool hasDetails: false

    property var delayTimer: Timer {
        interval: 1000
        repeat: false
        onTriggered: {
            Screenshot.takeScreenshot("screen")
        }
    }

    function action() {
        ControlCenterService.close()
        delayTimer.start()
    }
}
