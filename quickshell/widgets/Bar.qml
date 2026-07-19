import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../components"
import "../components/bar" as BarComponents
import "../services"
import "../core"
import QtCore

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    FontLoader {
        id: nerdFontLoader
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf"
    }

    implicitHeight: Styling.barHeight * Appearance.effectiveScale
    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: GlobalSettings.floatingBar ? -1 : (GlobalSettings.autoHideBar && !barHover.hovered ? 0 : implicitHeight)

    HoverHandler { id: barHover }
    property int topMarginOffset: (GlobalSettings.autoHideBar && !barHover.hovered) ? -implicitHeight + 2 : 0
    Behavior on topMarginOffset {
        NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
    }
    WlrLayershell.margins.top: topMarginOffset

    // Main bar container (completely transparent, hosting floating pills)
    Item {
        id: barContainer
        anchors.fill: parent
        anchors.leftMargin: 12 * Appearance.effectiveScale
        anchors.rightMargin: 12 * Appearance.effectiveScale
        anchors.topMargin: 4 * Appearance.effectiveScale
        anchors.bottomMargin: 4 * Appearance.effectiveScale

        // ── Glassmorphism toggle (reads ~/.config/hypr/.glassmorphism_enabled) ──
        property bool glassmorphism: false

        FileView {
            id: glassmorphismFlagFile
            path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
            watchChanges: true
            onFileChanged: glassmorphismReloadTimer.restart()
            Component.onCompleted: {
                try { glassmorphismFlagFile.reload(); barContainer.glassmorphism = true; } catch(e) { barContainer.glassmorphism = false; }
            }
            onLoaded: barContainer.glassmorphism = true
            onLoadFailed: barContainer.glassmorphism = false
        }
        Timer {
            id: glassmorphismReloadTimer
            interval: 200; repeat: false
            onTriggered: {
                try { glassmorphismFlagFile.reload(); } catch(e) {}
            }
        }

        // Glassmorphic color helpers
        readonly property color pillColor: glassmorphism
            ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.45)
            : Theme.surfaceContainerHigh
        readonly property color pillBorder: glassmorphism
            ? Qt.rgba(1, 1, 1, 0.18)
            : Theme.outlineVariant
        readonly property real pillOpacity: glassmorphism ? 1.0 : 0.95

        // LEFT MODULE: OS Icon + Workspaces
        Rectangle {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: leftLayout.implicitWidth + 24 * Appearance.effectiveScale
            radius: height / 2
            color: barContainer.pillColor
            opacity: barContainer.pillOpacity
            border.color: barContainer.pillBorder
            border.width: 1
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on border.color { ColorAnimation { duration: 400 } }

            // Glassmorphic gloss overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: barContainer.glassmorphism
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
                border.color: "transparent"
            }

            RowLayout {
                id: leftLayout
                anchors.centerIn: parent
                spacing: 12 * Appearance.effectiveScale

                // OS Icon (Arch Linux logo)
                Text {
                    text: ""
                    font.family: nerdFontLoader.name
                    font.pixelSize: 16 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.alignment: Qt.AlignVCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            LauncherService.toggle();
                        }
                    }
                }

                // Vertical separator
                Rectangle {
                    width: 1
                    height: 14 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                }

                // Workspaces switcher UI
                Workspaces {
                    id: workspaces
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // SEPARATE CPU & MEMORY SYSTEM MONITOR PILL (floating left, next to leftPill)
        Rectangle {
            id: sysMonitorPill
            anchors.left: leftPill.right
            anchors.leftMargin: 6 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: sysMonitorLayout.implicitWidth + 20 * Appearance.effectiveScale
            radius: height / 2
            color: barContainer.pillColor
            opacity: barContainer.pillOpacity
            border.color: barContainer.pillBorder
            border.width: 1
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on border.color { ColorAnimation { duration: 400 } }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: barContainer.glassmorphism
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
                border.color: "transparent"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    Quickshell.execDetached(["quickshell", "ipc", "call", "quickshell", "run", "performance"]);
                }

                RowLayout {
                    id: sysMonitorLayout
                    anchors.centerIn: parent
                    spacing: 10 * Appearance.effectiveScale

                    // Dynamic colors based on usage intensity
                    readonly property color cpuColor: SystemUsage.cpuPerc > 0.8 ? "#ffb4ab" : SystemUsage.cpuPerc > 0.5 ? "#dac58c" : Theme.primary
                    readonly property color memColor: SystemUsage.memPerc > 0.85 ? "#ffb4ab" : SystemUsage.memPerc > 0.65 ? "#dac58c" : Theme.secondary

                    Row {
                        spacing: 4 * Appearance.effectiveScale
                        DankIcon {
                            name: "developer_board"
                            size: 12 * Appearance.effectiveScale
                            color: sysMonitorLayout.cpuColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.cpuPerc * 100) + "%"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: sysMonitorLayout.cpuColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4 * Appearance.effectiveScale
                        DankIcon {
                            name: "thermostat"
                            size: 12 * Appearance.effectiveScale
                            color: SystemUsage.cpuTemp > 85 ? "#ffb4ab" : SystemUsage.cpuTemp > 70 ? "#dac58c" : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.cpuTemp) + "°C"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: SystemUsage.cpuTemp > 85 ? "#ffb4ab" : SystemUsage.cpuTemp > 70 ? "#dac58c" : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4 * Appearance.effectiveScale
                        DankIcon {
                            name: "memory"
                            size: 12 * Appearance.effectiveScale
                            color: sysMonitorLayout.memColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.memPerc * 100) + "%"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            color: sysMonitorLayout.memColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // CENTER MODULE: Media Player + Time & Day + Weather/Temperature
            Rectangle {
                id: centerPill
                property bool showLyricsMode: false
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: showLyricsMode ? Math.min(Math.max(400 * Appearance.effectiveScale, lyricsIsland.maxTextWidth + 60 * Appearance.effectiveScale), parent.width > 0 ? parent.width - 600 * Appearance.effectiveScale : 1000) : centerLayout.implicitWidth + 24 * Appearance.effectiveScale
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                radius: height / 2
                color: barContainer.pillColor
                opacity: barContainer.pillOpacity
                border.color: barContainer.pillBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: barContainer.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                        GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    border.color: "transparent"
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            if (barMediaPlayer.hasPlayer) {
                                centerPill.showLyricsMode = !centerPill.showLyricsMode
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            DankDashService.activeTab = 1
                            DankDashService.visible = true
                        }
                    }
                }

                Connections {
                    target: barMediaPlayer
                    function onHasPlayerChanged() {
                        if (!barMediaPlayer.hasPlayer) {
                            noPlayerTimer.restart()
                        } else {
                            noPlayerTimer.stop()
                        }
                    }
                }

                Timer {
                    id: noPlayerTimer
                    interval: 2000
                    repeat: false
                    onTriggered: {
                        // Only close after 2s of confirmed no player
                        if (!barMediaPlayer.hasPlayer && centerPill.showLyricsMode) {
                            centerPill.showLyricsMode = false
                        }
                    }
                }

                Rectangle {
                    id: centerPillMask
                    anchors.fill: parent
                    radius: centerPill.radius
                    color: "black"
                    visible: false
                }

                WaveVisualizer {
                    id: oceanWave
                    anchors.fill: parent
                    waveColor: Theme.primary
                    active: barMediaPlayer.isPlaying
                    visible: barMediaPlayer.isPlaying
                    waveYPercent: 0.6
                    maskSource: centerPillMask
                    opacity: 0.15
                }

            RowLayout {
                id: centerLayout
                visible: !centerPill.showLyricsMode
                anchors.centerIn: parent
                spacing: 12 * Appearance.effectiveScale

                BarMediaPlayer {
                    id: barMediaPlayer
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    width: 1
                    height: 14 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                    visible: barMediaPlayer.visible
                }

                MouseArea {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: barClock.implicitWidth
                    implicitHeight: barClock.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    BarClock {
                        id: barClock
                        anchors.fill: parent
                    }

                    onClicked: {
                        Quickshell.execDetached(["quickshell", "ipc", "call", "quickshell", "run", "overview"]);
                    }
                }

                Rectangle {
                    width: 1
                    height: 14 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                }

                MouseArea {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: barWeather.implicitWidth
                    implicitHeight: barWeather.implicitHeight
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    BarWeather {
                        id: barWeather
                        anchors.fill: parent
                    }

                    onClicked: {
                        Quickshell.execDetached(["quickshell", "ipc", "call", "quickshell", "run", "weather"]);
                    }
                }

                // Divider line for Alarm Indicator
                Rectangle {
                    width: 1
                    height: 14 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                    visible: alarmIndicator.visible
                }

                // Alarm Ringing Indicator
                MouseArea {
                    id: alarmIndicator
                    Layout.alignment: Qt.AlignVCenter
                    visible: TimerStopwatchService.alarmActive
                    
                    implicitWidth: alarmIndicatorRow.implicitWidth + 12 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 12 * Appearance.effectiveScale
                        color: alarmFlashTimer.flashState ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                        border.color: Theme.error
                        border.width: 1
                        
                        Timer {
                            id: alarmFlashTimer
                            interval: 500
                            running: TimerStopwatchService.alarmActive
                            repeat: true
                            property bool flashState: false
                            onTriggered: flashState = !flashState
                        }
                    }

                    RowLayout {
                        id: alarmIndicatorRow
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: "alarm"
                            size: 13 * Appearance.effectiveScale
                            color: Theme.error
                            
                            RotationAnimator on rotation {
                                from: -10
                                to: 10
                                duration: 150
                                running: TimerStopwatchService.alarmActive
                                loops: Animation.Infinite
                            }
                        }

                        Text {
                            text: "Dismiss: " + TimerStopwatchService.activeAlarmLabel
                            font.family: "Inter"
                            font.pixelSize: 10 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "white"
                        }
                    }

                    onClicked: {
                        TimerStopwatchService.dismissAlarm();
                    }
                }

                // Divider line for Timer/Stopwatch
                Rectangle {
                    id: tsDivider
                    width: 1
                    height: 14 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                    visible: timerWidget.visible || stopwatchWidget.visible
                }

                // Timer Widget
                Row {
                    id: timerWidget
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4 * Appearance.effectiveScale
                    visible: !TimerStopwatchService.timerSetupMode

                    DankIcon {
                        name: "hourglass"
                        size: 12 * Appearance.effectiveScale
                        color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: TimerStopwatchService.formatTimer(TimerStopwatchService.timerSeconds)
                        font.family: Theme.font.monospace
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Divider between timer and stopwatch if both visible
                Rectangle {
                    width: 1
                    height: 10 * Appearance.effectiveScale
                    color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.5)
                    Layout.alignment: Qt.AlignVCenter
                    visible: timerWidget.visible && stopwatchWidget.visible
                }

                // Stopwatch Widget
                Row {
                    id: stopwatchWidget
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4 * Appearance.effectiveScale
                    visible: TimerStopwatchService.stopwatchTime > 0

                    DankIcon {
                        name: "timer"
                        size: 12 * Appearance.effectiveScale
                        color: TimerStopwatchService.swRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: {
                            let ms = TimerStopwatchService.stopwatchTime;
                            let totalSecs = Math.floor(ms / 1000);
                            let tenths = Math.floor((ms % 1000) / 100);
                            let secs = totalSecs % 60;
                            let mins = Math.floor(totalSecs / 60);
                            let pad = (num) => String(num).padStart(2, '0');
                            return pad(mins) + ":" + pad(secs) + "." + tenths;
                        }
                        font.family: Theme.font.monospace
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: TimerStopwatchService.swRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Lyrics Island layout
            Item {
                id: lyricsIsland
                anchors.fill: parent
                anchors.leftMargin: 20 * Appearance.effectiveScale
                anchors.rightMargin: 20 * Appearance.effectiveScale
                visible: centerPill.showLyricsMode
                opacity: centerPill.showLyricsMode ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                clip: true

                BarAudioVisualizer {
                    id: lyricsVisualizer
                    activePlayer: barMediaPlayer.activePlayer
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    // Only show when the player has media
                    visible: activePlayer !== null
                }

                property bool showMarquee: LyricsService.backendStatus === "loading" || LyricsService.backendStatus === "missing" || LyricsService.backendStatus === "error" || LyricsService.backendStatus === "idle"

                property string lyricText: {
                    if (showMarquee) return ""; // Let marquee handle this
                    return LyricsService.currentLyric || MprisController.trackTitle || "";
                }
                
                property string activeLyricText: lyricText
                property string previousLyricText: ""
                property real lyricChangeProgress: 1
                
                property real maxTextWidth: {
                    let visualizerW = lyricsVisualizer.visible ? lyricsVisualizer.width + 12 : 0;
                    if (showMarquee) {
                        return Math.min(fallbackMarqueeText.implicitWidth, 250) + visualizerW;
                    }
                    return Math.max(oldTextItem.implicitWidth, newTextItem.implicitWidth) + visualizerW;
                }
                
                onLyricTextChanged: {
                    if (lyricText === activeLyricText) return;
                    if (activeLyricText === "") {
                        previousLyricText = "";
                        activeLyricText = lyricText;
                        lyricChangeProgress = 1;
                        return;
                    }
                    previousLyricText = activeLyricText;
                    activeLyricText = lyricText;
                    lyricChangeProgress = 0;
                    lyricChangeAnimation.restart();
                }

                SequentialAnimation {
                    id: lyricChangeAnimation

                    NumberAnimation {
                        target: lyricsIsland
                        property: "lyricChangeProgress"
                        from: 0
                        to: 1
                        duration: 260
                        easing.type: Easing.OutCubic
                    }

                    ScriptAction {
                        script: lyricsIsland.previousLyricText = ""
                    }
                }

                // Fallback Marquee (Loading / Missing)
                Item {
                    id: fallbackMarqueeContainer
                    visible: lyricsIsland.showMarquee
                    anchors.left: lyricsVisualizer.visible ? lyricsVisualizer.right : parent.left
                    anchors.leftMargin: lyricsVisualizer.visible ? 12 : 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    clip: true

                    Text {
                        id: fallbackMarqueeText
                        text: {
                            if (!barMediaPlayer.activePlayer) return "No Media";
                            var title = barMediaPlayer.activePlayer.trackTitle || barMediaPlayer.activePlayer.title || "Unknown Track";
                            var artist = barMediaPlayer.activePlayer.trackArtist || barMediaPlayer.activePlayer.artist || "";
                            return artist !== "" ? (title + " - " + artist) : title;
                        }
                        font.family: Theme.font.family
                        font.pixelSize: 14 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: Theme.primary
                        y: (parent.height - height) / 2
                        opacity: 1.0

                        SequentialAnimation {
                            running: LyricsService.backendStatus === "loading" && lyricsIsland.visible
                            loops: Animation.Infinite
                            NumberAnimation { target: fallbackMarqueeText; property: "opacity"; from: 1.0; to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { target: fallbackMarqueeText; property: "opacity"; from: 0.3; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                            onRunningChanged: {
                                if (!running) fallbackMarqueeText.opacity = 1.0
                            }
                        }

                        NumberAnimation on x {
                            id: lyricsMarqueeAnim
                            from: fallbackMarqueeContainer.width
                            to: -fallbackMarqueeText.implicitWidth
                            duration: Math.max(4000, fallbackMarqueeText.implicitWidth * 35)
                            loops: Animation.Infinite
                            running: lyricsIsland.showMarquee && lyricsIsland.visible
                        }

                        onTextChanged: lyricsMarqueeAnim.restart()
                    }
                }

                Text {
                    id: oldTextItem
                    visible: lyricsIsland.previousLyricText !== "" && !lyricsIsland.showMarquee
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -14 * Appearance.effectiveScale * lyricsIsland.lyricChangeProgress
                    width: parent.width
                    text: lyricsIsland.previousLyricText
                    color: Theme.primary
                    opacity: 1 - lyricsIsland.lyricChangeProgress
                    font.family: Theme.font.family
                    font.pixelSize: 14 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    id: newTextItem
                    visible: lyricsIsland.activeLyricText !== "" && !lyricsIsland.showMarquee
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: lyricsIsland.previousLyricText !== "" ? 12 * Appearance.effectiveScale * (1 - lyricsIsland.lyricChangeProgress) : 0
                    width: parent.width
                    text: lyricsIsland.activeLyricText
                    color: Theme.primary
                    opacity: lyricsIsland.previousLyricText !== "" ? lyricsIsland.lyricChangeProgress : 1
                    font.family: Theme.font.family
                    font.pixelSize: 14 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        // RIGHT MODULE: Three separate pills (connectivity, audio/display, system controls)
        Row {
            id: rightPills
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6 * Appearance.effectiveScale

            // Connectivity Pill (WiFi + Bluetooth)
            Rectangle {
                id: connectivityPill
                height: barContainer.height
                width: connectivityLayout.implicitWidth + 24 * Appearance.effectiveScale
                radius: height / 2
                color: barContainer.pillColor
                opacity: barContainer.pillOpacity
                border.color: barContainer.pillBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: barContainer.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                        GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    border.color: "transparent"
                }

                RowLayout {
                    id: connectivityLayout
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale

                    BarComponents.Network {
                        id: wifiWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.Bluetooth {
                        id: bluetoothWidget
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Audio & Brightness Pill
            Rectangle {
                id: audioPill
                height: barContainer.height
                width: audioLayout.implicitWidth + 24 * Appearance.effectiveScale
                radius: height / 2
                color: barContainer.pillColor
                opacity: barContainer.pillOpacity
                border.color: barContainer.pillBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: barContainer.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                        GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    border.color: "transparent"
                }

                RowLayout {
                    id: audioLayout
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale

                    BarComponents.Brightness {
                        id: brightnessWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.Volume {
                        id: volumeWidget
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // Control/Power Pill (Caffeine, DND, Battery, Notification Bell, Settings)
            Rectangle {
                id: controlPill
                height: barContainer.height
                width: controlLayout.implicitWidth + 24 * Appearance.effectiveScale
                radius: height / 2
                color: barContainer.pillColor
                opacity: barContainer.pillOpacity
                border.color: barContainer.pillBorder
                border.width: 1
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: barContainer.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                        GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    border.color: "transparent"
                }

                RowLayout {
                    id: controlLayout
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale

                    BarComponents.StatusIndicators {
                        id: statusIndicatorsWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                        visible: statusIndicatorsWidget.visible
                    }

                    BarComponents.Battery {
                        id: batteryWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.NotificationCenterToggle {
                        id: notificationBellWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.ControlCenterToggle {
                        id: settingsWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12 * Appearance.effectiveScale
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                        visible: systemTrayWidget.visible
                    }

                    BarComponents.SystemTray {
                        id: systemTrayWidget
                        Layout.alignment: Qt.AlignVCenter
                        parentWindow: barWindow
                    }
                }
            }
        }
    }
}
