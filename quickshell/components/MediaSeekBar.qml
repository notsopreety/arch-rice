import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../theme"

Item {
    id: root
    property var activePlayer: null

    readonly property real duration: activePlayer ? (activePlayer.length || 0) : 0
    property real seekRatio: 0
    property bool isSeeking: false

    // Polled position — MPRIS doesn't emit continuous positionChanged signals
    property real _currentPosition: 0
    Timer {
        interval: 200
        running: !!root.activePlayer
        repeat: true
        onTriggered: {
            if (root.activePlayer) {
                root._currentPosition = root.activePlayer.position || 0;
            }
        }
    }
    onActivePlayerChanged: {
        if (activePlayer) _currentPosition = activePlayer.position || 0;
    }

    readonly property real progressRatio: {
        if (isSeeking) return seekRatio;
        if (!activePlayer || duration <= 0) return 0;
        return Math.max(0, Math.min(1, _currentPosition / duration));
    }

    readonly property real displayPosition: {
        if (isSeeking) return seekRatio * duration;
        return _currentPosition;
    }

    // Colors mapped directly to M3 Theme
    property color fillColor: Theme.primary
    property color trackColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
    property color textColor: Theme.outline

    implicitHeight: 28
    Layout.fillWidth: true

    onProgressRatioChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 14

            Canvas {
                id: canvas
                anchors.fill: parent
                antialiasing: true

                property real phase: 0

                Timer {
                    interval: 16
                    running: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing
                    repeat: true
                    onTriggered: {
                        canvas.phase += 0.05
                        canvas.requestPaint()
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var midY = height / 2;
                    var playheadX = width * root.progressRatio;

                    // 1. Played wavy segment
                    ctx.beginPath();
                    ctx.strokeStyle = root.fillColor;
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";

                    var isPlaying = root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing;
                    var amp = isPlaying ? 2.2 : 0;
                    var wavelength = 20;

                    ctx.moveTo(0, midY);
                    for (var x = 0; x <= playheadX; x += 2) {
                        var y = midY + Math.sin((x / wavelength) * 2 * Math.PI + phase) * amp;
                        ctx.lineTo(x, y);
                    }
                    ctx.stroke();

                    // 2. Unplayed flat segment
                    ctx.beginPath();
                    ctx.strokeStyle = root.trackColor;
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round";
                    ctx.moveTo(playheadX, midY);
                    ctx.lineTo(width, midY);
                    ctx.stroke();
                }
            }

            // Playhead Pill
            Rectangle {
                id: playhead
                width: 4
                height: 12
                radius: 2
                color: root.fillColor
                x: Math.max(0, Math.min(parent.width - width, parent.width * root.progressRatio - width / 2))
                anchors.verticalCenter: parent.verticalCenter
            }

            // Click / Drag MouseArea
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function updateSeek(mouse) {
                    root.seekRatio = Math.max(0, Math.min(1, mouse.x / width));
                }

                onPressed: (mouse) => {
                    root.isSeeking = true;
                    updateSeek(mouse);
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        updateSeek(mouse);
                    }
                }
                onReleased: (mouse) => {
                    if (root.isSeeking) {
                        updateSeek(mouse);
                        root.isSeeking = false;
                        if (root.activePlayer && root.activePlayer.canSeek) {
                            root.activePlayer.position = root.seekRatio * root.duration;
                        }
                    }
                }
                onCanceled: {
                    root.isSeeking = false;
                }
            }
        }

        // Time labels
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 12

            Text {
                text: root.formatTime(root.displayPosition)
                font.family: Theme.font.family
                font.pixelSize: 10
                color: root.textColor
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.formatTime(root.duration)
                font.family: Theme.font.family
                font.pixelSize: 10
                color: root.textColor
            }
        }
    }

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        const minutes = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return minutes + ":" + (secs < 10 ? "0" : "") + secs;
    }
}
