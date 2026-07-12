import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtCore
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

FloatingWindow {
    id: win

    title: "Notepad"
    implicitWidth: 900
    implicitHeight: 650
    minimumSize: Qt.size(400, 300)

    color: "transparent"

    // Top-level alias so all children (including Repeater delegates) can access the text editor
    property alias textEditor: textInput

    // ── Tab Data Model ──
    property int currentTabIndex: 0
    property int tabCounter: 1

    // ── Find & Replace state ──
    property bool findBarVisible: false
    property bool replaceBarVisible: false
    property string findQuery: ""
    property bool findMatchCase: false
    property bool findWholeWord: false
    property int findCurrentMatch: 0
    property int findTotalMatches: 0
    property var findMatchPositions: []

    // ── Word wrap toggle ──
    property bool wordWrapEnabled: true

    // ── Zoom level ──
    property int zoomLevel: 100  // percentage

    ListModel {
        id: tabModel

        Component.onCompleted: {
            // Start with one empty tab
            addNewTab();
        }
    }

    function addNewTab() {
        tabModel.append({
            tabId: tabCounter++,
            tabTitle: "Untitled",
            tabFilePath: "",
            tabContent: "",
            tabSavedContent: "",
            tabIsModified: false,
            tabCursorPos: 0
        });
        currentTabIndex = tabModel.count - 1;
    }

    function closeTab(index) {
        if (tabModel.count <= 1) {
            // Last tab: just reset it
            tabModel.set(0, {
                tabTitle: "Untitled",
                tabFilePath: "",
                tabContent: "",
                tabSavedContent: "",
                tabIsModified: false,
                tabCursorPos: 0
            });
            currentTabIndex = 0;
            return;
        }

        tabModel.remove(index);
        if (currentTabIndex >= tabModel.count) {
            currentTabIndex = tabModel.count - 1;
        } else if (currentTabIndex > index) {
            currentTabIndex--;
        } else if (currentTabIndex === index) {
            // Stay at same index (now shows next tab), or go back if was last
            if (currentTabIndex >= tabModel.count) {
                currentTabIndex = tabModel.count - 1;
            }
        }
    }

    function currentTab() {
        if (currentTabIndex >= 0 && currentTabIndex < tabModel.count) {
            return tabModel.get(currentTabIndex);
        }
        return null;
    }

    function saveCurrentTabState() {
        if (currentTabIndex >= 0 && currentTabIndex < tabModel.count && textInput.item) {
            tabModel.setProperty(currentTabIndex, "tabContent", textInput.item.text);
            tabModel.setProperty(currentTabIndex, "tabCursorPos", textInput.item.cursorPosition);
        }
    }

    function switchToTab(index) {
        if (index === currentTabIndex) return;
        if (index < 0 || index >= tabModel.count) return;
        saveCurrentTabState();
        currentTabIndex = index;
    }

    // When tab index changes, load content into the text area
    onCurrentTabIndexChanged: {
        if (textInput.item && currentTabIndex >= 0 && currentTabIndex < tabModel.count) {
            let tab = tabModel.get(currentTabIndex);
            textInput.item.text = tab.tabContent;
            textInput.item.cursorPosition = Math.min(tab.tabCursorPos, textInput.item.text.length);
            statusMessage.text = tab.tabFilePath ? tab.tabFilePath : "Ready";
        }
    }

    // ── Find & Replace Functions ──
    function performFind() {
        if (!textInput.item || findQuery === "") {
            findMatchPositions = [];
            findTotalMatches = 0;
            findCurrentMatch = 0;
            return;
        }

        let text = textInput.item.text;
        let query = findQuery;
        let positions = [];

        if (!findMatchCase) {
            text = text.toLowerCase();
            query = query.toLowerCase();
        }

        let startIdx = 0;
        while (true) {
            let idx = text.indexOf(query, startIdx);
            if (idx === -1) break;

            if (findWholeWord) {
                let before = idx > 0 ? text[idx - 1] : " ";
                let after = (idx + query.length < text.length) ? text[idx + query.length] : " ";
                let wordBoundary = /[\s\.,;:!?\-\(\)\[\]\{\}'"\/\\<>@#$%^&*~`+=|]| /;
                if (!wordBoundary.test(before) || !wordBoundary.test(after)) {
                    startIdx = idx + 1;
                    continue;
                }
            }

            positions.push(idx);
            startIdx = idx + 1;
        }

        findMatchPositions = positions;
        findTotalMatches = positions.length;

        if (findTotalMatches > 0) {
            // Find the nearest match to current cursor
            let cursorPos = textInput.item.cursorPosition;
            let nearest = 0;
            for (let i = 0; i < positions.length; i++) {
                if (positions[i] >= cursorPos) {
                    nearest = i;
                    break;
                }
                nearest = i;
            }
            findCurrentMatch = nearest + 1;
            // Only select text, don't steal focus from find field
            highlightMatch(nearest, false);
        } else {
            findCurrentMatch = 0;
        }
    }

    function highlightMatch(matchIndex, grabFocus) {
        if (!textInput.item || matchIndex < 0 || matchIndex >= findMatchPositions.length) return;
        let pos = findMatchPositions[matchIndex];
        textInput.item.select(pos, pos + findQuery.length);
        if (grabFocus !== false) {
            textInput.item.forceActiveFocus();
        }
    }

    function findNext() {
        if (findTotalMatches === 0) return;
        findCurrentMatch = (findCurrentMatch % findTotalMatches) + 1;
        highlightMatch(findCurrentMatch - 1);
    }

    function findPrevious() {
        if (findTotalMatches === 0) return;
        findCurrentMatch = ((findCurrentMatch - 2 + findTotalMatches) % findTotalMatches) + 1;
        highlightMatch(findCurrentMatch - 1);
    }

    function replaceCurrentMatch(replaceText) {
        if (!textInput.item || findTotalMatches === 0 || findCurrentMatch === 0) return;
        let matchIdx = findCurrentMatch - 1;
        let pos = findMatchPositions[matchIdx];
        let origText = textInput.item.text;
        textInput.item.text = origText.substring(0, pos) + replaceText + origText.substring(pos + findQuery.length);
        performFind();
    }

    function replaceAll(replaceText) {
        if (!textInput.item || findTotalMatches === 0) return;
        let text = textInput.item.text;
        let query = findQuery;

        if (findMatchCase) {
            textInput.item.text = text.split(query).join(replaceText);
        } else {
            let re = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
            textInput.item.text = text.replace(re, replaceText);
        }
        performFind();
    }

    function goToLine(lineNum) {
        if (!textInput.item) return;
        let lines = textInput.item.text.split('\n');
        let targetLine = Math.max(1, Math.min(lineNum, lines.length));
        let pos = 0;
        for (let i = 0; i < targetLine - 1; i++) {
            pos += lines[i].length + 1; // +1 for newline
        }
        textInput.item.cursorPosition = pos;
        textInput.item.forceActiveFocus();
    }

    function getCharCount() {
        if (!textInput.item) return 0;
        return textInput.item.text.length;
    }

    function getWordCount() {
        if (!textInput.item || textInput.item.text.trim() === "") return 0;
        return textInput.item.text.trim().split(/\s+/).length;
    }

    function getLineCount() {
        if (!textInput.item) return 1;
        if (textInput.item.text === "") return 1;
        return textInput.item.text.split('\n').length;
    }

    function insertTimestamp() {
        if (!textInput.item) return;
        let now = new Date();
        let stamp = now.toLocaleString(Qt.locale(), "h:mm AP M/d/yyyy");
        let pos = textInput.item.cursorPosition;
        let txt = textInput.item.text;
        textInput.item.text = txt.substring(0, pos) + stamp + txt.substring(pos);
        textInput.item.cursorPosition = pos + stamp.length;
    }

    // ── Custom File Dialogs ──
    property string fileDialogMode: "open"

    Loader {
        id: fileDialogLoader
        active: false
        anchors.fill: parent
        z: 99

        sourceComponent: Component {
            DankFileDialog {
                title: win.fileDialogMode === "open" ? "Open File" : "Save File As"
                onAccepted: function(path) {
                    if (win.fileDialogMode === "open") {
                        win.openFileInTab(path);
                    } else {
                        win.saveCurrentTabAs(path);
                    }
                    fileDialogLoader.active = false;
                }
                onRejected: {
                    fileDialogLoader.active = false;
                }
            }
        }
    }

    // ── File I/O via NotepadService ──
    Connections {
        target: NotepadService
        function onFileOpened() {
            if (currentTabIndex >= 0 && currentTabIndex < tabModel.count) {
                let content = NotepadService.fileContent;
                let path = NotepadService.filePath;
                let name = path.split('/').pop();
                tabModel.setProperty(currentTabIndex, "tabContent", content);
                tabModel.setProperty(currentTabIndex, "tabSavedContent", content);
                tabModel.setProperty(currentTabIndex, "tabFilePath", path);
                tabModel.setProperty(currentTabIndex, "tabTitle", name);
                tabModel.setProperty(currentTabIndex, "tabIsModified", false);
                if (textInput.item) {
                    textInput.item.text = content;
                }
                statusMessage.text = "Opened: " + path;
            }
        }
        function onFileSaved() {
            if (currentTabIndex >= 0 && currentTabIndex < tabModel.count) {
                tabModel.setProperty(currentTabIndex, "tabIsModified", false);
                tabModel.setProperty(currentTabIndex, "tabSavedContent", textInput.item ? textInput.item.text : "");
            }
            statusMessage.text = "Saved successfully!";
        }
        function onErrorOccurred(msg) {
            statusMessage.text = "Error: " + msg;
        }
    }

    function openFileInTab(path) {
        // If current tab is untitled and empty, reuse it
        let tab = currentTab();
        if (tab && tab.tabFilePath === "" && tab.tabContent === "" && !tab.tabIsModified) {
            NotepadService.openFile(path);
        } else {
            // Open in a new tab
            addNewTab();
            NotepadService.openFile(path);
        }
    }

    function saveCurrentTab() {
        let tab = currentTab();
        if (!tab) return;
        if (tab.tabFilePath) {
            NotepadService.filePath = tab.tabFilePath;
            NotepadService.saveFile(textInput.item ? textInput.item.text : "");
        } else {
            win.fileDialogMode = "save";
            fileDialogLoader.active = true;
        }
    }

    function saveCurrentTabAs(path) {
        if (!path) return;
        let name = path.split('/').pop();
        tabModel.setProperty(currentTabIndex, "tabFilePath", path);
        tabModel.setProperty(currentTabIndex, "tabTitle", name);
        NotepadService.saveFileAs(path, textInput.item ? textInput.item.text : "");
    }

    // ── Main UI ──
    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.normal
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Menu bar ──
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.surfaceContainerHigh

                // Flatten bottom corners
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 8
                    color: parent.color
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 4

                    DankIcon {
                        name: "edit_note"
                        size: 20
                        color: Theme.primary
                        filled: true
                    }

                    Text {
                        text: "Notepad"
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                    }

                    // Separator
                    Rectangle { width: 1; height: 20; color: Theme.outlineVariant; opacity: 0.4 }

                    Repeater {
                        model: [
                            { label: "New", icon: "note_add", shortcut: "Ctrl+N" },
                            { label: "Open", icon: "folder_open", shortcut: "Ctrl+O" },
                            { label: "Save", icon: "save", shortcut: "Ctrl+S" },
                            { label: "Save As", icon: "save_as", shortcut: "Ctrl+Shift+S" },
                            { label: "Find", icon: "search", shortcut: "Ctrl+F" },
                            { label: "Replace", icon: "find_replace", shortcut: "Ctrl+H" }
                        ]

                        delegate: Rectangle {
                            width: menuRow.implicitWidth + 14
                            height: 28
                            radius: 6
                            color: menuMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Row {
                                id: menuRow
                                anchors.centerIn: parent
                                spacing: 4

                                DankIcon {
                                    name: modelData.icon
                                    size: 14
                                    color: Qt.rgba(1, 1, 1, 0.7)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.label
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: menuMA
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    switch (index) {
                                        case 0: // New
                                            win.addNewTab();
                                            if (textInput.item) textInput.item.text = "";
                                            break;
                                        case 1: // Open
                                            win.fileDialogMode = "open";
                                            fileDialogLoader.active = true;
                                            break;
                                        case 2: // Save
                                            win.saveCurrentTab();
                                            break;
                                        case 3: // Save As
                                            win.fileDialogMode = "save";
                                            fileDialogLoader.active = true;
                                            break;
                                        case 4: // Find
                                            win.findBarVisible = true;
                                            win.replaceBarVisible = false;
                                            findField.forceActiveFocus();
                                            findField.selectAll();
                                            break;
                                        case 5: // Replace
                                            win.findBarVisible = true;
                                            win.replaceBarVisible = true;
                                            findField.forceActiveFocus();
                                            findField.selectAll();
                                            break;
                                    }
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle { width: 1; height: 20; color: Theme.outlineVariant; opacity: 0.4 }

                    // Word Wrap toggle
                    Rectangle {
                        width: wrapRow.implicitWidth + 14
                        height: 28
                        radius: 6
                        color: wrapMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : (wordWrapEnabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")

                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            id: wrapRow
                            anchors.centerIn: parent
                            spacing: 4

                            DankIcon {
                                name: "wrap_text"
                                size: 14
                                color: wordWrapEnabled ? Theme.primary : Qt.rgba(1, 1, 1, 0.7)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "Wrap"
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: wordWrapEnabled ? Theme.primary : Qt.rgba(1, 1, 1, 0.8)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: wrapMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wordWrapEnabled = !wordWrapEnabled
                        }
                    }

                    // Zoom controls
                    Rectangle {
                        width: zoomRow.implicitWidth + 14
                        height: 28
                        radius: 6
                        color: "transparent"

                        Row {
                            id: zoomRow
                            anchors.centerIn: parent
                            spacing: 2

                            Rectangle {
                                width: 22; height: 22; radius: 4
                                color: zoomOutMA.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                DankIcon { anchors.centerIn: parent; name: "remove"; size: 12; color: Qt.rgba(1, 1, 1, 0.7) }
                                MouseArea { id: zoomOutMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (zoomLevel > 50) zoomLevel -= 10 }
                            }

                            Text {
                                text: zoomLevel + "%"
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 1, 1, 0.6)
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                horizontalAlignment: Text.AlignHCenter

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: zoomLevel = 100
                                }
                            }

                            Rectangle {
                                width: 22; height: 22; radius: 4
                                color: zoomInMA.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                                DankIcon { anchors.centerIn: parent; name: "add"; size: 12; color: Qt.rgba(1, 1, 1, 0.7) }
                                MouseArea { id: zoomInMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (zoomLevel < 300) zoomLevel += 10 }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ── Tab Bar ──
            Rectangle {
                Layout.fillWidth: true
                height: 38
                color: Theme.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 0

                    // Scrollable tab strip
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: tabRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.HorizontalFlick

                        Row {
                            id: tabRow
                            spacing: 2
                            height: parent.height

                            Repeater {
                                model: tabModel

                                delegate: Rectangle {
                                    id: tabDelegate
                                    width: Math.min(180, Math.max(100, tabLabelText.implicitWidth + 56))
                                    height: 34
                                    anchors.bottom: parent.bottom
                                    radius: 8

                                    // Flatten bottom corners
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: parent.radius
                                        color: parent.color
                                    }

                                    property bool isActive: win.currentTabIndex === index

                                    color: isActive
                                        ? Theme.surfaceContainerLow
                                        : tabDelegateMA.containsMouse
                                            ? Qt.rgba(1, 1, 1, 0.06)
                                            : "transparent"

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    // Active tab top accent
                                    Rectangle {
                                        visible: tabDelegate.isActive
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        height: 2
                                        radius: 1
                                        color: Theme.primary

                                        Behavior on visible { NumberAnimation { duration: 150 } }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 6
                                        spacing: 4

                                        // Tab icon
                                        DankIcon {
                                            name: tabFilePath ? "description" : "draft"
                                            size: 14
                                            color: tabDelegate.isActive ? Theme.primary : Qt.rgba(1, 1, 1, 0.5)
                                        }

                                        // Tab title
                                        Text {
                                            id: tabLabelText
                                            text: tabTitle + (tabIsModified ? " •" : "")
                                            font.family: Theme.font.family
                                            font.pixelSize: 11
                                            font.weight: tabDelegate.isActive ? Font.Medium : Font.Normal
                                            color: tabDelegate.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Close tab button
                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 4
                                            color: tabCloseMA.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                            visible: tabDelegateMA.containsMouse || tabDelegate.isActive

                                            Behavior on color { ColorAnimation { duration: 80 } }

                                            DankIcon {
                                                anchors.centerIn: parent
                                                name: "close"
                                                size: 12
                                                color: Qt.rgba(1, 1, 1, 0.6)
                                            }

                                            MouseArea {
                                                id: tabCloseMA
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    win.saveCurrentTabState();
                                                    win.closeTab(index);
                                                    // Load new current tab content
                                                    if (win.textEditor.item && win.currentTabIndex >= 0 && win.currentTabIndex < tabModel.count) {
                                                        win.textEditor.item.text = tabModel.get(win.currentTabIndex).tabContent;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: tabDelegateMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        // Don't steal from close button
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        z: -1

                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.MiddleButton) {
                                                win.saveCurrentTabState();
                                                win.closeTab(index);
                                                if (win.textEditor.item && win.currentTabIndex >= 0 && win.currentTabIndex < tabModel.count) {
                                                    win.textEditor.item.text = tabModel.get(win.currentTabIndex).tabContent;
                                                }
                                            } else {
                                                win.switchToTab(index);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // New tab button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: newTabMA.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color { ColorAnimation { duration: 100 } }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "add"
                            size: 16
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }

                        MouseArea {
                            id: newTabMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                win.saveCurrentTabState();
                                win.addNewTab();
                                if (textInput.item) textInput.item.text = "";
                            }
                        }
                    }
                }
            }

            // Thin separator under tabs
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.outlineVariant
                opacity: 0.3
            }

            // ── Find & Replace Bar ──
            Rectangle {
                id: findBar
                Layout.fillWidth: true
                visible: findBarVisible
                implicitHeight: findBarCol.implicitHeight + 12
                color: Theme.surfaceContainerHigh
                border.color: Theme.outlineVariant
                border.width: 0

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.3
                }

                ColumnLayout {
                    id: findBarCol
                    anchors.fill: parent
                    anchors.margins: 6
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    // ── Find Row ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Find input
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.color: findField.activeFocus ? Theme.primary : Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 4

                                DankIcon {
                                    name: "search"
                                    size: 14
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                }

                                TextInput {
                                    id: findField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.font.family
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                    clip: true
                                    selectByMouse: true
                                    selectedTextColor: Theme.onPrimary
                                    selectionColor: Theme.primary

                                    onTextChanged: {
                                        win.findQuery = text;
                                        win.performFind();
                                    }

                                    Keys.onReturnPressed: win.findNext()
                                    Keys.onEscapePressed: { win.findBarVisible = false; win.replaceBarVisible = false; if (textInput.item) textInput.item.forceActiveFocus(); }
                                }

                                // Match count badge
                                Text {
                                    visible: findField.text !== ""
                                    text: findTotalMatches > 0 ? findCurrentMatch + "/" + findTotalMatches : "No results"
                                    font.family: Theme.font.family
                                    font.pixelSize: 10
                                    color: findTotalMatches > 0 ? Qt.rgba(1, 1, 1, 0.5) : Theme.error
                                }
                            }
                        }

                        // Match Case toggle
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: findMatchCase ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : (matchCaseMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            border.color: findMatchCase ? Theme.primary : "transparent"
                            border.width: findMatchCase ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "Aa"
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: findMatchCase ? Theme.primary : Qt.rgba(1, 1, 1, 0.6)
                            }
                            MouseArea {
                                id: matchCaseMA
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { findMatchCase = !findMatchCase; performFind(); }
                            }

                            ToolTip {
                                parent: matchCaseMA
                                visible: matchCaseMA.containsMouse
                                text: "Match Case"
                                delay: 500
                            }
                        }

                        // Whole Word toggle
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: findWholeWord ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : (wholeWordMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            border.color: findWholeWord ? Theme.primary : "transparent"
                            border.width: findWholeWord ? 1 : 0

                            Text {
                                anchors.centerIn: parent
                                text: "W"
                                font.family: Theme.font.monospace
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.underline: true
                                color: findWholeWord ? Theme.primary : Qt.rgba(1, 1, 1, 0.6)
                            }
                            MouseArea {
                                id: wholeWordMA
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { findWholeWord = !findWholeWord; performFind(); }
                            }

                            ToolTip {
                                parent: wholeWordMA
                                visible: wholeWordMA.containsMouse
                                text: "Whole Word"
                                delay: 500
                            }
                        }

                        // Previous match
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: prevMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "keyboard_arrow_up"; size: 16; color: Qt.rgba(1, 1, 1, 0.7) }
                            MouseArea { id: prevMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.findPrevious() }
                        }

                        // Next match
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: nextMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "keyboard_arrow_down"; size: 16; color: Qt.rgba(1, 1, 1, 0.7) }
                            MouseArea { id: nextMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.findNext() }
                        }

                        // Toggle replace
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: replaceBarVisible ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : (toggleReplaceMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                            DankIcon { anchors.centerIn: parent; name: "find_replace"; size: 14; color: replaceBarVisible ? Theme.primary : Qt.rgba(1, 1, 1, 0.7) }
                            MouseArea { id: toggleReplaceMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: replaceBarVisible = !replaceBarVisible }
                        }

                        // Close find bar
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: closeFindMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            DankIcon { anchors.centerIn: parent; name: "close"; size: 14; color: Qt.rgba(1, 1, 1, 0.6) }
                            MouseArea { id: closeFindMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { findBarVisible = false; replaceBarVisible = false; if (textInput.item) textInput.item.forceActiveFocus(); } }
                        }
                    }

                    // ── Replace Row ──
                    RowLayout {
                        Layout.fillWidth: true
                        visible: replaceBarVisible
                        spacing: 6

                        // Replace input
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 6
                            color: Qt.rgba(1, 1, 1, 0.06)
                            border.color: replaceField.activeFocus ? Theme.primary : Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: 4

                                DankIcon {
                                    name: "find_replace"
                                    size: 14
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                }

                                TextInput {
                                    id: replaceField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.font.family
                                    font.pixelSize: 12
                                    color: "#ffffff"
                                    clip: true
                                    selectByMouse: true
                                    selectedTextColor: Theme.onPrimary
                                    selectionColor: Theme.primary

                                    Keys.onReturnPressed: win.replaceCurrentMatch(replaceField.text)
                                    Keys.onEscapePressed: { win.findBarVisible = false; win.replaceBarVisible = false; if (textInput.item) textInput.item.forceActiveFocus(); }
                                }
                            }
                        }

                        // Replace single
                        Rectangle {
                            width: replaceOneRow.implicitWidth + 12; height: 28; radius: 6
                            color: replaceOneMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Row {
                                id: replaceOneRow
                                anchors.centerIn: parent; spacing: 4
                                DankIcon { name: "swap_horiz"; size: 14; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "Replace"; font.family: Theme.font.family; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: replaceOneMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.replaceCurrentMatch(replaceField.text) }
                        }

                        // Replace all
                        Rectangle {
                            width: replaceAllRow.implicitWidth + 12; height: 28; radius: 6
                            color: replaceAllMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            Row {
                                id: replaceAllRow
                                anchors.centerIn: parent; spacing: 4
                                DankIcon { name: "done_all"; size: 14; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: "All"; font.family: Theme.font.family; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: replaceAllMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.replaceAll(replaceField.text) }
                        }
                    }
                }
            }

            // ── Text Area Container ──
            ScrollView {
                id: scrollArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                background: Rectangle {
                    color: Theme.surfaceContainerLow
                }

                Loader {
                    id: textInput
                    width: scrollArea.width
                    active: true

                    sourceComponent: Component {
                        TextArea {
                            width: textInput.width
                            placeholderText: "Start typing here..."
                            font.family: Theme.font.monospace
                            font.pixelSize: Math.round(Theme.font.sizeNormal * (win.zoomLevel / 100))
                            color: "#ffffff"
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.3)
                            selectedTextColor: Theme.onPrimary
                            selectionColor: Theme.primary
                            background: null
                            selectByMouse: true
                            wrapMode: wordWrapEnabled ? TextArea.Wrap : TextArea.NoWrap
                            padding: 16
                            tabStopDistance: 28

                            Component.onCompleted: {
                                forceActiveFocus();
                            }

                            onTextChanged: {
                                if (win.currentTabIndex >= 0 && win.currentTabIndex < tabModel.count) {
                                    let tab = tabModel.get(win.currentTabIndex);
                                    if (tab.tabSavedContent !== text) {
                                        tabModel.setProperty(win.currentTabIndex, "tabIsModified", true);
                                    } else {
                                        tabModel.setProperty(win.currentTabIndex, "tabIsModified", false);
                                    }
                                    tabModel.setProperty(win.currentTabIndex, "tabContent", text);
                                }
                            }
                        }
                    }
                }
            }

            // ── Status Bar ──
            Rectangle {
                Layout.fillWidth: true
                height: 26
                color: Theme.surfaceContainerHigh

                // Flatten top corners
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.3
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 16

                    Text {
                        id: statusMessage
                        text: "Ready"
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.5)
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }

                    // Word count
                    Text {
                        text: win.getWordCount() + (win.getWordCount() === 1 ? " word" : " words")
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.15) }

                    // Char count
                    Text {
                        text: win.getCharCount() + (win.getCharCount() === 1 ? " char" : " chars")
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.15) }

                    // Tab count
                    Text {
                        text: tabModel.count + (tabModel.count === 1 ? " tab" : " tabs")
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.15) }

                    // Zoom indicator
                    Text {
                        text: zoomLevel + "%"
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }

                    Rectangle { width: 1; height: 14; color: Qt.rgba(1, 1, 1, 0.15) }

                    // Line / Col indicator
                    Text {
                        text: {
                            if (!textInput.item) return "Ln 1, Col 1";
                            let pos = textInput.item.cursorPosition;
                            let txt = textInput.item.text;
                            let ln = txt.substr(0, pos).split('\n').length;
                            let col = pos - txt.lastIndexOf('\n', pos - 1);
                            return "Ln " + ln + ", Col " + col;
                        }
                        font.family: Theme.font.monospace
                        font.pixelSize: 10
                        color: Qt.rgba(1, 1, 1, 0.5)
                    }
                }
            }
        }
    }

    // ── Keyboard Shortcuts ──
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: {
            win.saveCurrentTabState();
            win.addNewTab();
            if (textInput.item) textInput.item.text = "";
        }
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: {
            win.fileDialogMode = "open";
            fileDialogLoader.active = true;
        }
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: win.saveCurrentTab()
    }

    Shortcut {
        sequence: "Ctrl+Shift+S"
        onActivated: {
            win.fileDialogMode = "save";
            fileDialogLoader.active = true;
        }
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: {
            win.saveCurrentTabState();
            win.closeTab(win.currentTabIndex);
            if (textInput.item && win.currentTabIndex >= 0 && win.currentTabIndex < tabModel.count) {
                textInput.item.text = tabModel.get(win.currentTabIndex).tabContent;
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            win.saveCurrentTabState();
            win.addNewTab();
            if (textInput.item) textInput.item.text = "";
        }
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: {
            if (tabModel.count > 1) {
                let next = (win.currentTabIndex + 1) % tabModel.count;
                win.switchToTab(next);
            }
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: {
            if (tabModel.count > 1) {
                let prev = (win.currentTabIndex - 1 + tabModel.count) % tabModel.count;
                win.switchToTab(prev);
            }
        }
    }

    // Find (Ctrl+F)
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            findBarVisible = true;
            replaceBarVisible = false;
            findField.forceActiveFocus();
            findField.selectAll();
            // Pre-populate with selected text
            if (textInput.item && textInput.item.selectedText !== "") {
                findField.text = textInput.item.selectedText;
            }
        }
    }

    // Replace (Ctrl+H)
    Shortcut {
        sequence: "Ctrl+H"
        onActivated: {
            findBarVisible = true;
            replaceBarVisible = true;
            findField.forceActiveFocus();
            findField.selectAll();
            if (textInput.item && textInput.item.selectedText !== "") {
                findField.text = textInput.item.selectedText;
            }
        }
    }

    // Find Next (F3)
    Shortcut {
        sequence: "F3"
        onActivated: win.findNext()
    }

    // Find Previous (Shift+F3)
    Shortcut {
        sequence: "Shift+F3"
        onActivated: win.findPrevious()
    }

    // Close find bar (Escape)
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (findBarVisible) {
                findBarVisible = false;
                replaceBarVisible = false;
                if (textInput.item) textInput.item.forceActiveFocus();
            }
        }
    }

    // Go to Line (Ctrl+G)
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: goToLineDialog.open()
    }

    // Insert timestamp (F5 — classic Notepad feature)
    Shortcut {
        sequence: "F5"
        onActivated: win.insertTimestamp()
    }

    // Zoom In (Ctrl+=)
    Shortcut {
        sequence: "Ctrl+="
        onActivated: if (zoomLevel < 300) zoomLevel += 10
    }

    // Zoom Out (Ctrl+-)
    Shortcut {
        sequence: "Ctrl+-"
        onActivated: if (zoomLevel > 50) zoomLevel -= 10
    }

    // Reset Zoom (Ctrl+0)
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: zoomLevel = 100
    }

    // Select All (Ctrl+A)
    Shortcut {
        sequence: "Ctrl+A"
        onActivated: if (textInput.item) textInput.item.selectAll()
    }

    // Duplicate Line (Ctrl+D)
    Shortcut {
        sequence: "Ctrl+D"
        onActivated: {
            if (!textInput.item) return;
            let pos = textInput.item.cursorPosition;
            let txt = textInput.item.text;
            let lineStart = txt.lastIndexOf('\n', pos - 1) + 1;
            let lineEnd = txt.indexOf('\n', pos);
            if (lineEnd === -1) lineEnd = txt.length;
            let line = txt.substring(lineStart, lineEnd);
            textInput.item.text = txt.substring(0, lineEnd) + "\n" + line + txt.substring(lineEnd);
            textInput.item.cursorPosition = pos + line.length + 1;
        }
    }

    // ── Go to Line Dialog ──
    Popup {
        id: goToLineDialog
        anchors.centerIn: parent
        width: 320
        height: goToLineCol.implicitHeight + 32
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.surfaceContainerHigh
            radius: 12
            border.color: Theme.outlineVariant
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 33
                color: "#40000000"
            }
        }

        ColumnLayout {
            id: goToLineCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Go to Line"
                font.family: Theme.font.family
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: "#ffffff"
            }

            Text {
                text: "Line number (1 – " + win.getLineCount() + ")"
                font.family: Theme.font.family
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.5)
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)
                border.color: goToLineInput.activeFocus ? Theme.primary : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                TextInput {
                    id: goToLineInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.font.monospace
                    font.pixelSize: 13
                    color: "#ffffff"
                    selectByMouse: true
                    validator: IntValidator { bottom: 1; top: 999999 }

                    Keys.onReturnPressed: {
                        let lineNum = parseInt(goToLineInput.text);
                        if (!isNaN(lineNum)) {
                            win.goToLine(lineNum);
                        }
                        goToLineDialog.close();
                    }
                    Keys.onEscapePressed: goToLineDialog.close()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: cancelGoRow.implicitWidth + 16; height: 32; radius: 6
                    color: cancelGoMA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    Row {
                        id: cancelGoRow; anchors.centerIn: parent; spacing: 4
                        Text { text: "Cancel"; font.family: Theme.font.family; font.pixelSize: 12; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: cancelGoMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: goToLineDialog.close() }
                }

                Rectangle {
                    width: goRow.implicitWidth + 16; height: 32; radius: 6
                    color: goMA.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                    Row {
                        id: goRow; anchors.centerIn: parent; spacing: 4
                        Text { text: "Go"; font.family: Theme.font.family; font.pixelSize: 12; font.weight: Font.DemiBold; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: goMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let lineNum = parseInt(goToLineInput.text);
                            if (!isNaN(lineNum)) win.goToLine(lineNum);
                            goToLineDialog.close();
                        }
                    }
                }
            }
        }

        onOpened: {
            goToLineInput.text = "";
            goToLineInput.forceActiveFocus();
        }
    }
}
