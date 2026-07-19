import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../core"
import "../../widgets"

RowLayout {
    id: root
    spacing: 4 * Appearance.effectiveScale
    readonly property bool hasItems: SystemTray.items.length > 0

    property var trayItems: SystemTray.items
    property var parentWindow: null

    property var activeMenu: null

    HyprlandFocusGrab {
        id: focusGrab
        active: root.activeMenu !== null
        windows: [root.activeMenu]
        onCleared: {
            if (root.activeMenu) root.activeMenu.visible = false;
            root.activeMenu = null;
            GlobalStates.activeTrayItem = null;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.trayItems = SystemTray.items
    }

    Repeater {
        model: root.trayItems
        
        delegate: Rectangle {
            id: delegateRoot
            required property SystemTrayItem modelData
            
            Layout.preferredWidth: 24 * Appearance.effectiveScale
            Layout.preferredHeight: 24 * Appearance.effectiveScale
            radius: 4 * Appearance.effectiveScale
            color: "transparent"
            
            property var currentMenu: null

            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: 16 * Appearance.effectiveScale
                height: 16 * Appearance.effectiveScale
                source: {
                    const icon = modelData.icon ?? ""
                    if (typeof icon === "string" && icon.includes("?path=")) {
                        const parts = icon.split("?path=")
                        const name = parts[0]
                        const base = parts[1] ?? ""
                        const fileName = name.slice(name.lastIndexOf("/") + 1)
                        return Qt.resolvedUrl(`${base}/${fileName}`)
                    }
                    return icon
                }
                visible: status === Image.Ready
                asynchronous: true
            }
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) {
                            if (GlobalStates.activeTrayItem === modelData) {
                                GlobalStates.activeTrayItem = null;
                            } else {
                                GlobalStates.activeTrayItem = modelData;
                            }
                        }
                    }
                }
            }

            Loader {
                id: menuLoader
                active: GlobalStates.activeTrayItem === modelData
                onLoaded: {
                    root.activeMenu = item;
                    delegateRoot.currentMenu = item;
                }
                sourceComponent: SystemTrayMenu {
                    trayItemMenuHandle: modelData.menu
                    
                    anchor {
                        window: root.parentWindow ?? delegateRoot.QsWindow.window
                        rect: {
                            var pos = delegateRoot.mapToItem(null, 0, 0); 
                            return Qt.rect(pos.x, pos.y + delegateRoot.height + (4 * Appearance.effectiveScale), delegateRoot.width, delegateRoot.height);
                        }
                        edges: Edges.Top | Edges.Center
                        gravity: Edges.Bottom
                    }

                    onMenuClosed: {
                        if (GlobalStates.activeTrayItem === modelData) {
                            GlobalStates.activeTrayItem = null;
                        }
                        if (root.activeMenu === delegateRoot.currentMenu) {
                            root.activeMenu = null;
                        }
                        delegateRoot.currentMenu = null;
                    }
                }
            }
        }
    }
}
