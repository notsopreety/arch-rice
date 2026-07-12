import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../components"

Item {
    id: root

    implicitWidth: 700
    implicitHeight: 410

    property bool showHourly: false

    // ── UNAVAILABLE STATE ──
    Column {
        anchors.centerIn: parent
        spacing: 24
        visible: !WeatherService.available

        Text {
            text: "󰖪"
            font.family: Theme.font.monospace
            font.pixelSize: 48
            color: Qt.rgba(1, 1, 1, 0.5)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "No Weather Data Available"
                font.family: Theme.font.family
                font.pixelSize: 16
                color: Qt.rgba(1, 1, 1, 0.7)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: refreshBtnUnavail
                text: "󰑐"
                font.family: Theme.font.monospace
                font.pixelSize: 18
                color: Qt.rgba(1, 1, 1, 0.4)
                anchors.verticalCenter: parent.verticalCenter
                property bool spinning: false

                RotationAnimation on rotation {
                    running: refreshBtnUnavail.spinning
                    from: 0; to: 360; duration: 1000
                    loops: Animation.Infinite
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        refreshBtnUnavail.spinning = true;
                        WeatherService.forceRefresh();
                        unavailTimer.restart();
                    }
                }
                Timer { id: unavailTimer; interval: 3000; onTriggered: refreshBtnUnavail.spinning = false }
            }
        }
    }

    // ── MAIN CONTENT ──
    Column {
        id: mainColumn
        anchors.fill: parent
        visible: WeatherService.available
        spacing: 10

        // ── HERO CARD ──
        Rectangle {
            id: heroCard
            width: parent.width
            height: heroContent.height + 28
            radius: Theme.rounding.normal
            color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
            border.color: Theme.outlineVariant
            border.width: 1

            Column {
                id: heroContent
                x: 20; y: 14
                width: parent.width - 40
                spacing: 12

                Item {
                    width: parent.width
                    height: Math.max(heroLeft.height, heroMetricsGrid.height)

                    // Left: Icon + Temp + Condition
                    Row {
                        id: heroLeft
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 20

                        CustomIcon {
                            source: WeatherService.googleIcon
                            iconFolder: "assets/google-weather"
                            width: 48; height: 48; colorize: false
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                spacing: 4
                                Text {
                                    text: WeatherService.temp + "°"
                                    font.family: Theme.font.family
                                    font.pixelSize: 36
                                    font.weight: Font.Light
                                    color: "white"
                                }
                                Text {
                                    text: "C"
                                    font.family: Theme.font.family
                                    font.pixelSize: 14
                                    color: Qt.rgba(1, 1, 1, 0.7)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: WeatherService.condition
                                font.family: Theme.font.family
                                font.pixelSize: 14
                                color: Qt.rgba(1, 1, 1, 0.7)
                            }

                            Text {
                                text: "Feels Like " + WeatherService.feelsLike + "°"
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }

                            Text {
                                text: {
                                    var parts = [];
                                    if (WeatherService.city) parts.push(WeatherService.city);
                                    if (WeatherService.country) parts.push(WeatherService.country);
                                    return parts.join(", ");
                                }
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.5)
                                visible: text.length > 0
                            }
                        }
                    }

                    // Right: 3×2 Metrics grid
                    Grid {
                        id: heroMetricsGrid
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        columns: 3
                        columnSpacing: 24
                        rowSpacing: 10

                        Repeater {
                            model: [
                                { icon: "󰖗", label: "Humidity", value: WeatherService.humidity + "%" },
                                { icon: "󰖝", label: "Wind", value: WeatherService.wind + " km/h" },
                                { icon: "󰓅", label: "Pressure", value: WeatherService.pressure + " hPa" },
                                { icon: "󰖗", label: "Precipitation", value: WeatherService.precipitationProbability + "%" },
                                { icon: "󰖨", label: "Sunrise", value: WeatherService.sunrise || "--" },
                                { icon: "󰖛", label: "Sunset", value: WeatherService.sunset || "--" }
                            ]

                            Row {
                                spacing: 6
                                Text {
                                    text: modelData.icon
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 12
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Column {
                                    spacing: 2
                                    Text {
                                        text: modelData.label
                                        font.family: Theme.font.family
                                        font.pixelSize: 10
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                    }
                                    Text {
                                        text: modelData.value
                                        font.family: Theme.font.family
                                        font.pixelSize: 13
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── CHIPS ROW ──
        Item {
            id: chipsRow
            width: parent.width
            height: 30

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: dailyChipText.width + 24; height: 28; radius: 14
                    color: !root.showHourly ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: !root.showHourly ? Theme.primary : Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    Text { id: dailyChipText; anchors.centerIn: parent; text: "Daily"; font.family: Theme.font.family; font.pixelSize: 12; font.weight: !root.showHourly ? Font.Medium : Font.Normal; color: !root.showHourly ? Theme.primary : "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.showHourly = false }
                }

                Rectangle {
                    width: hourlyChipText.width + 24; height: 28; radius: 14
                    color: root.showHourly ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: root.showHourly ? Theme.primary : Qt.rgba(1, 1, 1, 0.15)
                    border.width: 1
                    Text { id: hourlyChipText; anchors.centerIn: parent; text: "Hourly"; font.family: Theme.font.family; font.pixelSize: 12; font.weight: root.showHourly ? Font.Medium : Font.Normal; color: root.showHourly ? Theme.primary : "white" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.showHourly = true }
                }
            }

            Text {
                id: refreshBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "󰑐"
                font.family: Theme.font.monospace
                font.pixelSize: 18
                color: Qt.rgba(1, 1, 1, 0.4)
                property bool spinning: false

                RotationAnimation on rotation {
                    running: refreshBtn.spinning
                    from: 0; to: 360; duration: 1000
                    loops: Animation.Infinite
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        refreshBtn.spinning = true;
                        WeatherService.forceRefresh();
                        mainRefreshTimer.restart();
                    }
                }
                Timer { id: mainRefreshTimer; interval: 3000; onTriggered: refreshBtn.spinning = false }
            }
        }

        // ── FORECAST AREA ──
        Item {
            width: parent.width
            height: root.height - heroCard.height - chipsRow.height - mainColumn.spacing * 2

            // ── Daily Forecast ──
            Flickable {
                id: dailyFlickable
                anchors.fill: parent
                visible: !root.showHourly
                contentWidth: dailyRow.width
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: dailyRow
                    height: dailyFlickable.height
                    spacing: 8

                    Repeater {
                        model: WeatherService.forecast

                        Rectangle {
                            required property var modelData
                            required property int index
                            width: (dailyFlickable.width - 6 * 8) / 7
                            height: dailyRow.height
                            radius: Theme.rounding.normal

                            color: index === 0
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                : Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.3)
                            border.color: index === 0 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                            border.width: index === 0 ? 1 : 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: modelData.day || "--"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    font.weight: index === 0 ? Font.Medium : Font.Normal
                                    color: index === 0 ? Theme.primary : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                CustomIcon {
                                    source: WeatherService.getGoogleWeatherIcon(modelData.wCode, true)
                                    iconFolder: "assets/google-weather"
                                    width: 24; height: 24; colorize: false
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: modelData.tempMin + "° / " + modelData.tempMax + "°"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: index === 0 ? Theme.primary : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Row {
                                    spacing: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Text { text: "󰖗"; font.family: Theme.font.monospace; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.precipitationProbability + "%"; font.family: Theme.font.family; font.pixelSize: 9; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }
            }

            // ── Hourly Forecast ──
            Flickable {
                id: hourlyFlickable
                anchors.fill: parent
                visible: root.showHourly
                contentWidth: hourlyRow.width
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                Component.onCompleted: {
                    // Scroll to current hour
                    var now = new Date();
                    var cardW = (hourlyFlickable.width - 7 * 8) / 8;
                    var targetX = now.getHours() * (cardW + 8);
                    contentX = Math.min(targetX, Math.max(0, contentWidth - width));
                }

                Row {
                    id: hourlyRow
                    height: hourlyFlickable.height
                    spacing: 8

                    Repeater {
                        model: WeatherService.hourlyForecast

                        Rectangle {
                            required property var modelData
                            required property int index
                            width: (hourlyFlickable.width - 7 * 8) / 8
                            height: hourlyRow.height
                            radius: Theme.rounding.normal

                            property bool isCurrent: index === new Date().getHours()

                            color: isCurrent
                                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                : Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.3)
                            border.color: isCurrent ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
                            border.width: isCurrent ? 1 : 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.time || "--"
                                    font.family: Theme.font.family
                                    font.pixelSize: 10
                                    font.weight: isCurrent ? Font.Medium : Font.Normal
                                    color: isCurrent ? Theme.primary : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                CustomIcon {
                                    source: WeatherService.getGoogleWeatherIcon(modelData.wCode, true)
                                    iconFolder: "assets/google-weather"
                                    width: 20; height: 20; colorize: false
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: modelData.temp + "°"
                                    font.family: Theme.font.family
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: isCurrent ? Theme.primary : "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "Feels " + modelData.feelsLike + "°"
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Row {
                                    spacing: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Text { text: "󰖗"; font.family: Theme.font.monospace; font.pixelSize: 7; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.humidity + "%"; font.family: Theme.font.family; font.pixelSize: 8; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                }

                                Row {
                                    spacing: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Text { text: "󰖝"; font.family: Theme.font.monospace; font.pixelSize: 7; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.wind + " km/h"; font.family: Theme.font.family; font.pixelSize: 8; color: Qt.rgba(1,1,1,0.5); anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
