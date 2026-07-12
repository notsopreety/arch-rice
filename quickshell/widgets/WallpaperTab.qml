import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"
import "../components"

Item {
    id: root
    focus: true

    implicitWidth: 700
    implicitHeight: 410

    property int gridIndex: 0
    property string currentWallpaperPath: ""

    // JS arrays for local filtering
    property var allFiles: []
    property var filteredFiles: []

    onVisibleChanged: {
        if (visible) {
            readCurrentWallpaper.running = false;
            readCurrentWallpaper.running = true;
            wallpaperGrid.forceActiveFocus(); // Focus grid by default on open
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape && searchInput.activeFocus) {
            searchInput.focus = false;
            wallpaperGrid.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash && !searchInput.activeFocus) {
            searchInput.forceActiveFocus();
            event.accepted = true;
        } else if (handleKeyEvent(event)) {
            event.accepted = true;
        }
    }

    // Read config
    FileView {
        path: Quickshell.shellPath("widgets/wallpaper/config.json")
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: configs
            property string wallpaper_path
            property string cache_path
            property int number_of_pictures: 7
            property int cache_batch_size: 20
        }
    }

    Process {
        id: readCurrentWallpaper
        command: ["cat", "/home/sawmer/.cache/awww-wal/current"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw) {
                    root.currentWallpaperPath = raw;
                    root.setInitialSelection();
                }
            }
        }
    }

    function setInitialSelection() {
        if (!root.currentWallpaperPath || root.filteredFiles.length === 0) return;
        for (var i = 0; i < root.filteredFiles.length; i++) {
            var item = root.filteredFiles[i];
            if (item && root.cleanUrlToPath(item.filePath) === root.currentWallpaperPath) {
                root.gridIndex = i;
                wallpaperGrid.currentIndex = i;
                wallpaperGrid.positionViewAtIndex(i, GridView.Contain);
                break;
            }
        }
    }

    FolderListModel {
        id: folderModel
        folder: configs.wallpaper_path ? ("file://" + configs.wallpaper_path) : ""
        showDirs: false
        caseSensitive: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name
        onCountChanged: {
            updateAllFiles();
        }
    }

    function updateAllFiles() {
        var list = [];
        for (var i = 0; i < folderModel.count; i++) {
            var name = folderModel.get(i, "fileName");
            var path = folderModel.get(i, "filePath");
            if (name && path) {
                list.push({ fileName: name, filePath: path });
            }
        }
        allFiles = list;
        filterWallpapers();
    }

    function filterWallpapers() {
        var query = searchInput.text.toLowerCase().trim();
        if (query === "") {
            filteredFiles = allFiles;
        } else {
            filteredFiles = allFiles.filter(function(item) {
                return item.fileName.toLowerCase().includes(query);
            });
        }
        // Set selection
        if (filteredFiles.length > 0) {
            gridIndex = Math.min(gridIndex, filteredFiles.length - 1);
            if (gridIndex < 0) gridIndex = 0;
        } else {
            gridIndex = -1;
        }
        setInitialSelection();
    }

    function cleanUrlToPath(urlStr) {
        if (!urlStr) return "";
        var path = urlStr.toString();
        path = path.replace(/^file:\/\/\/?/, '/');
        try {
            path = decodeURIComponent(path);
        } catch (e) {}
        return path;
    }

    onGridIndexChanged: {
        if (wallpaperGrid.currentIndex !== gridIndex) {
            wallpaperGrid.currentIndex = gridIndex;
        }
    }

    function handleKeyEvent(event) {
        const columns = 3;
        const totalItems = root.filteredFiles.length;
        if (totalItems === 0) return false;

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (gridIndex >= 0 && gridIndex < totalItems) {
                var item = root.filteredFiles[gridIndex];
                if (item && item.filePath) {
                    var cleanPath = item.filePath.toString().replace(/^file:\/\//, '');
                    root.currentWallpaperPath = cleanPath;
                    Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=" + cleanPath]);
                    DankDashService.close(); // Close dashboard on select
                }
            }
            return true;
        }

        if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            if (gridIndex + 1 < totalItems) {
                gridIndex++;
            } else {
                gridIndex = 0;
            }
            wallpaperGrid.currentIndex = gridIndex;
            wallpaperGrid.positionViewAtIndex(gridIndex, GridView.Contain);
            return true;
        }

        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            if (gridIndex > 0) {
                gridIndex--;
            } else {
                gridIndex = totalItems - 1;
            }
            wallpaperGrid.currentIndex = gridIndex;
            wallpaperGrid.positionViewAtIndex(gridIndex, GridView.Contain);
            return true;
        }

        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            if (gridIndex + columns < totalItems) {
                gridIndex += columns;
            } else {
                gridIndex = gridIndex % columns;
            }
            wallpaperGrid.currentIndex = gridIndex;
            wallpaperGrid.positionViewAtIndex(gridIndex, GridView.Contain);
            return true;
        }

        if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (gridIndex >= columns) {
                gridIndex -= columns;
            } else {
                var lastRowIndex = gridIndex + Math.floor((totalItems - 1) / columns) * columns;
                if (lastRowIndex >= totalItems) {
                    lastRowIndex -= columns;
                }
                gridIndex = lastRowIndex;
            }
            wallpaperGrid.currentIndex = gridIndex;
            wallpaperGrid.positionViewAtIndex(gridIndex, GridView.Contain);
            return true;
        }

        return false;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: -10
        anchors.topMargin: -12
        spacing: 8

        // Search Input Box (identical to EmojiBoard)
        Item {
            Layout.fillWidth: true
            height: 48

            // Outlined container Rectangle
            Rectangle {
                id: searchBg
                anchors.fill: parent
                anchors.topMargin: 4
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
                y: -2
                height: 14
                width: labelText.implicitWidth + 8
                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1.0)
                
                Text {
                    id: labelText
                    anchors.centerIn: parent
                    text: "Search Wallpapers"
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: searchInput.activeFocus ? Theme.primary : Theme.outline
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 4
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
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    selectionColor: Theme.primary
                    selectedTextColor: "#ffffff"
                    focus: true

                    onTextChanged: root.filterWallpapers()

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                            wallpaperGrid.forceActiveFocus();
                            root.gridIndex = 0;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            searchInput.focus = false;
                            wallpaperGrid.forceActiveFocus();
                            event.accepted = true;
                        }
                    }

                    Text {
                        text: "Type to search wallpapers..."
                        color: Qt.rgba(255, 255, 255, 0.35)
                        font: searchInput.font
                        visible: !searchInput.text && !searchInput.activeFocus
                    }
                }

                // Close Button to clear search
                Rectangle {
                    width: 20; height: 20; radius: 10
                    visible: searchInput.text.length > 0
                    color: Qt.rgba(255, 255, 255, 0.1)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        color: "white"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Wallpapers Grid
        GridView {
            id: wallpaperGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: width / 3
            cellHeight: 140
            clip: true
            model: root.filteredFiles
            focus: true
            activeFocusOnTab: false
            keyNavigationEnabled: false
            currentIndex: root.gridIndex

            delegate: Item {
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                // Selection/Hover Ring (outside the clipped card frame)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 16
                    color: "transparent"
                    border.color: index === root.gridIndex 
                        ? Theme.primary 
                        : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45)
                    border.width: index === root.gridIndex ? 2 : 1.5
                    visible: index === root.gridIndex || mouseArea.containsMouse
                    z: 10
                }

                // Card Container
                Rectangle {
                    id: cardFrame
                    anchors.fill: parent
                    anchors.margins: 8
                    radius: 12
                    color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)
                    border.color: index === root.gridIndex 
                        ? Theme.primary 
                        : (mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5) : Qt.rgba(255, 255, 255, 0.08))
                    border.width: index === root.gridIndex ? 2 : 1
                    clip: true

                    // Scale animation on hover/selection
                    transform: Scale {
                        origin.x: cardFrame.width / 2
                        origin.y: cardFrame.height / 2
                        xScale: (mouseArea.containsMouse || index === root.gridIndex) ? 1.02 : 1.0
                        yScale: xScale
                        Behavior on xScale {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                    }

                    // Rounded Mask for OpacityMask
                    Rectangle {
                        id: maskShape
                        anchors.fill: parent
                        radius: 12
                        visible: false
                    }

                    Image {
                        id: wallImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: false

                        property string thumbName: modelData.fileName ? (modelData.fileName.substring(0, modelData.fileName.lastIndexOf('.')) + ".jpg") : ""
                        source: (configs.cache_path && thumbName) ? ("file://" + configs.cache_path + thumbName) : ""

                        onStatusChanged: {
                            if (status === Image.Error) {
                                source = modelData.filePath;
                            }
                        }
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: wallImage
                        maskSource: maskShape
                    }

                    // Put everything that overlays the image inside a container and clip it using OpacityMask
                    Item {
                        id: cardContent
                        anchors.fill: parent

                        // Subtle darken overlay
                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: mouseArea.containsMouse ? 0.1 : 0.25
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Glassmorphic name tag pill
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 8
                            height: 26
                            radius: 8
                            color: Qt.rgba(0, 0, 0, 0.6)
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 16
                                text: modelData.fileName ? modelData.fileName.replace(/\.[^/.]+$/, "") : ""
                                color: "white"
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        // Selection Checkmark Badge
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            width: 20
                            height: 20
                            radius: 10
                            color: Theme.primary
                            visible: {
                                if (!modelData.filePath || !root.currentWallpaperPath) return false;
                                return root.cleanUrlToPath(modelData.filePath) === root.currentWallpaperPath;
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.family: Theme.font.monospace
                                font.pixelSize: 11
                                color: "white"
                            }
                        }
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: cardContent
                        maskSource: maskShape
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.gridIndex = index;
                            wallpaperGrid.currentIndex = index;
                            if (modelData.filePath) {
                                var cleanPath = modelData.filePath.toString().replace(/^file:\/\//, '');
                                root.currentWallpaperPath = cleanPath;
                                Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=" + cleanPath]);
                                DankDashService.close(); // Close dashboard on select
                            }
                        }
                    }
                }
            }
        }
    }
}
