import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../core"
import "../../theme"
import "../../services"
import "../../components"
import "../"

PanelWindow {
    id: window

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-control-center"
    WlrLayershell.keyboardFocus: ControlCenterService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: ControlCenterService.visible || canvas.opacity > 0

    onVisibleChanged: {
        if (visible) {
            dashContent.forceActiveFocus();
        }
    }

    property bool editMode: false
    property var date: new Date()

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); window.glassmorphism = true; } catch(e) { window.glassmorphism = false; } }
        onLoaded: window.glassmorphism = true
        onLoadFailed: window.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    // Glassmorphic surface helpers
    readonly property color glassCanvasBg:        Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    0.35)
    readonly property color glassCardBg:          Qt.rgba(Theme.surfaceContainerHigh.r,Theme.surfaceContainerHigh.g,Theme.surfaceContainerHigh.b, 0.40)
    readonly property color glassActionBg:        Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    0.40)
    readonly property color glassBorder:          Qt.rgba(1, 1, 1, 0.18)

    // Solid (non-glass) surface helpers
    readonly property color solidCanvasBg:        Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    1.0)
    readonly property color solidCardBg:          Theme.surfaceContainerHigh
    readonly property color solidActionBg:        Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    1.0)
    readonly property color solidBorder:          Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

    // --- Media Player MPRIS State ---
    readonly property var textColor: "#ffffff"
    readonly property color primaryColor: Theme.primary
    readonly property color textMutedColor: "#e2e8f0"
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

    // --- Audio/Volume State ---
    readonly property real systemVolume: Audio.volume
    function setSystemVolume(vol) {
        Audio.setVolume(vol);
    }

    // --- Brightness State & Processes ---
    property real brightnessValue: 0.5
    property real brightnessMax: 1.0

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "get"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data.trim());
                if (!isNaN(val)) window.brightnessValue = val;
            }
        }
    }

    Process {
        id: brightnessMaxProc
        command: ["brightnessctl", "max"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var val = parseFloat(data.trim());
                if (!isNaN(val) && val > 0) window.brightnessMax = val;
            }
        }
    }

    Process {
        id: brightnessSetProc
        property string pendingValue: ""
        command: pendingValue !== "" ? ["brightnessctl", "set", pendingValue] : []
        running: false
    }

    function setBrightness(ratio) {
        var clamped = Math.max(0.01, Math.min(1.0, ratio));
        var raw = Math.round(clamped * window.brightnessMax);
        window.brightnessValue = raw;
        brightnessSetProc.pendingValue = String(raw);
        brightnessSetProc.running = true;
    }

    Timer {
        id: brightnessPoller
        interval: 2000
        running: ControlCenterService.visible
        repeat: true
        onTriggered: brightnessGetProc.running = true
    }

    Timer {
        id: dateTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: window.date = new Date()
    }

    FocusScope {
        id: dashContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                ControlCenterService.close();
                event.accepted = true;
            }
        }

        // Clicking the transparent background closes the window
        MouseArea {
            anchors.fill: parent
            onClicked: ControlCenterService.close()
        }

        // Floating Card Container (aligned right, below status bar)
        Rectangle {
            id: canvas
            width: 400
            height: {
                if (window.editMode) {
                    const baseHeight = 150 * Appearance.effectiveScale;
                    const gridHeight = widgetGrid.implicitHeight;
                    return Math.min(880 * Appearance.effectiveScale, Math.max(650 * Appearance.effectiveScale, baseHeight + gridHeight));
                } else {
                    return 650 * Appearance.effectiveScale;
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                }
            }
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 50 // Placed nicely below the top status bar

            radius: 24
            color: window.glassmorphism ? window.glassCanvasBg : window.solidCanvasBg
            border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
            border.width: 1
            clip: true
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on border.color { ColorAnimation { duration: 400 } }

            // Gloss overlay
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: parent.height * 0.45
                radius: parent.radius
                visible: window.glassmorphism
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.12) }
                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
                }
                border.color: "transparent"
                z: 999
            }

            transform: Translate {
                id: canvasTransform
            }

            states: [
                State {
                    name: "open"
                    when: ControlCenterService.visible
                    PropertyChanges { target: canvas; opacity: 1 }
                    PropertyChanges { target: canvasTransform; x: 0 }
                },
                State {
                    name: "closed"
                    when: !ControlCenterService.visible
                    PropertyChanges { target: canvas; opacity: 0 }
                    PropertyChanges { target: canvasTransform; x: canvas.width + 40 }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation {
                            target: canvasTransform
                            property: "x"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                        NumberAnimation {
                            target: canvas
                            property: "opacity"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.standard
                        }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation {
                            target: canvasTransform
                            property: "x"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: canvas
                            property: "opacity"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]

            // Click interceptor to prevent clicks on the card from closing it
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: (event) => { event.accepted = true; }
            }

            // Inside content layout
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                // ── Combined Header Section ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12 * Appearance.effectiveScale
                    Layout.topMargin: 4 * Appearance.effectiveScale
                    Layout.leftMargin: 4 * Appearance.effectiveScale
                    Layout.rightMargin: 4 * Appearance.effectiveScale

                    // Row 1: Time/Date & Action Buttons
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale

                            StyledText {
                                text: window.date.toLocaleTimeString(Qt.locale(), "hh:mm AP")
                                font.pixelSize: 28 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: "#ffffff" // Solid white text
                            }

                            StyledText {
                                text: window.date.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                                font.pixelSize: 13 * Appearance.effectiveScale
                                color: "#ffffff" // Solid white text
                                opacity: 0.8
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Right-side action buttons
                        Row {
                            spacing: 6 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            // Palette (Wallpaper selector) button
                            RippleButton {
                                id: paletteBtn
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: Qt.rgba(255, 255, 255, 0.1)
                                colBackgroundHover: Qt.rgba(255, 255, 255, 0.15)
                                colRipple: Theme.primary
                                onClicked: {
                                    ControlCenterService.close()
                                    WallpaperService.toggle()
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "palette"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: "#ffffff"
                                }
                                StyledToolTip { text: "Change Wallpaper" }
                            }

                            // Edit Mode toggle button
                            RippleButton {
                                id: editBtn
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: window.editMode ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                                colBackgroundHover: window.editMode ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                colRipple: Theme.primary
                                onClicked: window.editMode = !window.editMode
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: window.editMode ? "check" : "edit"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: window.editMode ? Theme.onPrimary : "#ffffff"
                                }
                                StyledToolTip { text: window.editMode ? "Done Editing" : "Edit Toggles" }
                            }

                            // System Settings button
                            RippleButton {
                                id: settingsBtn
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: Qt.rgba(255, 255, 255, 0.1)
                                colBackgroundHover: Qt.rgba(255, 255, 255, 0.15)
                                colRipple: Theme.primary
                                onClicked: {
                                    ControlCenterService.close()
                                    DankDashService.activeTab = 5
                                    DankDashService.visible = true
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "settings"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: "#ffffff"
                                }
                                StyledToolTip { text: "System Settings" }
                            }

                            // Power / Session menu button
                            RippleButton {
                                id: powerBtnTop
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                                colBackgroundHover: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.25)
                                colRipple: Theme.error
                                onClicked: {
                                    ControlCenterService.close()
                                    PowerMenuService.toggle()
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "power_settings_new"
                                    iconSize: 18 * Appearance.effectiveScale
                                    color: "#ff8993"
                                }
                                StyledToolTip { text: "Power Menu" }
                            }
                        }
                    }
                }

                // Separator Line below header combo
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                }

                // Flickable wrapper for scrollable area (Media Player, Sliders, and Widgets)
                Flickable {
                    id: flickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: scrollColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: scrollColumn
                        width: parent.width
                        spacing: 16 * Appearance.effectiveScale

                        // Row 2: Media Card + Volume/Brightness Sliders side by side
                        RowLayout {
                            id: mediaAndSlidersRow
                            width: parent.width
                            height: 165 * Appearance.effectiveScale
                            spacing: 10 * Appearance.effectiveScale
                            visible: !window.editMode // Hide during widget edit mode to keep focus on widgets

                    // Media Player Card
                    Rectangle {
                        id: mediaCard
                        Layout.preferredWidth: (widgetGrid.baseCellWidth * 2) + widgetGrid.toggleSpacing
                        Layout.fillWidth: false
                        Layout.preferredHeight: 165 * Appearance.effectiveScale
                        radius: 20 * Appearance.effectiveScale
                        color: window.glassmorphism ? window.glassCardBg : window.solidCardBg
                        border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
                        border.width: 1
                        clip: true
                        Behavior on color { ColorAnimation { duration: 400 } }
                        Behavior on border.color { ColorAnimation { duration: 400 } }

                        Image {
                            id: albumArtBg
                            anchors.fill: parent
                            source: (window.activePlayer && window.activePlayer.artUrl) ? window.activePlayer.artUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.15
                            visible: source !== ""
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 0.8
                            }
                        }

                        Rectangle {
                            id: mediaCardMask
                            anchors.fill: parent
                            radius: mediaCard.radius
                            color: "black"
                            visible: false
                        }

                        WaveVisualizer {
                            id: oceanWaveCC
                            anchors.fill: parent
                            waveColor: window.primaryColor
                            active: window.hasPlayer && window.activePlayer.playbackState === 1
                            visible: window.hasPlayer
                            waveYPercent: 0.65
                            maskSource: mediaCardMask
                            opacity: 0.15
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !window.hasPlayer
                                spacing: 4 * Appearance.effectiveScale
                                Layout.alignment: Qt.AlignCenter

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "music_note"
                                    iconSize: 28 * Appearance.effectiveScale
                                    color: Qt.rgba(1, 1, 1, 0.25)
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No Media playing"
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    color: window.textMutedColor
                                    opacity: 0.5
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: window.hasPlayer
                                spacing: 6 * Appearance.effectiveScale

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6 * Appearance.effectiveScale
                                    Layout.alignment: Qt.AlignLeft

                                    Item {
                                        width: 44 * Appearance.effectiveScale
                                        height: 44 * Appearance.effectiveScale
                                        clip: false
                                        Layout.alignment: Qt.AlignLeft
                                        Layout.leftMargin: 6 * Appearance.effectiveScale
                                        Layout.topMargin: 4 * Appearance.effectiveScale

                                        DankAlbumArt {
                                            anchors.fill: parent
                                            activePlayer: window.activePlayer
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1 * Appearance.effectiveScale
                                        Layout.alignment: Qt.AlignLeft

                                        StyledText {
                                            text: window.activePlayer ? (window.activePlayer.trackTitle || "Unknown") : ""
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            font.weight: Font.Bold
                                            color: window.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                        }

                                        StyledText {
                                            text: window.activePlayer ? (window.activePlayer.trackArtist || "Unknown Artist") : ""
                                            font.pixelSize: 10 * Appearance.effectiveScale
                                            color: window.textMutedColor
                                            opacity: 0.8
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 16 * Appearance.effectiveScale

                                    Rectangle {
                                        width: 28 * Appearance.effectiveScale
                                        height: 28 * Appearance.effectiveScale
                                        radius: 14 * Appearance.effectiveScale
                                        color: prevMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒮"
                                            font.family: Theme.font.monospace
                                            font.pixelSize: 16 * Appearance.effectiveScale
                                            color: window.textColor
                                        }

                                        MouseArea {
                                            id: prevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (window.activePlayer) window.activePlayer.previous()
                                        }
                                    }

                                    Rectangle {
                                        width: 36 * Appearance.effectiveScale
                                        height: 36 * Appearance.effectiveScale
                                        radius: 18 * Appearance.effectiveScale
                                        color: window.primaryColor

                                        Text {
                                            anchors.centerIn: parent
                                            text: (window.activePlayer && window.activePlayer.playbackState === 1) ? "󰏤" : "󰐊"
                                            font.family: Theme.font.monospace
                                            font.pixelSize: 18 * Appearance.effectiveScale
                                            color: "#000000"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (window.activePlayer) window.activePlayer.togglePlaying()
                                        }
                                    }

                                    Rectangle {
                                        width: 28 * Appearance.effectiveScale
                                        height: 28 * Appearance.effectiveScale
                                        radius: 14 * Appearance.effectiveScale
                                        color: nextMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰒭"
                                            font.family: Theme.font.monospace
                                            font.pixelSize: 16 * Appearance.effectiveScale
                                            color: window.textColor
                                        }

                                        MouseArea {
                                            id: nextMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (window.activePlayer) window.activePlayer.next()
                                        }
                                }
                            }
                        }
                    }
                }

                // Vertical Sliders Row (placed side by side with the Media Player Card)
                RowLayout {
                        Layout.fillWidth: false
                        Layout.preferredWidth: (widgetGrid.baseCellWidth * 2) + widgetGrid.toggleSpacing
                        Layout.fillHeight: true
                        spacing: 0

                        // Brightness Slider
                        Rectangle {
                            id: ccBrightnessPanel
                            width: 54 * Appearance.effectiveScale
                            height: 165 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter
                            radius: Appearance.rounding.normal
                            color: window.glassmorphism ? window.glassActionBg : window.solidActionBg
                            border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 400 } }
                            Behavior on border.color { ColorAnimation { duration: 400 } }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 6 * Appearance.effectiveScale

                                Item {
                                    id: ccBrightnessSlider
                                    width: parent.width * 0.8
                                    height: parent.height - 30 * Appearance.effectiveScale
                                    anchors.top: parent.top
                                    anchors.topMargin: 4 * Appearance.effectiveScale
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        width: parent.width
                                        height: parent.height
                                        anchors.centerIn: parent
                                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                        radius: Theme.rounding.small
                                    }

                                    Rectangle {
                                        readonly property real ratio: Brightness.brightness
                                        readonly property real thumbHeight: 4 * Appearance.effectiveScale
                                        width: parent.width
                                        height: Math.max(0, ratio * (parent.height - thumbHeight) - 3)
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Theme.primary
                                        radius: Theme.rounding.small
                                        topLeftRadius: 0
                                        topRightRadius: 0
                                    }

                                    MaterialSymbol {
                                        text: Brightness.brightness < 0.33 ? "brightness_low" : (Brightness.brightness < 0.66 ? "brightness_medium" : "brightness_high")
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Brightness.brightness >= 0.15 ? "#000000" : "#ffffff"
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 6 * Appearance.effectiveScale
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Rectangle {
                                        width: parent.width + 6 * Appearance.effectiveScale
                                        height: 4 * Appearance.effectiveScale
                                        radius: 2 * Appearance.effectiveScale
                                        y: {
                                            const ratio = Brightness.brightness;
                                            const travel = parent.height - height;
                                            return Math.max(0, Math.min(travel, travel * (1 - ratio)));
                                        }
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Theme.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -10 * Appearance.effectiveScale
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true

                                        onPressed: mouse => updateBrightness(mouse)
                                        onPositionChanged: mouse => {
                                            if (pressed) updateBrightness(mouse)
                                        }
                                        onClicked: mouse => updateBrightness(mouse)
                                        onWheel: (wheel) => {
                                            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                            Brightness.setBrightness(Brightness.brightness + step);
                                        }

                                        function updateBrightness(mouse) {
                                            var pct = 1.0 - (mouse.y / height);
                                            Brightness.setBrightness(Math.max(0.01, Math.min(1.0, pct)));
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 2 * Appearance.effectiveScale
                                    text: Math.round(Brightness.brightness * 100) + "%"
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Volume Slider
                        Rectangle {
                            id: ccVolumePanel
                            width: 54 * Appearance.effectiveScale
                            height: 165 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter
                            radius: Appearance.rounding.normal
                            color: window.glassmorphism ? window.glassActionBg : window.solidActionBg
                            border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 400 } }
                            Behavior on border.color { ColorAnimation { duration: 400 } }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 6 * Appearance.effectiveScale

                                Item {
                                    id: ccVolumeSlider
                                    width: parent.width * 0.8
                                    height: parent.height - 30 * Appearance.effectiveScale
                                    anchors.top: parent.top
                                    anchors.topMargin: 4 * Appearance.effectiveScale
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        width: parent.width
                                        height: parent.height
                                        anchors.centerIn: parent
                                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                        radius: Theme.rounding.small
                                    }

                                    Rectangle {
                                        readonly property real ratio: Math.min(1.0, Audio.volume)
                                        readonly property real thumbHeight: 4 * Appearance.effectiveScale
                                        width: parent.width
                                        height: Math.max(0, ratio * (parent.height - thumbHeight) - 3)
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Audio.muted ? "#808080" : Theme.primary
                                        radius: Theme.rounding.small
                                        topLeftRadius: 0
                                        topRightRadius: 0
                                    }

                                    MaterialSymbol {
                                        text: Audio.muted || Math.round(Audio.volume * 100) === 0 ? "volume_off" : (Audio.volume < 0.33 ? "volume_down" : (Audio.volume < 0.66 ? "volume_mute" : "volume_up"))
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Audio.volume >= 0.15 ? "#000000" : "#ffffff"
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 6 * Appearance.effectiveScale
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Rectangle {
                                        width: parent.width + 6 * Appearance.effectiveScale
                                        height: 4 * Appearance.effectiveScale
                                        radius: 2 * Appearance.effectiveScale
                                        y: {
                                            const ratio = Math.min(1.0, Audio.volume);
                                            const travel = parent.height - height;
                                            return Math.max(0, Math.min(travel, travel * (1 - ratio)));
                                        }
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Audio.muted ? "#808080" : Theme.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -10 * Appearance.effectiveScale
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true

                                        onPressed: mouse => updateVol(mouse)
                                        onPositionChanged: mouse => {
                                            if (pressed) updateVol(mouse)
                                        }
                                        onClicked: mouse => updateVol(mouse)
                                        onWheel: (wheel) => {
                                            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                            Audio.setVolume(Audio.volume + step);
                                        }

                                        function updateVol(mouse) {
                                            var pct = 1.0 - (mouse.y / height);
                                            Audio.setVolume(Math.max(0.0, Math.min(1.0, pct)));
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 2 * Appearance.effectiveScale
                                    text: Math.round(Audio.volume * 100) + "%"
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: Audio.muted ? "#808080" : "#ffffff"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Microphone Slider
                        Rectangle {
                            id: ccMicPanel
                            width: 54 * Appearance.effectiveScale
                            height: 165 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter
                            radius: Appearance.rounding.normal
                            color: window.glassmorphism ? window.glassActionBg : window.solidActionBg
                            border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 400 } }
                            Behavior on border.color { ColorAnimation { duration: 400 } }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 6 * Appearance.effectiveScale

                                Item {
                                    id: ccMicSlider
                                    width: parent.width * 0.8
                                    height: parent.height - 30 * Appearance.effectiveScale
                                    anchors.top: parent.top
                                    anchors.topMargin: 4 * Appearance.effectiveScale
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        width: parent.width
                                        height: parent.height
                                        anchors.centerIn: parent
                                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                                        radius: Theme.rounding.small
                                    }

                                    Rectangle {
                                        readonly property real ratio: Math.min(1.0, Audio.sourceVolume)
                                        readonly property real thumbHeight: 4 * Appearance.effectiveScale
                                        width: parent.width
                                        height: Math.max(0, ratio * (parent.height - thumbHeight) - 3)
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Audio.sourceMuted ? "#808080" : Theme.primary
                                        radius: Theme.rounding.small
                                        topLeftRadius: 0
                                        topRightRadius: 0
                                    }

                                    MaterialSymbol {
                                        text: Audio.sourceMuted ? "mic_off" : "mic"
                                        iconSize: 18 * Appearance.effectiveScale
                                        color: Audio.sourceVolume >= 0.15 ? "#000000" : "#ffffff"
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 6 * Appearance.effectiveScale
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Rectangle {
                                        width: parent.width + 6 * Appearance.effectiveScale
                                        height: 4 * Appearance.effectiveScale
                                        radius: 2 * Appearance.effectiveScale
                                        y: {
                                            const ratio = Math.min(1.0, Audio.sourceVolume);
                                            const travel = parent.height - height;
                                            return Math.max(0, Math.min(travel, travel * (1 - ratio)));
                                        }
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        color: Audio.sourceMuted ? "#808080" : Theme.primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -10 * Appearance.effectiveScale
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true

                                        onPressed: mouse => updateMic(mouse)
                                        onPositionChanged: mouse => {
                                            if (pressed) updateMic(mouse)
                                        }
                                        onClicked: mouse => updateMic(mouse)
                                        onWheel: (wheel) => {
                                            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                            Audio.setSourceVolume(Audio.sourceVolume + step);
                                        }

                                        function updateMic(mouse) {
                                            var pct = 1.0 - (mouse.y / height);
                                            Audio.setSourceVolume(Math.max(0.0, Math.min(1.0, pct)));
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 2 * Appearance.effectiveScale
                                    text: Math.round(Audio.sourceVolume * 100) + "%"
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: Audio.sourceMuted ? "#808080" : "#ffffff"
                                }
                            }
                        }
                    }
                }

                        WidgetGrid {
                            id: widgetGrid
                            width: parent.width
                            editMode: window.editMode
                        }
                    }
                }
            }
        }
    }
}
