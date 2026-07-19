import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "performance"
import "../core"

Item {
    id: root

    implicitWidth: 772 * Appearance.effectiveScale
    implicitHeight: 410 * Appearance.effectiveScale



    ColumnLayout {
        anchors.fill: parent
        spacing: 16 * Appearance.effectiveScale

        // Top: CPU Hero Card
        HeroCard {
            id: cpuCard
            Layout.fillWidth: true
            Layout.preferredHeight: 180 * Appearance.effectiveScale
            icon: "developer_board"
            label: "CPU"
            subLabel: "Central Processing Unit"
            usage: SystemUsage.cpuPerc
            temperature: DgopService.cpuTemperature
            accent: Theme.primary
        }

        // Bottom Row: Memory, Storage, Network
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16 * Appearance.effectiveScale

            MemoryCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            StorageCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            NetworkCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
