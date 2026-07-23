import QtQuick
import QtQuick.Layouts
import "../core"
import "../services"

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
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.2 - 16 * Appearance.effectiveScale
            anchors.right: parent.right
            y: 0 * Appearance.effectiveScale
            height: 100 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            NepaliCalendarCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 160 * Appearance.effectiveScale
                visible: GlobalSettings.showBS
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: (GlobalSettings.showBS ? 180 : 280) * Appearance.effectiveScale

                WeatherOverviewCard {
                    anchors.centerIn: parent
                    scale: GlobalSettings.showBS ? 1.0 : 1.15
                    width: parent.width / scale
                    height: parent.height / scale
                    onClicked: root.switchToWeatherTab()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: (GlobalSettings.showBS ? 170 : 220) * Appearance.effectiveScale

                UserInfoCard {
                    anchors.centerIn: parent
                    scale: GlobalSettings.showBS ? 1.0 : 1.15
                    width: parent.width / scale
                    height: parent.height / scale
                }
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
