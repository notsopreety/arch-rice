import QtQuick
import Quickshell
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Color Picker"
    readonly property bool toggled: false
    
    readonly property string icon: "colorize"
    readonly property string iconOff: "colorize"
    
    readonly property string statusText: "Pick a Color"

    readonly property bool hasDetails: false

    function action() {
        ColorPickerService.pickColor()
    }
}
