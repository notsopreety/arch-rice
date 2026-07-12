import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"
import "../components"

Card {
    id: root

    signal clicked

    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: !WeatherService.available

        Text {
            text: "󰖪"
            font.family: Theme.font.monospace
            font.pixelSize: 24
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "No Weather"
            font.family: Theme.font.family
            font.pixelSize: 11
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Row {
        id: weatherRow
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        visible: WeatherService.available

        CustomIcon {
            source: WeatherService.googleIcon
            iconFolder: "assets/google-weather"
            width: 32; height: 32; colorize: false
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            id: textCol
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: WeatherService.temp + "°C"
                font.family: Theme.font.family
                font.pixelSize: 22
                color: "white"
                font.weight: Font.Bold
            }

            Text {
                text: WeatherService.condition
                font.family: Theme.font.family
                font.pixelSize: 11
                color: "#e7bdb3"
                elide: Text.ElideRight
                width: root.width - weatherRow.anchors.leftMargin - textCol.x - 8
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
