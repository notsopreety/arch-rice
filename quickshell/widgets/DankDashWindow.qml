import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
import "../theme"
import "../services"
import "../components"
import "../core"

PanelWindow {
    id: dashWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-dankdash"
    
    WlrLayershell.keyboardFocus: DankDashService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: false

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); dashWindow.glassmorphism = true; } catch(e) { dashWindow.glassmorphism = false; } }
        onLoaded: dashWindow.glassmorphism = true
        onLoadFailed: dashWindow.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    Connections {
        target: DankDashService
        function onVisibleChanged() {
            if (DankDashService.visible) {
                dashWindow.visible = true;
                openAnim.restart();
                if (dashWindow.currentTabIndex === 2) {
                    wallpaperTab.forceActiveFocus();
                } else {
                    dashContent.forceActiveFocus();
                }
            } else {
                closeAnim.restart();
            }
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: dashContainer; property: "y"; from: 20; to: 50; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: dashContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: dashContainer; property: "y"; from: 50; to: 20; duration: 250; easing.type: Easing.OutCubic }
        NumberAnimation { target: dashContainer; property: "opacity"; from: 1.0; to: 0.0; duration: 250; easing.type: Easing.OutCubic }
        onFinished: {
            dashWindow.visible = false;
        }
    }

    property int currentTabIndex: DankDashService.activeTab
    onCurrentTabIndexChanged: {
        DankDashService.activeTab = currentTabIndex
        if (currentTabIndex === 2) {
            wallpaperTab.forceActiveFocus();
        } else {
            dashContent.forceActiveFocus();
        }
    }
    property int systemVolume: 40
    property int systemBrightness: 50

    // Media Dropdown Overlay properties
    property int dropdownType: 0
    property point dropdownAnchor: Qt.point(0, 0)
    property bool dropdownRightEdge: false

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
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || activePlayer.artUrl || "") : ""

    property var tabs: [
        { name: "Overview", icon: "dashboard" },
        { name: "Media", icon: "music_note" },
        { name: "Wallpapers", icon: "wallpaper" },
        { name: "Weather", icon: "wb_sunny" },
        { name: "Performance", icon: "speed" },
        { name: "Settings", icon: "settings" }
    ]

    // System Volume Control Processes
    Process {
        id: getVolumeProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var clean = line.replace("Volume: ", "").trim();
                var val = parseFloat(clean);
                if (!isNaN(val)) {
                    dashWindow.systemVolume = Math.round(val * 100);
                }
            }
        }
    }

    Process {
        id: setVolumeProc
        running: false
    }

    function setSystemVolume(pct) {
        var clamped = Math.max(0, Math.min(100, pct));
        dashWindow.systemVolume = clamped;
        var valStr = (clamped / 100.0).toFixed(2);
        console.log("🔊 Setting system volume to:", clamped, "% (valStr: " + valStr + ")");
        setVolumeProc.running = false;
        setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", valStr];
        setVolumeProc.running = true;
    }

    // Brightness Control Processes
    Process {
        id: getBrightnessProc
        command: ["brightnessctl", "-m"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(",");
                if (parts.length >= 4) {
                    var pctStr = parts[3].replace("%", "").trim();
                    var val = parseInt(pctStr);
                    if (!isNaN(val)) {
                        dashWindow.systemBrightness = val;
                    }
                }
            }
        }
    }

    Process {
        id: setBrightnessProc
        running: false
    }

    function setSystemBrightness(pct) {
        var clamped = Math.max(0, Math.min(100, pct));
        dashWindow.systemBrightness = clamped;
        setBrightnessProc.running = false;
        setBrightnessProc.command = ["brightnessctl", "set", clamped + "%"];
        setBrightnessProc.running = true;
    }

    Timer {
        id: statusPoller
        interval: 1000
        running: dashWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getVolumeProc.running = true;
            getBrightnessProc.running = true;
        }
    }

    FocusScope {
        id: dashContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                DankDashService.close();
                return;
            }
            if (dashWindow.currentTabIndex === 2) {
                if (typeof wallpaperTab.handleKeyEvent === "function") {
                    if (wallpaperTab.handleKeyEvent(event)) {
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        // Dim backdrop - clicking outside closes the dash
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: DankDashService.close()
            }
        }

        // Main Dashboard container (holding the card and the volume pill side-by-side)
        Item {
            id: dashContainer
            anchors.horizontalCenter: parent.horizontalCenter
            width: 820 * Appearance.effectiveScale
            height: 520 * Appearance.effectiveScale

            y: 50 * Appearance.effectiveScale

            // Drop shadow for the main card
            DropShadow {
                anchors.fill: dashCard
                source: dashCard
                verticalOffset: 16 * Appearance.effectiveScale
                radius: 48 * Appearance.effectiveScale
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.4)
                transparentBorder: true
            }

            Rectangle {
                id: dashCard
                anchors.fill: parent
                radius: Theme.rounding.large

                MouseArea {
                    anchors.fill: parent
                    // Consume clicks so they don't fall through to the backdrop
                }
                color: dashWindow.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
                border.color: dashWindow.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                clip: true // Round the clipped blur background automatically!
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Glossy reflection overlay
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.height * 0.45
                    radius: parent.radius
                    visible: dashWindow.glassmorphism && dashWindow.currentTabIndex !== 1
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                    }
                    border.color: "transparent"
                    z: 999
                }

                // Blurred Album Art Background for Media tab
                Item {
                    anchors.fill: parent
                    visible: dashWindow.currentTabIndex === 1 && dashWindow.artUrl !== ""
                    z: 0

                    Image {
                        id: bgImage
                        anchors.fill: parent
                        source: dashWindow.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    FastBlur {
                        id: blurredBg
                        anchors.fill: parent
                        source: bgImage
                        radius: 64
                        transparentBorder: false
                        visible: false
                    }

                    Rectangle {
                        id: maskRect
                        anchors.fill: parent
                        radius: Theme.rounding.large
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: blurredBg
                        maskSource: maskRect
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.rounding.large
                        color: Qt.rgba(0, 0, 0, 0.5) // Dark overlay for text readability
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    z: 1 // Keep above blurred background

                    // Tabs Header Row
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 52 * Appearance.effectiveScale

                        // Tabs Selector
                        Row {
                            anchors.centerIn: parent
                            spacing: 32 * Appearance.effectiveScale

                            Repeater {
                                model: dashWindow.tabs

                                delegate: Item {
                                    width: 80 * Appearance.effectiveScale
                                    height: 52 * Appearance.effectiveScale
                                    
                                    property bool isActive: index === dashWindow.currentTabIndex

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 6 * Appearance.effectiveScale

                                        DankIcon {
                                            name: modelData.icon
                                            size: 18 * Appearance.effectiveScale
                                            color: isActive ? Theme.primary : "white"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Theme.font.family
                                            font.pixelSize: 11 * Appearance.effectiveScale
                                            font.weight: isActive ? Font.Bold : Font.Normal
                                            color: isActive ? Theme.primary : "white"
                                            anchors.horizontalCenter: parent.horizontalCenter
                                        }
                                    }

                                    // Indicator Bar below active tab
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 50 * Appearance.effectiveScale
                                        height: 3 * Appearance.effectiveScale
                                        radius: 1.5 * Appearance.effectiveScale
                                        color: Theme.primary
                                        visible: isActive
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: DankDashService.activeTab = index
                                    }
                                }
                            }
                        }

                    }

                    // Separator below tabs
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.08)
                    }

                    // ==========================================
                    // TAB 0: OVERVIEW TAB CONTENT
                    // ==========================================
                    OverviewTab {
                        visible: dashWindow.currentTabIndex === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onSwitchToWeatherTab: DankDashService.activeTab = 3
                        onSwitchToMediaTab: DankDashService.activeTab = 1
                        onCloseDash: DankDashService.close()
                    }

                    // ==========================================
                    // TAB 1: MEDIA TAB CONTENT (Premium Visualizer View)
                    // ==========================================
                    Item {
                        visible: dashWindow.currentTabIndex === 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Item {
                            id: waveMaskSource
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: -24 * Appearance.effectiveScale
                            anchors.rightMargin: -24 * Appearance.effectiveScale
                            anchors.bottomMargin: -24 * Appearance.effectiveScale
                            height: 180 * Appearance.effectiveScale
                            visible: false
                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.rounding.large
                                color: "white"
                            }
                        }

                        WaveVisualizer {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: -24 * Appearance.effectiveScale
                            anchors.rightMargin: -24 * Appearance.effectiveScale
                            anchors.bottomMargin: -24 * Appearance.effectiveScale
                            height: 180 * Appearance.effectiveScale
                            z: 0
                            opacity: dashWindow.isPlaying ? 0.35 : 0.1
                            waveColor: Theme.primary
                            active: dashWindow.isPlaying
                            maskSource: waveMaskSource
                        }

                        // Center Content: Album Art, Info, Seekbar, Playback controls
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignHCenter

                            Item {
                                width: 200 * Appearance.effectiveScale
                                height: 200 * Appearance.effectiveScale
                                Layout.alignment: Qt.AlignHCenter

                                DankAlbumArt {
                                    id: fullAlbumArt
                                    anchors.fill: parent
                                    activePlayer: dashWindow.activePlayer
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4 * Appearance.effectiveScale

                                Text {
                                    text: dashWindow.hasPlayer ? (dashWindow.activePlayer.trackTitle || dashWindow.activePlayer.title || "Unknown Track") : "No Active Players"
                                    font.family: Theme.font.family
                                    font.pixelSize: 20 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    width: 500 * Appearance.effectiveScale
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: dashWindow.hasPlayer ? (dashWindow.activePlayer.trackArtist || dashWindow.activePlayer.artist || "Unknown Artist") : "Play some music to begin"
                                    font.family: Theme.font.family
                                    font.pixelSize: 13 * Appearance.effectiveScale
                                    color: "#e7bdb3" // Light peach/pink
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    width: 500 * Appearance.effectiveScale
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // Seekbar
                            Item {
                                width: 440 * Appearance.effectiveScale
                                height: 32 * Appearance.effectiveScale
                                Layout.alignment: Qt.AlignHCenter

                                MediaSeekBar {
                                    anchors.fill: parent
                                    activePlayer: dashWindow.activePlayer
                                    fillColor: Theme.primary
                                    textColor: "white"
                                }
                            }

                            // Centered Playback controls
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 28 * Appearance.effectiveScale
                                visible: dashWindow.hasPlayer

                                // Shuffle Button
                                Text {
                                    text: "󰒟"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 20 * Appearance.effectiveScale
                                    color: dashWindow.activePlayer && dashWindow.activePlayer.shuffle ? Theme.primary : Qt.rgba(1, 1, 1, 0.5)
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (dashWindow.activePlayer && dashWindow.activePlayer.shuffleSupported) {
                                                dashWindow.activePlayer.shuffle = !dashWindow.activePlayer.shuffle
                                            }
                                        }
                                    }
                                }

                                // Previous Button
                                Text {
                                    text: "󰒮"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 24 * Appearance.effectiveScale
                                    color: "white"
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (dashWindow.activePlayer) dashWindow.activePlayer.previous()
                                    }
                                }

                                // Play/Pause Button
                                Rectangle {
                                    width: 52 * Appearance.effectiveScale
                                    height: 52 * Appearance.effectiveScale
                                    radius: 26 * Appearance.effectiveScale
                                    color: Theme.primary

                                    Text {
                                        anchors.centerIn: parent
                                        text: dashWindow.isPlaying ? "󰏤" : "󰐊"
                                        font.family: Theme.font.monospace
                                        font.pixelSize: 24 * Appearance.effectiveScale
                                        color: Theme.background
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (dashWindow.activePlayer) dashWindow.activePlayer.togglePlaying()
                                    }
                                }

                                // Next Button
                                Text {
                                    text: "󰒭"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 24 * Appearance.effectiveScale
                                    color: "white"
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (dashWindow.activePlayer) dashWindow.activePlayer.next()
                                    }
                                }

                                // Loop/Repeat Button
                                Text {
                                    text: {
                                        if (!dashWindow.activePlayer) return "󰑖";
                                        switch (dashWindow.activePlayer.loopState) {
                                        case MprisLoopState.Track:
                                            return "󰑗"; // repeat-one / repeat-once
                                        case MprisLoopState.Playlist:
                                        default:
                                            return "󰑖"; // repeat
                                        }
                                    }
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 20 * Appearance.effectiveScale
                                    color: dashWindow.activePlayer && dashWindow.activePlayer.loopState !== MprisLoopState.None ? Theme.primary : Qt.rgba(1, 1, 1, 0.5)
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (dashWindow.activePlayer) {
                                                var current = dashWindow.activePlayer.loopState;
                                                var nextState = MprisLoopState.None;
                                                if (current === MprisLoopState.None) {
                                                    nextState = MprisLoopState.Playlist;
                                                } else if (current === MprisLoopState.Playlist) {
                                                    nextState = MprisLoopState.Track;
                                                } else {
                                                    nextState = MprisLoopState.None;
                                                }
                                                dashWindow.activePlayer.loopState = nextState;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // TAB 2, 3, 4 CONTENT
                    // ==========================================
                    WallpaperTab {
                        id: wallpaperTab
                        visible: dashWindow.currentTabIndex === 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        focus: true
                    }

                    WeatherTab {
                        visible: dashWindow.currentTabIndex === 3
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    PerformanceTab {
                        visible: dashWindow.currentTabIndex === 4
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    SettingsTab {
                        visible: dashWindow.currentTabIndex === 5
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

        }
        // Dropdown Overlay and close timer for Media controls
        Timer {
            id: dropdownCloseTimer
            interval: 400
            onTriggered: {
                dashWindow.dropdownType = 0;
            }
        }

        MediaDropdownOverlay {
            id: mediaDropdownOverlay
            dropdownType: dashWindow.dropdownType
            anchorPos: dashWindow.dropdownAnchor
            isRightEdge: dashWindow.dropdownRightEdge
            activePlayer: dashWindow.activePlayer
            systemVolume: dashWindow.systemVolume
            visible: dropdownType !== 0

            onCloseRequested: dashWindow.dropdownType = 0
            onPanelEntered: dropdownCloseTimer.stop()
            onPanelExited: dropdownCloseTimer.restart()
            onVolumeChanged: {
                dashWindow.setSystemVolume(volume * 100);
            }
        }
    }
}
