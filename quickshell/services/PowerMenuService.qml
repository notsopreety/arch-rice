pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool visible: false

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }

    // Processes
    property Process lockProc: Process { command: ["loginctl", "lock-session"] }
    property Process sleepProc: Process { command: ["sh", "-c", "loginctl lock-session && systemctl suspend"] }
    property Process reloadProc: Process { command: ["quickshell", "ipc", "call", "quickshell", "run", "reload"] }
    property Process rebootProc: Process { command: ["systemctl", "reboot"] }
    property Process logoutProc: Process { command: ["loginctl", "terminate-session", "$XDG_SESSION_ID"] }
    property Process poweroffProc: Process { command: ["systemctl", "poweroff"] }

    function runCommand(cmd) {
        console.log("PowerMenuService: running command:", cmd);
        if (cmd === "lock")          lockProc.running = true;
        else if (cmd === "sleep")    sleepProc.running = true;
        else if (cmd === "reload")   Quickshell.reload(true);
        else if (cmd === "reboot")   rebootProc.running = true;
        else if (cmd === "logout")   logoutProc.running = true;
        else if (cmd === "poweroff") poweroffProc.running = true;
        close();
    }
}
