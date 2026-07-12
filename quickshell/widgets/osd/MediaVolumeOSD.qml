import QtQuick
import "../../theme"
import "../../services"
import "../../components"

DankOSD {
    id: root

    readonly property var player: OsdService.activePlayer
    readonly property bool volumeSupported: player?.volumeSupported ?? false
    property int _displayVolume: player ? Math.round(player.volume * 100) : 0

    osdWidth: 260
    osdHeight: 48
    autoHideInterval: 3000
    enableMouseInteraction: true

    Connections {
        target: player
        ignoreUnknownSignals: true
        function onVolumeChanged() {
            if (OsdService.osdMediaPlaybackEnabled && volumeSupported) {
                root._displayVolume = Math.round(player.volume * 100);
                root.show();
            }
        }
    }

    content: Item {
        property int gap: Theme.rounding.small

        anchors.centerIn: parent
        width: parent.width - Theme.rounding.small * 2
        height: parent.height

        Rectangle {
            id: iconRect
            width: 32
            height: 32
            radius: 16
            color: "transparent"
            x: parent.gap
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "music_note"
                size: 20
                color: Theme.primary
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (player) {
                        player.volume = player.volume > 0 ? 0.0 : 1.0;
                    }
                }
                onContainsMouseChanged: setChildHovered(containsMouse || volumeSlider.containsMouse)
            }
        }

        DankSlider {
            id: volumeSlider
            width: parent.width - 32 - parent.gap * 3
            height: parent.height
            x: parent.gap * 2 + 32
            anchors.verticalCenter: parent.verticalCenter
            minimum: 0
            maximum: 100
            enabled: volumeSupported
            showValue: true
            unit: "%"
            thumbOutlineColor: Theme.surfaceContainer
            valueOverride: root._displayVolume
            alwaysShowValue: OsdService.osdAlwaysShowValue

            Component.onCompleted: {
                value = root._displayVolume;
            }

            onSliderValueChanged: newValue => {
                if (player) {
                    player.volume = newValue / 100.0;
                }
                resetHideTimer();
            }

            onContainsMouseChanged: setChildHovered(containsMouse || iconRect.visible)

            Binding on value {
                value: root._displayVolume
                when: !volumeSlider.isDragging
            }
        }
    }
}
