import QtQuick
import "../../../services"
import "../../osd" 

OsdValueIndicator {
    id: root
    value: Math.min(1.0, Audio.sourceVolume)
    icon: Audio.sourceMuted ? "mic_off" : "mic"
    rotateIcon: true
    scaleIcon: true
    name: "Microphone"
    shape: "cookie_7"
    isMuted: Audio.sourceMuted

    onSliderMoved: newValue => {
        Audio.setSourceVolume(newValue);
    }
}
