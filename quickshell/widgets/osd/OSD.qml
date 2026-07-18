import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"

/**
 * Centralized OSD (On-Screen Display) Manager
 * Positioned bottom-center of the active screen.
 */
Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")) || Quickshell.screens[0]

    property string currentIndicator: "volume"
    property bool ready: false
    property bool showOsd: false

    Timer {
        interval: 2500
        running: true
        repeat: false
        onTriggered: root.ready = true
    }

    property var indicators: [
        { id: "volume",         sourceUrl: "indicators/VolumeIndicator.qml" },
        { id: "brightness",     sourceUrl: "indicators/BrightnessIndicator.qml" },
        { id: "microphone",     sourceUrl: "indicators/MicVolumeIndicator.qml" },
        { id: "charging",       sourceUrl: "indicators/ChargingIndicator.qml" },
        { id: "conservation",   sourceUrl: "indicators/ConservationIndicator.qml" },
        { id: "airplaneMode",   sourceUrl: "indicators/AirplaneModeIndicator.qml" },
        { id: "capsLock",       sourceUrl: "indicators/CapsLockIndicator.qml" },
        { id: "idleInhibitor",  sourceUrl: "indicators/IdleInhibitorIndicator.qml" },
        { id: "powerProfile",   sourceUrl: "indicators/PowerProfileIndicator.qml" },
        { id: "dnd",            sourceUrl: "indicators/DndIndicator.qml" },
        { id: "kbdBrightness",  sourceUrl: "indicators/KbdBrightnessIndicator.qml" },
        { id: "nightLight",     sourceUrl: "indicators/NightLightIndicator.qml" },
        { id: "wifi",           sourceUrl: "indicators/WifiIndicator.qml" },
        { id: "bluetooth",      sourceUrl: "indicators/BluetoothIndicator.qml" }
    ]

    function triggerOsd() {
        if (!root.ready) return;
        osdLoader.active = true;
        root.showOsd = true;

        if (root.currentIndicator === "charging") {
            osdTimeout.interval = Battery.isPluggedIn ? 5000 : 3000;
        } else {
            osdTimeout.interval = 2000;
        }

        osdTimeout.restart();
    }

    Timer {
        id: osdTimeout
        interval: 2000
        repeat: false
        running: false
        onTriggered: {
            root.showOsd = false;
            root.protectionMessage = "";
        }
    }

    // ── Signal Connections ──
    Connections {
        target: Brightness
        function onBrightnessUpdated() {
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
        function onMutedChanged() {
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
        function onSourceVolumeChanged() {
            root.currentIndicator = "microphone";
            root.triggerOsd();
        }
        function onSourceMutedChanged() {
            root.currentIndicator = "microphone";
            root.triggerOsd();
        }
    }

    Connections {
        target: Battery
        function onIsPluggedInChanged() {
            root.currentIndicator = "charging";
            root.triggerOsd();
        }
    }

    Connections {
        target: ConservationMode
        enabled: ConservationMode.available
        function onActiveChanged() {
            root.currentIndicator = "conservation";
            root.triggerOsd();
        }
    }

    Connections {
        target: OsdService
        function onAirplaneModeTriggered(active) {
            root.currentIndicator = "airplaneMode";
            root.triggerOsd();
        }
        function onCapsLockTriggered() {
            if (OsdService.osdCapsLockEnabled) {
                root.currentIndicator = "capsLock";
                root.triggerOsd();
            }
        }
        function onIdleInhibitorTriggered(active) {
            if (OsdService.osdIdleInhibitorEnabled) {
                root.currentIndicator = "idleInhibitor";
                root.triggerOsd();
            }
        }
        function onPowerProfileTriggered(profile) {
            if (OsdService.osdPowerProfileEnabled) {
                root.currentIndicator = "powerProfile";
                root.triggerOsd();
            }
        }
        function onDndTriggered(active) {
            root.currentIndicator = "dnd";
            root.triggerOsd();
        }
        function onKbdBrightnessTriggered() {
            root.currentIndicator = "kbdBrightness";
            root.triggerOsd();
        }
        function onNightLightTriggered(active) {
            root.currentIndicator = "nightLight";
            root.triggerOsd();
        }
        function onWifiTriggered(connected, ssid) {
            root.currentIndicator = "wifi";
            root.triggerOsd();
        }
        function onBluetoothTriggered(connected, deviceName) {
            root.currentIndicator = "bluetooth";
            root.triggerOsd();
        }
    }

    // ── OSD Visual Layer ──
    Loader {
        id: osdLoader
        active: false

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            anchors {
                bottom: true
            }
            
            margins {
                bottom: 80 * Appearance.effectiveScale
            }

            screen: root.focusedScreen
            Connections {
                target: root
                function onFocusedScreenChanged() { osdRoot.screen = root.focusedScreen; }
            }

            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: -1

            implicitWidth: osdIndicatorLoader.implicitWidth + (40 * Appearance.effectiveScale)
            implicitHeight: osdIndicatorLoader.implicitHeight + (20 * Appearance.effectiveScale)
            visible: osdLoader.active

            Connections {
                target: root
                function onShowOsdChanged() {
                    if (root.showOsd) {
                        contentInAnim.start();
                    } else {
                        contentOutAnim.start();
                    }
                }
            }

            ParallelAnimation {
                id: contentInAnim
                NumberAnimation { target: osdIndicatorLoader; property: "opacity"; from: osdIndicatorLoader.opacity; to: 1.0; duration: 250; easing.type: Easing.OutQuint }
                NumberAnimation { target: osdIndicatorLoader; property: "scale"; from: osdIndicatorLoader.scale; to: 1.0; duration: 300; easing.type: Easing.OutBack }
            }

            ParallelAnimation {
                id: contentOutAnim
                NumberAnimation { target: osdIndicatorLoader; property: "opacity"; from: osdIndicatorLoader.opacity; to: 0.0; duration: 200; easing.type: Easing.InCubic }
                NumberAnimation { target: osdIndicatorLoader; property: "scale"; from: osdIndicatorLoader.scale; to: 0.93; duration: 200; easing.type: Easing.InCubic }
                onFinished: {
                    if (!root.showOsd) {
                        osdLoader.active = false;
                    }
                }
            }

            Component.onCompleted: {
                osdIndicatorLoader.opacity = 0;
                osdIndicatorLoader.scale = 0.93;
                contentInAnim.start();
            }

            Loader {
                id: osdIndicatorLoader
                anchors.centerIn: parent
                source: {
                    var ind = root.indicators.find(i => i.id === root.currentIndicator);
                    return ind ? ind.sourceUrl : "";
                }

                readonly property bool isSliderPressed: item && item.isSliderPressed

                onIsSliderPressedChanged: {
                    if (isSliderPressed) {
                        osdTimeout.stop();
                    } else {
                        osdTimeout.restart();
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        osdTimeout.stop();
                    }
                    onExited: {
                        if (!osdIndicatorLoader.isSliderPressed) {
                            osdTimeout.restart();
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osd"
        function showBrightness() { root.currentIndicator = "brightness"; root.triggerOsd(); }
        function showVolume() { root.currentIndicator = "volume"; root.triggerOsd(); }
        function showMic() { root.currentIndicator = "microphone"; root.triggerOsd(); }
    }
}
