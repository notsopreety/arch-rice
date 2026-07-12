import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import QtCore
import Quickshell
import "../theme"
import "../components"
import "../services"

Rectangle {
    id: root

    property string currentDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    property string selectedPath: ""
    property bool selectFolder: false
    property string title: "File Manager"
    property var navigationHistory: []
    property int historyIndex: -1

    signal accepted(string path)
    signal rejected()

    color: Theme.surfaceContainer
    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
    border.width: 1
    radius: Theme.rounding.normal

    // Focus scope for keyboard handling
    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.rejected();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (fileList.currentIndex >= 0 && fileList.currentIndex < folderModel.count) {
                let fullPath = folderModel.get(fileList.currentIndex, "filePath");
                if (fullPath.toString().startsWith("file://")) {
                    fullPath = fullPath.toString().substring(7);
                }
                let isDir = folderModel.get(fileList.currentIndex, "fileIsDir");
                if (isDir) {
                    pushHistory(root.currentDir);
                    root.currentDir = fullPath;
                    root.selectedPath = "";
                    fileList.currentIndex = 0;
                } else {
                    root.accepted(fullPath);
                }
            } else if (selectedInput.text) {
                root.accepted(root.currentDir + "/" + selectedInput.text);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            goUp();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            if (fileList.currentIndex > 0) {
                fileList.currentIndex--;
                updateSelectionFromIndex();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            if (fileList.currentIndex < folderModel.count - 1) {
                fileList.currentIndex++;
                updateSelectionFromIndex();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            fileList.currentIndex = 0;
            updateSelectionFromIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            fileList.currentIndex = folderModel.count - 1;
            updateSelectionFromIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            let newIdx = Math.max(0, fileList.currentIndex - 10);
            fileList.currentIndex = newIdx;
            updateSelectionFromIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            let newIdx = Math.min(folderModel.count - 1, fileList.currentIndex + 10);
            fileList.currentIndex = newIdx;
            updateSelectionFromIndex();
            event.accepted = true;
        } else if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
            pathInput.forceActiveFocus();
            pathInput.selectAll();
            event.accepted = true;
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchInput.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
            folderModel.showHidden = !folderModel.showHidden;
            event.accepted = true;
        } else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
            goBack();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right && (event.modifiers & Qt.AltModifier)) {
            goForward();
            event.accepted = true;
        }
    }

    function pushHistory(dir) {
        // Trim forward history
        if (historyIndex < navigationHistory.length - 1) {
            navigationHistory = navigationHistory.slice(0, historyIndex + 1);
        }
        navigationHistory.push(dir);
        historyIndex = navigationHistory.length - 1;
    }

    function goBack() {
        if (historyIndex > 0) {
            historyIndex--;
            root.currentDir = navigationHistory[historyIndex];
            root.selectedPath = "";
            fileList.currentIndex = 0;
        }
    }

    function goForward() {
        if (historyIndex < navigationHistory.length - 1) {
            historyIndex++;
            root.currentDir = navigationHistory[historyIndex];
            root.selectedPath = "";
            fileList.currentIndex = 0;
        }
    }

    function goUp() {
        let parts = root.currentDir.split("/");
        if (parts.length > 2) {
            pushHistory(root.currentDir);
            parts.pop();
            root.currentDir = parts.join("/");
            root.selectedPath = "";
            fileList.currentIndex = 0;
        }
    }

    function updateSelectionFromIndex() {
        if (fileList.currentIndex >= 0 && fileList.currentIndex < folderModel.count) {
            let fullPath = folderModel.get(fileList.currentIndex, "filePath");
            if (fullPath.toString().startsWith("file://")) {
                fullPath = fullPath.toString().substring(7);
            }
            root.selectedPath = fullPath;
        }
    }

    function formatFileSize(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(2) + " GB";
    }

    // Folder List Model
    FolderListModel {
        id: folderModel
        folder: "file://" + root.currentDir
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Type
        nameFilters: searchInput.text ? ["*" + searchInput.text + "*"] : ["*"]
    }

    // Subtle glow effect behind the dialog
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
        border.width: 2
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Header with title and navigation
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: Theme.surfaceContainerHigh
            radius: Theme.rounding.normal

            // Flatten bottom corners
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // Back button
                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.rounding.small
                    color: backMA.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                    opacity: root.historyIndex > 0 ? 1 : 0.3

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "arrow_back"
                        size: 18
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                    MouseArea {
                        id: backMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goBack()
                    }
                }

                // Forward button
                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.rounding.small
                    color: fwdMA.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                    opacity: root.historyIndex < root.navigationHistory.length - 1 ? 1 : 0.3

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "arrow_forward"
                        size: 18
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                    MouseArea {
                        id: fwdMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goForward()
                    }
                }

                // Up button
                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.rounding.small
                    color: upMA.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "arrow_upward"
                        size: 18
                        color: Qt.rgba(1, 1, 1, 0.7)
                    }
                    MouseArea {
                        id: upMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goUp()
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: 24
                    color: Theme.outlineVariant
                    opacity: 0.5
                }

                // Title icon
                DankIcon {
                    name: "folder_open"
                    size: 20
                    color: Theme.primary
                    filled: true
                }

                // Title text
                Text {
                    text: root.title
                    font.family: Theme.font.family
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                }

                Item { Layout.fillWidth: true }

                // Toggle hidden files
                Rectangle {
                    width: 32
                    height: 32
                    radius: Theme.rounding.small
                    color: hiddenMA.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    DankIcon {
                        anchors.centerIn: parent
                        name: folderModel.showHidden ? "visibility" : "visibility_off"
                        size: 18
                        color: folderModel.showHidden ? Theme.primary : Qt.rgba(1, 1, 1, 0.7)
                    }
                    MouseArea {
                        id: hiddenMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: folderModel.showHidden = !folderModel.showHidden

                        ToolTip.visible: containsMouse
                        ToolTip.text: "Toggle hidden files (Ctrl+H)"
                        ToolTip.delay: 500
                    }
                }
            }
        }

        // Breadcrumb path bar + search
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: Theme.surfaceContainerLow

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 6

                // Breadcrumb path
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    Row {
                        spacing: 2
                        height: parent.height

                        Repeater {
                            model: {
                                let parts = root.currentDir.split("/").filter(function(p) { return p !== ""; });
                                return parts;
                            }

                            delegate: Row {
                                spacing: 2
                                height: 44

                                // Separator chevron
                                Text {
                                    visible: index > 0
                                    text: "›"
                                    font.pixelSize: 16
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                    opacity: 0.5
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Breadcrumb chip
                                Rectangle {
                                    height: 28
                                    width: crumbText.implicitWidth + 16
                                    radius: Theme.rounding.small
                                    color: crumbMA.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                                    Text {
                                        id: crumbText
                                        anchors.centerIn: parent
                                        text: index === 0 ? "/" + modelData : modelData
                                        font.family: Theme.font.family
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: index === (root.currentDir.split("/").filter(function(p) { return p !== ""; }).length - 1) ? Theme.primary : Qt.rgba(1, 1, 1, 0.7)
                                    }

                                    MouseArea {
                                        id: crumbMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let parts = root.currentDir.split("/").filter(function(p) { return p !== ""; });
                                            let newPath = "/" + parts.slice(0, index + 1).join("/");
                                            root.pushHistory(root.currentDir);
                                            root.currentDir = newPath;
                                            root.selectedPath = "";
                                            fileList.currentIndex = 0;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1
                    height: 24
                    color: Theme.outlineVariant
                    opacity: 0.4
                    Layout.alignment: Qt.AlignVCenter
                }

                // Search input
                Rectangle {
                    width: 160
                    height: 30
                    radius: Theme.rounding.full
                    color: Theme.surfaceContainerHigh
                    border.color: searchInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme.anim.durationShort } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        DankIcon {
                            name: "search"
                            size: 14
                            color: Qt.rgba(1, 1, 1, 0.7)
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Filter..."
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            color: "#ffffff"
                            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                            background: null
                            padding: 0
                            topPadding: 0
                            bottomPadding: 0

                            Keys.onEscapePressed: {
                                text = "";
                                root.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // Editable path input (hidden by default, shown on Ctrl+L)
        TextField {
            id: pathInput
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            visible: activeFocus
            text: root.currentDir
            font.family: Theme.font.monospace
            font.pixelSize: 12
            color: "#ffffff"
            placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
            selectedTextColor: Theme.onPrimary
            selectionColor: Theme.primary
            background: Rectangle {
                color: Theme.surfaceContainerHigh
                border.color: Theme.primary
                border.width: 1
                radius: Theme.rounding.small
            }
            onAccepted: {
                root.pushHistory(root.currentDir);
                root.currentDir = text;
                root.forceActiveFocus();
            }
            Keys.onEscapePressed: {
                root.forceActiveFocus();
            }
        }

        // Column headers
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // Icon placeholder
                Item { width: 22; height: 1 }

                Text {
                    text: "Name"
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Qt.rgba(1, 1, 1, 0.6)
                    Layout.fillWidth: true
                }

                Text {
                    text: "Size"
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: Qt.rgba(1, 1, 1, 0.6)
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
            opacity: 0.3
        }

        // Files List
        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 0
            background: Rectangle {
                color: Theme.surfaceContainerLow
            }

            ScrollView {
                anchors.fill: parent
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: fileList
                    model: folderModel
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Theme.anim.durationShort
                    currentIndex: -1

                    // Empty state
                    Text {
                        visible: folderModel.count === 0
                        anchors.centerIn: parent
                        text: searchInput.text ? "No matching files" : "Empty folder"
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        color: Qt.rgba(1, 1, 1, 0.6)
                        opacity: 0.6
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        width: parent ? parent.width : 200
                        height: 40
                        color: {
                            if (fileList.currentIndex === index) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18);
                            }
                            if (delegateMA.containsMouse) {
                                return Qt.rgba(1, 1, 1, 0.06);
                            }
                            return "transparent";
                        }

                        Behavior on color { ColorAnimation { duration: 100 } }

                        // Left accent for selected item
                        Rectangle {
                            visible: fileList.currentIndex === index
                            width: 3
                            height: parent.height - 8
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: Theme.primary

                            Behavior on visible { NumberAnimation { duration: Theme.anim.durationShort } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 10

                            // File type icon
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                color: fileIsDir
                                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                    : Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.08)

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: {
                                        if (fileIsDir) return "folder";
                                        let ext = fileName.split('.').pop().toLowerCase();
                                        if (["jpg", "jpeg", "png", "gif", "svg", "webp", "bmp"].indexOf(ext) >= 0) return "image";
                                        if (["mp3", "wav", "flac", "ogg", "m4a", "aac"].indexOf(ext) >= 0) return "music_note";
                                        if (["mp4", "mkv", "avi", "mov", "webm"].indexOf(ext) >= 0) return "movie";
                                        if (["pdf"].indexOf(ext) >= 0) return "picture_as_pdf";
                                        if (["zip", "tar", "gz", "bz2", "xz", "7z", "rar"].indexOf(ext) >= 0) return "folder_zip";
                                        if (["py", "js", "ts", "cpp", "c", "h", "rs", "go", "java", "qml", "sh", "bash"].indexOf(ext) >= 0) return "code";
                                        if (["md", "txt", "log", "cfg", "ini", "conf", "json", "xml", "yaml", "yml", "toml"].indexOf(ext) >= 0) return "description";
                                        return "draft";
                                    }
                                    size: 16
                                    color: fileIsDir ? Theme.primary : Theme.tertiary
                                    filled: fileIsDir
                                }
                            }

                            // File name
                            Text {
                                text: fileName
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                font.weight: fileIsDir ? Font.Medium : Font.Normal
                                color: "#ffffff"
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            // File size (only for files)
                            Text {
                                text: fileIsDir ? "" : root.formatFileSize(fileSize)
                                font.family: Theme.font.monospace
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.5)
                                opacity: 0.7
                                Layout.preferredWidth: 80
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        MouseArea {
                            id: delegateMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                fileList.currentIndex = index;
                                let fullPath = filePath;
                                if (fullPath.toString().startsWith("file://")) {
                                    fullPath = fullPath.toString().substring(7);
                                }
                                root.selectedPath = fullPath;
                                root.forceActiveFocus();
                            }

                            onDoubleClicked: {
                                let fullPath = filePath;
                                if (fullPath.toString().startsWith("file://")) {
                                    fullPath = fullPath.toString().substring(7);
                                }
                                if (fileIsDir) {
                                    root.pushHistory(root.currentDir);
                                    root.currentDir = fullPath;
                                    root.selectedPath = "";
                                    fileList.currentIndex = 0;
                                } else {
                                    root.accepted(fullPath);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
            opacity: 0.3
        }

        // Footer: Selected file + action buttons
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: Theme.surfaceContainerHigh
            radius: Theme.rounding.normal

            // Flatten top corners
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // File name label
                Text {
                    text: "File:"
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Qt.rgba(1, 1, 1, 0.7)
                }

                // File name input
                TextField {
                    id: selectedInput
                    Layout.fillWidth: true
                    text: root.selectedPath ? root.selectedPath.split("/").pop() : ""
                    placeholderText: "Enter file name..."
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    color: "#ffffff"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    selectedTextColor: Theme.onPrimary
                    selectionColor: Theme.primary
                    background: Rectangle {
                        color: Theme.surfaceContainerLow
                        border.color: selectedInput.activeFocus ? Theme.primary : Theme.outlineVariant
                        border.width: 1
                        radius: Theme.rounding.small

                        Behavior on border.color { ColorAnimation { duration: Theme.anim.durationShort } }
                    }
                    onAccepted: {
                        if (root.selectedPath) {
                            root.accepted(root.selectedPath);
                        } else if (text) {
                            root.accepted(root.currentDir + "/" + text);
                        }
                    }
                }

                // Cancel button
                Rectangle {
                    width: cancelRow.implicitWidth + 20
                    height: 34
                    radius: Theme.rounding.small
                    color: cancelBtnMA.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                    border.color: Theme.outlineVariant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    Row {
                        id: cancelRow
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: "close"
                            size: 16
                            color: Qt.rgba(1, 1, 1, 0.7)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Cancel"
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Qt.rgba(1, 1, 1, 0.7)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: cancelBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.rejected()
                    }
                }

                // Select / Open button (primary)
                Rectangle {
                    width: selectRow.implicitWidth + 24
                    height: 34
                    radius: Theme.rounding.small
                    color: selectBtnMA.containsMouse ? Qt.lighter(Theme.primary, 1.15) : Theme.primary

                    Behavior on color { ColorAnimation { duration: Theme.anim.durationShort } }

                    Row {
                        id: selectRow
                        anchors.centerIn: parent
                        spacing: 4

                        DankIcon {
                            name: "check"
                            size: 16
                            color: Theme.onPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Select"
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: selectBtnMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.selectedPath) {
                                root.accepted(root.selectedPath);
                            } else if (selectedInput.text) {
                                root.accepted(root.currentDir + "/" + selectedInput.text);
                            }
                        }
                    }
                }
            }
        }

        // Keyboard shortcut hints bar
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: Qt.rgba(Theme.surfaceDim.r, Theme.surfaceDim.g, Theme.surfaceDim.b, 0.8)
            radius: Theme.rounding.normal

            // Flatten top corners
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 16

                Repeater {
                    model: [
                        { key: "Enter", action: "Open" },
                        { key: "Bksp", action: "Up" },
                        { key: "Ctrl+L", action: "Path" },
                        { key: "Ctrl+F", action: "Search" },
                        { key: "Ctrl+H", action: "Hidden" },
                        { key: "Esc", action: "Close" }
                    ]

                    delegate: Row {
                        spacing: 3

                        Rectangle {
                            width: keyLabel.implicitWidth + 8
                            height: 16
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: keyLabel
                                anchors.centerIn: parent
                                text: modelData.key
                                font.family: Theme.font.monospace
                                font.pixelSize: 9
                                color: Qt.rgba(1, 1, 1, 0.6)
                            }
                        }

                        Text {
                            text: modelData.action
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            color: Qt.rgba(1, 1, 1, 0.45)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Item count
                Text {
                    text: folderModel.count + " items"
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    color: Qt.rgba(1, 1, 1, 0.45)
                }
            }
        }
    }
}
