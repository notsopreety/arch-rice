import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../theme"
import "../../services"
import "../../components"
import "../../widgets"
import "../../core"
import "../"

PanelWindow {
    id: root

    property var focusedScreen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || Quickshell.screens[0]

    property string eventType: ""
    property string deviceNode: ""
    property string deviceName: ""
    property string deviceType: ""
    property string fileSystem: ""
    property string sizeString: ""
    property string busType: ""
    property string mountPoint: ""
    property bool isAddition: true

    property bool shouldBeVisible: false
    property int autoHideInterval: 4000

    screen: root.focusedScreen
    visible: false

    Connections {
        target: root
        function onFocusedScreenChanged() { root.screen = root.focusedScreen; }
    }

    Connections {
        target: UsbMonitorService
        function onDeviceEvent(info) {
            console.log("🔔 UsbOSD event received: " + JSON.stringify(info));
            root.eventType = info.event || "info";
            root.deviceNode = info.device || "";
            root.deviceName = info.displayName || info.device || "External Device";
            root.deviceType = info.deviceType || "Storage Device";
            root.fileSystem = info.filesystem || "";
            root.sizeString = info.sizeHuman || "";
            root.busType = info.bus || "";
            root.mountPoint = info.mountpoint || "";
            root.isAddition = (root.eventType !== "remove");

            root.show();
        }
    }

    function show() {
        OsdService.showOSD(root);
        shouldBeVisible = true;
        if (!visible) {
            visible = true;
            openAnim.restart();
        }
        hideTimer.restart();
    }

    function hide() {
        shouldBeVisible = false;
        closeAnim.restart();
    }

    Timer {
        id: hideTimer
        interval: autoHideInterval
        repeat: false
        onTriggered: hide()
    }

    Timer {
        id: closeTimer
        interval: 400
        onTriggered: {
            if (!shouldBeVisible) {
                visible = false;
            }
        }
    }

    // Material 3 Emphasized Decelerate and Accelerate Motion Curves
    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: osdContainer
            property: "x"
            from: root.closedX
            to: root.openX
            duration: 400
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
        NumberAnimation {
            target: osdContainer
            property: "opacity"
            from: 0.0; to: 1.0
            duration: 300
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: osdContainer
            property: "x"
            from: root.openX
            to: root.closedX
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedAccel
        }
        NumberAnimation {
            target: osdContainer
            property: "opacity"
            from: 1.0; to: 0.0
            duration: 200
        }
        onFinished: {
            root.visible = false;
        }
    }

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"

    readonly property real shadowBuffer: 24
    readonly property real alignedWidth: 380 * Appearance.effectiveScale
    readonly property real alignedHeight: 84 * Appearance.effectiveScale

    // Animation limits
    readonly property real openX: shadowBuffer
    readonly property real closedX: alignedWidth + (shadowBuffer * 2)

    anchors {
        bottom: true
        right: true
    }

    WlrLayershell.margins {
        right: 24 * Appearance.effectiveScale - shadowBuffer
        bottom: 24 * Appearance.effectiveScale - shadowBuffer
    }

    implicitWidth: alignedWidth + (shadowBuffer * 2)
    implicitHeight: alignedHeight + (shadowBuffer * 2)

    Item {
        id: osdContainer
        y: shadowBuffer
        width: alignedWidth
        height: alignedHeight
        x: root.closedX
        opacity: 0

        // Custom M3 shadow layer
        ElevationShadow {
            id: bgShadowLayer
            anchors.fill: parent
            z: -1
            targetRadius: 18 * Appearance.effectiveScale
            // MD3 soft container outline color
            targetColor: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.95)
            borderColor: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
            borderWidth: 1.5
        }

        // Material 3 Card Container
        Rectangle {
            anchors.fill: parent
            radius: 18 * Appearance.effectiveScale
            color: "transparent"
            clip: true

            // M3 Colored status strip on the side (accentuated thickness)
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 6 * Appearance.effectiveScale
                color: root.isAddition ? Theme.primary : Theme.error
                radius: 3 * Appearance.effectiveScale
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * Appearance.effectiveScale
                anchors.rightMargin: 20 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                // ── Left: M3 Outlined/Filled Icon Container ──
                Rectangle {
                    id: iconBox
                    Layout.preferredWidth: 44 * Appearance.effectiveScale
                    Layout.preferredHeight: 44 * Appearance.effectiveScale
                    radius: 12 * Appearance.effectiveScale // M3 Medium rounding squircle shape
                    
                    // Dynamic M3 Container Tonal Color
                    color: root.isAddition ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12)
                    border.width: 1.5 * Appearance.effectiveScale
                    border.color: root.isAddition ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            if (!root.isAddition) {
                                if (root.deviceType.toLowerCase().includes("smartphone") || root.deviceType.toLowerCase().includes("phone")) return "phonelink_off";
                                return "usb_off";
                            }
                            if (root.deviceType.toLowerCase().includes("smartphone") || root.deviceType.toLowerCase().includes("phone")) return "smartphone";
                            if (root.deviceType.toLowerCase().includes("sd") || root.deviceType.toLowerCase().includes("card")) return "sd_card";
                            if (root.deviceType.toLowerCase().includes("usb")) return "usb";
                            return "storage";
                        }
                        iconSize: 22 * Appearance.effectiveScale
                        color: root.isAddition ? Theme.primary : Theme.error
                    }
                }

                // ── Center/Right: Detailed MD3 Text Column ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale

                    // Section 1: Tiny MD3 Category Label (Uppercase + Spaced font)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 * Appearance.effectiveScale

                        Text {
                            text: (root.isAddition ? "CONNECTED" : "DISCONNECTED")
                            font.family: "Inter"
                            font.pixelSize: 9 * Appearance.effectiveScale
                            font.weight: Font.Black
                            font.capitalization: Font.AllUppercase
                            color: root.isAddition ? "#4caf50" : "#f44336"
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: "•"
                            font.family: "Inter"
                            font.pixelSize: 9 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.3)
                        }

                        Text {
                            text: root.isAddition ? root.deviceType.toUpperCase() : root.deviceNode.toUpperCase()
                            font.family: "Inter"
                            font.pixelSize: 9 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            font.capitalization: Font.AllUppercase
                            color: Qt.rgba(255, 255, 255, 0.6)
                            font.letterSpacing: 0.8
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Section 2: Large Title (OnSurface)
                    Text {
                        text: root.deviceName
                        font.family: "Inter"
                        font.pixelSize: 15 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Section 3: M3 Badges & Mount Status Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale
                        visible: root.isAddition

                        // Size badge (M3 Tonal Button Style)
                        Rectangle {
                            visible: root.sizeString !== ""
                            height: 18 * Appearance.effectiveScale
                            width: sizeText.implicitWidth + 16 * Appearance.effectiveScale
                            radius: 6 * Appearance.effectiveScale // M3 Small Rounding
                            color: Qt.rgba(255, 255, 255, 0.08)
                            border.color: Qt.rgba(255, 255, 255, 0.16)
                            border.width: 1

                            Text {
                                id: sizeText
                                anchors.centerIn: parent
                                text: root.sizeString
                                font.family: "Inter"
                                font.pixelSize: 9 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }
                        }

                        // Filesystem badge (M3 Primary Light Style)
                        Rectangle {
                            visible: root.fileSystem !== ""
                            height: 18 * Appearance.effectiveScale
                            width: fsText.implicitWidth + 16 * Appearance.effectiveScale
                            radius: 6 * Appearance.effectiveScale
                            color: root.isAddition ? Qt.rgba(76/255, 175/255, 80/255, 0.12) : Qt.rgba(244/255, 67/255, 54/255, 0.12)
                            border.color: root.isAddition ? Qt.rgba(76/255, 175/255, 80/255, 0.28) : Qt.rgba(244/255, 67/255, 54/255, 0.28)
                            border.width: 1

                            Text {
                                id: fsText
                                anchors.centerIn: parent
                                text: root.fileSystem.toUpperCase()
                                font.family: "Inter"
                                font.pixelSize: 9 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: root.isAddition ? "#4caf50" : "#f44336"
                            }
                        }

                        // Status Info text (OnSurfaceVariant)
                        Text {
                            text: {
                                if (root.mountPoint) {
                                    return "Mounted on " + root.mountPoint;
                                }
                                return root.busType ? "Bus: " + root.busType.toUpperCase() : "Ready to Mount";
                            }
                            font.family: "Inter"
                            font.pixelSize: 9 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: root.mountPoint ? "#81c784" : Qt.rgba(255, 255, 255, 0.6)
                            opacity: 0.8
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
