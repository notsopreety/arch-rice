pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real temp: 0
    property real tempF: 0
    property real feelsLike: 0
    property real feelsLikeF: 0
    property string condition: "Clear"
    property string city: ""
    property string country: ""
    property string icon: "󰖙"
    property string materialIcon: "sunny"
    property int wCode: 0
    property string googleIcon: "clear_day.svg"
    property bool loading: true
    property bool available: false
    property bool isDay: true

    // Extended weather data
    property real humidity: 0
    property real wind: 0
    property real pressure: 0
    property int precipitationProbability: 0
    property string sunrise: ""
    property string sunset: ""

    // Sync properties for WeatherCard
    property var lastUpdateTime: null
    property int todayHigh: 0
    property int todayLow: 0
    property var hourly: []
    property var daily: []

    // Forecast data
    property var forecast: []
    property var hourlyForecast: []

    // Location
    property var location: null

    function updateWeather() {
        if (!location) {
            getLocation();
            return;
        }
        fetchWeather();
    }

    function forceRefresh() {
        getLocation();
    }

    function getLocation() {
        root.loading = true;
        locationFetcher.running = true;
    }

    function fetchWeather() {
        if (!location) return;
        root.loading = true;
        var url = "https://api.open-meteo.com/v1/forecast?"
            + "latitude=" + location.lat + "&longitude=" + location.lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,surface_pressure,wind_speed_10m"
            + "&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m,surface_pressure,visibility"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,wind_speed_10m_max"
            + "&timezone=auto&forecast_days=7";
        weatherFetcher.command = ["curl", "-sS", "--fail", "--connect-timeout", "5", "--max-time", "10", "--compressed", url];
        weatherFetcher.running = true;
    }

    function reverseGeocode(lat, lon) {
        var url = "https://nominatim.openstreetmap.org/reverse?lat=" + lat + "&lon=" + lon + "&format=json&addressdetails=1&accept-language=en";
        reverseGeoFetcher.command = ["curl", "-sS", "--fail", "--connect-timeout", "5", "--max-time", "10", "-H", "User-Agent: QuickshellWeather/1.0", url];
        reverseGeoFetcher.running = true;
    }

    function getMaterialWeatherIcon(code) {
        if (code === 0 || code === 1) return "sunny";
        if (code >= 2 && code <= 3) return "cloudy";
        if (code >= 45 && code <= 48) return "foggy";
        if (code >= 51 && code <= 67) return "rainy";
        if (code >= 71 && code <= 77) return "snowing";
        if (code >= 80 && code <= 82) return "rainy";
        if (code >= 85 && code <= 86) return "snowing";
        if (code >= 95 && code <= 99) return "thunderstorm";
        return "sunny";
    }

    function getGoogleWeatherIcon(code, isDay) {
        if (code === 0) return isDay ? "clear_day.svg" : "clear_night.svg";
        if (code === 1 || code === 2) return isDay ? "partly_cloudy_day.svg" : "partly_cloudy_night.svg";
        if (code === 3) return "cloudy.svg";
        if (code >= 45 && code <= 48) return "haze_fog_dust_smoke.svg";
        if (code >= 51 && code <= 57) return "drizzle.svg";
        if ((code >= 61 && code <= 63) || code === 80 || code === 81) return isDay ? "rain_with_sunny_light.svg" : "rain_with_cloudy_light.svg";
        if (code === 65 || code === 82) return "heavy_rain.svg";
        if (code === 66 || code === 67) return "icy.svg";
        if ((code >= 71 && code <= 77) || code === 85) return isDay ? "snow_with_sunny_light.svg" : "snow_with_cloudy_light.svg";
        if (code === 75 || code === 86) return "heavy_snow.svg";
        if (code >= 95 && code <= 99) return "strong_thunderstorms.svg";
        return "cloudy.svg";
    }

    function getWeatherIcon(code) {
        if (code === 0 || code === 1) return "󰖙";
        if (code >= 2 && code <= 3) return "󰖐";
        if (code >= 45 && code <= 48) return "󰖑";
        if (code >= 51 && code <= 67) return "󰖗";
        if (code >= 71 && code <= 77) return "󰼶";
        if (code >= 80 && code <= 82) return "󰖗";
        if (code >= 85 && code <= 86) return "󰼶";
        if (code >= 95 && code <= 99) return "󰙏";
        return "󰖙";
    }

    function getWeatherCondition(code) {
        var conditions = {
            0: "Clear Sky", 1: "Clear Sky", 2: "Partly Cloudy", 3: "Overcast",
            45: "Fog", 48: "Fog", 51: "Drizzle", 53: "Drizzle", 55: "Drizzle",
            56: "Freezing Drizzle", 57: "Freezing Drizzle",
            61: "Light Rain", 63: "Rain", 65: "Heavy Rain",
            66: "Freezing Rain", 67: "Freezing Rain",
            71: "Light Snow", 73: "Snow", 75: "Heavy Snow", 77: "Snow",
            80: "Light Rain", 81: "Rain", 82: "Heavy Rain",
            85: "Snow Showers", 86: "Heavy Snow Showers",
            95: "Thunderstorm", 96: "Thunderstorm with Hail", 99: "Thunderstorm with Hail"
        };
        return conditions[code] || "Clear";
    }

    function formatHour(isoStr) {
        try {
            var parts = isoStr.split("T");
            var timeParts = parts[1].split(":");
            var h = parseInt(timeParts[0]);
            var ampm = h >= 12 ? "PM" : "AM";
            h = h % 12;
            if (h === 0) h = 12;
            return h + " " + ampm;
        } catch(e) { return isoStr; }
    }

    function formatTime(isoStr) {
        try {
            var parts = isoStr.split("T");
            var timeParts = parts[1].split(":");
            var h = parseInt(timeParts[0]);
            var m = timeParts[1];
            var ampm = h >= 12 ? "PM" : "AM";
            h = h % 12;
            if (h === 0) h = 12;
            return h + ":" + m + " " + ampm;
        } catch(e) { return isoStr; }
    }

    function formatDay(dateStr, idx) {
        if (idx === 0) return "Today";
        if (idx === 1) return "Tomorrow";
        try {
            var d = new Date(dateStr + "T00:00:00");
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            return days[d.getDay()];
        } catch(e) { return dateStr; }
    }

    // ── Location via ip-api.com ──
    Process {
        id: locationFetcher
        running: false
        command: ["curl", "-sS", "--fail", "--connect-timeout", "5", "--max-time", "10", "http://ip-api.com/json/"]

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (!raw || raw[0] !== "{") {
                    root.loading = false;
                    return;
                }
                try {
                    var loc = JSON.parse(raw);
                    root.location = {
                        lat: loc.lat,
                        lon: loc.lon
                    };
                    root.city = loc.city || "";
                    root.country = loc.country || "";
                    // Also run reverseGeocode to get more detailed address structure if needed
                    root.reverseGeocode(loc.lat, loc.lon);
                    root.fetchWeather();
                } catch(e) {
                    console.error("Location parse error:", e);
                    root.loading = false;
                }
            }
        }
    }

    // ── Reverse Geocoding via Nominatim ──
    Process {
        id: reverseGeoFetcher
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (!raw || raw[0] !== "{") {
                    root.loading = false;
                    return;
                }
                try {
                    var res = JSON.parse(raw);
                    var addr = res.address || {};
                    root.city = addr.city || addr.town || addr.village || addr.hamlet || addr.county || "";
                    root.country = addr.country || "";
                } catch(e) {
                    console.error("Geocode parse error:", e);
                    root.loading = false;
                }
            }
        }
    }

    // ── Weather Fetch via Open-Meteo ──
    Process {
        id: weatherFetcher
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (!raw || raw[0] !== "{") return;
                root.loading = false;
                try {
                    var res = JSON.parse(raw);
                    if (!res.current || !res.daily || !res.hourly) return;

                    var cur = res.current;
                    root.temp = Math.round(cur.temperature_2m || 0);
                    root.tempF = Math.round((cur.temperature_2m || 0) * 9 / 5 + 32);
                    root.feelsLike = Math.round(cur.apparent_temperature || cur.temperature_2m || 0);
                    root.feelsLikeF = Math.round((cur.apparent_temperature || cur.temperature_2m || 0) * 9 / 5 + 32);
                    root.wCode = cur.weather_code || 0;
                    root.googleIcon = getGoogleWeatherIcon(cur.weather_code || 0, Boolean(cur.is_day));
                    root.condition = getWeatherCondition(cur.weather_code || 0);
                    root.icon = getWeatherIcon(cur.weather_code || 0);
                    root.materialIcon = getMaterialWeatherIcon(cur.weather_code || 0);
                    root.humidity = Math.round(cur.relative_humidity_2m || 0);
                    root.wind = Math.round(cur.wind_speed_10m || 0);
                    root.pressure = Math.round(cur.surface_pressure || 0);
                    root.isDay = Boolean(cur.is_day);
                    root.available = true;

                    // Daily
                    if (res.daily.precipitation_probability_max && res.daily.precipitation_probability_max.length > 0)
                        root.precipitationProbability = res.daily.precipitation_probability_max[0] || 0;
                    if (res.daily.sunrise && res.daily.sunrise.length > 0)
                        root.sunrise = formatTime(res.daily.sunrise[0]);
                    if (res.daily.sunset && res.daily.sunset.length > 0)
                        root.sunset = formatTime(res.daily.sunset[0]);

                    // Build daily forecast
                    var dailyArr = [];
                    var dc = res.daily.time ? res.daily.time.length : 0;
                    for (var d = 0; d < dc; d++) {
                        dailyArr.push({
                            day: formatDay(res.daily.time[d], d),
                            date: res.daily.time[d],
                            tempMax: Math.round(res.daily.temperature_2m_max[d]),
                            tempMin: Math.round(res.daily.temperature_2m_min[d]),
                            wCode: res.daily.weather_code[d],
                            precipitationProbability: res.daily.precipitation_probability_max[d] || 0,
                            sunrise: formatTime(res.daily.sunrise[d]),
                            sunset: formatTime(res.daily.sunset[d])
                        });
                    }
                    root.forecast = dailyArr;

                    // Build hourly forecast
                    var hourlyArr = [];
                    var hc = Math.min(res.hourly.time ? res.hourly.time.length : 0, 48);
                    for (var h = 0; h < hc; h++) {
                        hourlyArr.push({
                            time: formatHour(res.hourly.time[h]),
                            rawTime: res.hourly.time[h],
                            temp: Math.round(res.hourly.temperature_2m[h]),
                            feelsLike: Math.round(res.hourly.apparent_temperature[h]),
                            humidity: Math.round(res.hourly.relative_humidity_2m[h]),
                            precipitationProbability: res.hourly.precipitation_probability[h] || 0,
                            wCode: res.hourly.weather_code[h],
                            wind: Math.round(res.hourly.wind_speed_10m[h]),
                            pressure: Math.round(res.hourly.surface_pressure[h])
                        });
                    }
                    root.hourlyForecast = hourlyArr;

                    root.lastUpdateTime = new Date();

                    if (dailyArr.length > 0) {
                        root.todayHigh = dailyArr[0].tempMax;
                        root.todayLow = dailyArr[0].tempMin;
                    }

                    // Build hourly for WeatherCard
                    var nowHour = new Date().getHours();
                    var upcoming = [];
                    for (var i = nowHour; i < nowHour + 6 && i < hourlyArr.length; i++) {
                        upcoming.push({
                            time: hourlyArr[i].time,
                            temp: hourlyArr[i].temp,
                            icon: getGoogleWeatherIcon(hourlyArr[i].wCode, true).replace(".svg", ""),
                            condition: getWeatherCondition(hourlyArr[i].wCode)
                        });
                    }
                    root.hourly = upcoming;

                    // Build daily list for WeatherCard
                    var dailyList = [];
                    for (var d = 0; d < Math.min(dailyArr.length, 3); d++) {
                        dailyList.push({
                            date: d === 0 ? "Today" : dailyArr[d].day,
                            maxTemp: dailyArr[d].tempMax,
                            minTemp: dailyArr[d].tempMin,
                            icon: getGoogleWeatherIcon(dailyArr[d].wCode, true).replace(".svg", "")
                        });
                    }
                    root.daily = dailyList;

                } catch(e) {
                    console.error("Weather parse error:", e);
                    root.loading = false;
                }
            }
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateWeather()
    }
}
