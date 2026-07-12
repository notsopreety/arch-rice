import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"
import "../components"
import "../services"

PanelWindow {
    id: root
    visible: false

    property var activeScreen: null
    property string mode: "region" // "region", "window", "screen"
    property bool saveToDisk: true // Option to save to disk

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var hyprlandMonitor: Hyprland.focusedMonitor
    property string tempPath: ""

    // ── Open / Close ──────────────────────────────────────────────────────
    function open() {
        activeScreen = null
        mode = "region" // Default mode
        const monitor = Hyprland.focusedMonitor
        if (!monitor) return

        for (const scr of Quickshell.screens) {
            if (scr.name === monitor.name) {
                activeScreen = scr
                screen = scr

                const ts = Date.now()
                tempPath = Quickshell.cachePath(`snip-freeze-${ts}.png`)
                Quickshell.execDetached(["grim", "-g",
                    `${scr.x},${scr.y} ${scr.width}x${scr.height}`, tempPath])
                showTimer.start()
                return
            }
        }
    }

    function close() {
        root.visible = false
        regionSelector.reset()
        windowSelector.reset()
    }

    Timer {
        id: showTimer
        interval: 50
        repeat: false
        onTriggered: root.visible = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: () => {
            Quickshell.execDetached(["rm", "-f", tempPath])
            root.close()
        }
    }

    // ── Frozen screen background ──────────────────────────────────────────
    ScreencopyView {
        captureSource: root.activeScreen
        anchors.fill: parent
        z: -1
    }

    // ── Shader Helper Function ────────────────────────────────────────────
    function getShaderUrl() {
        return Qt.resolvedUrl("../shaders/dimming.frag.qsb")
    }

    // ── Region Selector Mode ──────────────────────────────────────────────
    Item {
        id: regionSelector
        anchors.fill: parent
        visible: root.mode === "region"

        signal regionSelected(real x, real y, real width, real height)

        property point startPos
        property real selectionX: 0
        property real selectionY: 0
        property real selectionWidth: 0
        property real selectionHeight: 0

        property real targetX: 0
        property real targetY: 0
        property real targetWidth: 0
        property real targetHeight: 0

        function reset() {
            selectionX = 0; selectionY = 0
            selectionWidth = 0; selectionHeight = 0
            targetX = 0; targetY = 0
            targetWidth = 0; targetHeight = 0
        }

        Behavior on selectionX { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionY { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionWidth { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionHeight { SpringAnimation { spring: 4; damping: 0.4 } }

        ShaderEffect {
            anchors.fill: parent
            z: 0

            property vector4d selectionRect: Qt.vector4d(
                regionSelector.selectionX,
                regionSelector.selectionY,
                regionSelector.selectionWidth,
                regionSelector.selectionHeight
            )
            property real dimOpacity: 0.6
            property vector2d screenSize: Qt.vector2d(regionSelector.width, regionSelector.height)
            property real borderRadius: 10.0
            property real outlineThickness: 2.0

            fragmentShader: root.getShaderUrl()
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            z: 3
            cursorShape: Qt.CrossCursor

            Timer {
                id: updateTimer
                interval: 16
                repeat: true
                running: mouseArea.pressed
                onTriggered: {
                    regionSelector.selectionX = regionSelector.targetX
                    regionSelector.selectionY = regionSelector.targetY
                    regionSelector.selectionWidth = regionSelector.targetWidth
                    regionSelector.selectionHeight = regionSelector.targetHeight
                }
            }

            onPressed: (mouse) => {
                regionSelector.startPos = Qt.point(mouse.x, mouse.y)
                regionSelector.targetX = mouse.x
                regionSelector.targetY = mouse.y
                regionSelector.targetWidth = 0
                regionSelector.targetHeight = 0
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    const x = Math.min(regionSelector.startPos.x, mouse.x)
                    const y = Math.min(regionSelector.startPos.y, mouse.y)
                    const w = Math.abs(mouse.x - regionSelector.startPos.x)
                    const h = Math.abs(mouse.y - regionSelector.startPos.y)

                    regionSelector.targetX = x
                    regionSelector.targetY = y
                    regionSelector.targetWidth = w
                    regionSelector.targetHeight = h
                }
            }

            onReleased: {
                regionSelector.regionSelected(
                    Math.round(regionSelector.selectionX),
                    Math.round(regionSelector.selectionY),
                    Math.round(regionSelector.selectionWidth),
                    Math.round(regionSelector.selectionHeight)
                )
            }
        }

        onRegionSelected: (x, y, w, h) => {
            if (w < 5 || h < 5) {
                root.close()
                return
            }
            root.processRegion(x, y, w, h)
        }
    }

    // ── Window Selector Mode ──────────────────────────────────────────────
    Item {
        id: windowSelector
        anchors.fill: parent
        visible: root.mode === "window"

        signal regionSelected(real x, real y, real width, real height)

        property var monitor: Hyprland.focusedMonitor
        property var workspace: monitor ? monitor.activeWorkspace : null
        property var windows: (workspace && workspace.toplevels) ? workspace.toplevels : []

        signal checkHover(real mouseX, real mouseY)

        property real selectionX: 0
        property real selectionY: 0
        property real selectionWidth: 0
        property real selectionHeight: 0

        function reset() {
            selectionX = 0; selectionY = 0
            selectionWidth = 0; selectionHeight = 0
        }

        Behavior on selectionX { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionY { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionWidth { SpringAnimation { spring: 4; damping: 0.4 } }
        Behavior on selectionHeight { SpringAnimation { spring: 4; damping: 0.4 } }

        ShaderEffect {
            anchors.fill: parent
            z: 0

            property vector4d selectionRect: Qt.vector4d(
                windowSelector.selectionX,
                windowSelector.selectionY,
                windowSelector.selectionWidth,
                windowSelector.selectionHeight
            )
            property real dimOpacity: 0.6
            property vector2d screenSize: Qt.vector2d(windowSelector.width, windowSelector.height)
            property real borderRadius: 10.0
            property real outlineThickness: 2.0

            fragmentShader: root.getShaderUrl()
        }

        Repeater {
            model: windowSelector.windows

            Item {
                required property var modelData

                Connections {
                    target: windowSelector

                    function onCheckHover(mouseX, mouseY) {
                        const monitorX = windowSelector.monitor.lastIpcObject.x
                        const monitorY = windowSelector.monitor.lastIpcObject.y
                        
                        const windowX = modelData.lastIpcObject.at[0] - monitorX
                        const windowY = modelData.lastIpcObject.at[1] - monitorY
                        
                        const w = modelData.lastIpcObject.size[0]
                        const h = modelData.lastIpcObject.size[1]

                        if (mouseX >= windowX && mouseX <= windowX + w && mouseY >= windowY && mouseY <= windowY + h) {
                            windowSelector.selectionX = windowX
                            windowSelector.selectionY = windowY
                            windowSelector.selectionWidth = w
                            windowSelector.selectionHeight = h
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPositionChanged: (mouse) => {
                windowSelector.checkHover(mouse.x, mouse.y)
            }

            onReleased: (mouse) => {
                if (mouse.x >= windowSelector.selectionX && mouse.x <= windowSelector.selectionX + windowSelector.selectionWidth &&
                    mouse.y >= windowSelector.selectionY && mouse.y <= windowSelector.selectionY + windowSelector.selectionHeight) {
                    windowSelector.regionSelected(
                        Math.round(windowSelector.selectionX),
                        Math.round(windowSelector.selectionY),
                        Math.round(windowSelector.selectionWidth),
                        Math.round(windowSelector.selectionHeight)
                    )
                }
            }
        }

        onRegionSelected: (x, y, w, h) => {
            if (w < 5 || h < 5) return
            root.processRegion(x, y, w, h)
        }
    }

    // ── Entire Screen Mode ────────────────────────────────────────────────
    Item {
        id: screenSelector
        anchors.fill: parent
        visible: root.mode === "screen"

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.15
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onReleased: {
                root.processRegion(0, 0, root.width, root.height)
            }
        }
    }

    // ── UI Selection Overlay and Mode Toggle ──────────────────────────────
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        z: 10

        width: toolbarRow.width + 24
        height: 48
        color: Qt.rgba(0.06, 0.06, 0.08, 0.9)
        radius: 14
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        RowLayout {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 12

            DankIcon {
                name: "content_cut"
                size: 18
                color: Theme.primary
            }

            Text {
                text: "Snip Tool"
                font.family: Theme.font.family
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "white"
            }

            Rectangle {
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Mode Selector
            RowLayout {
                spacing: 4
                Layout.preferredWidth: 260
                Layout.preferredHeight: 32

                Repeater {
                    model: [
                        { mode: "region", icon: "crop_free", label: "Region" },
                        { mode: "window", icon: "window", label: "Window" },
                        { mode: "screen", icon: "monitor", label: "Screen" }
                    ]

                    Button {
                        id: modeBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter

                        background: Rectangle {
                            radius: 8
                            color: {
                                if (root.mode === modelData.mode) return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                if (modeBtn.hovered) return Qt.rgba(1, 1, 1, 0.05)
                                return "transparent"
                            }
                            border.color: root.mode === modelData.mode ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6) : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        contentItem: RowLayout {
                            anchors.fill: parent
                            spacing: 4
                            DankIcon {
                                Layout.alignment: Qt.AlignVCenter
                                size: 14
                                name: modelData.icon
                                color: root.mode === modelData.mode ? "white" : Qt.rgba(1, 1, 1, 0.6)
                            }
                            Text {
                                text: modelData.label
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                font.weight: root.mode === modelData.mode ? Font.Bold : Font.Normal
                                color: root.mode === modelData.mode ? "white" : Qt.rgba(1, 1, 1, 0.6)
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                Layout.fillWidth: true
                            }
                        }

                        onClicked: {
                            root.mode = modelData.mode
                        }
                    }
                }
            }

            Rectangle {
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Save to Disk Switch
            RowLayout {
                spacing: 6
                Text {
                    text: "Save disk"
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
                Switch {
                    id: diskSwitch
                    checked: root.saveToDisk
                    onCheckedChanged: root.saveToDisk = checked
                    
                    // Style switch slightly smaller
                    scale: 0.8
                }
            }

            Rectangle {
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            Text {
                text: "ESC to cancel"
                font.family: Theme.font.family
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.35)
            }
        }
    }

    // ── Process the selected region ───────────────────────────────────────
    function processRegion(x, y, w, h) {
        root.close()

        const scale = hyprlandMonitor.scale
        const sx = Math.round(x * scale)
        const sy = Math.round(y * scale)
        const sw = Math.round(w * scale)
        const sh = Math.round(h * scale)

        const picturesDir = "/home/sawmer/Pictures/Screenshots"
        const now = new Date()
        const ts = Qt.formatDateTime(now, "yyyy-MM-dd_hh-mm-ss")
        const outputFilename = `screenshot-${ts}.png`
        const outputPath = `${picturesDir}/${outputFilename}`

        const cropPath = `/tmp/snip-crop-${Date.now()}.png`

        cropProc.command = ["sh", "-c",
            `magick "${tempPath}" -crop ${sw}x${sh}+${sx}+${sy} "${cropPath}" && ` +
            `wl-copy < "${cropPath}" && ` +
            (root.saveToDisk ? `mkdir -p "${picturesDir}" && cp "${cropPath}" "${outputPath}" && ` : "") +
            `notify-send -r 1010 -a "Snip Tool" -i "${cropPath}" "Screenshot Captured" "${root.saveToDisk ? "Saved to Screenshots and clipboard" : "Copied to clipboard"}" && ` +
            `rm -f "${cropPath}" "${tempPath}"`
        ]

        cropProc.running = true
    }

    Process {
        id: cropProc
        running: false
        onExited: code => {
            if (code !== 0) {
                Logger.error("SnipTool", `Capture failed (code: ${code})`)
            } else {
                Logger.info("SnipTool", "Snip captured successfully")
            }
        }
    }
}
