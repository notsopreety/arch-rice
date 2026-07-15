import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../components/bar" as BarComponents
import "../services"
import QtCore

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Styling.barHeight
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
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        // LEFT MODULE: OS Icon + Workspaces
        Rectangle {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: leftLayout.implicitWidth + 24
            radius: height / 2
            
            color: Theme.surfaceContainerHigh
            opacity: 0.95
            border.color: Theme.outlineVariant
            border.width: 1

            RowLayout {
                id: leftLayout
                anchors.centerIn: parent
                spacing: 12

                // OS Icon (Arch Linux logo)
                Text {
                    text: ""
                    font.family: Theme.font.monospace
                    font.pixelSize: 16
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
                    height: 14
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
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: sysMonitorLayout.implicitWidth + 20
            radius: height / 2

            color: Theme.surfaceContainerHigh
            opacity: 0.95
            border.color: Theme.outlineVariant
            border.width: 1

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
                    spacing: 10

                    // Dynamic colors based on usage intensity
                    readonly property color cpuColor: SystemUsage.cpuPerc > 0.8 ? "#ffb4ab" : SystemUsage.cpuPerc > 0.5 ? "#dac58c" : Theme.primary
                    readonly property color memColor: SystemUsage.memPerc > 0.85 ? "#ffb4ab" : SystemUsage.memPerc > 0.65 ? "#dac58c" : Theme.secondary

                    Row {
                        spacing: 4
                        DankIcon {
                            name: "developer_board"
                            size: 12
                            color: sysMonitorLayout.cpuColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.cpuPerc * 100) + "%"
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            color: sysMonitorLayout.cpuColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4
                        DankIcon {
                            name: "thermostat"
                            size: 12
                            color: SystemUsage.cpuTemp > 85 ? "#ffb4ab" : SystemUsage.cpuTemp > 70 ? "#dac58c" : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.cpuTemp) + "°C"
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            color: SystemUsage.cpuTemp > 85 ? "#ffb4ab" : SystemUsage.cpuTemp > 70 ? "#dac58c" : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: 4
                        DankIcon {
                            name: "memory"
                            size: 12
                            color: sysMonitorLayout.memColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(SystemUsage.memPerc * 100) + "%"
                            font.family: Theme.font.family
                            font.pixelSize: 11
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
                width: showLyricsMode ? Math.min(Math.max(400, lyricsIsland.maxTextWidth + 60), parent.width > 0 ? parent.width - 600 : 1000) : centerLayout.implicitWidth + 24
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                radius: height / 2
                
                color: Theme.surfaceContainerHigh
                opacity: 0.95
                border.color: Theme.outlineVariant
                border.width: 1

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
                spacing: 12

                BarMediaPlayer {
                    id: barMediaPlayer
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    width: 1
                    height: 14
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
                    height: 14
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
                    height: 14
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                    visible: alarmIndicator.visible
                }

                // Alarm Ringing Indicator
                MouseArea {
                    id: alarmIndicator
                    Layout.alignment: Qt.AlignVCenter
                    visible: TimerStopwatchService.alarmActive
                    
                    implicitWidth: alarmIndicatorRow.implicitWidth + 12
                    implicitHeight: 24
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
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
                            size: 13
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
                            font.pixelSize: 10
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
                    height: 14
                    color: Theme.outlineVariant
                    Layout.alignment: Qt.AlignVCenter
                    visible: timerWidget.visible || stopwatchWidget.visible
                }

                // Timer Widget
                Row {
                    id: timerWidget
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    visible: !TimerStopwatchService.timerSetupMode

                    DankIcon {
                        name: "hourglass"
                        size: 12
                        color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: TimerStopwatchService.formatTimer(TimerStopwatchService.timerSeconds)
                        font.family: Theme.font.monospace
                        font.pixelSize: 11
                        color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Divider between timer and stopwatch if both visible
                Rectangle {
                    width: 1
                    height: 10
                    color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.5)
                    Layout.alignment: Qt.AlignVCenter
                    visible: timerWidget.visible && stopwatchWidget.visible
                }

                // Stopwatch Widget
                Row {
                    id: stopwatchWidget
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    visible: TimerStopwatchService.stopwatchTime > 0

                    DankIcon {
                        name: "timer"
                        size: 12
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
                        font.pixelSize: 11
                        color: TimerStopwatchService.swRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Lyrics Island layout
            Item {
                id: lyricsIsland
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
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

                property string lyricText: {
                    if (LyricsService.backendStatus === "missing" || LyricsService.backendStatus === "error" || LyricsService.backendStatus === "idle") return "No lyrics found";
                    if (LyricsService.backendStatus === "loading") return "Loading lyrics...";
                    return LyricsService.currentLyric || MprisController.trackTitle || "";
                }
                
                property string activeLyricText: lyricText
                property string previousLyricText: ""
                property real lyricChangeProgress: 1
                property real maxTextWidth: Math.max(oldTextItem.implicitWidth, newTextItem.implicitWidth) + (lyricsVisualizer.visible ? lyricsVisualizer.width + 12 : 0)
                
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

                Text {
                    id: oldTextItem
                    visible: lyricsIsland.previousLyricText !== ""
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -14 * lyricsIsland.lyricChangeProgress
                    width: parent.width
                    text: lyricsIsland.previousLyricText
                    color: Theme.primary
                    opacity: 1 - lyricsIsland.lyricChangeProgress
                    font.family: Theme.font.family
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    id: newTextItem
                    visible: lyricsIsland.activeLyricText !== ""
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: lyricsIsland.previousLyricText !== "" ? 12 * (1 - lyricsIsland.lyricChangeProgress) : 0
                    width: parent.width
                    text: lyricsIsland.activeLyricText
                    color: Theme.primary
                    opacity: lyricsIsland.previousLyricText !== "" ? lyricsIsland.lyricChangeProgress : 1
                    font.family: Theme.font.family
                    font.pixelSize: 14
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
            spacing: 6

            // Connectivity Pill (WiFi + Bluetooth)
            Rectangle {
                id: connectivityPill
                height: barContainer.height
                width: connectivityLayout.implicitWidth + 24
                radius: height / 2
                color: Theme.surfaceContainerHigh
                opacity: 0.95
                border.color: Theme.outlineVariant
                border.width: 1

                RowLayout {
                    id: connectivityLayout
                    anchors.centerIn: parent
                    spacing: 8

                    BarComponents.Network {
                        id: wifiWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12
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
                width: audioLayout.implicitWidth + 24
                radius: height / 2
                color: Theme.surfaceContainerHigh
                opacity: 0.95
                border.color: Theme.outlineVariant
                border.width: 1

                RowLayout {
                    id: audioLayout
                    anchors.centerIn: parent
                    spacing: 8

                    BarComponents.Brightness {
                        id: brightnessWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12
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
                width: controlLayout.implicitWidth + 24
                radius: height / 2
                color: Theme.surfaceContainerHigh
                opacity: 0.95
                border.color: Theme.outlineVariant
                border.width: 1

                RowLayout {
                    id: controlLayout
                    anchors.centerIn: parent
                    spacing: 8

                    BarComponents.StatusIndicators {
                        id: statusIndicatorsWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12
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
                        height: 12
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.NotificationCenterToggle {
                        id: notificationBellWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BarComponents.ControlCenterToggle {
                        id: settingsWidget
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 12
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
