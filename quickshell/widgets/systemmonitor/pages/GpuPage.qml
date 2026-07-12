import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../services"
import "../../../widgets"
import "../../../theme"
import ".."

/**
 * GPU detail page for System Monitor with premium layout and real-time sparkline graph.
 */
Item {
    id: root

    // Determine GPU info dynamically from SystemData or fallback to SystemUsage
    readonly property var activeGpu: {
        if (SystemData.hasValidGpuData && SystemData.availableGpus.length > 0) {
            return SystemData.availableGpus[0];
        }
        return {
            name: SystemUsage.gpuType !== "none" ? SystemUsage.gpuType.toUpperCase() + " GPU" : "GPU",
            vendor: SystemUsage.gpuType !== "none" ? SystemUsage.gpuType : "",
            temp: SystemUsage.gpuTemp,
            pciId: "N/A",
            isDedicated: SystemUsage.gpuType === "nvidia" || SystemUsage.gpuType === "amd",
            typeLabel: SystemUsage.gpuType === "nvidia" || SystemUsage.gpuType === "amd" ? "Discrete" : "Integrated",
            driver: SystemUsage.gpuType === "nvidia" ? "NVIDIA Proprietary" : "Mesa/Open Source",
            usage: SystemUsage.gpuUsage
        };
    }

    readonly property bool hasGpu: SystemUsage.hasGpu || SystemData.hasValidGpuData

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight + (40 * Appearance.effectiveScale)
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick

        ScrollBar.vertical: StyledScrollBar {}

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale

            StyledText {
                text: "GPU Performance"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            // --- MAIN GPU PERFORMANCE CARD ---
            Rectangle {
                visible: root.hasGpu
                Layout.fillWidth: true
                Layout.preferredHeight: 380 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                radius: 16 * Appearance.effectiveScale
                border.width: 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: root.activeGpu.name
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: "white"
                            }
                            StyledText {
                                text: root.activeGpu.vendor.toUpperCase() + " • " + root.activeGpu.typeLabel
                                color: Qt.rgba(255, 255, 255, 0.6)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: Math.round(root.activeGpu.usage) + "%"
                            font.pixelSize: 32 * Appearance.effectiveScale
                            font.weight: Font.Black
                            color: Theme.primary
                        }
                    }

                    // Utilization History Graph
                    PerformanceGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        history: SystemData.gpuHistory.length > 0 ? SystemData.gpuHistory : [0, 0]
                        lineColor: Theme.primary
                        fillColor: Theme.primary
                        maxValue: 100
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText { text: "DRIVER"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: root.activeGpu.driver || "Loaded"; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText { text: "PCI ADDRESS"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: root.activeGpu.pciId || "N/A"; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }
                    }
                }
            }

            // --- DETAILED STAT CARDS GRID ---
            RowLayout {
                visible: root.hasGpu
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                // 1. Core Utilization Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "percent"; color: Theme.primary; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "CORE USAGE"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: Math.round(root.activeGpu.usage) + "%"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: "white"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.08)
                            radius: 2 * Appearance.effectiveScale

                            Rectangle {
                                width: parent.width * (Math.max(0, Math.min(100, root.activeGpu.usage)) / 100.0)
                                height: parent.height
                                color: Theme.primary
                                radius: parent.radius
                            }
                        }
                    }
                }

                // 2. VRAM Memory Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "memory"; color: Theme.secondary; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "VRAM MEMORY"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: SystemUsage.gpuMemTotal > 0 
                                ? `${Math.round(SystemUsage.gpuMemUsed)} / ${Math.round(SystemUsage.gpuMemTotal)} MB`
                                : "N/A"
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: "white"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.08)
                            radius: 2 * Appearance.effectiveScale

                            Rectangle {
                                width: parent.width * SystemUsage.gpuMemPerc
                                height: parent.height
                                color: Theme.secondary
                                radius: parent.radius
                                visible: SystemUsage.gpuMemTotal > 0
                            }
                        }
                    }
                }

                // 3. GPU Temperature Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "thermostat"; color: root.activeGpu.temp > 80 ? "#ffb4ab" : Theme.primary; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "TEMPERATURE"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: root.activeGpu.temp > 0 ? Math.round(root.activeGpu.temp) + "°C" : "N/A"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: root.activeGpu.temp > 80 ? "#ffb4ab" : "white"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.08)
                            radius: 2 * Appearance.effectiveScale

                            Rectangle {
                                width: parent.width * (Math.max(0, Math.min(100, root.activeGpu.temp)) / 100.0)
                                height: parent.height
                                color: root.activeGpu.temp > 80 ? "#ffb4ab" : Theme.primary
                                radius: parent.radius
                                visible: root.activeGpu.temp > 0
                            }
                        }
                    }
                }
            }

            // --- NO GPU FALLBACK CARD ---
            Rectangle {
                visible: !root.hasGpu
                Layout.fillWidth: true
                Layout.preferredHeight: 340 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                radius: 16 * Appearance.effectiveScale

                ColumnLayout {
                    anchors.centerIn: parent
                    Layout.preferredWidth: parent.width * 0.8
                    spacing: 16 * Appearance.effectiveScale
                    
                    MaterialSymbol {
                        text: "videogame_asset_off"
                        iconSize: 48 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.5)
                        Layout.alignment: Qt.AlignCenter
                    }
                    
                    StyledText {
                        text: "GPU performance data not available"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: "white"
                        Layout.alignment: Qt.AlignCenter
                    }
                    
                    StyledText {
                        text: "Your GPU (likely integrated) does not report usage or temperature data to the system sensors."
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Qt.rgba(255, 255, 255, 0.6)
                        Layout.alignment: Qt.AlignCenter
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
