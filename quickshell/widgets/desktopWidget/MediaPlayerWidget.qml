import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../theme"
import "../../components"
import "../../core"
import "../widgetCanvas"

Item {
    id: root

    property real customWidth: -1
    property real customLyricsHeight: 384

    property int styleMode: 1 // 1: Card, 2: Stadium Pill, 3: Symmetry Scalloped Pill Card, 4: Squircle Hero Card, 5: Floating Scalloped Silhouette, 6: Lockscreen Style

    readonly property real defaultWidth: (root.styleMode === 6 ? 440 : (root.styleMode === 5 ? 240 : (root.styleMode === 4 ? 260 : (root.styleMode === 3 ? 360 : (root.styleMode === 2 ? 370 : 420))))) * Appearance.effectiveScale
    readonly property real compactHeight: (root.styleMode === 6 ? 160 : (root.styleMode === 5 ? 240 : (root.styleMode === 4 ? 260 : (root.styleMode === 3 ? 155 : (root.styleMode === 2 ? 82 : 120))))) * Appearance.effectiveScale
    readonly property real lyricsHeight: (customLyricsHeight > 180 ? customLyricsHeight : 384) * Appearance.effectiveScale

    width: customWidth > 0 ? (customWidth * Appearance.effectiveScale) : defaultWidth
    height: (root.styleMode === 1 && root.showLyrics) ? lyricsHeight : compactHeight

    Behavior on width { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    
    // Position bindings
    x: settingsX >= 0 ? settingsX : (parent ? parent.width - width - 40 * Appearance.effectiveScale : 0)
    y: settingsY >= 0 ? settingsY : (parent ? parent.height - height - 40 * Appearance.effectiveScale : 0)
    visible: isActive && opacity > 0
    
    // Scale bindings
    scale: dragArea.pressed ? 0.98 : (dragArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // Settings
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let p = data.mediaPlayer || {};
            if (p.isActive !== undefined) root.isActive = p.isActive;
            if (p.x !== undefined) root.settingsX = p.x;
            if (p.y !== undefined) root.settingsY = p.y;
            if (p.styleMode !== undefined) root.styleMode = p.styleMode;
            if (p.showLyrics !== undefined) root.showLyrics = p.showLyrics;
            if (p.width !== undefined && p.width > 0) root.customWidth = p.width;
            if (p.lyricsHeight !== undefined && p.lyricsHeight > 180) root.customLyricsHeight = p.lyricsHeight;
        } catch(e) {}
    }
    
    Timer { id: reloadTimer; interval: 150; running: false; repeat: false; onTriggered: settingsFile.reload() }
    FileView { id: settingsFile; path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"; watchChanges: true; preload: true; onLoaded: root.loadSettings(text()); onFileChanged: reloadTimer.restart() }
    Process { id: saveSettingsProc }
    
    function saveSettings(newX, newY, lyricsMode, newW, newLyricsH, newStyle) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "p = data.setdefault('mediaPlayer', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("p['x'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("p['y'] = " + Math.round(newY));
        if (lyricsMode !== undefined) updates.push("p['showLyrics'] = " + (lyricsMode ? "True" : "False"));
        let sm = (newStyle !== undefined) ? newStyle : root.styleMode;
        updates.push("p['styleMode'] = " + sm);
        if (newW !== undefined && newW > 0) updates.push("p['width'] = " + Math.round(newW));
        else if (newW === -1) updates.push("p.pop('width', None)");
        if (newLyricsH !== undefined && newLyricsH > 180) updates.push("p['lyricsHeight'] = " + Math.round(newLyricsH));
        updates.push("p.pop('height', None)"); // Remove outdated fixed height
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; f = open(tmp, 'w'); json.dump(data, f, indent=2); f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }


    function hexToRgba(hex, alpha) {
        var c = Qt.color(hex);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }
    readonly property color cardBgColor: root.backgroundOpacity >= 1.0 ? Theme.surfaceContainerHigh : hexToRgba(Theme.surfaceContainerHigh, root.backgroundOpacity)
    readonly property color cardBorderColor: hexToRgba(Theme.outline, root.borderOpacity)
    readonly property color controlsBgColor: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.1)


    // ── Configurable Settings from PluginData ──
    property bool showLyrics: false
    property bool showVisualizer: true
    property string lyricAlignment: "center"
    property string preferredPlayer: "auto"
    property bool filterDuplicates: true
    property real backgroundOpacity: 1.0
    property real borderOpacity: 1.0
    property string colorMode: "primary"
    property var customColor: Theme.primary
    property bool cookieRotation: true
    property real cookieRotateSpeed: 5

    // ── Color Theme Resolution ──
    readonly property color activeAccentColor: {
        if (root.colorMode === "secondary") return Theme.secondary;
        if (root.colorMode === "custom" && root.customColor) {
            if (typeof root.customColor === "string") return root.customColor;
            if (root.customColor.valid) return root.customColor;
        }
        return Theme.primary;
    }

    
    

    // ── MPRIS Active Player Tracking ──
    readonly property var playersList: Mpris.players.values
    readonly property MprisPlayer activePlayer: {
        if (!playersList || playersList.length === 0) return null;
        if (root.preferredPlayer !== "auto" && root.preferredPlayer !== "") {
            for (let i = 0; i < playersList.length; i++) {
                let p = playersList[i];
                let identity = p && p.identity ? p.identity : "";
                let desktopEntry = p && p.desktopEntry ? p.desktopEntry : "";
                if (identity.toLowerCase().includes(root.preferredPlayer.toLowerCase()) ||
                    desktopEntry.toLowerCase().includes(root.preferredPlayer.toLowerCase())) {
                    return p;
                }
            }
        }
        for (let i = 0; i < playersList.length; i++) {
            if (playersList[i] && playersList[i].isPlaying) return playersList[i];
        }
        return playersList[0];
    }

    readonly property bool hasActiveMedia: activePlayer && activePlayer.trackTitle && activePlayer.trackTitle.trim().length > 0 && activePlayer.playbackState !== MprisPlaybackState.Stopped
    readonly property bool showNoPlayerNow: !hasActiveMedia

    opacity: showNoPlayerNow ? 0 : 1

    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    readonly property string trackTitle: (activePlayer && activePlayer.trackTitle) ? activePlayer.trackTitle : "No Media Playing"
    readonly property string trackArtist: (activePlayer && activePlayer.trackArtist) ? activePlayer.trackArtist : "Unknown Artist"
    readonly property string trackArtUrl: (activePlayer && activePlayer.trackArtUrl) ? activePlayer.trackArtUrl : ""
    readonly property real trackPosition: (activePlayer && activePlayer.position) ? activePlayer.position : 0
    readonly property real trackLength: (activePlayer && activePlayer.length) ? activePlayer.length : 0

    // Central playback controls
    function playPause() {
        if (root.activePlayer && root.activePlayer.togglePlaying) {
            root.activePlayer.togglePlaying();
        } else {
            let p = root.activePlayer || (root.playersList && root.playersList.length > 0 ? root.playersList[0] : null);
            if (p && p.play) p.play();
        }
    }
    function nextTrack() {
        if (root.activePlayer && root.activePlayer.next) root.activePlayer.next();
    }
    function prevTrack() {
        if (root.activePlayer && root.activePlayer.previous) root.activePlayer.previous();
    }

    // Shared time format & polled position
    property real currentPosition: 0
    Timer {
        id: positionTimer
        interval: 250
        running: !!root.activePlayer && (root.activePlayer.isPlaying || root.styleMode === 3 || root.styleMode === 4)
        repeat: true
        onTriggered: {
            if (root.activePlayer) root.currentPosition = root.activePlayer.position || 0;
        }
    }
    onActivePlayerChanged: {
        if (root.activePlayer) root.currentPosition = root.activePlayer.position || 0;
    }
    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        const minutes = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return minutes + ":" + (secs < 10 ? "0" : "") + secs;
    }

    // Cover Art Local Download
    property string artFilePath: ""
    property bool artDownloaded: false

    onTrackArtUrlChanged: {
        if (!trackArtUrl || trackArtUrl.length === 0) {
            artDownloaded = false;
            artFilePath = "";
            return;
        }
        if (trackArtUrl.startsWith("file://")) {
            artFilePath = trackArtUrl;
            artDownloaded = true;
            return;
        }
        coverArtDownloader.running = true;
    }

    Process {
        id: coverArtDownloader
        command: ["bash", "-c", "target='/tmp/dms_cover_" + Qt.md5(root.trackArtUrl) + ".jpg'; [ -f \"$target\" ] || curl -sSL '" + root.trackArtUrl + "' -o \"$target\"; echo \"$target\""]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                if (data.trim() !== "") {
                    root.artFilePath = "file://" + data.trim();
                    root.artDownloaded = true;
                }
            }
        }
    }

    // ── Wavy CAVA Audio Visualizer Process ──
    property var cavaPoints: []

    Process {
        id: cavaConfigWriter
        command: [
            "bash", "-c",
            "mkdir -p /tmp/.dankshell && cat > /tmp/.dankshell/cava-matplayer.cfg << 'CAVAEOF'\n" +
            "[general]\n" +
            "bars = 32\n" +
            "framerate = 60\n" +
            "sensitivity = 100\n" +
            "channels = stereo\n" +
            "\n" +
            "[output]\n" +
            "method = raw\n" +
            "channels = stereo\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 1000\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "CAVAEOF"
        ]
        running: false
        onRunningChanged: {
            if (!running) cavaProcess.running = true;
        }
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", "/tmp/.dankshell/cava-matplayer.cfg"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (!line || line.length === 0) return;
                const parts = line.split(";");
                const vals = [];
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i], 10);
                    if (!isNaN(n)) vals.push(n);
                }
                if (vals.length > 0) {
                    root.cavaPoints = vals;
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.showVisualizer) cavaConfigWriter.running = true;
    }

    onShowVisualizerChanged: {
        if (showVisualizer) {
            if (!cavaProcess.running) cavaConfigWriter.running = true;
        } else {
            cavaProcess.running = false;
        }
    }

    // ── Synced Lyrics Engine ──
    property var lyricsLines: []
    property int activeLyricIndex: -1
    property string lyricsStatus: "idle" // "idle", "loading", "ok", "not_found"

    // 300ms Timer syncing track position with lyrics
    Timer {
        id: lyricSyncTimer
        interval: 300
        repeat: true
        running: root.lyricsStatus === "ok" && root.lyricsLines.length > 0 && root.activePlayer && root.activePlayer.isPlaying
        onTriggered: {
            let pos = root.trackPosition;
            let idx = -1;
            for (let i = 0; i < root.lyricsLines.length; i++) {
                if (root.lyricsLines[i].time <= pos) idx = i;
                else break;
            }
            if (idx !== root.activeLyricIndex) {
                root.activeLyricIndex = idx;
            }
        }
    }

    // Python LRCLIB Fetcher Process
    Process {
        id: lyricsProcess
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                let trimmed = data.trim();
                if (trimmed === "not_found" || trimmed === "no_info") {
                    root.lyricsStatus = "not_found";
                    return;
                }
                let parts = trimmed.split("§");
                if (parts.length < 3 || parts[parts.length - 1].trim() !== "ok") {
                    root.lyricsStatus = "not_found";
                    return;
                }
                let lines = [];
                for (let i = 0; i < parts.length - 1; i += 2) {
                    let t = parseFloat(parts[i]);
                    let txt = parts[i + 1] || "";
                    if (!isNaN(t)) lines.push({ time: t, text: txt });
                }
                if (lines.length === 0) {
                    root.lyricsStatus = "not_found";
                    return;
                }
                root.lyricsLines = lines;
                root.activeLyricIndex = -1;
                root.lyricsStatus = "ok";
            }
        }
    }

    function fetchLyrics() {
        lyricsProcess.running = false;
        root.lyricsLines = [];
        root.activeLyricIndex = -1;

        if (!root.activePlayer || !root.trackTitle || root.trackTitle === "No Media Playing") {
            root.lyricsStatus = "idle";
            return;
        }

        root.lyricsStatus = "loading";
        let scriptPath = Quickshell.shellPath("scripts/lyrics.py");
        lyricsProcess.command = [
            "python3", scriptPath,
            root.trackTitle, root.trackArtist, String(Math.floor(root.trackLength))
        ];
        lyricsProcess.running = true;
    }

    onTrackTitleChanged: fetchLyrics()
    onTrackArtistChanged: fetchLyrics()

    // Simple Rectangle Drop Shadow (avoids Qt5Compat.DropShadow duplication bugs)
    Rectangle {
        anchors.fill: card
        anchors.margins: -1
        anchors.verticalCenterOffset: 6 * Appearance.effectiveScale
        radius: card.radius
        color: Qt.rgba(0, 0, 0, 0.45)
        visible: root.styleMode !== 5
    }

    // ── Main Widget Card Container ──
    Rectangle {
        id: card
        anchors.fill: parent
        radius: root.styleMode === 5 ? (width / 2) : (root.styleMode === 2 ? (height / 2) : (root.styleMode === 6 ? Theme.rounding.large : (root.styleMode === 4 ? Math.min(32 * Appearance.effectiveScale, height * 0.15) : (root.styleMode === 3 ? Math.min(26 * Appearance.effectiveScale, height * 0.18) : (Theme.rounding.normal * 1.5)))))
        color: root.styleMode === 5 ? "transparent" : root.cardBgColor
        border.color: "transparent"
        border.width: 0
        clip: root.styleMode !== 5

        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Strict Mask for Card Rounded Corners
        layer.enabled: root.styleMode !== 5
        layer.effect: Component {
            OpacityMask {
                maskSource: Rectangle {
                    width: card.width
                    height: card.height
                    radius: card.radius
                }
            }
        }

        // ── Wavy CAVA Audio Visualizer Background ──
        MaterialPlayerVisualizer {
            id: waveVis
            anchors.fill: parent
            color: root.activeAccentColor
            points: root.cavaPoints
            live: root.showVisualizer && (root.activePlayer ? root.activePlayer.isPlaying : false)
            visible: root.showVisualizer && root.styleMode !== 5 && root.styleMode !== 6
        }

        // ── Drag & Direct Mouse Controls Area ──
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            hoverEnabled: true
            cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            onReleased: {
                if (drag.active) {
                    root.saveSettings(root.x, root.y, root.showLyrics, root.customWidth, root.customLyricsHeight, root.styleMode);
                }
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    // 3-finger click / Middle Click: Expand Lyrics (Style 1 only)
                    if (root.styleMode === 1) {
                        root.showLyrics = !root.showLyrics;
                        root.saveSettings(root.x, root.y, root.showLyrics, root.customWidth, root.customLyricsHeight, root.styleMode);
                    }
                } else if (mouse.button === Qt.RightButton) {
                    // Right Click: Cycle Style Mode (1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1)
                    root.customWidth = -1;
                    root.styleMode = (root.styleMode % 6) + 1;
                    root.saveSettings(root.x, root.y, root.showLyrics, -1, root.customLyricsHeight, root.styleMode);
                }
            }
        }

        // 3-Finger Touchpad / Touch Gesture Handler
        TapHandler {
            target: root
            gesturePolicy: TapHandler.DragThreshold
            acceptedDevices: PointerDevice.TouchScreen | PointerDevice.TouchPad
            onTapped: (eventPoint) => {
                // If 3 fingers tapped simultaneously
                if (root.styleMode === 1) {
                    root.showLyrics = !root.showLyrics;
                    root.saveSettings(root.x, root.y, root.showLyrics, root.customWidth, root.customLyricsHeight, root.styleMode);
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // STYLE 1: Full Card Layout with Optional Expandable Lyrics
        // ═════════════════════════════════════════════════════════════════════
        Column {
            anchors.fill: parent
            spacing: 0
            visible: root.styleMode === 1

            // ── Top Main Row (Strictly 120px compact height) ──
            Item {
                id: topRow
                width: parent.width
                height: root.compactHeight

                // Album Art (Strictly Capped Curved Edge Cover Image)
                Rectangle {
                    id: artRect
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    height: Math.min(100, Math.max(40, topRow.height - 20))
                    width: height
                    radius: Theme.rounding.normal
                    color: Theme.surfaceContainer
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: artRect.width
                            height: artRect.height
                            radius: artRect.radius
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: root.artFilePath
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artDownloaded && root.artFilePath !== ""
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "music_note"
                        size: Math.min(parent.width * 0.4, 42)
                        color: root.activeAccentColor
                        visible: !root.artDownloaded || root.artFilePath === ""
                    }
                }

                // Center/Right Content Layout: Song Info + Control Pill
                ColumnLayout {
                    anchors {
                        left: artRect.right
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 4

                    // Artist Name (Top, bold) & Track Title (Bottom)
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.trackTitle
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            renderType: Text.NativeRendering
                            font.pixelSize: Math.max(14, Math.min(parent.width * 0.05, 17))
                            font.weight: Font.DemiBold
                            color: Theme.onSurfaceColor
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.trackArtist
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            renderType: Text.NativeRendering
                            font.pixelSize: Math.max(12, Math.min(parent.width * 0.04, 14))
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.75
                            elide: Text.ElideRight
                        }
                    }

                    // Controls Pill (Right Aligned)
                    Rectangle {
                        id: controlsPill
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: controlsRow.implicitWidth + 12
                        implicitHeight: Math.max(36, Math.min(parent.height * 0.4, 44))
                        radius: 999
                        color: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.1)

                        RowLayout {
                            id: controlsRow
                            anchors.centerIn: parent
                            spacing: 4

                            // Synced Lyrics Toggle Button
                            Rectangle {
                                implicitWidth: Math.max(28, Math.min(controlsPill.height * 0.8, 34))
                                implicitHeight: implicitWidth
                                radius: implicitWidth / 2
                                color: root.showLyrics ? root.activeAccentColor : "transparent"

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "lyrics"
                                    size: Math.max(14, Math.min(parent.width * 0.55, 18))
                                    color: root.showLyrics ? Theme.onPrimaryColor : Theme.onSurfaceColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.showLyrics = !root.showLyrics;
                                        root.saveSettings(root.x, root.y, root.showLyrics);
                                        if (root.setData) root.setData("showLyrics", root.showLyrics);
                                    }
                                }
                            }

                            // 12-Sided Material Cookie Play/Pause Button
                            MaterialPlayerShape {
                                Layout.preferredWidth: controlsPill.height
                                Layout.preferredHeight: controlsPill.height
                                color: root.activeAccentColor
                                shapeMode: "cookie"
                                animated: root.cookieRotation && (root.activePlayer ? root.activePlayer.isPlaying : false)
                                rotateSpeed: root.cookieRotateSpeed

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                                    size: Math.max(18, Math.min(parent.width * 0.5, 24))
                                    color: Theme.onPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.activePlayer && root.activePlayer.togglePlaying) root.activePlayer.togglePlaying();
                                    }
                                }
                            }

                            // Next / Skip Button
                            Rectangle {
                                implicitWidth: Math.max(28, Math.min(controlsPill.height * 0.8, 34))
                                implicitHeight: implicitWidth
                                radius: implicitWidth / 2
                                color: "transparent"

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "skip_next"
                                    size: Math.max(14, Math.min(parent.width * 0.55, 18))
                                    color: Theme.onSurfaceColor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.activePlayer && root.activePlayer.next) root.activePlayer.next();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Horizontal Gradient Divider Line ──
            Item {
                width: parent.width
                height: root.showLyrics ? 2 : 0
                visible: root.showLyrics

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: Theme.onSurfaceColor }
                        GradientStop { position: 0.8; color: Theme.onSurfaceColor }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    opacity: 0.15
                }
            }

            // ── Bottom Synced Lyrics Expandable Container ──
            Item {
                id: lyricsPanel
                width: parent.width
                height: root.showLyrics ? Math.max(0, card.height - topRow.height - 2) : 0
                visible: root.showLyrics
                clip: true

                // Loading / Error Status View
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.lyricsStatus !== "ok"
                    spacing: 8

                    DankIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: root.lyricsStatus === "loading" ? "sync" : "lyrics"
                        size: 28
                        color: root.activeAccentColor
                        rotation: root.lyricsStatus === "loading" ? rotation : 0

                        SequentialAnimation on rotation {
                            running: root.lyricsStatus === "loading"
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: 360; duration: 1000 }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (root.lyricsStatus === "loading") return "Fetching Synced Lyrics...";
                            if (root.lyricsStatus === "not_found") return "No Lyrics Found on LRCLIB";
                            return "Play a Track to Load Lyrics";
                        }
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        renderType: Text.NativeRendering
                        font.pixelSize: 13
                        color: Theme.onSurfaceVariantColor
                    }
                }

                // Smooth Scrolling Synced Lyrics ListView
                ListView {
                    id: lyricsListView
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    visible: root.lyricsStatus === "ok"
                    clip: true
                    interactive: false
                    model: root.lyricsLines
                    currentIndex: root.activeLyricIndex >= 0 ? root.activeLyricIndex : 0
                    highlightFollowsCurrentItem: true
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: height * 0.38
                    preferredHighlightEnd: height * 0.62
                    spacing: Math.max(2, Math.min(lyricsPanel.height * 0.02, 8))

                    Behavior on contentY {
                        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
                    }

                    delegate: Item {
                        required property int index
                        required property var modelData
                        width: lyricsListView.width
                        height: Math.max(22, Math.min(lyricsPanel.height * 0.12, 32))

                        readonly property int dist: Math.abs(index - lyricsListView.currentIndex)

                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            renderType: Text.NativeRendering
                            horizontalAlignment: {
                                if (root.lyricAlignment === "left") return Text.AlignLeft;
                                if (root.lyricAlignment === "right") return Text.AlignRight;
                                return Text.AlignHCenter;
                            }
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            text: modelData ? (modelData.text || "♪") : ""

                            font.pixelSize: {
                                let h = lyricsPanel.height;
                                if (dist === 0) return Math.max(14, Math.min(h * 0.075, 17));
                                if (dist === 1) return Math.max(12, Math.min(h * 0.06, 14));
                                if (dist === 2) return Math.max(10, Math.min(h * 0.05, 12));
                                return Math.max(9, Math.min(h * 0.04, 11));
                            }
                            font.weight: dist === 0 ? Font.DemiBold : Font.Normal
                            opacity: {
                                if (dist === 0) return 1.0;
                                if (dist === 1) return 0.65;
                                if (dist === 2) return 0.35;
                                return 0.12;
                            }
                            color: dist === 0 ? root.activeAccentColor : Theme.onSurfaceColor

                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // STYLE 2: Stadium Pill Layout (Circular Avatar + Title/Subtitle + Pill Controls)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: stadiumPillContent
            anchors.fill: parent
            visible: root.styleMode === 2

            readonly property real pad: Math.max(10 * Appearance.effectiveScale, height * 0.12)
            readonly property real avatarSize: Math.max(46 * Appearance.effectiveScale, height - pad * 2)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: stadiumPillContent.pad
                anchors.rightMargin: stadiumPillContent.pad
                spacing: 12 * Appearance.effectiveScale

                // ── Left: Circular Album / Artist Avatar ──
                Rectangle {
                    id: pillAvatarRect
                    Layout.preferredWidth: stadiumPillContent.avatarSize
                    Layout.preferredHeight: stadiumPillContent.avatarSize
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: Theme.surfaceContainerHighest
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: pillAvatarRect.width
                            height: pillAvatarRect.height
                            radius: pillAvatarRect.radius
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: root.artDownloaded && root.artFilePath !== "" ? root.artFilePath : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: root.artDownloaded && root.artFilePath !== ""
                    }

                    // Fallback Music Illustration / Icon
                    DankIcon {
                        anchors.centerIn: parent
                        name: "headphones"
                        size: Math.round(parent.width * 0.52)
                        color: root.activeAccentColor
                        visible: !root.artDownloaded || root.artFilePath === ""
                    }
                }

                // ── Center: Title & Subtitle Stack ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2 * Appearance.effectiveScale

                    Text {
                        Layout.fillWidth: true
                        text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                            ? root.trackTitle
                            : "No Music Playing"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(13, Math.round(card.height * 0.20))
                        font.weight: Font.DemiBold
                        color: Theme.onSurfaceColor
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Text {
                        Layout.fillWidth: true
                        text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                            ? root.trackArtist
                            : "Tap to Play"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(card.height * 0.15))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.85
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }

                // ── Right: Stadium Pill Controls (Prev, Cookie Play/Pause, Next) ──
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: Math.max(38 * Appearance.effectiveScale, card.height * 0.62)
                    Layout.preferredWidth: Math.max(115 * Appearance.effectiveScale, card.height * 1.55)
                    radius: height / 2
                    color: root.controlsBgColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8 * Appearance.effectiveScale
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale

                        // Previous Track
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height * 0.65
                            color: "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_previous"
                                size: Math.max(15, Math.round(parent.height * 0.44))
                                color: Theme.onSurfaceColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.prevTrack()
                            }
                        }

                        // Center 12-sided Material Cookie Play / Pause Button
                        Item {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height

                            MaterialPlayerShape {
                                id: pillCookieShape
                                anchors.centerIn: parent
                                width: Math.round(parent.height * 1.05)
                                height: width
                                shapeMode: "cookie"
                                color: root.activeAccentColor
                                animated: root.cookieRotation && (root.activePlayer ? root.activePlayer.isPlaying : false)
                                rotateSpeed: root.cookieRotateSpeed

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                                    size: Math.max(16, Math.round(parent.width * 0.46))
                                    color: Theme.onPrimary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.playPause()
                            }
                        }

                        // Next Track
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.preferredWidth: height * 0.65
                            color: "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_next"
                                size: Math.max(15, Math.round(parent.height * 0.44))
                                color: Theme.onSurfaceColor
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nextTrack()
                            }
                        }
                    }
                }
            }
        }
        // ═════════════════════════════════════════════════════════════════════
        // STYLE 3: Symmetry Scalloped Pill Card (Cookie Prev/Next + Stadium Play + Wavy Progress)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: symmetryCookieCardContent
            anchors.fill: parent
            visible: root.styleMode === 3

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14 * Appearance.effectiveScale
                spacing: 6 * Appearance.effectiveScale

                // ── Top: Track Info (Centered) ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2 * Appearance.effectiveScale

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                            ? root.trackTitle
                            : "No Music Playing"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(14, Math.round(card.height * 0.11))
                        font.weight: Font.DemiBold
                        color: Theme.onSurfaceColor
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                            ? root.trackArtist
                            : "Tap to Play"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(card.height * 0.085))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.8
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }
                }

                // ── Middle: Controls Row (Cookie Prev, Stadium Play/Pause, Cookie Next) ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14 * Appearance.effectiveScale

                    Item { Layout.fillWidth: true }

                    // Prev Button: Cookie Shape
                    Item {
                        Layout.preferredWidth: Math.max(42 * Appearance.effectiveScale, card.height * 0.28)
                        Layout.preferredHeight: Layout.preferredWidth

                        MaterialPlayerShape {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            shapeMode: "cookie"
                            color: root.controlsBgColor
                            animated: false

                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_previous"
                                size: Math.max(16, Math.round(parent.width * 0.44))
                                color: Theme.onSurfaceColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevTrack()
                        }
                    }

                    // Center Play/Pause: Stadium / Capsule Pill
                    Rectangle {
                        Layout.preferredWidth: Math.max(92 * Appearance.effectiveScale, card.height * 0.65)
                        Layout.preferredHeight: Math.max(42 * Appearance.effectiveScale, card.height * 0.28)
                        radius: height / 2
                        color: root.controlsBgColor

                        DankIcon {
                            anchors.centerIn: parent
                            name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                            size: Math.max(20, Math.round(parent.height * 0.52))
                            color: Theme.onSurfaceColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playPause()
                        }
                    }

                    // Next Button: Cookie Shape
                    Item {
                        Layout.preferredWidth: Math.max(42 * Appearance.effectiveScale, card.height * 0.28)
                        Layout.preferredHeight: Layout.preferredWidth

                        MaterialPlayerShape {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            shapeMode: "cookie"
                            color: root.controlsBgColor
                            animated: false

                            DankIcon {
                                anchors.centerIn: parent
                                name: "skip_next"
                                size: Math.max(16, Math.round(parent.width * 0.44))
                                color: Theme.onSurfaceColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextTrack()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // ── Bottom: Elapsed / Total Time & Wavy Progress Bar ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Math.min(card.width - 40 * Appearance.effectiveScale, 220 * Appearance.effectiveScale)
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2 * Appearance.effectiveScale

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.formatTime(root.currentPosition) + " / " + root.formatTime(root.trackLength)
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(10, Math.round(card.height * 0.075))
                        font.weight: Font.Medium
                        color: Theme.onSurfaceVariantColor
                        renderType: Text.NativeRendering
                    }

                    MediaSeekBar {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(card.width - 40 * Appearance.effectiveScale, 220 * Appearance.effectiveScale)
                        implicitHeight: 18
                        activePlayer: root.activePlayer
                        fillColor: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.45)
                        trackColor: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.20)
                        textColor: "transparent"
                    }
                }
            }
        }
        // ═════════════════════════════════════════════════════════════════════
        // STYLE 4: Squircle Hero Card (Stadium Album Art + Prev/CookiePlay/Next + Wavy Progress + Time)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: heroSquircleContent
            anchors.fill: parent
            visible: root.styleMode === 4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                // ── Top: Stadium Pill Hero Album / Illustration ──
                Rectangle {
                    id: heroStadiumArt
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(90 * Appearance.effectiveScale, card.height * 0.46)
                    radius: height / 2
                    color: Theme.surfaceContainerHighest
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: heroStadiumArt.width
                            height: heroStadiumArt.height
                            radius: heroStadiumArt.radius
                        }
                    }

                    // Album Art Image (if available)
                    Image {
                        anchors.fill: parent
                        source: root.artDownloaded && root.artFilePath !== "" ? root.artFilePath : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: root.artDownloaded && root.artFilePath !== ""
                    }

                    // Fallback Illustration / Icon when no art
                    Item {
                        anchors.fill: parent
                        visible: !root.artDownloaded || root.artFilePath === ""

                        DankIcon {
                            anchors.right: parent.right
                            anchors.rightMargin: 18 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            name: "headphones"
                            size: Math.round(parent.height * 0.58)
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.35
                        }

                        DankIcon {
                            anchors.left: parent.left
                            anchors.leftMargin: 20 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            name: "music_note"
                            size: Math.round(parent.height * 0.38)
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.25
                        }
                    }

                    // Dark Tint Overlay for Text Legibility
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, (root.artDownloaded && root.artFilePath !== "") ? 0.40 : 0.15)
                    }

                    // Overlay Title / Artist Text (Centered)
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 32 * Appearance.effectiveScale
                        spacing: 2 * Appearance.effectiveScale

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                                ? root.trackTitle
                                : "Tap to Play"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(14, Math.round(heroStadiumArt.height * 0.18))
                            font.weight: Font.DemiBold
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                                ? root.trackArtist
                                : ""
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(heroStadiumArt.height * 0.13))
                            font.weight: Font.Normal
                            color: Qt.rgba(1, 1, 1, 0.82)
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                            visible: text !== ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playPause()
                    }
                }

                // ── Middle: Circular Prev + Cookie Play/Pause + Circular Next ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16 * Appearance.effectiveScale

                    Item { Layout.fillWidth: true }

                    // Prev Button: Circular Disc
                    Rectangle {
                        Layout.preferredWidth: Math.max(40 * Appearance.effectiveScale, card.height * 0.16)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: root.controlsBgColor

                        DankIcon {
                            anchors.centerIn: parent
                            name: "skip_previous"
                            size: Math.max(18, Math.round(parent.width * 0.46))
                            color: Theme.onSurfaceColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevTrack()
                        }
                    }

                    // Center Play/Pause: 12-sided Material Cookie Shape
                    Item {
                        Layout.preferredWidth: Math.max(50 * Appearance.effectiveScale, card.height * 0.20)
                        Layout.preferredHeight: Layout.preferredWidth

                        MaterialPlayerShape {
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            shapeMode: "cookie"
                            color: root.controlsBgColor
                            animated: false

                            DankIcon {
                                anchors.centerIn: parent
                                name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                                size: Math.max(22, Math.round(parent.width * 0.50))
                                color: Theme.onSurfaceColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playPause()
                        }
                    }

                    // Next Button: Circular Disc
                    Rectangle {
                        Layout.preferredWidth: Math.max(40 * Appearance.effectiveScale, card.height * 0.16)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: root.controlsBgColor

                        DankIcon {
                            anchors.centerIn: parent
                            name: "skip_next"
                            size: Math.max(18, Math.round(parent.width * 0.46))
                            color: Theme.onSurfaceColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextTrack()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // ── Bottom: Wavy Progress Bar above Elapsed / Total Time ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: Math.min(card.width - 32 * Appearance.effectiveScale, 220 * Appearance.effectiveScale)
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6 * Appearance.effectiveScale

                    MediaSeekBar {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(card.width - 32 * Appearance.effectiveScale, 220 * Appearance.effectiveScale)
                        implicitHeight: 18
                        activePlayer: root.activePlayer
                        fillColor: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.45)
                        trackColor: Qt.rgba(Theme.onSurfaceColor.r, Theme.onSurfaceColor.g, Theme.onSurfaceColor.b, 0.20)
                        textColor: "transparent"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.formatTime(root.currentPosition) + " / " + root.formatTime(root.trackLength)
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(card.height * 0.055))
                        font.weight: Font.Medium
                        color: Theme.onSurfaceVariantColor
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
        // ═════════════════════════════════════════════════════════════════════
        // STYLE 5: Floating Scalloped Cookie Silhouette Player
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: floatingCookieContent
            anchors.fill: parent
            visible: root.styleMode === 5

            // Background Shadow for the Scalloped Cookie
            Item {
                anchors.fill: parent
                anchors.topMargin: 4 * Appearance.effectiveScale

                MaterialPlayerShape {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) * 0.94
                    height: width
                    shapeMode: "cookie"
                    color: Qt.rgba(0, 0, 0, 0.45)
                    animated: false
                }
            }

            // Main Scalloped Cookie Disc Container
            Item {
                id: cookieDisc
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.94
                height: width

                // Base Cookie Shape
                MaterialPlayerShape {
                    id: cookieDiscBase
                    anchors.fill: parent
                    shapeMode: "cookie"
                    color: root.cardBgColor
                    animated: false
                }

                // Masked Album Art / Themed Silhouette Inside Cookie
                Item {
                    id: cookieDiscArtContainer
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: MaterialPlayerShape {
                            width: cookieDiscArtContainer.width
                            height: cookieDiscArtContainer.height
                            shapeMode: "cookie"
                            animated: false
                        }
                    }

                    // Album Art Image (if playing / downloaded)
                    Image {
                        anchors.fill: parent
                        source: root.artDownloaded && root.artFilePath !== "" ? root.artFilePath : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: root.artDownloaded && root.artFilePath !== ""
                    }

                    // Fallback Vector Silhouette / Art when no cover image
                    Item {
                        anchors.fill: parent
                        visible: !root.artDownloaded || root.artFilePath === ""

                        DankIcon {
                            anchors.centerIn: parent
                            name: "headphones"
                            size: Math.round(parent.width * 0.60)
                            color: Theme.onSurfaceColor
                            opacity: 0.35
                        }

                        DankIcon {
                            anchors.right: parent.right
                            anchors.rightMargin: parent.width * 0.12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: parent.height * 0.12
                            name: "music_note"
                            size: Math.round(parent.width * 0.32)
                            color: Theme.onSurfaceColor
                            opacity: 0.25
                        }
                    }

                    // Subtle darkening overlay
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, (root.artDownloaded && root.artFilePath !== "") ? 0.30 : 0.05)
                    }
                }
            }

            // ── Top-Right Stadium Pill: Skip Previous & Skip Next ──
            Rectangle {
                id: pillTrackNav
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 8 * Appearance.effectiveScale
                anchors.topMargin: 12 * Appearance.effectiveScale
                width: Math.max(86 * Appearance.effectiveScale, parent.width * 0.38)
                height: Math.max(38 * Appearance.effectiveScale, parent.height * 0.17)
                radius: height / 2
                color: root.controlsBgColor
                clip: true

                // Drop Shadow for Floating Pill
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    anchors.topMargin: 2
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.30)
                    z: -1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6 * Appearance.effectiveScale
                    anchors.rightMargin: 6 * Appearance.effectiveScale
                    spacing: 4 * Appearance.effectiveScale

                    // Previous Track
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        color: "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "skip_previous"
                            size: Math.max(16, Math.round(parent.height * 0.48))
                            color: Theme.onSurfaceColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevTrack()
                        }
                    }

                    // Next Track
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        color: "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: "skip_next"
                            size: Math.max(16, Math.round(parent.height * 0.48))
                            color: Theme.onSurfaceColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextTrack()
                        }
                    }
                }
            }

            // ── Bottom-Left Circular Disc: Play / Pause Button ──
            Rectangle {
                id: circularPlayBtn
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8 * Appearance.effectiveScale
                anchors.bottomMargin: 14 * Appearance.effectiveScale
                width: Math.max(62 * Appearance.effectiveScale, parent.width * 0.28)
                height: width
                radius: width / 2
                color: root.controlsBgColor

                // Drop Shadow for Floating Circular Button
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    anchors.topMargin: 3
                    radius: parent.radius
                    color: Qt.rgba(0, 0, 0, 0.30)
                    z: -1
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                    size: Math.max(26, Math.round(parent.width * 0.52))
                    color: Theme.onSurfaceColor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playPause()
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        // STYLE 6: Lockscreen Media Player Style (Rotating CAVA Morphing Album Art + Wave Visualizer + Lockscreen Controls)
        // ═════════════════════════════════════════════════════════════════════
        Item {
            id: lockscreenStyleContent
            anchors.fill: parent
            visible: root.styleMode === 6

            // Blurred Album Art Background
            Image {
                id: lockscreenBgArt
                anchors.fill: parent
                source: root.artDownloaded && root.artFilePath !== "" ? root.artFilePath : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            FastBlur {
                id: lockscreenBlurredBg
                anchors.fill: parent
                source: lockscreenBgArt
                radius: 40
                z: 0
                visible: root.artDownloaded && root.artFilePath !== ""
                opacity: 0.25

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: lockscreenBlurredBg.width
                        height: lockscreenBlurredBg.height
                        radius: Theme.rounding.large
                    }
                }
            }

            Item {
                id: lockscreenWaveMask
                anchors.fill: parent
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding.large
                    color: "white"
                }
            }

            WaveVisualizer {
                id: lockscreenOceanWave
                anchors.fill: parent
                z: 1
                opacity: (root.activePlayer && root.activePlayer.isPlaying) ? 0.35 : 0.1
                waveColor: root.activeAccentColor
                active: (root.activePlayer && root.activePlayer.isPlaying)
                maskSource: lockscreenWaveMask
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                z: 2

                // Left: Rotating Album Art with Cava morphing visualizer
                Item {
                    Layout.preferredWidth: parent.height
                    Layout.preferredHeight: parent.height
                    Layout.alignment: Qt.AlignVCenter

                    DankAlbumArt {
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: parent
                        activePlayer: root.activePlayer
                        showAnimation: true
                    }
                }

                // Right: Song Info, Lockscreen MediaSeekBar, and Controls Row
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4 * Appearance.effectiveScale

                    // Title & Artist
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true

                        Label {
                            Layout.fillWidth: true
                            text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                                ? root.trackTitle
                                : "No Title"
                            color: root.activeAccentColor
                            font.family: Theme.font.family
                            font.pixelSize: Math.max(15, Math.round(card.height * 0.125))
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            text: (root.activePlayer && root.activePlayer.trackTitle && root.activePlayer.trackTitle.trim().length > 0)
                                ? root.trackArtist
                                : "Unknown Artist"
                            color: Theme.outline
                            font.family: Theme.font.family
                            font.pixelSize: Math.max(12, Math.round(card.height * 0.09))
                            elide: Text.ElideRight
                        }
                    }

                    // Lockscreen MediaSeekBar
                    MediaSeekBar {
                        Layout.fillWidth: true
                        activePlayer: root.activePlayer
                        fillColor: root.activeAccentColor
                        trackColor: Qt.rgba(root.activeAccentColor.r, root.activeAccentColor.g, root.activeAccentColor.b, 0.18)
                        textColor: Theme.outline
                        z: 2
                    }

                    // Controls Row (Previous, Play/Pause, Next)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 24 * Appearance.effectiveScale

                        DankIcon {
                            name: "skip_previous"
                            size: 24 * Appearance.effectiveScale
                            color: root.activeAccentColor
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.prevTrack()
                            }
                        }

                        DankIcon {
                            name: (root.activePlayer && root.activePlayer.isPlaying) ? "pause" : "play_arrow"
                            size: 30 * Appearance.effectiveScale
                            color: root.activeAccentColor
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.playPause()
                            }
                        }

                        DankIcon {
                            name: "skip_next"
                            size: 24 * Appearance.effectiveScale
                            color: root.activeAccentColor
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nextTrack()
                            }
                        }
                    }
                }
            }
        }
    }

    WidgetResizeFrame {
        id: resizeFrame
        target: root
        widgetName: "Media Player"
        minWidth: (root.styleMode === 5 ? 200 : (root.styleMode === 4 ? 220 : (root.styleMode === 3 ? 280 : (root.styleMode === 2 ? 300 : 320)))) * Appearance.effectiveScale
        minHeight: (root.styleMode === 1 && root.showLyrics) ? (240 * Appearance.effectiveScale) : root.compactHeight
        maxHeight: (root.styleMode === 1 && root.showLyrics) ? (800 * Appearance.effectiveScale) : (root.styleMode >= 4 ? 400 * Appearance.effectiveScale : root.compactHeight)
        maxWidth: 1000 * Appearance.effectiveScale

        onResized: (newW, newH) => {
            root.customWidth = Math.round(newW / Appearance.effectiveScale);
            if (root.showLyrics) {
                root.customLyricsHeight = Math.round(newH / Appearance.effectiveScale);
            }
        }
        onResizeEnded: (finalW, finalH) => {
            root.customWidth = Math.round(finalW / Appearance.effectiveScale);
            if (root.showLyrics) {
                root.customLyricsHeight = Math.round(finalH / Appearance.effectiveScale);
            }
            root.saveSettings(root.x, root.y, root.showLyrics, root.customWidth, root.customLyricsHeight);
        }
        onResetRequested: {
            root.customWidth = -1;
            root.customLyricsHeight = 384;
            root.saveSettings(root.x, root.y, root.showLyrics, -1, 384);
        }
    }
}
