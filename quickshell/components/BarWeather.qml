import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../core"

RowLayout {
    id: root
    spacing: 6 * Appearance.effectiveScale

    DankIcon {
        name: WeatherService.materialIcon
        size: 13 * Appearance.effectiveScale
        color: Theme.primary
        visible: WeatherService.available
    }

    Text {
        text: WeatherService.available ? (WeatherService.temp + "°C") : "--°C"
        font.family: Theme.font.family
        font.pixelSize: 11 * Appearance.effectiveScale
        font.weight: Font.Medium
        color: Theme.onSurfaceColor
    }
}
