import "../core"
import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

Slider {
    id: root

    orientation: Qt.Vertical

    property real defaultValue: -1
    property var stopIndicatorValues: defaultValue >= 0 ? [defaultValue] : []
    enum Configuration {
        Wavy = 4,
        X0 = 3,
        XS = 12,
        S = 18,
        M = 30,
        L = 42,
        XL = 72
    }

    property var configuration: VerticalStyledSlider.Configuration.S

    property real handleDefaultHeight: 3 * Appearance.effectiveScale
    property real handlePressedHeight: 1.5 * Appearance.effectiveScale
    property color highlightColor: Appearance.m3colors.m3primary
    property color trackColor: Appearance.m3colors.m3secondaryContainer
    property color handleColor: Appearance.m3colors.m3primary
    property color dotColor: Appearance.m3colors.m3onSecondaryContainer
    property color dotColorHighlighted: Appearance.m3colors.m3onPrimary
    property real unsharpenRadius: Appearance.rounding.verysmall
    
    property real trackWidth: configuration * Appearance.effectiveScale
    property real trackRadius: trackWidth >= VerticalStyledSlider.Configuration.XL * Appearance.effectiveScale ? 24 * Appearance.effectiveScale
        : trackWidth >= VerticalStyledSlider.Configuration.L * Appearance.effectiveScale ? 16 * Appearance.effectiveScale
        : trackWidth >= VerticalStyledSlider.Configuration.M * Appearance.effectiveScale ? 12 * Appearance.effectiveScale
        : trackWidth >= VerticalStyledSlider.Configuration.S * Appearance.effectiveScale ? 8 * Appearance.effectiveScale
        : width / 2
    property real handleWidth: (configuration === VerticalStyledSlider.Configuration.X0) ? 14 * Appearance.effectiveScale : Math.max(33 * Appearance.effectiveScale, trackWidth + (9 * Appearance.effectiveScale))
    property real handleHeight: root.pressed ? handlePressedHeight : handleDefaultHeight
    property real handleMargins: 4 * Appearance.effectiveScale
    property real trackDotSize: 3 * Appearance.effectiveScale
    property bool usePercentTooltip: true
    property string tooltipContent: usePercentTooltip ? `${Math.round(((value - from) / (to - from)) * 100)}%` : `${Math.round(value)}`
    property bool wavy: false
    property bool animateValue: true

    topPadding: handleMargins
    bottomPadding: handleMargins
    implicitHeight: 100 * Appearance.effectiveScale
    implicitWidth: trackWidth
    property real effectiveDraggingHeight: height - topPadding - bottomPadding

    Layout.fillHeight: true
    from: 0
    to: 1

    Behavior on value {
        enabled: root.animateValue && !root.pressed
        SmoothedAnimation {
            velocity: Appearance.animation.elementMoveFast.velocity
        }
    }

    Behavior on handleMargins {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = false
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor 
    }

    background: Item {
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        implicitWidth: trackWidth
        
        // Fill bottom
        Loader {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
            }
            width: root.trackWidth
            height: root.handleMargins + ((1 - root.visualPosition) * root.effectiveDraggingHeight) - (root.handleHeight / 2 + root.handleMargins)
            active: !root.wavy
            sourceComponent: Rectangle {
                color: root.highlightColor
                bottomLeftRadius: root.trackRadius
                bottomRightRadius: root.trackRadius
                topLeftRadius: 0
                topRightRadius: 0
            }
        }

        // Fill top
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
            }
            width: root.trackWidth
            height: root.handleMargins + (root.visualPosition * root.effectiveDraggingHeight) - (root.handleHeight / 2 + root.handleMargins)
            color: root.trackColor
            topLeftRadius: root.trackRadius
            topRightRadius: root.trackRadius
            bottomLeftRadius: 0
            bottomRightRadius: 0
        }
    }

    handle: Rectangle {
        id: handle

        implicitWidth: root.handleWidth
        implicitHeight: root.handleHeight
        y: root.topPadding + (root.visualPosition * root.effectiveDraggingHeight) - (root.handleHeight / 2)
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Appearance.rounding.full
        color: root.handleColor

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledToolTip {
            extraVisibleCondition: root.pressed
            text: root.tooltipContent
            font {
                family: Appearance.font.family.numbers
                variableAxes: Appearance.font.variableAxes.numbers
            }
        }
    }
}
