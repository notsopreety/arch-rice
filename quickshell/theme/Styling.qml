pragma Singleton
import QtQuick

QtObject {
    // Spacing and Padding
    readonly property int paddingSmall: 6
    readonly property int paddingNormal: 12
    readonly property int paddingLarge: 18

    readonly property int spacingSmall: 8
    readonly property int spacingNormal: 14
    readonly property int spacingLarge: 20

    // Component Dimensions
    readonly property int barHeight: 44
    readonly property int barWidth: 320
    readonly property int widgetCardWidth: 280
    
    // Shadows
    readonly property var shadow: QtObject {
        property color color: "#50000000"
        property int radius: 8
        property int offsetX: 0
        property int offsetY: 4
    }
}
