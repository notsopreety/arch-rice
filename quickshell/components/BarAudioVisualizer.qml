import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"
import "../services"
import "../components"

Item {
    id: root

    property var activePlayer: null
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === 1

    width: 22
    height: 14

    Loader {
        active: true
        sourceComponent: Component {
            Ref {
                service: CavaService
            }
        }
    }

    readonly property real maxBarHeight: 12
    readonly property real minBarHeight: 3
    readonly property real heightRange: maxBarHeight - minBarHeight
    property var barHeights: [minBarHeight, minBarHeight, minBarHeight, minBarHeight, minBarHeight, minBarHeight]

    Timer {
        id: fallbackTimer
        running: !CavaService.cavaAvailable && root.isPlaying
        interval: 300
        repeat: true
        onTriggered: {
            CavaService.values = [Math.random() * 20 + 5, Math.random() * 25 + 8, Math.random() * 22 + 6, Math.random() * 20 + 5, Math.random() * 22 + 6, Math.random() * 25 + 8];
        }
    }

    Connections {
        target: CavaService
        function onValuesChanged() {
            const newHeights = [];
            for (let i = 0; i < 6; i++) {
                if (CavaService.values.length <= i) {
                    newHeights.push(root.minBarHeight);
                    continue;
                }

                const rawLevel = CavaService.values[i];
                if (rawLevel <= 0) {
                    newHeights.push(root.minBarHeight);
                } else if (rawLevel >= 100) {
                    newHeights.push(root.maxBarHeight);
                } else {
                    newHeights.push(root.minBarHeight + Math.sqrt(rawLevel * 0.01) * root.heightRange);
                }
            }
            root.barHeights = newHeights;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 1.5

        Repeater {
            model: 6

            Rectangle {
                width: 2
                height: root.barHeights[index]
                radius: 1
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    enabled: !CavaService.cavaAvailable
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}
