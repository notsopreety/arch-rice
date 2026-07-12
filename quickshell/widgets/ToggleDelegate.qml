import "../core"
import "../core/functions" as Functions
import "../services"
import "../theme"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * Quick Settings toggle button — supports size 1 (icon-only) and size 2 (expanded with label).
 *
 * Normal mode:
 *   - Left-click: toggle action (or open detail panel if expanded + hasDetails)
 *   - Right-click: open detail panel (for icon-only toggles with details)
 *
 * Edit mode (handled by blocking MouseArea on top):
 *   - Left-click: enable/disable toggle (add/remove from list)
 *   - Right-click: cycle size (1 ↔ 2)
 *   - Scroll: reorder position
 */
RippleButton {
    id: root

    // Data from repeater
    required property int buttonIndex
    required property var buttonData
    required property var allToggles
    required property bool editMode
    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing

    // Signals
    signal openDetails()
    signal dragStarted(real startX, real startY)
    signal dragUpdated(real mouseX, real mouseY)
    signal dragFinished()

    // Resolved toggle info
    property var toggleData: allToggles ? (allToggles[buttonData.type] !== undefined ? allToggles[buttonData.type] : null) : null
    property bool isToggled: (toggleData && toggleData.toggled !== undefined) ? toggleData.toggled : false
    property int cellSize: {
        if (!Config.options || !Config.options.quickSettings || !Config.options.quickSettings.toggles) {
            return (buttonData && buttonData.size !== undefined) ? buttonData.size : 1;
        }
        const type = buttonData.type;
        const item = Config.options.quickSettings.toggles.find(t => t && t.type === type);
        return item ? (item.size || 1) : 1;
    }
    property bool expandedSize: cellSize > 1
    property bool hasMenu: false  // Removed: left click always toggles now

    // Sizing (Both Layout-based and absolute dimensions for parent absolute container)
    Layout.preferredWidth: Math.floor(baseCellWidth * cellSize + cellSpacing * (cellSize - 1))
    Layout.preferredHeight: baseCellHeight
    width: Math.floor(baseCellWidth * cellSize + cellSpacing * (cellSize - 1))
    height: baseCellHeight

    // Drag / Animation states
    property bool dragging: false
    readonly property bool inRemoveZone: dragging && (y > (parent ? parent.height + 10 * Appearance.effectiveScale : 9999))
    scale: dragging ? 1.15 : 1.0
    opacity: dragging ? (inRemoveZone ? 0.5 : 0.95) : 1.0
    z: dragging ? 100 : (root.editMode ? 10 : 1)

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    Behavior on x {
        enabled: !root.dragging
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !root.dragging
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    visible: toggleData !== null && (editMode || (toggleData.available !== undefined ? toggleData.available : true))
    enabled: (toggleData && toggleData.available !== undefined ? toggleData.available : true) || editMode
    padding: 6 * Appearance.effectiveScale

    // Styling
    toggled: hasMenu ? false : isToggled
    colBackground: toggleData && toggleData.customColorInactive !== undefined ? toggleData.customColorInactive : Qt.rgba(255, 255, 255, 0.05)
    colBackgroundHover: toggleData && toggleData.customColorInactiveHover !== undefined ? toggleData.customColorInactiveHover : Qt.rgba(255, 255, 255, 0.1)
    colBackgroundToggled: (hasMenu) ? colBackground : (toggleData && toggleData.customColorActive !== undefined ? toggleData.customColorActive : Theme.primary)
    colBackgroundToggledHover: (hasMenu) ? colBackgroundHover : (toggleData && toggleData.customColorActiveHover !== undefined ? toggleData.customColorActiveHover : colBackgroundToggled)
    
    buttonRadius: isToggled ? 16 * Appearance.effectiveScale : height / 2

    property color colText: isToggled 
        ? (toggleData && toggleData.customTextColorActive !== undefined ? toggleData.customTextColorActive : Theme.onPrimary)
        : (toggleData && toggleData.customTextColorInactive !== undefined ? toggleData.customTextColorInactive : "#ffffff")
    property color colIcon: toggleData && toggleData.customIconColor !== undefined ? toggleData.customIconColor : colText

    // ── Normal mode click handling ──
    // Left click always toggles the toggle on/off
    onClicked: {
        if (toggleData && toggleData.action) toggleData.action();
    }

    // Right click opens detail panel (e.g., WiFi networks, Bluetooth devices)
    altAction: {
        if (!editMode) {
            if (toggleData && toggleData.hasDetails && toggleData.detailsAction) return (() => toggleData.detailsAction());
            if (toggleData && toggleData.altAction) return toggleData.altAction;
        }
        return null;
    }

    // Content
    contentItem: Item {
        // Optional border overlay for custom styled toggles (like Power Profile)
        Rectangle {
            anchors.fill: parent
            radius: root.buttonRadius
            color: "transparent"
            border.color: root.isToggled ? (root.toggleData && root.toggleData.customBorderColorActive !== undefined ? root.toggleData.customBorderColorActive : "transparent") : (root.toggleData && root.toggleData.customBorderColorInactive !== undefined ? root.toggleData.customBorderColorInactive : "transparent")
            border.width: border.color !== "transparent" ? 1 : 0
            visible: border.width > 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            spacing: 6 * Appearance.effectiveScale
            
            // Spacers for 1x centering
            Item { Layout.fillWidth: true; visible: !root.expandedSize }

            // Icon area (clickable toggle zone for expanded+hasDetails buttons)
            MouseArea {
                id: iconMouseArea
                hoverEnabled: root.hasMenu
                propagateComposedEvents: true
                acceptedButtons: (root.hasMenu) ? Qt.LeftButton : Qt.NoButton
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 36 * Appearance.effectiveScale
                Layout.preferredWidth: 36 * Appearance.effectiveScale
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (root.toggleData && root.toggleData.action) root.toggleData.action();
                }

                Rectangle {
                    id: iconBackground
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: (root.hasMenu && root.isToggled) ? 12 * Appearance.effectiveScale : width / 2
                    color: {
                        const isActive = root.isToggled
                        const baseColor = isActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                        const transparentizeAmount = (root.hasMenu && isActive) ? 0 : 1
                        return Functions.ColorUtils.transparentize(baseColor, transparentizeAmount)
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: root.isToggled ? 1 : 0
                        iconSize: root.expandedSize ? 20 * Appearance.effectiveScale : 22 * Appearance.effectiveScale
                        color: root.colIcon
                        text: root.isToggled 
                            ? (root.toggleData && root.toggleData.icon !== undefined ? root.toggleData.icon : "check") 
                            : (root.toggleData && root.toggleData.iconOff !== undefined ? root.toggleData.iconOff : (root.toggleData && root.toggleData.icon !== undefined ? root.toggleData.icon : "circle"))
                    }

                    // Hover state layer for icon area when it acts as a button
                    Rectangle {
                        anchors.fill: parent
                        radius: iconBackground.radius
                        visible: root.hasMenu
                        color: Functions.ColorUtils.transparentize(
                            root.colIcon, 
                            iconMouseArea.containsPress ? 0.88 : iconMouseArea.containsMouse ? 0.95 : 1
                        )
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }

            // Text column — only shown when expanded
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                visible: root.expandedSize
                spacing: -2 * Appearance.effectiveScale

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.toggleData && root.toggleData.name !== undefined ? root.toggleData.name : ""
                }

                StyledText {
                    visible: (root.toggleData && root.toggleData.statusText !== undefined) ? root.toggleData.statusText !== "" : false
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.toggleData && root.toggleData.statusText !== undefined ? root.toggleData.statusText : ""
                }
            }

            // Spacers for 1x centering
            Item { Layout.fillWidth: true; visible: !root.expandedSize }
        }
    }

    // ── Edit mode: blocking MouseArea ──
    // Sits on top of everything and handles all edit interactions via direct mutation
    MouseArea {
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        property real pressX: 0
        property real pressY: 0
        property bool dragDetected: false
        property bool dragDetectedButIgnored: false
        property real dragThreshold: 8 * Appearance.effectiveScale

        function toggleEnabled() {
            var toggleList = (Config.options.quickSettings && Config.options.quickSettings.toggles !== undefined) ? Config.options.quickSettings.toggles : null;
            
            if (!toggleList) return;
            var buttonType = root.buttonData.type;
            var found = false;
            var foundIndex = -1;
            
            for (var i = 0; i < toggleList.length; i++) {
                if (toggleList[i].type === buttonType) { 
                    found = true; 
                    foundIndex = i;
                    break; 
                }
            }

            if (found) {
                toggleList.splice(foundIndex, 1);
            } else {
                toggleList.push({ type: buttonType, size: 1 });
            }
            Config.options.quickSettings.toggles = toggleList;
        }

        function toggleSize() {
            var toggleList = (Config.options.quickSettings && Config.options.quickSettings.toggles !== undefined) ? Config.options.quickSettings.toggles : null;
            if (!toggleList) return;
            var idx = root.buttonIndex;
            if (idx < 0 || idx >= toggleList.length) return;
            var currentSize = toggleList[idx].size || 1;
            toggleList[idx].size = (currentSize === 1) ? 2 : 1;
            
            // Force re-evaluation of the list to trigger signals
            Config.options.quickSettings.toggles = toggleList;
        }

        onPressed: (event) => {
            if (event.button === Qt.RightButton) {
                toggleSize();
            } else if (event.button === Qt.LeftButton) {
                pressX = event.x;
                pressY = event.y;
                dragDetected = false;
                dragDetectedButIgnored = false;
            }
        }

        onPositionChanged: (event) => {
            if (pressed && (pressedButtons & Qt.LeftButton) && root.buttonIndex >= 0) {
                var dx = event.x - pressX;
                var dy = event.y - pressY;
                var moved = Math.sqrt(dx*dx + dy*dy) > dragThreshold;
                
                if (moved) {
                    var isCtrlPressed = (event.modifiers & Qt.ControlModifier);
                    if (isCtrlPressed) {
                        if (!dragDetected) {
                            dragDetected = true;
                            var mappedPress = root.mapToItem(root.parent, pressX, pressY);
                            var offsetX = mappedPress.x - root.x;
                            var offsetY = mappedPress.y - root.y;
                            root.dragStarted(offsetX, offsetY);
                        }
                    } else {
                        dragDetectedButIgnored = true;
                    }
                }
                
                if (dragDetected) {
                    var mappedMouse = root.mapToItem(root.parent, event.x, event.y);
                    root.dragUpdated(mappedMouse.x, mappedMouse.y);
                }
            }
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton) {
                if (dragDetected) {
                    dragDetected = false;
                    root.dragFinished();
                } else if (!dragDetectedButIgnored) {
                    toggleEnabled();
                }
                dragDetectedButIgnored = false;
            }
        }
    }

    // Edit mode visual overlay (purely visual, behind the MouseArea)
    Rectangle {
        visible: root.editMode
        anchors.fill: parent
        radius: root.buttonRadius
        // Active toggles get red remove overlay; unused get green add overlay
        property bool isActive: root.buttonIndex >= 0
        color: Functions.ColorUtils.transparentize(
            isActive ? Appearance.m3colors.m3error : Appearance.colors.colPrimary,
            0.85
        )

        MaterialSymbol {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4 * Appearance.effectiveScale
            text: parent.isActive ? "remove_circle" : "add_circle"
            color: parent.isActive ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
            iconSize: 18 * Appearance.effectiveScale
            fill: 1
        }
        // Size indicator — only for active toggles
        StyledText {
            visible: parent.isActive
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 6 * Appearance.effectiveScale
            text: root.cellSize === 1 ? "1×" : "2×"
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.m3colors.m3error
        }
    }

    // Shadow underneath the button when dragged
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4 * Appearance.effectiveScale
        radius: root.buttonRadius
        color: "#000000"
        opacity: root.dragging ? 0.35 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Glow/light effect under the delegate when dragging
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4 * Appearance.effectiveScale
        radius: root.buttonRadius + 4 * Appearance.effectiveScale
        color: "transparent"
        border.color: root.inRemoveZone 
            ? Qt.rgba(Appearance.m3colors.m3error.r, Appearance.m3colors.m3error.g, Appearance.m3colors.m3error.b, 0.8)
            : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4)
        border.width: 2 * Appearance.effectiveScale
        visible: root.dragging
        z: -1
        
        // Add a pulsating effect to the glow/light (only when not in remove zone)
        SequentialAnimation on border.color {
            running: root.dragging && !root.inRemoveZone
            loops: Animation.Infinite
            ColorAnimation { to: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.8); duration: 800; easing.type: Easing.InOutQuad }
            ColorAnimation { to: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4); duration: 800; easing.type: Easing.InOutQuad }
        }
    }

    // Tooltip
    ToolTip {
        id: toggleTooltip
        visible: !root.editMode && (root.hovered || root.realHovered) && (text !== "")
        delay: 300
        text: {
            const data = root.toggleData;
            if (!data) return "";
            if (data.tooltipText) return data.tooltipText;
            if (data.name) {
                return (data.statusText && data.statusText !== "") 
                    ? data.name + ": " + data.statusText
                    : data.name;
            }
            return "";
        }
        
        contentItem: StyledText {
            text: toggleTooltip.text
            color: Theme.primary
            font.pixelSize: Appearance.font.pixelSize.smaller
            horizontalAlignment: Text.AlignHCenter
        }

        background: Rectangle {
            color: Theme.surfaceContainerHigh
            radius: 8 * Appearance.effectiveScale
            border.color: Theme.outlineVariant
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
        }
    }
}
