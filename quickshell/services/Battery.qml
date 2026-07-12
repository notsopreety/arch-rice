pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core"

Singleton {
    id: root
    
    // Find the actual battery device (usually battery_BAT0) for detailed stats
    readonly property var batteryDevice: {
        const devices = UPower.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].isLaptopBattery) return devices[i];
        }
        return UPower.displayDevice;
    }

    property bool available: batteryDevice ? batteryDevice.isLaptopBattery : false
    property var chargeState: batteryDevice ? batteryDevice.state : UPowerDevice.Unknown
    property bool isCharging: chargeState == UPowerDevice.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDevice.PendingCharge || chargeState == UPowerDevice.FullyCharged
    property real percentage: batteryDevice ? batteryDevice.percentage : 1

    // Stats
    property real energyRate: batteryDevice ? batteryDevice.changeRate : 0
    property real timeToEmpty: batteryDevice ? batteryDevice.timeToEmpty : 0
    property real timeToFull: batteryDevice ? batteryDevice.timeToFull : 0
    
    // Hardware Details
    property string vendor: "Unknown"
    property string model: "Generic Battery"
    property string technology: "Unknown"
    property real voltage: 0
    property real capacity: 0
    property real energy: 0
    property real energyFull: 0
    property real energyFullDesign: 0
    property string serial: "Not Available"
    property int cycles: 0

    property real health: {
        if (energyFullDesign > 0 && energyFull > 0) {
            return Math.min(100, (energyFull / energyFullDesign) * 100);
        }
        return 0;
    }

    // --- Data Fetcher ---
    Timer {
        id: detailUpdater
        interval: 5000 // Update every 5s
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: upowerProc.running = true
    }

    Process {
        id: upowerProc
        command: ["bash", "-c", "upower -i $(upower -e | grep 'battery' | head -n1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length < 2) return;
                    const key = parts[0].trim();
                    const val = parts[1].trim();

                    if (key === "vendor") root.vendor = val;
                    if (key === "model") root.model = val;
                    if (key === "serial") root.serial = val;
                    if (key === "technology") root.technology = val;
                    if (key === "voltage") root.voltage = parseFloat(val);
                    if (key === "energy") root.energy = parseFloat(val);
                    if (key === "energy-full") root.energyFull = parseFloat(val);
                    if (key === "energy-full-design") root.energyFullDesign = parseFloat(val);
                    if (key === "charge-cycles") root.cycles = parseInt(val);
                });
            }
        }
    }

    property bool isLow: available && (percentage <= (Config.options && Config.options.battery && Config.options.battery.low ? Config.options.battery.low / 100 : 0.20))
    property bool isCritical: available && (percentage <= (Config.options && Config.options.battery && Config.options.battery.critical ? Config.options.battery.critical / 100 : 0.10))

    property bool conservationMode: false
    property string conservationModePath: "/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/conservation_mode"

    function toggleConservationMode() {
        conservationToggleProc.command = [
            "pkexec", "sh", "-c", 
            `echo ${root.conservationMode ? "0" : "1"} > ${root.conservationModePath}`
        ];
        conservationToggleProc.running = true;
    }

    Process {
        id: conservationToggleProc
        running: false
        onExited: {
            conservationCheckProc.running = true;
        }
    }

    Process {
        id: conservationCheckProc
        command: ["cat", root.conservationModePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = this.text.trim();
                root.conservationMode = (val === "1");
            }
        }
    }

    Timer {
        id: conservationModeUpdater
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            conservationCheckProc.running = true;
        }
    }

    // Material symbol for status bar
    property string materialSymbol: {
        if (!available) return "battery_unknown";
        if (isCharging) return "battery_charging_full";
        if (percentage > 0.95) return "battery_full";
        if (percentage > 0.80) return "battery_6_bar";
        if (percentage > 0.65) return "battery_5_bar";
        if (percentage > 0.50) return "battery_4_bar";
        if (percentage > 0.35) return "battery_3_bar";
        if (percentage > 0.20) return "battery_2_bar";
        if (percentage > 0.10) return "battery_1_bar";
        return "battery_alert";
    }

    // Percentage text for display
    property string percentageText: available ? `${Math.round(percentage * 100)}%` : ""
}
