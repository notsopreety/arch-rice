import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../core/functions" as Functions
import "../services"
import "../widgets"
import "../theme"

import "systemmonitor"
import "systemmonitor/pages"

FloatingWindow {
    id: win

    color: "transparent"
    title: "System Monitor"

    readonly property bool isNarrow: win.width < 750 * Appearance.effectiveScale

    // Default native window size
    implicitWidth: Math.min(1100 * Appearance.effectiveScale, Appearance.sizes.screen.width * 0.75)
    implicitHeight: Math.min(820 * Appearance.effectiveScale, Appearance.sizes.screen.height * 0.85)
    minimumSize: Qt.size(600, 450)

    Component.onCompleted: {
        GlobalStates.systemMonitorOpen = true;
    }

    Component.onDestruction: {
        GlobalStates.systemMonitorOpen = false;
        GlobalStates.systemMonitorIndex = 0;
    }

    // Main Panel Background
    Rectangle {
        id: root
        property int currentIndex: 0
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.outlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        clip: true

        focus: visible
        Keys.onEscapePressed: {
            win.close();
        }

        // Stop click propagation to backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        // Reset tab to Performance (0) when closed
        Connections {
            target: GlobalStates
            function onSystemMonitorOpenChanged() {
                if (!GlobalStates.systemMonitorOpen) {
                    root.currentIndex = 0;
                    GlobalStates.systemMonitorIndex = 0;
                }
            }
        }

        // Auto-fallback if battery is removed/unavailable
        Connections {
            target: Battery
            function onAvailableChanged() {
                if (!Battery.available && GlobalStates.systemMonitorIndex === 1) {
                    GlobalStates.systemMonitorIndex = 0;
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ── Global Header ──
            Item {
                id: headerWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 52 * Appearance.effectiveScale

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20 * Appearance.effectiveScale
                    anchors.rightMargin: 12 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "monitoring"
                        iconSize: 28 * Appearance.effectiveScale
                        color: Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        text: "System Monitor"
                        font.pixelSize: 24 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        color: "white"
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true } // Spacer
                }
            }

            // ── Main Content Area (Sidebar + Pages) ──
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12 * Appearance.effectiveScale
                
                // Side Navigation (Matching SettingsSidebar style)
                Rectangle {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: isNarrow ? 72 * Appearance.effectiveScale : 220 * Appearance.effectiveScale
                    Layout.fillWidth: false
                    color: Theme.surfaceContainerLow
                    radius: 20 * Appearance.effectiveScale
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale
                        
                        // Navigation Items
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8 * Appearance.effectiveScale
                            
                            Repeater {
                                model: [
                                    { name: "Performance", icon: "monitoring", stackIndex: 0 },
                                    { name: "Battery", icon: "battery_charging_full", stackIndex: 1, visible: Battery.available },
                                    { name: "Processes", icon: "list", stackIndex: 2 }
                                ]
                                
                                delegate: RippleButton {
                                    visible: modelData.visible !== false
                                    Layout.fillWidth: true
                                    implicitHeight: visible ? 48 * Appearance.effectiveScale : 0
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                        ? Functions.ColorUtils.transparentize(Theme.primary, 0.88) 
                                        : "transparent"
                                    colBackgroundHover: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                        ? colBackground 
                                        : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                                    
                                    onClicked: GlobalStates.systemMonitorIndex = modelData.stackIndex
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: isNarrow ? 0 : 16 * Appearance.effectiveScale
                                        spacing: isNarrow ? 0 : 16 * Appearance.effectiveScale
                                        Layout.alignment: isNarrow ? Qt.AlignCenter : Qt.AlignLeft
                                        
                                        MaterialSymbol {
                                            text: modelData.icon
                                            iconSize: 24 * Appearance.effectiveScale
                                            color: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                                ? Theme.primary 
                                                : "white"
                                            Layout.alignment: Qt.AlignCenter
                                        }
                                        
                                        StyledText {
                                            visible: !isNarrow
                                            text: modelData.name
                                            font.pixelSize: 14 * Appearance.effectiveScale
                                            font.weight: GlobalStates.systemMonitorIndex === modelData.stackIndex ? Font.Medium : Font.Normal
                                            color: GlobalStates.systemMonitorIndex === modelData.stackIndex 
                                                ? Theme.primary 
                                                : "white"
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                        
                        // Bottom Profile info (Using universal widget)
                        UserInfoCard {
                            visible: !isNarrow
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90 * Appearance.effectiveScale
                        }
                    }
                }
                
                // Main Content Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.surfaceContainer
                    radius: 20 * Appearance.effectiveScale
                    clip: true
                    
                    StackLayout {
                        anchors.fill: parent
                        currentIndex: GlobalStates.systemMonitorIndex
                        
                        PerformancePage {}
                        BatteryPage { visible: Battery.available }
                        ProcessesPage {}
                    }
                }
            }
        }
    }
}
