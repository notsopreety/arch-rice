pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuUsage: 0
    property real cpuTemperature: 40
    property real memoryUsage: 0
    property string uptime: "up 0 minutes"

    // Stub functions for compatibility with copied widgets
    function addRef(modules) {
        pollTimer.start();
    }
    function removeRef(modules) {}

    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statsProc.running = true;
        }
    }

    Process {
        id: statsProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'; pkg_temp_file=\"\"; for h in /sys/devices/platform/coretemp.0/hwmon/hwmon*; do if [ -d \"$h\" ]; then for f in \"$h\"/temp*_label; do if [ -f \"$f\" ]; then lbl=$(cat \"$f\"); if [ \"$lbl\" = \"Package id 0\" ] || [[ \"$lbl\" =~ [Pp]ackage ]]; then pkg_temp_file=\"${f%_label}_input\"; break 2; fi; fi; done; fi; done; if [ -n \"$pkg_temp_file\" ] && [ -f \"$pkg_temp_file\" ]; then cat \"$pkg_temp_file\"; else temp_file=\"/sys/class/thermal/thermal_zone0/temp\"; for z in /sys/class/thermal/thermal_zone*; do type=$(cat $z/type 2>/dev/null); if [ \"$type\" = \"x86_pkg_temp\" ] || [ \"$type\" = \"TCPU\" ]; then temp_file=\"$z/temp\"; break; fi; done; cat \"$temp_file\" 2>/dev/null || echo 40000; fi; free -m | awk 'NR==2{print $3/$2*100}'; uptime -p"]
        running: false
        
        property int lineCount: 0
        
        onStarted: {
            lineCount = 0;
        }
 
        stdout: SplitParser {
            onRead: function(line) {
                statsProc.lineCount++;
                var clean = line.trim();
                if (statsProc.lineCount === 1) {
                    root.cpuUsage = parseFloat(clean) || 0;
                } else if (statsProc.lineCount === 2) {
                    var rawTemp = parseFloat(clean) || 40000;
                    root.cpuTemperature = Math.round(rawTemp / 1000);
                } else if (statsProc.lineCount === 3) {
                    root.memoryUsage = parseFloat(clean) || 0;
                } else if (statsProc.lineCount === 4) {
                    root.uptime = clean
                        .replace(/\bminutes\b/g, "min")
                        .replace(/\bminute\b/g, "min")
                        .replace(/\bhours\b/g, "hrs")
                        .replace(/\bhour\b/g, "hr")
                        .replace(/\bdays\b/g, "d")
                        .replace(/\bday\b/g, "d");
                }
            }
        }
    }
}
