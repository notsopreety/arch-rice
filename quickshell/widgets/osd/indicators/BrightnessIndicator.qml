import QtQuick
import "../../../services"
import "../../osd" 

OsdValueIndicator {
    id: root
    icon: "light_mode"
    rotateIcon: true
    scaleIcon: true
    name: "Brightness"
    value: Brightness.brightness
    shape: "cookie_7"


    onSliderMoved: newValue => {
        Brightness.setBrightness(newValue);
    }
}
