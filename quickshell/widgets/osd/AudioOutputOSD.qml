import QtQuick
import "../../theme"
import "../../services"
import "../../components"

DankOSD {
    id: root

    property string deviceName: ""
    property string deviceIcon: "speaker"

    osdWidth: Math.min(260, Math.max(140, 48 + textMetrics.width))
    osdHeight: 48
    autoHideInterval: 2500
    enableMouseInteraction: false

    TextMetrics {
        id: textMetrics
        font.pixelSize: Theme.font.sizeNormal
        font.weight: Font.Medium
        font.family: Theme.font.family
        text: root.deviceName
    }

    Connections {
        target: OsdService
        function onAudioOutputTriggered(name, icon) {
            if (OsdService.osdAudioOutputEnabled) {
                root.deviceName = name;
                root.deviceIcon = icon;
                root.show();
            }
        }
    }

    content: Item {
        property int gap: Theme.rounding.small

        anchors.centerIn: parent
        width: parent.width - Theme.rounding.small * 2
        height: parent.height

        DankIcon {
            id: iconItem
            width: 24
            height: 24
            x: parent.gap
            anchors.verticalCenter: parent.verticalCenter
            name: root.deviceIcon
            size: 20
            color: Theme.primary
        }

        StyledText {
            id: textItem
            x: parent.gap * 2 + 24
            width: parent.width - 24 - parent.gap * 3
            anchors.verticalCenter: parent.verticalCenter
            text: root.deviceName
            font.pixelSize: Theme.font.sizeNormal
            font.weight: Font.Medium
            color: Theme.onSurface
            elide: Text.ElideRight
        }
    }
}
