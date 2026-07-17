import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import "../theme"
import "../services"
import "../core"
import "../components"
import "."

PanelWindow {
    id: window

    readonly property color textColor: "#ffffff"
    readonly property color textMutedColor: "#e2e8f0"
    readonly property color primaryColor: Theme.primary
    readonly property color errorColor: Theme.error

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); window.glassmorphism = true; } catch(e) { window.glassmorphism = false; } }
        onLoaded: window.glassmorphism = true
        onLoadFailed: window.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    // Glassmorphic surface helpers
    readonly property color glassCanvasBg:        Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    0.35)
    readonly property color glassIslandBg:        Qt.rgba(Theme.surfaceContainerLow.r, Theme.surfaceContainerLow.g, Theme.surfaceContainerLow.b, 0.35)
    readonly property color glassCardBg:          Qt.rgba(Theme.surfaceContainer.r,    Theme.surfaceContainer.g,    Theme.surfaceContainer.b,    0.40)
    readonly property color glassCardHoverBg:     Qt.rgba(Theme.surfaceContainerHigh.r,Theme.surfaceContainerHigh.g,Theme.surfaceContainerHigh.b, 0.45)
    readonly property color glassActionBg:        Qt.rgba(Theme.surfaceContainerHigh.r,Theme.surfaceContainerHigh.g,Theme.surfaceContainerHigh.b, 0.40)
    readonly property color glassBorder:          Qt.rgba(1, 1, 1, 0.18)

    readonly property var visibleNotifications: (Notifs.recentNotifications ?? []).slice(0, 100)
    property bool _triggeredByClear: false

    function iconSourceFor(notification) {
        if (!notification || !notification.appIcon) return ""
        if (notification.appIcon.startsWith("/") || notification.appIcon.startsWith("file://")) return notification.appIcon
        return "image://icon/" + notification.appIcon
    }

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return errorColor
        if (u === NotificationUrgency.Low) return textMutedColor
        return primaryColor
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-notification-center"
    WlrLayershell.keyboardFocus: NotificationCenterService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: false

    Connections {
        target: NotificationCenterService
        function onVisibleChanged() {
            if (NotificationCenterService.visible) {
                window.visible = true;
                closeAnimation.stop();
                openAnimation.start();
                dashContent.forceActiveFocus();
                Notifs.markAllRead();
                if (window.visibleNotifications.length === 0) {
                    bellSwingAnim.restart();
                }
            } else {
                openAnimation.stop();
                closeAnimation.start();
            }
        }
    }

    ParallelAnimation {
        id: openAnimation
        NumberAnimation {
            target: canvasTransform
            property: "x"
            to: 0
            duration: Appearance.animation.elementMove.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
        NumberAnimation {
            target: canvas
            property: "opacity"
            to: 1
            duration: Appearance.animation.elementMove.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.standard
        }
    }

    ParallelAnimation {
        id: closeAnimation
        NumberAnimation {
            target: canvasTransform
            property: "x"
            to: canvas.width + 40
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
        NumberAnimation {
            target: canvas
            property: "opacity"
            to: 0
            duration: Appearance.animation.elementMoveExit.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
        onFinished: {
            window.visible = false;
        }
    }

    FocusScope {
        id: dashContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                NotificationCenterService.close();
                event.accepted = true;
            }
        }

        // Clicking the transparent background closes the window
        MouseArea {
            anchors.fill: parent
            onClicked: NotificationCenterService.close()
        }

        // Floating Card Container (aligned right, below status bar)
        Rectangle {
            id: canvas
            width: 400
            height: Math.min(950, parent.height - 80)
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 50 // Placed nicely below the top status bar

            radius: 24
            color: window.glassmorphism ? window.glassCanvasBg : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.85)
            border.color: window.glassmorphism ? window.glassBorder : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
            border.width: 1
            clip: true
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on border.color { ColorAnimation { duration: 400 } }

            // Gloss overlay
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: parent.height * 0.45
                radius: parent.radius
                visible: window.glassmorphism
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.12) }
                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.00) }
                }
                border.color: "transparent"
                z: 999
            }

            opacity: 0

            transform: Translate {
                id: canvasTransform
                x: canvas.width + 40
            }

            // Click interceptor to prevent clicks on the card from closing it
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
                onClicked: (event) => { event.accepted = true; }
            }

            // Inside content layout
            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                // ── Weather Card ──
                WeatherCard {
                    id: weatherCard
                    Layout.fillWidth: true
                }

                // ── Notification Island ──
                Rectangle {
                    id: notificationIsland
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 20
                    color: window.glassmorphism ? window.glassIslandBg : Qt.rgba(Theme.surfaceContainerLow.r, Theme.surfaceContainerLow.g, Theme.surfaceContainerLow.b, 0.95)
                    border.color: window.glassmorphism ? window.glassBorder : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 400 } }
                    Behavior on border.color { ColorAnimation { duration: 400 } }

                    ColumnLayout {
                        id: islandColumn
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // ── Notifications Content Area ──
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Empty State Placeholder
                            ColumnLayout {
                                id: placeholder
                                anchors.centerIn: parent
                                visible: window.visibleNotifications.length === 0
                                spacing: 8

                                onVisibleChanged: {
                                    if (visible && bellBg && typeof bellBg.randomizeShape === "function") {
                                        bellBg.randomizeShape();
                                    }
                                }

                                Item {
                                    Layout.alignment: Qt.AlignCenter
                                    implicitWidth: 80
                                    implicitHeight: 80

                                    MaterialShape {
                                        id: bellBg
                                        anchors.fill: parent
                                        color: Theme.surfaceContainerHigh
                                        
                                        readonly property var allowedShapes: [
                                            "square", "oval", "sunny", "very_sunny", 
                                            "cookie_4", "cookie_6", "cookie_7", "cookie_9", "cookie_12", 
                                            "clover_4", "clover_8", "soft_burst", "puffy_diamond"
                                        ]
                                        
                                        shape: "sunny"
                                        
                                        function randomizeShape() {
                                            var idx = Math.floor(Math.random() * allowedShapes.length);
                                            shape = allowedShapes[idx];
                                        }
                                        
                                        Component.onCompleted: randomizeShape()

                                        RotationAnimation on rotation {
                                            loops: Animation.Infinite
                                            from: 0; to: 360
                                            duration: 3000
                                            running: window.visibleNotifications.length === 0 && window.visible
                                        }
                                    }
                                    
                                    DankIcon {
                                        id: bellIcon
                                        anchors.centerIn: parent
                                        name: Notifs.dnd ? "notifications_off" : "notifications"
                                        size: 44
                                        color: "#ffffff"

                                        transform: Rotation {
                                            id: bellRotation
                                            origin.x: bellIcon.width / 2
                                            origin.y: 0
                                            angle: 0
                                        }

                                        SequentialAnimation {
                                            id: bellSwingAnim
                                            loops: 1
                                            running: false

                                            NumberAnimation { target: bellRotation; property: "angle"; from: 0; to: 20; duration: 250; easing.type: Easing.OutBack }
                                            NumberAnimation { target: bellRotation; property: "angle"; from: 20; to: -20; duration: 400; easing.type: Easing.InOutSine }
                                            NumberAnimation { target: bellRotation; property: "angle"; from: -20; to: 15; duration: 300; easing.type: Easing.InOutSine }
                                            NumberAnimation { target: bellRotation; property: "angle"; from: 15; to: -10; duration: 250; easing.type: Easing.InOutSine }
                                            NumberAnimation { target: bellRotation; property: "angle"; from: -10; to: 0; duration: 200; easing.type: Easing.OutSine }
                                        }

                                        Connections {
                                            target: Notifs
                                            function onRecentNotificationsChanged() {
                                                if ((Notifs.recentNotifications ?? []).length === 0 && !window._triggeredByClear) {
                                                    bellSwingAnim.restart()
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "You're all caught up"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: window.textMutedColor
                                }
                            }

                            // List view
                            ListView {
                                id: listView
                                anchors.fill: parent
                                clip: true
                                spacing: 6
                                visible: window.visibleNotifications.length > 0
                                model: window.visibleNotifications

                                add: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
                                        NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 250; easing.type: Easing.OutCubic }
                                    }
                                }
                                remove: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                                        NumberAnimation { property: "x"; to: listView.width / 2; duration: 200; easing.type: Easing.InQuad }
                                    }
                                }
                                displaced: Transition {
                                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
                                }

                                delegate: Rectangle {
                                    id: cardDelegate
                                    required property var modelData
                                    required property int index
                                    property bool expanded: false

                                    width: listView.width
                                    height: content.implicitHeight + 14
                                    Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    radius: 14

                                    SequentialAnimation {
                                        id: delegateDismissAnim
                                        ParallelAnimation {
                                            NumberAnimation { target: cardDelegate; property: "opacity"; to: 0; duration: 250; easing.type: Easing.OutCubic }
                                            NumberAnimation { target: cardDelegate; property: "x"; to: listView.width / 2; duration: 250; easing.type: Easing.InCubic }
                                        }
                                        NumberAnimation { target: cardDelegate; property: "height"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                                        ScriptAction { script: Notifs.deleteNotification(cardDelegate.modelData) }
                                    }

                                    Connections {
                                        target: window
                                        function on_TriggeredByClearChanged() {
                                            if (window._triggeredByClear) {
                                                sweepAnim.startDelay = index * 40;
                                                sweepAnim.start();
                                            }
                                        }
                                    }

                                    SequentialAnimation {
                                        id: sweepAnim
                                        property int startDelay: 0
                                        PauseAnimation { duration: sweepAnim.startDelay }
                                        ParallelAnimation {
                                            NumberAnimation { target: cardDelegate; property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                                            NumberAnimation { target: cardDelegate; property: "x"; to: listView.width; duration: 200; easing.type: Easing.InCubic }
                                        }
                                    }

                                    color: cardMouse.containsMouse
                                        ? (window.glassmorphism ? window.glassCardHoverBg : Theme.surfaceContainerHigh)
                                        : (window.glassmorphism ? window.glassCardBg      : Theme.surfaceContainer)
                                    border.width: modelData.read ? 1 : 1.25
                                    border.color: window.glassmorphism
                                        ? (modelData.read ? Qt.rgba(1,1,1,0.12) : Qt.rgba(window.urgencyColor(modelData.urgency).r, window.urgencyColor(modelData.urgency).g, window.urgencyColor(modelData.urgency).b, 0.40))
                                        : (modelData.read ? Qt.rgba(255,255,255,0.05) : Qt.rgba(window.urgencyColor(modelData.urgency).r, window.urgencyColor(modelData.urgency).g, window.urgencyColor(modelData.urgency).b, 0.32))

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    MouseArea {
                                        id: cardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cardDelegate.expanded = !cardDelegate.expanded
                                            cardDelegate.modelData.read = true
                                        }
                                    }

                                    ColumnLayout {
                                        id: content
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                                radius: 10
                                                color: Qt.rgba(window.urgencyColor(cardDelegate.modelData.urgency).r, window.urgencyColor(cardDelegate.modelData.urgency).g, window.urgencyColor(cardDelegate.modelData.urgency).b, 0.12)

                                                Image {
                                                    id: appIconImg
                                                    anchors.centerIn: parent
                                                    width: 18
                                                    height: 18
                                                    source: window.iconSourceFor(cardDelegate.modelData)
                                                    visible: status === Image.Ready
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: !appIconImg.visible
                                                    text: (cardDelegate.modelData.appName ?? "N").slice(0, 1).toUpperCase()
                                                    font.family: "Inter"
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                    color: window.urgencyColor(cardDelegate.modelData.urgency)
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 1

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: cardDelegate.modelData.summary || "Notification"
                                                    font.family: "Inter"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                    color: window.textColor
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: cardDelegate.modelData.appName || "Unknown app"
                                                    font.family: "Inter"
                                                    font.pixelSize: 10
                                                    color: window.textMutedColor
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            ColumnLayout {
                                                spacing: 2

                                                Rectangle {
                                                    Layout.alignment: Qt.AlignRight
                                                    width: 6
                                                    height: 6
                                                    radius: 3
                                                    visible: !cardDelegate.modelData.read
                                                    color: Theme.primary
                                                }

                                                Text {
                                                    Layout.alignment: Qt.AlignRight
                                                    text: cardDelegate.modelData.timeString
                                                    font.family: "Inter"
                                                    font.pixelSize: 9
                                                    color: window.textMutedColor
                                                }
                                            }

                                            // Circular expand/chevron indicator
                                            Rectangle {
                                                Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: 10
                                                color: "#1d1b20"
                                                DankIcon {
                                                    anchors.centerIn: parent
                                                    name: cardDelegate.expanded ? "expand_less" : "expand_more"
                                                    size: 14
                                                    color: "#ffffff"
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: { cardDelegate.expanded = !cardDelegate.expanded; }
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: cardDelegate.modelData.body || ""
                                            visible: text.length > 0
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: cardDelegate.expanded ? 6 : 2
                                            elide: Text.ElideRight
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            color: window.textMutedColor
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            visible: cardDelegate.expanded && cardDelegate.modelData.actions && cardDelegate.modelData.actions.length > 0

                                            Repeater {
                                                model: cardDelegate.modelData.actions || []

                                                Rectangle {
                                                    required property var modelData
                                                    Layout.preferredHeight: 24
                                                    Layout.preferredWidth: Math.min(120, label.implicitWidth + 14)
                                                    radius: 12
                                                    color: actionMouse.containsMouse
                                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                                                        : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                                                    Text {
                                                        id: label
                                                        anchors.centerIn: parent
                                                        text: modelData.text
                                                        font.family: "Inter"
                                                        font.pixelSize: 10
                                                        font.weight: Font.Medium
                                                        color: Theme.primary
                                                    }

                                                    MouseArea {
                                                        id: actionMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            cardDelegate.modelData.read = true
                                                            modelData.invoke()
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            visible: cardDelegate.expanded

                                            Item { Layout.fillWidth: true }

                                            Rectangle {
                                                Layout.preferredWidth: 64
                                                Layout.preferredHeight: 24
                                                radius: 12
                                                color: closeMouse.containsMouse
                                                    ? Qt.rgba(255, 255, 255, 0.12)
                                                    : Qt.rgba(255, 255, 255, 0.06)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: cardDelegate.modelData.closed ? "Dismissed" : "Dismiss"
                                                    font.family: "Inter"
                                                    font.pixelSize: 9
                                                    color: window.textColor
                                                }

                                                MouseArea {
                                                    id: closeMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        cardDelegate.modelData.read = true
                                                        cardDelegate.modelData.close()
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                Layout.preferredWidth: 58
                                                Layout.preferredHeight: 24
                                                radius: 12
                                                color: deleteMouse.containsMouse
                                                    ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                                    : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.10)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Delete"
                                                    font.family: "Inter"
                                                    font.pixelSize: 9
                                                    color: Theme.error
                                                }

                                                MouseArea {
                                                    id: deleteMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: delegateDismissAnim.start()
                                                }
                                            }
                                        }
                                    }
                                }

                                footer: Item {
                                    width: listView.width
                                    height: 6
                                }
                            }
                        }

                        // ── Bottom Action Row ──
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            spacing: 8

                            // DND/Silent Toggle Button
                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 40
                                radius: 20
                                color: Notifs.dnd 
                                    ? (window.glassmorphism ? Qt.rgba(Theme.primaryContainer.r, Theme.primaryContainer.g, Theme.primaryContainer.b, 0.5) : Theme.primaryContainer)
                                    : (window.glassmorphism ? window.glassActionBg : Theme.surfaceContainerHigh)
                                border.color: window.glassmorphism ? window.glassBorder : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 400 } }
                                Behavior on border.color { ColorAnimation { duration: 400 } }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: Notifs.dnd ? "notifications_off" : "notifications_active"
                                    size: 20
                                    color: Notifs.dnd ? Theme.onPrimaryContainer : "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.dnd = !Notifs.dnd
                                }
                            }

                            // Notification Count Pill
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                radius: 20
                                color: window.glassmorphism ? window.glassActionBg : Theme.surfaceContainerHigh
                                border.color: window.glassmorphism ? window.glassBorder : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 400 } }
                                Behavior on border.color { ColorAnimation { duration: 400 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: window.visibleNotifications.length > 0
                                        ? `${window.visibleNotifications.length} notification${window.visibleNotifications.length === 1 ? "" : "s"}`
                                        : "No notifications"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                }
                            }

                            // Clear All/Delete Sweep Button
                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 40
                                radius: 20
                                color: window.glassmorphism ? window.glassActionBg : Theme.surfaceContainerHigh
                                border.color: window.glassmorphism ? window.glassBorder : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 400 } }
                                Behavior on border.color { ColorAnimation { duration: 400 } }
                                opacity: window.visibleNotifications.length > 0 ? 1.0 : 0.5

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "delete_sweep"
                                    size: 20
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: window.visibleNotifications.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        if (window.visibleNotifications.length > 0) {
                                            window._triggeredByClear = true
                                            clearDelayTimer.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: clearDelayTimer
        interval: 600
        repeat: false
        onTriggered: {
            Notifs.clearAll()
            if (window._triggeredByClear) {
                bellSwingAnim.restart()
                window._triggeredByClear = false
            }
        }
    }
}
