import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"
import "../components"
import "../core"

Card {
    id: root

    signal clicked

    Column {
        anchors.centerIn: parent
        spacing: 8 * Appearance.effectiveScale
        visible: !WeatherService.available

        Text {
            text: "󰖪"
            font.family: Theme.font.monospace
            font.pixelSize: 24 * Appearance.effectiveScale
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "No Weather"
            font.family: Theme.font.family
            font.pixelSize: 11 * Appearance.effectiveScale
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: 8 * Appearance.effectiveScale
        visible: WeatherService.available

        CustomIcon {
            source: WeatherService.googleIcon
            iconFolder: "assets/google-weather"
            width: 32; height: 32; colorize: false
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            id: textCol
            spacing: 2 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: WeatherService.temp + "°C"
                font.family: Theme.font.family
                font.pixelSize: 22 * Appearance.effectiveScale
                color: "white"
                font.weight: Font.Bold
            }

            Text {
                text: WeatherService.condition
                font.family: Theme.font.family
                font.pixelSize: 11 * Appearance.effectiveScale
                color: "#e7bdb3"
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
