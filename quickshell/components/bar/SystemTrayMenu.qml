import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../widgets"
import "../../theme"

PopupWindow {
    id: root
    required property QsMenuHandle trayItemMenuHandle
    
    signal menuClosed()

    color: "transparent"

    implicitWidth: Math.max(120 * Appearance.effectiveScale, menuLayout.implicitWidth + (8 * Appearance.effectiveScale))
    implicitHeight: menuLayout.implicitHeight + (8 * Appearance.effectiveScale)

    onVisibleChanged: {
        if (!visible) menuClosed();
    }

    Component.onDestruction: menuClosed()

    Rectangle {
        id: popupBackground
        anchors.fill: parent
        color: Theme.surfaceContainerHigh
        border.color: Theme.outlineVariant
        border.width: 1
        radius: Appearance.rounding.small
        clip: true

        opacity: 0
        scale: 0.9

        ParallelAnimation {
            id: enterAnim
            running: true
            NumberAnimation { target: popupBackground; property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { target: popupBackground; property: "scale"; from: 0.9; to: 1; duration: 150; easing.type: Easing.OutBack }
        }

        ColumnLayout {
            id: menuLayout
            anchors {
                fill: parent
                margins: 4 * Appearance.effectiveScale
            }
            spacing: 0

            QsMenuOpener {
                id: menuOpener
                menu: root.trayItemMenuHandle
            }

            Repeater {
                id: menuEntriesRepeater
                
                property bool iconColumnNeeded: {
                    for (var i = 0; i < menuOpener.children.length; i++) {
                        if (menuOpener.children[i].icon.length > 0) return true;
                    }
                    return false;
                }

                property bool interactionColumnNeeded: {
                    for (var i = 0; i < menuOpener.children.length; i++) {
                        if (menuOpener.children[i].buttonType !== QsMenuButtonType.None) return true;
                    }
                    return false;
                }

                model: menuOpener.children
                delegate: SystemTrayMenuEntry {
                    required property QsMenuEntry modelData
                    menuEntry: modelData
                    forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                    forceInteractionColumn: menuEntriesRepeater.interactionColumnNeeded
                    
                    onDismiss: root.visible = false
                    onOpenSubmenu: (handle) => {
                        root.trayItemMenuHandle = handle;
                    }
                }
            }
        }
    }

    Component.onCompleted: visible = true
}
