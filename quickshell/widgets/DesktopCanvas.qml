import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"
import "desktopWidget"
import "widgetCanvas"

PanelWindow {
    id: canvasWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Bottom
    exclusionMode: ExclusionMode.Ignore

    // Main Canvas area hosting floating widgets
    Item {
        id: canvasContainer
        anchors.fill: parent

        property int topZ: 1

        function bringToTop(item) {
            if (item && item.z !== topZ) item.z = ++topZ;
        }

        Clock {
            id: clockWidget
            onXChanged: canvasContainer.bringToTop(clockWidget)
            onYChanged: canvasContainer.bringToTop(clockWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(clockWidget)
            }
        }

        PhotoFrameWidget {
            id: photoFrameWidget
            onXChanged: canvasContainer.bringToTop(photoFrameWidget)
            onYChanged: canvasContainer.bringToTop(photoFrameWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(photoFrameWidget)
            }
        }

        ActivateLinuxWatermark {
            id: activateLinuxWatermark
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(activateLinuxWatermark)
            }
        }

        FlowersWidget {
            id: flowersWidget
        }

        ScreenTimeWidget {
            id: screenTimeWidget
            onXChanged: canvasContainer.bringToTop(screenTimeWidget)
            onYChanged: canvasContainer.bringToTop(screenTimeWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(screenTimeWidget)
            }
        }

        WeatherWidget {
            id: weatherWidget
            onXChanged: canvasContainer.bringToTop(weatherWidget)
            onYChanged: canvasContainer.bringToTop(weatherWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(weatherWidget)
            }
        }

        MediaPlayerWidget {
            id: mediaPlayerWidget
            onXChanged: canvasContainer.bringToTop(mediaPlayerWidget)
            onYChanged: canvasContainer.bringToTop(mediaPlayerWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(mediaPlayerWidget)
            }
        }

        RamStorageWidget {
            id: ramStorageWidget
            onXChanged: canvasContainer.bringToTop(ramStorageWidget)
            onYChanged: canvasContainer.bringToTop(ramStorageWidget)
            TapHandler {
                acceptedButtons: Qt.AllButtons
                gesturePolicy: TapHandler.DragThreshold
                onPressedChanged: if (pressed) canvasContainer.bringToTop(ramStorageWidget)
            }
        }

        // ── Floating Desktop Edit Mode Toolbar ──────────────────────────────
        Rectangle {
            id: editToolbar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24 * Appearance.effectiveScale
            visible: DesktopEditModeService.isEditing
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            implicitWidth: toolbarRow.implicitWidth + 28 * Appearance.effectiveScale
            implicitHeight: 42 * Appearance.effectiveScale
            radius: 21 * Appearance.effectiveScale
            color: Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.95)
            border.color: Theme.primary
            border.width: 1.5
            z: 99999

            RowLayout {
                id: toolbarRow
                anchors.centerIn: parent
                spacing: 12 * Appearance.effectiveScale

                DankIcon {
                    name: "tune"
                    size: 18 * Appearance.effectiveScale
                    color: Theme.primary
                }

                Text {
                    text: "Desktop Edit Mode  •  Drag to reposition  •  Drag corner handles or Ctrl + Scroll to resize"
                    font.family: Theme.font.family
                    font.pixelSize: 12 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: Theme.onSurface
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    width: 1
                    height: 18 * Appearance.effectiveScale
                    color: Theme.outlineVariant
                }

                // Done / Exit Button
                Rectangle {
                    implicitWidth: doneText.implicitWidth + 24 * Appearance.effectiveScale
                    implicitHeight: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: doneArea.pressed 
                        ? Theme.primary 
                        : (doneArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent")
                    border.color: Theme.primary
                    border.width: 1

                    Text {
                        id: doneText
                        anchors.centerIn: parent
                        text: "Done"
                        font.family: Theme.font.family
                        font.pixelSize: 12 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: doneArea.pressed ? Theme.onPrimary : Theme.primary
                    }

                    MouseArea {
                        id: doneArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DesktopEditModeService.isEditing = false
                    }
                }
            }
        }
    }
}
