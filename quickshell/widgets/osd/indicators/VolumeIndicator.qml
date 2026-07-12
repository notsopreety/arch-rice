import QtQuick
import "../../../services"
import "../../osd" 

OsdValueIndicator {
    id: osdValues
    value: Audio.volume
    icon: Audio.muted ? "volume_off" : (Audio.volume === 0 ? "volume_mute" : (Audio.volume < 0.33 ? "volume_down" : (Audio.volume < 0.66 ? "volume_mute" : "volume_up")))
    rotateIcon: true
    scaleIcon: true
    name: "Volume"
    shape: "cookie_7"
    isMuted: Audio.muted

    onSliderMoved: newValue => {
        Audio.setVolume(newValue);
    }
}
