import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import "../../core"
import "../../theme"
import "../../services"
import "../"
import "toggles"

Item {
    id: root

    property bool editMode: false
    implicitWidth: parent.width
    implicitHeight: mainColumn.implicitHeight

    // ── Instantiate each toggle component from the toggles/ directory ──
    WifiToggle { id: wifiToggle }
    BluetoothToggle { id: bluetoothToggle }
    DndToggle { id: dndToggle }
    CaffeineToggle { id: caffeineToggle }
    ScreenshotToggle { id: screenshotToggle }
    ScreenRecordToggle { id: screenRecordToggle }
    GoogleLensToggle { id: googleLensToggle }
    SnipToggle { id: snipToggle }
    ReadingModeToggle { id: readingModeToggle }
    ColorPickerToggle { id: colorPickerToggle }
    PowerProfileToggle { id: powerProfileToggle }
    AirplaneModeToggle { id: airplaneModeToggle }
    ConservationModeToggle { id: conservationModeToggle }
    SystemUpdateToggle { id: systemUpdateToggle }

    // ── Toggle grid constants ──
    readonly property int columns: 4
    readonly property real toggleSpacing: 8 * Appearance.effectiveScale
    readonly property real togglePadding: 2 * Appearance.effectiveScale
    readonly property real baseCellWidth: {
        const availableWidth = root.width - (togglePadding * 2) - (toggleSpacing * (columns - 1))
        return Math.max(40 * Appearance.effectiveScale, Math.floor(availableWidth / columns))
    }
    readonly property real baseCellHeight: 52 * Appearance.effectiveScale

    // ── Toggle registry (maps config keys to instantiated objects) ──
    readonly property var allToggles: ({
        "wifi": wifiToggle,
        "bluetooth": bluetoothToggle,
        "dnd": dndToggle,
        "caffeine": caffeineToggle,
        "screenshot": screenshotToggle,
        "screenRecord": screenRecordToggle,
        "googleLens": googleLensToggle,
        "screenSnip": snipToggle,
        "nightLight": readingModeToggle,
        "colorPicker": colorPickerToggle,
        "powerProfile": powerProfileToggle,
        "airplaneMode": airplaneModeToggle,
        "conservationMode": conservationModeToggle,
        "systemUpdate": systemUpdateToggle
    })

    // ── Toggle data sources ──
    readonly property var availableToggleTypes: [
        "wifi", "bluetooth", "dnd", "darkMode", "caffeine", "nightLight",
        "colorPicker", "screenSnip", "gameMode", "screenRecord",
        "musicRecognition", "easyEffects", "conservationMode", "warp",
        "screenshot", "googleLens", "airplaneMode", "powerProfile", "systemUpdate"
    ]

    readonly property var toggles: Config.options.quickSettings.toggles
    readonly property var toggleRows: toggleRowsForList(toggles)
    readonly property var unusedToggles: {
        const types = availableToggleTypes.filter(type => {
            return (root.allToggles[type] !== undefined) && !toggles.some(toggle => (toggle && toggle.type === type));
        })
        return types.map(type => { return { type: type, size: 1 } })
    }
    readonly property var unusedToggleRows: toggleRowsForList(unusedToggles)

    // Drag-and-drop state properties
    property int draggingIndex: -1
    property real dragX: 0
    property real dragY: 0
    property real dragStartMouseX: 0
    property real dragStartMouseY: 0
    property bool isReallyDragging: false
    property var visualOrder: []

    onTogglesChanged: {
        if (draggingIndex === -1) {
            updateVisualOrder();
        }
    }

    Component.onCompleted: {
        updateVisualOrder();
    }

    function updateVisualOrder() {
        var arr = [];
        var len = (root.toggles !== undefined && root.toggles !== null) ? root.toggles.length : 0;
        for (var i = 0; i < len; i++) {
            arr.push(i);
        }
        root.visualOrder = arr;
    }

    readonly property var togglePositions: calculatePositions(root.visualOrder)
    readonly property real activeGridHeight: {
        if (togglePositions.length === 0) return 0;
        var maxY = 0;
        for (var i = 0; i < togglePositions.length; i++) {
            if (togglePositions[i] && togglePositions[i].y > maxY) {
                maxY = togglePositions[i].y;
            }
        }
        return maxY + root.baseCellHeight + root.togglePadding;
    }

    function isToggleVisible(toggle) {
        if (!toggle) return false;
        var data = root.allToggles[toggle.type];
        if (!data) return false;
        if (root.editMode) return true;
        return (data.available !== undefined) ? data.available : true;
    }

    function calculatePositions(order) {
        var positions = [];
        for (var i = 0; i < root.toggles.length; i++) {
            positions.push({ x: 0, y: 0, width: 0, height: 0 });
        }
        if (order.length === 0) return positions;
        
        var occupied = [];
        
        for (var v = 0; v < order.length; v++) {
            var origIdx = order[v];
            var toggle = root.toggles[origIdx];
            if (!toggle) continue;
            
            if (!isToggleVisible(toggle)) {
                continue;
            }
            
            var size = toggle.size || 1;
            
            var foundRow = 0;
            var foundCol = 0;
            var found = false;
            
            for (var r = 0; !found; r++) {
                if (occupied[r] === undefined) {
                    occupied[r] = [false, false, false, false];
                }
                
                for (var c = 0; c <= root.columns - size; c++) {
                    var free = true;
                    for (var w = 0; w < size; w++) {
                        if (occupied[r][c + w]) {
                            free = false;
                            break;
                        }
                    }
                    if (free) {
                        foundRow = r;
                        foundCol = c;
                        found = true;
                        break;
                    }
                }
            }
            
            for (var w = 0; w < size; w++) {
                occupied[foundRow][foundCol + w] = true;
            }
            
            var posX = root.togglePadding + foundCol * (root.baseCellWidth + root.toggleSpacing);
            var posY = root.togglePadding + foundRow * (root.baseCellHeight + root.toggleSpacing);
            
            positions[origIdx] = {
                x: posX,
                y: posY,
                width: root.baseCellWidth * size + root.toggleSpacing * (size - 1),
                height: root.baseCellHeight
            };
        }
        return positions;
    }

    function getSlotAt(order, mouseX, mouseY) {
        var targetVisualIdx = -1;
        var minDist = 999999;
        
        var occupied = [];
        
        for (var v = 0; v < order.length; v++) {
            var origIdx = order[v];
            var toggle = root.toggles[origIdx];
            if (!toggle) continue;
            
            if (!isToggleVisible(toggle)) {
                continue;
            }
            
            var size = toggle.size || 1;
            
            var foundRow = 0;
            var foundCol = 0;
            var found = false;
            
            for (var r = 0; !found; r++) {
                if (occupied[r] === undefined) {
                    occupied[r] = [false, false, false, false];
                }
                
                for (var c = 0; c <= root.columns - size; c++) {
                    var free = true;
                    for (var w = 0; w < size; w++) {
                        if (occupied[r][c + w]) {
                            free = false;
                            break;
                        }
                    }
                    if (free) {
                        foundRow = r;
                        foundCol = c;
                        found = true;
                        break;
                    }
                }
            }
            
            for (var w = 0; w < size; w++) {
                occupied[foundRow][foundCol + w] = true;
            }
            
            var posX = root.togglePadding + foundCol * (root.baseCellWidth + root.toggleSpacing);
            var posY = root.togglePadding + foundRow * (root.baseCellHeight + root.toggleSpacing);
            var width = root.baseCellWidth * size + root.toggleSpacing * (size - 1);
            var height = root.baseCellHeight;
            
            if (mouseX >= posX && mouseX <= posX + width &&
                mouseY >= posY && mouseY <= posY + height) {
                return v;
            }
            
            var slotCenterX = posX + width / 2;
            var slotCenterY = posY + height / 2;
            var dist = Math.sqrt(Math.pow(mouseX - slotCenterX, 2) + Math.pow(mouseY - slotCenterY, 2));
            if (dist < minDist) {
                minDist = dist;
                targetVisualIdx = v;
            }
        }
        return targetVisualIdx;
    }

    function reorderVisual(fromVisualIdx, toVisualIdx) {
        if (fromVisualIdx === toVisualIdx) return;
        var order = [].concat(root.visualOrder);
        var item = order.splice(fromVisualIdx, 1)[0];
        order.splice(toVisualIdx, 0, item);
        root.visualOrder = order;
    }

    function handleDragMove(draggedIdx, mouseX, mouseY) {
        if (root.visualOrder.length === 0) return;
        
        var currentVisualIdx = root.visualOrder.indexOf(draggedIdx);
        if (currentVisualIdx === -1) return;
        
        var targetVisualIdx = getSlotAt(root.visualOrder, mouseX, mouseY);
        if (targetVisualIdx !== -1 && targetVisualIdx !== currentVisualIdx) {
            reorderVisual(currentVisualIdx, targetVisualIdx);
        }
    }

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0;
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            var typeInfo = root.allToggles[togglesList[i].type];
            if (!typeInfo) continue;

            var size = togglesList[i].size || 1;
            if (totalSize + size > columns) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            var toggleWithIdx = Object.assign({}, togglesList[i]);
            toggleWithIdx.originalIndex = i;
            row.push(toggleWithIdx);
            totalSize += size;
        }
        if (row.length > 0) rows.push(row);
        return rows;
    }

    Column {
        id: mainColumn
        width: parent.width
        spacing: 12 * Appearance.effectiveScale

        // Grid Area for Active Toggles (Absolute/Draggable Layout)
        Item {
            width: parent.width
            height: root.activeGridHeight

            Repeater {
                model: ScriptModel {
                    values: root.toggles
                    objectProp: "type"
                }

                delegate: ToggleDelegate {
                    id: toggleDel
                    required property var modelData
                    required property int index
                    
                    buttonIndex: index
                    buttonData: modelData
                    allToggles: root.allToggles
                    editMode: root.editMode
                    baseCellWidth: root.baseCellWidth
                    baseCellHeight: root.baseCellHeight
                    cellSpacing: root.toggleSpacing

                    // Absolute coordinates
                    x: dragging ? root.dragX : targetX
                    y: dragging ? root.dragY : targetY

                    dragging: root.draggingIndex === index
                    property real targetX: (root.togglePositions[index] !== undefined) ? root.togglePositions[index].x : 0
                    property real targetY: (root.togglePositions[index] !== undefined) ? root.togglePositions[index].y : 0

                    onDragStarted: (offsetX, offsetY) => {
                        root.draggingIndex = index;
                        root.dragX = x;
                        root.dragY = y;
                        root.dragStartMouseX = offsetX;
                        root.dragStartMouseY = offsetY;
                        root.isReallyDragging = true;
                    }

                    onDragUpdated: (parentMouseX, parentMouseY) => {
                        root.dragX = parentMouseX - root.dragStartMouseX;
                        root.dragY = parentMouseY - root.dragStartMouseY;
                        
                        root.handleDragMove(index, parentMouseX, parentMouseY);
                    }

                    onDragFinished: {
                        if (root.isReallyDragging) {
                            var dragYParent = toggleDel.y;
                            if (dragYParent > root.activeGridHeight + 10 * Appearance.effectiveScale) {
                                var list = [];
                                for (var i = 0; i < root.visualOrder.length; i++) {
                                    var origIdx = root.visualOrder[i];
                                    if (origIdx !== index) {
                                        list.push(root.toggles[origIdx]);
                                    }
                                }
                                Config.options.quickSettings.toggles = list;
                            } else {
                                var list = [];
                                for (var i = 0; i < root.visualOrder.length; i++) {
                                    list.push(root.toggles[root.visualOrder[i]]);
                                }
                                Config.options.quickSettings.toggles = list;
                            }
                        }
                        root.draggingIndex = -1;
                        root.isReallyDragging = false;
                    }
                }
            }
        }

        // Available Toggles Section (Shown only in Edit Mode)
        Loader {
            width: parent.width
            active: root.editMode && root.unusedToggles.length > 0
            visible: active
            sourceComponent: Column {
                spacing: 8 * Appearance.effectiveScale

                StyledText {
                    text: "Available Toggles"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Theme.primary
                }

                Column {
                    width: parent.width
                    spacing: root.toggleSpacing

                    Repeater {
                        model: ScriptModel {
                            values: Array(root.unusedToggleRows.length)
                        }

                        delegate: RowLayout {
                            id: unusedRow
                            required property int index
                            property var modelData: root.unusedToggleRows[index]
                            width: parent.width
                            spacing: root.toggleSpacing

                            Repeater {
                                model: ScriptModel {
                                    values: (unusedRow && unusedRow.modelData !== undefined) ? unusedRow.modelData : []
                                    objectProp: "type"
                                }

                                delegate: ToggleDelegate {
                                    required property var modelData
                                    required property int index
                                    buttonIndex: -1  // Not in active list
                                    buttonData: modelData
                                    allToggles: root.allToggles
                                    editMode: root.editMode
                                    baseCellWidth: root.baseCellWidth
                                    baseCellHeight: root.baseCellHeight
                                    cellSpacing: root.toggleSpacing
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        // ── Interactive Key Helpers (Edit Mode Info Pill) ──
        Rectangle {
            width: parent.width
            implicitHeight: 40 * Appearance.effectiveScale
            radius: 12 * Appearance.effectiveScale
            color: Qt.rgba(Theme.primaryContainer.r, Theme.primaryContainer.g, Theme.primaryContainer.b, 0.25)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
            visible: root.editMode
            opacity: root.editMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 20 * Appearance.effectiveScale

                // Add/Remove
                RowLayout {
                    spacing: 6 * Appearance.effectiveScale
                    StyledText { text: "Add/Remove"; font.pixelSize: 10 * Appearance.effectiveScale; color: "#ffffff" }
                    Rectangle {
                        width: 44 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                        color: Theme.primaryContainer
                        StyledText { anchors.centerIn: parent; text: "LClick"; font.pixelSize: 9 * Appearance.effectiveScale; font.weight: Font.DemiBold; color: "#ffffff" }
                    }
                }

                // Resize
                RowLayout {
                    spacing: 6 * Appearance.effectiveScale
                    StyledText { text: "Resize"; font.pixelSize: 10 * Appearance.effectiveScale; color: "#ffffff" }
                    Rectangle {
                        width: 44 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                        color: Theme.primaryContainer
                        StyledText { anchors.centerIn: parent; text: "RClick"; font.pixelSize: 9 * Appearance.effectiveScale; font.weight: Font.DemiBold; color: "#ffffff" }
                    }
                }

                // Move
                RowLayout {
                    spacing: 6 * Appearance.effectiveScale
                    StyledText { text: "Move"; font.pixelSize: 10 * Appearance.effectiveScale; color: "#ffffff" }
                    Rectangle {
                        width: 60 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                        color: Theme.primaryContainer
                        StyledText { anchors.centerIn: parent; text: "Ctrl+Drag"; font.pixelSize: 9 * Appearance.effectiveScale; font.weight: Font.DemiBold; color: "#ffffff" }
                    }
                }
            }
        }
    }
}
