import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."
import "../../../theme"

/**
 * CPU detail page for System Monitor.
 */
Item {
    id: root

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
                text: "CPU Performance"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 380 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                radius: 16 * Appearance.effectiveScale
                border.width: 0
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 0
                            StyledText { text: SystemData.cpuModel; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Medium; color: "white" }
                            StyledText { 
                                text: `${SystemData.physicalCores} Cores / ${SystemData.cpuThreads} Threads`; 
                                color: Qt.rgba(255, 255, 255, 0.6); 
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledText { 
                            text: Math.round(SystemData.cpuUsage * 100) + "%"
                            font.pixelSize: 32 * Appearance.effectiveScale
                            font.weight: Font.Black
                            color: Theme.primary
                        }
                    }
                    
                    PerformanceGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        history: SystemData.cpuHistory
                        lineColor: Appearance.m3colors.m3primary
                        fillColor: Appearance.m3colors.m3primary
                        maxValue: 100
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20 * Appearance.effectiveScale
                        
                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "TEMPERATURE"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: Math.round(SystemData.cpuTemperature) + "°C"; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "FREQUENCY"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: SystemData.cpuFrequency; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "GOVERNOR"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: SystemData.cpuGovernor; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "ARCHITECTURE"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: SystemData.cpuArchitecture; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "LOAD AVERAGE"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: SystemData.loadAverage; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "UPTIME"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: SystemData.uptime; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; horizontalAlignment: Text.AlignRight; color: "white" }
                        }
                    }
                }
            }

            // Per-Core Utilization Card
            Rectangle {
                visible: SystemData.cpuCoresUsages.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.ceil(SystemData.cpuCoresUsages.length / (contentColumn.width > 700 ? 3 : 2)) * 64 * Appearance.effectiveScale + (80 * Appearance.effectiveScale)
                color: Appearance.colors.colLayer2
                radius: 16 * Appearance.effectiveScale
                border.width: 1 * Appearance.effectiveScale
                border.color: Qt.rgba(255, 255, 255, 0.05)
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        Layout.fillWidth: true
                        MaterialSymbol { text: "analytics"; color: Theme.primary; iconSize: 20 * Appearance.effectiveScale }
                        StyledText {
                            text: "Thread Utilization & Temperatures"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.DemiBold
                            color: "white"
                        }
                        Item { Layout.fillWidth: true }
                    }
                    
                    GridLayout {
                        columns: contentColumn.width > 700 ? 3 : 2
                        Layout.fillWidth: true
                        rowSpacing: 12 * Appearance.effectiveScale
                        columnSpacing: 20 * Appearance.effectiveScale
                        
                        Repeater {
                            model: SystemData.cpuCoresUsages
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52 * Appearance.effectiveScale
                                color: Qt.rgba(255, 255, 255, 0.03)
                                radius: 12 * Appearance.effectiveScale
                                border.width: 1 * Appearance.effectiveScale
                                border.color: Qt.rgba(255, 255, 255, 0.04)

                                property real usageVal: modelData.usage !== undefined ? modelData.usage : modelData
                                property real tempVal: modelData.temp !== undefined ? modelData.temp : 0

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10 * Appearance.effectiveScale
                                    spacing: 4 * Appearance.effectiveScale

                                    RowLayout {
                                        Layout.fillWidth: true
                                        StyledText {
                                            text: "CPU " + (modelData.index !== undefined ? modelData.index : index)
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: Qt.rgba(255, 255, 255, 0.6)
                                        }
                                        Item { Layout.fillWidth: true }
                                        StyledText {
                                            visible: tempVal > 0
                                            text: Math.round(tempVal) + "°C"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.Medium
                                            color: {
                                                if (tempVal > 80) return "#FF8A80";
                                                if (tempVal > 60) return "#FFD54F";
                                                return Qt.rgba(255, 255, 255, 0.4);
                                            }
                                        }
                                        StyledText {
                                            text: Math.round(usageVal) + "%"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: {
                                                if (usageVal > 80) return "#FF8A80";
                                                if (usageVal > 50) return "#FFD54F";
                                                return "#81C995";
                                            }
                                        }
                                    }

                                    // Bar Visualizer
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 6 * Appearance.effectiveScale
                                        color: Qt.rgba(255, 255, 255, 0.05)
                                        radius: 3 * Appearance.effectiveScale
                                        clip: true

                                        Rectangle {
                                            width: parent.width * (usageVal / 100.0)
                                            height: parent.height
                                            radius: 3 * Appearance.effectiveScale
                                            color: {
                                                if (usageVal > 80) return "#FF8A80";
                                                if (usageVal > 50) return "#FFD54F";
                                                return "#81C995";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
