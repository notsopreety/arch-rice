import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../services"
import "../../../widgets"
import "../../../theme"
import ".."

/**
 * Memory detail page for System Monitor with premium layout and real-time sparkline graph.
 */
Item {
    id: root

    function formatMemory(mbValue) {
        if (mbValue < 1024) return Math.round(mbValue) + " MB";
        return (mbValue / 1024).toFixed(2) + " GB";
    }

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
                text: "Memory Performance"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            // --- MAIN MEMORY CARD ---
            Rectangle {
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
                                text: "System RAM"
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: "white"
                            }
                            StyledText {
                                text: `Total Capacity: ${(SystemData.totalMemoryMB / 1024).toFixed(2)} GB`
                                color: Qt.rgba(255, 255, 255, 0.6)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: Math.round(SystemData.memUsage * 100) + "%"
                            font.pixelSize: 32 * Appearance.effectiveScale
                            font.weight: Font.Black
                            color: "#8AB4F8"
                        }
                    }

                    // Memory History Graph
                    PerformanceGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        history: SystemData.memHistory
                        lineColor: "#8AB4F8"
                        fillColor: "#8AB4F8"
                        maxValue: 100
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText { text: "ACTIVE USED"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: formatMemory(SystemData.usedMemoryMB); font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText { text: "AVAILABLE RAM"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Qt.rgba(255, 255, 255, 0.4) }
                            StyledText { text: formatMemory(SystemData.totalMemoryMB - SystemData.usedMemoryMB); font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; color: "white" }
                        }
                    }
                }
            }

            // --- DETAILED RAM CARDS GRID (Row 1) ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                // 1. Used Memory Detail
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
                            MaterialSymbol { text: "memory"; color: "#8AB4F8"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "USED RAM"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: Math.round(SystemData.memUsage * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: "#8AB4F8"
                            }
                        }

                        StyledText {
                            text: formatMemory(SystemData.usedMemoryMB)
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
                                width: parent.width * SystemData.memUsage
                                height: parent.height
                                color: "#8AB4F8"
                                radius: parent.radius
                            }
                        }
                    }
                }

                // 2. Available Memory Detail
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
                            MaterialSymbol { text: "check_circle"; color: "#a8dab5"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "AVAILABLE RAM"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: Math.round((1.0 - SystemData.memUsage) * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: "#a8dab5"
                            }
                        }

                        StyledText {
                            text: formatMemory(SystemData.totalMemoryMB - SystemData.usedMemoryMB)
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
                                width: parent.width * (1.0 - SystemData.memUsage)
                                height: parent.height
                                color: "#a8dab5"
                                radius: parent.radius
                            }
                        }
                    }
                }
            }

            // --- DETAILED RAM CARDS GRID (Row 2) ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                // 3. Cached Memory Detail
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
                            MaterialSymbol { text: "storage"; color: "#FDD663"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "CACHED"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: SystemData.totalMemoryMB > 0 ? Math.round((SystemData.cachedMemoryMB / SystemData.totalMemoryMB) * 100) + "%" : "0%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: "#FDD663"
                            }
                        }

                        StyledText {
                            text: formatMemory(SystemData.cachedMemoryMB)
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
                                width: parent.width * (SystemData.totalMemoryMB > 0 ? (SystemData.cachedMemoryMB / SystemData.totalMemoryMB) : 0)
                                height: parent.height
                                color: "#FDD663"
                                radius: parent.radius
                            }
                        }
                    }
                }

                // 4. Free Memory Detail
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
                            MaterialSymbol { text: "align_horizontal_left"; color: "#9E9E9E"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "FREE RAM"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: SystemData.totalMemoryMB > 0 ? Math.round((SystemData.freeMemoryMB / SystemData.totalMemoryMB) * 100) + "%" : "0%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: "#9E9E9E"
                            }
                        }

                        StyledText {
                            text: formatMemory(SystemData.freeMemoryMB)
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
                                width: parent.width * (SystemData.totalMemoryMB > 0 ? (SystemData.freeMemoryMB / SystemData.totalMemoryMB) : 0)
                                height: parent.height
                                color: "#9E9E9E"
                                radius: parent.radius
                            }
                        }
                    }
                }

                // 5. Swap Space Detail
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
                            MaterialSymbol { text: "swap_horiz"; color: Theme.secondary; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "SWAP MEMORY"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: SystemData.totalSwapMB > 0 ? Math.round(SystemData.swapUsage * 100) + "%" : "0%"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.DemiBold
                                color: Theme.secondary
                            }
                        }

                        StyledText {
                            text: SystemData.totalSwapMB > 0 
                                ? `${formatMemory(SystemData.usedSwapMB)} / ${formatMemory(SystemData.totalSwapMB)}`
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
                                width: parent.width * SystemData.swapUsage
                                height: parent.height
                                color: Theme.secondary
                                radius: parent.radius
                                visible: SystemData.totalSwapMB > 0
                            }
                        }
                    }
                }
            }
        }
    }
}
