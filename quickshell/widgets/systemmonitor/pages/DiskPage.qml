import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."
import "../../../theme"

/**
 * Disk detail page for System Monitor with premium layout and micro-metrics.
 */
Item {
    id: root

    function formatRate(bytesPerSec) {
        if (bytesPerSec < 1024) return Math.round(bytesPerSec) + " B/s";
        let kb = bytesPerSec / 1024;
        if (kb < 1024) return kb.toFixed(1) + " KB/s";
        let mb = kb / 1024;
        return mb.toFixed(2) + " MB/s";
    }

    function formatSize(mbValue) {
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
                text: "Disk Performance"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            // Real-time Disk I/O Cards
            RowLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale

                // 1. Read Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "downloading"; color: "#81C995"; iconSize: 22 * Appearance.effectiveScale }
                            StyledText { text: "DISK READ SPEED"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: formatRate(SystemData.diskReadRate)
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Black
                            color: "white"
                        }
                    }
                }

                // 2. Write Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    radius: 16 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol { text: "upload_file"; color: "#FF8A65"; iconSize: 22 * Appearance.effectiveScale }
                            StyledText { text: "DISK WRITE SPEED"; font.pixelSize: Appearance.font.pixelSize.smaller; font.weight: Font.DemiBold; color: "white" }
                            Item { Layout.fillWidth: true }
                        }

                        StyledText {
                            text: formatRate(SystemData.diskWriteRate)
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Black
                            color: "white"
                        }
                    }
                }
            }

            StyledText {
                text: "Mounted Filesystems"
                Layout.topMargin: 12 * Appearance.effectiveScale
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: Theme.primary
            }

            // Monitors each disk in the list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 24 * Appearance.effectiveScale

                Repeater {
                    model: SystemData.diskStats
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer2
                        radius: 16 * Appearance.effectiveScale

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8 * Appearance.effectiveScale
                                MaterialSymbol {
                                    text: "dns"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: Theme.primary
                                }
                                StyledText {
                                    text: modelData.hasAlias ? `${modelData.label.toUpperCase()} (${modelData.path})` : `MOUNT: ${modelData.path}`
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: `${Math.round(modelData.usage * 100)}% USED`
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.DemiBold
                                    color: {
                                        if (modelData.usage > 0.85) return "#FF8A80";
                                        if (modelData.usage > 0.60) return "#FFD54F";
                                        return "#81C995";
                                    }
                                }
                            }

                            // Large Graded Disk Progress Bar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8 * Appearance.effectiveScale
                                radius: 4 * Appearance.effectiveScale
                                color: Qt.rgba(255, 255, 255, 0.06)
                                clip: true

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, modelData.usage))
                                    height: parent.height
                                    radius: 4 * Appearance.effectiveScale
                                    color: {
                                        if (modelData.usage > 0.85) return "#FF8A80";
                                        if (modelData.usage > 0.60) return "#FFD54F";
                                        return "#81C995";
                                    }
                                    visible: modelData.usage > 0

                                    Behavior on width {
                                        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                StyledText {
                                    text: "Available: " + formatSize(modelData.total - modelData.used)
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Qt.rgba(255, 255, 255, 0.5)
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: formatSize(modelData.used) + " / " + formatSize(modelData.total)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    font.weight: Font.Medium
                                    color: "white"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
