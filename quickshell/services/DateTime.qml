pragma Singleton

import QtQuick
import Quickshell
import "../core"

/**
 * Provides current date and time as properties that auto-update.
 */
Singleton {
    id: root
    property string currentTime: ""
    property string currentDate: ""
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string time12h: ""

    property var clock: SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    property string time: root.currentTime
    property string date: root.currentDate
    property string dayNameShort: Qt.locale().toString(sysClock.date, "ddd")
    property string dayOfMonth: Qt.locale().toString(sysClock.date, "d")
    property string shortDate: Qt.locale().toString(sysClock.date, "dd/MM")
    property string longDate: Qt.locale().toString(sysClock.date, "dddd, dd/MM")
    readonly property bool use12HourClock: Config.ready && Config.options.time ? Config.options.time.timeStyle !== "24H" : false
    property string meridiem: root.hours >= 12 ? "PM" : "AM"

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = sysClock.date || new Date()
            
            // Manual formatting to ensure leading zeros for 12h mode as requested
            const h = now.getHours()
            const m = now.getMinutes()
            const is24 = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true
            
            if (is24) {
                root.currentTime = h.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0")
            } else {
                const upper = Config.options && Config.options.time ? Config.options.time.timeStyle === "12H_PM" : true
                const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am")
                const h12 = h % 12 || 12
                root.currentTime = h12.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + ap
            }
            
            root.currentDate = Qt.formatDate(now, Config.dateFormat || "ddd, MMM d")
            root.hours = h
            root.minutes = m
            root.seconds = now.getSeconds()
            root.meridiem = h >= 12 ? "PM" : "AM"
            
            // Always provide a standard 12h string for accessories
            const h12_raw = h % 12 || 12
            root.time12h = h12_raw.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + (h >= 12 ? "pm" : "am")
        }
    }

    // Uptime is provided by SystemData (from dgop); no local /proc/uptime reader needed.
}
