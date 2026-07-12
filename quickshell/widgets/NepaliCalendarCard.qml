import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"

Card {
    id: root

    color: root.isHoliday
        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
        : Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.4)

    border.color: root.isHoliday
        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.4)
        : Theme.outlineVariant

    property string gatey: ""
    property string mahina: ""
    property string baar: ""
    property string barsa: ""
    property string tithi: ""
    property string eventText: ""
    property bool isHoliday: false
    property bool loading: true
    property bool hasValidCacheData: false

    // File reader to read the cached data synchronously on startup
    property FileView cacheReader: FileView {
        id: cacheReader
        path: Quickshell.env("HOME") + "/.config/quickshell/scratch/nepali_calendar_cache.json"
        preload: true
        onLoaded: {
            root.loadAndCheckCache();
        }
    }

    // Process to write cache data back using Python
    Process {
        id: cacheWriter
        running: false
    }

    function isCacheExpired(lastFetchMs) {
        if (!lastFetchMs) return true;
        var now = new Date();
        var last = new Date(lastFetchMs);
        
        // If more than 12 hours have passed, definitely expired
        if (now.getTime() - last.getTime() > 12 * 60 * 60 * 1000) {
            return true;
        }
        
        // If the date is different, it has crossed midnight (12 AM)
        if (now.getDate() !== last.getDate()) {
            return true;
        }
        
        // If they are on the same day, check if they crossed noon (12 PM)
        var nowHours = now.getHours();
        var lastHours = last.getHours();
        if (lastHours < 12 && nowHours >= 12) {
            return true;
        }
        
        return false;
    }

    function saveToCache(jsonString) {
        var cachePath = Quickshell.env("HOME") + "/.config/quickshell/scratch/nepali_calendar_cache.json";
        cacheWriter.command = [
            "python3", "-c", 
            "import os, sys; os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True); open(sys.argv[1], 'w').write(sys.argv[2])", 
            cachePath, jsonString
        ];
        cacheWriter.running = true;
    }

    function loadAndCheckCache() {
        var hasCache = false;
        var expired = true;
        var lastTimestamp = 0;
        
        try {
            var rawText = cacheReader.text();
            if (rawText) {
                var cache = JSON.parse(rawText);
                if (cache && cache.miti) {
                    root.gatey = cache.miti.gatey || "";
                    root.mahina = cache.miti.mahina || "";
                    root.baar = cache.baar || cache.miti.baar || "";
                    root.barsa = cache.miti.barsa || "";
                    root.tithi = cache.tithi || "";
                    root.eventText = cache.event || "";
                    root.isHoliday = cache.isHoliday || false;
                    lastTimestamp = cache.timestamp || 0;
                    hasCache = true;
                    root.hasValidCacheData = true;
                    root.loading = false;
                }
            }
        } catch (e) {
            console.log("Error loading Nepali Calendar cache:", e);
        }
        
        if (hasCache) {
            expired = isCacheExpired(lastTimestamp);
        }
        
        if (!hasCache || expired) {
            fetchDetailed(hasCache);
        }
    }

    function fetchDetailed(hasCache) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "https://nepali-calender-ten.vercel.app/detailed");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res && res.miti) {
                            root.gatey = res.miti.gatey || "";
                            root.mahina = res.miti.mahina || "";
                            root.baar = res.baar || res.miti.baar || "";
                            root.barsa = res.miti.barsa || "";
                            root.tithi = res.tithi || "";
                            root.eventText = res.event || "";
                            root.isHoliday = res.isHoliday || false;
                            root.loading = false;
                            root.hasValidCacheData = true;
                            
                            // Save to cache with timestamp
                            res.timestamp = new Date().getTime();
                            saveToCache(JSON.stringify(res));
                        }
                    } catch (e) {
                        console.log("Error parsing Nepali Calendar JSON:", e);
                    }
                } else {
                    // API request failed (e.g. no internet)
                    if (!root.hasValidCacheData) {
                        root.loading = false;
                        root.gatey = "N/A";
                        root.mahina = "Offline";
                        root.baar = "No Connection";
                    }
                }
            }
        };
        xhr.send();
    }

    Component.onCompleted: {
        loadAndCheckCache();
    }

    // Periodic check to refetch if time crossed 12 AM/PM
    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        onTriggered: loadAndCheckCache()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2
        visible: !root.loading

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            Text {
                text: root.gatey
                font.family: Theme.font.family
                font.pixelSize: 32
                font.weight: Font.Bold
                color: root.isHoliday ? Theme.error : Theme.primary
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.mahina + " " + root.barsa
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: "white"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.baar
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    color: "#e7bdb3"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            text: root.tithi + (root.eventText ? " • " + root.eventText : "")
            font.family: Theme.font.family
            font.pixelSize: 9
            color: root.isHoliday ? Theme.error : "#e2e8f0"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    Text {
        anchors.centerIn: parent
        text: "Loading..."
        font.family: Theme.font.family
        font.pixelSize: 11
        color: "#a0aec0"
        visible: root.loading
    }
}
