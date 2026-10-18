pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/translator.py"

    // ── Languages ──
    property var languages: []
    property var byKey: ({})
    property bool available: true

    function ensureLanguages() {
        if (root.languages.length === 0 && !languagesProc.running)
            languagesProc.running = true;
    }

    function find(lang) {
        if (!lang) return null;
        let item = root.byKey[lang.toLowerCase()];
        return item !== undefined ? item : null;
    }

    function codeOf(lang) {
        if (!lang || lang === "auto") return "auto";
        let item = root.find(lang);
        return item && item.code ? item.code : lang;
    }

    function displayName(lang) {
        if (!lang || lang === "auto") return "Detect language";
        let item = root.find(lang);
        return item && item.endonym ? item.endonym : lang;
    }

    function englishName(lang) {
        if (!lang || lang === "auto") return "";
        let item = root.find(lang);
        return item && item.name ? item.name : "";
    }

    Process {
        id: languagesProc
        command: ["python3", root.helperPath, "languages"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rows = [];
                try {
                    rows = JSON.parse(this.text);
                } catch (e) {
                    rows = [];
                }
                if (!Array.isArray(rows)) {
                    if (rows && rows.error === "missing-trans")
                        root.available = false;
                    return;
                }
                rows.sort((a, b) => a.endonym.localeCompare(b.endonym));
                const keys = {};
                for (const row of rows) {
                    for (const name of [row.endonym, row.name]) {
                        if (keys[name.toLowerCase()] === undefined)
                            keys[name.toLowerCase()] = row;
                    }
                }
                for (const row of rows)
                    keys[row.code.toLowerCase()] = row;
                root.byKey = keys;
                root.languages = rows;
            }
        }
    }

    // ── Language Pair ──
    property string sourceLanguage: "auto"
    property string targetLanguage: "en"
    property int swapTurns: 0

    function setSource(lang) {
        if (!lang) return;
        root.sourceLanguage = root.codeOf(lang);
    }

    function setTarget(lang) {
        if (!lang || lang === "auto") return;
        root.targetLanguage = root.codeOf(lang);
    }

    function swap(detected) {
        let source = root.sourceLanguage;
        if (source === "auto") {
            if (!detected) return false;
            source = detected;
        }
        const target = root.targetLanguage;
        root.swapTurns++;
        root.sourceLanguage = target;
        root.targetLanguage = source;
        return true;
    }

    // ── Active Translation State ──
    property string inputText: ""
    readonly property string trimmed: root.inputText.trim()
    readonly property bool hasInput: root.trimmed.length > 0
    readonly property string sourceCode: root.codeOf(root.sourceLanguage)
    readonly property string targetCode: root.codeOf(root.targetLanguage)

    property var result: null
    property string error: ""
    property bool pending: false
    property bool busy: root.hasInput && (debounce.running || translateProc.running || root.pending)

    readonly property string translation: root.hasInput && root.result && root.result.translation ? root.result.translation : ""
    readonly property string transliteration: root.hasInput && root.result && root.result.transliteration ? root.result.transliteration : ""
    readonly property string sourceTransliteration: root.hasInput && root.result && root.result.sourceTransliteration ? root.result.sourceTransliteration : ""
    readonly property string detected: root.hasInput && root.result && root.result.detected ? root.result.detected : ""
    readonly property string correction: root.hasInput && root.result && root.result.correction ? root.result.correction : ""
    readonly property var alternatives: root.hasInput && root.result && root.result.alternatives ? root.result.alternatives : []
    readonly property var dictionary: root.hasInput && root.result && root.result.dictionary ? root.result.dictionary : []
    readonly property var synonyms: root.hasInput && root.result && root.result.synonyms ? root.result.synonyms : []
    readonly property var definitions: root.hasInput && root.result && root.result.definitions ? root.result.definitions : []
    readonly property var examples: root.hasInput && root.result && root.result.examples ? root.result.examples : []
    readonly property bool hasDictionary: root.synonyms.length > 0 || root.definitions.length > 0 || root.examples.length > 0
    readonly property string effectiveSource: root.sourceCode === "auto" ? (root.detected || "en") : root.sourceCode

    readonly property string requestKey: ["auto", "en", root.sourceCode, root.targetCode, root.trimmed].join("\u0001")

    onRequestKeyChanged: root.schedule()

    // ── Cache ──
    property var cache: ({})
    property var cacheOrder: []
    readonly property int cacheSize: 60

    function cached(key) {
        let val = root.cache[key];
        return val !== undefined ? val : null;
    }

    function remember(key, value) {
        if (root.cache[key] === undefined) {
            root.cacheOrder.push(key);
            if (root.cacheOrder.length > root.cacheSize)
                delete root.cache[root.cacheOrder.shift()];
        }
        root.cache[key] = value;
    }

    function schedule() {
        if (!root.hasInput) {
            debounce.stop();
            root.result = null;
            root.error = "";
            return;
        }
        const hit = root.cached(root.requestKey);
        if (hit) {
            debounce.stop();
            root.result = hit;
            root.error = "";
            return;
        }
        debounce.restart();
    }

    function retry() {
        root.error = "";
        root.startTranslate();
    }

    function startTranslate() {
        if (!root.hasInput) return;
        if (translateProc.running) {
            root.pending = true;
            return;
        }
        root.pending = false;
        translateProc.key = root.requestKey;
        translateProc.command = ["python3", root.helperPath, "translate", "auto", root.sourceCode, root.targetCode, "en", root.trimmed];
        translateProc.running = true;
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: root.startTranslate()
    }

    Process {
        id: translateProc
        property string key: ""
        property string output: ""
        property bool streamDone: false
        property bool exitDone: false

        onStarted: {
            output = "";
            streamDone = false;
            exitDone = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                translateProc.output = this.text;
                translateProc.streamDone = true;
                translateProc.settle();
            }
        }
        onExited: (exitCode, exitStatus) => {
            translateProc.exitDone = true;
            translateProc.settle();
        }

        function settle() {
            if (!streamDone || !exitDone) return;
            streamDone = false;
            exitDone = false;
            let parsed = null;
            try {
                parsed = JSON.parse(output);
            } catch (e) {
                parsed = null;
            }
            if (parsed && parsed.ok)
                root.remember(key, parsed);
            if (key === root.requestKey) {
                if (parsed && parsed.ok) {
                    root.result = parsed;
                    root.error = "";
                } else {
                    root.error = (parsed && parsed.error) ? parsed.error : "Translation failed";
                    if (root.error === "missing-trans")
                        root.available = false;
                }
            }
            if (root.pending) {
                root.pending = false;
                root.startTranslate();
            }
        }
    }

    // ── Speech ──
    property string speakingKey: ""

    function speak(key, text, lang) {
        const code = root.codeOf(lang);
        if (!text || text.trim().length === 0 || code === "auto")
            return;
        if (root.speakingKey === key) {
            root.stopSpeaking();
            return;
        }
        root.speakingKey = key;
        speakProc.command = ["python3", root.helperPath, "speak", code, text.trim()];
        speakProc.running = true;
    }

    function stopSpeaking() {
        root.speakingKey = "";
        if (speakProc.running) {
            speakProc.running = false;
        }
    }

    Process {
        id: speakProc
        onExited: {
            root.speakingKey = "";
        }
    }
}
