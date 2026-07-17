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

PanelWindow {
    id: clipboardWindow

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); clipboardWindow.glassmorphism = true; } catch(e) { clipboardWindow.glassmorphism = false; } }
        onLoaded: clipboardWindow.glassmorphism = true
        onLoadFailed: clipboardWindow.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }


    property var allHistory: []
    
    function filterHistory() {
        historyModel.clear();
        var query = searchInput.text.toLowerCase().trim();
        
        var showOnlyImages = (query === ">i" || query === ">img" || query.startsWith(">i ") || query.startsWith(">img "));
        
        // Extract the search query after the prefix if present
        var actualQuery = query;
        if (showOnlyImages) {
            if (query.startsWith(">img")) {
                actualQuery = query.substring(4).trim();
            } else if (query.startsWith(">i")) {
                actualQuery = query.substring(2).trim();
            }
        }

        for (var i = 0; i < allHistory.length; i++) {
            var item = allHistory[i];
            
            if (showOnlyImages) {
                if (item.isImage) {
                    if (actualQuery === "" || item.displayContent.toLowerCase().includes(actualQuery)) {
                        historyModel.append(item);
                    }
                }
            } else {
                if (query === "" || item.displayContent.toLowerCase().includes(query)) {
                    historyModel.append(item);
                }
            }
        }
        if (listview) listview.currentIndex = 0;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-clipboard"
    
    WlrLayershell.keyboardFocus: ClipboardService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: ClipboardService.visible

    onVisibleChanged: {
        if (visible) {
            loadHistory();
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }

    Connections {
        target: ClipboardService
        function onRequestOpen() {
            cursorposProc.running = true;
        }
        function onRequestToggle() {
            if (clipboardWindow.visible) {
                ClipboardService.close();
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
                    if (clipboardWindow.screen) {
                        screenWidth = clipboardWindow.screen.width;
                        screenHeight = clipboardWindow.screen.height;
                    }
                    
                    // Position safely within screen limits
                    var posX = Math.max(10, Math.min(x, screenWidth - cardContainer.width - 10));
                    var posY = Math.max(10, Math.min(y, screenHeight - cardContainer.height - 10));
                    
                    cardContainer.x = posX;
                    cardContainer.y = posY;
                }
                ClipboardService.visible = true;
            }
        }
    }

    // List model to store parsed clipboard history
    ListModel {
        id: historyModel
    }

    // Process to list clipboard items
    Process {
        id: listProc
        command: ["cliphist", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                parseHistory(this.text);
            }
        }
    }

    // Process to delete a clipboard item
    Process {
        id: deleteProc
        running: false
    }

    function loadHistory() {
        if (!listProc.running) {
            listProc.running = true;
        }
    }

    function cacheImage(id) {
        var cachePath = "/home/sawmer/.cache/quickshell-clipboard/" + id + ".png";
        var cmd = "mkdir -p /home/sawmer/.cache/quickshell-clipboard && cliphist decode \"$1\" > \"$2\"";
        Quickshell.execDetached(["bash", "-c", cmd, "_", id, cachePath]);
    }

    function parseHistory(rawText) {
        historyModel.clear();
        clipboardWindow.allHistory = [];
        if (!rawText) return;
        
        var lines = rawText.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (!line.trim()) continue;
            
            var tabIdx = line.indexOf("\t");
            if (tabIdx === -1) continue;
            
            var id = line.substring(0, tabIdx).trim();
            var content = line.substring(tabIdx + 1);
            var isBinary = content.includes("[[ binary data");
            
            if (isBinary) {
                cacheImage(id);
            }

            clipboardWindow.allHistory.push({
                "itemId": id,
                "displayContent": content,
                "isImage": isBinary
            });
        }
        clipboardWindow.filterHistory();
    }

    function copyItem(id, preview) {
        Quickshell.execDetached(["bash", "-c", "cliphist decode \"$1\" | wl-copy", "_", id]);
        
        // Show notification toast
        var notificationText = isImageText(preview) ? "Image copied to clipboard" : preview;
        if (notificationText.length > 40) {
            notificationText = notificationText.substring(0, 37) + "...";
        }
        Quickshell.execDetached(["notify-send", "-r", "1007", "-a", "Clipboard", "Copied to Clipboard", notificationText]);
        
        ClipboardService.close();
    }

    function deleteItem(id, preview) {
        // Construct the exact line expected by cliphist delete: id + \t + preview
        var rawLine = id + "\t" + preview;
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist delete", "_", rawLine]);
        // Reload after a brief delay to let cliphist update
        reloadTimer.start();
    }

    function clearAllHistory() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        Quickshell.execDetached(["notify-send", "-r", "1007", "-a", "Clipboard", "Clipboard Cleared", "All clipboard history has been wiped."]);
        reloadTimer.start();
    }

    function isImageText(txt) {
        return txt.includes("[[ binary data") || txt.endsWith("png") || txt.endsWith("jpg") || txt.endsWith("jpeg");
    }

    Timer {
        id: reloadTimer
        interval: 150
        repeat: false
        onTriggered: loadHistory()
    }

    // Keyboard navigation helper
    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                ClipboardService.close();
                event.accepted = true;
            }
        }

        // Click outside to close (transparent backdrop)
        MouseArea {
            anchors.fill: parent
            onClicked: ClipboardService.close()
        }

        // Card Container
        Item {
            id: cardContainer
            width: 380
            height: 580

            // Drop shadow
            DropShadow {
                anchors.fill: clipboardCard
                source: clipboardCard
                verticalOffset: 16
                radius: 48
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.45)
                transparentBorder: true
                cached: true
            }

            Rectangle {
                id: clipboardCard
                anchors.fill: parent
                radius: Theme.rounding.extraLarge
                color: clipboardWindow.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
                border.color: clipboardWindow.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1
                clip: true
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Glossy reflection overlay
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.height * 0.45
                    radius: parent.radius
                    visible: clipboardWindow.glassmorphism
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
                    height: 64
                    anchors.top: parent.top
                    cursorShape: Qt.OpenHandCursor
                    drag.target: cardContainer
                    drag.axis: Drag.XAndYAxis
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    // Header
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Clipboard History"
                            font.family: "Inter"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Clear All Button
                        QQC.Button {
                            id: clearBtn
                            background: Rectangle {
                                color: clearBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                                radius: 8
                                border.color: clearBtn.hovered ? Theme.error : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                DankIcon {
                                    name: "delete_sweep"
                                    size: 16
                                    color: Theme.error
                                }
                                Text {
                                    text: "Clear All"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Theme.error
                                }
                            }
                            onClicked: clearAllHistory()
                        }
                    }

                    // Search input box
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
                            border.color: searchInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
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
                            color: Theme.surfaceContainer
                            
                            Text {
                                id: labelText
                                anchors.centerIn: parent
                                text: "Clipboard"
                                font.pixelSize: 10
                                font.family: "Inter"
                                font.weight: Font.Medium
                                color: searchInput.activeFocus ? Theme.primary : Theme.outline
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
                                font.pixelSize: 14
                                clip: true
                                selectByMouse: true
                                selectionColor: Theme.primary
                                selectedTextColor: "#ffffff"
                                
                                 property string placeholderText: "Search history..."

                                 onTextChanged: clipboardWindow.filterHistory()

                                 Keys.onPressed: (event) => {
                                     if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                                         listview.forceActiveFocus();
                                         listview.currentIndex = 0;
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
                                width: 24; height: 24; radius: 12
                                visible: searchInput.text.length > 0
                                color: Qt.rgba(255, 255, 255, 0.1)

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 10
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

                     // Clipboard list
                     ListView {
                         id: listview
                         Layout.fillWidth: true
                         Layout.fillHeight: true
                         spacing: 8
                         clip: true
                         boundsBehavior: Flickable.StopAtBounds
                         focus: true
                         keyNavigationEnabled: true
                         highlightFollowsCurrentItem: true

                         Keys.onPressed: (event) => {
                             if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                 if (listview.currentIndex >= 0 && listview.currentIndex < listview.count) {
                                     var currentItem = historyModel.get(listview.currentIndex);
                                     if (currentItem) {
                                         copyItem(currentItem.itemId, currentItem.displayContent);
                                     }
                                 }
                                 event.accepted = true;
                             } else if (event.key === Qt.Key_Up && listview.currentIndex === 0) {
                                 searchInput.forceActiveFocus();
                                 event.accepted = true;
                             } else if (event.key === Qt.Key_PageUp) {
                                 searchInput.forceActiveFocus();
                                 event.accepted = true;
                             }
                         }

                         QQC.ScrollBar.vertical: QQC.ScrollBar {
                             policy: QQC.ScrollBar.AlwaysOff
                         }

                         model: historyModel

                         delegate: Rectangle {
                             id: delegateRoot
                             width: listview.width
                             height: 60
                             radius: 12
                             color: ((delegateRoot.ListView.isCurrentItem && listview.activeFocus) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : (delegateHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.03)))
                             border.color: (delegateRoot.ListView.isCurrentItem && listview.activeFocus) ? Theme.primary : Qt.rgba(255, 255, 255, 0.05)
                             border.width: 1

                             HoverHandler {
                                 id: delegateHover
                             }

                             MouseArea {
                                 id: itemMouse
                                 anchors.fill: parent
                                 hoverEnabled: true
                                 acceptedButtons: Qt.LeftButton
                                 cursorShape: Qt.PointingHandCursor
                                 onClicked: copyItem(itemId, displayContent)
                             }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 12

                                // Icon (Image or Text)
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: isImage ? Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.15) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    clip: true

                                    Image {
                                        id: previewImg
                                        visible: isImage
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        source: isImage ? "file:///home/sawmer/.cache/quickshell-clipboard/" + itemId + ".png" : ""
                                        cache: false
                                    }

                                    DankIcon {
                                        anchors.centerIn: parent
                                        visible: !isImage || previewImg.status !== Image.Ready
                                        name: isImage ? "image" : "description"
                                        size: 18
                                        color: isImage ? Theme.secondary : Theme.primary
                                    }
                                }

                                // Truncated preview text
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: isImage ? "Image Entry" : displayContent.trim()
                                        font.family: "Inter"
                                        font.pixelSize: 13
                                        font.weight: isImage ? Font.Medium : Font.Normal
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                    
                                    Text {
                                        text: isImage ? displayContent.trim() : "Text"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: Qt.rgba(255, 255, 255, 0.4)
                                    }
                                }

                                // Actions
                                RowLayout {
                                    spacing: 4
                                    visible: delegateHover.hovered

                                    // Delete Button
                                    QQC.Button {
                                        id: delBtn
                                        background: Rectangle {
                                            color: delBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                                            radius: 6
                                        }
                                        contentItem: DankIcon {
                                            name: "delete"
                                            size: 16
                                            color: Theme.error
                                        }
                                        onClicked: deleteItem(itemId, displayContent)
                                    }
                                }
                            }
                        }

                        // Empty State
                        ColumnLayout {
                            id: emptyPlaceholder
                            anchors.centerIn: parent
                            visible: historyModel.count === 0
                            spacing: 12

                            onVisibleChanged: {
                                if (visible && shapeBg && typeof shapeBg.randomizeShape === "function") {
                                    shapeBg.randomizeShape();
                                }
                            }

                            Item {
                                Layout.alignment: Qt.AlignCenter
                                implicitWidth: 80
                                implicitHeight: 80

                                MaterialShape {
                                    id: shapeBg
                                    anchors.fill: parent
                                    color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.5)
                                    
                                    readonly property var allowedShapes: [
                                        "square", "oval", "sunny", "very_sunny", 
                                        "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                                        "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                                    ]
                                    
                                    shape: "sunny"
                                    
                                    function randomizeShape() {
                                        var idx = Math.floor(Math.random() * allowedShapes.length);
                                        shape = allowedShapes[idx];
                                    }
                                    
                                    Component.onCompleted: randomizeShape()

                                    RotationAnimation on rotation {
                                        loops: Animation.Infinite
                                        from: 0; to: 360
                                        duration: 3000
                                        running: historyModel.count === 0 && clipboardWindow.visible
                                    }
                                }

                                DankIcon {
                                    id: clipboardEmptyIcon
                                    anchors.centerIn: parent
                                    name: "content_paste"
                                    size: 40
                                    color: "#ffffff"
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignCenter
                                text: "Clipboard is empty"
                                color: Qt.rgba(255, 255, 255, 0.4)
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }
        }
    }
}
