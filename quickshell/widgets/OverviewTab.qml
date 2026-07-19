import QtQuick
import QtQuick.Layouts
import "../core"

Item {
    id: root

    implicitWidth: 700 * Appearance.effectiveScale
    implicitHeight: 410 * Appearance.effectiveScale

    signal switchToWeatherTab
    signal switchToMediaTab
    signal closeDash

    Item {
        anchors.fill: parent
        
        // Clock - top left
        ClockCard {
            x: 0 * Appearance.effectiveScale
            y: 0 * Appearance.effectiveScale
            width: parent.width * 0.2 - 16 * 2 * Appearance.effectiveScale
            height: 180 * Appearance.effectiveScale
        }

        // Top Row for Calendar, Weather, and User Info (responsive layout)
        RowLayout {
            x: parent.width * 0.2 - 16 * Appearance.effectiveScale
            y: 0 * Appearance.effectiveScale
            width: parent.width * 0.8 + 16
            height: 100 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            NepaliCalendarCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 180 * Appearance.effectiveScale
            }

            WeatherOverviewCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 130 * Appearance.effectiveScale
                visible: true
                onClicked: root.switchToWeatherTab()
            }

            UserInfoCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 250 * Appearance.effectiveScale
            }
        }

        // SystemMonitor - middle left
        SystemMonitorCard {
            x: 0 * Appearance.effectiveScale
            y: (180 + 16) * Appearance.effectiveScale
            width: parent.width * 0.2 - 16 * 2 * Appearance.effectiveScale
            height: 210 * Appearance.effectiveScale
        }

        // Calendar - bottom middle
        CalendarOverviewCard {
            x: parent.width * 0.2 - 16 * Appearance.effectiveScale
            y: (100 + 16) * Appearance.effectiveScale
            width: parent.width * 0.6
            height: 290 * Appearance.effectiveScale
        }

        // Media - bottom right
        MediaOverviewCard {
            x: parent.width * 0.8
            y: (100 + 16) * Appearance.effectiveScale
            width: parent.width * 0.2
            height: 290 * Appearance.effectiveScale
            onClicked: root.switchToMediaTab()
        }
    }
}
