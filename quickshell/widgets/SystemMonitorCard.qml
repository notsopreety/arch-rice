import QtQuick
import "../theme"
import "../services"
import "../components"

Card {
    id: root

    Component.onCompleted: {
        DgopService.addRef("system");
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // CPU Bar
        Column {
            width: (parent.width - 24) / 3
            height: parent.height
            spacing: 8

            Rectangle {
                width: 8
                height: parent.height - 24
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(255, 255, 255, 0.1)

                Rectangle {
                    width: parent.width
                    height: parent.height * Math.min(DgopService.cpuUsage / 100, 1)
                    radius: parent.radius
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: DgopService.cpuUsage > 80 ? "#ffb4ab" : DgopService.cpuUsage > 60 ? "#dac58c" : Theme.primary

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            DankIcon {
                name: "developer_board"
                size: 14
                anchors.horizontalCenter: parent.horizontalCenter
                color: DgopService.cpuUsage > 80 ? "#ffb4ab" : DgopService.cpuUsage > 60 ? "#dac58c" : Theme.primary
            }
        }

        // Temperature Bar
        Column {
            width: (parent.width - 24) / 3
            height: parent.height
            spacing: 8

            Rectangle {
                width: 8
                height: parent.height - 24
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(255, 255, 255, 0.1)

                Rectangle {
                    width: parent.width
                    height: parent.height * Math.min(DgopService.cpuTemperature / 100, 1)
                    radius: parent.radius
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: DgopService.cpuTemperature > 80 ? "#ffb4ab" : DgopService.cpuTemperature > 60 ? "#dac58c" : Theme.primary

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            DankIcon {
                name: "thermostat"
                size: 14
                anchors.horizontalCenter: parent.horizontalCenter
                color: DgopService.cpuTemperature > 80 ? "#ffb4ab" : DgopService.cpuTemperature > 60 ? "#dac58c" : Theme.primary
            }
        }

        // RAM Bar
        Column {
            width: (parent.width - 24) / 3
            height: parent.height
            spacing: 8

            Rectangle {
                width: 8
                height: parent.height - 24
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(255, 255, 255, 0.1)

                Rectangle {
                    width: parent.width
                    height: parent.height * Math.min(DgopService.memoryUsage / 100, 1)
                    radius: parent.radius
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: DgopService.memoryUsage > 85 ? "#ffb4ab" : DgopService.memoryUsage > 70 ? "#dac58c" : Theme.primary

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }
            }

            DankIcon {
                name: "memory"
                size: 14
                anchors.horizontalCenter: parent.horizontalCenter
                color: DgopService.memoryUsage > 85 ? "#ffb4ab" : DgopService.memoryUsage > 70 ? "#dac58c" : Theme.primary
            }
        }
    }
}
