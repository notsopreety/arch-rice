import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../services"

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property bool showWeather: true

    property int winSize: 220
    property int scallops: 12
    property int amplitude: 5
    property bool showNumbers: true
    property bool showTicks: true
    property bool showDayLabel: true
    property bool showDigitalTime: true
    property bool showDateBadge: true
    property bool showSecondHand: true
    property bool showSecondHandLine: true

    property int numberDistOffsetVal: 40
    property int tickDistOffsetVal: 15
    property real hourThicknessVal: 0.07
    property real minuteThicknessVal: 0.05
    property real secondThicknessVal: 0.03
    property real hand1LengthVal: 60
    property real hand2LengthVal: 100
    property real hand3LengthVal: 120

    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") {
            console.log("[Clock] Empty settings file loaded, skipping parse.");
            return;
        }
        try {
            let data = JSON.parse(jsonText);
            let clk = data.clock || {};
            if (clk.isActive !== undefined) root.isActive = clk.isActive;
            if (clk.showWeather !== undefined) root.showWeather = clk.showWeather;
            if (clk.winX !== undefined) root.settingsX = clk.winX;
            if (clk.winY !== undefined) root.settingsY = clk.winY;
            if (clk.winSize !== undefined) root.winSize = clk.winSize;
            if (clk.scallops !== undefined) root.scallops = clk.scallops;
            if (clk.amplitude !== undefined) root.amplitude = clk.amplitude;
            if (clk.showNumbers !== undefined) root.showNumbers = clk.showNumbers;
            if (clk.showTicks !== undefined) root.showTicks = clk.showTicks;
            if (clk.showDayLabel !== undefined) root.showDayLabel = clk.showDayLabel;
            if (clk.showDigitalTime !== undefined) root.showDigitalTime = clk.showDigitalTime;
            if (clk.showDateBadge !== undefined) root.showDateBadge = clk.showDateBadge;
            if (clk.showSecondHand !== undefined) root.showSecondHand = clk.showSecondHand;
            if (clk.showSecondHandLine !== undefined) root.showSecondHandLine = clk.showSecondHandLine;
            if (clk.numberDistOffset !== undefined) root.numberDistOffsetVal = clk.numberDistOffset;
            if (clk.tickDistOffset !== undefined) root.tickDistOffsetVal = clk.tickDistOffset;
            if (clk.hourThickness !== undefined) root.hourThicknessVal = clk.hourThickness;
            if (clk.minuteThickness !== undefined) root.minuteThicknessVal = clk.minuteThickness;
            if (clk.secondThickness !== undefined) root.secondThicknessVal = clk.secondThickness;
            if (clk.hand1Length !== undefined) root.hand1LengthVal = clk.hand1Length;
            if (clk.hand2Length !== undefined) root.hand2LengthVal = clk.hand2Length;
            if (clk.hand3Length !== undefined) root.hand3LengthVal = clk.hand3Length;
            console.log("[Clock] Successfully loaded settings. isActive:", root.isActive, "showWeather:", root.showWeather);
        } catch(e) {
            console.error("Failed to parse settings.json for Clock:", e);
        }
    }

    Timer {
        id: reloadTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: settingsFile.reload()
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true
        
        onLoaded: root.loadSettings(text())
        onFileChanged: reloadTimer.restart()
    }

    Process {
        id: saveSettingsProc
    }
    
    function saveSettings(newX, newY) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "clk = data.setdefault('clock', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("clk['winX'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("clk['winY'] = " + Math.round(newY));
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; " +
               "f = open(tmp, 'w'); " +
               "json.dump(data, f, indent=2); " +
               "f.close(); " +
               "os.replace(tmp, path)";
        
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    // Dynamic Colors: Matugen Theme
    property color bgColor: Theme.primaryContainer
    property color accentColor: Theme.primary
    property color primaryColor: Theme.onPrimaryContainerColor
    property color secondaryColor: Theme.outline
    
    // THE ULTIMATE RESPONSIVE SCALE
    // Everything is calculated as a fraction of winSize.
    readonly property real ratio: winSize / 320.0
    
    property real hourThickness: hourThicknessVal
    property real minuteThickness: minuteThicknessVal
    property real secondThickness: secondThicknessVal
    
    // Convert "pixel" settings to proportional winSize units
    property real hand1Len: (hand1LengthVal / 320.0) * winSize
    property real hand2Len: (hand2LengthVal / 320.0) * winSize
    property real hand3Len: (hand3LengthVal / 320.0) * winSize
    
    property real numOffset: (numberDistOffsetVal / 320.0) * winSize
    property real tickOffset: (tickDistOffsetVal / 320.0) * winSize
    property real ampScaled: (amplitude / 320.0) * winSize

    property bool interactive: true

    width: winSize
    height: winSize
    x: settingsX >= 0 ? settingsX : 10
    y: settingsY >= 0 ? settingsY : 40
    visible: isActive

    // Drag-to-scale micro-animation
    scale: dragArea.pressed ? 0.98 : (dragArea.containsMouse && interactive ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: Theme.anim.durationShort
            easing.bezierCurve: Theme.anim.curve
        }
    }

    // Drag area handler
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: (containsMouse && root.interactive) ? Qt.SizeAllCursor : Qt.ArrowCursor
        
        onReleased: {
            if (drag.active) {
                root.saveSettings(root.x, root.y);
            }
        }
    }

    // Clock Logic
    property var currentTime: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: currentTime = new Date()
    }



    // ── Scalloped Background ──
    Canvas {
        id: clockFace
        anchors.fill: parent
        anchors.margins: winSize * 0.03
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onScallopsChanged() { clockFace.requestPaint() }
            function onAmplitudeChanged() { clockFace.requestPaint() }
            function onWinSizeChanged() { clockFace.requestPaint() }
            function onBgColorChanged() { clockFace.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2;
            var cy = height / 2;
            var radius = Math.min(width, height) / 2 - ampScaled - (winSize * 0.015);

            ctx.beginPath();
            for (var i = 0; i <= 360; i += 0.5) {
                var angle = i * Math.PI / 180;
                var r = radius + ampScaled * Math.cos(scallops * angle);
                var x = cx + r * Math.cos(angle);
                var y = cy + r * Math.sin(angle);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.closePath();
            ctx.fillStyle = bgColor;
            ctx.fill();
        }
    }

    // ── Tick Marks ──
    Repeater {
        model: showTicks ? 60 : 0
        Rectangle {
            required property int index
            property bool isHour: index % 5 == 0
            property real tickAngleRad: index * 6 * Math.PI / 180
            property real displayAngle: tickAngleRad - Math.PI / 2

            property real baseRadius: winSize / 2 - ampScaled - (winSize * 0.03)
            property real dist: baseRadius + ampScaled * Math.cos(scallops * tickAngleRad) - tickOffset

            width: (isHour ? winSize * 0.009 : winSize * 0.003)
            height: (isHour ? winSize * 0.037 : winSize * 0.018)
            color: isHour ? primaryColor : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)
            radius: width / 2

            x: parent.width / 2 + dist * Math.cos(displayAngle) - width / 2
            y: parent.height / 2 + dist * Math.sin(displayAngle) - height / 2

            transform: Rotation {
                origin.x: width / 2
                origin.y: height / 2
                angle: index * 6
            }
        }
    }

    // ── Hour Numbers ──
    Repeater {
        model: showNumbers ? 12 : 0
        Label {
            required property int index
            property real angle: (index + 1) * 30 * Math.PI / 180 - Math.PI / 2
            property real dist: winSize / 2 - ampScaled - numOffset

            x: parent.width / 2 + dist * Math.cos(angle) - width / 2
            y: parent.height / 2 + dist * Math.sin(angle) - height / 2

            text: index + 1
            color: primaryColor
            font.pixelSize: winSize * 0.075
            font.weight: Font.Bold
            font.family: Theme.font.family
        }
    }

    // ── Day Label ──
    Canvas {
        id: dayCanvas
        visible: showDayLabel
        anchors.fill: parent
        anchors.margins: winSize * 0.03
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var cx = width / 2;
            var cy = height / 2;
            var dayText = currentTime.toLocaleDateString(Qt.locale("en_US"), "dddd");

            var textRadius = winSize * 0.22;
            var fontSize = winSize * 0.055;
            ctx.font = "bold " + Math.round(fontSize) + "px '" + Theme.font.family + "'";
            ctx.fillStyle = primaryColor;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            var totalAngle = dayText.length * 0.14;
            var startAngle = -Math.PI / 2 - totalAngle / 2;

            for (var i = 0; i < dayText.length; i++) {
                var charAngle = startAngle + i * (totalAngle / (dayText.length - 1 || 1));
                var charX = cx + textRadius * Math.cos(charAngle);
                var charY = cy + textRadius * Math.sin(charAngle);

                ctx.save();
                ctx.translate(charX, charY);
                ctx.rotate(charAngle + Math.PI / 2);
                ctx.fillText(dayText[i], 0, 0);
                ctx.restore();
            }
        }

        Connections {
            target: root
            function onCurrentTimeChanged() { dayCanvas.requestPaint() }
            function onWinSizeChanged() { dayCanvas.requestPaint() }
            function onPrimaryColorChanged() { dayCanvas.requestPaint() }
        }

        Component.onCompleted: requestPaint()
    }

    // ── Digital Time Display ──
    Item {
        visible: showDigitalTime
        anchors.centerIn: parent
        width: winSize * 0.7
        height: winSize * 0.7

        // Hours
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: winSize * 0.005
            text: {
                var h = currentTime.getHours() % 12;
                if (h === 0) h = 12;
                return (h < 10 ? "0" : "") + h;
            }
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.15)
            font.pixelSize: winSize * 0.32
            font.weight: Font.Black
            font.family: Theme.font.family
        }

        // Minutes
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.verticalCenter
            anchors.topMargin: -winSize * 0.04
            text: {
                var m = currentTime.getMinutes();
                return (m < 10 ? "0" : "") + m;
            }
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.15)
            font.pixelSize: winSize * 0.32
            font.weight: Font.Black
            font.family: Theme.font.family
        }
    }

    // ── Date Badge ──
    Rectangle {
        visible: showDateBadge
        anchors.right: parent.right
        anchors.rightMargin: winSize * 0.14
        anchors.verticalCenter: parent.verticalCenter
        width: winSize * 0.14
        height: winSize * 0.08
        radius: height / 2
        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)

        Text {
            anchors.centerIn: parent
            text: {
                var d = currentTime.getDate();
                return (d < 10 ? "0" : "") + d;
            }
            color: primaryColor
            font.pixelSize: parent.height * 0.7
            font.weight: Font.Bold
            font.family: Theme.font.family
        }
    }

    // ── Clock Hands ──
    Item {
        id: handsContainer
        anchors.centerIn: parent
        width: parent.width; height: parent.height

        // Hand 1 (Hour)
        Rectangle {
            id: hand1
            anchors.horizontalCenter: parent.horizontalCenter
            width: winSize * hourThickness
            height: width + hand1Len
            radius: width / 2
            color: primaryColor
            y: winSize / 2 - height + width / 2
            antialiasing: true
            transform: Rotation {
                origin.x: hand1.width / 2
                origin.y: hand1.height - hand1.width / 2
                angle: (currentTime.getHours() % 12 + currentTime.getMinutes() / 60) * 30
            }
        }

        // Hand 2 (Minute)
        Rectangle {
            id: hand2
            anchors.horizontalCenter: parent.horizontalCenter
            width: winSize * minuteThickness
            height: width + hand2Len
            radius: width / 2
            color: accentColor
            y: winSize / 2 - height + width / 2
            antialiasing: true
            transform: Rotation {
                origin.x: hand2.width / 2
                origin.y: hand2.height - hand2.width / 2
                angle: (currentTime.getMinutes() + currentTime.getSeconds() / 60) * 6
            }
        }

        // Hand 3 (Second)
        Item {
            id: secondHandGroup
            visible: showSecondHand
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            
            transform: Rotation {
                origin.x: winSize / 2
                origin.y: winSize / 2
                angle: currentTime.getSeconds() * 6
            }

            // The Line
            Rectangle {
                visible: showSecondHandLine
                anchors.horizontalCenter: parent.horizontalCenter
                width: winSize * secondThickness
                height: hand3Len
                radius: width / 2
                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.15)
                y: winSize / 2 - height
                antialiasing: true
            }

            // The Dot
            Rectangle {
                visible: !showSecondHandLine
                anchors.horizontalCenter: parent.horizontalCenter
                width: winSize * secondThickness * 2.5
                height: width
                radius: width / 2
                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.25)
                y: winSize / 2 - hand3Len - height / 2
                antialiasing: true
            }
        }

        // Center Pin
        Rectangle {
            anchors.centerIn: parent
            width: winSize * 0.04
            height: width
            radius: width / 2
            color: accentColor
        }
    }

    Column {
        visible: root.showWeather
        anchors.top: parent.bottom
        anchors.topMargin: 16 * root.ratio
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6 * root.ratio
        
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8 * root.ratio
            
            Image {
                width: 44 * root.ratio
                height: 44 * root.ratio
                fillMode: Image.PreserveAspectFit
                source: "file:///home/sawmer/.config/quickshell/assets/google-weather/" + WeatherService.googleIcon
            }
            
            Text {
                text: Math.round(WeatherService.temp) + "°"
                font.pixelSize: 36 * root.ratio
                font.weight: Font.DemiBold
                color: Theme.onSurfaceColor
                font.family: Theme.font.family
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        Text {
            text: WeatherService.condition
            font.pixelSize: 16 * root.ratio
            font.weight: Font.Normal
            color: Theme.outline
            font.family: Theme.font.family
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
