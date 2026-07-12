pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ----------------------------------------------------
    // TIMER DATA & FUNCTIONS
    // ----------------------------------------------------
    property int timerSeconds: 300
    property int timerTotal: 300
    property bool timerRunning: false
    property bool timerSetupMode: true
    
    // Temp setup values
    property int setupMins: 5
    property int setupSecs: 0

    function formatTimer(s) {
        let secs = s % 60;
        let mins = Math.floor(s / 60);
        let pad = (num) => String(num).padStart(2, '0');
        return pad(mins) + ":" + pad(secs);
    }

    Timer {
        id: countdownTimer
        interval: 1000
        running: root.timerRunning && root.timerSeconds > 0
        repeat: true
        onTriggered: {
            if (root.timerSeconds > 0) {
                root.timerSeconds--;
                if (root.timerSeconds === 0) {
                    root.timerRunning = false;
                    root.timerSetupMode = true;
                    // Play alarm sound using pw-play (timer only plays once)
                    Quickshell.execDetached(["pw-play", "/home/sawmer/.config/quickshell/assets/alarm.mp3"]);
                    // Send desktop notification
                    Quickshell.execDetached(["notify-send", "-r", "1005", "-a", "Timer", "Time's Up!", "Your timer has finished."]);
                }
            }
        }
    }

    // ----------------------------------------------------
    // STOPWATCH DATA & FUNCTIONS
    // ----------------------------------------------------
    property double stopwatchTime: 0
    property double swStartTime: 0
    property double swBaseTime: 0
    property bool swRunning: false

    readonly property alias swLaps: swLapsModel
    ListModel {
        id: swLapsModel
    }

    function formatStopwatch(ms) {
        let totalSecs = Math.floor(ms / 1000);
        let hundredths = Math.floor((ms % 1000) / 10);
        let secs = totalSecs % 60;
        let mins = Math.floor(totalSecs / 60);
        let pad = (num) => String(num).padStart(2, '0');
        return pad(mins) + ":" + pad(secs) + "." + pad(hundredths);
    }

    Timer {
        id: stopwatchTimer
        interval: 16 // ~60 FPS update rate
        running: root.swRunning
        repeat: true
        onTriggered: {
            root.stopwatchTime = root.swBaseTime + (Date.now() - root.swStartTime);
        }
    }

    // ----------------------------------------------------
    // ALARM DATA & SERVICE FUNCTIONS
    // ----------------------------------------------------
    property bool alarmActive: false
    property string activeAlarmLabel: ""

    property Process alarmPlayer: Process {
        command: ["mpv", "--no-video", "--loop-file=inf", "/home/sawmer/.config/quickshell/assets/alarm.mp3"]
    }

    readonly property alias alarms: alarmsModel
    ListModel {
        id: alarmsModel
    }

    FileView {
        id: alarmsFile
        path: Quickshell.shellPath("alarms.json")
        blockLoading: true
        blockWrites: true
        watchChanges: true
        onLoaded: {
            try {
                let content = alarmsFile.text().trim();
                if (content.length > 0) {
                    let list = JSON.parse(content);
                    alarmsModel.clear();
                    for (let i = 0; i < list.length; i++) {
                        let item = list[i];
                        item.lastTriggeredMinute = -1; // reset runtime state
                        item.repeatMode = item.repeatMode || "once";
                        alarmsModel.append(item);
                    }
                } else {
                    alarmsModel.clear();
                    alarmsModel.append({ "hour": 7, "minute": 30, "isPM": false, "label": "Wake Up", "enabled": true, "repeatMode": "once", "lastTriggeredMinute": -1 });
                }
            } catch (e) {
                console.log("[TimerStopwatchService] Failed to parse alarms.json: " + e);
            }
        }
    }

    function saveAlarms() {
        try {
            let list = [];
            for (let i = 0; i < alarmsModel.count; i++) {
                let item = alarmsModel.get(i);
                list.push({
                    "hour": item.hour,
                    "minute": item.minute,
                    "isPM": item.isPM,
                    "label": item.label,
                    "enabled": item.enabled,
                    "repeatMode": item.repeatMode || "once"
                });
            }
            alarmsFile.setText(JSON.stringify(list, null, 2));
        } catch (e) {
            console.log("[TimerStopwatchService] Failed to write alarms.json: " + e);
        }
    }

    // Alarm checker timer
    Timer {
        id: alarmChecker
        interval: 5000 // Check every 5 seconds
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            let currentHour = now.getHours();
            let currentMin = now.getMinutes();

            // Convert current 24h hour to 12h + isPM
            let isPM = currentHour >= 12;
            let hour12 = currentHour % 12;
            if (hour12 === 0) hour12 = 12;

            for (let i = 0; i < alarmsModel.count; i++) {
                let alarm = alarmsModel.get(i);
                if (alarm.enabled && alarm.hour === hour12 && alarm.minute === currentMin && alarm.isPM === isPM) {
                    let lastTriggered = alarm.lastTriggeredMinute || -1;
                    let minuteKey = currentHour * 60 + currentMin;
                    if (lastTriggered !== minuteKey) {
                        alarm.lastTriggeredMinute = minuteKey;
                        if (alarm.repeatMode === "once") {
                            alarm.enabled = false;
                        }
                        root.triggerAlarm(alarm);
                        saveAlarms();
                    }
                }
            }
        }
    }

    function triggerAlarm(alarm) {
        root.alarmActive = true;
        root.activeAlarmLabel = alarm.label || "Alarm";
        root.alarmPlayer.running = false;
        root.alarmPlayer.running = true; // Start infinite loop play via mpv
        
        // Send desktop notification
        Quickshell.execDetached(["notify-send", "-r", "1006", "-a", "Alarm", "Alarm Ringing!", alarm.label ? alarm.label : "Alarm time reached!"]);
    }

    function dismissAlarm() {
        root.alarmPlayer.running = false;
        root.alarmActive = false;
        root.activeAlarmLabel = "";
    }
}
