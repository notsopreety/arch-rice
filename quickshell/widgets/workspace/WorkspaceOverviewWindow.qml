pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../core"
import "../../theme"
import ".."

Item {
    id: root

    property var toplevel: null
    property var windowData: null
    property var monitorData: null
    property var widgetMonitor: null
    property real scale: 0.18
    property real xOffset: 0
    property real yOffset: 0
    property bool centerIcons: true
    property bool hovered: false
    property bool pressed: false
    property bool draggingActive: false
    property real topLeftRadius: 18
    property real topRightRadius: 18
    property real bottomLeftRadius: 18
    property real bottomRightRadius: 18

    readonly property real widthRatio: {
        if (!widgetMonitor || !monitorData)
            return 1;

        const widgetWidth = widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width;
        const monitorWidth = monitorData.transform & 1 ? monitorData.height : monitorData.width;
        return monitorWidth > 0 ? (widgetWidth * monitorData.scale) / (monitorWidth * widgetMonitor.scale) : 1;
    }
    readonly property real heightRatio: {
        if (!widgetMonitor || !monitorData)
            return 1;

        const widgetHeight = widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height;
        const monitorHeight = monitorData.transform & 1 ? monitorData.width : monitorData.height;
        return monitorHeight > 0 ? (widgetHeight * monitorData.scale) / (monitorHeight * widgetMonitor.scale) : 1;
    }
    property real screenPaddingFactor: 0.90
    readonly property real monitorRenderWidth: (monitorData && monitorData.width ? monitorData.width : 1920) * widthRatio * scale
    readonly property real monitorRenderHeight: (monitorData && monitorData.height ? monitorData.height : 1080) * heightRatio * scale
    readonly property real screenPaddingX: monitorRenderWidth * ((1.0 - screenPaddingFactor) / 2.0)
    readonly property real screenPaddingY: monitorRenderHeight * ((1.0 - screenPaddingFactor) / 2.0)

    readonly property real targetWindowWidth: Math.max(52, (windowData && windowData.size ? windowData.size[0] : 240) * scale * widthRatio * screenPaddingFactor)
    readonly property real targetWindowHeight: Math.max(38, (windowData && windowData.size ? windowData.size[1] : 140) * scale * heightRatio * screenPaddingFactor)
    readonly property real initX: {
        if (!windowData || !monitorData)
            return xOffset;

        const reserved = monitorData.reserved ? monitorData.reserved : [0, 0, 0, 0];
        const position = windowData.at ? windowData.at : [monitorData.x, monitorData.y];
        return Math.max((position[0] - monitorData.x - reserved[0]) * widthRatio * scale, 0) * screenPaddingFactor + xOffset + screenPaddingX;
    }
    readonly property real initY: {
        if (!windowData || !monitorData)
            return yOffset;

        const reserved = monitorData.reserved ? monitorData.reserved : [0, 0, 0, 0];
        const position = windowData.at ? windowData.at : [monitorData.x, monitorData.y];
        return Math.max((position[1] - monitorData.y - reserved[1]) * heightRatio * scale, 0) * screenPaddingFactor + yOffset + screenPaddingY;
    }
    readonly property string iconLookupName: {
        if (!windowData)
            return "";

        return windowData.class || windowData.initialClass || windowData.app_id || windowData.initialTitle || windowData.title || "";
    }
    readonly property string resolvedIconName: {
        const name = root.iconLookupName;
        if (!name) return "application-x-executable";
        const lower = name.toLowerCase();
        
        // App-specific normalization mappings to ensure high-quality icons load
        if (lower === "code" || lower === "code-url-handler") {
            return "code";
        } else if (lower.includes("vscodium") || lower.includes("codium")) {
            return "vscodium";
        } else if (lower === "spotify") {
            return "spotify-client";
        } else if (lower === "chrome" || lower.includes("chrome")) {
            return "google-chrome";
        }
        return name;
    }
    readonly property string iconPath: {
        const path = Quickshell.iconPath(root.resolvedIconName, true);
        if (path) return path;
        const fallback = Quickshell.iconPath("utilities-terminal", true) || Quickshell.iconPath("application-x-executable", true);
        return fallback || "";
    }
    property string searchQuery: ""
    readonly property bool matchesSearch: {
        if (!searchQuery || searchQuery.trim() === "")
            return true;
        const query = searchQuery.toLowerCase();
        const winClass = (windowData && windowData.class ? windowData.class : "").toLowerCase();
        const winTitle = (windowData && windowData.title ? windowData.title : "").toLowerCase();
        return winClass.includes(query) || winTitle.includes(query);
    }

    readonly property bool compactMode: Math.min(targetWindowWidth, targetWindowHeight) < 120
    readonly property bool previewActive: visible && opacity > 0 && !!toplevel
    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    opacity: !windowData ? 0 : (!matchesSearch ? 0.12 : (widgetMonitor && windowData.monitor === widgetMonitor.id ? 1 : 0.46))

    Behavior on x {
        enabled: !root.draggingActive

        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !root.draggingActive

        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        color: "transparent"
        contentUnderBorder: true
        antialiasing: true
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        border.width: 1
        border.color: root.hovered ? "#77ffffff" : "#33ffffff"

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.previewActive ? root.toplevel : null
            constraintSize: Qt.size(Math.max(1, Math.round(root.width)), Math.max(1, Math.round(root.height)))
            live: root.previewActive
        }

        Rectangle {
            anchors.fill: parent
            color: root.pressed
                ? "#40000000"
                : (root.hovered ? "#18000000" : "#08000000")
        }

        Image {
            id: appIcon

            readonly property real iconSize: Math.max(18, Math.min(root.width, root.height) * (root.compactMode ? 0.52 : 0.32))

            anchors.centerIn: parent
            visible: root.compactMode
            source: root.iconPath
            width: iconSize
            height: iconSize
            sourceSize: Qt.size(width, height)
            mipmap: true
            smooth: true
            opacity: 0.96

            onStatusChanged: {
                if (status === Image.Error) {
                    source = "";
                }
            }
        }

        // App Icon Badge in the bottom-right corner
        Rectangle {
            id: iconBadge
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8 * Appearance.effectiveScale
            
            width: 32 * Appearance.effectiveScale
            height: 32 * Appearance.effectiveScale
            radius: width / 2
            
            color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.9)
            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.4)
            border.width: 1

            visible: root.iconPath !== "" && !root.compactMode

            Image {
                anchors.centerIn: parent
                width: 20 * Appearance.effectiveScale
                height: 20 * Appearance.effectiveScale
                source: root.iconPath
                sourceSize: Qt.size(width, height)
                mipmap: true
                smooth: true
            }
        }
    }

    StyledToolTip {
        id: windowTooltip
        text: "<center>" + (windowData && windowData.title ? windowData.title : "Window") + "<br>[" + (windowData && windowData.class ? windowData.class : "") + "]</center>"
        
        // Custom positioning: top-center of the window preview
        x: (parent.width - width) / 2
        y: -height - 8 * Appearance.effectiveScale
    }
}
