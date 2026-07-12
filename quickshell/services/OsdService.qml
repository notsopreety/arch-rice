pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "."

Singleton {
    id: root

    // Signals for OSD windows to trigger
    signal volumeTriggered()
    signal micTriggered()
    signal brightnessTriggered()
    signal capsLockTriggered()
    signal audioOutputTriggered(string name, string icon)
    signal mediaPlaybackTriggered()
    signal powerProfileTriggered(string profile)
    signal idleInhibitorTriggered(bool active)
    signal dndTriggered(bool active)
    signal airplaneModeTriggered(bool active)
    signal kbdBrightnessTriggered()
    signal nightLightTriggered(bool active)
    signal wifiTriggered(bool connected, string ssid)
    signal bluetoothTriggered(bool connected, string deviceName)

    readonly property bool wifiConnected: Network.connected || Network.isWired
    readonly property string wifiSsid: Network.isWired ? Network.wiredConnectionName : Network.ssid

    onWifiConnectedChanged: {
        if (root.isStartupDone) {
            root.wifiTriggered(wifiConnected, wifiSsid);
        }
    }
    onWifiSsidChanged: {
        if (root.isStartupDone && wifiConnected) {
            root.wifiTriggered(wifiConnected, wifiSsid);
        }
    }

    readonly property bool btConnected: Bluetooth.connected
    readonly property string btDeviceNames: Bluetooth.deviceName

    onBtConnectedChanged: {
        if (root.isStartupDone) {
            root.bluetoothTriggered(btConnected, btDeviceNames);
        }
    }
    onBtDeviceNamesChanged: {
        if (root.isStartupDone && btConnected) {
            root.bluetoothTriggered(btConnected, btDeviceNames);
        }
    }

    // Current states bound directly to singletons for maximum responsiveness
    property int volume: Audio.percentage
    property bool muted: Audio.muted
    property int micVolume: Audio.sourcePercentage
    property bool micMuted: Audio.sourceMuted
    property int brightness: Brightness.percentage
    property bool capsLockState: false
    property bool idleInhibited: false
    property string powerProfile: "balanced"
    property bool dndActive: false
    property bool airplaneModeActive: false
    property bool nightLightActive: false
    property string kbdPath: ""
    property int kbdMaxBrightness: 1
    property real kbdBrightness: 0

    // Configuration / settings fallback
    property bool osdVolumeEnabled: true
    property bool osdMicVolumeEnabled: true
    property bool osdMicMuteEnabled: true
    property bool osdBrightnessEnabled: true
    property bool osdCapsLockEnabled: true
    property bool osdAudioOutputEnabled: true
    property bool osdMediaPlaybackEnabled: true
    property bool osdPowerProfileEnabled: true
    property bool osdIdleInhibitorEnabled: true
    property bool osdAlwaysShowValue: true

    // Internal trackers
    property var lastSink: null
    property var lastSource: null
    property string lastTrackTitle: ""

    property bool isStartupDone: false

    Timer {
        id: startupTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: root.isStartupDone = true
    }

    // Connect to Audio singleton changes to trigger OSD instantly
    Connections {
        target: Audio
        function onVolumeChanged() {
            if (Audio.sink !== root.lastSink) {
                root.lastSink = Audio.sink;
                return;
            }
            if (root.isStartupDone && root.osdVolumeEnabled) {
                root.volumeTriggered();
            }
        }
        function onMutedChanged() {
            if (Audio.sink !== root.lastSink) {
                root.lastSink = Audio.sink;
                return;
            }
            if (root.isStartupDone && root.osdVolumeEnabled) {
                root.volumeTriggered();
            }
        }
        function onSourceVolumeChanged() {
            if (Audio.source !== root.lastSource) {
                root.lastSource = Audio.source;
                return;
            }
            if (root.isStartupDone && (root.osdMicVolumeEnabled || root.osdMicMuteEnabled)) {
                root.micTriggered();
            }
        }
        function onSourceMutedChanged() {
            if (Audio.source !== root.lastSource) {
                root.lastSource = Audio.source;
                return;
            }
            if (root.isStartupDone && (root.osdMicVolumeEnabled || root.osdMicMuteEnabled)) {
                root.micTriggered();
            }
        }
    }

    // Connect to Brightness singleton changes to trigger OSD instantly
    Connections {
        target: Brightness
        function onBrightnessUpdated() {
            if (root.isStartupDone && root.osdBrightnessEnabled) {
                root.brightnessTriggered();
            }
        }
    }

    // Caps Lock state detection via FileView (updates at 100ms, 0% CPU overhead)
    property string capslockPath: ""
    
    Process {
        id: detectCapslockProc
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock/brightness 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim();
                if (path.length > 0) {
                    root.capslockPath = path;
                }
            }
        }
    }

    FileView {
        id: capslockFile
        path: root.capslockPath
        preload: true
        watchChanges: false
    }

    Timer {
        id: capslockTimer
        interval: 100
        repeat: true
        running: root.capslockPath !== ""
        triggeredOnStart: true
        onTriggered: {
            capslockFile.reload();
            var text = capslockFile.text().trim();
            if (text) {
                var val = parseInt(text);
                if (!isNaN(val)) {
                    var state = (val === 1);
                    if (state !== root.capsLockState) {
                        root.capsLockState = state;
                        if (root.isStartupDone && root.osdCapsLockEnabled) {
                            root.capsLockTriggered();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: detectKbdProc
        command: ["sh", "-c", "ls -d /sys/class/leds/*kbd_backlight/brightness 2>/dev/null | head -n 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var path = text.trim();
                if (path.length > 0) {
                    root.kbdPath = path;
                    detectKbdMaxProc.running = true;
                }
            }
        }
    }

    Process {
        id: detectKbdMaxProc
        command: ["sh", "-c", "cat /sys/class/leds/*kbd_backlight/max_brightness 2>/dev/null | head -n 1"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(text.trim());
                if (!isNaN(val) && val > 0) {
                    root.kbdMaxBrightness = val;
                }
            }
        }
    }

    FileView {
        id: kbdFile
        path: root.kbdPath
        preload: true
        watchChanges: false
    }

    Timer {
        id: kbdTimer
        interval: 100
        repeat: true
        running: root.kbdPath !== ""
        triggeredOnStart: true
        onTriggered: {
            kbdFile.reload();
            var text = kbdFile.text().trim();
            if (text) {
                var val = parseInt(text);
                if (!isNaN(val)) {
                    var percentage = val / root.kbdMaxBrightness;
                    if (percentage !== root.kbdBrightness) {
                        root.kbdBrightness = percentage;
                        if (root.isStartupDone) {
                            root.kbdBrightnessTriggered();
                        }
                    }
                }
            }
        }
    }

    // MPRIS Media Playback monitoring
    Connections {
        target: Mpris.players
        function onValuesChanged() {
            monitorActivePlayer();
        }
    }

    readonly property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    onActivePlayerChanged: {
        monitorActivePlayer();
    }

    function monitorActivePlayer() {
        if (activePlayer) {
            playerConnections.target = activePlayer;
            if (activePlayer.trackTitle && activePlayer.trackTitle !== root.lastTrackTitle) {
                root.lastTrackTitle = activePlayer.trackTitle;
                root.mediaPlaybackTriggered();
            }
        } else {
            playerConnections.target = null;
        }
    }

    Connections {
        id: playerConnections
        target: null
        ignoreUnknownSignals: true

        function onTrackTitleChanged() {
            if (activePlayer && activePlayer.trackTitle !== root.lastTrackTitle) {
                root.lastTrackTitle = activePlayer.trackTitle;
                root.mediaPlaybackTriggered();
            }
        }

        function onPlaybackStateChanged() {
            root.mediaPlaybackTriggered();
        }

        function onVolumeChanged() {
            root.mediaPlaybackTriggered();
        }
    }

    // Helper functions for audio sinks
    function sinkIcon(node) {
        if (!node)
            return "speaker";
        const props = node.properties || {};
        const formFactor = (props["device.form-factor"] || "").toLowerCase();
        switch (formFactor) {
            case "headphone":
            case "headset":
            case "hands-free":
            case "handset":
                return "headset";
            case "tv":
            case "monitor":
                return "tv";
            case "speaker":
            case "computer":
            case "hifi":
            case "portable":
            case "car":
                return "speaker";
        }
        const bus = (props["device.bus"] || "").toLowerCase();
        if (bus === "bluetooth")
            return "headset";
        return "speaker";
    }

    function displayName(node) {
        if (!node) return "";
        if (node.properties && node.properties["node.description"]) {
            return node.properties["node.description"];
        }
        return node.name || "Default Output";
    }

    // Expose toggle helpers
    function toggleMute() {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }

    function toggleMicMute() {
        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
        }
    }

    function toggleIdleInhibitor() {
        root.idleInhibited = !root.idleInhibited;
        root.idleInhibitorTriggered(root.idleInhibited);
    }

    function cyclePowerProfile() {
        var profiles = ["balanced", "power-saver", "performance"];
        var idx = profiles.indexOf(root.powerProfile);
        var nextIdx = (idx + 1) % profiles.length;
        root.powerProfile = profiles[nextIdx];
        root.powerProfileTriggered(root.powerProfile);
        
        // Execute powerprofilesctl if available
        ppProc.command = ["powerprofilesctl", "set", root.powerProfile];
        ppProc.running = true;
    }

    Process {
        id: ppProc
        running: false
    }

    property var currentOSDsByScreen: ({})

    function showOSD(osd) {
        if (!osd || !osd.screen)
            return;
        var screenName = osd.screen.name;
        var currentOSD = currentOSDsByScreen[screenName];
        if (currentOSD && currentOSD !== osd) {
            try {
                currentOSD.hide();
            } catch (e) {}
        }
        currentOSDsByScreen[screenName] = osd;
    }

    onAirplaneModeActiveChanged: {
        if (root.isStartupDone) {
            // Ignore "Airplane Mode Off" OSD if we are already connected/connecting to WiFi or Bluetooth
            if (!airplaneModeActive && (wifiConnected || btConnected)) {
                return;
            }
            root.airplaneModeTriggered(airplaneModeActive);
        }
    }

    Connections {
        target: PowerProfiles
        function onActiveProfileChanged() {
            root.powerProfile = PowerProfiles.activeProfile;
            if (root.isStartupDone && root.osdPowerProfileEnabled) {
                root.powerProfileTriggered(root.powerProfile);
            }
        }
    }

    Connections {
        target: Notifs
        function onDndChanged() {
            root.dndActive = Notifs.dnd;
            if (root.isStartupDone) {
                root.dndTriggered(root.dndActive);
            }
        }
    }

    // Airplane Mode System Integration
    function toggleAirplaneMode() {
        var nextState = !root.airplaneModeActive;
        root.airplaneModeActive = nextState;
        if (nextState) {
            blockAirplaneModeProcess.running = false;
            blockAirplaneModeProcess.running = true;
        } else {
            unblockAirplaneModeProcess.running = false;
            unblockAirplaneModeProcess.running = true;
        }
    }

    Process {
        id: blockAirplaneModeProcess
        command: ["rfkill", "block", "all"]
        running: false
    }

    Process {
        id: unblockAirplaneModeProcess
        command: ["rfkill", "unblock", "all"]
        running: false
    }

    Process {
        id: rfkillCheckProcess
        command: ["sh", "-c", "rfkill list wifi | grep -q 'Soft blocked: yes'"]
        running: false
        onExited: (code) => {
            var active = (code === 0);
            if (root.airplaneModeActive !== active) {
                root.airplaneModeActive = active;
            }
        }
    }

    Process {
        id: rfkillEventProcess
        command: ["rfkill", "event"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                rfkillCheckProcess.running = false;
                rfkillCheckProcess.running = true;
            }
        }
    }

    Timer {
        id: rfkillWatcherTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!rfkillEventProcess.running) {
                rfkillEventProcess.running = true;
            }
            rfkillCheckProcess.running = false;
            rfkillCheckProcess.running = true;
            
            // Periodically verify hyprsunset running state
            hyprsunsetCheckProcess.running = false;
            hyprsunsetCheckProcess.running = true;
        }
    }

    onNightLightActiveChanged: {
        if (root.isStartupDone) {
            root.nightLightTriggered(nightLightActive);
        }
    }

    function toggleNightLight() {
        var nextState = !root.nightLightActive;
        root.nightLightActive = nextState;
        if (nextState) {
            Quickshell.execDetached(["hyprsunset", "-t", "4000"]);
        } else {
            Quickshell.execDetached(["pkill", "hyprsunset"]);
        }
    }

    Process {
        id: hyprsunsetCheckProcess
        command: ["pgrep", "-x", "hyprsunset"]
        running: false
        onExited: (code) => {
            var active = (code === 0);
            if (root.nightLightActive !== active) {
                root.nightLightActive = active;
            }
        }
    }

    Component.onCompleted: {
        root.lastSink = Pipewire.defaultAudioSink;
        root.lastSource = Pipewire.defaultAudioSource;
        root.powerProfile = PowerProfiles.activeProfile;
        root.dndActive = Notifs.dnd;
        monitorActivePlayer();
        
        // Initial system checks
        rfkillCheckProcess.running = true;
        hyprsunsetCheckProcess.running = true;
    }
}
