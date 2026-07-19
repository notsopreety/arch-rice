pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string currentProvider: "yande.re"
    property string searchTags: ""
    property int currentPage: 1
    property bool isLoading: false
    property bool nsfwEnabled: false

    readonly property ListModel images: ListModel {}

    readonly property var providers: ({
        "yande.re": { 
            name: "Yande.re",
            url: "https://yande.re/post.json", 
            previewKey: "preview_url", 
            fullKey: "file_url", 
            sampleKey: "sample_url",
            tagsKey: "tags" 
        },
        "konachan": { 
            name: "Konachan",
            url: "https://konachan.net/post.json", 
            previewKey: "preview_url", 
            fullKey: "file_url", 
            sampleKey: "sample_url",
            tagsKey: "tags" 
        }
    })

    readonly property var providerList: ["yande.re", "konachan"]

    FileView {
        id: keyFile
        path: Quickshell.shellPath("settings.json")
        blockLoading: true
        blockWrites: true
        watchChanges: true
        onLoaded: {
            try {
                let content = keyFile.text().trim();
                if (content.length > 0) {
                    let obj = JSON.parse(content);
                    if (obj) {
                        let booru = obj.booru || {};
                        if (booru.currentProvider !== undefined) {
                            root.currentProvider = booru.currentProvider;
                        }
                        if (booru.nsfwEnabled !== undefined) {
                            root.nsfwEnabled = booru.nsfwEnabled;
                        }
                    }
                }
            } catch (e) {
                console.log("[BooruService] Failed to parse settings.json: " + e);
            }
        }
    }

    function saveSettings() {
        try {
            let obj = {};
            try {
                let currentContent = keyFile.text().trim();
                if (currentContent.length > 0) {
                    obj = JSON.parse(currentContent);
                }
            } catch (e) {}
            
            let booru = obj.booru || {};
            if (booru.currentProvider !== currentProvider || booru.nsfwEnabled !== nsfwEnabled) {
                booru.currentProvider = currentProvider;
                booru.nsfwEnabled = nsfwEnabled;
                obj.booru = booru;
                keyFile.setText(JSON.stringify(obj, null, 2));
            }
        } catch (e) {
            console.log("[BooruService] Failed to write settings.json: " + e);
        }
    }

    onCurrentProviderChanged: saveSettings()
    onNsfwEnabledChanged: saveSettings()

    function search(tags) {
        searchTags = tags;
        currentPage = 1;
        images.clear();
        fetchImages();
    }

    function loadMore() {
        if (isLoading) return;
        currentPage++;
        fetchImages();
    }

    function fetchImages() {
        isLoading = true;
        let config = providers[currentProvider];
        let url = config.url + "?page=" + currentPage + "&limit=20";

        let finalTags = searchTags;
        if (!nsfwEnabled) {
            finalTags += " rating:safe";
        }

        if (finalTags.trim() !== "") {
            url += "&tags=" + encodeURIComponent(finalTags.trim());
        }

        requestProcess.command = ["curl", "-sL", url];
        requestProcess.running = true;
    }

    Process {
        id: requestProcess
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let responseText = text.trim();
                    if (responseText.length === 0) return;
                    let arr = JSON.parse(responseText);
                    let config = providers[currentProvider];
                    if (Array.isArray(arr)) {
                        for (let i = 0; i < arr.length; i++) {
                            let item = arr[i];
                            let preview = item[config.previewKey] || "";
                            let full = item[config.fullKey] || "";
                            let sample = item[config.sampleKey] || full || "";
                            let tags = item[config.tagsKey] || "";
                            
                            if (preview && full) {
                                images.append({
                                    "previewUrl": preview,
                                    "fullUrl": full,
                                    "sampleUrl": sample,
                                    "tags": tags
                                });
                            }
                        }
                    }
                } catch (e) {
                    console.log("[BooruService] JSON parse error: " + e);
                }
                root.isLoading = false;
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.isLoading = false;
                console.log("[BooruService] Request failed with exit code: " + exitCode);
            }
        }
    }
}
