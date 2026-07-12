pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    signal brightnessUpdated()
    onBrightnessChanged: root.brightnessUpdated()

    property real brightness: 0.5
    property real maxBrightness: 1.0
    
    // Alias for easier access
    readonly property real level: brightness
    readonly property int percentage: Math.round(brightness * 100)
    
    property string _backlightDevice: ""
    readonly property string backlightPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/brightness` : ""
    readonly property string maxBrightnessPath: _backlightDevice !== "" ? `/sys/class/backlight/${_backlightDevice}/max_brightness` : ""
    
    property int currentValue: 0
    property int maxValue: 255
    
    Component.onCompleted: {
        detectBacklightDevice()
        readMaxBrightness()
        readBrightness()
        updateTimer.start()
    }

    function detectBacklightDevice() {
        detectProc.running = true
    }
    
    function readMaxBrightness() {
        if (maxBrightnessPath === "") return
        maxBrightnessProcess.command = ["/bin/cat", maxBrightnessPath]
        maxBrightnessProcess.running = true
    }

    Timer {
        id: cooldownTimer
        interval: 1000
        repeat: false
    }

    function readBrightness() {
        if (cooldownTimer.running) return
        if (backlightPath === "") return
        brightnessFile.reload()
        var text = brightnessFile.text().trim()
        if (text) {
            var value = parseInt(text)
            if (!isNaN(value)) {
                currentValue = value
                var newBrightness = maxValue > 0 ? value / maxValue : 0
                if (newBrightness !== brightness) {
                    brightness = newBrightness
                }
            }
        }
    }
    
    function setBrightness(value) {
        // Clamp between 0 and 1
        const newValue = Math.max(0, Math.min(1, value))

        if (backlightPath === "")
            return

        // Instantly update the local state so the UI responds immediately!
        brightness = newValue
        cooldownTimer.restart()

        // Use brightnessctl when available (works for most backlight devices)
        // Fallback to sysfs write when brightnessctl isn't present.
        const percent = Math.round(newValue * 100)
        const sysfsValue = Math.round(newValue * maxValue)
        const cmd = `brightnessctl set ${percent}% || echo ${sysfsValue} | sudo tee "${backlightPath}" >/dev/null; cat "${backlightPath}"`
        setBrightnessProcess.command = ["/bin/sh", "-c", cmd]
        setBrightnessProcess.running = true
    }
    
    function increaseBrightness() {
        setBrightness(brightness + 0.05)
    }
    
    function decreaseBrightness() {
        setBrightness(brightness - 0.05)
    }
    
    // Read max brightness
    Process {
        id: detectProc
        command: ["/bin/sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n 1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const dev = text.trim()
                if (dev.length > 0) {
                    root._backlightDevice = dev
                } else {
                    root._backlightDevice = ""
                }

                readMaxBrightness()
                readBrightness()
            }
        }
    }

    Process {
        id: maxBrightnessProcess
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value) && value > 0) {
                    maxValue = value
                }
            }
        }
    }
    
    FileView {
        id: brightnessFile
        path: root.backlightPath
        preload: true
        watchChanges: false
    }
    
    // Set brightness process
    Process {
        id: setBrightnessProcess
        running: false

        stdout: SplitParser {
            onRead: data => {
                const value = parseInt(data.trim())
                if (!isNaN(value)) {
                    currentValue = value
                    brightness = maxValue > 0 ? value / maxValue : 0
                }
            }
        }
    }
    
    // Update timer - fast interval for smooth OSD updates
    Timer {
        id: updateTimer
        interval: 50
        repeat: true
        triggeredOnStart: true
        onTriggered: readBrightness()
    }
}
