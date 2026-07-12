pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal deviceEvent(var info)

    property var lastDevice: null
    property var devicesList: []

    // Helper to safely eject a device node
    function ejectDevice(node) {
        console.log("⚡ UsbMonitorService requesting eject for:", node);
        ejectProc.command = ["/home/sawmer/.config/quickshell/scripts/usb_monitor.sh", "--eject", node];
        ejectProc.running = true;
    }

    property string pendingSound: ""

    Timer {
        id: soundDebounceTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (root.pendingSound !== "") {
                playProcess.command = ["pw-play", root.pendingSound];
                playProcess.running = true;
                root.pendingSound = "";
            }
        }
    }

    function playSound(filePath) {
        root.pendingSound = filePath;
        soundDebounceTimer.restart();
    }

    Process {
        id: playProcess
        running: false
    }

    // Helper to sanitize duplicates from the connected devices list
    function sanitizeDevicesList(list) {
        let clean = [];
        let excludedDevpaths = {};

        // Compare every pair of devices. If device A is nested under device B
        // (i.e. A's devpath starts with B's devpath followed by a slash),
        // we exclude B in favor of the more specific child node A.
        for (let i = 0; i < list.length; i++) {
            let itemA = list[i];
            let pathA = itemA.devpath || "";
            if (!pathA) continue;

            for (let j = 0; j < list.length; j++) {
                if (i === j) continue;
                let itemB = list[j];
                let pathB = itemB.devpath || "";
                if (!pathB) continue;

                // If pathA starts with pathB + "/", pathA is a nested descendant of pathB
                if (pathA.startsWith(pathB + "/")) {
                    excludedDevpaths[pathB] = true;
                }
            }
        }

        // Also add a fallback to exclude whole disks if their partition nodes are present
        let partitionParents = {};
        for (let i = 0; i < list.length; i++) {
            let dev = list[i].device;
            let isBlock = dev.startsWith("/dev/sd") || dev.startsWith("/dev/mmcblk") || dev.startsWith("/dev/nvme");
            if (isBlock) {
                let isPart = false;
                let parent = "";
                if (dev.startsWith("/dev/sd")) {
                    isPart = /[0-9]$/.test(dev);
                    if (isPart) parent = dev.replace(/[0-9]+$/, "");
                } else if (dev.startsWith("/dev/mmcblk") || dev.startsWith("/dev/nvme")) {
                    isPart = /p[0-9]+$/.test(dev);
                    if (isPart) parent = dev.replace(/p[0-9]+$/, "");
                }
                if (isPart && parent) {
                    partitionParents[parent] = true;
                }
            }
        }

        // Build clean list
        for (let i = 0; i < list.length; i++) {
            let item = list[i];
            let path = item.devpath || "";
            let dev = item.device;
            
            // Exclude if it's in the devpath exclusions list
            if (path && excludedDevpaths[path]) {
                continue;
            }

            // Exclude if it's a parent disk and we have partition nodes
            if (partitionParents[dev]) {
                continue;
            }

            clean.push(item);
        }

        return clean;
    }

    Process {
        id: ejectProc
        running: false
        onExited: exitCode => {
            console.log("ℹ️ UsbMonitorService eject finished with code:", exitCode);
        }
    }

    // Query connected devices at startup
    Process {
        id: initialListProc
        command: ["/home/sawmer/.config/quickshell/scripts/usb_monitor.sh", "--list"]
        running: true
        stdout: StdioCollector {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed.length === 0) return;
                try {
                    const parsed = JSON.parse(trimmed);
                    if (Array.isArray(parsed)) {
                        root.devicesList = root.sanitizeDevicesList(parsed);
                        console.log("🔌 UsbMonitorService initialized connected devices:", JSON.stringify(root.devicesList));
                    }
                } catch (e) {
                    console.log("❌ UsbMonitorService initial list parse error:", e);
                }
            }
        }
    }

    Process {
        id: monitorProc
        command: ["/home/sawmer/.config/quickshell/scripts/usb_monitor.sh"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed.length === 0) return;
                console.log("📥 UsbMonitorService read line:", trimmed);
                try {
                    const info = JSON.parse(trimmed);
                    root.lastDevice = info;
                    
                    // Maintain the connected devices list in real-time
                    let temp = [...root.devicesList];
                    if (info.event === "add") {
                        root.playSound("/home/sawmer/.config/quickshell/assets/USB-Insert.wav");
                        let exists = false;
                        for (let i = 0; i < temp.length; i++) {
                            if (temp[i].device === info.device) {
                                exists = true;
                                temp[i] = info;
                                break;
                            }
                        }
                        if (!exists) {
                            temp.push(info);
                        }
                        root.devicesList = root.sanitizeDevicesList(temp);
                        root.deviceEvent(info);
                    } else if (info.event === "remove") {
                        // Find the matching item in the current devicesList before we remove it
                        let foundItem = null;
                        for (let i = 0; i < root.devicesList.length; i++) {
                            let item = root.devicesList[i];
                            if (item.device === info.device || item.device.startsWith(info.device) || info.device.startsWith(item.device)) {
                                foundItem = item;
                                break;
                            }
                        }

                        if (foundItem !== null) {
                            // Only play sound and broadcast event if we actually track this device removal
                            root.playSound("/home/sawmer/.config/quickshell/assets/USB-Remove.wav");
                            
                            let removalInfo = {
                                event: "remove",
                                device: info.device,
                                displayName: foundItem.displayName,
                                deviceType: foundItem.deviceType,
                                timestamp: info.timestamp || new Date().toISOString()
                            };

                            // Update list
                            temp = temp.filter(item => {
                                return item.device !== info.device && !item.device.startsWith(info.device) && !info.device.startsWith(item.device);
                            });
                            root.devicesList = root.sanitizeDevicesList(temp);
                            
                            root.deviceEvent(removalInfo);
                        }
                    }
                } catch (e) {
                    console.log("❌ UsbMonitorService parse error:", e, "on data:", trimmed);
                }
            }
        }

        onExited: exitCode => {
            console.log("⚠️ UsbMonitorService monitorProc exited with code:", exitCode);
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (!monitorProc.running) {
                monitorProc.running = true;
            }
        }
    }
}
