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
import "sidebar"

PanelWindow {
    id: window

    property int activeTab: 0

    property var tabs: [
        { name: "Intelligence", icon: "neurology" },
        { name: "Anime", icon: "bookmark_heart" }
    ]

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
            width: 420
            height: parent.height - 32
            x: 16
            y: 16

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
                    PropertyChanges { target: containerTranslate; x: -container.width - 40 }
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

            // Drop shadow
            DropShadow {
                anchors.fill: sidebarCard
                source: sidebarCard
                horizontalOffset: 8
                radius: 48
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.4)
                transparentBorder: true
            }

            Rectangle {
                id: sidebarCard
                anchors.fill: parent
                radius: Theme.rounding.large

                // Block clicks from reaching backdrop
                MouseArea { anchors.fill: parent }

                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14
                    z: 1

                    // ── Tab Selector (Pill Style) ──
                    Rectangle {
                        id: tabSelectorContainer
                        Layout.alignment: Qt.AlignHCenter
                        width: 320
                        height: 38
                        radius: 19
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.color: Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        visible: window.tabs.length > 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4

                            Repeater {
                                model: window.tabs
                                delegate: Rectangle {
                                    width: window.tabs.length > 0 ? (tabSelectorContainer.width - 12) / window.tabs.length : 0
                                    height: 30
                                    radius: 15
                                    color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : "transparent"
                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
                                    border.width: 1
                                    
                                    property bool isActive: index === window.activeTab

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 16
                                            color: isActive ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Theme.font.family
                                            font.pixelSize: 12
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

                    // ── Smooth Blur/Fade Gradient (Replacing the line separator) ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: 12
                        color: "transparent"
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.6) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // ── Tab Content ──
                    AiChatTab {
                        visible: window.activeTab === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    AnimeTab {
                        visible: window.activeTab === 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
