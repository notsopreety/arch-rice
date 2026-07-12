import QtQuick
import Quickshell.Services.Mpris
import "../theme"
import "../components"

Card {
    id: root
    clip: true

    signal clicked

    readonly property var internalState: ({ lastPlayerDbusName: "" })
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;

        let p = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        if (p) return p;

        if (internalState.lastPlayerDbusName !== "") {
            p = players.find(p => p.dbusName === internalState.lastPlayerDbusName);
            if (p && (p.playbackState === MprisPlaybackState.Playing || p.playbackState === MprisPlaybackState.Paused)) return p;
        }

        p = players.find(p => p.playbackState === MprisPlaybackState.Paused);
        if (p) return p;

        return null;
    }
    onActivePlayerChanged: {
        if (activePlayer && activePlayer.dbusName) {
            internalState.lastPlayerDbusName = activePlayer.dbusName;
        }
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.playbackState === 1

    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: !root.hasPlayer

        Text {
            text: "󰎆"
            font.family: Theme.font.monospace
            font.pixelSize: 24
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "No Media"
            font.family: Theme.font.family
            font.pixelSize: 11
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: 6
        visible: root.hasPlayer

        // Art and Titles wrapped in MouseArea to switch tabs
        MouseArea {
            width: parent.width
            height: 104 // Height of Art (72) + Spacing (6) + Text block (26)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()

            Column {
                anchors.fill: parent
                spacing: 6

                Item {
                    width: 72
                    height: 72
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: false

                    DankAlbumArt {
                        anchors.fill: parent
                        activePlayer: root.activePlayer
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Text {
                        text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown") : ""
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "white"
                        width: parent.width
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        text: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
                        font.family: Theme.font.family
                        font.pixelSize: 9
                        color: "#e7bdb3"
                        width: parent.width
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Item {
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: 18

            MediaSeekBar {
                anchors.fill: parent
                activePlayer: root.activePlayer
                fillColor: Theme.primary
                textColor: "white"
            }
        }

        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "󰒮"
                font.family: Theme.font.monospace
                font.pixelSize: 14
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.activePlayer) root.activePlayer.previous()
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: Theme.primary

                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: Theme.font.monospace
                    font.pixelSize: 14
                    color: Theme.background
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                }
            }

            Text {
                text: "󰒭"
                font.family: Theme.font.monospace
                font.pixelSize: 14
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.activePlayer) root.activePlayer.next()
                }
            }
        }
    }

    AnimatedImage {
        id: bongocat
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -16
        width: parent.width + 12
        height: 130
        playing: root.isPlaying
        speed: 0.35 // Slow down the default animation speed further
        source: "file:///home/sawmer/.config/quickshell/assets/bongocat.gif"
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
        opacity: root.hasPlayer ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }
}
