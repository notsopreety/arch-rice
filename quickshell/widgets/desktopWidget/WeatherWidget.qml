import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects as GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../core"
import "../../theme"
import "../../components"
import "../../services"
import "../widgetCanvas"

Item {
    id: root

    property int settingsX: -1
    property int settingsY: -1
    property bool isActive: true
    property int styleMode: 1 // 1: Small, 2: Medium, 3: Large
    property int shapeMode: 1 // 1: Diagonal Organic Pebble, 2: Horizontal Pill Stadium

    property real customWidth: -1
    property real customHeight: -1

    // ── Glassmorphism Toggle ─────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); } catch(e) {} }
        onLoaded: root.glassmorphism = true
        onLoadFailed: root.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    function getNaturalWidth(shape, style) {
        if (shape === 11) { // Wave Temp Curve Timeline Card (Reference UI)
            return (style === 1 ? 330 : (style === 2 ? 370 : 420)) * Appearance.effectiveScale;
        } else if (shape === 10) { // Minimal Hourly Forecast Card
            return (style === 1 ? 330 : (style === 2 ? 370 : 420)) * Appearance.effectiveScale;
        } else if (shape === 9) { // Material Cookie Scalloped Card
            return (style === 1 ? 185 : (style === 2 ? 215 : 255)) * Appearance.effectiveScale;
        } else if (shape === 8) { // Humidity & Dew Point Card
            return (style === 1 ? 160 : (style === 2 ? 185 : 220)) * Appearance.effectiveScale;
        } else if (shape === 7) { // Circular Satellite Pill Card
            return (style === 1 ? 180 : (style === 2 ? 210 : 250)) * Appearance.effectiveScale;
        } else if (shape === 6) { // Sunrise & Sunset Square Card
            return (style === 1 ? 175 : (style === 2 ? 205 : 245)) * Appearance.effectiveScale;
        } else if (shape === 5) { // Compact Inverted Square Card
            return (style === 1 ? 165 : (style === 2 ? 195 : 230)) * Appearance.effectiveScale;
        } else if (shape === 4) { // Compact Rounded Square Card
            return (style === 1 ? 180 : (style === 2 ? 210 : 250)) * Appearance.effectiveScale;
        } else if (shape === 3) { // Minimal Stadium Capsule Pill
            return (style === 1 ? 165 : (style === 2 ? 195 : 235)) * Appearance.effectiveScale;
        } else if (shape === 2) { // Cookie Badge Stadium Pill
            return (style === 1 ? 340 : (style === 2 ? 410 : 480)) * Appearance.effectiveScale;
        } else { // Detailed Forecast Card (Reference UI)
            return (style === 1 ? 380 : (style === 2 ? 430 : 490)) * Appearance.effectiveScale;
        }
    }

    function getNaturalHeight(shape, style) {
        if (shape === 11) { // Wave Temp Curve Timeline Card (Reference UI)
            return (style === 1 ? 180 : (style === 2 ? 200 : 225)) * Appearance.effectiveScale;
        } else if (shape === 10) { // Minimal Hourly Forecast Card
            return (style === 1 ? 165 : (style === 2 ? 185 : 210)) * Appearance.effectiveScale;
        } else if (shape === 9) { // Material Cookie Scalloped Card
            return (style === 1 ? 185 : (style === 2 ? 215 : 255)) * Appearance.effectiveScale;
        } else if (shape === 8) { // Humidity & Dew Point Card
            return (style === 1 ? 165 : (style === 2 ? 195 : 230)) * Appearance.effectiveScale;
        } else if (shape === 7) { // Circular Satellite Pill Card
            return (style === 1 ? 180 : (style === 2 ? 210 : 250)) * Appearance.effectiveScale;
        } else if (shape === 6) { // Sunrise & Sunset Square Card
            return (style === 1 ? 175 : (style === 2 ? 205 : 245)) * Appearance.effectiveScale;
        } else if (shape === 5) { // Compact Inverted Square Card
            return (style === 1 ? 170 : (style === 2 ? 200 : 235)) * Appearance.effectiveScale;
        } else if (shape === 4) { // Compact Rounded Square Card
            return (style === 1 ? 180 : (style === 2 ? 210 : 250)) * Appearance.effectiveScale;
        } else if (shape === 3) { // Minimal Stadium Capsule Pill
            return (style === 1 ? 72 : (style === 2 ? 84 : 98)) * Appearance.effectiveScale;
        } else if (shape === 2) { // Cookie Badge Stadium Pill
            return (style === 1 ? 115 : (style === 2 ? 140 : 165)) * Appearance.effectiveScale;
        } else { // Detailed Forecast Card (Reference UI)
            return (style === 1 ? 185 : (style === 2 ? 210 : 240)) * Appearance.effectiveScale;
        }
    }

    // Responsive Dimensions based on shapeMode and styleMode
    readonly property real baseWidth: getNaturalWidth(root.shapeMode, root.styleMode)
    readonly property real baseHeight: getNaturalHeight(root.shapeMode, root.styleMode)

    width: customWidth > 0 ? (customWidth * Appearance.effectiveScale) : baseWidth
    height: customHeight > 0 ? (customHeight * Appearance.effectiveScale) : baseHeight

    x: settingsX >= 0 ? settingsX : 260
    y: settingsY >= 0 ? settingsY : (Appearance.sizes.screen.height - height - 120)

    visible: isActive

    Behavior on width { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { enabled: typeof resizeFrame !== 'undefined' && resizeFrame ? !resizeFrame.isResizing : true; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // Dynamic Matugen Theme Colors & Glassmorphism UI Support (Matching ScreenTimeWidget & Clock)
    property color containerBg: root.glassmorphism 
        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.40) 
        : Theme.surfaceContainer

    property color strokeColor: root.glassmorphism 
        ? Qt.rgba(1, 1, 1, 0.32) 
        : Theme.outline

    property color textColor: Theme.primary

    Behavior on containerBg { ColorAnimation { duration: 400 } }
    Behavior on strokeColor { ColorAnimation { duration: 400 } }
    Behavior on textColor { ColorAnimation { duration: 400 } }

    // Load Settings from settings.json
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") return;
        try {
            let data = JSON.parse(jsonText);
            let w = data.weatherWidget || data.weather || {};
            if (w.isActive !== undefined) root.isActive = w.isActive;
            if (w.winX !== undefined) root.settingsX = w.winX;
            else if (w.weatherX !== undefined) root.settingsX = w.weatherX;
            
            if (w.winY !== undefined) root.settingsY = w.winY;
            else if (w.weatherY !== undefined) root.settingsY = w.weatherY;
            
            if (w.styleMode !== undefined) root.styleMode = w.styleMode;
            if (w.shapeMode !== undefined) root.shapeMode = w.shapeMode;
            if (w.width !== undefined) root.customWidth = w.width;
            if (w.height !== undefined) root.customHeight = w.height;
        } catch(e) {
            console.log("[WeatherWidget] Error loading settings:", e);
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
        running: false
    }

    function saveSettings(newX, newY, newStyle, newShape, newActive, newW, newH) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "w = data.setdefault('weatherWidget', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("w['winX'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("w['winY'] = " + Math.round(newY));
        if (newStyle !== undefined) updates.push("w['styleMode'] = " + Math.round(newStyle));
        if (newShape !== undefined) updates.push("w['shapeMode'] = " + Math.round(newShape));
        if (newActive !== undefined) updates.push("w['isActive'] = " + (newActive ? "True" : "False"));
        if (newW !== undefined && newW > 0) updates.push("w['width'] = " + Math.round(newW));
        else if (newW === -1) updates.push("w.pop('width', None)");
        if (newH !== undefined && newH > 0) updates.push("w['height'] = " + Math.round(newH));
        else if (newH === -1) updates.push("w.pop('height', None)");
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; " +
               "f = open(tmp, 'w'); " +
               "json.dump(data, f, indent=2); " +
               "f.close(); os.replace(tmp, path)";
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }

    Process {
        id: openWeatherProc
        command: ["quickshell", "ipc", "call", "quickshell", "run", "weather"]
        running: false
    }

    // 1-Minute Auto-Update Timer
    Timer {
        id: autoUpdateTimer
        interval: 1 * 60 * 1000 // 1 minute
        running: true
        repeat: true
        onTriggered: {
            WeatherService.updateWeather();
        }
    }

    // Refresh Rotation Animation Helper
    property bool isRefreshing: false
    function refreshData() {
        root.isRefreshing = true;
        WeatherService.updateWeather();
        refreshStopTimer.restart();
    }

    Timer {
        id: refreshStopTimer
        interval: 1200
        repeat: false
        onTriggered: root.isRefreshing = false
    }

    // Drag Scale Dynamics
    scale: dragArea.pressed ? 0.97 : (dragArea.containsMouse ? 1.03 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    function getForecastItem(dayOffset) {
        if (WeatherService.forecast && WeatherService.forecast.length > dayOffset) {
            let f = WeatherService.forecast[dayOffset];
            let dayName = "Day";
            if (f.date) {
                try {
                    let d = new Date(f.date + "T00:00:00");
                    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                    dayName = days[d.getDay()];
                } catch(e) {
                    dayName = f.day || "Day";
                }
            } else {
                dayName = f.day || "Day";
            }
            return {
                day: dayName,
                min: f.tempMin !== undefined ? Math.round(f.tempMin) + "°" : Math.round(WeatherService.temp - 4) + "°",
                max: f.tempMax !== undefined ? Math.round(f.tempMax) + "°" : Math.round(WeatherService.temp + 3) + "°"
            };
        }
        let now = new Date();
        now.setDate(now.getDate() + dayOffset);
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return {
            day: days[now.getDay()],
            min: Math.round(WeatherService.temp - (3 + dayOffset)) + "°",
            max: Math.round(WeatherService.temp + (4 - dayOffset)) + "°"
        };
    }

    // ── Main Card: Rounded Rectangle Layout Matching Reference UI ──
    Rectangle {
        id: card
        anchors.fill: parent
        radius: shapeMode === 7 ? (Math.min(width, height) / 2) : ((root.shapeMode === 2 || root.shapeMode === 3) ? (height / 2) : ((root.shapeMode === 4 || root.shapeMode === 5 || root.shapeMode === 6 || root.shapeMode === 8) ? Math.min(26 * Appearance.effectiveScale, height * 0.18) : Math.min(28 * Appearance.effectiveScale, height * 0.15)))
        color: root.shapeMode === 9 ? "transparent" : root.containerBg
        border.color: "transparent"
        border.width: 0
        clip: shapeMode === 8 ? true : false

        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        // Glassmorphic Gradient Overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: root.glassmorphism && root.shapeMode !== 9
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        // ── UI Style 1: Detailed Forecast Card with Squiggly Divider ──
        Item {
            anchors.fill: parent
            anchors.margins: Math.round(card.height * 0.09)
            visible: root.shapeMode === 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Left Column: City, Temp, Weather Icon & 3-Day Forecast ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: 10 * Appearance.effectiveScale

                    // Top Left Area: City + Big Temp (Left) and Weather Art Icon (Right)
                    Item {
                        id: leftTopArea
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: Math.round(parent.height * 0.48)

                        ColumnLayout {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            spacing: 0

                            Text {
                                text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "New York"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(12, Math.round(Math.min(card.height * 0.082, card.width * 0.045)))
                                font.weight: Font.Normal
                                color: Theme.onSurfaceColor
                                opacity: 0.95
                                elide: Text.ElideRight
                                Layout.maximumWidth: Math.max(50, leftTopArea.width - mainWeatherIcon.width - 12)
                                renderType: Text.NativeRendering
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                text: Math.round(WeatherService.temp) + "°"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(22, Math.round(Math.min(card.height * 0.20, card.width * 0.12)))
                                font.weight: Font.Bold
                                color: Theme.onSurfaceColor
                                renderType: Text.NativeRendering
                            }
                        }

                        Image {
                            id: mainWeatherIcon
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 6 * Appearance.effectiveScale
                            }
                            readonly property real idealSize: Math.min(leftTopArea.height * 0.88, leftTopArea.width * 0.45)
                            width: Math.max(30, Math.round(idealSize))
                            height: width
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            source: {
                                let iconName = WeatherService.googleIcon;
                                if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                                return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                            }
                        }
                    }

                    // Bottom Left Area: 3-Day Forecast List
                    ColumnLayout {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: Math.round(parent.height * 0.44)
                        spacing: 0

                        Repeater {
                            model: [1, 2, 3]

                            delegate: RowLayout {
                                required property int modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                readonly property var forecastItem: root.getForecastItem(modelData)

                                Text {
                                    text: forecastItem.day
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.070))
                                    font.weight: Font.Normal
                                    color: Theme.onSurfaceColor
                                    opacity: 0.90
                                    Layout.preferredWidth: 42 * Appearance.effectiveScale
                                    renderType: Text.NativeRendering
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: forecastItem.min
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.070))
                                    font.weight: Font.Normal
                                    color: Theme.onSurfaceVariantColor
                                    opacity: 0.75
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: " " + forecastItem.max
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.070))
                                    font.weight: Font.Normal
                                    color: Theme.onSurfaceColor
                                    opacity: 0.95
                                    renderType: Text.NativeRendering
                                }
                            }
                        }
                    }
                }

                // ── Center Vertical Squiggly / Wavy Divider ──
                Canvas {
                    id: wavyDivider
                    Layout.preferredWidth: 20 * Appearance.effectiveScale
                    Layout.fillHeight: true
                    Layout.topMargin: 4 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: Theme
                        function onJsonDataChanged() { wavyDivider.requestPaint(); }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);

                        var cx = width / 2;
                        var amplitude = 3.2 * Appearance.effectiveScale;
                        var totalHeight = height;
                        var waves = 4.5;
                        var lineWidth = 2.0 * Appearance.effectiveScale;

                        ctx.strokeStyle = Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.40);
                        ctx.lineWidth = lineWidth;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();

                        for (var y = lineWidth; y <= totalHeight - lineWidth; y += 1) {
                            var progress = (y - lineWidth) / (totalHeight - 2 * lineWidth);
                            var x = cx + amplitude * Math.sin(progress * waves * 2 * Math.PI);
                            if (y === lineWidth) ctx.moveTo(x, y);
                            else ctx.lineTo(x, y);
                        }
                        ctx.stroke();
                    }
                }

                // ── Right Column: Vertical List of Weather Details ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 12 * Appearance.effectiveScale

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: 2 * Appearance.effectiveScale
                        anchors.bottomMargin: 2 * Appearance.effectiveScale
                        spacing: 0

                        Text {
                            text: WeatherService.condition || "Sunny"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(13, Math.round(card.height * 0.082))
                            font.weight: Font.DemiBold
                            color: Theme.onSurfaceColor
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Feels like " + (WeatherService.feelsLike ? Math.round(WeatherService.feelsLike) : Math.round(WeatherService.temp)) + "°"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(card.height * 0.068))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "High: " + (WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp + 3)) + "°  |  Low: " + (WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 4)) + "°"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(card.height * 0.068))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Precipitation: " + (WeatherService.precipitationProbability || 0) + "%"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(card.height * 0.068))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Humidity: " + (WeatherService.humidity || 0) + "%"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(card.height * 0.068))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Wind: " + (WeatherService.wind ? Math.round(WeatherService.wind) : 0) + " km/h"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(card.height * 0.068))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }

        // ── UI Style 2: Horizontal Stadium Pill with Rotating Cookie Badge ──
        Item {
            id: stadiumContent
            anchors.fill: parent
            visible: root.shapeMode === 2

            // Right Block: Material Cookie Badge Accent (cookie_12 Shape)
            Item {
                id: cookieBadge
                anchors {
                    right: parent.right
                    rightMargin: Math.round(card.height * 0.14)
                    verticalCenter: parent.verticalCenter
                }
                width: Math.round(card.height * 0.72)
                height: Math.round(card.height * 0.72)

                MaterialShape {
                    id: cookieShapeItem
                    anchors.fill: parent
                    shape: "cookie_12"
                    color: Qt.rgba(Theme.primary.r * 0.45 + Theme.surfaceContainer.r * 0.55, Theme.primary.g * 0.45 + Theme.surfaceContainer.g * 0.55, Theme.primary.b * 0.45 + Theme.surfaceContainer.b * 0.55, 0.95)
                    borderWidth: 0
                    borderColor: "transparent"

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 18000
                        loops: Animation.Infinite
                        running: root.visible && root.shapeMode === 2
                    }
                }

                // Content inside Material Cookie Badge
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        width: Math.round(cookieBadge.height * 0.30)
                        height: Math.round(cookieBadge.height * 0.30)
                        sourceSize.width: Math.round(cookieBadge.height * 0.30)
                        sourceSize.height: Math.round(cookieBadge.height * 0.30)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(WeatherService.temp) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(cookieBadge.height * 0.18)
                        font.weight: Font.Normal
                        color: "#ffffff"
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Center Divider: Smooth Bar Pill Divider Line
            Rectangle {
                id: dividerLine
                anchors {
                    right: cookieBadge.left
                    rightMargin: Math.round(card.width * 0.04)
                    verticalCenter: parent.verticalCenter
                }
                width: Math.max(1, Math.round(2 * Appearance.effectiveScale))
                height: Math.round(card.height * 0.38)
                radius: width / 2
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.25)
            }

            // Left Block: High/Low Temperatures + Weather Condition (Clean & Non-Bold)
            ColumnLayout {
                anchors {
                    left: parent.left
                    leftMargin: Math.round(card.height * 0.38)
                    right: dividerLine.left
                    rightMargin: Math.round(card.width * 0.03)
                    verticalCenter: parent.verticalCenter
                }
                spacing: Math.round(card.height * 0.03)

                // Top Line: "Today Low° / High°"
                Text {
                    text: "Today " + (WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 4)) + "° / " + (WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp + 3)) + "°"
                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                    font.pixelSize: Math.round(card.height * 0.14)
                    font.weight: Font.Normal
                    color: root.textColor
                    renderType: Text.NativeRendering
                    Layout.alignment: Qt.AlignLeft
                }

                // Bottom Line: Small Condition Icon + Condition Text
                RowLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignLeft

                    Image {
                        width: Math.round(card.height * 0.12)
                        height: Math.round(card.height * 0.12)
                        Layout.preferredWidth: Math.round(card.height * 0.12)
                        Layout.preferredHeight: Math.round(card.height * 0.12)
                        sourceSize.width: Math.round(card.height * 0.12)
                        sourceSize.height: Math.round(card.height * 0.12)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        Layout.alignment: Qt.AlignVCenter
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_night.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Text {
                        text: WeatherService.condition || "Mostly cloudy"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.round(card.height * 0.13)
                        font.weight: Font.Normal
                        color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.85)
                        renderType: Text.NativeRendering
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ── UI Style 3: Minimal Stadium Pill (Weather Art Icon + Big Temp) ──
        Item {
            id: minimalPillContent
            anchors.fill: parent
            visible: root.shapeMode === 3

            RowLayout {
                anchors.centerIn: parent
                spacing: Math.max(4, Math.round(Math.min(card.height, card.width * 0.45) * 0.14))

                Image {
                    Layout.alignment: Qt.AlignVCenter
                    readonly property real idealSize: Math.min(card.height * 0.68, card.width * 0.38)
                    width: Math.max(22, Math.round(idealSize))
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                    source: {
                        let iconName = WeatherService.googleIcon;
                        if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                        return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Math.round(WeatherService.temp) + "°"
                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                    font.pixelSize: Math.max(13, Math.round(Math.min(card.height * 0.42, card.width * 0.28)))
                    font.weight: Font.Bold
                    color: Theme.onSurfaceColor
                    renderType: Text.NativeRendering
                }
            }
        }

        // ── UI Style 4: Compact Rounded Square Card (City + Temp + Icon Top, Details Bottom) ──
        Item {
            id: squareCardContent
            anchors.fill: parent
            anchors.margins: Math.round(Math.min(card.width, card.height) * 0.11)
            visible: root.shapeMode === 4

            ColumnLayout {
                anchors.fill: parent
                spacing: Math.max(3, Math.round(card.height * 0.04))

                // Top Area: (City + Big Temp) on Left, Weather Art Icon on Right
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.round(parent.height * 0.46)

                    ColumnLayout {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        spacing: 0

                        Text {
                            text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "New York"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(Math.min(card.height, card.width) * 0.080))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceColor
                            opacity: 0.95
                            elide: Text.ElideRight
                            Layout.maximumWidth: Math.max(40, squareCardContent.width - squareIcon.width - 12)
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: Math.round(WeatherService.temp) + "°"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(22, Math.round(Math.min(card.height, card.width) * 0.22))
                            font.weight: Font.Bold
                            color: Theme.onSurfaceColor
                            renderType: Text.NativeRendering
                        }
                    }

                    Image {
                        id: squareIcon
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        readonly property real idealSize: Math.min(parent.height * 0.95, parent.width * 0.44)
                        width: Math.max(32, Math.round(idealSize))
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }
                }

                Item { Layout.preferredHeight: Math.max(1, Math.round(card.height * 0.02)) }

                // Bottom Details Area
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.max(2, Math.round(card.height * 0.02))

                    Text {
                        text: WeatherService.condition || "Sunny"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(Math.min(card.height, card.width) * 0.080))
                        font.weight: Font.DemiBold
                        color: Theme.onSurfaceColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "Precipitation: " + (WeatherService.precipitationProbability || 0) + "%"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(10, Math.round(Math.min(card.height, card.width) * 0.068))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.90
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "Humidity: " + (WeatherService.humidity || 0) + "%"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(10, Math.round(Math.min(card.height, card.width) * 0.068))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.90
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "Wind: " + (WeatherService.wind ? Math.round(WeatherService.wind) : 0) + " km/h"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(10, Math.round(Math.min(card.height, card.width) * 0.068))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.90
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        // ── UI Style 5: Compact Inverted Square (Icon + City/Condition Top, Temp + Low/High Bottom) ──
        Item {
            id: compactInvertedContent
            anchors.fill: parent
            anchors.margins: Math.round(Math.min(card.width, card.height) * 0.12)
            visible: root.shapeMode === 5

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Top Row: Weather Art Icon (Left) and City + Condition (Right)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(compactInvertedContent.height * 0.42)
                    spacing: 8

                    Image {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        readonly property real idealSize: Math.min(compactInvertedContent.height * 0.42, compactInvertedContent.width * 0.42)
                        width: Math.max(30, Math.round(idealSize))
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        spacing: 2

                        Text {
                            text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "New York"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(11, Math.round(Math.min(card.height, card.width) * 0.082))
                            font.weight: Font.DemiBold
                            color: Theme.onSurfaceColor
                            opacity: 0.95
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: WeatherService.condition || "Sunny"
                            font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                            font.pixelSize: Math.max(10, Math.round(Math.min(card.height, card.width) * 0.072))
                            font.weight: Font.Normal
                            color: Theme.onSurfaceVariantColor
                            opacity: 0.90
                            horizontalAlignment: Text.AlignRight
                            Layout.alignment: Qt.AlignRight
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Bottom Area: Large Temp & Low/High
                ColumnLayout {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                    spacing: 2

                    Text {
                        text: Math.round(WeatherService.temp) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(26, Math.round(Math.min(card.height, card.width) * 0.24))
                        font.weight: Font.Bold
                        color: Theme.onSurfaceColor
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: (WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 3)) + "°  " + (WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp)) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(Math.min(card.height, card.width) * 0.076))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.85
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // UI STYLE 6: Sunrise & Sunset Squircle Card
        // ══════════════════════════════════════════════════════════════════
        Item {
            id: sunriseSunsetContent
                anchors.fill: parent
                visible: root.shapeMode === 6

                readonly property real contentPad: Math.max(14 * Appearance.effectiveScale, Math.min(card.width, card.height) * 0.10)
                readonly property real sunCircleSize: Math.max(34 * Appearance.effectiveScale, Math.min(card.width, card.height) * 0.26)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: sunriseSunsetContent.contentPad
                    spacing: 0

                    // ── Top Section: Sunrise (Sun on left, Sunrise info on right) ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12 * Appearance.effectiveScale

                        // Golden Morning Sun
                        Rectangle {
                            Layout.preferredWidth: sunriseSunsetContent.sunCircleSize
                            Layout.preferredHeight: sunriseSunsetContent.sunCircleSize
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ffca28" }
                                GradientStop { position: 1.0; color: "#f57f17" }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Sunrise Label & Time
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            spacing: 2 * Appearance.effectiveScale

                            Text {
                                text: "Sunrise"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(13, Math.round(Math.min(card.width, card.height) * 0.095))
                                font.weight: Font.DemiBold
                                color: Theme.onSurfaceColor
                                horizontalAlignment: Text.AlignRight
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: WeatherService.sunrise ? WeatherService.sunrise : "6:30 AM"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(11, Math.round(Math.min(card.width, card.height) * 0.080))
                                font.weight: Font.Normal
                                color: Theme.onSurfaceVariantColor
                                opacity: 0.90
                                horizontalAlignment: Text.AlignRight
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    // ── Center Horizontal Squiggly / Wavy Divider ──
                    Canvas {
                        id: wavyHorizontalDivider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignVCenter

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        Connections {
                            target: Theme
                            function onJsonDataChanged() { wavyHorizontalDivider.requestPaint(); }
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.clearRect(0, 0, width, height);

                            var cy = height / 2;
                            var amplitude = 3.0 * Appearance.effectiveScale;
                            var totalWidth = width;
                            var waves = 5.5;
                            var lineWidth = 2.0 * Appearance.effectiveScale;

                            ctx.strokeStyle = Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.40);
                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.beginPath();

                            for (var x = lineWidth; x <= totalWidth - lineWidth; x += 1) {
                                var progress = (x - lineWidth) / (totalWidth - 2 * lineWidth);
                                var y = cy + amplitude * Math.sin(progress * waves * 2 * Math.PI);
                                if (x === lineWidth) ctx.moveTo(x, y);
                                else ctx.lineTo(x, y);
                            }
                            ctx.stroke();
                        }
                    }

                    // ── Bottom Section: Sunset (Sunset info on left, Sunset sun on right) ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12 * Appearance.effectiveScale

                        // Sunset Label & Time
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                            spacing: 2 * Appearance.effectiveScale

                            Text {
                                text: "Sunset"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(13, Math.round(Math.min(card.width, card.height) * 0.095))
                                font.weight: Font.DemiBold
                                color: Theme.onSurfaceColor
                                horizontalAlignment: Text.AlignLeft
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: WeatherService.sunset ? WeatherService.sunset : "7:00 PM"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(11, Math.round(Math.min(card.width, card.height) * 0.080))
                                font.weight: Font.Normal
                                color: Theme.onSurfaceVariantColor
                                opacity: 0.90
                                horizontalAlignment: Text.AlignLeft
                                renderType: Text.NativeRendering
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Warm Reddish-Orange Evening Sun
                        Rectangle {
                            Layout.preferredWidth: sunriseSunsetContent.sunCircleSize
                            Layout.preferredHeight: sunriseSunsetContent.sunCircleSize
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ff7043" }
                                GradientStop { position: 1.0; color: "#d84315" }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // UI STYLE 7: Circular Satellite Pill Card (Today / New York / Sunny)
            // ══════════════════════════════════════════════════════════════════
            Item {
                id: circularSatelliteContent
                anchors.fill: parent
                visible: root.shapeMode === 7

                readonly property real baseDim: Math.min(card.width, card.height)
                readonly property real pillSize: Math.max(48 * Appearance.effectiveScale, baseDim * 0.35)
                readonly property real pillRadius: Math.max(14 * Appearance.effectiveScale, pillSize * 0.32)

                // ── Center Text Stack: Today / City / Condition ──
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2 * Appearance.effectiveScale

                    Text {
                        text: "Today"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(circularSatelliteContent.baseDim * 0.076))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.85
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "New York"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(16, Math.round(circularSatelliteContent.baseDim * 0.125))
                        font.weight: Font.Medium
                        color: Theme.onSurfaceColor
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: Math.round(circularSatelliteContent.baseDim * 0.72)
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: WeatherService.condition || "Sunny"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(circularSatelliteContent.baseDim * 0.076))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.90
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        renderType: Text.NativeRendering
                    }
                }

                // ── Top-Right Pill: Temperature ──
                Rectangle {
                    id: tempPill
                    width: circularSatelliteContent.pillSize
                    height: circularSatelliteContent.pillSize
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Math.round(circularSatelliteContent.baseDim * 0.05)
                    anchors.rightMargin: Math.round(circularSatelliteContent.baseDim * 0.05)
                    radius: circularSatelliteContent.pillRadius
                    color: Theme.surfaceContainerHighest
                    border.color: "transparent"
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: Math.round(WeatherService.temp) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(15, Math.round(circularSatelliteContent.pillSize * 0.38))
                        font.weight: Font.Bold
                        color: Theme.onSurfaceColor
                        renderType: Text.NativeRendering
                    }
                }

                // ── Bottom-Left Pill: Weather Art / Condition Icon ──
                Rectangle {
                    id: iconPill
                    width: circularSatelliteContent.pillSize
                    height: circularSatelliteContent.pillSize
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.bottomMargin: Math.round(circularSatelliteContent.baseDim * 0.05)
                    anchors.leftMargin: Math.round(circularSatelliteContent.baseDim * 0.05)
                    radius: circularSatelliteContent.pillRadius
                    color: Theme.surfaceContainerHighest
                    border.color: "transparent"
                    border.width: 0

                    Image {
                        anchors.centerIn: parent
                        width: Math.round(circularSatelliteContent.pillSize * 0.62)
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // UI STYLE 8: Humidity & Dew Point Card (Cookie Badge + Bottom Highlight)
            // ══════════════════════════════════════════════════════════════════
            Item {
                id: humidityCardContent
                anchors.fill: parent
                visible: root.shapeMode === 8

                readonly property real baseDim: Math.min(card.width, card.height)
                readonly property real contentPad: Math.max(14 * Appearance.effectiveScale, baseDim * 0.10)
                readonly property real cookieSize: Math.max(36 * Appearance.effectiveScale, baseDim * 0.28)

                // Dew point calculation: Td ≈ T - ((100 - RH) / 5)
                readonly property int dewPointVal: {
                    let h = WeatherService.humidity > 0 ? WeatherService.humidity : 25;
                    let t = WeatherService.temp;
                    return Math.round(t - ((100 - h) / 5));
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Top Section: Cookie Badge with droplet icon + Humidity & Dew Point labels
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: humidityCardContent.contentPad
                        Layout.rightMargin: humidityCardContent.contentPad
                        Layout.topMargin: humidityCardContent.contentPad
                        Layout.bottomMargin: Math.max(4 * Appearance.effectiveScale, Math.round(humidityCardContent.contentPad * 0.4))

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 4 * Appearance.effectiveScale

                            // 12-sided Material Cookie Badge with Water Droplet Icon
                            Item {
                                Layout.preferredWidth: humidityCardContent.cookieSize
                                Layout.preferredHeight: humidityCardContent.cookieSize
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop

                                MaterialShape {
                                    id: humidityCookieShape
                                    anchors.fill: parent
                                    shape: "cookie_12"
                                    color: Qt.rgba(Theme.primary.r * 0.35 + Theme.surfaceContainerHighest.r * 0.65,
                                                   Theme.primary.g * 0.35 + Theme.surfaceContainerHighest.g * 0.65,
                                                   Theme.primary.b * 0.35 + Theme.surfaceContainerHighest.b * 0.65, 0.90)
                                    borderWidth: 0
                                    borderColor: "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰖌"
                                    font.family: "Material Design Icons, Symbols Nerd Font, " + Theme.font.family
                                    font.pixelSize: Math.max(16, Math.round(humidityCardContent.cookieSize * 0.50))
                                    color: Theme.onSurfaceColor
                                    renderType: Text.NativeRendering
                                }
                            }

                            Item { Layout.fillHeight: true }

                            // "Humidity" and "<dew_point>° Dew Point"
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                                spacing: 1 * Appearance.effectiveScale

                                Text {
                                    text: "Humidity"
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(12, Math.round(humidityCardContent.baseDim * 0.090))
                                    font.weight: Font.DemiBold
                                    color: Theme.onSurfaceColor
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: humidityCardContent.dewPointVal + "° Dew Point"
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(10, Math.round(humidityCardContent.baseDim * 0.072))
                                    font.weight: Font.Normal
                                    color: Theme.onSurfaceVariantColor
                                    opacity: 0.90
                                    renderType: Text.NativeRendering
                                }
                            }
                        }
                    }

                    // Bottom Section: Distinct Highlight Container with Bold Humidity Percentage
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(38 * Appearance.effectiveScale, Math.round(card.height * 0.35))

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHighest
                            bottomLeftRadius: card.radius
                            bottomRightRadius: card.radius

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: humidityCardContent.contentPad
                                anchors.verticalCenter: parent.verticalCenter
                                text: (WeatherService.humidity > 0 ? Math.round(WeatherService.humidity) : 25) + "%"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(22, Math.round(parent.height * 0.68))
                                font.weight: Font.Bold
                                color: Theme.onSurfaceColor
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // UI STYLE 9: Material Cookie Scalloped Card (Full cookie_12 shape)
            // ══════════════════════════════════════════════════════════════════
            Item {
                id: cookieScallopContent
                anchors.fill: parent
                visible: root.shapeMode === 9

                readonly property real baseDim: Math.min(card.width, card.height)

                // Background 12-sided Material Cookie Shape
                MaterialShape {
                    id: cookieBackgroundShape
                    anchors.centerIn: parent
                    width: cookieScallopContent.baseDim
                    height: cookieScallopContent.baseDim
                    shape: "cookie_12"
                    color: root.glassmorphism
                        ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.50)
                        : root.containerBg
                    borderColor: "transparent"
                    borderWidth: 0
                }

                // Inner Content centered in the Cookie
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2 * Appearance.effectiveScale

                    // Weather Art Icon
                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        readonly property real iconSize: Math.max(38 * Appearance.effectiveScale, cookieScallopContent.baseDim * 0.36)
                        width: Math.round(iconSize)
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        source: {
                            let iconName = WeatherService.googleIcon;
                            if (!iconName || iconName === "") iconName = "partly_cloudy_day.svg";
                            return "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + iconName;
                        }
                    }

                    Item {
                        Layout.preferredHeight: 4 * Appearance.effectiveScale
                    }

                    // Temp & City: e.g. "20° New York"
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(WeatherService.temp) + "° " + (WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "New York")
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(13, Math.round(cookieScallopContent.baseDim * 0.088))
                        font.weight: Font.DemiBold
                        color: Theme.onSurfaceColor
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        Layout.maximumWidth: Math.round(cookieScallopContent.baseDim * 0.70)
                        renderType: Text.NativeRendering
                    }

                    // Low / High: e.g. "08° 20°"
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        readonly property int lowVal: WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 3)
                        readonly property int highVal: WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp)
                        text: (lowVal < 10 && lowVal >= 0 ? "0" + lowVal : lowVal) + "°  " + (highVal < 10 && highVal >= 0 ? "0" + highVal : highVal) + "°"
                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                        font.pixelSize: Math.max(11, Math.round(cookieScallopContent.baseDim * 0.076))
                        font.weight: Font.Normal
                        color: Theme.onSurfaceVariantColor
                        opacity: 0.85
                        horizontalAlignment: Text.AlignHCenter
                        renderType: Text.NativeRendering
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // UI STYLE 10: Minimal Clean Hourly Forecast Card (Reference UI)
            // ══════════════════════════════════════════════════════════════════
            Item {
                id: style10Content
                anchors.fill: parent
                anchors.margins: Math.round(Math.min(card.width, card.height) * 0.08)
                visible: root.shapeMode === 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Math.round(card.height * 0.04)

                    // ── Top Section: Big Temp + Range on Left, Location Pin + City + Condition on Right ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8 * Appearance.effectiveScale

                        // Left: Temperature & Min~Max
                        ColumnLayout {
                            spacing: 0
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                            RowLayout {
                                spacing: 1 * Appearance.effectiveScale

                                Text {
                                    text: String(Math.round(WeatherService.temp))
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(26, Math.round(card.height * 0.26))
                                    font.weight: Font.Bold
                                    color: Theme.onSurfaceColor
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    text: "°C"
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.095))
                                    font.weight: Font.Medium
                                    color: Theme.onSurfaceVariantColor
                                    Layout.alignment: Qt.AlignTop
                                    Layout.topMargin: 2 * Appearance.effectiveScale
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                readonly property int lowVal: WeatherService.todayLow !== 0 ? WeatherService.todayLow : Math.round(WeatherService.temp - 4)
                                readonly property int highVal: WeatherService.todayHigh !== 0 ? WeatherService.todayHigh : Math.round(WeatherService.temp + 1)
                                text: lowVal + " ~ " + highVal + "°C"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(10, Math.round(card.height * 0.080))
                                font.weight: Font.Normal
                                color: Theme.onSurfaceVariantColor
                                renderType: Text.NativeRendering
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Right: Location Pin + City and Condition below
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 2 * Appearance.effectiveScale

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 3 * Appearance.effectiveScale

                                DankIcon {
                                    name: "location_on"
                                    size: Math.max(12, Math.round(card.height * 0.085))
                                    color: Theme.onSurfaceVariantColor
                                }

                                Text {
                                    text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "Paris"
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.082))
                                    font.weight: Font.Medium
                                    color: Theme.onSurfaceVariantColor
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Math.round(card.width * 0.38)
                                    renderType: Text.NativeRendering
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: WeatherService.condition && WeatherService.condition.length > 0 ? WeatherService.condition : "Sunny"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(12, Math.round(card.height * 0.088))
                                font.weight: Font.Bold
                                color: Theme.onSurfaceColor
                                elide: Text.ElideRight
                                Layout.maximumWidth: Math.round(card.width * 0.40)
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    // ── Bottom Section: 6-Hour Timeline Columns (Temp, Icon, Time) ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(52, Math.round(card.height * 0.46))
                        spacing: 0

                        Repeater {
                            model: {
                                let items = [];
                                let hForecast = WeatherService.hourlyForecast || [];
                                let currentHour = new Date().getHours();
                                
                                for (let step = 0; step < 6; step++) {
                                    let targetHour = currentHour + (step * 2);
                                    let match = null;
                                    
                                    for (let i = 0; i < hForecast.length; i++) {
                                        if (hForecast[i] && hForecast[i].rawTime) {
                                            let rawH = parseInt(hForecast[i].rawTime.split("T")[1].split(":")[0]);
                                            if (rawH === (targetHour % 24)) {
                                                match = hForecast[i];
                                                break;
                                            }
                                        }
                                    }
                                    
                                    let hStr = (targetHour % 24 < 10 ? "0" : "") + (targetHour % 24) + ":00";
                                    let tempVal = match ? match.temp : Math.round(WeatherService.temp - (step > 0 ? (step % 2) : 0));
                                    let iconName = match ? WeatherService.getGoogleWeatherIcon(match.wCode, true) : WeatherService.googleIcon;
                                    
                                    items.push({
                                        timeLabel: step === 0 ? "NOW" : hStr,
                                        temp: tempVal,
                                        icon: iconName || "clear_day.svg",
                                        isNow: step === 0
                                    });
                                }
                                return items;
                            }

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2 * Appearance.effectiveScale

                                    // Hour Temperature
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: String(modelData.temp)
                                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                        font.pixelSize: Math.max(10, Math.round(card.height * 0.075))
                                        font.weight: modelData.isNow ? Font.Bold : Font.Normal
                                        color: modelData.isNow ? Theme.onSurfaceColor : Theme.onSurfaceVariantColor
                                        renderType: Text.NativeRendering
                                    }

                                    // Weather SVG Icon
                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: Math.max(16, Math.round(card.height * 0.14))
                                        height: width
                                        sourceSize.width: width
                                        sourceSize.height: height
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + modelData.icon
                                    }

                                    // Time Label
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.timeLabel
                                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                        font.pixelSize: Math.max(9, Math.round(card.height * 0.068))
                                        font.weight: modelData.isNow ? Font.Bold : Font.Normal
                                        color: modelData.isNow ? Theme.onSurfaceColor : Theme.onSurfaceVariantColor
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ══════════════════════════════════════════════════════════════════
            // UI STYLE 11: Wave Temp Curve Timeline Card (Reference UI)
            // ══════════════════════════════════════════════════════════════════
            Item {
                id: style11Content
                anchors.fill: parent
                anchors.margins: Math.round(Math.min(card.width, card.height) * 0.08)
                visible: root.shapeMode === 11

                readonly property var timelineModel: {
                    let items = [];
                    let hForecast = WeatherService.hourlyForecast || [];
                    let currentHour = new Date().getHours();
                    
                    for (let step = 0; step < 5; step++) {
                        let targetHour = currentHour + (step * 2);
                        let match = null;
                        
                        for (let i = 0; i < hForecast.length; i++) {
                            if (hForecast[i] && hForecast[i].rawTime) {
                                let rawH = parseInt(hForecast[i].rawTime.split("T")[1].split(":")[0]);
                                if (rawH === (targetHour % 24)) {
                                    match = hForecast[i];
                                    break;
                                }
                            }
                        }
                        
                        let hStr = (targetHour % 24 < 10 ? "0" : "") + (targetHour % 24) + ":00";
                        let tempVal = match ? match.temp : Math.round(WeatherService.temp - (step === 2 ? 3 : (step === 1 ? 1 : 0)));
                        let iconName = match ? WeatherService.getGoogleWeatherIcon(match.wCode, true) : WeatherService.googleIcon;
                        
                        items.push({
                            timeLabel: step === 0 ? "Now" : hStr,
                            temp: tempVal,
                            icon: iconName || "clear_day.svg",
                            isNow: step === 0
                        });
                    }
                    return items;
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // ── Top Header: Temp on Left, Condition + Pin/City on Right ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(38, Math.round(card.height * 0.28))
                        spacing: 8 * Appearance.effectiveScale

                        // Left: Temperature e.g. "26 °C"
                        RowLayout {
                            spacing: 2 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

                            Text {
                                text: String(Math.round(WeatherService.temp))
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(28, Math.round(card.height * 0.26))
                                font.weight: Font.Bold
                                color: Theme.onSurfaceColor
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: "°C"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(12, Math.round(card.height * 0.095))
                                font.weight: Font.Medium
                                color: Theme.onSurfaceVariantColor
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 3 * Appearance.effectiveScale
                                renderType: Text.NativeRendering
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Right: Sunny / Location
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            spacing: 2 * Appearance.effectiveScale

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: WeatherService.condition && WeatherService.condition.length > 0 ? WeatherService.condition : "Sunny"
                                font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                font.pixelSize: Math.max(13, Math.round(card.height * 0.095))
                                font.weight: Font.Bold
                                color: Theme.onSurfaceColor
                                elide: Text.ElideRight
                                Layout.maximumWidth: Math.round(card.width * 0.40)
                                renderType: Text.NativeRendering
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 3 * Appearance.effectiveScale

                                DankIcon {
                                    name: "location_on"
                                    size: Math.max(12, Math.round(card.height * 0.082))
                                    color: Theme.onSurfaceVariantColor
                                }

                                Text {
                                    text: WeatherService.city && WeatherService.city.length > 0 ? WeatherService.city : "Paris"
                                    font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                    font.pixelSize: Math.max(11, Math.round(card.height * 0.080))
                                    font.weight: Font.Medium
                                    color: Theme.onSurfaceVariantColor
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Math.round(card.width * 0.38)
                                    renderType: Text.NativeRendering
                                }
                            }
                        }
                    }

                    // ── Middle Section: Temperature Wave Graph & Current-Time Ring Marker ──
                    Item {
                        id: waveGraphContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                let ctx = getContext("2d");
                                ctx.reset();

                                let w = width;
                                let h = height;
                                if (w <= 0 || h <= 0) return;

                                let data = style11Content.timelineModel;
                                let n = data.length;
                                if (n < 2) return;

                                let minT = data[0].temp;
                                let maxT = data[0].temp;
                                for (let i = 0; i < n; i++) {
                                    if (data[i].temp < minT) minT = data[i].temp;
                                    if (data[i].temp > maxT) maxT = data[i].temp;
                                }
                                if (maxT === minT) { maxT += 2; minT -= 2; }
                                let range = (maxT - minT) || 1;

                                let pts = [];
                                for (let i = 0; i < n; i++) {
                                    let px = (i + 0.5) * (w / n);
                                    let ratio = (data[i].temp - minT) / range;
                                    let py = h * 0.80 - (ratio * (h * 0.55));
                                    pts.push({ x: px, y: py });
                                }

                                // 1. Horizontal dashed threshold guideline
                                ctx.beginPath();
                                ctx.strokeStyle = Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.32);
                                ctx.lineWidth = 1.2;
                                ctx.setLineDash([3, 3]);
                                ctx.moveTo(0, pts[0].y);
                                ctx.lineTo(w, pts[0].y);
                                ctx.stroke();

                                // 2. Vertical dashed drop-line from 'Now' marker
                                ctx.beginPath();
                                ctx.strokeStyle = Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.32);
                                ctx.lineWidth = 1.2;
                                ctx.setLineDash([2, 3]);
                                ctx.moveTo(pts[0].x, pts[0].y);
                                ctx.lineTo(pts[0].x, h);
                                ctx.stroke();
                                ctx.setLineDash([]);

                                // 3. Smooth cubic spline curve
                                ctx.beginPath();
                                ctx.strokeStyle = Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.60);
                                ctx.lineWidth = 2.2;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                ctx.moveTo(0, pts[0].y);
                                ctx.lineTo(pts[0].x, pts[0].y);

                                for (let i = 0; i < pts.length - 1; i++) {
                                    let cpX = (pts[i].x + pts[i + 1].x) / 2;
                                    ctx.bezierCurveTo(cpX, pts[i].y, cpX, pts[i + 1].y, pts[i + 1].x, pts[i + 1].y);
                                }
                                ctx.lineTo(w, pts[pts.length - 1].y);
                                ctx.stroke();

                                // 4. Outer ring marker at 'Now'
                                ctx.beginPath();
                                ctx.arc(pts[0].x, pts[0].y, 6.5, 0, 2 * Math.PI);
                                ctx.strokeStyle = Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.60);
                                ctx.lineWidth = 1.8;
                                ctx.stroke();

                                // Inner solid dot
                                ctx.beginPath();
                                ctx.arc(pts[0].x, pts[0].y, 3.2, 0, 2 * Math.PI);
                                ctx.fillStyle = Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.75);
                                ctx.fill();
                            }

                            Connections {
                                target: WeatherService
                                function onTempChanged() { waveCanvas.requestPaint(); }
                                function onHourlyForecastChanged() { waveCanvas.requestPaint(); }
                            }
                            Connections {
                                target: card
                                function onWidthChanged() { waveCanvas.requestPaint(); }
                                function onHeightChanged() { waveCanvas.requestPaint(); }
                            }
                        }
                    }

                    // ── Bottom Section: 5 Timeline Columns (Weather Icon & Time Label) ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(44, Math.round(card.height * 0.32))
                        spacing: 0

                        Repeater {
                            model: style11Content.timelineModel

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4 * Appearance.effectiveScale

                                    // Weather SVG Icon
                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: Math.max(18, Math.round(card.height * 0.14))
                                        height: width
                                        sourceSize.width: width
                                        sourceSize.height: height
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/google-weather/" + modelData.icon
                                    }

                                    // Time Label (Now, 12:00, 14:00, 16:00, 18:00)
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.timeLabel
                                        font.family: "Google Sans, Product Sans, Inter, Outfit, " + Theme.font.family
                                        font.pixelSize: Math.max(10, Math.round(card.height * 0.075))
                                        font.weight: modelData.isNow ? Font.Bold : Font.Normal
                                        color: modelData.isNow ? Theme.onSurfaceColor : Theme.onSurfaceVariantColor
                                        renderType: Text.NativeRendering
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Pill Indicator Bar
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 2 * Appearance.effectiveScale
                        width: 28 * Appearance.effectiveScale
                        height: 3 * Appearance.effectiveScale
                        radius: 1.5 * Appearance.effectiveScale
                        color: Qt.rgba(Theme.onSurfaceVariantColor.r, Theme.onSurfaceVariantColor.g, Theme.onSurfaceVariantColor.b, 0.40)
                    }
                }
            }
        }

    // Drag, Click & Direct Mouse Controls Area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        drag.target: root

        onReleased: {
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, root.customWidth, root.customHeight);
        }

        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                // Middle Click: Cycle Size Style (Small -> Medium -> Large)
                root.customWidth = -1;
                root.customHeight = -1;
                root.styleMode = (root.styleMode % 3) + 1;
                root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, -1, -1);
            } else if (mouse.button === Qt.RightButton) {
                // Right Click: Cycle UI Style (1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> 11 -> 1)
                root.customWidth = -1;
                root.customHeight = -1;
                root.shapeMode = (root.shapeMode % 11) + 1;
                root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, -1, -1);
            } else if (mouse.button === Qt.LeftButton) {
                // Left Click: Open Weather App
                openWeatherProc.running = true;
            }
        }

        onWheel: wheel => {
            root.customWidth = -1;
            root.customHeight = -1;
            if (wheel.angleDelta.y > 0) {
                root.styleMode = Math.min(3, root.styleMode + 1);
            } else if (wheel.angleDelta.y < 0) {
                root.styleMode = Math.max(1, root.styleMode - 1);
            }
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, -1, -1);
        }
    }

    WidgetResizeFrame {
        id: resizeFrame
        target: root
        widgetName: "Weather"
        minWidth: ((root.shapeMode === 4 || root.shapeMode === 5 || root.shapeMode === 6 || root.shapeMode === 7 || root.shapeMode === 8 || root.shapeMode === 9) ? 140 : (root.shapeMode === 3 ? 120 : (root.shapeMode === 2 ? 200 : (root.shapeMode >= 10 ? 280 : 320)))) * Appearance.effectiveScale
        minHeight: ((root.shapeMode === 4 || root.shapeMode === 5 || root.shapeMode === 6 || root.shapeMode === 7 || root.shapeMode === 8 || root.shapeMode === 9) ? 140 : (root.shapeMode === 3 ? 50 : (root.shapeMode === 2 ? 80 : (root.shapeMode >= 10 ? 130 : 150)))) * Appearance.effectiveScale
        maxWidth: 750 * Appearance.effectiveScale
        maxHeight: 380 * Appearance.effectiveScale

        onResized: (newW, newH) => {
            root.customWidth = Math.round(newW / Appearance.effectiveScale);
            root.customHeight = Math.round(newH / Appearance.effectiveScale);
        }
        onResizeEnded: (finalW, finalH) => {
            root.customWidth = Math.round(finalW / Appearance.effectiveScale);
            root.customHeight = Math.round(finalH / Appearance.effectiveScale);
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, root.customWidth, root.customHeight);
        }
        onResetRequested: {
            root.customWidth = -1;
            root.customHeight = -1;
            root.saveSettings(root.x, root.y, root.styleMode, root.shapeMode, root.isActive, -1, -1);
        }
    }
}
