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
    id: keybindsWindow

    property var allBinds: []
    
    function filterBinds() {
        bindsModel.clear();
        var query = searchInput.text.toLowerCase().trim();
        for (var i = 0; i < allBinds.length; i++) {
            var item = allBinds[i];
            if (query === "" || item.keys.toLowerCase().includes(query) || item.desc.toLowerCase().includes(query) || item.cat.toLowerCase().includes(query)) {
                bindsModel.append(item);
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
    WlrLayershell.namespace: "quickshell-keybinds"
    
    WlrLayershell.keyboardFocus: KeybindsService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: KeybindsService.visible

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
            if (!fetchProc.running) fetchProc.running = true;
        }
    }

    Process {
        id: fetchProc
        command: ["python3", "/home/sawmer/.config/quickshell/scripts/parse_keybinds.py"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    keybindsWindow.allBinds = data;
                    keybindsWindow.filterBinds();
                } catch (e) {
                    console.log("Error parsing keybinds JSON: " + e);
                }
            }
        }
    }

    Connections {
        target: KeybindsService
        function onRequestOpen() {
            cursorposProc.running = true;
        }
        function onRequestToggle() {
            if (keybindsWindow.visible) {
                KeybindsService.close();
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
                    if (keybindsWindow.screen) {
                        screenWidth = keybindsWindow.screen.width;
                        screenHeight = keybindsWindow.screen.height;
                    }
                    
                    var posX = Math.max(10, Math.min(x, screenWidth - cardContainer.width - 10));
                    var posY = Math.max(10, Math.min(y, screenHeight - cardContainer.height - 10));
                    
                    cardContainer.x = posX;
                    cardContainer.y = posY;
                }
                KeybindsService.visible = true;
            }
        }
    }

    ListModel {
        id: bindsModel
    }

    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                KeybindsService.close();
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: KeybindsService.close()
        }

        Item {
            id: cardContainer
            width: 820
            height: 520

            DropShadow {
                anchors.fill: bindsCard
                source: bindsCard
                verticalOffset: 16
                radius: 48
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.45)
                transparentBorder: true
                cached: true
            }

            Rectangle {
                id: bindsCard
                anchors.fill: parent
                radius: Theme.rounding.extraLarge
                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                border.width: 1
                clip: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

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

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Text {
                            text: "Keybindings"
                            font.family: "Inter"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }
                        
                        Rectangle {
                            width: countText.implicitWidth + 16
                            height: 24
                            radius: 12
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
                            border.width: 1
                            
                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: bindsModel.count + " total"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.primary
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 52
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
                        Rectangle {
                            x: 12
                            y: 0
                            height: 14
                            width: labelText.implicitWidth + 8
                            color: Theme.surfaceContainer
                            Text {
                                id: labelText
                                anchors.centerIn: parent
                                text: "Search"
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
                                property string placeholderText: "Find keybind..."
                                
                                onTextChanged: keybindsWindow.filterBinds()
                                
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
                        }
                    }

                    GridView {
                        id: listview
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cellWidth: width / 2
                        cellHeight: 68
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        focus: true
                        keyNavigationEnabled: true

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Up && listview.currentIndex < 2) {
                                searchInput.forceActiveFocus();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                searchInput.forceActiveFocus();
                                event.accepted = true;
                            }
                        }

                        QQC.ScrollBar.vertical: QQC.ScrollBar { policy: QQC.ScrollBar.AlwaysOff }

                        model: bindsModel

                        delegate: Rectangle {
                            id: delegateRoot
                            width: listview.cellWidth - 12
                            height: 60
                            radius: 12
                            color: ((delegateRoot.GridView.isCurrentItem && listview.activeFocus) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.03))
                            border.color: (delegateRoot.GridView.isCurrentItem && listview.activeFocus) ? Theme.primary : Qt.rgba(255, 255, 255, 0.05)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    Text {
                                        anchors.centerIn: parent
                                        text: cat === "Quickshell" ? "󱓞" : (cat === "Window" ? "󰖲" : (cat === "Workspace" ? "󰲋" : "󰒓"))
                                        font.family: Theme.font.monospace
                                        font.pixelSize: 18
                                        color: Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text {
                                        Layout.fillWidth: true
                                        text: keys
                                        font.family: Theme.font.monospace
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: desc
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        color: Qt.rgba(255, 255, 255, 0.8)
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
