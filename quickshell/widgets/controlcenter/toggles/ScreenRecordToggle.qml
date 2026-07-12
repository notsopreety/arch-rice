import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: Screenshot.isRecording ? "Recording" : "Screen Record"
    readonly property bool toggled: Screenshot.isRecording
    
    readonly property string icon: "screen_record"
    readonly property string iconOff: "screen_record"
    
    readonly property string statusText: Screenshot.isRecording ? "Tap to stop" : "Fullscreen"

    readonly property bool hasDetails: false

    function action() {
        if (Screenshot.isRecording) {
            Screenshot.stopRecording()
        } else {
            ControlCenterService.close()
            Screenshot.startRecording()
        }
    }
}
