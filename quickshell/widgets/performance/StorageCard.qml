import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../../components"
import "../"

Card {
    id: root

    readonly property color accent: Theme.secondary

    implicitWidth: 220
    implicitHeight: 200

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 12

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignLeft

            DankIcon {
                name: "storage"
                size: 18
                color: root.accent
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Storage"
                font.family: Theme.font.family
                font.pixelSize: 14
                font.weight: Font.Bold
                color: "white"
            }
        }

        // Circular Gauge
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                property real value: SystemUsage.diskPerc

                onValueChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var centreX = width / 2;
                    var centreY = height / 2;
                    var radius = Math.min(width, height) / 2 - 8;

                    // Draw background track
                    ctx.beginPath();
                    ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.08);
                    ctx.lineWidth = 6;
                    ctx.arc(centreX, centreY, radius, 0, 2 * Math.PI);
                    ctx.stroke();

                    // Draw progress fill
                    ctx.beginPath();
                    ctx.strokeStyle = root.accent;
                    ctx.lineWidth = 6;
                    ctx.lineCap = "round";
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle + (Math.min(Math.max(canvas.value, 0.0), 1.0) * 2 * Math.PI);
                    ctx.arc(centreX, centreY, radius, startAngle, endAngle);
                    ctx.stroke();
                }

                Behavior on value {
                    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    text: Math.round(SystemUsage.diskPerc * 100) + "%"
                    font.family: Theme.font.family
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: root.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Used"
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    color: Qt.rgba(255, 255, 255, 0.6)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // GB formatted values
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                var usedGB = SystemUsage.diskUsed / (1024 * 1024 * 1024);
                var totalGB = SystemUsage.diskTotal / (1024 * 1024 * 1024);
                return usedGB.toFixed(1) + " / " + Math.round(totalGB) + " GB";
            }
            font.family: Theme.font.family
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "white"
        }
    }
}
