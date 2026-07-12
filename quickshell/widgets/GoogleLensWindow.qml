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
                tempPath = Quickshell.cachePath(`lens-freeze-${ts}.png`)
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

        // Fullscreen dim overlay that clicks to search the whole screen
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

    // ── UI Selection Overlay and Mode Toggle (UX matches hyprquickshot) ────
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
                name: "image_search"
                size: 18
                color: Theme.primary
            }

            Text {
                text: "Google Lens"
                font.family: Theme.font.family
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "white"
            }

            Rectangle {
                width: 1; height: 16
                color: Qt.rgba(1, 1, 1, 0.15)
            }

            // Mode Selector inside the main bar
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

        // Crop from the frozen screenshot, upload, and open in Lens
        const cropPath = `/tmp/lens-crop-${Date.now()}.png`
        cropProc.exec(["magick", tempPath, "-crop", `${sw}x${sh}+${sx}+${sy}`, cropPath])

        root._cropPath = cropPath
    }

    property string _cropPath: ""

    Process {
        id: cropProc
        onExited: code => {
            cleanupProc.exec(["rm", "-f", root.tempPath])

            if (code !== 0) {
                Logger.error("GoogleLens", `Crop failed (code: ${code})`)
                return
            }

            uploadProc.exec(["bash", "-c",
                `RESP=$(curl -sS -f -F "files[]=@${root._cropPath}" "https://uguu.se/upload" 2>/dev/null); ` +
                `rm -f "${root._cropPath}"; ` +
                `[ -z "$RESP" ] && exit 3; ` +
                `URL=$(echo "$RESP" | jq -r ".files[0].url" 2>/dev/null); ` +
                `[ -z "$URL" ] || [ "$URL" = "null" ] && exit 4; ` +
                `notify-send -r 1009 -a "Google Lens" -i "web-browser" "Google Lens" "Opening visual search..." || true; ` +
                `xdg-open "https://lens.google.com/uploadbyurl?url=$URL"`
            ])
        }
    }

    Process {
        id: uploadProc
        onExited: code => {
            if (code === 0) {
                Logger.info("GoogleLens", "Visual search opened in browser")
            } else {
                Logger.error("GoogleLens", `Upload/open failed (code: ${code})`)
            }
        }
    }

    Process {
        id: cleanupProc
    }
}
