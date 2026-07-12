import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../../components"
import "../"

Card {
    id: root

    readonly property color dlColor: Theme.primary
    readonly property color ulColor: Theme.tertiary

    implicitWidth: 260
    implicitHeight: 200

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec >= 1024 * 1024) {
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        } else if (bytesPerSec >= 1024) {
            return (bytesPerSec / 1024).toFixed(1) + " KB/s";
        }
        return Math.round(bytesPerSec) + " B/s";
    }

    function formatShortSpeed(bytesPerSec) {
        var bitsPerSec = bytesPerSec * 8;
        if (bitsPerSec >= 1000 * 1000 * 1000) {
            return (bitsPerSec / (1000 * 1000 * 1000)).toFixed(0) + "g";
        } else if (bitsPerSec >= 1000 * 1000) {
            return (bitsPerSec / (1000 * 1000)).toFixed(0) + "m";
        } else if (bitsPerSec >= 1000) {
            return (bitsPerSec / 1000).toFixed(0) + "k";
        }
        return bitsPerSec + "b";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignLeft

            DankIcon {
                name: "router"
                size: 18
                color: dlColor
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Network"
                font.family: Theme.font.family
                font.pixelSize: 14
                font.weight: Font.Bold
                color: "white"
            }
        }

        // Sparkline Graph
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Canvas {
                id: graph
                anchors.fill: parent
                antialiasing: true

                // Trigger repaint whenever history changes
                Connections {
                    target: SystemUsage
                    ignoreUnknownSignals: true
                    function onNetworkHistoryChanged() {
                        graph.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var history = SystemUsage.networkHistory;
                    if (!history || history.length < 2) return;

                    var w = width;
                    var h = height;

                    // Find max value for scaling
                    var maxVal = 25000000; // default 200 Mbps (25,000,000 B/s) scale limit
                    for (var i = 0; i < history.length; i++) {
                        if (history[i].download > maxVal) maxVal = history[i].download;
                        if (history[i].upload > maxVal) maxVal = history[i].upload;
                    }

                    // Draw subtle background grid
                    ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.05);
                    ctx.lineWidth = 1;
                    
                    // Horizontal grid lines (20%, 40%, 60%, 80%)
                    for (var yLine = 1; yLine < 5; yLine++) {
                        var gy = (h * yLine) / 5;
                        ctx.beginPath();
                        ctx.moveTo(0, gy);
                        ctx.lineTo(w, gy);
                        ctx.stroke();
                    }

                    // Vertical grid lines
                    for (var xLine = 1; xLine < 4; xLine++) {
                        var gx = (w * xLine) / 4;
                        ctx.beginPath();
                        ctx.moveTo(gx, 0);
                        ctx.lineTo(gx, h);
                        ctx.stroke();
                    }

                    // Draw grid text labels
                    ctx.fillStyle = Qt.rgba(255, 255, 255, 0.3);
                    ctx.font = "8px sans-serif";
                    ctx.textBaseline = "middle";
                    ctx.textAlign = "left";
                    ctx.fillText(root.formatShortSpeed(maxVal), 4, 6);
                    ctx.fillText(root.formatShortSpeed(maxVal * 0.8), 4, h * 1 / 5);
                    ctx.fillText(root.formatShortSpeed(maxVal * 0.6), 4, h * 2 / 5);
                    ctx.fillText(root.formatShortSpeed(maxVal * 0.4), 4, h * 3 / 5);
                    ctx.fillText(root.formatShortSpeed(maxVal * 0.2), 4, h * 4 / 5);
                    ctx.fillText("0b", 4, h - 6);

                    var stepX = w / (history.length - 1);

                    // Draw Download Graph
                    ctx.beginPath();
                    ctx.strokeStyle = root.dlColor;
                    ctx.lineWidth = 2;
                    for (var d = 0; d < history.length; d++) {
                        var dx = d * stepX;
                        var dy = h - ((history[d].download / maxVal) * (h - 4)) - 2;
                        if (d === 0) ctx.moveTo(dx, dy);
                        else ctx.lineTo(dx, dy);
                    }
                    ctx.stroke();

                    // Fill Download area
                    ctx.lineTo(w, h);
                    ctx.lineTo(0, h);
                    ctx.closePath();
                    ctx.fillStyle = Qt.rgba(root.dlColor.r, root.dlColor.g, root.dlColor.b, 0.1);
                    ctx.fill();

                    // Draw Upload Graph
                    ctx.beginPath();
                    ctx.strokeStyle = root.ulColor;
                    ctx.lineWidth = 1.5;
                    for (var u = 0; u < history.length; u++) {
                        var ux = u * stepX;
                        var uy = h - ((history[u].upload / maxVal) * (h - 4)) - 2;
                        if (u === 0) ctx.moveTo(ux, uy);
                        else ctx.lineTo(ux, uy);
                    }
                    ctx.stroke();
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Collecting data..."
                font.family: Theme.font.family
                font.pixelSize: 11
                color: Qt.rgba(255, 255, 255, 0.4)
                visible: !SystemUsage.networkHistory || SystemUsage.networkHistory.length < 2
            }
        }

        // Values at bottom
        Column {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                width: parent.width

                Row {
                    spacing: 4
                    DankIcon {
                        name: "arrow_downward"
                        size: 12
                        color: root.dlColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { text: "Down"; font.family: Theme.font.family; font.pixelSize: 11; color: Qt.rgba(255, 255, 255, 0.6); anchors.verticalCenter: parent.verticalCenter }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatSpeed(SystemUsage.downloadSpeed)
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "white"
                }
            }

            RowLayout {
                width: parent.width

                Row {
                    spacing: 4
                    DankIcon {
                        name: "arrow_upward"
                        size: 12
                        color: root.ulColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text { text: "Up"; font.family: Theme.font.family; font.pixelSize: 11; color: Qt.rgba(255, 255, 255, 0.6); anchors.verticalCenter: parent.verticalCenter }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatSpeed(SystemUsage.uploadSpeed)
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "white"
                }
            }
        }
    }
}
