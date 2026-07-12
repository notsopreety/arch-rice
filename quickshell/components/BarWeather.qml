import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

RowLayout {
    id: root
    spacing: 6

    DankIcon {
        name: WeatherService.materialIcon
        size: 13
        color: Theme.primary
        visible: WeatherService.available
    }

    Text {
        text: WeatherService.available ? (WeatherService.temp + "°C") : "--°C"
        font.family: Theme.font.family
        font.pixelSize: 11
        font.weight: Font.Medium
        color: Theme.onSurfaceColor
    }
}
