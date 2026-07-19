import QtQuick
import Quickshell
import "../theme"
import "../core"

Card {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: 0 * Appearance.effectiveScale

        Column {
            spacing: -8 * Appearance.effectiveScale
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                spacing: 0 * Appearance.effectiveScale
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: {
                        const hours = systemClock.date ? systemClock.date.getHours() : 12;
                        const display = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
                        return String(display).padStart(2, '0').charAt(0);
                    }
                    font.family: Theme.font.family
                    font.pixelSize: 42 * Appearance.effectiveScale
                    color: Theme.primary
                    font.weight: Font.Medium
                    width: 26 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: {
                        const hours = systemClock.date ? systemClock.date.getHours() : 12;
                        const display = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
                        return String(display).padStart(2, '0').charAt(1);
                    }
                    font.family: Theme.font.family
                    font.pixelSize: 42 * Appearance.effectiveScale
                    color: Theme.primary
                    font.weight: Font.Medium
                    width: 26 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Row {
                spacing: 0 * Appearance.effectiveScale
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: systemClock.date ? String(systemClock.date.getMinutes()).padStart(2, '0').charAt(0) : "0"
                    font.family: Theme.font.family
                    font.pixelSize: 42 * Appearance.effectiveScale
                    color: Theme.primary
                    font.weight: Font.Medium
                    width: 26 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    text: systemClock.date ? String(systemClock.date.getMinutes()).padStart(2, '0').charAt(1) : "0"
                    font.family: Theme.font.family
                    font.pixelSize: 42 * Appearance.effectiveScale
                    color: Theme.primary
                    font.weight: Font.Medium
                    width: 26 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Item {
            width: 1 * Appearance.effectiveScale
            height: 8 * Appearance.effectiveScale
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: systemClock.date ? systemClock.date.toLocaleDateString(Qt.locale(), "MMM dd") : ""
            font.family: Theme.font.family
            font.pixelSize: 12 * Appearance.effectiveScale
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }
}
