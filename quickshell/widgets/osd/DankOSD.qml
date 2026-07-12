import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../services"
import "../../components"

PanelWindow {
    id: root

    property alias content: contentLoader.sourceComponent
    property alias contentLoader: contentLoader
    property var modelData
    property bool shouldBeVisible: false
    property int autoHideInterval: 2500
    property bool enableMouseInteraction: false
    property real osdWidth: 260
    property real osdHeight: 48
    property int animationDuration: 250

    signal osdShown
    signal osdHidden

    function show() {
        if (shouldBeVisible) {
            hideTimer.restart();
            return;
        }
        OsdService.showOSD(root);
        closeTimer.stop();
        shouldBeVisible = true;
        visible = true;
        hideTimer.restart();
        osdShown();
    }

    function hide() {
        shouldBeVisible = false;
        closeTimer.restart();
    }

    function resetHideTimer() {
        if (shouldBeVisible) {
            hideTimer.restart();
        }
    }

    function setChildHovered(hovered) {
        if (enableMouseInteraction) {
            if (hovered) {
                hideTimer.stop();
            } else if (shouldBeVisible) {
                hideTimer.restart();
            }
        }
    }

    screen: modelData
    visible: false

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    color: "transparent"

    readonly property real screenWidth: screen ? screen.width : 1920
    readonly property real screenHeight: screen ? screen.height : 1080
    readonly property real shadowBuffer: 15
    readonly property real alignedWidth: osdWidth
    readonly property real alignedHeight: osdHeight

    readonly property bool isVerticalLayout: false

    readonly property real alignedX: (screenWidth - alignedWidth) / 2
    readonly property real alignedY: screenHeight - alignedHeight - 80 // Positioned nicely at the bottom center

    anchors {
        top: true
        left: true
    }

    WlrLayershell.margins {
        left: Math.max(0, alignedX - shadowBuffer)
        top: Math.max(0, alignedY - shadowBuffer)
    }

    implicitWidth: alignedWidth + (shadowBuffer * 2)
    implicitHeight: alignedHeight + (shadowBuffer * 2)

    Timer {
        id: hideTimer
        interval: autoHideInterval
        repeat: false
        onTriggered: {
            if (!enableMouseInteraction || !mouseArea.containsMouse) {
                hide();
            } else {
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: closeTimer
        interval: animationDuration + 50
        onTriggered: {
            if (!shouldBeVisible) {
                visible = false;
                osdHidden();
            }
        }
    }

    Item {
        id: osdContainer
        x: shadowBuffer
        y: shadowBuffer
        width: alignedWidth
        height: alignedHeight
        opacity: shouldBeVisible ? 1 : 0
        scale: shouldBeVisible ? 1 : 0.9

        ElevationShadow {
            id: bgShadowLayer
            anchors.fill: parent
            z: -1
            targetRadius: Theme.rounding.large
            targetColor: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.9)
            borderColor: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
            borderWidth: 1
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: enableMouseInteraction
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            z: -1
            onContainsMouseChanged: setChildHovered(containsMouse)
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: root.visible
            asynchronous: false
        }

        Behavior on opacity {
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: animationDuration
                easing.type: Easing.OutQuad
            }
        }
    }
}
