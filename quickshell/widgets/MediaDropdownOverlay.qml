import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"
import "../services"

Item {
    id: root
    anchors.fill: parent
    z: 9999

    property int dropdownType: 0
    property var activePlayer: null
    property point anchorPos: Qt.point(0, 0)
    property bool isRightEdge: false
    property int systemVolume: 0

    property real currentVolume: systemVolume / 100
    property bool volumeAvailable: true

    signal closeRequested
    signal panelEntered
    signal panelExited
    signal volumeChanged(real volume)

    property int __panelHoverCount: 0

    onDropdownTypeChanged: {
        if (dropdownType === 0) {
            __panelHoverCount = 0;
        }
    }

    function panelAreaEntered() {
        __panelHoverCount++;
        panelEntered();
    }

    function panelAreaExited() {
        __panelHoverCount = Math.max(0, __panelHoverCount - 1);
        if (__panelHoverCount === 0)
            panelExited();
    }

    function getVolumeIcon(muted, volume) {
        if (muted || volume === 0)
            return "󰝟";
        if (volume < 0.3)
            return "󰕿";
        if (volume < 0.7)
            return "󰖀";
        return "󰕾";
    }

    // Dismiss overlay on background click
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: dropdownType !== 0
        onClicked: closeRequested()
    }

    // ==========================================
    // 1. VOLUME PANEL (Vertical Hover Slider next to dash)
    // ==========================================
    Rectangle {
        id: volumePanel
        visible: dropdownType === 1 && volumeAvailable
        width: 60
        height: 180
        x: isRightEdge ? anchorPos.x + 12 : anchorPos.x - width - 12
        y: anchorPos.y - height / 2
        radius: Theme.rounding.normal
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: panelAreaEntered()
            onExited: panelAreaExited()
        }

        Item {
            anchors.fill: parent
            anchors.margins: 8

            Item {
                id: volumeSlider
                width: parent.width * 0.5
                height: parent.height - 36
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter

                // Track Background
                Rectangle {
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                    radius: Theme.rounding.small
                }

                // Filled volume part
                Rectangle {
                    readonly property real ratio: volumeAvailable ? Math.min(1.0, currentVolume) : 0
                    readonly property real thumbHeight: 4
                    width: parent.width
                    height: Math.max(0, ratio * (parent.height - thumbHeight) - 3)
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.primary
                    radius: Theme.rounding.small
                    topLeftRadius: 0
                    topRightRadius: 0
                }

                // Thumb Indicator
                Rectangle {
                    width: parent.width + 8
                    height: 4
                    radius: 2
                    y: {
                        const ratio = volumeAvailable ? Math.min(1.0, currentVolume) : 0;
                        const travel = parent.height - height;
                        return Math.max(0, Math.min(travel, travel * (1 - ratio)));
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.primary
                    border.width: 0
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
                    enabled: volumeAvailable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onEntered: panelAreaEntered()
                    onExited: panelAreaExited()
                    onPressed: mouse => updateVolume(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) updateVolume(mouse)
                    }
                    onClicked: mouse => updateVolume(mouse)

                    function updateVolume(mouse) {
                        if (!volumeAvailable) return;
                        var pct = 1.0 - (mouse.y / height);
                        var targetVol = Math.max(0.0, Math.min(1.0, pct));
                        root.volumeChanged(targetVol);
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 4
                text: volumeAvailable ? Math.round(currentVolume * 100) + "%" : "0%"
                font.family: Theme.font.family
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "white"
            }
        }
    }

}
