import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import "../../theme"
import "../../services"
import "../../components"
import "../../core"
import "../"

PanelWindow {
    id: main

    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlag.reload()
        onLoaded: main.glassmorphism = true
        onLoadFailed: main.glassmorphism = false
        Component.onCompleted: {
            try { glassFlag.reload(); } catch(e) {}
        }
    }

    // Responsive card dimensions
    readonly property real cardWidth: Math.min(260 * Appearance.effectiveScale, main.width * 0.25)
    readonly property real cardHeight: cardWidth * (380 / 260)


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
        color: main.glassmorphism 
            ? Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.35) 
            : "#000000"
        opacity: main.visible ? (main.glassmorphism ? 1.0 : 0.65) : 0.0

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
        width: parent.width
        height: main.cardHeight + 140 * Appearance.effectiveScale
        anchors.centerIn: parent
        focus: true
        model: folderModel

        path: Path {
            startX: 0
            startY: carousel.height / 2

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.7 }
            PathAttribute { name: "itemOpacity"; value: 0.45 }

            PathLine {
                x: carousel.width * 0.38
                y: carousel.height / 2
            }
            PathPercent { value: 0.38 }

            PathAttribute { name: "z"; value: 15 }
            PathAttribute { name: "itemScale"; value: 0.82 }
            PathAttribute { name: "itemOpacity"; value: 0.75 }

            PathLine {
                x: carousel.width / 2
                y: carousel.height / 2
            }
            PathPercent { value: 0.5 }

            PathAttribute { name: "z"; value: 100 }
            PathAttribute { name: "itemScale"; value: 1.0 }
            PathAttribute { name: "itemOpacity"; value: 1.0 }

            PathLine {
                x: carousel.width * 0.62
                y: carousel.height / 2
            }
            PathPercent { value: 0.62 }

            PathAttribute { name: "z"; value: 15 }
            PathAttribute { name: "itemScale"; value: 0.82 }
            PathAttribute { name: "itemOpacity"; value: 0.75 }

            PathLine {
                x: carousel.width
                y: carousel.height / 2
            }
            PathPercent { value: 1.0 }

            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "itemScale"; value: 0.7 }
            PathAttribute { name: "itemOpacity"; value: 0.45 }
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
            width: main.cardWidth
            height: main.cardHeight

            property real itemScale: PathView.itemScale !== undefined ? PathView.itemScale : 0.7
            property real itemZ: PathView.z !== undefined ? PathView.z : 0
            property real itemOpacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 0.45
            property bool isCurrent: PathView.isCurrentItem

            z: itemZ
            opacity: itemOpacity
            scale: itemScale

            transform: Rotation {
                origin.x: delegate.width / 2
                origin.y: delegate.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: {
                    let center = (carousel.width - delegate.width) / 2;
                    let offset = delegate.x - center;
                    let maxDist = carousel.width / 2;
                    let pct = Math.max(-1.0, Math.min(1.0, offset / maxDist));
                    return pct * -45;
                }
            }

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
        anchors.bottom: carousel.top
        anchors.bottomMargin: 16 * Appearance.effectiveScale
        text: (main.selectedIndex + 1) + " / " + folderModel.count
        color: Theme.onSurfaceVariantColor
        font.pixelSize: 16 * Appearance.effectiveScale
        font.family: Theme.font.family
        font.weight: Font.Medium
    }

    // ============================================
    // BOTTOM UNIFIED CONTROL DOCK (Material You Design)
    // ============================================
    Rectangle {
        id: controlDock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: carousel.bottom
        anchors.topMargin: 24 * Appearance.effectiveScale
        height: 56 * Appearance.effectiveScale
        width: (searchContainer.expanded ? 320 : 160) * Appearance.effectiveScale
        radius: height / 2
        
        color: main.glassmorphism 
            ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.22) 
            : Theme.surfaceContainerHigh
        border.width: 1
        border.color: main.glassmorphism 
            ? Qt.rgba(1, 1, 1, 0.18) 
            : Theme.outlineVariant
            
        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // Glassmorphic vertical gloss overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: main.glassmorphism
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12 * Appearance.effectiveScale

            // ── Shuffle Button ──
            Rectangle {
                id: randButton
                width: 40 * Appearance.effectiveScale
                height: 40 * Appearance.effectiveScale
                radius: width / 2
                color: "transparent"
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "shuffle"
                    iconSize: 20 * Appearance.effectiveScale
                    color: randMouse.containsMouse ? Theme.primary : Theme.onSurfaceColor
                    Behavior on color { ColorAnimation { duration: 150 } }
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

                StyledToolTip {
                    text: "Random Wallpaper"
                    alternativeVisibleCondition: randMouse.containsMouse
                }
            }

            // ── Search Input (Expands inside capsule) ──
            Item {
                id: searchWrapper
                width: searchContainer.expanded ? 180 * Appearance.effectiveScale : 40 * Appearance.effectiveScale
                height: 40 * Appearance.effectiveScale
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: searchContainer
                    property bool expanded: false
                    anchors.fill: parent
                    radius: expanded ? 8 * Appearance.effectiveScale : height / 2
                    color: "transparent"
                    border.width: expanded ? (searchInput.activeFocus ? 2 : 1) : 0
                    border.color: expanded 
                        ? (searchInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)) 
                        : "transparent"
                    
                    Behavior on radius { NumberAnimation { duration: 200 } }

                    MaterialSymbol {
                        text: "search"
                        iconSize: 20 * Appearance.effectiveScale
                        color: (searchMouse.containsMouse || searchContainer.expanded) ? Theme.primary : Theme.onSurfaceColor
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * Appearance.effectiveScale
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    TextInput {
                        id: searchInput
                        visible: searchContainer.expanded
                        opacity: searchContainer.expanded ? 1.0 : 0.0
                        anchors.left: parent.left
                        anchors.leftMargin: 36 * Appearance.effectiveScale
                        anchors.right: closeSearch.left
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.onSurfaceColor
                        font.pixelSize: 14 * Appearance.effectiveScale
                        font.family: "Inter"
                        selectByMouse: true
                        selectionColor: Theme.primaryContainer
                        selectedTextColor: Theme.onPrimaryContainer
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                searchContainer.expanded = false;
                                carousel.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                        onTextChanged: main.searchQuery = text
                        onAccepted: carousel.forceActiveFocus()
                    }

                    Text {
                        text: "Search..."
                        color: Qt.rgba(255, 255, 255, 0.35)
                        font: searchInput.font
                        visible: !searchInput.text && !searchInput.activeFocus && searchContainer.expanded
                        anchors.left: parent.left
                        anchors.leftMargin: 36 * Appearance.effectiveScale
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        id: closeSearch
                        visible: searchContainer.expanded
                        width: 24 * Appearance.effectiveScale
                        height: 24 * Appearance.effectiveScale
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 16 * Appearance.effectiveScale
                            color: closeSearch.containsMouse ? Theme.primary : Theme.outline
                            Behavior on color { ColorAnimation { duration: 150 } }
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

                // Floating label overlapping the top border of searchContainer
                Rectangle {
                    x: 12 * Appearance.effectiveScale
                    y: -6 * Appearance.effectiveScale
                    height: 14 * Appearance.effectiveScale
                    width: labelText.implicitWidth + 8 * Appearance.effectiveScale
                    color: controlDock.color
                    visible: searchContainer.expanded
                    
                    Text {
                        id: labelText
                        anchors.centerIn: parent
                        text: "Search"
                        font.pixelSize: 10 * Appearance.effectiveScale
                        font.family: "Inter"
                        font.weight: Font.Medium
                        color: searchInput.activeFocus ? Theme.primary : Theme.outline
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }

                StyledToolTip {
                    text: "Search Wallpapers"
                    alternativeVisibleCondition: searchMouse.containsMouse && !searchContainer.expanded
                }
            }

            // ── Refresh Button ──
            Rectangle {
                id: reloadButton
                width: 40 * Appearance.effectiveScale
                height: 40 * Appearance.effectiveScale
                radius: width / 2
                color: "transparent"
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 20 * Appearance.effectiveScale
                    color: reloadMouse.containsMouse ? Theme.primary : Theme.onSurfaceColor
                    Behavior on color { ColorAnimation { duration: 150 } }
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

                StyledToolTip {
                    text: "Clear Cache & Reload"
                    alternativeVisibleCondition: reloadMouse.containsMouse
                }
            }
        }
    }
    }
}
