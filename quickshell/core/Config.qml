pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false

    // Centralized Format Logic
    readonly property string timeFormat: {
        if (!ready) return "HH:mm"
        switch (options.time.timeStyle) {
            case "12H_pm": return "hh:mm ap"
            case "12H_PM": return "hh:mm AP"
            case "24H":    return "HH:mm"
            default:       return "HH:mm"
        }
    }

    readonly property string dateFormat: {
        if (!ready) return "ddd, dd/MM"
        switch (options.time.dateStyle) {
            case "DMY": return "ddd, dd/MM"
            case "MDY": return "ddd, MM/dd"
            case "YMD": return "yyyy/MM/dd" 
            default:    return "ddd, dd/MM"
        }
    }

    readonly property string longDateFormat: {
        if (!ready) return "ddd, d MMMM yyyy"
        switch (options.time.dateStyle) {
            case "DMY": return "ddd, d MMMM yyyy"
            case "MDY": return "ddd, MMMM d, yyyy"
            case "YMD": return "yyyy, MMMM d (ddd)"
            default:    return "ddd, d MMMM yyyy"
        }
    }

    Timer {
        id: fileReloadTimer
        interval: 50
        repeat: false
        onTriggered: configFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: 50
        repeat: false
        onTriggered: configFileView.writeAdapter()
    }

    // Single queued writer for settings.json. Every writer merges a section here so
    // independent read-modify-write calls can't drop each other's keys.
    // A value of null (JSON null) deletes that key.
    property var pending: ({})
    property bool flushing: false

    Timer {
        id: saveDebounce
        interval: 50
        repeat: false
        onTriggered: root.flushPending()
    }

    Process {
        id: saveSectionProc
        onExited: {
            root.flushing = false;
            // A flush can arrive while the previous one is still in flight.
            if (root.pending && Object.keys(root.pending).length > 0) {
                root.flushPending();
            }
        }
    }

    function setSection(name, obj) {
        if (!name || !obj) return;
        let section = root.pending[name] || ({});
        for (let key in obj) {
            section[key] = obj[key];
        }
        root.pending[name] = section;
        saveDebounce.restart();
    }

    function flushPending() {
        if (!root.ready || root.flushing) return;
        let changes = root.pending;
        if (!changes || Object.keys(changes).length === 0) return;
        root.pending = ({});
        root.flushing = true;
        // path and changes are passed as argv so they can't break out of the script
        let cmd = "import json, os, sys\n" +
                  "path = sys.argv[1]\n" +
                  "changes = json.loads(sys.argv[2])\n" +
                  "data = json.load(open(path)) if os.path.exists(path) else {}\n" +
                  "for name, vals in changes.items():\n" +
                  "    sec = data.setdefault(name, {})\n" +
                  "    for key, val in vals.items():\n" +
                  "        if val is None:\n" +
                  "            sec.pop(key, None)\n" +
                  "        else:\n" +
                  "            sec[key] = val\n" +
                  "tmp = path + '.tmp'\n" +
                  "f = open(tmp, 'w')\n" +
                  "json.dump(data, f, indent=2)\n" +
                  "f.close()\n" +
                  "os.replace(tmp, path)";
        saveSectionProc.command = ["python3", "-c", cmd, root.filePath, JSON.stringify(changes)];
        saveSectionProc.running = true;
    }

    function saveToggles(togglesList) {
        if (!togglesList) return;
        let arr = [];
        for (let i = 0; i < togglesList.length; i++) {
            let item = togglesList[i];
            if (item) {
                arr.push({
                    "type": item.type || "",
                    "size": item.size || 1
                });
            }
        }
        root.setSection("quickSettings", { toggles: arr });
    }

    onReadyChanged: {
        if (root.ready) root.flushPending();
    }

    Connections {
        target: configOptionsJsonAdapter.quickSettings
        function onTogglesChanged() {
            if (root.ready) {
                root.saveToggles(configOptionsJsonAdapter.quickSettings.toggles);
            }
        }
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onLoaded: {
            root.ready = true;
        }
        onLoadFailed: error => {
            console.error("[Config] FileView load failed:", error);
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            // --- Time & Clock ---
            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string dateFormat: "ddd, dd/MM"
                property string longDateFormat: "dd/MM/yyyy"
                property string timeStyle: "24H" 
                property string dateStyle: "DMY" 
            }

            // --- Appearance ---
            property JsonObject appearance: JsonObject {
                property real globalScale: 1.0
                property bool autoScale: true
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string monospace: "JetBrains Mono NF"
                }
                property JsonObject background: JsonObject {
                    property string wallpaperPath: "file://" + Directories.assetsPath + "/sakura.png"
                    property bool darkmode: true
                    property bool matugen: true
                    property string matugenScheme: "scheme-content"
                    property string matugenCustomColor: "#3F51B5"
                    property string matugenThemeFile: ""
                    property string matugenSource: "desktop"
                    property string liveWallpaperPath: ""
                    property bool autoCycleEnabled: false
                    property string autoCycleDirectory: Directories.home + "/Pictures/Wallpapers"
                    property int autoCycleInterval: 30 
                    property list<string> customFolders: []
                    property bool showCava: false
                    property real cavaOpacity: 0.15
                }
                property JsonObject screenCorners: JsonObject {
                    property int mode: 1
                    property int radius: 20
                }
                property JsonObject clock: JsonObject {
                    property string style: "digital"
                    property string styleLocked: "digital"
                    property bool showOnDesktop: true
                    property bool showDate: true
                    property bool useSameStyle: true
                    property int offsetX: 0
                    property int offsetY: -50
                    property bool locked: false

                    property JsonObject digital: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property int dateFontSize: 24
                        property int dateGap: 4
                        property bool hideAmPm: false
                    }
                    property JsonObject digitalLocked: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property int dateFontSize: 24
                        property int dateGap: 4
                        property bool hideAmPm: false
                    }
                    property JsonObject analog: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape" 
                        property int sides: 12
                        property string backgroundShape: "Circle" 
                        property string shape: "Circle" 
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property string dateStyle: "bubble" 
                        property string handStyle: "modern" 
                        property string hourHandStyle: "fill" 
                        property string minuteHandStyle: "bold" 
                        property string secondHandStyle: "dot" 
                        property string dialStyle: "dots" 
                        property int size: 240
                    }
                    property JsonObject analogLocked: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape"
                        property int sides: 12
                        property string backgroundShape: "Circle"
                        property string shape: "Circle"
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property string dateStyle: "bubble"
                        property string handStyle: "modern"
                        property string hourHandStyle: "fill"
                        property string minuteHandStyle: "bold"
                        property string secondHandStyle: "dot"
                        property string dialStyle: "dots"
                        property int size: 240
                    }
                    property JsonObject code: JsonObject {
                        property string valueColorStyle: "primary"
                        property string keywordColorStyle: "tertiary"
                        property string blockColorStyle: "primary"
                        property int fontSize: 18
                        property string blockType: "js"
                        property string fontFamily: "JetBrainsMono Nerd Font"
                    }
                    property JsonObject codeLocked: JsonObject {
                        property string valueColorStyle: "primary"
                        property string keywordColorStyle: "tertiary"
                        property string blockColorStyle: "primary"
                        property int fontSize: 18
                        property string blockType: "js"
                        property string fontFamily: "JetBrainsMono Nerd Font"
                    }
                    property JsonObject stacked: JsonObject {
                        property string colorStyle: "error"
                        property string textColorStyle: "onSurface"
                        property int fontSize: 84
                        property int labelFontSize: 42
                        property string fontFamily: "Google Sans Flex"
                        property string fontWeight: "Medium"
                        property string labelFontWeight: "Light"
                        property string alignment: "left"
                    }
                    property JsonObject stackedLocked: JsonObject {
                        property string colorStyle: "error"
                        property string textColorStyle: "onSurface"
                        property int fontSize: 84
                        property int labelFontSize: 42
                        property string fontFamily: "Google Sans Flex"
                        property string fontWeight: "Medium"
                        property string labelFontWeight: "Light"
                        property string alignment: "left"
                    }
                    property JsonObject text: JsonObject {
                        property int fontSize: 42
                        property int dateFontSize: 18
                        property string alignment: "center"
                        property string timeColorStyle: "onSurface"
                        property string dateColorStyle: "primary"
                    }
                    property JsonObject textLocked: JsonObject {
                        property int fontSize: 42
                        property int dateFontSize: 18
                        property string alignment: "center"
                        property string timeColorStyle: "onSurface"
                        property string dateColorStyle: "primary"
                    }
                    property JsonObject pill: JsonObject {
                        property int size: 120
                        property bool isVertical: false
                        property bool showBackground: true
                        property string timeColorStyle: "onLayer0"
                        property string dateColorStyle: "primary"
                        property string pillColorStyle: "surfaceContainerHigh"
                    }
                    property JsonObject pillLocked: JsonObject {
                        property int size: 120
                        property bool isVertical: false
                        property bool showBackground: true
                        property string timeColorStyle: "onLayer0"
                        property string dateColorStyle: "primary"
                        property string pillColorStyle: "surfaceContainerHigh"
                    }
                }
            }

            // --- Bar ---
            property JsonObject bar: JsonObject {
                property bool show_network_speed: false
            }

            // --- Status Bar ---
            property JsonObject statusBar: JsonObject {
                property bool useGradient: true
                property int backgroundStyle: 0
                property string textColorMode: "adaptive" 
            }

            // --- Quick Settings ---
            property JsonObject quickSettings: JsonObject {
                property list<var> toggles: [
                    { "type": "wifi", "size": 2 },
                    { "type": "bluetooth", "size": 2 },
                    { "type": "dnd", "size": 1 },
                    { "type": "caffeine", "size": 1 },
                    { "type": "screenshot", "size": 1 },
                    { "type": "screenRecord", "size": 1 },
                    { "type": "googleLens", "size": 1 },
                    { "type": "screenSnip", "size": 1 },
                    { "type": "nightLight", "size": 1 },
                    { "type": "colorPicker", "size": 1 },
                    { "type": "powerProfile", "size": 2 },
                    { "type": "airplaneMode", "size": 1 },
                    { "type": "conservationMode", "size": 1 },
                    { "type": "systemUpdate", "size": 1 }
                ]
            }

            // --- Weather ---
            property JsonObject weather: JsonObject {
                property bool enable: true
                property bool autoLocation: true
                property string location: ""
                property string unit: "C" 
                property string provider: "open-meteo" 
                property bool showDailyForecast: true
                property int updateInterval: 30 
            }

            // --- Battery ---
            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
            }

            // --- Lock ---
            property JsonObject lock: JsonObject {
                property string wallpaperPath: ""
                property bool useSeparateWallpaper: false
                property JsonObject weather: JsonObject { property string textColorMode: "adaptive" }
            }

            // --- System ---
            property JsonObject system: JsonObject {
                property list<var> monitoredDisks: [ { "path": "/", "alias": "System" } ]
            }

            // --- Media ---
            property JsonObject media: JsonObject {
                property string priority: ""
                property bool enableMediaHover: true
                property string notchMediaStyle: "mini" 
            }
        }
    }
}
