//@ pragma UseQApplication
//@ pragma ShellId quickshell

import QtQuick
import Quickshell
import Quickshell.Io
import "widgets"
import "widgets/controlcenter"
import "widgets/wallpaper"
import "widgets/lockscreen"
import "widgets/osd"
import "widgets/workspace"
import "widgets/launcher"
import "theme"
import "services"

ShellRoot {
    id: root

    readonly property bool _appInit: {
        Qt.application.organization = "quickshell"
        Qt.application.domain = "quickshell.org"
        Qt.application.name = "quickshell"
        return true
    }

    // Instantiate Status Bar
    Bar {
        id: topBar
    }

    // Instantiate Desktop Canvas for Draggable Widgets
    DesktopCanvas {
        id: desktopCanvas
    }

    // Instantiate Power Menu Overlay Window
    PowerMenuWindow {
        id: powermenuWindow
    }

    // Instantiate Wallpaper Selector Overlay Window
    WallpaperWindow {
        id: wallpaperWindow
    }

    // Instantiate Lock Screen (triggered via IPC)
    LockWindow {
        id: lockWindow
    }

    // Instantiate Dank Dash Overlay Window
    DankDashWindow {
        id: dankdashWindow
    }

    // Instantiate Notification Center Overlay Window
    NotificationCenterWindow {
        id: notificationcenterWindow
    }

    // Instantiate WiFi Selection Overlay Window
    NetworkWindow {
        id: networkWindow
    }

    // Instantiate Bluetooth Selection Overlay Window
    BluetoothWindow {
        id: bluetoothWindow
    }

    // Instantiate Control Center Overlay Window
    ControlCenterWindow {
        id: controlCenterWindow
    }

    // Instantiate Battery Overlay Window
    BatteryWindow {
        id: batteryWindow
    }

    // Instantiate Clipboard Overlay Window
    ClipboardWindow {
        id: clipboardWindow
    }

    // Instantiate Keybinds Cheatsheet Window
    KeybindsWindow {
        id: keybindsWindow
    }

    // Instantiate Emoji Board Window
    EmojiBoardWindow {
        id: emojiBoardWindow
    }

    // Instantiate Application Launcher Window
    LauncherWindow {
        id: launcherWindow
    }

    // Instantiate Shapes Overview Window
    ShapesOverviewWindow {
        id: shapesOverviewWindow
    }

    // Instantiate Workspace Overview Window
    WorkspaceWindow {
        id: workspaceWindow
    }

    // Instantiate Sidebar Window
    SidebarWindow {
        id: sidebarWindow
    }

    // Instantiate Google Lens Overlay Window
    GoogleLensWindow {
        id: googleLensWindow
        Component.onCompleted: GoogleLensService.overlayWindow = googleLensWindow
    }

    // Instantiate Snip Tool Window
    SnipWindow {
        id: snipWindow
        Component.onCompleted: SnipService.overlayWindow = snipWindow
    }

    // Instantiate Polkit Authentication Panel
    PolkitPanel {
        id: polkitPanel
    }


    // Centralized Android-16 OSD Manager
    OSD {}
    Variants {
        model: Quickshell.screens
        delegate: AudioOutputOSD { modelData: item }
    }
    Variants {
        model: Quickshell.screens
        delegate: MediaPlaybackOSD { modelData: item }
    }



    // Custom Desktop Notification Toast Manager
    NotificationPopup {}

    // USB/External storage hotplug OSD
    UsbOSD {}

    // Media hover popup notch window
    MediaNotchPopup {}

    // Instantiate Notepad Window via Loader for proper close/reopen
    Loader {
        id: notepadLoader
        active: false

        sourceComponent: Component {
            NotepadWindow {
                visible: true
                onClosed: {
                    notepadLoader.active = false;
                }
            }
        }
    }

    // Instantiate Calculator Window via Loader for proper close/reopen
    Loader {
        id: calculatorLoader
        active: false

        sourceComponent: Component {
            CalculatorWindow {
                visible: true
                onClosed: {
                    calculatorLoader.active = false;
                }
            }
        }
    }

    // Instantiate System Monitor Window via Loader for proper close/reopen
    Loader {
        id: systemMonitorLoader
        active: false

        sourceComponent: Component {
            SystemMonitorWindow {
                visible: true
                onClosed: {
                    systemMonitorLoader.active = false;
                }
            }
        }
    }

    // Ipc Handler for systemmonitor target
    IpcHandler {
        target: "systemmonitor"

        function systemmonitor() { systemMonitorLoader.active = !systemMonitorLoader.active; }
        function open() { systemMonitorLoader.active = true; }
        function open_direct() { systemMonitorLoader.active = true; }
        function close() { systemMonitorLoader.active = false; }
        function toggle() { systemMonitorLoader.active = !systemMonitorLoader.active; }
    }

    // Screen Time Window Loader
    Loader {
        id: screenTimeLoader
        active: false

        sourceComponent: Component {
            ScreenTimeWindow {
                visible: true
                onClosed: {
                    screenTimeLoader.active = false;
                }
            }
        }
    }

    // Ipc Handler for screentime target
    IpcHandler {
        target: "screentime"
        function open() { screenTimeLoader.active = true; }
        function open_direct() { screenTimeLoader.active = true; }
        function close() { screenTimeLoader.active = false; }
        function toggle() { screenTimeLoader.active = !screenTimeLoader.active; }
    }

    // Native Quickshell IPC Handler
    IpcHandler {
        target: "quickshell"

        function systemmonitor() { systemMonitorLoader.active = !systemMonitorLoader.active; }

        // Exposed run method for terminal/scripts
        function run(command: string) {
            command = command.toLowerCase();
            console.log("Quickshell IPC command received:", command);

            if (command.startsWith("eject")) {
                let parts = command.split(" ");
                if (parts.length > 1) {
                    let dev = parts[1];
                    ejectProcess.command = ["/home/sawmer/.config/quickshell/scripts/usb_monitor.sh", "--eject", dev];
                    ejectProcess.running = true;
                }
                return;
            }
            
            // Check for notepad with arguments
            if (command.startsWith("notepad")) {
                let parts = command.split(" ");
                if (parts.length > 1) {
                    let path = parts.slice(1).join(" ");
                    NotepadService.openFile(path);
                }
                notepadLoader.active = true;
                return;
            }

            if (command.startsWith("calculator") || command === "calc") {
                calculatorLoader.active = true;
                return;
            }

            if (command === "systemmonitor" || command === "sysmon" || command === "system monitor") {
                systemMonitorLoader.active = true;
                return;
            }

            if (command === "screentime" || command === "digital wellbeing") {
                screenTimeLoader.active = true;
                return;
            }

            switch (command) {
                case "reload":
                    Quickshell.reload(true);
                    break;
                case "powermenu":
                    PowerMenuService.toggle();
                    break;
                case "dashboard":
                    DankDashService.toggle();
                    break;
                case "overview":
                    DankDashService.activeTab = 0;
                    DankDashService.visible = true;
                    break;
                case "media":
                    DankDashService.activeTab = 1;
                    DankDashService.visible = true;
                    break;
                case "wallpapers":
                    DankDashService.activeTab = 2;
                    DankDashService.visible = true;
                    break;
                case "weather":
                    DankDashService.activeTab = 3;
                    DankDashService.visible = true;
                    break;
                case "performance":
                    DankDashService.activeTab = 4;
                    DankDashService.visible = true;
                    break;
                case "settings":
                    DankDashService.activeTab = 5;
                    DankDashService.visible = true;
                    break;
                case "notification":
                case "notiification":
                case "notifications":
                    NotificationCenterService.toggle();
                    break;
                case "controlcenter":
                    ControlCenterService.toggle();
                    break;
                case "airplane":
                case "airplanemode":
                    OsdService.toggleAirplaneMode();
                    break;
                case "wifi":
                    WifiCenterService.toggle();
                    break;
                case "bluetooth":
                    BluetoothCenterService.toggle();
                    break;
                case "wallpaper":
                    WallpaperService.toggle();
                    break;
                case "clipboard":
                    ClipboardService.toggle();
                    break;
                case "keybinds":
                    KeybindsService.toggle();
                    break;
                case "emojiboard":
                    EmojiService.toggle();
                    break;
                case "launcher":
                    LauncherService.toggle();
                    break;
                case "glens":
                    GoogleLensService.capture();
                    break;
                case "sniptool":
                    SnipService.capture();
                    break;
                case "colorpicker":
                case "picker":
                    ColorPickerService.pickColor();
                    break;
                case "screenshot":
                    Screenshot.takeScreenshot("screen");
                    break;
                case "screenrecorder":
                    if (Screenshot.isRecording) {
                        Screenshot.stopRecording();
                    } else {
                        Screenshot.startRecording();
                    }
                    break;
                case "shapes":
                    ShapesOverviewService.toggle();
                    break;
                case "workspace":
                    WorkspaceService.toggle();
                    break;
                case "sidebar":
                    SidebarService.toggle();
                    break;
                case "lock":
                    LockService.lock();
                    break;
                case "systemmonitor":
                    systemMonitorLoader.active = !systemMonitorLoader.active;
                    break;

                default:
                    console.warn("Unknown IPC command:", command);
            }
        }
    }

    Process {
        id: ejectProcess
        running: false
        onExited: exitCode => {
            console.log("ℹ️ Eject command finished with code:", exitCode);
        }
    }
}
