import QtQuick
import "../../../services"
import "../../osd" 

OsdValueIndicator {
    id: root
    icon: "keyboard"
    rotateIcon: true
    scaleIcon: true
    name: "Kbd Backlight"
    value: OsdService.kbdBrightness
    shape: "cookie_7"

}
