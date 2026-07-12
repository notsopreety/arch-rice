import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."
import "../../../theme"

/**
 * Network detail page for System Monitor with premium layout and micro-metrics.
 */
Item {
    id: root

    // Formatter function to show dynamic units
    function formatRate(bytesPerSec) {
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s";
        let kb = bytesPerSec / 1024;
        if (kb < 1024) return kb.toFixed(1) + " KB/s";
        let mb = kb / 1024;
        return mb.toFixed(2) + " MB/s";
    }

    function formatTotal(bytes) {
        if (!bytes) return "0 B";
        if (bytes < 1024) return bytes + " B";
        let kb = bytes / 1024;
        if (kb < 1024) return kb.toFixed(1) + " KB";
        let mb = kb / 1024;
        if (mb < 1024) return mb.toFixed(1) + " MB";
        let gb = mb / 1024;
        return gb.toFixed(2) + " GB";
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
                text: "Network Activity"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            // --- DOUBLE GRAPH SECTION ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 380 * Appearance.effectiveScale
                color: Appearance.colors.colLayer2
                radius: 16 * Appearance.effectiveScale
                border.width: 0
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 0
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 16 * Appearance.effectiveScale
                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText { text: "Network Bandwidth Traffic"; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold; color: "white" }
                            StyledText { 
                                text: "Combined Traffic: " + formatRate(SystemData.networkTotalRate); 
                                color: Qt.rgba(255, 255, 255, 0.6); 
                                font.pixelSize: Appearance.font.pixelSize.smaller 
                            }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                            spacing: 24 * Appearance.effectiveScale
                            ColumnLayout {
                                spacing: 0
                                StyledText { text: "DOWNLOAD"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: "#81C995"; Layout.alignment: Qt.AlignRight }
                                StyledText { text: formatRate(SystemData.networkRxRate); font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Black; color: "white"; Layout.alignment: Qt.AlignRight }
                            }
                            ColumnLayout {
                                spacing: 0
                                StyledText { text: "UPLOAD"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: "#FF8A65"; Layout.alignment: Qt.AlignRight }
                                StyledText { text: formatRate(SystemData.networkTxRate); font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Black; color: "white"; Layout.alignment: Qt.AlignRight }
                            }
                        }
                    }
                    
                    PerformanceGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        history: SystemData.networkRxHistory
                        lineColor: "#81C995"
                        fillColor: "#81C995"
                        maxValue: 1024 * 5 // Auto scales or handles 5MB limit
                    }

                    // Center boundary
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.08)
                    }

                    PerformanceGraph {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        history: SystemData.networkTxHistory
                        lineColor: "#FF8A65"
                        fillColor: "#FF8A65"
                        inverted: true
                        maxValue: 1024 * 5
                    }
                }
            }

            // --- DETAILED INTERFACE STATS CARDS ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                // 1. Download Cumulative Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "download"; color: "#81C995"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "CUMULATIVE DOWNLOAD"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: SystemData.lastNetworkStats ? formatTotal(SystemData.lastNetworkStats.rx) : "0 B"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: "white"
                        }
                        
                        StyledText {
                            text: "Active Network Speed: " + formatRate(SystemData.networkRxRate)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Qt.rgba(255, 255, 255, 0.5)
                        }
                    }
                }

                // 2. Upload Cumulative Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "upload"; color: "#FF8A65"; iconSize: 20 * Appearance.effectiveScale }
                            StyledText { text: "CUMULATIVE UPLOAD"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: SystemData.lastNetworkStats ? formatTotal(SystemData.lastNetworkStats.tx) : "0 B"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: "white"
                        }
                        
                        StyledText {
                            text: "Active Network Speed: " + formatRate(SystemData.networkTxRate)
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Qt.rgba(255, 255, 255, 0.5)
                        }
                    }
                }
            }
        }
    }
}
