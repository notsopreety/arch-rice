import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"
import "../services"
import "../core"

RowLayout {
    id: root
    spacing: 10 * Appearance.effectiveScale

    HoverHandler {
        id: mediaHoverHandler
        onHoveredChanged: {
            if (hovered && MprisController.activePlayer) {
                GlobalStates.openMediaNotch(root.QsWindow.window.screen);
            } else {
                GlobalStates.stopMediaNotchTimer();
                GlobalStates.mediaNotchOpen = false;
            }
        }
    }

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
    
    // Disappear only if no media player exists at all (not when paused)
    visible: root.hasPlayer

    // Clickable container for Visualizer + Title Marquee
    Item {
        id: infoClickArea
        width: visualizerRow.implicitWidth
        height: 16 * Appearance.effectiveScale
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            id: visualizerRow
            anchors.fill: parent
            spacing: 8 * Appearance.effectiveScale

            // 1. Vertical Bar Visualizer
            BarAudioVisualizer {
                activePlayer: root.activePlayer
                Layout.alignment: Qt.AlignVCenter
            }

            // 2. Infinitely Animated Title Marquee (R to L)
            Item {
                id: titleContainer
                width: 60 * Appearance.effectiveScale
                height: 16 * Appearance.effectiveScale
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: titleText
                    text: {
                        if (!root.hasPlayer) return "No Media";
                        var title = root.activePlayer.trackTitle || root.activePlayer.title || "Unknown Track";
                        var artist = root.activePlayer.trackArtist || root.activePlayer.artist || "";
                        return artist !== "" ? (title + " - " + artist) : title;
                    }
                    font.family: Theme.font.family
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "white"
                    y: (parent.height - height) / 2

                    // Marquee Infinite Right-to-Left animation
                    NumberAnimation on x {
                        id: marqueeAnim
                        from: titleContainer.width
                        to: -titleText.implicitWidth
                        duration: Math.max(4000, titleText.implicitWidth * 35)
                        loops: Animation.Infinite
                        running: root.hasPlayer
                    }

                    // Restart animation when text changes
                    onTextChanged: {
                        marqueeAnim.restart();
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                DankDashService.activeTab = 1;
                DankDashService.visible = true;
            }
        }
    }

    // 3. Playback Controls: Prev, Play/Pause, Next
    Row {
        spacing: 8 * Appearance.effectiveScale
        Layout.alignment: Qt.AlignVCenter

        // Prev Button
        DankIcon {
            name: "skip_previous"
            size: 12 * Appearance.effectiveScale
            color: "white"
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer) {
                        root.activePlayer.previous();
                    }
                }
            }
        }

        // Play/Pause Button
        DankIcon {
            name: root.isPlaying ? "pause" : "play_arrow"
            size: 12 * Appearance.effectiveScale
            color: Theme.primary
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer) {
                        root.activePlayer.togglePlaying();
                    }
                }
            }
        }

        // Next Button
        DankIcon {
            name: "skip_next"
            size: 12 * Appearance.effectiveScale
            color: "white"
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer) {
                        root.activePlayer.next();
                    }
                }
            }
        }
    }
}
