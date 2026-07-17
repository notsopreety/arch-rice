import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); root.glassmorphism = true; } catch(e) { root.glassmorphism = false; } }
        onLoaded: root.glassmorphism = true
        onLoadFailed: root.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    readonly property color surface: root.glassmorphism
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35)
        : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.97)
    readonly property color textColor: "#ffffff"
    readonly property color textMutedColor: "#e2e8f0"
    readonly property color primaryColor: Theme.primary
    readonly property color errorColor: Theme.error

    readonly property real swipeThreshold: 0.30

    // Configuration
    readonly property int maxVisible: 4
    readonly property int margin: 16
    readonly property int popupWidth: 360
    readonly property int spacing: 10
    readonly property int timeoutMs: 6000

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return errorColor
        if (u === NotificationUrgency.Low) return textMutedColor
        return primaryColor
    }

    screen: Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: root.margin; right: root.margin }
    visible: notifStack.children.length > 0
    color: "transparent"
    implicitWidth: root.popupWidth
    implicitHeight: notifStack.height

    function createPopup(notifWrapper) {
        if (!notifWrapper || notifWrapper.closed) return
        
        // Prevent duplicate popups but refresh them if already active
        for (let i = 0; i < notifStack.children.length; i++) {
            let child = notifStack.children[i]
            if (child && child.modelData === notifWrapper) {
                if (typeof child.refresh === "function") {
                    child.refresh()
                }
                return
            }
        }

        // Limit visible popups by dismissing the oldest active one
        let activeCount = 0
        let oldestChild = null
        for (let i = 0; i < notifStack.children.length; i++) {
            let child = notifStack.children[i]
            if (child && typeof child.isClosing !== "undefined" && !child.isClosing) {
                activeCount++
                if (!oldestChild) oldestChild = child
            }
        }
        if (activeCount >= root.maxVisible && oldestChild) {
            oldestChild.dismiss()
        }

        // Dynamically instantiate the popup card
        cardComponent.createObject(notifStack, {
            modelData: notifWrapper
        })
    }

    Connections {
        target: Notifs
        function onNotificationAdded(notifWrapper) {
            root.createPopup(notifWrapper)
        }
    }

    Component.onCompleted: {
        const active = Notifs.activeNotifications || []
        const limit = Math.min(active.length, root.maxVisible)
        for (let i = limit - 1; i >= 0; i--) {
            root.createPopup(active[i])
        }
    }

    // Physical Stack Container hosting the card deck
    Item {
        id: notifStack
        width: parent.width
        height: topCardHeight + 40

        property real topCardHeight: 90

        onChildrenChanged: {
            recalculateIndexes();
        }

        function recalculateIndexes() {
            var activeCount = 0;
            // Iterate backwards to compute indices from newest to oldest
            for (var i = children.length - 1; i >= 0; i--) {
                var child = children[i];
                if (child && typeof child.calculateActiveIndex === "function") {
                    child.calculateActiveIndex(activeCount);
                    if (!child.isClosing) {
                        activeCount++;
                    }
                }
            }
        }
    }

    Component {
        id: cardComponent

        Item {
            id: card

            property var modelData
            property bool isClosing: false

            property int activeIndex: 0

            readonly property real targetHeight: activeIndex === 0 ? (col.implicitHeight + 28) : 90

            width: root.popupWidth - (activeIndex >= 0 ? activeIndex * 16 : 0)
            height: targetHeight
            clip: true

            // Positioning & Stacking transformations
            x: (root.popupWidth - width) / 2 + dragX
            y: activeIndex >= 0 ? activeIndex * 10 : 0
            z: 100 - activeIndex
            opacity: activeIndex === 0 ? entryOpacity : (activeIndex === 1 ? 0.75 : (activeIndex === 2 ? 0.45 : (activeIndex === 3 ? 0.15 : 0.0)))
            visible: activeIndex >= 0 && activeIndex <= 3

            // Smooth morphing transformations for standard stacked positioning
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            onTargetHeightChanged: {
                if (activeIndex === 0 && targetHeight > 0 && !isClosing) {
                    notifStack.topCardHeight = targetHeight;
                }
            }

            onActiveIndexChanged: {
                if (activeIndex === 0 && !isClosing) {
                    notifStack.topCardHeight = targetHeight;
                }
            }

            function calculateActiveIndex(activeCountBefore) {
                if (isClosing) {
                    activeIndex = -1;
                } else {
                    activeIndex = activeCountBefore;
                }
            }

            onIsClosingChanged: {
                notifStack.recalculateIndexes();
            }

            property bool visible_: true
            property bool hovered: false
            property bool dragging: false
            property bool expanded: false
            property real dragX: root.popupWidth + root.margin
            property real timeoutProgress: 1.0
            property real entryScale: 0.9
            property real entryOpacity: 0
            property real refreshScale: 1.0

            function refresh() {
                timeoutProgress = 1.0
                if (progAnim) {
                    progAnim.restart()
                }
                refreshAnim.restart()
            }

            SequentialAnimation {
                id: refreshAnim
                ParallelAnimation {
                    NumberAnimation { target: card; property: "refreshScale"; from: 1.0; to: 1.06; duration: 100; easing.type: Easing.OutQuad }
                    ColorAnimation { target: bg; property: "border.color"; to: Theme.primary; duration: 100 }
                }
                ParallelAnimation {
                    NumberAnimation { target: card; property: "refreshScale"; from: 1.06; to: 0.97; duration: 100; easing.type: Easing.InOutQuad }
                    ColorAnimation { target: bg; property: "border.color"; to: Qt.rgba(root.urgencyColor(modelData.urgency).r, root.urgencyColor(modelData.urgency).g, root.urgencyColor(modelData.urgency).b, 0.32); duration: 200 }
                }
                NumberAnimation { target: card; property: "refreshScale"; from: 0.97; to: 1.0; duration: 80; easing.type: Easing.InQuad }
            }

            Component.onCompleted: {
                animIn.start()
                notifStack.recalculateIndexes()
            }

            SequentialAnimation {
                id: animIn
                ParallelAnimation {
                    NumberAnimation { target: card; property: "entryOpacity"; from: 0; to: 1; duration: 150 }
                    NumberAnimation { target: card; property: "entryScale"; from: 0.9; to: 1; duration: 300; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "dragX"; from: root.popupWidth + root.margin; to: 0; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                }
            }

            ParallelAnimation {
                id: snapBack
                NumberAnimation { target: card; property: "dragX"; to: 0; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }

            SequentialAnimation {
                id: animOut
                ParallelAnimation {
                    NumberAnimation { target: card; property: "dragX"; to: -(root.popupWidth + root.margin); duration: 300; easing.type: Easing.InCubic }
                    NumberAnimation { target: card; property: "entryOpacity"; to: 0; duration: 250 }
                    NumberAnimation { target: card; property: "entryScale"; to: 0.9; duration: 250 }
                }
                NumberAnimation { target: card; property: "height"; to: 0; duration: 180; easing.type: Easing.InOutQuad }
                ScriptAction { script: {
                    if (modelData && typeof modelData.close === "function") modelData.close();
                    card.destroy();
                }}
            }

            SequentialAnimation {
                id: animSwipeRight
                ParallelAnimation {
                    NumberAnimation { target: card; property: "dragX"; to: root.popupWidth + 60; duration: 250; easing.type: Easing.InCubic }
                    NumberAnimation { target: card; property: "entryOpacity"; to: 0.3; duration: 200 }
                }
                NumberAnimation { target: card; property: "height"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                ScriptAction { script: {
                    if (modelData && typeof modelData.close === "function") modelData.close();
                    card.destroy();
                }}
            }

            SequentialAnimation {
                id: animSwipeLeft
                ParallelAnimation {
                    NumberAnimation { target: card; property: "dragX"; to: -(root.popupWidth + 60); duration: 250; easing.type: Easing.InCubic }
                    NumberAnimation { target: card; property: "entryOpacity"; to: 0.3; duration: 200 }
                }
                NumberAnimation { target: card; property: "height"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                ScriptAction { script: {
                    if (modelData && typeof modelData.close === "function") modelData.close();
                    card.destroy();
                }}
            }

            function dismiss() {
                if (isClosing) return
                isClosing = true
                visible_ = false
                animOut.start()
            }

            function swipeDismiss(dir) {
                if (isClosing) return
                isClosing = true
                visible_ = false
                if (dir > 0) animSwipeRight.start(); else animSwipeLeft.start()
            }

            Connections {
                target: modelData
                function onClosedChanged() {
                    if (modelData.closed && !isClosing) {
                        card.dismiss()
                    }
                }
                function onUpdated() {
                    card.refresh()
                }
            }

            Item {
                id: body
                anchors.fill: parent
                scale: card.entryScale * card.refreshScale

                Rectangle {
                    anchors.fill: bg
                    radius: bg.radius
                    visible: Math.abs(card.dragX) > 20 && card.activeIndex === 0
                    opacity: Math.min(0.85, Math.abs(card.dragX) / (root.popupWidth * root.swipeThreshold * 1.5))
                    color: card.dragX > 0 ? Qt.rgba(root.errorColor.r, root.errorColor.g, root.errorColor.b, 0.06) : Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.06)
                    Text {
                        anchors.centerIn: parent
                        text: card.dragX > 0 ? "󰅖" : "󰄬"
                        font.family: "Material Design Icons"
                        font.pixelSize: 22
                        color: card.dragX > 0 ? root.errorColor : root.primaryColor
                        opacity: 0.5
                    }
                }

                Rectangle {
                    id: bg
                    width: parent.width
                    height: parent.height
                    radius: 14
                    color: root.surface
                    border.width: 1.25
                    border.color: Qt.rgba(root.urgencyColor(modelData.urgency).r, root.urgencyColor(modelData.urgency).g, root.urgencyColor(modelData.urgency).b, 0.32)
                    clip: true
                    Behavior on color { ColorAnimation { duration: 400 } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.2)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 4
                    }

                    // Gloss overlay
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        height: parent.height * 0.45
                        radius: parent.radius
                        visible: root.glassmorphism
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                        }
                        border.color: "transparent"
                        z: 999
                    }

                    // Progress timeout track (only visible on top card)
                    Rectangle {
                        id: progTrack
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: 4; leftMargin: 24; rightMargin: 24 }
                        height: 2; radius: 1
                        color: Qt.rgba(255, 255, 255, 0.04)
                        visible: card.visible_ && !card.hovered && card.activeIndex === 0
                        clip: true
                        Rectangle {
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            width: progTrack.width * card.timeoutProgress; radius: parent.radius
                            color: { const c = root.urgencyColor(modelData.urgency); return Qt.rgba(c.r, c.g, c.b, 0.5) }
                            NumberAnimation {
                                id: progAnim; target: card; property: "timeoutProgress"; from: 1; to: 0
                                duration: root.timeoutMs; running: card.visible_
                                onFinished: if (card.visible_) card.dismiss()
                            }
                        }
                    }

                    Connections {
                        target: card
                        function onHoveredChanged() { if (progAnim.running) progAnim.paused = card.hovered || card.dragging }
                        function onDraggingChanged() { if (progAnim.running) progAnim.paused = card.hovered || card.dragging }
                    }

                    // Card contents (fades out completely when card is stacked below index 0)
                    ColumnLayout {
                        id: col
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 6
                        opacity: card.activeIndex === 0 ? 1.0 : 0.0
                        visible: opacity > 0.001
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        // Header row (Badge, App Name / Title Column, Metadata Column, Expand button)
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 10
                                color: Qt.rgba(root.urgencyColor(modelData.urgency).r, root.urgencyColor(modelData.urgency).g, root.urgencyColor(modelData.urgency).b, 0.12)

                                Image {
                                    id: appIconImg
                                    anchors.centerIn: parent; width: 18; height: 18
                                    source: { if (!modelData.appIcon) return ""; if (modelData.appIcon.startsWith("/") || modelData.appIcon.startsWith("file://")) return modelData.appIcon; return "image://icon/" + modelData.appIcon }
                                    fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !appIconImg.visible
                                    text: (modelData.appName ?? "N").slice(0, 1).toUpperCase()
                                    font.family: "Inter"; font.pixelSize: 14; font.weight: Font.Bold
                                    color: root.urgencyColor(modelData.urgency)
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary || "Notification"
                                    font.family: "Inter"; font.pixelSize: 12; font.weight: Font.DemiBold
                                    color: root.textColor; elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.appName || "Unknown app"
                                    font.family: "Inter"; font.pixelSize: 10
                                    color: root.textMutedColor; elide: Text.ElideRight
                                }
                            }

                            ColumnLayout {
                                spacing: 2

                                Rectangle {
                                    Layout.alignment: Qt.AlignRight
                                    width: 6; height: 6; radius: 3
                                    visible: true // Popups are always unread
                                    color: Theme.primary
                                }

                                Text {
                                    Layout.alignment: Qt.AlignRight
                                    text: modelData.timeString || "now"
                                    font.family: "Inter"; font.pixelSize: 9
                                    color: root.textMutedColor
                                }
                            }

                            // Circular expand/chevron indicator
                            Rectangle {
                                Layout.preferredWidth: 20; Layout.preferredHeight: 20; radius: 10
                                color: "#1d1b20"
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: card.expanded ? "expand_less" : "expand_more"
                                    size: 14
                                    color: "#ffffff"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { card.expanded = !card.expanded; }
                                }
                            }
                        }

                        // Body Text
                        Text {
                            Layout.fillWidth: true
                            text: modelData.body || ""
                            visible: text.length > 0
                            wrapMode: Text.WordWrap
                            maximumLineCount: card.expanded ? 6 : 2
                            elide: Text.ElideRight
                            font.family: "Inter"; font.pixelSize: 10
                            color: root.textMutedColor
                        }

                        // Image attachment preview
                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: 120
                            visible: card.expanded && modelData.image && modelData.image.length > 0
                            Rectangle {
                                anchors.fill: parent; radius: 10; clip: true
                                color: root.surface
                                Image {
                                    anchors.fill: parent; anchors.margins: 1
                                    source: { 
                                        if (!modelData.image) return ""; 
                                        if (modelData.image.startsWith("/") || modelData.image.startsWith("file://") || modelData.image.startsWith("image://")) return modelData.image; 
                                        return "image://icon/" + modelData.image; 
                                    }
                                    fillMode: Image.PreserveAspectCrop; smooth: true; asynchronous: true
                                    layer.enabled: true; layer.effect: MultiEffect { maskEnabled: true; maskThresholdMin: 0.5; maskSpreadAtMin: 1; maskSource: ShaderEffectSource { sourceItem: Rectangle { width: 1; height: 1; radius: 9 } } }
                                }
                            }
                        }

                        // Actions Flow
                        Flow {
                            Layout.fillWidth: true; Layout.topMargin: 4
                            spacing: 6; visible: card.expanded && modelData.actions && modelData.actions.length > 0
                            Repeater {
                                model: card.modelData.actions || []
                                Rectangle {
                                    required property var modelData
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: Math.min(120, label.implicitWidth + 14)
                                    radius: 12
                                    color: actMA.pressed ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.28) : actMA.containsMouse ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.18) : Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.12)
                                    scale: actMA.pressed ? 0.94 : 1
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    Text {
                                        id: label; anchors.centerIn: parent
                                        text: parent.modelData.text || parent.modelData.identifier
                                        font.family: "Inter"; font.pixelSize: 10; font.weight: Font.Medium
                                        color: Theme.primary
                                    }
                                    MouseArea {
                                        id: actMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { parent.modelData.invoke(); card.dismiss() }
                                    }
                                }
                            }
                        }
                    }
                }

                // Swipe Gesture Area (only active for top card)
                MouseArea {
                    id: gestureArea
                    anchors.fill: bg; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    enabled: card.activeIndex === 0

                    property real startX: 0
                    property bool gestureStarted: false
                    property real scrollAccum: 0
                    property bool isScrolling: false

                    onEntered: card.hovered = true
                    onExited: { if (!pressed && !isScrolling) card.hovered = false }

                    onWheel: wheel => {
                        if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
                            wheel.accepted = true
                            scrollAccum += wheel.angleDelta.x * 0.5
                            card.dragX = scrollAccum; isScrolling = true; card.dragging = true; sTimer.restart()
                            if (Math.abs(scrollAccum) > root.popupWidth * root.swipeThreshold) {
                                sTimer.stop(); isScrolling = false; card.swipeDismiss(scrollAccum); scrollAccum = 0
                            }
                        }
                    }

                    Timer {
                        id: sTimer; interval: 300
                        onTriggered: {
                            gestureArea.isScrolling = false; card.dragging = false
                            const thresh = root.popupWidth * root.swipeThreshold
                            if (Math.abs(gestureArea.scrollAccum) > thresh) card.swipeDismiss(gestureArea.scrollAccum)
                            else snapBack.start()
                            gestureArea.scrollAccum = 0
                        }
                    }

                    onPressed: mouse => { startX = mouse.x; gestureStarted = false; card.dragging = false; scrollAccum = 0 }
                    onPositionChanged: mouse => {
                        if (!pressed) return
                        const dx = mouse.x - startX
                        if (!gestureStarted && Math.abs(dx) > 10) { gestureStarted = true; card.dragging = true }
                        if (card.dragging) card.dragX = dx * 0.8
                    }
                    onReleased: mouse => {
                        card.dragging = false; if (!containsMouse) card.hovered = false
                        const thresh = root.popupWidth * root.swipeThreshold
                        if (Math.abs(card.dragX) > thresh) card.swipeDismiss(card.dragX)
                        else snapBack.start()
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) { card.dismiss() }
                        else if (!gestureStarted) {
                            if (modelData.actions && modelData.actions.length === 1) { modelData.actions[0].invoke(); card.dismiss() }
                            else card.expanded = !card.expanded
                        }
                    }
                }
            }
        }
    }
}
