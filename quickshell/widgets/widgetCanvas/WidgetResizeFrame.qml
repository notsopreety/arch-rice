import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"

Item {
    id: root

    property Item target: parent
    property string widgetName: ""
    property real minWidth: 80 * Appearance.effectiveScale
    property real minHeight: 80 * Appearance.effectiveScale
    property real maxWidth: 1200 * Appearance.effectiveScale
    property real maxHeight: 1000 * Appearance.effectiveScale
    property bool lockAspectRatio: false
    property real aspectRatio: 1.0

    signal resized(real newWidth, real newHeight)
    signal resizeStarted()
    signal resizeEnded(real finalWidth, real finalHeight)
    signal resetRequested()
    property bool mutateTargetDimensions: false

    anchors.fill: parent
    z: 9999

    readonly property bool isEditing: DesktopEditModeService.isEditing
    property bool isResizing: false
    readonly property bool isHovered: hoverTracker.containsMouse || brHandleArea.containsMouse || blHandleArea.containsMouse
    readonly property bool showGuides: isEditing || isHovered || isResizing || badgeTimer.running

    // ── Mouse hover tracking for the entire widget ──
    MouseArea {
        id: hoverTracker
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        z: -1
    }

    // ── Ctrl + Mouse Wheel Resizing ──
    WheelHandler {
        target: root
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            if (!target) return;
            let delta = event.angleDelta.y;
            let factor = delta > 0 ? 1.05 : 0.95;

            let curW = target.width;
            let curH = target.height;
            let newW = curW * factor;
            let newH = curH * factor;

            if (root.lockAspectRatio) {
                newH = newW / (root.aspectRatio > 0 ? root.aspectRatio : 1.0);
            }

            newW = Math.max(root.minWidth, Math.min(root.maxWidth, newW));
            newH = Math.max(root.minHeight, Math.min(root.maxHeight, newH));

            if (root.mutateTargetDimensions) {
                target.width = newW;
                target.height = newH;
            }

            root.resized(newW, newH);
            badgeTimer.restart();
            saveDebounceTimer.restart();
        }
    }

    Timer {
        id: saveDebounceTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (target) {
                root.resizeEnded(target.width, target.height);
            }
        }
    }

    Timer {
        id: badgeTimer
        interval: 1400
        repeat: false
    }

    // ── Visual Bounding Box (Accent glow when editing or resizing) ──
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Theme.rounding.normal
        border.color: Theme.primary
        border.width: root.isEditing ? 2 : (root.isResizing ? 1.5 : 1)
        opacity: root.showGuides ? (root.isEditing ? 0.9 : 0.45) : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    // ── Top / Left Accent Dots in Edit Mode ──
    Rectangle {
        visible: root.isEditing
        width: 8 * Appearance.effectiveScale
        height: 8 * Appearance.effectiveScale
        radius: 4 * Appearance.effectiveScale
        color: Theme.primary
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -4 * Appearance.effectiveScale
        anchors.topMargin: -4 * Appearance.effectiveScale
    }

    Rectangle {
        visible: root.isEditing
        width: 8 * Appearance.effectiveScale
        height: 8 * Appearance.effectiveScale
        radius: 4 * Appearance.effectiveScale
        color: Theme.primary
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -4 * Appearance.effectiveScale
        anchors.topMargin: -4 * Appearance.effectiveScale
    }

    // ── Bottom-Left Handle (in Edit Mode) ──
    Rectangle {
        id: blHandle
        visible: root.isEditing
        width: 14 * Appearance.effectiveScale
        height: 14 * Appearance.effectiveScale
        radius: 7 * Appearance.effectiveScale
        color: blHandleArea.pressed ? Theme.primary : Theme.surfaceContainerHighest
        border.color: Theme.primary
        border.width: 1.5
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: -7 * Appearance.effectiveScale
        anchors.bottomMargin: -7 * Appearance.effectiveScale

        MouseArea {
            id: blHandleArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.SizeBDiagCursor
            acceptedButtons: Qt.LeftButton

            property real startParentX: 0
            property real startParentY: 0
            property real startTargetW: 0
            property real startTargetH: 0
            property real startTargetX: 0

            onPressed: (mouse) => {
                root.isResizing = true;
                root.resizeStarted();
                let p = mapToItem(target.parent, mouse.x, mouse.y);
                startParentX = p.x;
                startParentY = p.y;
                startTargetW = target.width;
                startTargetH = target.height;
                startTargetX = target.x;
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return;
                let p = mapToItem(target.parent, mouse.x, mouse.y);
                let deltaX = startParentX - p.x;
                let deltaY = p.y - startParentY;

                let newW = startTargetW + deltaX;
                let newH = startTargetH + deltaY;

                if (root.lockAspectRatio) {
                    newH = newW / (root.aspectRatio > 0 ? root.aspectRatio : 1.0);
                }

                newW = Math.max(root.minWidth, Math.min(root.maxWidth, newW));
                newH = Math.max(root.minHeight, Math.min(root.maxHeight, newH));

                let actualDeltaX = newW - startTargetW;
                target.x = startTargetX - actualDeltaX;
                if (root.mutateTargetDimensions) {
                    target.width = newW;
                    target.height = newH;
                }

                root.resized(newW, newH);
            }

            onReleased: {
                root.isResizing = false;
                root.resizeEnded(target.width, target.height);
            }
        }
    }

    // ── Primary Bottom-Right Corner Resize Handle ──
    Item {
        id: brHandle
        width: 28 * Appearance.effectiveScale
        height: 28 * Appearance.effectiveScale
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -6 * Appearance.effectiveScale
        anchors.bottomMargin: -6 * Appearance.effectiveScale

        opacity: root.showGuides ? 1.0 : 0.0
        scale: brHandleArea.pressed ? 1.15 : (brHandleArea.containsMouse ? 1.08 : 1.0)

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
        Behavior on scale {
            NumberAnimation { duration: 120 }
        }

        // Circular Grip Background
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: brHandleArea.pressed 
                ? Theme.primary 
                : (brHandleArea.containsMouse 
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.95) 
                    : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.90))
            border.color: Theme.primary
            border.width: 1.5

            // Diagonal Resize Arrows Icon
            DankIcon {
                anchors.centerIn: parent
                name: "open_in_full"
                size: 13 * Appearance.effectiveScale
                color: brHandleArea.pressed ? Theme.onPrimary : (brHandleArea.containsMouse ? Theme.onPrimary : Theme.primary)
                rotation: 45
            }
        }

        MouseArea {
            id: brHandleArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            acceptedButtons: Qt.LeftButton

            property real startParentX: 0
            property real startParentY: 0
            property real startTargetW: 0
            property real startTargetH: 0

            onPressed: (mouse) => {
                root.isResizing = true;
                root.resizeStarted();
                let p = mapToItem(target.parent, mouse.x, mouse.y);
                startParentX = p.x;
                startParentY = p.y;
                startTargetW = target.width;
                startTargetH = target.height;
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return;
                let p = mapToItem(target.parent, mouse.x, mouse.y);
                let deltaX = p.x - startParentX;
                let deltaY = p.y - startParentY;

                let newW = startTargetW + deltaX;
                let newH = startTargetH + deltaY;

                if (root.lockAspectRatio) {
                    let maxDelta = Math.abs(deltaX) > Math.abs(deltaY) ? deltaX : deltaY;
                    newW = startTargetW + maxDelta;
                    newH = newW / (root.aspectRatio > 0 ? root.aspectRatio : 1.0);
                }

                newW = Math.max(root.minWidth, Math.min(root.maxWidth, newW));
                newH = Math.max(root.minHeight, Math.min(root.maxHeight, newH));

                if (root.mutateTargetDimensions) {
                    target.width = newW;
                    target.height = newH;
                }

                root.resized(newW, newH);
            }

            onDoubleClicked: {
                root.resetRequested();
                badgeTimer.restart();
            }

            onReleased: {
                root.isResizing = false;
                root.resizeEnded(target.width, target.height);
            }
        }
    }

    // ── Dimension Badge Pill (Floats above widget when resizing / editing) ──
    Rectangle {
        id: dimBadge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 8 * Appearance.effectiveScale
        width: dimText.implicitWidth + 18 * Appearance.effectiveScale
        height: 24 * Appearance.effectiveScale
        radius: 12 * Appearance.effectiveScale
        color: Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.95)
        border.color: Theme.primary
        border.width: 1

        opacity: (root.isResizing || badgeTimer.running || (root.isEditing && root.isHovered)) ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Text {
            id: dimText
            anchors.centerIn: parent
            text: (root.widgetName ? (root.widgetName + "  ") : "") + (target ? (Math.round(target.width) + " × " + Math.round(target.height)) : "")
            font.family: Theme.font.family
            font.pixelSize: 11 * Appearance.effectiveScale
            font.weight: Font.DemiBold
            color: Theme.primary
            renderType: Text.NativeRendering
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                root.resetRequested();
                badgeTimer.restart();
            }
        }
    }
}
