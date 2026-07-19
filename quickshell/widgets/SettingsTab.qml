import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../services"
import QtCore
import "../core"

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Widget visibility states
    property bool clockWidgetActive: true
    property bool photoFrameWidgetActive: true
    property bool activateLinuxWidgetActive: true
    property bool flowersWidgetActive: false

    function loadWidgetSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            if (data.clock && data.clock.isActive !== undefined)
                root.clockWidgetActive = data.clock.isActive;
            if (data.photoFrame && data.photoFrame.isActive !== undefined)
                root.photoFrameWidgetActive = data.photoFrame.isActive;
            if (data.activateLinux && data.activateLinux.isActive !== undefined)
                root.activateLinuxWidgetActive = data.activateLinux.isActive;
            if (data.flowersWidget && data.flowersWidget.isActive !== undefined)
                root.flowersWidgetActive = data.flowersWidget.isActive;
        } catch(e) {
            console.error("[SettingsTab] Failed to parse settings.json:", e);
        }
    }

    function saveWidgetSetting(widgetKey, isActive) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let val = isActive ? "True" : "False";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "w = data.setdefault('" + widgetKey + "', {}); " +
                  "w['isActive'] = " + val + "; " +
                  "tmp = path + '.tmp'; " +
                  "f = open(tmp, 'w'); " +
                  "json.dump(data, f, indent=2); " +
                  "f.close(); " +
                  "os.replace(tmp, path)";
        widgetSaveProc.command = ["python3", "-c", cmd];
        widgetSaveProc.running = true;
    }

    FileView {
        id: widgetSettingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true

        onLoaded: root.loadWidgetSettings(text())
        onFileChanged: widgetReloadTimer.restart()
    }

    Timer {
        id: widgetReloadTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: widgetSettingsFile.reload()
    }

    Process {
        id: widgetSaveProc
    }

    QQC.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        QQC.ScrollBar.vertical.policy: QQC.ScrollBar.AlwaysOff

        ColumnLayout {
            width: root.width - 32 * Appearance.effectiveScale
            x: 16 * Appearance.effectiveScale
            y: 16 * Appearance.effectiveScale
            spacing: 16 * Appearance.effectiveScale

            // =============================================
            // SECTION: System & UI Settings
            // =============================================
            Text {
                text: "System & UI Settings"
                font.family: Theme.font.family
                font.pixelSize: 18 * Appearance.effectiveScale
                font.weight: Font.Bold
                color: "white"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 16 * Appearance.effectiveScale
                rowSpacing: 16 * Appearance.effectiveScale

                // --- Niri Layout Toggle ---
                SettingsToggle {
                    id: autoTilingPill
                    property bool isNiri: true
                    isActive: isNiri
                    title: "Niri Layout"
                    statusText: isNiri ? "Enabled" : "Disabled"
                    iconName: "window"
                    iconOffName: "auto_awesome_mosaic"
                    tooltipText: "Toggle Niri Layout"
                    onClicked: {
                        autoTilingPill.isNiri = !autoTilingPill.isNiri
                        Quickshell.execDetached(["sh", "-c", "if [ -f ~/.config/hypr/.niri_tiling_enabled ]; then rm ~/.config/hypr/.niri_tiling_enabled; else touch ~/.config/hypr/.niri_tiling_enabled; fi; hyprctl reload"])
                    }
                    Process {
                        id: checkTilingState
                        command: ["sh", "-c", "[ -f ~/.config/hypr/.niri_tiling_enabled ] && echo enabled || echo disabled"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                autoTilingPill.isNiri = (data.trim() === "enabled");
                            }
                        }
                    }
                }

                // --- HL Scale Toggle ---
                SettingsToggle {
                    id: hlScalePill
                    property string currentScale: "auto"
                    isActive: currentScale !== "auto"
                    title: "HL Scale"
                    statusText: currentScale
                    iconName: "aspect_ratio"
                    tooltipText: "Change HL Scale"
                    onClicked: {
                        var nextScale = "auto";
                        if (hlScalePill.currentScale === "auto") {
                            nextScale = "1";
                        } else if (hlScalePill.currentScale === "1") {
                            nextScale = "1.25";
                        } else if (hlScalePill.currentScale === "1.25") {
                            nextScale = "1.5";
                        }
                        hlScalePill.currentScale = nextScale;
                        Quickshell.execDetached(["sh", "-c", "sed -i -E 's/(scale *= *)\"[^\"]+\"/\\1\"" + nextScale + "\"/g' ~/.config/hypr/lua.d/monitors.lua; hyprctl reload"]);
                    }
                    Process {
                        id: checkScaleState
                        command: ["sh", "-c", "grep 'scale *=' ~/.config/hypr/lua.d/monitors.lua | sed -E 's/.*scale *= *\\\"([^\\\"]+)\\\".*/\\1/'"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                if (data.trim() !== "") {
                                    hlScalePill.currentScale = data.trim();
                                }
                            }
                        }
                    }
                }

                // --- Glassmorphism Toggle ---
                SettingsToggle {
                    id: glassmorphismPill
                    property bool isGlass: false
                    isActive: isGlass
                    title: "Glassmorphism"
                    statusText: isGlass ? "Enabled" : "Disabled"
                    iconName: "blur_on"
                    iconOffName: "blur_off"
                    tooltipText: "Toggle Glassmorphism"
                    onClicked: {
                        glassmorphismPill.isGlass = !glassmorphismPill.isGlass
                        Quickshell.execDetached(["sh", "-c", "if [ -f ~/.config/hypr/.glassmorphism_enabled ]; then rm ~/.config/hypr/.glassmorphism_enabled; else touch ~/.config/hypr/.glassmorphism_enabled; fi; hyprctl reload"])
                    }
                    Process {
                        id: checkGlassState
                        command: ["sh", "-c", "[ -f ~/.config/hypr/.glassmorphism_enabled ] && echo enabled || echo disabled"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                glassmorphismPill.isGlass = (data.trim() === "enabled");
                            }
                        }
                    }
                }

                // --- Border Animation Toggle ---
                SettingsToggle {
                    id: borderanglePill
                    property bool isBorderangle: false
                    isActive: isBorderangle
                    title: "Border Animation"
                    statusText: isBorderangle ? "Enabled" : "Disabled"
                    iconName: "motion_mode"
                    iconOffName: "sync_disabled"
                    tooltipText: "Toggle Border Animation"
                    onClicked: {
                        borderanglePill.isBorderangle = !borderanglePill.isBorderangle
                        Quickshell.execDetached(["sh", "-c", "if [ -f ~/.config/hypr/.borderangle_enabled ]; then rm ~/.config/hypr/.borderangle_enabled; else touch ~/.config/hypr/.borderangle_enabled; fi; hyprctl reload"])
                    }
                    Process {
                        id: checkBorderangleState
                        command: ["sh", "-c", "[ -f ~/.config/hypr/.borderangle_enabled ] && echo enabled || echo disabled"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                borderanglePill.isBorderangle = (data.trim() === "enabled");
                            }
                        }
                    }
                }

                // --- Rounding Pill ---
                Rectangle {
                    id: roundingPill
                    property int value: 10
                    property bool isActive: value !== 10

                    HoverHandler {
                        id: roundingHover
                        onHoveredChanged: {
                            if (hovered) {
                                roundingInput.forceActiveFocus();
                                roundingInput.selectAll();
                            }
                        }
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            roundingPill.value = 10;
                            roundingInput.text = "10";
                            roundingInput.editingFinished();
                        }
                    }
                    QQC.ToolTip {
                        visible: roundingHover.hovered
                        delay: 200
                        y: -height - 4
                        contentItem: Text {
                            text: "Change Window Rounding"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                        background: Rectangle {
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                        }
                    }

                    Process {
                        id: checkRoundingState
                        command: ["sh", "-c", "grep -E 'rounding *=' ~/.config/hypr/lua.d/look_and_feel.lua | head -n 1 | grep -o '[0-9]\\+'"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                var val = parseInt(data.trim());
                                if (!isNaN(val)) {
                                    roundingPill.value = val;
                                    roundingInput.text = val.toString();
                                }
                            }
                        }
                    }

                    Process {
                        id: updateRoundingProc
                        running: false
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    radius: isActive ? 16 : height / 2
                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    color: {
                        if (isActive) {
                            return roundingHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary;
                        } else {
                            return roundingHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05);
                        }
                    }
                    border.color: isActive ? "transparent" : (roundingHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15))
                    border.width: 1 * Appearance.effectiveScale

                    scale: roundingHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale

                        DankIcon {
                            name: "rounded_corner"
                            size: 24 * Appearance.effectiveScale
                            color: roundingPill.isActive ? "#000000" : "white"
                        }

                        Text {
                            text: "Rounding"
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: roundingPill.isActive ? "#000000" : "white"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: roundingPill.value.toString() + "px"
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: roundingPill.isActive ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(1, 1, 1, 0.6)
                            visible: !roundingHover.hovered
                        }

                        RowLayout {
                            spacing: 4 * Appearance.effectiveScale
                            visible: roundingHover.hovered

                            Rectangle {
                                width: 36 * Appearance.effectiveScale
                                height: 32 * Appearance.effectiveScale
                                radius: 6 * Appearance.effectiveScale
                                color: Qt.rgba(0,0,0,0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                border.width: 1 * Appearance.effectiveScale

                                TextInput {
                                    id: roundingInput
                                    anchors.fill: parent
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: roundingPill.value.toString()
                                    color: "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 14 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    validator: IntValidator { bottom: 0; top: 100 }
                                    onEditingFinished: {
                                        let v = parseInt(text);
                                        if (!isNaN(v)) {
                                            roundingPill.value = v;
                                            updateRoundingProc.command = ["sh", "-c", "hyprctl keyword decoration:rounding " + v + " && sed -i -E 's/(rounding *= )[0-9]+(,*)/\\1" + v + "\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"];
                                            updateRoundingProc.running = true;
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Rectangle {
                                    width: 24 * Appearance.effectiveScale
                                    height: 15 * Appearance.effectiveScale
                                    radius: 4 * Appearance.effectiveScale
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                    border.width: 1 * Appearance.effectiveScale

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            roundingPill.value++;
                                            roundingInput.text = roundingPill.value.toString();
                                            roundingInput.editingFinished();
                                        }
                                    }
                                    DankIcon { name: "arrow_drop_up"; size: 16 * Appearance.effectiveScale; anchors.centerIn: parent; color: Theme.primary }
                                }
                                Rectangle {
                                    width: 24 * Appearance.effectiveScale
                                    height: 15 * Appearance.effectiveScale
                                    radius: 4 * Appearance.effectiveScale
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                    border.width: 1 * Appearance.effectiveScale

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (roundingPill.value > 0) roundingPill.value--;
                                            roundingInput.text = roundingPill.value.toString();
                                            roundingInput.editingFinished();
                                        }
                                    }
                                    DankIcon { name: "arrow_drop_down"; size: 16 * Appearance.effectiveScale; anchors.centerIn: parent; color: Theme.primary }
                                }
                            }
                        }
                    }
                }

                // --- Border Size Pill ---
                Rectangle {
                    id: borderSizePill
                    property int value: 2
                    property bool isActive: value !== 2

                    HoverHandler {
                        id: borderSizeHover
                        onHoveredChanged: {
                            if (hovered) {
                                borderSizeInput.forceActiveFocus();
                                borderSizeInput.selectAll();
                            }
                        }
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            borderSizePill.value = 2;
                            borderSizeInput.text = "2";
                            borderSizeInput.editingFinished();
                        }
                    }
                    QQC.ToolTip {
                        visible: borderSizeHover.hovered
                        delay: 200
                        y: -height - 4
                        contentItem: Text {
                            text: "Change Border Size"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                        background: Rectangle {
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                        }
                    }

                    Process {
                        id: checkBorderSizeState
                        command: ["sh", "-c", "grep -E 'border_size *=' ~/.config/hypr/lua.d/look_and_feel.lua | head -n 1 | grep -o '[0-9]\\+'"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                var val = parseInt(data.trim());
                                if (!isNaN(val)) {
                                    borderSizePill.value = val;
                                    borderSizeInput.text = val.toString();
                                }
                            }
                        }
                    }

                    Process {
                        id: updateBorderSizeProc
                        running: false
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    radius: isActive ? 16 : height / 2
                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    color: {
                        if (isActive) {
                            return borderSizeHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary;
                        } else {
                            return borderSizeHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05);
                        }
                    }
                    border.color: isActive ? "transparent" : (borderSizeHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15))
                    border.width: 1 * Appearance.effectiveScale

                    scale: borderSizeHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale

                        DankIcon {
                            name: "border_outer"
                            size: 24 * Appearance.effectiveScale
                            color: borderSizePill.isActive ? "#000000" : "white"
                        }

                        Text {
                            text: "Border Size"
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: borderSizePill.isActive ? "#000000" : "white"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: borderSizePill.value.toString() + "px"
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: Qt.rgba(1, 1, 1, 0.6)
                            visible: !borderSizeHover.hovered
                        }

                        RowLayout {
                            spacing: 4 * Appearance.effectiveScale
                            visible: borderSizeHover.hovered

                            Rectangle {
                                width: 36 * Appearance.effectiveScale
                                height: 32 * Appearance.effectiveScale
                                radius: 6 * Appearance.effectiveScale
                                color: Qt.rgba(0,0,0,0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                border.width: 1 * Appearance.effectiveScale

                                TextInput {
                                    id: borderSizeInput
                                    anchors.fill: parent
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: borderSizePill.value.toString()
                                    color: "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 14 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    validator: IntValidator { bottom: 0; top: 100 }
                                    onEditingFinished: {
                                        let v = parseInt(text);
                                        if (!isNaN(v)) {
                                            borderSizePill.value = v;
                                            updateBorderSizeProc.command = ["sh", "-c", "hyprctl keyword general:border_size " + v + " && sed -i -E 's/(border_size *= )[0-9]+(,*)/\\1" + v + "\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"];
                                            updateBorderSizeProc.running = true;
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Rectangle {
                                    width: 24 * Appearance.effectiveScale
                                    height: 15 * Appearance.effectiveScale
                                    radius: 4 * Appearance.effectiveScale
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                    border.width: 1 * Appearance.effectiveScale

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            borderSizePill.value++;
                                            borderSizeInput.text = borderSizePill.value.toString();
                                            borderSizeInput.editingFinished();
                                        }
                                    }
                                    DankIcon { name: "arrow_drop_up"; size: 16 * Appearance.effectiveScale; anchors.centerIn: parent; color: Theme.primary }
                                }
                                Rectangle {
                                    width: 24 * Appearance.effectiveScale
                                    height: 15 * Appearance.effectiveScale
                                    radius: 4 * Appearance.effectiveScale
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                                    border.width: 1 * Appearance.effectiveScale

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (borderSizePill.value > 0) borderSizePill.value--;
                                            borderSizeInput.text = borderSizePill.value.toString();
                                            borderSizeInput.editingFinished();
                                        }
                                    }
                                    DankIcon { name: "arrow_drop_down"; size: 16 * Appearance.effectiveScale; anchors.centerIn: parent; color: Theme.primary }
                                }
                            }
                        }
                    }
                }

                // --- Timezone Pill ---
                Rectangle {
                    id: timezonePill
                    property string timezoneVal: "Asia/Kathmandu"
                    property bool isActive: false

                    property var allowedTimezones: []

                    Process {
                        id: loadTimezonesProc
                        command: ["timedatectl", "list-timezones"]
                        running: true
                        stdout: StdioCollector {
                            onStreamFinished: {
                                var lines = this.text.split("\n");
                                var list = [];
                                for (var i = 0; i < lines.length; i++) {
                                    var tz = lines[i].trim();
                                    if (tz !== "") {
                                        list.push(tz);
                                    }
                                }
                                timezonePill.allowedTimezones = list;
                            }
                        }
                    }

                    property string suggestion: {
                        var typed = timezoneInput.text.trim();
                        if (typed === "") return "";
                        for (var i = 0; i < allowedTimezones.length; i++) {
                            var tz = allowedTimezones[i];
                            if (tz.toLowerCase().startsWith(typed.toLowerCase())) {
                                return tz;
                            }
                        }
                        return "";
                    }

                    HoverHandler {
                        id: timezoneHover
                        onHoveredChanged: {
                            if (hovered) {
                                timezoneInput.forceActiveFocus();
                            }
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            autodetectTimezoneProc.running = true;
                        }
                    }

                    Process {
                        id: autodetectTimezoneProc
                        command: ["curl", "-s", "https://ipapi.co/timezone"]
                        running: false
                        stdout: StdioCollector {
                            onStreamFinished: {
                                var tz = this.text.trim();
                                if (tz !== "" && tz.indexOf("/") !== -1) {
                                    timezonePill.timezoneVal = tz;
                                    timezoneInput.text = tz;
                                    updateTimezoneProc.command = ["pkexec", "timedatectl", "set-timezone", tz];
                                    updateTimezoneProc.running = true;
                                }
                            }
                        }
                    }

                    Process {
                        id: checkTimezoneState
                        command: ["timedatectl", "show", "--property=Timezone", "--value"]
                        running: true
                        stdout: SplitParser {
                            onRead: data => {
                                var val = data.trim();
                                if (val !== "") {
                                    timezonePill.timezoneVal = val;
                                    timezoneInput.text = val;
                                }
                            }
                        }
                    }

                    Process {
                        id: updateTimezoneProc
                        running: false
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    radius: height / 2
                    color: timezoneHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05)
                    border.color: timezoneHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    border.width: 1 * Appearance.effectiveScale

                    scale: timezoneHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale

                        DankIcon {
                            name: "public"
                            size: 24 * Appearance.effectiveScale
                            color: "white"
                        }

                        Text {
                            text: "Timezone"
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "white"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Display when not hovered
                        Text {
                            text: timezonePill.timezoneVal
                            font.family: Theme.font.family
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: Qt.rgba(1, 1, 1, 0.6)
                            visible: !timezoneHover.hovered
                            Layout.alignment: Qt.AlignRight
                        }

                        // Input field when hovered
                        Item {
                            id: inputWrapper
                            Layout.preferredWidth: 130 * Appearance.effectiveScale
                            Layout.preferredHeight: 32 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignRight
                            visible: timezoneHover.hovered

                            Rectangle {
                                anchors.fill: parent
                                radius: 6 * Appearance.effectiveScale
                                color: Qt.rgba(0, 0, 0, 0.3)
                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                                border.width: 1 * Appearance.effectiveScale

                                // Ghost text suggestion behind the input text
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8 * Appearance.effectiveScale
                                    anchors.rightMargin: 8 * Appearance.effectiveScale
                                    verticalAlignment: Text.AlignVCenter
                                    text: {
                                        var typed = timezoneInput.text;
                                        if (timezonePill.suggestion !== "" && timezonePill.suggestion.toLowerCase().startsWith(typed.toLowerCase())) {
                                            return typed + timezonePill.suggestion.substring(typed.length);
                                        }
                                        return "";
                                    }
                                    font.family: Theme.font.family
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    color: Qt.rgba(255, 255, 255, 0.25)
                                    clip: true
                                }

                                TextInput {
                                    id: timezoneInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8 * Appearance.effectiveScale
                                    anchors.rightMargin: 8 * Appearance.effectiveScale
                                    horizontalAlignment: TextInput.AlignLeft
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: timezonePill.timezoneVal
                                    color: "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    clip: true

                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Tab) {
                                            if (timezonePill.suggestion !== "") {
                                                var typed = text;
                                                if (timezonePill.suggestion.toLowerCase().startsWith(typed.toLowerCase())) {
                                                    text = timezonePill.suggestion;
                                                    cursorPosition = text.length;
                                                    event.accepted = true;
                                                }
                                            }
                                        }
                                    }

                                    onEditingFinished: {
                                        let v = text.trim();
                                        if (v !== "" && v !== timezonePill.timezoneVal) {
                                            timezonePill.timezoneVal = v;
                                            updateTimezoneProc.command = ["pkexec", "timedatectl", "set-timezone", v];
                                            updateTimezoneProc.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } // end System & UI GridLayout

            // =============================================
            // SECTION: Bar
            // =============================================
            Text {
                text: "Bar"
                font.family: Theme.font.family
                font.pixelSize: 16 * Appearance.effectiveScale
                font.weight: Font.Bold
                color: "white"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16 * Appearance.effectiveScale
                rowSpacing: 16 * Appearance.effectiveScale

                // --- Floating Bar Toggle ---
                SettingsToggle {
                    id: floatingBarPill
                    isActive: GlobalSettings.floatingBar
                    title: "Floating Bar"
                    statusText: GlobalSettings.floatingBar ? "Enabled" : "Disabled"
                    iconName: "open_in_new"
                    tooltipText: "Toggle Floating Bar"
                    onClicked: {
                        GlobalSettings.floatingBar = !GlobalSettings.floatingBar
                    }
                }

                // --- Auto Hide Bar Toggle ---
                SettingsToggle {
                    id: autoHideBarPill
                    isActive: GlobalSettings.autoHideBar
                    title: "Auto Hide"
                    statusText: GlobalSettings.autoHideBar ? "Enabled" : "Disabled"
                    iconName: "visibility_off"
                    tooltipText: "Toggle Auto Hide Bar"
                    onClicked: {
                        GlobalSettings.autoHideBar = !GlobalSettings.autoHideBar
                    }
                }
            } // end Bar GridLayout

            // =============================================
            // SECTION: Window Gaps
            // =============================================
            Text {
                text: "Window Gaps"
                font.family: Theme.font.family
                font.pixelSize: 16 * Appearance.effectiveScale
                font.weight: Font.Bold
                color: "white"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 16 * Appearance.effectiveScale
                rowSpacing: 16 * Appearance.effectiveScale

                // --- Gaps In Slider ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    radius: 24 * Appearance.effectiveScale
                    color: gapsInHover.hovered ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95) : Theme.surfaceContainer
                    border.color: gapsInHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    border.width: 1 * Appearance.effectiveScale

                    scale: gapsInHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: gapsInHover }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            gapsInSlider.value = 3;
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword general:gaps_in 3 && sed -i -E 's/(gaps_in *= )[0-9]+(,*)/\\13\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"]);
                        }
                    }

                    QQC.ToolTip {
                        visible: gapsInHover.hovered
                        delay: 200
                        y: -height - 4
                        contentItem: Text {
                            text: "Gaps In (Right Click to Reset)"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                        background: Rectangle {
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale

                        // Center Slider
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            StyledSlider {
                                id: gapsInSlider
                                anchors.centerIn: parent
                                width: parent.width
                                from: 0
                                to: 40
                                enabled: true
                                configuration: StyledSlider.Configuration.M
                                animateValue: !pressed
                                handleMargins: 4 * Appearance.effectiveScale
                                highlightColor: Theme.primary
                                trackColor: Theme.surfaceVariant
                                handleColor: Theme.primary

                                Process {
                                    id: checkGapsInState
                                    command: ["sh", "-c", "grep -E 'gaps_in *=' ~/.config/hypr/lua.d/look_and_feel.lua | head -n 1 | grep -o '[0-9]\\+'"]
                                    running: true
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var val = parseInt(data.trim());
                                            if (!isNaN(val)) {
                                                gapsInSlider.value = val;
                                            }
                                        }
                                    }
                                }

                                Process {
                                    id: setGapsInProc
                                    running: false
                                }

                                onMoved: {
                                    var val = Math.round(value);
                                    setGapsInProc.command = ["sh", "-c", "hyprctl keyword general:gaps_in " + val + " && sed -i -E 's/(gaps_in *= )[0-9]+(,*)/\\1" + val + "\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"];
                                    setGapsInProc.running = true;
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "GAPS IN"
                                font.pixelSize: 9 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: "#ffffff"
                                opacity: 0.35
                                z: 10
                            }
                        }

                        // Right value box
                        Rectangle {
                            width: 36 * Appearance.effectiveScale
                            height: 28 * Appearance.effectiveScale
                            radius: 10 * Appearance.effectiveScale
                            color: Theme.secondaryContainer
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                            border.width: 1 * Appearance.effectiveScale

                            Text {
                                anchors.centerIn: parent
                                text: Math.round(gapsInSlider.value)
                                font.pixelSize: 11 * Appearance.effectiveScale
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                            }
                        }
                    }
                }

                // --- Gaps Out Slider ---
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    radius: 24 * Appearance.effectiveScale
                    color: gapsOutHover.hovered ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95) : Theme.surfaceContainer
                    border.color: gapsOutHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    border.width: 1 * Appearance.effectiveScale

                    scale: gapsOutHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: gapsOutHover }

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            gapsOutSlider.value = 10;
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword general:gaps_out 10 && sed -i -E 's/(gaps_out *= )[0-9]+(,*)/\\110\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"]);
                        }
                    }

                    QQC.ToolTip {
                        visible: gapsOutHover.hovered
                        delay: 200
                        y: -height - 4
                        contentItem: Text {
                            text: "Gaps Out (Right Click to Reset)"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                        background: Rectangle {
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 12 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale

                        // Center Slider
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            StyledSlider {
                                id: gapsOutSlider
                                anchors.centerIn: parent
                                width: parent.width
                                from: 0
                                to: 40
                                enabled: true
                                configuration: StyledSlider.Configuration.M
                                animateValue: !pressed
                                handleMargins: 4 * Appearance.effectiveScale
                                highlightColor: Theme.primary
                                trackColor: Theme.surfaceVariant
                                handleColor: Theme.primary

                                Process {
                                    id: checkGapsOutState
                                    command: ["sh", "-c", "grep -E 'gaps_out *=' ~/.config/hypr/lua.d/look_and_feel.lua | head -n 1 | grep -o '[0-9]\\+'"]
                                    running: true
                                    stdout: SplitParser {
                                        onRead: data => {
                                            var val = parseInt(data.trim());
                                            if (!isNaN(val)) {
                                                gapsOutSlider.value = val;
                                            }
                                        }
                                    }
                                }

                                Process {
                                    id: setGapsOutProc
                                    running: false
                                }

                                onMoved: {
                                    var val = Math.round(value);
                                    setGapsOutProc.command = ["sh", "-c", "hyprctl keyword general:gaps_out " + val + " && sed -i -E 's/(gaps_out *= )[0-9]+(,*)/\\1" + val + "\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"];
                                    setGapsOutProc.running = true;
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "GAPS OUT"
                                font.pixelSize: 9 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: "#ffffff"
                                opacity: 0.35
                                z: 10
                            }
                        }

                        // Right value box
                        Rectangle {
                            width: 36 * Appearance.effectiveScale
                            height: 28 * Appearance.effectiveScale
                            radius: 10 * Appearance.effectiveScale
                            color: Theme.secondaryContainer
                            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                            border.width: 1 * Appearance.effectiveScale

                            Text {
                                anchors.centerIn: parent
                                text: Math.round(gapsOutSlider.value)
                                font.pixelSize: 11 * Appearance.effectiveScale
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                            }
                        }
                    }
                }

                // --- Sync Gaps Pill ---
                Rectangle {
                    id: syncGapsPill
                    property bool isActive: Math.round(gapsInSlider.value) === Math.round(gapsOutSlider.value)

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    radius: isActive ? 16 : height / 2
                    Behavior on radius { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    color: {
                        if (isActive) {
                            return syncGapsHover.hovered ? Qt.darker(Theme.primary, 1.1) : Theme.primary;
                        } else {
                            return syncGapsHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05);
                        }
                    }
                    border.color: isActive ? "transparent" : (syncGapsHover.hovered ? Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15))
                    border.width: 1 * Appearance.effectiveScale

                    scale: syncGapsHover.hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: syncGapsHover }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            gapsInSlider.value = 3;
                            gapsOutSlider.value = 10;
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword general:gaps_in 3 && hyprctl keyword general:gaps_out 10 && sed -i -E 's/(gaps_in *= )[0-9]+(,*)/\\13\\2/; s/(gaps_out *= )[0-9]+(,*)/\\110\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"]);
                        }
                    }
                    QQC.ToolTip {
                        visible: syncGapsHover.hovered
                        delay: 200
                        y: -height - 4
                        contentItem: Text {
                            text: "Sync Gaps (Right Click to Reset)"
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                        background: Rectangle {
                            color: Theme.surfaceContainer
                            border.color: Theme.outline
                            border.width: 1 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale

                        DankIcon {
                            name: "sync"
                            size: 24 * Appearance.effectiveScale
                            color: syncGapsPill.isActive ? "#000000" : "white"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "Sync Gaps"
                                font.family: Theme.font.family
                                font.pixelSize: 14 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: syncGapsPill.isActive ? "#000000" : "white"
                            }

                            Text {
                                text: "Match Out to In"
                                font.family: Theme.font.family
                                font.pixelSize: 12 * Appearance.effectiveScale
                                color: syncGapsPill.isActive ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(1, 1, 1, 0.6)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var val = gapsInSlider.value;
                            gapsOutSlider.value = val;
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword general:gaps_out " + val + " && sed -i -E 's/(gaps_out *= )[0-9]+(,*)/\\1" + val + "\\2/' ~/.config/hypr/lua.d/look_and_feel.lua"]);
                        }
                    }
                }
            } // end Window Gaps GridLayout

            // =============================================
            // SECTION: Desktop Widgets
            // =============================================
            Text {
                text: "Desktop Widgets"
                font.family: Theme.font.family
                font.pixelSize: 16 * Appearance.effectiveScale
                font.weight: Font.Bold
                color: "white"
            }


            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16 * Appearance.effectiveScale
                rowSpacing: 16 * Appearance.effectiveScale

                // --- Clock Widget Toggle ---
                SettingsToggle {
                    id: clockWidgetPill
                    isActive: root.clockWidgetActive
                    title: "Clock Widget"
                    statusText: root.clockWidgetActive ? "Visible" : "Hidden"
                    iconName: "schedule"
                    iconOffName: "timer_off"
                    tooltipText: "Toggle Clock Desktop Widget"
                    onClicked: {
                        root.clockWidgetActive = !root.clockWidgetActive;
                        root.saveWidgetSetting("clock", root.clockWidgetActive);
                    }
                }

                // --- Photo Frame Widget Toggle ---
                SettingsToggle {
                    id: photoFrameWidgetPill
                    isActive: root.photoFrameWidgetActive
                    title: "Photo Frame"
                    statusText: root.photoFrameWidgetActive ? "Visible" : "Hidden"
                    iconName: "photo_frame"
                    iconOffName: "hide_image"
                    tooltipText: "Toggle Photo Frame Desktop Widget"
                    onClicked: {
                        root.photoFrameWidgetActive = !root.photoFrameWidgetActive;
                        root.saveWidgetSetting("photoFrame", root.photoFrameWidgetActive);
                    }
                }

                // --- Activate Linux Widget Toggle ---
                SettingsToggle {
                    id: activateLinuxWidgetPill
                    isActive: root.activateLinuxWidgetActive
                    title: "Activate Linux"
                    statusText: root.activateLinuxWidgetActive ? "Visible" : "Hidden"
                    iconName: "verified"
                    iconOffName: "verified_user"
                    tooltipText: "Toggle Activate Linux Desktop Watermark"
                    onClicked: {
                        root.activateLinuxWidgetActive = !root.activateLinuxWidgetActive;
                        root.saveWidgetSetting("activateLinux", root.activateLinuxWidgetActive);
                    }
                }

                // --- Flowers Widget Toggle ---
                SettingsToggle {
                    id: flowersWidgetPill
                    isActive: root.flowersWidgetActive
                    title: "Flowers Widget"
                    statusText: root.flowersWidgetActive ? "Visible" : "Hidden"
                    iconName: "local_florist"
                    iconOffName: "spa"
                    tooltipText: "Toggle Flowers Desktop Widget"
                    onClicked: {
                        root.flowersWidgetActive = !root.flowersWidgetActive;
                        root.saveWidgetSetting("flowersWidget", root.flowersWidgetActive);
                    }
                }
            } // end Desktop Widgets GridLayout

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 20 * Appearance.effectiveScale
            }
        } // end ColumnLayout
    } // end ScrollView
} // end root Item
