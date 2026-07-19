import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Controls 6.10
import "../../theme"
import "../../services"
import "../../components"
import "../../core"
// Status Indicators - Caffeine, DND, and Recording dots in the bar
Item {
    id: root
    
    readonly property var matugen: Theme
    readonly property var caffeineService: CaffeineService
    readonly property var notifs: Notifs
    readonly property var screenshot: Screenshot
    readonly property var updatesService: SystemUpdateService
    
    readonly property bool caffeineActive: caffeineService.inhibited
    readonly property bool recordingActive: screenshot.isRecording
    readonly property bool micMuted: Audio.sourceMuted
    readonly property bool updatesActive: updatesService.updateCount > 0
    readonly property bool devicesActive: UsbMonitorService.devicesList.length > 0
    readonly property bool hasActiveIndicators: caffeineActive || recordingActive || micMuted || updatesActive || devicesActive
    
    implicitWidth: hasActiveIndicators ? indicatorRow.implicitWidth : 0
    implicitHeight: 28 * Appearance.effectiveScale
    
    visible: hasActiveIndicators
    opacity: hasActiveIndicators ? 1 : 0
    
    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
    
    Row {
        id: indicatorRow
        anchors.centerIn: parent
        spacing: 6 * Appearance.effectiveScale
        
        // Caffeine indicator (coffee icon)
        Rectangle {
            id: caffeineIndicator
            width: caffeineActive ? 22 * Appearance.effectiveScale : 0
            height: 22 * Appearance.effectiveScale
            radius: 11 * Appearance.effectiveScale
            color: Qt.rgba(matugen.primary.r, matugen.primary.g, matugen.primary.b, 0.2)
            visible: caffeineActive || width > 0
            
            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            DankIcon {
                anchors.centerIn: parent
                name: "coffee"
                size: 12 * Appearance.effectiveScale
                color: matugen.primary
            }
            
            // Subtle pulse animation when active
            SequentialAnimation on opacity {
                running: caffeineActive
                loops: Animation.Infinite
                NumberAnimation { to: 0.7; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: caffeineService.setInhibited(false)
            }
        }
        
        // Microphone Muted indicator
        Rectangle {
            id: micMutedIndicator
            width: micMuted ? 22 * Appearance.effectiveScale : 0
            height: 22 * Appearance.effectiveScale
            radius: 11 * Appearance.effectiveScale
            color: Qt.rgba(matugen.primary.r, matugen.primary.g, matugen.primary.b, 0.2)
            visible: micMuted || width > 0
            
            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }
            
            DankIcon {
                anchors.centerIn: parent
                name: "mic_off"
                size: 12 * Appearance.effectiveScale
                color: matugen.primary
            }
            
            // Subtle pulse animation when active
            SequentialAnimation on opacity {
                running: micMuted
                loops: Animation.Infinite
                NumberAnimation { to: 0.7; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: Audio.setSourceMute(false)
            }
        }
        
        
        
        // Recording indicator (red dot with timer)
        Rectangle {
            id: recIndicator
            width: recordingActive ? recRow.implicitWidth + 16 * Appearance.effectiveScale : 0
            height: 22 * Appearance.effectiveScale
            radius: 11 * Appearance.effectiveScale
            color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
            visible: recordingActive

            property int elapsedSeconds: 0

            Timer {
                interval: 1000
                running: root.recordingActive
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    if (root.screenshot.recordingStartedAt > 0) {
                        parent.elapsedSeconds = Math.floor((new Date().getTime() - root.screenshot.recordingStartedAt) / 1000)
                    }
                }
            }

            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }

            Row {
                id: recRow
                anchors.centerIn: parent
                spacing: 4 * Appearance.effectiveScale
                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "videocam"
                    size: 12 * Appearance.effectiveScale
                    color: Theme.error
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const m = Math.floor(parent.parent.elapsedSeconds / 60)
                        const s = parent.parent.elapsedSeconds % 60
                        return m + ":" + (s < 10 ? "0" : "") + s
                    }
                    font.family: "Inter"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: Theme.error
                }
            }

            // Pulse animation when recording
            SequentialAnimation on opacity {
                running: recordingActive
                loops: Animation.Infinite
                NumberAnimation { to: 0.5; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: root.screenshot.stopRecording()
            }
        }

        // System updates indicator
        Rectangle {
            id: updatesIndicator
            width: updatesActive ? updatesRow.implicitWidth + 14 * Appearance.effectiveScale : 0
            height: 22 * Appearance.effectiveScale
            radius: 11 * Appearance.effectiveScale
            color: Qt.rgba(matugen.primary.r, matugen.primary.g, matugen.primary.b, 0.2)
            visible: updatesActive
            clip: true

            Behavior on width {
                NumberAnimation { duration: 200; easing.bezierCurve: [0.34, 1.56, 0.64, 1] }
            }

            Row {
                id: updatesRow
                anchors.centerIn: parent
                spacing: 4 * Appearance.effectiveScale
                
                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "system_update_alt"
                    size: 12 * Appearance.effectiveScale
                    color: matugen.primary
                }
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: updatesService.updateCount
                    font.family: "Inter"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: matugen.primary
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: updatesService.triggerUpdate()
            }
        }

        // Connected Devices Tray indicator
        DeviceTray {
            id: deviceTrayIndicator
            visible: root.devicesActive
        }
    }
}
