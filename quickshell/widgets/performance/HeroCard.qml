import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../services"
import "../../components"
import "../../core"
import "../"

Card {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage // 0 to 1
    required property real temperature

    implicitWidth: 340
    implicitHeight: 180

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 16

        // Left Side: Circular Canvas Meter
        Item {
            id: circularProgress
            width: 100
            height: 100
            Layout.alignment: Qt.AlignVCenter

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                property real value: root.usage

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
                    // Arc starts from top (-Math.PI/2)
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle + (Math.min(Math.max(canvas.value, 0.0), 1.0) * 2 * Math.PI);
                    ctx.arc(centreX, centreY, radius, startAngle, endAngle);
                    ctx.stroke();
                }

                Behavior on value {
                    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                }
            }

            // Text / Icon in center of the gauge
            Column {
                anchors.centerIn: parent
                spacing: 2

                DankIcon {
                    name: root.icon
                    size: 20
                    color: root.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: Math.round(root.usage * 100) + "%"
                    font.family: Theme.font.family
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // Right Side: Info details (Name, Usage description, Temp bar)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.label === "CPU" ? SystemUsage.cpuModel : root.label
                    font.family: Theme.font.family
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: root.accent
                    elide: Text.ElideRight
                    width: 250
                }

                Text {
                    text: root.label === "CPU" 
                        ? `${SystemUsage.cpuCores} Cores / ${SystemUsage.cpuThreads} Threads | Freq: ${SystemUsage.cpuFreq}`
                        : root.subLabel
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    color: Qt.rgba(255, 255, 255, 0.6)
                    elide: Text.ElideRight
                    width: 250
                }
            }

            // Temperature Details & Graph Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Column {
                    Layout.preferredWidth: 140
                    spacing: 4

                    RowLayout {
                        width: parent.width
                        
                        DankIcon {
                            name: "thermostat"
                            size: 16
                            color: root.temperature > 80 ? "#ffb4ab" : root.accent
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: isNaN(root.temperature) || root.temperature <= 0 ? "N/A" : Math.round(root.temperature) + "°C"
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "white"
                        }
                    }

                    // Temp progress bar
                    Rectangle {
                        width: 130
                        height: 6
                        radius: 3
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            width: isNaN(root.temperature) || root.temperature <= 0 ? 0 : Math.min(1.0, root.temperature / 100.0) * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: root.temperature > 80 ? "#ffb4ab" : root.accent

                            Behavior on width {
                                NumberAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // CPU History Graph
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    visible: root.label === "CPU"

                    Canvas {
                        id: cpuGraph
                        anchors.fill: parent
                        antialiasing: true

                        Connections {
                            target: SystemUsage
                            ignoreUnknownSignals: true
                            function onCpuHistoryChanged() {
                                cpuGraph.requestPaint();
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            var history = SystemUsage.cpuHistory;
                            if (!history || history.length < 2) return;

                            var w = width;
                            var h = height;

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
                            ctx.fillText("100%", 4, 6);
                            ctx.fillText("80%", 4, h * 1 / 5);
                            ctx.fillText("60%", 4, h * 2 / 5);
                            ctx.fillText("40%", 4, h * 3 / 5);
                            ctx.fillText("20%", 4, h * 4 / 5);
                            ctx.fillText("0%", 4, h - 6);

                            var stepX = w / (history.length - 1);

                            // Draw sparkline path
                            ctx.beginPath();
                            ctx.strokeStyle = root.accent;
                            ctx.lineWidth = 2;
                            for (var i = 0; i < history.length; i++) {
                                var x = i * stepX;
                                var y = h - (history[i] * (h - 4)) - 2;
                                if (i === 0) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.stroke();

                            // Fill area under sparkline with a vertical gradient
                            ctx.lineTo(w, h);
                            ctx.lineTo(0, h);
                            ctx.closePath();
                            
                            var grad = ctx.createLinearGradient(0, 0, 0, h);
                            grad.addColorStop(0, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25));
                            grad.addColorStop(1, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.0));
                            ctx.fillStyle = grad;
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }

    // "View More" link button on the top-right
    Item {
        id: viewMoreLink
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 12
        anchors.rightMargin: 12
        width: contentRow.width
        height: contentRow.height

        Row {
            id: contentRow
            spacing: 4

            Text {
                text: "View More"
                font.family: Theme.font.family
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: linkMouseArea.containsMouse ? root.accent : Qt.rgba(255, 255, 255, 0.7)
                font.underline: linkMouseArea.containsMouse
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            DankIcon {
                name: "arrow_forward"
                size: 14
                color: linkMouseArea.containsMouse ? root.accent : Qt.rgba(255, 255, 255, 0.7)
                anchors.verticalCenter: parent.verticalCenter
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        
        MouseArea {
            id: linkMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                DankDashService.close();
                GlobalStates.activateSystemMonitor();
            }
        }
    }
}
