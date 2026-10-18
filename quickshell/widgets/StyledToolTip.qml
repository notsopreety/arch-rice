import "../core"
import "../theme"
import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false

    readonly property bool parentHovered: {
        if (!parent) return false;
        if (parent.hovered !== undefined) return Boolean(parent.hovered);
        if (parent.realHovered !== undefined) return Boolean(parent.realHovered);
        if (parent.containsMouse !== undefined) return Boolean(parent.containsMouse);
        return false;
    }

    readonly property bool internalVisibleCondition: alternativeVisibleCondition || (extraVisibleCondition && parentHovered)
    
    // Minimal padding to match ToggleDelegate
    padding: 0
    verticalPadding: 0
    horizontalPadding: 0
    
    background: Rectangle {
        color: Theme.surfaceContainerHigh
        radius: 8 * Appearance.effectiveScale
        border.color: Theme.outlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
    }
    
    font {
        family: Appearance.font.family.main
        variableAxes: Appearance.font.variableAxes.main
        pixelSize: Appearance.font.pixelSize.smaller
        hintingPreference: Font.PreferNoHinting
    }

    delay: 300
    visible: internalVisibleCondition
    
    contentItem: StyledToolTipContent {
        id: contentItem
        text: root.text
        shown: root.internalVisibleCondition
    }
}
