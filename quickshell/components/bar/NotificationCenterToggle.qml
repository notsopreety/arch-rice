import QtQuick 6.10
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"

Item {
    id: root

    property var sidebar
    property var controlCenter
    property var launcher

    readonly property var matugen: Theme
    readonly property var notifs: Notifs
    readonly property bool isActive: NotificationCenterService.visible
    readonly property bool isHovered: mouse.containsMouse
    readonly property int unreadCount: notifs.unreadCount

    implicitWidth: bell.implicitWidth + (badge.visible ? badge.width + 4 * Appearance.effectiveScale : 8 * Appearance.effectiveScale)
    implicitHeight: bell.implicitHeight

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            NotificationCenterService.toggle();
        }
    }

    DankIcon {
        id: bell
        anchors.centerIn: parent
        name: notifs.dnd ? "notifications_paused" : (unreadCount > 0 ? "notifications_active" : "notifications")
        size: 18 * Appearance.effectiveScale
        color: isActive || unreadCount > 0 || notifs.dnd
            ? matugen.primary
            : isHovered
                ? matugen.primary
                : Qt.rgba(1, 1, 1, 0.85)

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        scale: mouse.pressed ? 0.92 : (isHovered || isActive ? 1.08 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }
    }

    Rectangle {
        id: badge
        anchors.left: bell.right
        anchors.leftMargin: 2 * Appearance.effectiveScale
        anchors.top: bell.top
        width: Math.max(16 * Appearance.effectiveScale, badgeText.implicitWidth + 8 * Appearance.effectiveScale)
        height: 16 * Appearance.effectiveScale
        radius: 8 * Appearance.effectiveScale
        color: Qt.rgba(matugen.primary.r, matugen.primary.g, matugen.primary.b, 0.9)
        visible: unreadCount > 0

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: unreadCount > 99 ? "99+" : `${unreadCount}`
            font.family: "Inter"
            font.pixelSize: 9 * Appearance.effectiveScale
            font.weight: Font.Bold
            color: matugen.background
        }
    }
}