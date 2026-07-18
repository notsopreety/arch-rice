import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"
import "../services"
import "../components"
import "../theme"
import "."
import "../core/functions" as Functions

/**
 * Media Notch Popup — The expanded HUD that appears below the Dynamic Island / top bar.
 * Refactored for global scaling.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: popupWindow
        required property var modelData
        screen: modelData
        
        readonly property string notchStyle: (Config.ready && Config.options.media && Config.options.media.notchMediaStyle) ? Config.options.media.notchMediaStyle : "mini"
        readonly property bool isFull: notchStyle === "full"

        // Glassmorphism detector
        property bool glassmorphism: false
        FileView {
            id: glassmorphismFlagFile
            path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
            preload: true
            watchChanges: true
            onFileChanged: glassmorphismReloadTimer.restart()
            Component.onCompleted: {
                try { glassmorphismFlagFile.reload(); popupWindow.glassmorphism = true; } catch(e) { popupWindow.glassmorphism = false; }
            }
            onLoaded: popupWindow.glassmorphism = true
            onLoadFailed: popupWindow.glassmorphism = false
        }
        Timer {
            id: glassmorphismReloadTimer
            interval: 200; repeat: false
            onTriggered: {
                try { glassmorphismFlagFile.reload(); } catch(e) {}
            }
        }

        // Positioning: Center top, below status bar
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:media-hud"
        exclusiveZone: 0

        anchors {
            top: true
        }

        WlrLayershell.margins {
            top: 4 * Appearance.effectiveScale
        }

        // Responsive window width
        implicitWidth: isFull ? Math.min(450 * Appearance.effectiveScale, modelData.width * 0.9) : Math.min(320 * Appearance.effectiveScale, modelData.width * 0.9)
        implicitHeight: contentRect.height + (20 * Appearance.effectiveScale)
        color: "transparent"

        visible: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) || contentRect.opacity > 0

        Rectangle {
            id: contentRect
            // Responsive pill width
            width: parent.width - (20 * Appearance.effectiveScale)
            anchors.horizontalCenter: parent.horizontalCenter
            height: isFull ? (fullLoader.item ? fullLoader.item.implicitHeight : 118 * Appearance.effectiveScale) : (miniLayout.implicitHeight + (12 * Appearance.effectiveScale))
            
            color: popupWindow.glassmorphism 
                ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.45) 
                : (isFull ? "transparent" : Theme.surfaceContainerHigh)
            border.color: popupWindow.glassmorphism 
                ? Qt.rgba(1, 1, 1, 0.18) 
                : (isFull ? "transparent" : Theme.outlineVariant)
            border.width: isFull ? 0 : 1
            radius: Appearance.rounding.button

            // Glassmorphic gloss overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                visible: popupWindow.glassmorphism && !popupWindow.isFull
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 0.46; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            // Animation for entry
            opacity: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0
            scale: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

            // Hover tracking area
            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered && Config.options.media.enableMediaHover) {
                        GlobalStates.openMediaNotch(modelData);
                    } else {
                        GlobalStates.stopMediaNotchTimer();
                        GlobalStates.mediaNotchOpen = false;
                    }
                }
            }

            // --- Style 1: Mini HUD ---
            RowLayout {
                id: miniLayout
                visible: !popupWindow.isFull
                anchors.fill: parent
                anchors.margins: 8 * Appearance.effectiveScale
                spacing: 10 * Appearance.effectiveScale

                Item {
                    id: artShape
                    width: 36 * Appearance.effectiveScale; height: 36 * Appearance.effectiveScale

                    // Rotating container for album art
                    Item {
                        id: rotatingArtContainer
                        anchors.fill: parent

                        Rectangle {
                            id: artShapeMask
                            anchors.fill: parent
                            radius: width / 2
                            color: "white"
                            visible: false
                        }

                        Image {
                            id: artImage
                            anchors.fill: parent
                            source: MprisController.displayedArtFilePath || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: artImage
                            maskSource: artShapeMask
                            visible: (MprisController.displayedArtFilePath && MprisController.displayedArtFilePath.toString() !== "")
                        }

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 20000
                            loops: Animation.Infinite
                            paused: !MprisController.isPlaying
                        }
                    }

                    // Fallback background circle if no image
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Theme.surfaceContainer
                        visible: !MprisController.displayedArtFilePath || MprisController.displayedArtFilePath.toString() === ""
                    }
                    
                    // Semi-transparent overlay for contrast
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "black"
                        opacity: (MprisController.displayedArtFilePath && MprisController.displayedArtFilePath.toString() !== "") ? 0.35 : 0
                        visible: opacity > 0
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: 18 * Appearance.effectiveScale
                        fill: 1
                        visible: !MprisController.displayedArtFilePath || MprisController.displayedArtFilePath.toString() === ""
                        color: Theme.onSurfaceVariant
                    }

                    // Play/Pause Overlay
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 24 * Appearance.effectiveScale
                        fill: 1
                        color: Theme.primary
                        opacity: 0.9
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.togglePlaying()
                    }
                }

                // ── 2. Skip Previous ──
                MaterialSymbol {
                    text: "skip_previous"; iconSize: 22 * Appearance.effectiveScale; fill: 1; color: Theme.primary
                    opacity: MprisController.canGoPrevious ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: MprisController.previous() 
                    }
                }

                // ── 3. Slider ──
                StyledSlider {
                    id: progressSlider
                    Layout.fillWidth: true; Layout.preferredHeight: 14 * Appearance.effectiveScale
                    configuration: StyledSlider.Configuration.Wavy
                    wavy: MprisController.isPlaying
                    value: MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0
                    highlightColor: Theme.primary
                    trackColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                    handleColor: Theme.primary
                    onMoved: if (MprisController.activePlayer) MprisController.activePlayer.position = value * MprisController.activePlayer.length
                    
                    Connections {
                        target: MprisController
                        function onPositionChanged() {
                            if (!progressSlider.pressed) {
                                progressSlider.value = MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0;
                            }
                        }
                    }
                }

                // ── 4. Skip Next ──
                MaterialSymbol {
                    text: "skip_next"; iconSize: 22 * Appearance.effectiveScale; fill: 1; color: Theme.primary
                    opacity: MprisController.canGoNext ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                        onClicked: MprisController.next() 
                    }
                }
            }

            // --- Style 2: Full Media Card ---
            Loader {
                id: fullLoader
                anchors.fill: parent
                active: popupWindow.isFull
                visible: popupWindow.isFull
                sourceComponent: MediaCard {
                    // Force a slightly different styling if needed
                    radius: Appearance.rounding.button
                }
            }
        }
    }
}
