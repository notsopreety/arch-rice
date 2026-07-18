import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../theme"
import "../../services"
import "../../components"

PanelWindow {
    id: launcherWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.keyboardFocus: LauncherService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real cardWidth: 640
    property real cardHeight: 580

    // Dynamic Colors mapped directly to Theme singleton
    property color col_primary: Theme.primary
    property color col_on_primary: Theme.onPrimary
    property color col_surface: Theme.surface
    property color col_on_surface: "#ffffff"
    property color col_surface_container: Theme.surfaceContainer
    property color col_surface_container_high: Theme.surfaceContainerHigh
    property color col_surface_bright: Theme.surfaceBright
    property color col_outline: Theme.outline
    property color col_outline_variant: Theme.outlineVariant

    property color backdropColor: Qt.rgba(0, 0, 0, 0.55)
    property color cardBorderColor: Qt.rgba(col_outline.r, col_outline.g, col_outline.b, 0.15)
    property color hoverBgColor: Qt.rgba(col_primary.r, col_primary.g, col_primary.b, 0.12)
    property color searchBgColor: Qt.rgba(col_surface_bright.r, col_surface_bright.g, col_surface_bright.b, 0.5)
    property color searchIconColor: Qt.rgba(1, 1, 1, 0.6)
    property color searchBorderColor: Qt.rgba(col_outline_variant.r, col_outline_variant.g, col_outline_variant.b, 0.3)
    property color searchFocusBorderColor: Qt.rgba(col_primary.r, col_primary.g, col_primary.b, 0.6)
    property color placeholderColor: Qt.rgba(1, 1, 1, 0.4)
    property color textDimColor: "#ffffff"
    property color chipBorderColor: Qt.rgba(col_outline_variant.r, col_outline_variant.g, col_outline_variant.b, 0.5)
    property color chipTextColor: Qt.rgba(1, 1, 1, 0.7)

    // App Data
    property var appList: []
    property string searchText: ""
    property string selectedCategory: "All"

    property var categoryLabels: ["All", "Web", "System", "Utility", "Development", "Game", "Office"]

    property var categoryMap: ({
        "Web": ["Network", "WebBrowser", "InstantMessaging"],
        "System": ["System", "TerminalEmulator", "Settings", "DesktopSettings", "HardwareSettings", "Monitor", "Core", "Filesystem"],
        "Utility": ["Utility", "FileTools", "FileManager", "TextEditor", "Recorder", "Viewer", "ConsoleOnly"],
        "Development": ["Development", "IDE", "Building"],
        "Game": ["Game"],
        "Office": ["Office"]
    })

    property var categories: {
        var available = ["All"];
        var catSet = {};
        for (var i = 0; i < appList.length; i++) {
            var app = appList[i];
            if (app.categories) {
                var parts = app.categories.split(";");
                for (var j = 0; j < parts.length; j++) {
                    catSet[parts[j].trim()] = true;
                }
            }
        }
        for (var k = 1; k < categoryLabels.length; k++) {
            var label = categoryLabels[k];
            var mapped = categoryMap[label];
            for (var m = 0; m < mapped.length; m++) {
                if (catSet[mapped[m]]) { available.push(label); break; }
            }
        }
        return available;
    }

    property string _pendingQuery: ""
    property string _activeQuery: ""
    property string _activeCat: "All"

    // Glassmorphism Detector
    property bool glassmorphism: false
    FileView {
        id: glassmorphismFlagFile
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        preload: true
        watchChanges: true
        onFileChanged: glassmorphismReloadTimer.restart()
        Component.onCompleted: {
            try { glassmorphismFlagFile.reload(); launcherWindow.glassmorphism = true; } catch(e) { launcherWindow.glassmorphism = false; }
        }
        onLoaded: launcherWindow.glassmorphism = true
        onLoadFailed: launcherWindow.glassmorphism = false
    }
    Timer {
        id: glassmorphismReloadTimer
        interval: 200; repeat: false
        onTriggered: {
            try { glassmorphismFlagFile.reload(); } catch(e) {}
        }
    }

    property var filteredAppList: {
        var query = _activeQuery;
        var cat = _activeCat;
        if (query === "" && cat === "All") return appList;
        var mapped = cat === "All" ? null : categoryMap[cat];
        return appList.filter(function(app) {
            if (query !== "" && app.name.toLowerCase().indexOf(query) < 0) return false;
            if (cat !== "All") {
                var appCats = app.categories || "";
                for (var i = 0; i < mapped.length; i++) {
                    if (appCats.indexOf(mapped[i]) >= 0) return true;
                }
                return false;
            }
            return true;
        });
    }

    Timer {
        id: debounceTimer
        interval: 80
        onTriggered: {
            launcherWindow._activeQuery = launcherWindow._pendingQuery;
            launcherWindow._activeCat = launcherWindow.selectedCategory;
        }
    }

    onSearchTextChanged: {
        _pendingQuery = searchText.toLowerCase();
        debounceTimer.restart();
    }

    onSelectedCategoryChanged: {
        _pendingQuery = searchText.toLowerCase();
        _activeCat = selectedCategory;
        _activeQuery = _pendingQuery;
        debounceTimer.stop();
    }

    function launchApp(cmd, id, terminal) {
        if (terminal) {
            Quickshell.execDetached(["kitty", "-e", "bash", "-c", cmd]);
        } else if (id) {
            Quickshell.execDetached(["gtk-launch", id]);
        } else if (cmd) {
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
        LauncherService.close();
    }

    Process {
        id: appFetcher
        command: ["python3", Quickshell.shellPath("scripts/get_apps.py")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { launcherWindow.appList = JSON.parse(text); }
                catch (e) { console.error("Launcher: app fetch error", e); }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 120000 // Refresh every 2 minutes in background
        repeat: true
        running: true
        onTriggered: appFetcher.running = true
    }

    // Connect to LauncherService for visibility toggling
    Connections {
        target: LauncherService
        function onRequestOpen() {
            LauncherService.visible = true;
        }
        function onRequestToggle() {
            if (launcherWindow.visible) {
                LauncherService.close();
            } else {
                LauncherService.visible = true;
            }
        }
    }

    visible: LauncherService.visible

    property real animValue: 0.0

    Behavior on animValue {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    onVisibleChanged: {
        if (visible) {
            animValue = 1.0;
            searchText = "";
            searchInput.text = "";
            searchInput.forceActiveFocus();
        } else {
            animValue = 0.0;
        }
    }

    // Dim Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: launcherWindow.animValue * 0.3
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        TapHandler { onTapped: LauncherService.close() }
    }

    // Card Container
    Item {
        id: card
        anchors.centerIn: parent
        width: launcherWindow.cardWidth
        height: launcherWindow.cardHeight
        opacity: launcherWindow.animValue
        scale: 0.92 + (0.08 * launcherWindow.animValue)

        layer.enabled: true
        layer.smooth: false

        DropShadow {
            anchors.fill: cardBg
            source: cardBg
            verticalOffset: 16
            radius: 48
            samples: 65
            spread: 0.04
            color: Qt.rgba(0, 0, 0, 0.5)
            transparentBorder: true
            cached: true
        }

        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: 28
            color: launcherWindow.glassmorphism
                ? Qt.rgba(launcherWindow.col_surface.r, launcherWindow.col_surface.g, launcherWindow.col_surface.b, 0.22)
                : launcherWindow.col_surface
            border.color: launcherWindow.glassmorphism
                ? Qt.rgba(1, 1, 1, 0.18)
                : launcherWindow.col_outline_variant
            border.width: 1

            // Glassmorphic vertical gloss overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: launcherWindow.glassmorphism
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            MouseArea {
                anchors.fill: parent
                // Consume clicks so they don't fall through to the backdrop
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // Search Bar
                Item {
                    Layout.fillWidth: true
                    height: 52

                    // Outlined container Rectangle
                    Rectangle {
                        id: searchBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: searchInput.activeFocus ? launcherWindow.col_primary : launcherWindow.col_outline
                        border.width: searchInput.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                    }

                    // Floating Label overlapping top border
                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: labelText.implicitWidth + 8
                        color: launcherWindow.glassmorphism ? "transparent" : launcherWindow.col_surface
                        
                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: "Applications"
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.weight: Font.Medium
                            color: searchInput.activeFocus ? launcherWindow.col_primary : launcherWindow.col_outline
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 6
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        DankIcon {
                            name: "search"
                            size: 20
                            color: searchInput.activeFocus ? launcherWindow.col_primary : launcherWindow.col_outline
                            Layout.alignment: Qt.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 15
                            font.family: "Inter"
                            color: launcherWindow.col_on_surface
                            selectionColor: Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.3)
                            clip: true

                            Text {
                                text: "Search apps..."
                                color: placeholderColor
                                visible: !searchInput.text
                                anchors.verticalCenter: parent.verticalCenter
                                font: searchInput.font
                            }

                            onTextChanged: launcherWindow.searchText = text
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Escape) {
                                    LauncherService.close();
                                } else if (event.key === Qt.Key_Down) {
                                    grid.forceActiveFocus();
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (text.startsWith(">")) {
                                        var cmd = text.substring(1).trim();
                                        if (cmd.length > 0) {
                                            Quickshell.execDetached(["sh", "-c", cmd]);
                                            LauncherService.close();
                                        }
                                    } else if (launcherWindow.filteredApps && launcherWindow.filteredApps.length > 0) {
                                        var firstApp = launcherWindow.filteredApps[0];
                                        launcherWindow.launchApp(firstApp.cmd, firstApp.id, firstApp.terminal);
                                    }
                                }
                            }
                        }

                        Row {
                            spacing: 4
                            Rectangle {
                                width: 24; height: 24; radius: 12
                                visible: searchInput.text.length > 0
                                color: Qt.rgba(launcherWindow.col_on_surface.r, launcherWindow.col_on_surface.g, launcherWindow.col_on_surface.b, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 10
                                    color: Qt.rgba(launcherWindow.col_on_surface.r, launcherWindow.col_on_surface.g, launcherWindow.col_on_surface.b, 0.6)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { searchInput.text = ""; searchInput.forceActiveFocus(); }
                                }
                            }

                            // Clipboard Button
                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: clipboardMa.containsMouse ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.15) : "transparent"
                                
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "content_paste"
                                    size: 18
                                    color: clipboardMa.containsMouse ? launcherWindow.col_primary : launcherWindow.col_outline
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                
                                MouseArea {
                                    id: clipboardMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        LauncherService.close();
                                        ClipboardService.toggle();
                                    }
                                }
                            }

                            // Emoji Picker Button
                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: emojiMa.containsMouse ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.15) : "transparent"
                                
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "sentiment_satisfied"
                                    size: 18
                                    color: emojiMa.containsMouse ? launcherWindow.col_primary : launcherWindow.col_outline
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                
                                MouseArea {
                                    id: emojiMa
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        LauncherService.close();
                                        EmojiService.toggle();
                                    }
                                }
                            }
                        }
                    }
                }

                // Category Chips
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: categories.length > 1
                    clip: true

                    Repeater {
                        model: launcherWindow.categories

                        delegate: Item {
                            id: chip
                            height: 30
                            width: chipLabel.implicitWidth + 24

                            property bool isActive: launcherWindow.selectedCategory === modelData

                            transform: Scale {
                                origin.x: width / 2; origin.y: height / 2
                                xScale: chipMa.pressed ? 0.92 : 1.0
                                yScale: xScale
                                Behavior on xScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                id: chipBg
                                anchors.fill: parent
                                radius: 15
                                color: chip.isActive
                                    ? (chipMa.containsMouse ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.85) : launcherWindow.col_primary)
                                    : (chipMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
                                border.color: chip.isActive
                                    ? "transparent"
                                    : (chipMa.containsMouse ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.5) : chipBorderColor)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 180 } }
                                Behavior on border.color { ColorAnimation { duration: 180 } }

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 12
                                    font.weight: chip.isActive ? Font.Medium : Font.Normal
                                    color: chip.isActive ? launcherWindow.col_on_primary : (chipMa.containsMouse ? launcherWindow.col_primary : chipTextColor)
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { launcherWindow.selectedCategory = modelData; searchInput.forceActiveFocus(); }
                            }
                        }
                    }
                }

                // App Grid
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        anchors.topMargin: 4
                        cellWidth: 96
                        cellHeight: 100
                        cacheBuffer: 200

                        focus: true
                        keyNavigationEnabled: true
                        highlightFollowsCurrentItem: true

                        model: launcherWindow.filteredAppList

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100; easing.type: Easing.OutCubic }
                            NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: 120; easing.type: Easing.OutCubic }
                        }
                        remove: Transition {
                            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80; easing.type: Easing.InCubic }
                            NumberAnimation { property: "scale"; to: 0.85; duration: 80; easing.type: Easing.InCubic }
                        }
                        displaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 120; easing.type: Easing.OutCubic }
                        }
                        populate: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100; easing.type: Easing.OutCubic }
                        }

                        delegate: Item {
                            id: gridDelegate
                            width: grid.cellWidth
                            height: grid.cellHeight

                            transform: Scale {
                                origin.x: width / 2; origin.y: height / 2
                                xScale: ma.pressed ? 0.92 : 1.0
                                yScale: xScale
                                Behavior on xScale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                            }

                            // Morphing background (matches powermenu style)
                            Rectangle {
                                id: tileBg
                                anchors.centerIn: parent
                                width: 88; height: 88
                                radius: ma.containsMouse ? 24 : 16

                                color: (ma.containsMouse || (gridDelegate.GridView.isCurrentItem && grid.activeFocus))
                                    ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.15)
                                    : (launcherWindow.glassmorphism
                                        ? Qt.rgba(launcherWindow.col_surface_container_high.r, launcherWindow.col_surface_container_high.g, launcherWindow.col_surface_container_high.b, 0.4)
                                        : launcherWindow.col_surface_container_high)
                                border.color: (ma.containsMouse || (gridDelegate.GridView.isCurrentItem && grid.activeFocus))
                                    ? Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.35)
                                    : (launcherWindow.glassmorphism ? Qt.rgba(1, 1, 1, 0.06) : launcherWindow.col_outline_variant)
                                border.width: 1

                                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                                Behavior on border.color { ColorAnimation { duration: 180 } }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                // Icon container
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 42; height: 42

                                    MaterialShape {
                                        id: avatarBg
                                        anchors.centerIn: parent
                                        width: 42; height: 42
                                        
                                        // Allowed shapes for random hover transform
                                        readonly property var allowedShapes: [
                                            "square", "oval", "sunny", "very_sunny", 
                                            "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                                            "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                                        ]
                                        property string hoverShape: "square"
                                        
                                        shape: ma.containsMouse ? hoverShape : "circle"
                                        color: Qt.rgba(launcherWindow.col_primary.r, launcherWindow.col_primary.g, launcherWindow.col_primary.b, 0.18)
                                        z: 1

                                        // Custom scale transition on hover
                                        scale: ma.containsMouse ? 1.12 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                                        // Dynamic rotation animation on hover
                                        RotationAnimation on rotation {
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 2200
                                            running: ma.containsMouse
                                        }
                                    }

                                    Item {
                                        anchors.centerIn: parent
                                        width: 32; height: 32
                                        z: 2

                                        transform: [
                                            Rotation {
                                                id: iconWobble
                                                origin.x: 16; origin.y: 16
                                                angle: 0
                                            },
                                            Scale {
                                                origin.x: 16; origin.y: 16
                                                xScale: ma.containsMouse ? 1.15 : 1.0
                                                yScale: xScale
                                                Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                            }
                                        ]

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.icon
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectFit
                                            smooth: false
                                        }

                                        // Icon wiggle animation on hover
                                        SequentialAnimation {
                                            running: ma.containsMouse
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
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: 70
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.family: "sans-serif"
                                    font.weight: ma.containsMouse ? Font.Medium : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: ma.containsMouse ? launcherWindow.col_primary : textDimColor
                                    lineHeight: 1.2
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.launchApp(modelData.cmd, modelData.id, modelData.terminal)
                                onEntered: {
                                    avatarBg.hoverShape = avatarBg.allowedShapes[Math.floor(Math.random() * avatarBg.allowedShapes.length)]
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 4
                            background: Rectangle { color: "transparent" }
                            contentItem: Rectangle {
                                radius: 2
                                color: Qt.rgba(launcherWindow.col_on_surface.r, launcherWindow.col_on_surface.g, launcherWindow.col_on_surface.b, 0.2)
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) LauncherService.close();
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (currentIndex >= 0 && currentIndex < model.length) {
                                    launcherWindow.launchApp(model[currentIndex].cmd, model[currentIndex].id, model[currentIndex].terminal);
                                }
                            } else if (event.key === Qt.Key_Up && currentIndex < Math.floor(grid.width / grid.cellWidth)) {
                                searchInput.forceActiveFocus();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                var cols = Math.floor(grid.width / grid.cellWidth);
                                var rows = Math.floor(grid.height / grid.cellHeight);
                                currentIndex = Math.max(0, currentIndex - (cols * rows));
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                var cols = Math.floor(grid.width / grid.cellWidth);
                                var rows = Math.floor(grid.height / grid.cellHeight);
                                currentIndex = Math.min(model.length - 1, currentIndex + (cols * rows));
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                LauncherService.close();
                event.accepted = true;
            }
        }
    }
}
