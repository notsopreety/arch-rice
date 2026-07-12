import QtQuick
import "../theme"

Item {
    id: slider

    property int value: 50
    property int minimum: 0
    property int maximum: 100
    property int step: 1
    property string leftIcon: ""
    property string rightIcon: ""
    property string unit: "%"
    property bool showValue: true
    property bool isDragging: false
    property bool wheelEnabled: true
    property bool centerMinimum: false
    property real valueOverride: -1
    property bool alwaysShowValue: false
    readonly property bool containsMouse: sliderMouseArea.containsMouse

    property color thumbOutlineColor: Theme.surfaceContainer
    property color trackColor: enabled ? Theme.outline : Theme.outline
    property real trackOpacity: 0.2

    signal sliderValueChanged(int newValue)
    signal sliderDragFinished(int finalValue)

    height: 48

    function updateValueFromPosition(x) {
        let ratio = Math.max(0, Math.min(1, (x - sliderHandle.width / 2) / (sliderTrack.width - sliderHandle.width)));
        if (centerMinimum)
            ratio = Math.max(0, (ratio - 0.5) * 2);
        let rawValue = minimum + ratio * (maximum - minimum);
        let newValue = step > 1 ? Math.round(rawValue / step) * step : Math.round(rawValue);
        newValue = Math.max(minimum, Math.min(maximum, newValue));
        if (newValue !== value) {
            value = newValue;
            sliderValueChanged(newValue);
        }
    }

    Row {
        anchors.centerIn: parent
        width: parent.width
        spacing: 16

        DankIcon {
            name: slider.leftIcon
            size: 24
            color: slider.enabled ? Theme.onSurface : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.38)
            anchors.verticalCenter: parent.verticalCenter
            visible: slider.leftIcon.length > 0
        }

        Rectangle {
            id: sliderTrack

            property int leftIconWidth: slider.leftIcon.length > 0 ? 24 : 0
            property int rightIconWidth: slider.rightIcon.length > 0 ? 24 : 0

            width: parent.width - (leftIconWidth + rightIconWidth + (slider.leftIcon.length > 0 ? 16 : 0) + (slider.rightIcon.length > 0 ? 16 : 0))
            height: 12
            radius: 6
            color: Qt.rgba(slider.trackColor.r, slider.trackColor.g, slider.trackColor.b, slider.trackOpacity)
            anchors.verticalCenter: parent.verticalCenter
            clip: false

            Rectangle {
                id: sliderFill
                height: parent.height
                radius: 6
                topRightRadius: 0
                bottomRightRadius: 0
                width: {
                    const range = slider.maximum - slider.minimum;
                    const rawRatio = range === 0 ? 0 : (slider.value - slider.minimum) / range;
                    const ratio = slider.centerMinimum ? (0.5 + rawRatio * 0.5) : rawRatio;
                    const travel = sliderTrack.width - sliderHandle.width;
                    const handleLeft = travel * ratio;
                    const endPoint = handleLeft - 3;
                    return Math.max(0, Math.min(sliderTrack.width, endPoint));
                }
                color: slider.enabled ? Theme.primary : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.12)
            }

            Rectangle {
                id: sliderHandle

                property bool active: sliderMouseArea.containsMouse || sliderMouseArea.pressed || slider.isDragging

                width: 4
                height: 20
                radius: 2
                x: {
                    const range = slider.maximum - slider.minimum;
                    const rawRatio = range === 0 ? 0 : (slider.value - slider.minimum) / range;
                    const ratio = slider.centerMinimum ? (0.5 + rawRatio * 0.5) : rawRatio;
                    const travel = sliderTrack.width - width;
                    return Math.max(0, Math.min(travel, travel * ratio));
                }
                anchors.verticalCenter: parent.verticalCenter
                color: slider.enabled ? Theme.primary : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.12)
                border.width: 0

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Theme.onPrimary
                    opacity: slider.enabled ? (sliderMouseArea.pressed ? 0.16 : (sliderMouseArea.containsMouse ? 0.08 : 0)) : 0
                    visible: opacity > 0
                }

                Rectangle {
                    id: ripple
                    anchors.centerIn: parent
                    width: 0
                    height: 0
                    radius: width / 2
                    color: Theme.onPrimary
                    opacity: 0

                    function start() {
                        opacity = 0.16;
                        width = 0;
                        height = 0;
                        rippleAnimation.start();
                    }

                    SequentialAnimation {
                        id: rippleAnimation
                        NumberAnimation {
                            target: ripple
                            properties: "width,height"
                            to: 28
                            duration: 180
                        }
                        NumberAnimation {
                            target: ripple
                            property: "opacity"
                            to: 0
                            duration: 150
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onPressedChanged: {
                        if (pressed && slider.enabled) {
                            ripple.start();
                        }
                    }
                }

                scale: active ? 1.05 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }

            Item {
                id: sliderContainer

                anchors.fill: parent

                MouseArea {
                    id: sliderMouseArea

                    property bool isDragging: false

                    anchors.fill: parent
                    anchors.topMargin: -10
                    anchors.bottomMargin: -10
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: slider.enabled
                    preventStealing: true
                    acceptedButtons: Qt.LeftButton
                    onWheel: wheelEvent => {
                        if (!slider.wheelEnabled) {
                            wheelEvent.accepted = false;
                            return;
                        }
                        let wheelStep = slider.step > 1 ? slider.step : Math.max(1, (maximum - minimum) / 100);
                        let newValue = wheelEvent.angleDelta.y > 0 ? Math.min(maximum, value + wheelStep) : Math.max(minimum, value - wheelStep);
                        if (slider.step > 1)
                            newValue = Math.round(newValue / slider.step) * slider.step;
                        newValue = Math.round(newValue);
                        if (newValue !== value) {
                            value = newValue;
                            sliderValueChanged(newValue);
                        }
                        wheelEvent.accepted = true;
                    }
                    onPressed: mouse => {
                        if (slider.enabled) {
                            slider.isDragging = true;
                            sliderMouseArea.isDragging = true;
                            updateValueFromPosition(mouse.x);
                        }
                    }
                    onReleased: {
                        if (slider.enabled) {
                            slider.isDragging = false;
                            sliderMouseArea.isDragging = false;
                            slider.sliderDragFinished(slider.value);
                        }
                    }
                    onPositionChanged: mouse => {
                        if (pressed && slider.isDragging && slider.enabled) {
                            updateValueFromPosition(mouse.x);
                        }
                    }
                    onClicked: mouse => {
                        if (slider.enabled && !slider.isDragging) {
                            updateValueFromPosition(mouse.x);
                        }
                    }
                }
            }

            Rectangle {
                id: valueTooltip

                width: tooltipText.contentWidth + 16
                height: tooltipText.contentHeight + 8
                radius: 8
                color: Theme.surfaceContainer
                border.color: Theme.outline
                border.width: 1
                anchors.bottom: parent.top
                anchors.bottomMargin: 4
                x: Math.max(0, Math.min(parent.width - width, sliderHandle.x + sliderHandle.width / 2 - width / 2))
                visible: slider.alwaysShowValue ? slider.showValue : ((sliderMouseArea.containsMouse && slider.showValue) || (slider.isDragging && slider.showValue))
                opacity: visible ? 1 : 0

                Text {
                    id: tooltipText
                    text: (slider.valueOverride >= 0 ? Math.round(slider.valueOverride) : slider.value) + slider.unit
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: Theme.primary
                    font.weight: Font.Medium
                    anchors.centerIn: parent
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }
        }

        DankIcon {
            name: slider.rightIcon
            size: 24
            color: slider.enabled ? Theme.onSurface : Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.38)
            anchors.verticalCenter: parent.verticalCenter
            visible: slider.rightIcon.length > 0
        }
    }
}
