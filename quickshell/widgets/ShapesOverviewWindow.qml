import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

PanelWindow {
    id: shapesWindow

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-shapes"
    WlrLayershell.keyboardFocus: ShapesOverviewService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: ShapesOverviewService.visible

    property real animValue: 0.0

    Behavior on animValue {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    onVisibleChanged: {
        if (visible) {
            animValue = 1.0;
        } else {
            animValue = 0.0;
        }
    }

    // Dim Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: shapesWindow.animValue * 0.55
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        TapHandler { onTapped: ShapesOverviewService.close() }
    }

    // Connect to ShapesOverviewService
    Connections {
        target: ShapesOverviewService
        function onRequestOpen() {
            ShapesOverviewService.visible = true;
        }
        function onRequestToggle() {
            ShapesOverviewService.visible = !ShapesOverviewService.visible;
        }
    }

    // Card Container
    Item {
        id: card
        anchors.centerIn: parent
        width: 820
        height: 720
        opacity: shapesWindow.animValue
        scale: 0.92 + (0.08 * shapesWindow.animValue)

        layer.enabled: true
        layer.smooth: false

        DropShadow {
            anchors.fill: cardBg
            source: cardBg
            verticalOffset: 16
            radius: 48
            samples: 65
            spread: 0.04
            color: Qt.rgba(0, 0, 0, 0.5)
            transparentBorder: true
            cached: true
        }

        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: 28
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.22)
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.18)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 20

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Column {
                        spacing: 4
                        Text {
                            text: "Material You 3 Shape Library"
                            font.family: "Inter"
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }
                        Text {
                            text: "GPU-accelerated shapes for premium UI design"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: Qt.rgba(1, 1, 1, 0.6)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 14
                            color: "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShapesOverviewService.close()
                        }
                    }
                }

                // Grid Canvas illustrating all 35 shapes
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        cellWidth: 108
                        cellHeight: 116
                        interactive: false

                        model: [
                            { name: "Circle", shape: "circle" },
                            { name: "Square", shape: "square" },
                            { name: "Slanted", shape: "slanted" },
                            { name: "Arch", shape: "arch" },
                            { name: "Semicircle", shape: "semicircle" },
                            { name: "Oval", shape: "oval" },
                            { name: "Pill", shape: "pill" },

                            { name: "Triangle", shape: "triangle" },
                            { name: "Arrow", shape: "arrow" },
                            { name: "Fan", shape: "fan" },
                            { name: "Diamond", shape: "diamond" },
                            { name: "Clamshell", shape: "clamshell" },
                            { name: "Pentagon", shape: "pentagon" },
                            { name: "Gem", shape: "gem" },

                            { name: "Sunny", shape: "sunny" },
                            { name: "Very sunny", shape: "very_sunny" },
                            { name: "4-sided cookie", shape: "cookie_4" },
                            { name: "6-sided cookie", shape: "cookie_6" },
                            { name: "7-sided cookie", shape: "cookie_7" },
                            { name: "9-sided cookie", shape: "cookie_9" },
                            { name: "12-sided cookie", shape: "cookie_12" },

                            { name: "4-leaf clover", shape: "clover_4" },
                            { name: "8-leaf clover", shape: "clover_8" },
                            { name: "Burst", shape: "burst" },
                            { name: "Soft burst", shape: "soft_burst" },
                            { name: "Boom", shape: "boom" },
                            { name: "Soft boom", shape: "soft_boom" },
                            { name: "Flower", shape: "flower" },

                            { name: "Puffy", shape: "puffy" },
                            { name: "Puffy diamond", shape: "puffy_diamond" },
                            { name: "Ghost-ish", shape: "ghost" },
                            { name: "Pixel circle", shape: "pixel_circle" },
                            { name: "Pixel triangle", shape: "pixel_triangle" },
                            { name: "Bun", shape: "bun" },
                            { name: "Heart", shape: "heart" }
                        ]

                        delegate: Item {
                            width: grid.cellWidth
                            height: grid.cellHeight

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                // Material Shape element from our library
                                MaterialShape {
                                    id: materialShape
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 54
                                    height: 54
                                    shape: modelData.shape
                                    color: ma.containsMouse ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45)
                                    borderColor: ma.containsMouse ? "#ffffff" : "transparent"
                                    borderWidth: 1.5

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    transform: Scale {
                                        origin.x: 27; origin.y: 27
                                        xScale: ma.containsMouse ? 1.15 : 1.0
                                        yScale: xScale
                                        Behavior on xScale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.maximumWidth: grid.cellWidth - 10
                                    text: modelData.name
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: ma.containsMouse ? Font.Medium : Font.Normal
                                    color: ma.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.7)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                ShapesOverviewService.close();
                event.accepted = true;
            }
        }
    }
}
