import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick.Effects
import "../../theme"
import "../../components"
import "../../services"
import "../desktopWidget" as DesktopClock
import Quickshell

Rectangle {
    id: root
    required property LockContext context

    color: "transparent"

    FontLoader {
        id: anuratiFont
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/fonts/anurati/Anurati-Regular.otf"
    }

    // Wallpaper image
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Theme.wallpaperPath ? "file://" + Theme.wallpaperPath : "file:///home/sawmer/.cache/awww-wal/wall.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    // Blur effect on wallpaper
    FastBlur {
        anchors.fill: parent
        source: wallpaperSource
        radius: 40
    }

    // Source for blur
    ShaderEffectSource {
        id: wallpaperSource
        sourceItem: wallpaper
        visible: false
    }

    // Semi-transparent overlay for readability
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: 0.45
    }

    ColumnLayout {
        id: clockContainer
        property var date: new Date()

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Math.max(20, parent.height * 0.1)
        }

        // Clock Configuration - M3 Themed
        property string clockFontFamily: anuratiFont.name
        property int containerSpacing: 12

        // Day settings
        property int dayFontSize: 56
        property double dayOpacity: 1.0
        property int dayLetterSpacing: 20
        property int dayTopMargin: 0

        // Date settings
        property int dateFontSize: 20
        property double dateOpacity: 0.9
        property int dateLetterSpacing: 5
        property int dateTopMargin: 8

        // Time settings
        property int timeFontSize: 16
        property double timeOpacity: 0.8
        property int timeLetterSpacing: 5
        property int timeTopMargin: 12

        spacing: containerSpacing

        Timer {
            running: true
            repeat: true
            interval: 1000
            onTriggered: clockContainer.date = new Date()
        }

        // Day name - Large elegant style
        Label {
            renderType: Text.NativeRendering
            font.pointSize: clockContainer.dayFontSize
            font.family: clockContainer.clockFontFamily
            font.weight: Font.Bold
            font.letterSpacing: clockContainer.dayLetterSpacing
            color: Theme.primary
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: clockContainer.dayTopMargin
            opacity: clockContainer.dayOpacity
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.2)

            text: {
                const days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
                return days[clockContainer.date.getDay()];
            }
        }

        // Date - Medium size
        Label {
            renderType: Text.NativeRendering
            font.pointSize: clockContainer.dateFontSize
            font.family: clockContainer.clockFontFamily
            font.weight: Font.Normal
            font.letterSpacing: clockContainer.dateLetterSpacing
            color: Theme.onSurfaceColor
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: clockContainer.dateTopMargin
            opacity: clockContainer.dateOpacity

            text: {
                const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
                                'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
                const month = months[clockContainer.date.getMonth()];
                const day = clockContainer.date.getDate();
                const year = clockContainer.date.getFullYear();
                return `${month} ${day}, ${year}`;
            }
        }

        // Time - Small with decorative dashes
        Label {
            renderType: Text.NativeRendering
            font.pointSize: clockContainer.timeFontSize
            font.family: clockContainer.clockFontFamily
            font.weight: Font.Normal
            font.letterSpacing: clockContainer.timeLetterSpacing
            color: Theme.secondary
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: clockContainer.timeTopMargin
            opacity: clockContainer.timeOpacity

            text: {
                let hours = clockContainer.date.getHours();
                const minutes = clockContainer.date.getMinutes().toString().padStart(2, '0');
                const ampm = hours >= 12 ? 'PM' : 'AM';
                hours = hours % 12;
                hours = hours ? hours : 12;
                return `- ${hours}:${minutes} ${ampm} -`;
            }
        }
    }

    // Container to dynamically fit available vertical space
    Item {
        id: freeSpaceContainer
        anchors {
            top: clockContainer.bottom
            bottom: mediaPlayer.top
            left: parent.left
            right: parent.right
            topMargin: 20
            bottomMargin: 20
        }

        // Auto-scale to fit instead of hiding
        property real requiredHeight: 320
        property real scaleFactor: Math.min(1.0, Math.max(0.4, height / requiredHeight))
        
        // Offset the centering upwards if we're squeezed, so it doesn't just shrink in the middle
        property real squeezeOffset: (1.0 - scaleFactor) * 50

        // Home screen clock widget centered on the lockscreen with weather
        DesktopClock.Clock {
            id: lockscreenHomeClock
            winSize: 220
            interactive: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -freeSpaceContainer.squeezeOffset
            scale: freeSpaceContainer.scaleFactor
            transformOrigin: Item.Center
        }
    }

    // ============================================
    // STATUS BAR - Top of screen
    // ============================================
    Row {
        id: statusBar
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 12

        // Battery
        Rectangle {
            id: batteryPill
            property var battery: UPower.displayDevice
            property bool hasBattery: battery && battery.ready
            property int pct: hasBattery ? Math.round(battery.percentage * 100) : 0
            property bool charging: hasBattery && (
                battery.state === UPowerDeviceState.Charging ||
                battery.state === UPowerDeviceState.FullyCharged
            )
            readonly property bool isCharging: hasBattery && (battery.state === UPowerDeviceState.Charging || battery.state === 5)
            readonly property bool isFullyCharged: hasBattery && (battery.state === UPowerDeviceState.FullyCharged)
            readonly property bool isPluggedIn: charging

            readonly property color greenColor: "#4caf50"
            readonly property color yellowColor: "#ffc107"
            readonly property color redColor: "#f44336"

            readonly property color chargingColor: greenColor
            readonly property color normalColor: Theme.primary

            readonly property color compactBatteryColor: {
                if (battMouseArea.containsMouse) return Theme.primary;
                if (charging) return chargingColor;
                if (pct < 10) return redColor;
                if (pct < 20) return yellowColor;
                return Theme.primary;
            }

            width: battMouseArea.containsMouse ? (batteryRow.implicitWidth + 24) : 44
            height: 36
            radius: Theme.rounding.full
            color: Theme.surfaceContainerHigh
            opacity: 0.9
            clip: true

            Behavior on width { NumberAnimation { duration: Theme.anim.durationNormal; easing.type: Theme.anim.type; easing.bezierCurve: Theme.anim.curve } }

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 6
                Item {
                    width: 22
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    
                    // Battery body
                    Rectangle {
                        id: batteryBody
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 12
                        radius: 3
                        color: "transparent"
                        border.width: 1.5
                        border.color: batteryPill.compactBatteryColor
                        
                        Behavior on border.color { ColorAnimation { duration: 300 } }
                        
                        // Fill level
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 2.5
                            width: Math.max(0, (parent.width - 5) * (batteryPill.pct / 100))
                            radius: 1.5
                            color: batteryPill.compactBatteryColor
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            
                            // Charging shimmer
                            Rectangle {
                                visible: batteryPill.isCharging && !batteryPill.isFullyCharged
                                anchors.fill: parent
                                radius: parent.radius
                                color: Qt.rgba(1, 1, 1, 0.12)
                                opacity: 0
                                
                                property real shimmerPos: 0
                                x: (parent.width + width) * shimmerPos - width
                                
                                SequentialAnimation on shimmerPos {
                                    running: batteryPill.isCharging && !batteryPill.isFullyCharged
                                    loops: Animation.Infinite
                                    NumberAnimation { from: -0.3; to: 1.3; duration: 1200; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: 400 }
                                }
                                SequentialAnimation on opacity {
                                    running: batteryPill.isCharging && !batteryPill.isFullyCharged
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.04; to: 0.16; duration: 600; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.16; to: 0.04; duration: 600; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                    
                    // Terminal nub
                    Rectangle {
                        anchors.left: batteryBody.right
                        anchors.leftMargin: -1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 5
                        radius: 1.5
                        color: batteryPill.compactBatteryColor

                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    
                    // Charging bolt icon
                    DankIcon {
                        visible: batteryPill.isPluggedIn
                        anchors.centerIn: batteryBody
                        name: "bolt"
                        size: 9
                        color: batteryPill.pct > 50 ? Qt.rgba(0,0,0,0.8) : Qt.rgba(1,1,1,0.9)
                        opacity: 0.9

                        SequentialAnimation on scale {
                            running: batteryPill.isCharging && !batteryPill.isFullyCharged
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.2; duration: 400; easing.type: Easing.OutCubic }
                            NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InCubic }
                        }
                    }
                }
                Text {
                    visible: battMouseArea.containsMouse
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.primary
                    text: batteryPill.pct + "%" + (batteryPill.charging ? " Charging" : "")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: battMouseArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // WiFi
        Rectangle {
            id: wifiPill
            width: wifiMouseArea.containsMouse ? (wifiRow.implicitWidth + 24) : 44
            height: 36
            radius: Theme.rounding.full
            color: Theme.surfaceContainerHigh
            opacity: 0.9
            clip: true

            Behavior on width { NumberAnimation { duration: Theme.anim.durationNormal; easing.type: Theme.anim.type; easing.bezierCurve: Theme.anim.curve } }

            property bool wifiEnabled: true
            property string wifiSSID: ""
            property int wifiSignal: 0
            property bool wifiConnected: false
            property string connectivity: "none"

            Row {
                id: wifiRow
                anchors.centerIn: parent
                spacing: 6
                DankIcon {
                    name: !wifiPill.wifiEnabled ? "wifi_off" : (!wifiPill.wifiConnected ? "signal_wifi_off" : "wifi")
                    size: 16
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    visible: wifiMouseArea.containsMouse
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.primary
                    text: !wifiPill.wifiEnabled ? "WiFi Off" : (!wifiPill.wifiConnected ? "Disconnected" : (wifiPill.wifiSSID || "Connected"))
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: wifiMouseArea
                anchors.fill: parent
                hoverEnabled: true
            }

            Timer {
                interval: 3000
                running: true
                repeat: true
                onTriggered: {
                    wifiCheckProc.running = true
                    connectivityProc.running = true
                }
            }

            Process {
                id: wifiCheckProc
                command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        var parts = line.trim().split(":")
                        if (parts.length >= 3 && parts[0] === "yes") {
                            wifiPill.wifiConnected = true
                            wifiPill.wifiSSID = parts[1]
                            wifiPill.wifiSignal = parseInt(parts[2]) || 0
                        }
                    }
                }
                onRunningChanged: {
                    if (running) {
                        wifiPill.wifiConnected = false
                        wifiPill.wifiSSID = ""
                    }
                }
            }

            Process {
                id: connectivityProc
                command: ["nmcli", "-t", "networking", "connectivity"]
                running: false
                stdout: SplitParser {
                    onRead: line => wifiPill.connectivity = line.trim()
                }
            }

            Timer {
                interval: 10000
                running: true
                repeat: true
                onTriggered: wifiRadioProc.running = true
            }

            Process {
                id: wifiRadioProc
                command: ["nmcli", "radio", "wifi"]
                running: false
                stdout: SplitParser {
                    onRead: line => wifiPill.wifiEnabled = line.trim() === "enabled"
                }
            }

            Component.onCompleted: {
                wifiCheckProc.running = true
                wifiRadioProc.running = true
                connectivityProc.running = true
            }
        }

        // Bluetooth
        Rectangle {
            id: bluetoothPill
            property var adapter: Bluetooth.defaultAdapter
            property var connectedDevices: Bluetooth.devices

            width: btMouseArea.containsMouse ? (bluetoothRow.implicitWidth + 24) : 44
            height: 36
            radius: Theme.rounding.full
            color: Theme.surfaceContainerHigh
            opacity: 0.9
            clip: true

            Behavior on width { NumberAnimation { duration: Theme.anim.durationNormal; easing.type: Theme.anim.type; easing.bezierCurve: Theme.anim.curve } }

            Row {
                id: bluetoothRow
                anchors.centerIn: parent
                spacing: 6
                DankIcon {
                    name: (!bluetoothPill.adapter || !bluetoothPill.adapter.enabled) ? "bluetooth_disabled" : (bluetoothPill.connectedDevices.values.filter(d => d.state === BluetoothDeviceState.Connected).length > 0 ? "bluetooth_connected" : "bluetooth")
                    size: 16
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    visible: btMouseArea.containsMouse
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.primary
                    text: {
                        if (!bluetoothPill.adapter || !bluetoothPill.adapter.enabled) return "Bluetooth Off"
                        var connected = bluetoothPill.connectedDevices.values.filter(d => d.state === BluetoothDeviceState.Connected)
                        if (connected.length > 0) return connected[0].name
                        return "Disconnected"
                    }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: btMouseArea
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    // ============================================
    // MEDIA PLAYER - Dynamic Island Style
    // ============================================
    property string lastPlayerDbusName: ""
    readonly property var activePlayer: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;
        
        let p = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        if (p) return p;
        
        if (lastPlayerDbusName !== "") {
            p = players.find(p => p.dbusName === lastPlayerDbusName);
            if (p && p.playbackState === MprisPlaybackState.Paused) return p;
        }
        
        p = players.find(p => p.playbackState === MprisPlaybackState.Paused);
        if (p) return p;
        
        return players[0];
    }

    // Use a Connections block or a simple trigger that does not loop back immediately inside the activePlayer evaluation itself.
    // Since activePlayer depends on lastPlayerDbusName, changing lastPlayerDbusName inside onActivePlayerChanged triggers recalculation of activePlayer, creating a loop.
    // Instead, update lastPlayerDbusName asynchronously or only when activePlayer's state changes without causing re-evaluation during the binding phase.
    onActivePlayerChanged: {
        if (activePlayer && activePlayer.dbusName) {
            if (lastPlayerDbusName !== activePlayer.dbusName) {
                // Use Qt.callLater to defer setting lastPlayerDbusName, breaking the evaluation dependency loop
                Qt.callLater(function() {
                    if (activePlayer && activePlayer.dbusName) {
                        lastPlayerDbusName = activePlayer.dbusName;
                    }
                });
            }
        }
    }

    property real trackProgress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"
    property real totalLengthRaw: 0

    Timer {
        id: mprisPoller
        interval: 500
        running: !!activePlayer
        repeat: true
        onTriggered: {
            positionProc.running = true
        }
    }

    Process {
        id: positionProc
        command: ["playerctl", "metadata", "--format", "{{duration(position)}}|{{duration(mpris:length)}}|{{position}}|{{mpris:length}}"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("|")
                if (parts.length >= 4) {
                    root.timePlayed = parts[0] || "0:00"
                    root.timeTotal = parts[1] || "0:00"
                    let pos = parseFloat(parts[2]) || 0
                    let len = parseFloat(parts[3]) || 0
                    root.totalLengthRaw = len
                    if (len > 0) root.trackProgress = pos / len
                    else root.trackProgress = 0
                }
            }
        }
    }

    // Power Commands
    Process { id: shutdownProc; command: ["systemctl", "poweroff"]; running: false }
    Process { id: rebootProc; command: ["systemctl", "reboot"]; running: false }
    Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"]; running: false }
    Process { id: sleepProc; command: ["sh", "-c", "systemctl suspend"]; running: false }

    Rectangle {
        id: mediaPlayer
        property bool isActive: {
            if (!activePlayer) return false;
            const state = activePlayer.playbackState;
            return state === MprisPlaybackState.Playing || state === MprisPlaybackState.Paused;
        }
        property real visualizerPhase: 0
        property color primaryColor: Theme.primary

        function visualizerLevel(index) {
            const phase = visualizerPhase + index * 0.78;
            const primary = (Math.sin(phase) + 1) * 0.5;
            const secondary = (Math.sin(phase * 2 + index * 0.95) + 1) * 0.5;
            return 0.22 + primary * 0.42 + secondary * 0.24;
        }

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: passwordSection.top
            bottomMargin: isActive ? 20 : 0
        }

        width: isActive ? 440 : 0
        height: isActive ? 160 : 0
        radius: Theme.rounding.large
        color: "transparent"
        border.color: Theme.outlineVariant
        border.width: 1
        opacity: isActive ? 0.95 : 0
        visible: opacity > 0
        clip: true

        // Blurred Album Art Background
        Image {
            id: playerBgArt
            anchors.fill: parent
            source: albumArt.artUrl || albumArt.lastValidArtUrl || ""
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
        }

        FastBlur {
            id: blurredBg
            anchors.fill: parent
            source: playerBgArt
            radius: 40
            z: -2

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: blurredBg.width
                    height: blurredBg.height
                    radius: Theme.rounding.large
                }
            }
        }

        // Overlay to dim the background for readability
        Rectangle {
            anchors.fill: parent
            color: Theme.surfaceContainer
            opacity: 0.7
            z: -1
            radius: Theme.rounding.large
        }

        Behavior on opacity { NumberAnimation { duration: Theme.anim.durationNormal; easing.type: Theme.anim.type; easing.bezierCurve: Theme.anim.curve } }
        Behavior on width { NumberAnimation { duration: Theme.anim.durationLong; easing.type: Easing.OutBack } }
        Behavior on height { NumberAnimation { duration: Theme.anim.durationLong; easing.type: Easing.OutBack } }

        Timer {
            interval: 32
            repeat: true
            running: mediaPlayer.isActive && activePlayer.playbackState === MprisPlaybackState.Playing
            onTriggered: {
                mediaPlayer.visualizerPhase += 0.15;
                if (mediaPlayer.visualizerPhase > Math.PI * 2) mediaPlayer.visualizerPhase -= Math.PI * 2;
            }
        }

        Item {
            id: playerMaskSource
            anchors.fill: parent
            visible: false
            Rectangle {
                anchors.fill: parent
                radius: Theme.rounding.large
                color: "white"
            }
        }

        WaveVisualizer {
            id: waveVisualizer
            anchors.fill: parent
            z: 1
            opacity: mediaPlayer.isActive && (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing) ? 0.35 : 0.1
            waveColor: mediaPlayer.primaryColor
            active: mediaPlayer.isActive && (root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing)
            maskSource: playerMaskSource
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // Left side: rotating album art container with Cava visualizer
            Item {
                Layout.preferredWidth: parent.height - 32
                Layout.preferredHeight: parent.height - 32
                Layout.alignment: Qt.AlignVCenter

                DankAlbumArt {
                    id: albumArt
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    activePlayer: root.activePlayer
                }
            }

            // Right side: song information, seekbar, and controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                // Title and Artist
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        Layout.fillWidth: true
                        text: activePlayer ? (activePlayer.trackTitle || activePlayer.title || "No Title") : "No Title"
                        color: Theme.primary
                        font.family: Theme.font.family
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: activePlayer ? (activePlayer.trackArtist || activePlayer.artist || "Unknown Artist") : "Unknown Artist"
                        color: Theme.outline
                        font.family: Theme.font.family
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }
                }

                // SeekBar
                MediaSeekBar {
                    id: mediaSeek
                    Layout.fillWidth: true
                    activePlayer: root.activePlayer
                    fillColor: mediaPlayer.primaryColor
                    trackColor: Qt.rgba(mediaPlayer.primaryColor.r, mediaPlayer.primaryColor.g, mediaPlayer.primaryColor.b, 0.18)
                    textColor: Theme.outline
                    z: 2
                }

                // Controls row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 24
                    DankIcon {
                        name: "skip_previous"
                        size: 24
                        color: Theme.primary
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer) activePlayer.previous() }
                    }
                    DankIcon {
                        name: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                        size: 30
                        color: Theme.primary
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer) activePlayer.togglePlaying() }
                    }
                    DankIcon {
                        name: "skip_next"
                        size: 24
                        color: Theme.primary
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (activePlayer) activePlayer.next() }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: passwordSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: powerButtonsRow.top
            bottomMargin: 24
        }

        // ── Bottom Island (Password Only) ──
        Rectangle {
            id: bottomIsland
            Layout.preferredWidth: 380
            Layout.preferredHeight: 48
            radius: height / 2
            color: Theme.surfaceContainer
            border.color: passwordInput.activeFocus ? Theme.primary : Theme.outlineVariant
            border.width: passwordInput.activeFocus ? 1.5 : 1

            property bool showPasswordText: false

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                // Fingerprint (Clickable to toggle show password)
                DankIcon {
                    name: "fingerprint"
                    size: 22
                    color: bottomIsland.showPasswordText ? Theme.primary : Theme.outline
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 8

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bottomIsland.showPasswordText = !bottomIsland.showPasswordText
                    }
                }

                // Input
                Rectangle {
                    id: inputWrapper
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.surfaceContainerLow
                    radius: height / 2

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        
                        font.pixelSize: 13
                        color: bottomIsland.showPasswordText ? Theme.onSurfaceColor : "transparent"
                        cursorVisible: bottomIsland.showPasswordText && activeFocus
                        inputMethodHints: Qt.ImhSensitiveData
                        echoMode: TextInput.Normal
                        cursorDelegate: Item {}
                        clip: true
                        padding: 12
                        focus: true

                        onTextChanged: root.context.currentText = text
                        onAccepted:    root.context.tryUnlock()

                        Connections {
                            target: root.context
                            function onCurrentTextChanged() {
                                if (passwordInput.text !== root.context.currentText)
                                    passwordInput.text = root.context.currentText
                            }
                        }

                        PasswordChars {
                            anchors.fill: parent
                            active: passwordInput.activeFocus && !bottomIsland.showPasswordText
                            visible: !bottomIsland.showPasswordText
                            length: root.context.currentText.length
                            selectionStart: passwordInput.selectionStart
                            selectionEnd: passwordInput.selectionEnd
                            cursorPosition: passwordInput.cursorPosition
                            
                            charSize: 14
                            shapeColor: Theme.primary
                            selectionColor: Theme.primaryContainer
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: passwordInput.text.length === 0
                            text: root.context.showFailure ? "Incorrect password" : "Enter password"
                            font.pixelSize: 12
                            font.family: Theme.font.family
                            color: root.context.showFailure ? Theme.error : Theme.outline
                        }
                    }
                    
                    // Shake
                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to: -10; duration: 50 }
                        NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  10; duration: 50 }
                        NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  -5; duration: 50 }
                        NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:   5; duration: 50 }
                        NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:   0; duration: 50 }
                    }
                    Connections {
                        target: root.context
                        function onShowFailureChanged() {
                            if (root.context.showFailure) shakeAnim.restart()
                        }
                    }
                }

                // Main Action Button (Unlock)
                Button {
                    id: unlockButton
                    implicitWidth: 40
                    implicitHeight: 40
                    focusPolicy: Qt.NoFocus
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 4

                    enabled: !root.context.unlockInProgress && root.context.currentText !== "";
                    onClicked: {
                        btnShake.restart()
                        root.context.tryUnlock()
                    }

                    onHoveredChanged: {
                        if (hovered) {
                            unlockBg.hoverShape = unlockBg.allowedShapes[Math.floor(Math.random() * unlockBg.allowedShapes.length)]
                            btnShake.restart()
                        }
                    }

                    // Shake animation on hover / click
                    SequentialAnimation {
                        id: btnShake
                        NumberAnimation { target: unlockBg; property: "anchors.horizontalCenterOffset"; to: -4; duration: 40 }
                        NumberAnimation { target: unlockBg; property: "anchors.horizontalCenterOffset"; to: 4; duration: 40 }
                        NumberAnimation { target: unlockBg; property: "anchors.horizontalCenterOffset"; to: -2; duration: 40 }
                        NumberAnimation { target: unlockBg; property: "anchors.horizontalCenterOffset"; to: 2; duration: 40 }
                        NumberAnimation { target: unlockBg; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40 }
                    }

                    background: MaterialShape {
                        id: unlockBg
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent

                        readonly property var allowedShapes: [
                            "square", "oval", "sunny", "very_sunny", 
                            "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                            "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                        ]
                        property string hoverShape: "square"

                        shape: unlockButton.hovered ? hoverShape : "circle"
                        color: unlockButton.enabled ? Theme.primary : Theme.surfaceContainerLow
                        borderWidth: 0

                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 2200
                            running: unlockButton.hovered && unlockButton.enabled
                        }
                    }

                    contentItem: Item {
                        DankIcon {
                            anchors.centerIn: parent
                            name: root.context.unlockInProgress ? "progress_activity" : "arrow_forward"
                            size: 18
                            color: unlockButton.enabled ? Theme.onPrimaryColor : Theme.outline
                        }
                    }
                }
            }
        }
    }

    // Power Options Row
    Row {
        id: powerButtonsRow
        anchors {
            bottom: parent.bottom
            bottomMargin: 40
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 24

        Repeater {
            model: [
                { name: "Sleep", icon: "bedtime", proc: sleepProc, color: Theme.secondary },
                { name: "Reboot", icon: "autorenew", proc: rebootProc, color: Theme.tertiary },
                { name: "Shut Down", icon: "power_settings_new", proc: shutdownProc, color: Theme.error },
                { name: "Log Out", icon: "logout", proc: logoutProc, color: Theme.primary }
            ]

            delegate: Item {
                id: powerBtn
                width: 48
                height: 48
                scale: powerMouse.containsMouse ? 1.15 : 1.0
                opacity: powerMouse.containsMouse ? 1.0 : 0.85

                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MaterialShape {
                    id: powerBtnBg
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent

                    readonly property var allowedShapes: [
                        "square", "oval", "sunny", "very_sunny", 
                        "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                        "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                    ]
                    property string hoverShape: "square"

                    shape: powerMouse.containsMouse ? hoverShape : "circle"
                    color: powerMouse.containsMouse ? Theme.primary : Theme.surfaceContainerHigh
                    borderWidth: 0

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 2200
                        running: powerMouse.containsMouse
                    }

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Item {
                    id: iconContainer
                    anchors.centerIn: parent
                    width: 24; height: 24

                    transform: [
                        Rotation {
                            id: iconWobble
                            origin.x: 12; origin.y: 12
                            angle: 0
                        },
                        Scale {
                            origin.x: 12; origin.y: 12
                            xScale: powerMouse.containsMouse ? 1.08 : 1.0
                            yScale: xScale
                            Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    ]

                    DankIcon {
                        anchors.centerIn: parent
                        name: modelData.icon
                        size: 20
                        color: powerMouse.containsMouse ? Theme.onPrimaryColor : Theme.onSurfaceColor
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    SequentialAnimation {
                        running: powerMouse.containsMouse
                        loops: Animation.Infinite
                        PauseAnimation { duration: 1200 }
                        NumberAnimation { target: iconWobble; property: "angle"; to: -12; duration: 70; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: iconWobble; property: "angle"; to: 12;  duration: 70; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: iconWobble; property: "angle"; to: -8;  duration: 60; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: iconWobble; property: "angle"; to: 8;   duration: 60; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: iconWobble; property: "angle"; to: 0;   duration: 60; easing.type: Easing.InOutQuad }
                        onRunningChanged: { if (!running) iconWobble.angle = 0; }
                    }
                }

                ToolTip {
                    id: tooltip
                    visible: powerMouse.containsMouse
                    delay: 400
                    text: modelData.name

                    enter: Transition {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                    }
                    exit: Transition {
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.OutCubic }
                    }

                    contentItem: Text {
                        text: tooltip.text
                        color: Theme.primary
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    background: Rectangle {
                        color: Theme.surfaceContainer
                        radius: 8
                        border.color: Theme.outline
                        border.width: 1

                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: 0
                            verticalOffset: 4
                            radius: 8
                            samples: 17
                            color: Qt.rgba(0, 0, 0, 0.3)
                        }
                    }
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        powerBtnBg.hoverShape = powerBtnBg.allowedShapes[Math.floor(Math.random() * powerBtnBg.allowedShapes.length)]
                    }
                    onClicked: modelData.proc.running = true
                }
            }
        }
    }
}
