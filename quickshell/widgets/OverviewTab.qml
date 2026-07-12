import QtQuick
import QtQuick.Layouts

Item {
    id: root

    implicitWidth: 700
    implicitHeight: 410

    signal switchToWeatherTab
    signal switchToMediaTab
    signal closeDash

    Item {
        anchors.fill: parent
        
        // Clock - top left
        ClockCard {
            x: 0
            y: 0
            width: parent.width * 0.2 - 16 * 2
            height: 180
        }

        // Top Row for Calendar, Weather, and User Info (responsive layout)
        RowLayout {
            x: parent.width * 0.2 - 16
            y: 0
            width: parent.width * 0.8 + 16
            height: 100
            spacing: 16

            NepaliCalendarCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 180
            }

            WeatherOverviewCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 130
                visible: true
                onClicked: root.switchToWeatherTab()
            }

            UserInfoCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 250
            }
        }

        // SystemMonitor - middle left
        SystemMonitorCard {
            x: 0
            y: 180 + 16
            width: parent.width * 0.2 - 16 * 2
            height: 210
        }

        // Calendar - bottom middle
        CalendarOverviewCard {
            x: parent.width * 0.2 - 16
            y: 100 + 16
            width: parent.width * 0.6
            height: 290
        }

        // Media - bottom right
        MediaOverviewCard {
            x: parent.width * 0.8
            y: 100 + 16
            width: parent.width * 0.2
            height: 290
            onClicked: root.switchToMediaTab()
        }
    }
}
