import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../../theme"
import "../../services"
import "../../components"

DankOSD {
    id: root

    readonly property bool useVertical: isVerticalLayout
    readonly property var player: OsdService.activePlayer
    readonly property string artUrl: player ? (player.trackArtUrl || player.artUrl || "") : ""

    osdWidth: useVertical ? (40 + Theme.rounding.small * 2) : Math.min(280, Screen.width - Theme.rounding.normal * 2)
    osdHeight: useVertical ? 64 : (40 + Theme.rounding.small * 2)
    autoHideInterval: 3000
    enableMouseInteraction: true

    property string _displayIcon: "music_note"

    function updatePlaybackIcon() {
        if (!player) {
            _displayIcon = "music_note";
            return;
        }
        switch (player.playbackState) {
            case MprisPlaybackState.Playing:
                _displayIcon = "pause";
                break;
            case MprisPlaybackState.Paused:
            case MprisPlaybackState.Stopped:
                _displayIcon = "play_arrow";
                break;
            default:
                _displayIcon = "music_note";
        }
    }

    function togglePlaying() {
        if (player?.canTogglePlaying) {
            player.togglePlaying();
        }
    }

    Connections {
        target: OsdService
        function onMediaPlaybackTriggered() {
            if (OsdService.osdMediaPlaybackEnabled) {
                root.updatePlaybackIcon();
                root.show();
            }
        }
    }

    content: Loader {
        anchors.fill: parent
        sourceComponent: useVertical ? verticalContent : horizontalContent
    }

    Component {
        id: horizontalContent

        Item {
            property int gap: Theme.rounding.small

            anchors.centerIn: parent
            width: parent.width - Theme.rounding.small * 2
            height: 40

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Item {
                id: bgContainer
                anchors.fill: parent
                visible: root.artUrl !== ""

                Image {
                    id: bgImage
                    anchors.centerIn: parent
                    width: Math.max(parent.width, parent.height)
                    height: width
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                }

                Item {
                    id: blurredBg
                    anchors.fill: parent
                    visible: false

                    MultiEffect {
                        anchors.centerIn: parent
                        width: bgImage.width
                        height: bgImage.height
                        source: bgImage
                        blurEnabled: true
                        blurMax: 64
                        blur: 0.3
                        saturation: -0.2
                        brightness: -0.25
                    }
                }

                Rectangle {
                    id: bgMask
                    anchors.fill: parent
                    radius: Theme.rounding.large
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: blurredBg
                    maskEnabled: true
                    maskSource: bgMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    opacity: 0.7
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding.large
                    color: Theme.surfaceContainer
                    opacity: 0.3
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                x: parent.gap
                anchors.verticalCenter: parent.verticalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: root._displayIcon
                    size: 20
                    color: playPauseButton.containsMouse ? Theme.primary : Theme.primary
                }

                MouseArea {
                    id: playPauseButton

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        togglePlaying();
                        root.hide();
                    }
                }
            }

            Column {
                x: parent.gap * 2 + 24
                width: parent.width - 24 - parent.gap * 3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                StyledText {
                    id: topText
                    width: parent.width
                    text: player ? (player.trackTitle || "Unknown Title") : ""
                    font.pixelSize: Theme.font.sizeNormal
                    font.weight: Font.Medium
                    color: Theme.primary
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    id: bottomText
                    width: parent.width
                    text: player ? ((player.trackArtist || "Unknown Artist") + (player.trackAlbum ? ` • ${player.trackAlbum}` : "")) : ""
                    font.pixelSize: Theme.font.sizeSmall
                    font.weight: Font.Light
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7)
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }
        }
    }

    Component {
        id: verticalContent

        Item {
            property int gap: Theme.rounding.small

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                anchors.centerIn: parent
                y: gap

                DankIcon {
                    anchors.centerIn: parent
                    name: root._displayIcon
                    size: 20
                    color: playPauseButtonVert.containsMouse ? Theme.primary : Theme.primary
                }

                MouseArea {
                    id: playPauseButtonVert

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        togglePlaying();
                        root.hide();
                    }
                }
            }
        }
    }
}
