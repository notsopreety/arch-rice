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
        },
        "danbooru": { 
            name: "Danbooru",
            url: "https://danbooru.donmai.us/posts.json", 
            previewKey: "preview_file_url", 
            fullKey: "file_url", 
            sampleKey: "large_file_url",
            tagsKey: "tag_string" 
        }
    })

    readonly property var providerList: ["yande.re", "konachan", "danbooru"]

    readonly property bool _appInit: {
        Qt.application.organization = "quickshell"
        Qt.application.domain = "quickshell.org"
        Qt.application.name = "quickshell"
        return true
    }

    Settings {
        id: settings
        category: "BooruService"
        property alias currentProvider: root.currentProvider
        property alias nsfwEnabled: root.nsfwEnabled
    }

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
            if (currentProvider === "danbooru") {
                finalTags += " rating:g";
            } else {
                finalTags += " rating:safe";
            }
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
