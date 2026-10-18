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
import "sidebar"

PanelWindow {
    id: window

    property int activeTab: 0

    property var tabs: [
        { name: "Intelligence", icon: "neurology" },
        { name: "Anime", icon: "bookmark_heart" },
        { name: "Translator", icon: "translate" }
    ]

    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlag.reload()
        onLoaded: window.glassmorphism = true
        onLoadFailed: window.glassmorphism = false
        Component.onCompleted: {
            try { glassFlag.reload(); } catch(e) {}
        }
    }
    // Glassmorphic surface helpers (matching ControlCenterWindow)
    readonly property color glassCanvasBg: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35)
    readonly property color glassBorder:   Qt.rgba(1, 1, 1, 0.18)

    // Solid (non-glass) surface helpers
    readonly property color solidCanvasBg: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1.0)
    readonly property color solidBorder:   Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

    property real sidebarWidth: 440 * Appearance.effectiveScale

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true
        onLoaded: {
            try {
                let data = JSON.parse(text());
                if (data && data.sidebar && data.sidebar.width) {
                    window.sidebarWidth = data.sidebar.width * Appearance.effectiveScale;
                }
            } catch(e) {}
        }
    }

    Process {
        id: saveSettingsProc
        running: false
    }

    function saveWidth() {
        let rawW = Math.round(window.sidebarWidth / Appearance.effectiveScale);
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "data.setdefault('sidebar', {})['width'] = " + rawW + "; " +
                  "tmp = path + '.tmp'; f = open(tmp, 'w'); json.dump(data, f, indent=2); f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-sidebar"
    WlrLayershell.keyboardFocus: SidebarService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: SidebarService.visible || container.opacity > 0

    onVisibleChanged: {
        if (visible) {
            sidebarScope.forceActiveFocus();
        }
    }

    FocusScope {
        id: sidebarScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                SidebarService.close();
                event.accepted = true;
            }
        }

        // Transparent backdrop
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: SidebarService.close()
            }
        }

        // Sidebar card container
        Item {
            id: container
            width: Math.max(360 * Appearance.effectiveScale, Math.min(window.width - 32 * Appearance.effectiveScale, window.sidebarWidth))
            height: Math.min(window.height - 60 * Appearance.effectiveScale, Math.max(480 * Appearance.effectiveScale, window.height - 80 * Appearance.effectiveScale))
            x: 16 * Appearance.effectiveScale
            y: 50 * Appearance.effectiveScale

            transform: Translate {
                id: containerTranslate
            }

            states: [
                State {
                    name: "open"
                    when: SidebarService.visible
                    PropertyChanges { target: container; opacity: 1 }
                    PropertyChanges { target: containerTranslate; x: 0 }
                },
                State {
                    name: "closed"
                    when: !SidebarService.visible
                    PropertyChanges { target: container; opacity: 0 }
                    PropertyChanges { target: containerTranslate; x: -container.width - 40 * Appearance.effectiveScale }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { target: container; property: "opacity"; duration: 250; easing.type: Easing.OutCubic }
                        NumberAnimation { target: containerTranslate; property: "x"; duration: 350; easing.type: Easing.OutBack }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { target: container; property: "opacity"; duration: 200; easing.type: Easing.InCubic }
                        NumberAnimation { target: containerTranslate; property: "x"; duration: 250; easing.type: Easing.InCubic }
                    }
                }
            ]

            Rectangle {
                id: sidebarCard
                anchors.fill: parent
                radius: 24 * Appearance.effectiveScale

                // Block clicks from reaching backdrop
                MouseArea { anchors.fill: parent }

                color: window.glassmorphism ? window.glassCanvasBg : window.solidCanvasBg
                border.color: window.glassmorphism ? window.glassBorder : window.solidBorder
                border.width: 1
                clip: true
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                // Gloss overlay matching Control Center
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.height * 0.45
                    radius: parent.radius
                    visible: window.glassmorphism
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                    }
                    border.color: "transparent"
                    z: 999
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 14 * Appearance.effectiveScale
                    z: 1

                    // ── Tab Selector (Pill Style) ──
                    Rectangle {
                        id: tabSelectorContainer
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(container.width - 48 * Appearance.effectiveScale, 340 * Appearance.effectiveScale)
                        height: 38 * Appearance.effectiveScale
                        radius: 19 * Appearance.effectiveScale
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.color: Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        visible: window.tabs.length > 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale

                            Repeater {
                                model: window.tabs
                                delegate: Rectangle {
                                    width: window.tabs.length > 0 ? (tabSelectorContainer.width - 12 * Appearance.effectiveScale) / window.tabs.length : 0
                                    height: 30 * Appearance.effectiveScale
                                    radius: 15 * Appearance.effectiveScale
                                    color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : "transparent"
                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                                    border.width: 1
                                    
                                    property bool isActive: index === window.activeTab

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8 * Appearance.effectiveScale

                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16 * Appearance.effectiveScale
                                            color: isActive ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Theme.font.family
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            font.weight: isActive ? Font.Bold : Font.Normal
                                            color: isActive ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: window.activeTab = index
                                    }
                                }
                            }
                        }
                    }



                    // ── Tab Content (Lazy loaded to prevent first-open freeze) ──
                    Loader {
                        id: aiChatTabLoader
                        visible: window.activeTab === 0
                        active: window.activeTab === 0 || loadedOnce
                        property bool loadedOnce: window.activeTab === 0
                        onActiveChanged: if (active) loadedOnce = true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: Component { AiChatTab {} }
                    }

                    Loader {
                        id: animeTabLoader
                        visible: window.activeTab === 1
                        active: window.activeTab === 1 || loadedOnce
                        property bool loadedOnce: window.activeTab === 1
                        onActiveChanged: if (active) loadedOnce = true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: Component { AnimeTab {} }
                    }

                    Loader {
                        id: translatorTabLoader
                        visible: window.activeTab === 2
                        active: window.activeTab === 2 || loadedOnce
                        property bool loadedOnce: window.activeTab === 2
                        onActiveChanged: if (active) loadedOnce = true
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: Component { TranslatorTab {} }
                    }
                }
            }

            // ── Right Edge Drag-to-Resize Handle ──
            MouseArea {
                id: resizeHandle
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 14 * Appearance.effectiveScale
                anchors.rightMargin: -6 * Appearance.effectiveScale
                cursorShape: Qt.SizeHorCursor
                hoverEnabled: true
                z: 100

                property real startX: 0
                property real startWidth: 0

                onPressed: (mouse) => {
                    startX = mouse.x;
                    startWidth = container.width;
                }

                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let delta = mouse.x - startX;
                        window.sidebarWidth = Math.max(360 * Appearance.effectiveScale, Math.min(window.width - 32 * Appearance.effectiveScale, startWidth + delta));
                    }
                }

                onReleased: {
                    window.saveWidth();
                }
            }
        }
    }
}
