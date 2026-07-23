import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../core"
import "../services"
import "../theme"
import "../components"

FloatingWindow {
    id: win

    color: "transparent"
    title: "Digital Wellbeing - Screen Time"

    implicitWidth: 500 * Appearance.effectiveScale
    implicitHeight: 850 * Appearance.effectiveScale
    minimumSize: Qt.size(400, 600)

    Process {
        id: forceSaveProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/screentime_daemon.py", "--flush"]
        running: false
    }

    // ── Glassmorphism Toggle Listener ─────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); win.glassmorphism = true; } catch(e) { win.glassmorphism = false; } }
        onLoaded: win.glassmorphism = true
        onLoadFailed: win.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    readonly property color cBg: win.glassmorphism 
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.55) 
        : Appearance.colors.colLayer0
    readonly property color cCard: win.glassmorphism 
        ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.40) 
        : Appearance.colors.colLayer1
    readonly property color cCardBorder: win.glassmorphism 
        ? Qt.rgba(1, 1, 1, 0.18) 
        : Theme.outlineVariant

    onVisibleChanged: {
        if (visible) {
            forceSaveProc.running = true;
        }
    }

    Process {
        id: appFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/get_apps.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.appsData = JSON.parse(text);
                    root.mapIcons();
                } catch (e) { console.log("Icon fetch error", e); }
            }
        }
    }

    Process {
        id: weeklyFetcher
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/get_weekly_screentime.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let wData = JSON.parse(text);
                    root.todayIndex = wData.today_index;
                    if (!root.hasUserSelectedDay) {
                        root.selectedDayIndex = wData.today_index;
                    }
                    root.weeklyData = wData.daily_data;
                    root.computeWeeklyTotals();
                    root.updateAppStatsForSelectedDay();
                } catch (e) { console.log("Weekly data fetch error", e); }
            }
        }
    }

    // Main Window Background - Sharp Edges for M3 & Glassmorphic Support
    Rectangle {
        id: root
        anchors.fill: parent
        color: win.cBg
        border.color: win.cCardBorder
        border.width: 1
        clip: true
        radius: 0 

        // Glossy Glassmorphic Reflection Overlay
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.35
            visible: win.glassmorphism
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.02) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        focus: visible
        Keys.onEscapePressed: {
            if (root.selectedApp) {
                root.selectedApp = null;
            } else {
                win.close();
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        property var appStats: []
        property var appsData: []
        property var weeklyData: [{},{},{},{},{},{},{}]
        property var weeklyTotals: [0,0,0,0,0,0,0]
        property int todayIndex: 0
        property int selectedDayIndex: 0
        property bool hasUserSelectedDay: false
        property int maxTime: 1
        property int totalTime: 0
        property int maxWeeklyTime: 12 * 3600
        
        property var selectedApp: null
        property var selectedAppWeeklyTotals: [0,0,0,0,0,0,0]
        property int maxSelectedAppWeeklyTime: 1

        Timer {
            id: todayTimer
            interval: 1000 * 60 * 60
            running: true
            repeat: true
            onTriggered: {
                fileView.path = Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json"
            }
        }

        function refreshAllData() {
            forceSaveProc.running = true;
            weeklyFetcher.running = true;
            fileView.path = Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json";
        }

        FileView {
            id: fileView
            path: Quickshell.env("HOME") + "/.cache/screentime/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + ".json"
            watchChanges: true
            onLoaded: {
                try {
                    let txt = fileView.text().trim();
                    if (txt.length > 0) {
                        let obj = JSON.parse(txt);
                        
                        let tempWeekly = root.weeklyData;
                        tempWeekly[root.todayIndex] = obj;
                        root.weeklyData = tempWeekly;
                        
                        root.computeWeeklyTotals();
                        root.updateAppStatsForSelectedDay();
                        
                        if (root.selectedApp) {
                            root.computeSelectedAppWeekly();
                        }
                    }
                } catch (e) {
                    console.log("[ScreenTime] parse error", e);
                }
            }
        }

        function getSelectedDate() {
            let today = new Date();
            let currentDayOfWeek = today.getDay(); // 0 = Sun, 1 = Mon ...
            let monIdx = (currentDayOfWeek + 6) % 7; // 0 = Mon ... 6 = Sun
            let diff = root.selectedDayIndex - monIdx;
            let d = new Date(today.getTime() + diff * 86400000);
            return d;
        }

        function getSelectedDayTotalTime() {
            let dayData = root.weeklyData[root.selectedDayIndex] || {};
            if (root.selectedApp) {
                let appRaw = root.selectedApp.rawName;
                return (dayData[appRaw] && dayData[appRaw].time) ? dayData[appRaw].time : 0;
            } else {
                let sum = 0;
                for (let k in dayData) {
                    sum += (dayData[k].time || 0);
                }
                return sum;
            }
        }

        function updateAppStatsForSelectedDay() {
            let dayData = root.weeklyData[root.selectedDayIndex] || {};
            let arr = [];
            let mt = 1;
            let tt = 0;
            for (let key in dayData) {
                let t = dayData[key].time || 0;
                let o = dayData[key].opens || 0;
                arr.push({ name: key, rawName: key, time: t, opens: o, icon: "" });
                if (t > mt) mt = t;
                tt += t;
            }
            arr.sort((a, b) => b.time - a.time);
            root.maxTime = mt;
            root.totalTime = tt;
            root.appStats = arr;
            root.mapIcons();
        }

        function computeWeeklyTotals() {
            let temp = [0,0,0,0,0,0,0];
            let mw = 12 * 3600;
            for (let i = 0; i < 7; i++) {
                let dayObj = root.weeklyData[i] || {};
                let sum = 0;
                for (let k in dayObj) {
                    sum += dayObj[k].time || 0;
                }
                temp[i] = sum;
                if (sum > mw) mw = sum;
            }
            root.weeklyTotals = temp;
            root.maxWeeklyTime = mw;
        }
        
        function computeSelectedAppWeekly() {
            if (!root.selectedApp) return;
            let temp = [0,0,0,0,0,0,0];
            let mw = 1; 
            let searchKey = root.selectedApp.rawName;
            
            for (let i = 0; i < 7; i++) {
                let dayObj = root.weeklyData[i] || {};
                let val = 0;
                if (dayObj[searchKey] !== undefined) {
                    val = dayObj[searchKey].time || 0;
                }
                temp[i] = val;
                if (val > mw) mw = val;
            }
            root.selectedAppWeeklyTotals = temp;
            root.maxSelectedAppWeeklyTime = mw * 1.2; 
        }

        function mapIcons() {
            if (root.appsData.length === 0 || root.appStats.length === 0) return;
            let temp = [];
            for (let i = 0; i < root.appStats.length; i++) {
                let stat = root.appStats[i];
                let foundIcon = "";
                let foundName = stat.name;
                
                let lowerClass = stat.name.toLowerCase();
                for (let j = 0; j < root.appsData.length; j++) {
                    let app = root.appsData[j];
                    if (app.id.toLowerCase().includes(lowerClass) || app.name.toLowerCase().includes(lowerClass) || app.cmd.toLowerCase().includes(lowerClass)) {
                        foundIcon = app.icon;
                        foundName = app.name;
                        break;
                    }
                }
                
                if (lowerClass === "org.quickshell") {
                    foundName = "Quickshell";
                    foundIcon = "quickshell";
                }
                
                temp.push({ 
                    rawName: stat.name,
                    name: foundName, 
                    time: stat.time,
                    opens: stat.opens,
                    icon: foundIcon,
                    fallbackStr: stat.name.charAt(0).toUpperCase()
                });
            }
            root.appStats = temp;
            
            if (root.selectedApp) {
                for (let i = 0; i < temp.length; i++) {
                    if (temp[i].rawName === root.selectedApp.rawName) {
                        root.selectedApp = temp[i];
                        break;
                    }
                }
            }
        }

        function formatTimeDisplay(secs) {
            let m = Math.floor(secs / 60);
            let h = Math.floor(m / 60);
            let remainM = m % 60;
            if (h > 0) {
                return remainM > 0 ? (h + (h === 1 ? " hr, " : " hrs, ") + remainM + " mins") : (h + (h === 1 ? " hr" : " hrs"));
            } else if (remainM > 0) {
                return remainM + (remainM === 1 ? " minute" : " minutes");
            } else {
                return Math.floor(secs) + " seconds";
            }
        }
        
        function formatMinutes(secs) {
            let m = Math.floor(secs / 60);
            if (m === 0 && secs > 0) return "< 1 min";
            if (m >= 60) {
                let h = Math.floor(m / 60);
                let remainM = m % 60;
                if (remainM > 0) {
                    return h + (h === 1 ? " hr " : " hrs ") + remainM + " min";
                } else {
                    return h + (h === 1 ? " hr" : " hrs");
                }
            } else {
                return m + (m === 1 ? " minute" : " minutes");
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ==========================================
            // M3 CARD 1: Hero & Chart Area
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 410 * Appearance.effectiveScale
                color: win.cCard
                radius: 20 * Appearance.effectiveScale
                border.color: win.cCardBorder
                border.width: 1
                clip: true

                // Card Glossy Overlay
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * 0.4
                    radius: parent.radius
                    visible: win.glassmorphism
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Dynamic Header
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20 * Appearance.effectiveScale
                        Layout.bottomMargin: 8 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale

                        DankIcon {
                            name: "arrow_back"
                            size: 24 * Appearance.effectiveScale
                            color: "white"
                            visible: root.selectedApp !== null
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedApp = null
                            }
                        }

                        Rectangle {
                            width: 32 * Appearance.effectiveScale
                            height: 32 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                            color: root.selectedApp && root.selectedApp.icon ? "transparent" : Appearance.colors.colLayer2
                            visible: root.selectedApp !== null
                            
                            Image {
                                anchors.fill: parent
                                source: root.selectedApp ? root.selectedApp.icon : ""
                                sourceSize: Qt.size(64, 64)
                                visible: root.selectedApp && root.selectedApp.icon !== ""
                                antialiasing: true
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: root.selectedApp ? root.selectedApp.fallbackStr : ""
                                font.pixelSize: 16 * Appearance.effectiveScale
                                color: "white"
                                visible: root.selectedApp && root.selectedApp.icon === ""
                            }
                        }

                        Text {
                            text: root.selectedApp ? root.selectedApp.name : "App activity details"
                            font.family: Theme.font.family
                            font.pixelSize: 24 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: "white"
                        }

                        DankIcon {
                            id: appRefreshBtn
                            name: "refresh"
                            size: 22 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.8)
                            property bool spinning: false

                            RotationAnimation on rotation {
                                running: appRefreshBtn.spinning
                                from: 0; to: 360; duration: 1000
                                loops: Animation.Infinite
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    appRefreshBtn.spinning = true;
                                    root.refreshAllData();
                                    appRefreshTimer.restart();
                                }
                            }
                            Timer { id: appRefreshTimer; interval: 1000; onTriggered: appRefreshBtn.spinning = false }
                        }
                    }

                    // Hero Time
                    Text {
                        text: root.selectedApp ? root.formatMinutes(root.getSelectedDayTotalTime()) : root.formatTimeDisplay(root.getSelectedDayTotalTime())
                        font.family: Theme.font.family
                        font.pixelSize: 38 * Appearance.effectiveScale
                        font.weight: Font.Light
                        color: "white"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4 * Appearance.effectiveScale
                    }

                    // Selected Date Subtitle
                    Text {
                        text: root.selectedDayIndex === root.todayIndex ? "Today" : Qt.formatDateTime(root.getSelectedDate(), "ddd, d MMM")
                        font.family: Theme.font.family
                        font.pixelSize: 14 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.6)
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 16 * Appearance.effectiveScale
                    }

                    // Dynamic Chart
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 24 * Appearance.effectiveScale
                        Layout.rightMargin: 24 * Appearance.effectiveScale
                        Layout.bottomMargin: 8 * Appearance.effectiveScale
                        
                        Repeater {
                            model: 5
                            Item {
                                y: parent.height - 20 * Appearance.effectiveScale - (index * ((parent.height - 20 * Appearance.effectiveScale) / 4))
                                width: parent.width
                                
                                Rectangle {
                                    width: parent.width - 30 * Appearance.effectiveScale
                                    height: 1
                                    color: Qt.rgba(255, 255, 255, 0.05)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    property real maxVal: root.selectedApp ? root.maxSelectedAppWeeklyTime : root.maxWeeklyTime
                                    property int divisor: root.selectedApp ? 60 : 3600
                                    property string suffix: root.selectedApp ? "m" : "h"
                                    text: Math.round((index * (maxVal / 4)) / divisor) + suffix
                                    
                                    font.family: Theme.font.family
                                    font.pixelSize: 10 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.4)
                                }
                            }
                        }
                        
                        RowLayout {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 20 * Appearance.effectiveScale
                            anchors.top: parent.top
                            width: parent.width - 40 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale
                            
                            Repeater {
                                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    property bool isSelected: index === root.selectedDayIndex
                                    Rectangle {
                                        id: barRect
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 28 * Appearance.effectiveScale
                                        
                                        property real targetVal: root.selectedApp ? root.selectedAppWeeklyTotals[index] : root.weeklyTotals[index]
                                        property real maxVal: root.selectedApp ? root.maxSelectedAppWeeklyTime : root.maxWeeklyTime
                                        height: targetVal > 0 ? Math.max(4, Math.min(parent.height, parent.height * (targetVal / maxVal))) : 0
                                        visible: targetVal > 0
                                        
                                        color: isSelected ? Theme.primary : Qt.tint("white", Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45))
                                        radius: 6 * Appearance.effectiveScale
                                        
                                        // Bottom square overlay
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: Math.min(barRect.height, 6 * Appearance.effectiveScale)
                                            color: barRect.color
                                        }
                                        
                                        Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                                        Behavior on color { ColorAnimation { duration: 250 } }
                                    }
                                    
                                    Text {
                                        anchors.top: parent.bottom
                                        anchors.topMargin: 6 * Appearance.effectiveScale
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData
                                        font.family: Theme.font.family
                                        font.pixelSize: 10 * Appearance.effectiveScale
                                        font.weight: isSelected ? Font.Bold : Font.Normal
                                        color: isSelected ? "white" : Qt.rgba(255, 255, 255, 0.4)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: index <= root.todayIndex ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (index <= root.todayIndex) {
                                                root.hasUserSelectedDay = true;
                                                root.selectedDayIndex = index;
                                                root.updateAppStatsForSelectedDay();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Date Changer Control (< Date >)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 16 * Appearance.effectiveScale
                        spacing: 24 * Appearance.effectiveScale
                        
                        Item {
                            width: 32 * Appearance.effectiveScale
                            height: 32 * Appearance.effectiveScale
                            DankIcon {
                                anchors.centerIn: parent
                                name: "arrow_back_ios"
                                size: 16 * Appearance.effectiveScale
                                color: root.selectedDayIndex > 0 ? "white" : Qt.rgba(255, 255, 255, 0.2)
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: root.selectedDayIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (root.selectedDayIndex > 0) {
                                        root.hasUserSelectedDay = true;
                                        root.selectedDayIndex--;
                                        root.updateAppStatsForSelectedDay();
                                    }
                                }
                            }
                        }

                        Text {
                            text: Qt.formatDateTime(root.getSelectedDate(), "ddd, d MMM")
                            font.family: Theme.font.family
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: "white"
                        }

                        Item {
                            width: 32 * Appearance.effectiveScale
                            height: 32 * Appearance.effectiveScale
                            DankIcon {
                                anchors.centerIn: parent
                                name: "arrow_forward_ios"
                                size: 16 * Appearance.effectiveScale
                                color: root.selectedDayIndex < root.todayIndex ? "white" : Qt.rgba(255, 255, 255, 0.2)
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: root.selectedDayIndex < root.todayIndex ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (root.selectedDayIndex < root.todayIndex) {
                                        root.hasUserSelectedDay = true;
                                        root.selectedDayIndex++;
                                        root.updateAppStatsForSelectedDay();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // M3 CARD 2: App List Area
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: win.cCard
                radius: 20 * Appearance.effectiveScale
                border.color: win.cCardBorder
                border.width: 1
                clip: true
                
                // Card Glossy Overlay
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * 0.3
                    radius: parent.radius
                    visible: win.glassmorphism
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }
                
                ListView {
                    anchors.fill: parent
                    anchors.margins: 8 * Appearance.effectiveScale
                    model: root.appStats
                    clip: true
                    spacing: 4 * Appearance.effectiveScale
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 64 * Appearance.effectiveScale
                        radius: 12 * Appearance.effectiveScale
                        
                        property bool isSelected: root.selectedApp && root.selectedApp.rawName === modelData.rawName
                        
                        color: isSelected ? Appearance.colors.colLayer3 : (mouseArea.containsMouse ? Appearance.colors.colLayer2 : "transparent")
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            
                            Rectangle {
                                width: 40 * Appearance.effectiveScale
                                height: 40 * Appearance.effectiveScale
                                radius: 10 * Appearance.effectiveScale
                                color: modelData.icon ? "transparent" : Appearance.colors.colLayer3
                                
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                    sourceSize: Qt.size(64, 64)
                                    visible: modelData.icon !== ""
                                    antialiasing: true
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.fallbackStr
                                    font.pixelSize: 20 * Appearance.effectiveScale
                                    color: "white"
                                    visible: modelData.icon === ""
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale
                                
                                Text {
                                    text: modelData.name
                                    font.family: Theme.font.family
                                    font.pixelSize: 16 * Appearance.effectiveScale
                                    font.weight: Font.Medium
                                    color: "white"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: root.formatMinutes(modelData.time)
                                    font.family: Theme.font.family
                                    font.pixelSize: 13 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                }
                            }
                            
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2 * Appearance.effectiveScale
                                
                                Text {
                                    text: modelData.opens
                                    font.family: Theme.font.family
                                    font.pixelSize: 16 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: "white"
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.opens === 1 ? "time" : "times"
                                    font.family: Theme.font.family
                                    font.pixelSize: 10 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (root.selectedApp && root.selectedApp.rawName === modelData.rawName) {
                                    root.selectedApp = null;
                                } else {
                                    root.selectedApp = modelData;
                                    root.computeSelectedAppWeekly();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
