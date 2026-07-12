import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import "../../theme"
import "../../services"
import "../../components"

PanelWindow {
    id: main

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: WallpaperService.visible

    aboveWindows: true
    exclusionMode: "Ignore"
    exclusiveZone: -1

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: WallpaperService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: {
        Quickshell.execDetached(["bash", Quickshell.shellPath("widgets/wallpaper/cache.sh")])
    }

    onVisibleChanged: {
        if (visible) {
            carousel.forceActiveFocus();
            initialIndexSet = false;
            readCurrentWallpaper.running = false;
            readCurrentWallpaper.running = true;
            openAnim.restart();
        }
    }

    // ============================================
    // CONFIGURATION
    // ============================================
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

    // ============================================
    // CURRENT WALLPAPER DETECTION
    // ============================================
    property string currentWallpaperPath: ""
    property bool initialIndexSet: false

    Process {
        id: readCurrentWallpaper
        command: ["cat", "/home/sawmer/.cache/awww-wal/current"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                main.currentWallpaperPath = data.trim()
                main.setInitialIndex()
            }
        }
    }

    function setInitialIndex() {
        if (initialIndexSet || folderModel.count === 0 || !currentWallpaperPath) return

        // Extract just the filename
        let parts = currentWallpaperPath.split("/")
        let targetName = parts[parts.length - 1]

        for (let i = 0; i < folderModel.count; i++) {
            let fn = folderModel.get(i, "fileName")
            if (fn === targetName) {
                carousel.currentIndex = i
                selectedIndex = i
                initialIndexSet = true
                return
            }
        }
        initialIndexSet = true
    }

    // ============================================
    // WALLPAPER MODEL
    // ============================================
    FolderListModel {
        id: folderModel
        folder: configs.wallpaper_path ? ("file://" + configs.wallpaper_path) : ""
        showDirs: false
        caseSensitive: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        sortField: FolderListModel.Name

        onCountChanged: main.setInitialIndex()
    }

    // ============================================
    // STATE & PROPERTIES
    // ============================================
    property string searchQuery: ""
    onSearchQueryChanged: {
        let q = searchQuery.trim()
        if (q === "") {
            folderModel.nameFilters = ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        } else {
            folderModel.nameFilters = ["*" + q + "*.png", "*" + q + "*.jpg", "*" + q + "*.jpeg", "*" + q + "*.webp"]
        }
    }

    property int selectedIndex: 0

    function activateCurrent() {
        const path = folderModel.get(selectedIndex, "filePath")
        if (path) {
            Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=" + path])
        }
        WallpaperService.close()
    }

    // ============================================
    // BACKGROUND DIM - click to close
    // ============================================
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: main.visible ? 0.6 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.anim.durationNormal
                easing.bezierCurve: Theme.anim.curve
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: WallpaperService.close()
        }
    }

    // Main UI container for animation
    Item {
        id: contentContainer
        anchors.fill: parent

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: contentContainer; property: "scale"; from: 0.95; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { target: contentContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
        }

        // ============================================
        // HORIZONTAL SPOTLIGHT SLIDER
        // ============================================
        PathView {
        id: carousel
        anchors.fill: parent
        focus: true
        model: folderModel

        path: Path {
            startX: 0
            startY: carousel.height / 2

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }

            PathLine {
                x: carousel.width / 2
                y: carousel.height / 2
            }

            PathAttribute { name: "z"; value: 100 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }

            PathLine {
                x: carousel.width
                y: carousel.height / 2
            }

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.65 }
            PathAttribute { name: "itemOpacity"; value: 0.35 }
        }

        pathItemCount: configs.number_of_pictures

        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: main.initialIndexSet ? Theme.anim.durationLong : 0

        currentIndex: main.selectedIndex
        onCurrentIndexChanged: main.selectedIndex = currentIndex

        snapMode: PathView.SnapToItem
        flickDeceleration: 1200
        maximumFlickVelocity: 800

        // ============================================
        // DELEGATE - CARDS
        // ============================================
        delegate: Item {
            id: delegate
            width: 260
            height: 380

            property real itemScale: PathView.itemScale !== undefined ? PathView.itemScale : 0.65
            property real itemZ: PathView.z !== undefined ? PathView.z : 0
            property real itemOpacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.35
            property bool isCurrent: PathView.isCurrentItem

            z: itemZ
            opacity: itemOpacity
            scale: itemScale

            // Glow / Shadow behind the current card
            Rectangle {
                visible: isCurrent
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                radius: Theme.rounding.large + 4
                border.width: 2
                border.color: Theme.primary
                opacity: 0.4
            }

            // Image Container
            Rectangle {
                id: imageContainer
                anchors.fill: parent
                color: Theme.surfaceContainer
                radius: Theme.rounding.large
                border.width: isCurrent ? 2 : 1
                border.color: isCurrent ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                clip: true

                Image {
                    id: img
                    anchors.fill: parent
                    anchors.margins: isCurrent ? 2 : 1
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true

                    // Safely construct thumbnail name
                    property string thumbName: fileName ? (fileName.substring(0, fileName.lastIndexOf('.')) + ".jpg") : ""
                    source: (configs.cache_path && thumbName) ? ("file://" + configs.cache_path + thumbName) : ""

                    sourceSize.width: 400
                    sourceSize.height: 600

                    // Mask the image corners
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: img.width
                            height: img.height
                            radius: Theme.rounding.large - 2
                        }
                    }

                    Rectangle {
                        visible: img.status !== Image.Ready
                        anchors.fill: parent
                        color: Theme.surfaceContainer

                        Text {
                            anchors.centerIn: parent
                            text: "Loading..."
                            color: Theme.onSurfaceVariantColor
                            font.family: Theme.font.family
                            font.pixelSize: 13
                        }
                    }

                    onStatusChanged: {
                        if (status === Image.Error) {
                            retryTimer.start()
                        }
                    }

                    Timer {
                        id: retryTimer
                        interval: 1000
                        repeat: false
                        onTriggered: {
                            let s = img.source
                            img.source = ""
                            img.source = s
                        }
                    }
                }
            }

            // Filename Label (current only)
            Text {
                visible: isCurrent
                anchors.top: imageContainer.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: imageContainer.horizontalCenter
                text: fileName ? fileName.replace(/\.[^/.]+$/, "") : ""
                color: Theme.primary
                font.pixelSize: 14
                font.weight: Font.Bold
                font.family: Theme.font.family
            }

            // Click interaction
            MouseArea {
                anchors.fill: imageContainer
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (isCurrent) {
                        main.activateCurrent()
                    } else {
                        carousel.currentIndex = index
                        main.selectedIndex = index
                    }
                }
            }
        }

        // ============================================
        // KEYBOARD CONTROLS
        // ============================================
        Keys.onPressed: function(event) {
            switch (event.key) {
                case Qt.Key_Right:
                case Qt.Key_L:
                case Qt.Key_D:
                    carousel.incrementCurrentIndex()
                    break

                case Qt.Key_Left:
                case Qt.Key_H:
                case Qt.Key_A:
                    carousel.decrementCurrentIndex()
                    break

                case Qt.Key_Space:
                case Qt.Key_Return:
                    main.activateCurrent()
                    break

                case Qt.Key_Escape:
                    WallpaperService.close()
                    break

                default:
                    return
            }
            event.accepted = true
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton

            property bool wheelLocked: false

            Timer {
                id: wheelCooldown
                interval: 80
                onTriggered: parent.wheelLocked = false
            }

            onWheel: function(wheel) {
                if (wheelLocked) { wheel.accepted = true; return }
                let dy = wheel.angleDelta.y
                let dx = wheel.angleDelta.x
                let delta = Math.abs(dy) > Math.abs(dx) ? dy : dx
                if (delta < 0) {
                    carousel.incrementCurrentIndex()
                } else if (delta > 0) {
                    carousel.decrementCurrentIndex()
                }
                wheelLocked = true
                wheelCooldown.restart()
                wheel.accepted = true
            }
        }
    }

    // ============================================
    // COUNTER (above spotlight)
    // ============================================
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - 230
        text: (main.selectedIndex + 1) + " / " + folderModel.count
        color: Theme.onSurfaceVariantColor
        font.pixelSize: 16
        font.family: Theme.font.family
        font.weight: Font.Medium
    }

    // ============================================
    // BOTTOM CONTROLS
    // ============================================
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + 265
        spacing: 16

        // Random button
        Rectangle {
            id: randButton
            width: 48; height: 48; radius: 14
            color: randMouse.pressed ? Theme.surfaceContainerLow : randMouse.containsMouse ? Theme.primary : Theme.surfaceContainer
            opacity: randMouse.containsMouse ? 1.0 : 0.8
            border.width: 1
            border.color: randMouse.containsMouse ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

            Behavior on color { ColorAnimation { duration: 150 } }

            DankIcon {
                anchors.centerIn: parent
                name: "shuffle"
                size: 20
                color: randMouse.containsMouse ? Theme.onPrimaryColor : Theme.primary
            }

            MouseArea {
                id: randMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["/home/sawmer/.config/scripts/wall.sh", "-i=rand"])
                    WallpaperService.close()
                }
            }
        }

        // Search button/box wrapper to prevent clipping of floating label
        Item {
            id: searchWrapper
            width: searchContainer.expanded ? 240 : 48
            height: 48

            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Rectangle {
                id: searchContainer
                property bool expanded: false
                anchors.fill: parent
                radius: expanded ? 8 : 14
                color: expanded ? "transparent" : (searchMouse.pressed ? Theme.surfaceContainerLow : searchMouse.containsMouse ? Theme.primary : Theme.surfaceContainer)
                opacity: (searchMouse.containsMouse || expanded) ? 1.0 : 0.8
                border.width: expanded ? (searchInput.activeFocus ? 2 : 1) : 1
                border.color: expanded 
                    ? (searchInput.activeFocus ? Theme.primary : Theme.outline)
                    : (searchMouse.containsMouse ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2))
                clip: true

                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }

                DankIcon {
                    name: "search"
                    size: 20
                    color: (searchMouse.containsMouse || searchContainer.expanded) 
                        ? (searchContainer.expanded && searchInput.activeFocus ? Theme.primary : Theme.onPrimaryColor) 
                        : Theme.primary
                    anchors.left: parent.left
                    anchors.leftMargin: searchContainer.expanded ? 12 : 14
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on anchors.leftMargin { NumberAnimation { duration: 200 } }
                }

                TextInput {
                    id: searchInput
                    visible: searchContainer.expanded
                    opacity: searchContainer.expanded ? 1.0 : 0.0
                    anchors.left: parent.left
                    anchors.leftMargin: 40
                    anchors.right: closeSearch.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: searchInput.activeFocus ? Theme.primary : Theme.onSurface
                    font.pixelSize: 14
                    font.family: "Inter"
                    selectByMouse: true
                    selectionColor: Theme.surfaceContainerLow
                    selectedTextColor: Theme.primary
                    
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            searchContainer.expanded = false;
                            carousel.forceActiveFocus();
                            event.accepted = true;
                        }
                    }

                    onTextChanged: {
                        main.searchQuery = text
                    }

                    onAccepted: {
                        carousel.forceActiveFocus()
                    }

                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    id: closeSearch
                    visible: searchContainer.expanded
                    width: 28
                    height: 28
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    cursorShape: Qt.PointingHandCursor
                    
                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 16
                        color: searchInput.activeFocus ? Theme.primary : Theme.outline
                    }

                    onClicked: {
                        searchInput.text = ""
                        searchContainer.expanded = false
                        carousel.forceActiveFocus()
                    }
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    visible: !searchContainer.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchContainer.expanded = true
                        searchInput.forceActiveFocus()
                    }
                }
            }

            // Floating label when expanded - placed outside clip boundary
            Rectangle {
                x: 12
                y: -7
                height: 14
                width: labelText.implicitWidth + 8
                color: Theme.background // Matches app surface container background
                visible: searchContainer.expanded
                
                Text {
                    id: labelText
                    anchors.centerIn: parent
                    text: "Wallpapers"
                    font.pixelSize: 10
                    font.family: "Inter"
                    font.weight: Font.Medium
                    color: searchInput.activeFocus ? Theme.primary : Theme.outline
                }
            }
        }

        // Reload button
        Rectangle {
            id: reloadButton
            width: 48; height: 48; radius: 14
            color: reloadMouse.pressed ? Theme.surfaceContainerLow : reloadMouse.containsMouse ? Theme.primary : Theme.surfaceContainer
            opacity: reloadMouse.containsMouse ? 1.0 : 0.8
            border.width: 1
            border.color: reloadMouse.containsMouse ? "transparent" : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

            Behavior on color { ColorAnimation { duration: 150 } }

            DankIcon {
                anchors.centerIn: parent
                name: "refresh"
                size: 20
                color: reloadMouse.containsMouse ? Theme.onPrimaryColor : Theme.primary
            }

            MouseArea {
                id: reloadMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", "rm -rf " + configs.cache_path + "* && bash " + Quickshell.shellPath("widgets/wallpaper/cache.sh")])
                }
            }
        }
    }
    }
}
