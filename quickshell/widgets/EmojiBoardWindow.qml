import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"
import "../core"

PanelWindow {
    id: emojiBoardWindow

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); emojiBoardWindow.glassmorphism = true; } catch(e) { emojiBoardWindow.glassmorphism = false; } }
        onLoaded: emojiBoardWindow.glassmorphism = true
        onLoadFailed: emojiBoardWindow.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }


    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-emojiboard"
    
    WlrLayershell.keyboardFocus: EmojiService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: EmojiService.visible

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    // Load emojis.json using FileView
    FileView {
        id: jsonFile
        path: "/home/sawmer/.config/quickshell/assets/emojis.json"
        
        function loadData() {
            var raw = text();
            if (raw) {
                try {
                    var obj = JSON.parse(raw);
                    emojiBoardWindow.allEmojis = obj.emojis || [];
                } catch (e) {
                    console.error("Error parsing emojis.json:", e);
                }
            }
        }
        
        onLoaded: loadData()
        onFileChanged: loadData()
    }

    property var allEmojis: []

    // Filter emojis based on search input
    property string searchPrefix: searchInput.text.toLowerCase().trim()
    property var filteredEmojis: {
        if (searchPrefix === "") {
            return allEmojis;
        }
        return allEmojis.filter(item => 
            item && (
                (item.name && item.name.toLowerCase().includes(searchPrefix)) || 
                (item.shortname && item.shortname.toLowerCase().includes(searchPrefix))
            )
        );
    }

    Connections {
        target: EmojiService
        function onRequestOpen() {
            cursorposProc.running = true;
        }
        function onRequestToggle() {
            if (emojiBoardWindow.visible) {
                EmojiService.close();
            } else {
                cursorposProc.running = true;
            }
        }
    }

    Process {
        id: cursorposProc
        command: ["hyprctl", "cursorpos"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var coords = this.text.trim().split(",");
                if (coords.length === 2) {
                    var x = parseInt(coords[0].trim());
                    var y = parseInt(coords[1].trim());
                    
                    var screenWidth = 1920;
                    var screenHeight = 1080;
                    if (emojiBoardWindow.screen) {
                        screenWidth = emojiBoardWindow.screen.width;
                        screenHeight = emojiBoardWindow.screen.height;
                    }
                    
                    // Position safely within screen limits
                    var posX = Math.max(10, Math.min(x, screenWidth - cardContainer.width - 10));
                    var posY = Math.max(10, Math.min(y, screenHeight - cardContainer.height - 10));
                    
                    cardContainer.x = posX;
                    cardContainer.y = posY;
                }
                EmojiService.visible = true;
            }
        }
    }

    function selectEmoji(emoji) {
        Quickshell.execDetached(["wl-copy", emoji]);
        EmojiService.close();
    }

    // Keyboard navigation helper
    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                EmojiService.close();
                event.accepted = true;
            }
        }

        // Click outside to close (transparent backdrop)
        MouseArea {
            anchors.fill: parent
            onClicked: EmojiService.close()
        }

        // Card Container
        Item {
            id: cardContainer
            width: 380 * Appearance.effectiveScale
            height: 520 * Appearance.effectiveScale

            // Drop shadow
            DropShadow {
                anchors.fill: boardCard
                source: boardCard
                verticalOffset: 16 * Appearance.effectiveScale
                radius: 48 * Appearance.effectiveScale
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.45)
                transparentBorder: true
                cached: true
            }

            Rectangle {
                id: boardCard
                anchors.fill: parent
                radius: Theme.rounding.extraLarge
                color: emojiBoardWindow.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
                border.color: emojiBoardWindow.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1
                clip: true
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Glossy reflection overlay
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.height * 0.45
                    radius: parent.radius
                    visible: emojiBoardWindow.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                    }
                    border.color: "transparent"
                    z: 999
                }

                // Block clicks on the card itself to prevent closing on clicking empty space
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                // Top drag handle (first 64px of the card)
                MouseArea {
                    width: parent.width
                    height: 64 * Appearance.effectiveScale
                    anchors.top: parent.top
                    cursorShape: Qt.OpenHandCursor
                    drag.target: cardContainer
                    drag.axis: Drag.XAndYAxis
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    // Header
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Emoji Board"
                            font.family: "Inter"
                            font.pixelSize: 20 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }
                    }

                    // Search input box
                    Item {
                        Layout.fillWidth: true
                        height: 52 * Appearance.effectiveScale

                        // Outlined container Rectangle
                        Rectangle {
                            id: searchBg
                            anchors.fill: parent
                            anchors.topMargin: 6 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                            color: "transparent"
                            border.color: searchInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: searchInput.activeFocus ? 2 : 1
                            Behavior on border.color { ColorAnimation { duration: 180 } }
                            Behavior on border.width { NumberAnimation { duration: 180 } }
                        }

                        // Floating Label overlapping top border
                        Rectangle {
                            x: 12 * Appearance.effectiveScale
                            y: 0
                            height: 14 * Appearance.effectiveScale
                            width: labelText.implicitWidth + 8 * Appearance.effectiveScale
                            color: Theme.surfaceContainer
                            
                            Text {
                                id: labelText
                                anchors.centerIn: parent
                                text: "Emojis"
                                font.pixelSize: 10
                                font.family: "Inter"
                                font.weight: Font.Medium
                                color: searchInput.activeFocus ? Theme.primary : Theme.outline
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.topMargin: 6 * Appearance.effectiveScale
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 10 * Appearance.effectiveScale

                            DankIcon {
                                name: "search"
                                size: 20 * Appearance.effectiveScale
                                color: searchInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 14 * Appearance.effectiveScale
                                clip: true
                                selectByMouse: true
                                selectionColor: Theme.primary
                                selectedTextColor: "#ffffff"
                                
                                property string placeholderText: "Search emojis..."
                                
                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                                        gridview.forceActiveFocus();
                                        gridview.currentIndex = 0;
                                        event.accepted = true;
                                    }
                                }

                                Text {
                                    text: searchInput.placeholderText
                                    color: Qt.rgba(255, 255, 255, 0.35)
                                    font: searchInput.font
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }
                            }

                            Rectangle {
                                width: 24 * Appearance.effectiveScale; height: 24 * Appearance.effectiveScale; radius: 12 * Appearance.effectiveScale
                                visible: searchInput.text.length > 0
                                color: Qt.rgba(255, 255, 255, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 10 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { searchInput.text = ""; searchInput.forceActiveFocus(); }
                                }
                            }
                        }
                    }

                    // Wrapper to resolve Layout anchors warning
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // GridView of Emojis
                        GridView {
                            id: gridview
                            anchors.fill: parent
                            clip: true
                            cellWidth: 41.5 * Appearance.effectiveScale
                            cellHeight: 44 * Appearance.effectiveScale
                            boundsBehavior: Flickable.StopAtBounds
                            focus: true
                            keyNavigationEnabled: true
                            highlightFollowsCurrentItem: true

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (gridview.currentIndex >= 0 && gridview.currentIndex < gridview.count) {
                                        var currentEmoji = emojiBoardWindow.filteredEmojis[gridview.currentIndex];
                                        if (currentEmoji) {
                                            selectEmoji(currentEmoji.emoji);
                                        }
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up && gridview.currentIndex < 8) {
                                    searchInput.forceActiveFocus();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_PageUp) {
                                    var cols = Math.floor(gridview.width / gridview.cellWidth);
                                    var rows = Math.floor(gridview.height / gridview.cellHeight);
                                    var jump = cols * rows;
                                    if (gridview.currentIndex < jump) {
                                        gridview.currentIndex = 0;
                                        searchInput.forceActiveFocus();
                                    } else {
                                        gridview.currentIndex = Math.max(0, gridview.currentIndex - jump);
                                    }
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_PageDown) {
                                    var cols2 = Math.floor(gridview.width / gridview.cellWidth);
                                    var rows2 = Math.floor(gridview.height / gridview.cellHeight);
                                    gridview.currentIndex = Math.min(gridview.count - 1, gridview.currentIndex + (cols2 * rows2));
                                    event.accepted = true;
                                }
                            }

                            QQC.ScrollBar.vertical: QQC.ScrollBar {
                                policy: QQC.ScrollBar.AlwaysOff
                            }

                            model: emojiBoardWindow.filteredEmojis

                            delegate: Rectangle {
                                id: delegateRoot
                                width: gridview.cellWidth
                                height: gridview.cellHeight
                                color: (delegateRoot.GridView.isCurrentItem && gridview.activeFocus) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
                                border.color: (delegateRoot.GridView.isCurrentItem && gridview.activeFocus) ? Theme.primary : "transparent"
                                border.width: 1
                                radius: 8 * Appearance.effectiveScale

                                // Press scaling animation
                                scale: itemMouse.pressed ? 0.88 : ((itemMouse.containsMouse || (delegateRoot.GridView.isCurrentItem && gridview.activeFocus)) ? 1.12 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.emoji
                                    font.pixelSize: 22 * Appearance.effectiveScale
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                 QQC.ToolTip {
                                     id: tooltip
                                     visible: itemMouse.containsMouse || (delegateRoot.GridView.isCurrentItem && gridview.activeFocus)
                                     delay: 400
                                     text: modelData.name ? modelData.name.replace(/\b\w/g, c => c.toUpperCase()) : ""
                                     
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
                                         font.pixelSize: 11 * Appearance.effectiveScale
                                         font.weight: Font.Medium
                                     }

                                     background: Rectangle {
                                         color: Theme.surfaceContainer
                                         radius: 8 * Appearance.effectiveScale
                                         border.color: Theme.outline
                                         border.width: 1
                                         
                                         layer.enabled: true
                                         layer.effect: DropShadow {
                                             horizontalOffset: 0
                                             verticalOffset: 4 * Appearance.effectiveScale
                                             radius: 8 * Appearance.effectiveScale
                                             samples: 17
                                             color: Qt.rgba(0, 0, 0, 0.3)
                                         }
                                     }
                                 }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: selectEmoji(modelData.emoji)
                                }
                            }
                        }

                        // Empty State
                        Text {
                            anchors.centerIn: parent
                            visible: emojiBoardWindow.filteredEmojis.length === 0
                            text: "No emojis found"
                            color: Qt.rgba(255, 255, 255, 0.4)
                            font.family: "Inter"
                            font.pixelSize: 14 * Appearance.effectiveScale
                        }
                    }
                }
            }
        }
    }
}
