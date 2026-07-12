import "../core"
import "../services"
import "../theme"
import "."
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

import "./weather"

/**
 * Weather widget with Android 16 aesthetics.
 * Features full-card atmospheric animations and a clean M3 surface.
 */
Rectangle {
    id: root
    implicitHeight: mainLayout.implicitHeight
    radius: Appearance.rounding.card

    property color bgTopColor: {
        var isDay = WeatherService.isDay;
        var cond = (WeatherService.condition || "").toLowerCase();
        var hr = DateTime.hours;
        
        if (cond.indexOf("rain") !== -1 || cond.indexOf("drizzle") !== -1 || cond.indexOf("shower") !== -1) {
            return isDay ? "#4b6584" : "#1e272c";
        } else if (cond.indexOf("snow") !== -1 || cond.indexOf("flurries") !== -1 || cond.indexOf("ice") !== -1) {
            return isDay ? "#a5b1c2" : "#2b3b4c";
        } else if (cond.indexOf("thunder") !== -1 || cond.indexOf("storm") !== -1) {
            return isDay ? "#3d3d3d" : "#0f0c1b";
        } else if (cond.indexOf("cloud") !== -1 || cond.indexOf("overcast") !== -1) {
            return isDay ? "#4b7bec" : "#1e3799";
        } else if (cond.indexOf("fog") !== -1 || cond.indexOf("haze") !== -1 || cond.indexOf("mist") !== -1) {
            return isDay ? "#bdc3c7" : "#2c3e50";
        } else {
            if (isDay) {
                if (hr >= 5 && hr <= 7) return "#fc5c65"; // Sunrise coral
                if (hr >= 17 && hr <= 19) return "#706fd3"; // Sunset violet
                return "#2680eb"; // Clear sky blue
            } else {
                return "#0B0C10"; // Clear space night
            }
        }
    }

    property color bgBotColor: {
        var isDay = WeatherService.isDay;
        var cond = (WeatherService.condition || "").toLowerCase();
        var hr = DateTime.hours;
        
        if (cond.indexOf("rain") !== -1 || cond.indexOf("drizzle") !== -1 || cond.indexOf("shower") !== -1) {
            return isDay ? "#2d98da" : "#3867d6";
        } else if (cond.indexOf("snow") !== -1 || cond.indexOf("flurries") !== -1 || cond.indexOf("ice") !== -1) {
            return isDay ? "#d1d8e0" : "#4b6584";
        } else if (cond.indexOf("thunder") !== -1 || cond.indexOf("storm") !== -1) {
            return isDay ? "#1a1a2e" : "#24243e";
        } else if (cond.indexOf("cloud") !== -1 || cond.indexOf("overcast") !== -1) {
            return isDay ? "#a5b1c2" : "#0c2461";
        } else if (cond.indexOf("fog") !== -1 || cond.indexOf("haze") !== -1 || cond.indexOf("mist") !== -1) {
            return isDay ? "#95a5a6" : "#0f171e";
        } else {
            if (isDay) {
                if (hr >= 5 && hr <= 7) return "#f7b731"; // Sunrise yellow
                if (hr >= 17 && hr <= 19) return "#ff793f"; // Sunset orange
                return "#5cd1ff"; // Soft day cyan
            } else {
                return "#1F2833"; // Night blue-nebula
            }
        }
    }

    Behavior on bgTopColor { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
    Behavior on bgBotColor { ColorAnimation { duration: 1000; easing.type: Easing.InOutQuad } }

    gradient: Gradient {
        GradientStop { position: 0.0; color: root.bgTopColor }
        GradientStop { position: 1.0; color: root.bgBotColor }
    }
    
    // Clipping mask to ensure animations respect card corners
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
    
    readonly property string weatherIconsDir: "assets/google-weather"
    readonly property bool showDailyForecast: Config.options.weather ? Config.options.weather.showDailyForecast : true
    
    property color contentColor: {
        var isDay = WeatherService.isDay;
        var cond = (WeatherService.condition || "").toLowerCase();
        
        if (isDay) {
            if (cond.indexOf("rain") !== -1 || cond.indexOf("thunder") !== -1 || cond.indexOf("storm") !== -1) {
                return "#ffffff";
            }
            return "#1e272c"; // High contrast text on bright sunny/cloudy/foggy days
        }
        return "#ffffff"; // High contrast white text on dark nights
    }
    
    Behavior on contentColor { ColorAnimation { duration: 600 } }
    
    readonly property real midOpacity: 0.8
    readonly property real lowOpacity: 0.6

    // --- Atmospheric Overlay ---
    WeatherAnimation {
        id: weatherAnim
        anchors.fill: parent
        animationsEnabled: root.visible
        backgroundEnabled: false 
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        // ── Top Section: Primary Conditions ──
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20 * Appearance.effectiveScale
            Layout.bottomMargin: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 6 * Appearance.effectiveScale
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale
                    CustomIcon {
                        source: WeatherService.googleIcon
                        iconFolder: root.weatherIconsDir
                        width: 32 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale; colorize: false
                    }
                    StyledText {
                        text: WeatherService.loading ? "Updating..." : WeatherService.condition
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: root.contentColor
                        Layout.fillWidth: true
                    }
                }

                StyledText {
                    text: `Feels like ${WeatherService.feelsLike}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                    opacity: root.midOpacity
                    Layout.fillWidth: true
                }

                StyledText {
                    text: `${WeatherService.todayHigh}° · ${WeatherService.todayLow}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                    opacity: root.lowOpacity
                    Layout.fillWidth: true
                }
            }

            StyledText {
                text: WeatherService.temp + "°"
                font.pixelSize: 64 * Appearance.effectiveScale
                font.weight: Font.Normal
                color: root.contentColor
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
            }
        }

        // ── Middle Section: Hourly (Transparent) ──
        Item {
            Layout.fillWidth: true
            implicitHeight: hourlyCol.implicitHeight + 32 * Appearance.effectiveScale
            
            ColumnLayout {
                id: hourlyCol
                anchors.fill: parent
                anchors.leftMargin: 20 * Appearance.effectiveScale; anchors.rightMargin: 20 * Appearance.effectiveScale
                anchors.topMargin: 16 * Appearance.effectiveScale; anchors.bottomMargin: 16 * Appearance.effectiveScale
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: WeatherService.hourly
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 8 * Appearance.effectiveScale
                            StyledText {
                                text: modelData.temp + "°"; font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium; color: root.contentColor; Layout.alignment: Qt.AlignHCenter
                            }
                            CustomIcon {
                                source: modelData.icon; iconFolder: root.weatherIconsDir
                                width: 28 * Appearance.effectiveScale; height: 28 * Appearance.effectiveScale; colorize: false; Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                text: index === 0 ? "Now" : modelData.time
                                font.pixelSize: Appearance.font.pixelSize.smallest; color: root.contentColor; opacity: root.lowOpacity
                                Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom Section: Daily (Transparent) ──
        Item {
            visible: WeatherService.daily.length > 0
            Layout.fillWidth: true
            implicitHeight: dailyCol.implicitHeight + 24 * Appearance.effectiveScale
            
            ColumnLayout {
                id: dailyCol
                anchors.fill: parent
                anchors.leftMargin: 20 * Appearance.effectiveScale; anchors.rightMargin: 20 * Appearance.effectiveScale
                anchors.topMargin: 12 * Appearance.effectiveScale; anchors.bottomMargin: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale
                Repeater {
                    model: root.showDailyForecast ? WeatherService.daily : WeatherService.daily.slice(0, 1)
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8 * Appearance.effectiveScale; Layout.rightMargin: 8 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale
                        StyledText {
                            text: modelData.date; font.pixelSize: Appearance.font.pixelSize.small
                            color: root.contentColor; Layout.fillWidth: true
                        }
                        StyledText {
                            text: `${modelData.maxTemp}° ${modelData.minTemp}°`
                            font.pixelSize: Appearance.font.pixelSize.small; color: root.contentColor; opacity: root.midOpacity
                        }
                        CustomIcon {
                            source: modelData.icon; iconFolder: root.weatherIconsDir
                            width: 24 * Appearance.effectiveScale; height: 24 * Appearance.effectiveScale; colorize: false
                        }
                    }
                }
            }
        }

        // ── Footer Section: Status ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Layout.topMargin: 4 * Appearance.effectiveScale
            Layout.bottomMargin: 16 * Appearance.effectiveScale

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * Appearance.effectiveScale
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6 * Appearance.effectiveScale
                    
                    MaterialSymbol {
                        text: "sync"
                        iconSize: 11 * Appearance.effectiveScale
                        color: root.contentColor
                        opacity: root.lowOpacity
                        visible: WeatherService.loading
                        
                        RotationAnimation on rotation {
                            running: WeatherService.loading
                            from: 0; to: 360; duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    StyledText {
                        id: timestampText
                        font.pixelSize: 9 * Appearance.effectiveScale
                        color: root.contentColor; opacity: root.lowOpacity; textFormat: Text.StyledText
                        
                        property int ticker: 0
                        text: WeatherService.loading ? "Updating..." : `Updated ${timeString}, click to refresh`
                        
                        readonly property string timeString: {
                            let dummy = ticker;
                            if (!WeatherService.lastUpdateTime) return "unknown";
                            let diff = Math.floor((new Date() - new Date(WeatherService.lastUpdateTime)) / 60000);
                            if (diff < 1) return "just now";
                            if (diff < 60) return diff + " mins ago";
                            return Math.floor(diff / 60) + " hours ago";
                        }
                        
                        Timer { interval: 60000; running: true; repeat: true; onTriggered: timestampText.ticker++; triggeredOnStart: true }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: WeatherService.forceRefresh()
                }
            }
        }
    }
}
