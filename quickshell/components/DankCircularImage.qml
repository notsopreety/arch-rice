import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Effects
import "../theme"

Rectangle {
    id: root

    property string imageSource: ""
    property string fallbackIcon: "music_note"
    property string fallbackText: ""
    property bool hasImage: imageSource !== ""
    readonly property bool shouldProbe: imageSource !== "" && !imageSource.startsWith("image://")
    readonly property bool isAnimated: shouldProbe && probe.status === Image.Ready && probe.frameCount > 1
    readonly property var activeImage: isAnimated ? probe : staticImage
    property int imageStatus: activeImage.status

    radius: width / 2
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
    border.color: "transparent"
    border.width: 0

    AnimatedImage {
        id: probe
        anchors.fill: parent
        anchors.margins: 2
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        cache: true
        visible: false
        source: root.shouldProbe ? root.imageSource : ""
    }

    Image {
        id: staticImage
        anchors.fill: parent
        anchors.margins: 2
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        cache: true
        visible: false
        sourceSize.width: Math.max(width * 2, 128)
        sourceSize.height: Math.max(height * 2, 128)
        source: !root.shouldProbe ? root.imageSource : ""
    }

    Connections {
        target: probe
        function onStatusChanged() {
            if (!root.shouldProbe)
                return;
            switch (probe.status) {
            case Image.Ready:
                if (probe.frameCount <= 1) {
                    staticImage.source = root.imageSource;
                    probe.source = "";
                }
                break;
            case Image.Error:
                staticImage.source = root.imageSource;
                probe.source = "";
                break;
            }
        }
    }

    onImageSourceChanged: {
        if (root.shouldProbe) {
            staticImage.source = "";
            probe.source = root.imageSource;
        } else {
            probe.source = "";
            staticImage.source = root.imageSource;
        }
    }

    MultiEffect {
        anchors.fill: parent
        anchors.margins: 2
        source: root.activeImage
        maskEnabled: true
        maskSource: circularMask
        visible: root.activeImage.status === Image.Ready && root.imageSource !== ""
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Item {
        id: circularMask
        anchors.centerIn: parent
        width: parent.width - 4
        height: parent.height - 4
        layer.enabled: true
        layer.smooth: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black"
            antialiasing: true
        }
    }

    Label {
        anchors.centerIn: parent
        visible: (root.activeImage.status !== Image.Ready || root.imageSource === "")
        text: "󰎇"
        font.family: Theme.font.monospace
        font.pointSize: parent.width > 0 ? Math.max(1, Math.round(parent.width * 0.3)) : 12
        color: Theme.onSurfaceVariantColor
    }
}
