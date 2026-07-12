pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Instantiate FileView as a property to load and watch colors.json
    property FileView fileReader: FileView {
        id: fileReader
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        preload: true
        watchChanges: true
        blockLoading: true

        onFileChanged: fileReader.reload()
        onLoaded: root.updateColors()
        Component.onCompleted: root.updateColors()
    }

    property var jsonData: ({})

    function updateColors() {
        try {
            var rawText = fileReader.text();
            if (rawText) {
                jsonData = JSON.parse(rawText);
            }
        } catch(e) {
            console.error("Failed to parse colors.json:", e);
        }
    }

    onJsonDataChanged: {
        // Colors updated successfully
    }

    // Direct access helper properties (using camelCase for QML access)
    // Using direct ternary expressions ensures 100% reactive bindings in QML
    readonly property color primary: jsonData && jsonData.primary !== undefined ? jsonData.primary : "#ffb2ba"
    readonly property color onPrimary: onPrimaryColor
    readonly property color onPrimaryColor: jsonData && jsonData.on_primary !== undefined ? jsonData.on_primary : "#561d27"
    readonly property color primaryContainer: jsonData && jsonData.primary_container !== undefined ? jsonData.primary_container : "#72333c"
    readonly property color onPrimaryContainer: onPrimaryContainerColor
    readonly property color onPrimaryContainerColor: jsonData && jsonData.on_primary_container !== undefined ? jsonData.on_primary_container : "#ffd9dc"
    
    readonly property color secondary: jsonData && jsonData.secondary !== undefined ? jsonData.secondary : "#e5bdc0"
    readonly property color onSecondary: onSecondaryColor
    readonly property color onSecondaryColor: jsonData && jsonData.on_secondary !== undefined ? jsonData.on_secondary : "#43292c"
    readonly property color secondaryContainer: jsonData && jsonData.secondary_container !== undefined ? jsonData.secondary_container : "#5c3f42"
    readonly property color onSecondaryContainer: onSecondaryContainerColor
    readonly property color onSecondaryContainerColor: jsonData && jsonData.on_secondary_container !== undefined ? jsonData.on_secondary_container : "#ffd9dc"

    readonly property color tertiary: jsonData && jsonData.tertiary !== undefined ? jsonData.tertiary : "#e9bf8f"
    readonly property color onTertiary: onTertiaryColor
    readonly property color onTertiaryColor: jsonData && jsonData.on_tertiary !== undefined ? jsonData.on_tertiary : "#442b07"
    readonly property color tertiaryContainer: jsonData && jsonData.tertiary_container !== undefined ? jsonData.tertiary_container : "#5e411b"
    readonly property color onTertiaryContainer: onTertiaryContainerColor
    readonly property color onTertiaryContainerColor: jsonData && jsonData.on_tertiary_container !== undefined ? jsonData.on_tertiary_container : "#ffddb7"

    readonly property color error: jsonData && jsonData.error !== undefined ? jsonData.error : "#ffb4ab"
    readonly property color onErrorColor: jsonData && jsonData.on_error !== undefined ? jsonData.on_error : "#690005" // Avoid conflict with FileView's error signal
    readonly property color errorContainer: jsonData && jsonData.error_container !== undefined ? jsonData.error_container : "#93000a"
    readonly property color onErrorContainer: onErrorContainerColor
    readonly property color onErrorContainerColor: jsonData && jsonData.on_error_container !== undefined ? jsonData.on_error_container : "#ffdad6"

    readonly property color background: jsonData && jsonData.background !== undefined ? jsonData.background : "#1a1112"
    readonly property color onBackground: onBackgroundColor
    readonly property color onBackgroundColor: jsonData && jsonData.on_background !== undefined ? jsonData.on_background : "#f0dedf"

    readonly property color surface: jsonData && jsonData.surface !== undefined ? jsonData.surface : "#1a1112"
    readonly property color onSurface: onSurfaceColor
    readonly property color onSurfaceColor: jsonData && jsonData.on_surface !== undefined ? jsonData.on_surface : "#f0dedf"
    readonly property color surfaceVariant: jsonData && jsonData.surface_variant !== undefined ? jsonData.surface_variant : "#524344"
    readonly property color onSurfaceVariant: onSurfaceVariantColor
    readonly property color onSurfaceVariantColor: jsonData && jsonData.on_surface_variant !== undefined ? jsonData.on_surface_variant : "#d7c1c3"
    
    readonly property color surfaceContainer: jsonData && jsonData.surface_container !== undefined ? jsonData.surface_container : "#261d1e"
    readonly property color surfaceContainerLow: jsonData && jsonData.surface_container_low !== undefined ? jsonData.surface_container_low : "#22191a"
    readonly property color surfaceContainerHigh: jsonData && jsonData.surface_container_high !== undefined ? jsonData.surface_container_high : "#312828"
    readonly property color surfaceBright: jsonData && jsonData.surface_bright !== undefined ? jsonData.surface_bright : "#413737"
    readonly property color surfaceDim: jsonData && jsonData.surface_dim !== undefined ? jsonData.surface_dim : "#1a1112"

    readonly property color outline: jsonData && jsonData.outline !== undefined ? jsonData.outline : "#9f8c8d"
    readonly property color outlineVariant: jsonData && jsonData.outline_variant !== undefined ? jsonData.outline_variant : "#524344"

    readonly property string wallpaperPath: jsonData && jsonData.image !== undefined ? jsonData.image : ""

    // Typography
    readonly property var font: QtObject {
        property string family: "Noto Sans"
        property string monospace: "JetBrainsMono Nerd Font"
        property int sizeSmall: 11
        property int sizeNormal: 14
        property int sizeLarge: 18
        property int sizeTitle: 24
        property int sizeClock: 48
    }

    // Animations (Material You 3 Spec)
    readonly property var anim: QtObject {
        property int durationShort: 150
        property int durationNormal: 250
        property int durationLong: 400
        property int type: Easing.BezierSpline
        property list<real> curve: [0.2, 0, 0, 1] // Emphasized decelerate
    }

    // Rounding
    readonly property var rounding: QtObject {
        property int small: 8
        property int normal: 16
        property int large: 24
        property int extraLarge: 32
        property int full: 9999
    }

    readonly property color foreground: onSurface
    readonly property color info: primary
}
