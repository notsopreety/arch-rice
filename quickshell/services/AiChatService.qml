pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal messageUpdated()

    property string apiKey: ""
    property string systemInstruction: ""
    property bool isStreaming: false
    property string currentModel: "gemini-2.5-flash"
    property real temperature: 0.7
    property string accumulatedResponse: ""
    property bool userInterrupted: false

    readonly property ListModel messages: ListModel {}

    readonly property bool _appInit: {
        Qt.application.organization = "quickshell"
        Qt.application.domain = "quickshell.org"
        Qt.application.name = "quickshell"
        return true
    }

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
                        let ai = obj.ai || {};
                        if (ai.apiKey !== undefined) {
                            root.apiKey = ai.apiKey;
                        }
                        if (ai.systemInstruction !== undefined) {
                            root.systemInstruction = ai.systemInstruction;
                        }
                        if (ai.currentModel !== undefined) {
                            root.currentModel = ai.currentModel;
                        }
                        if (ai.temperature !== undefined) {
                            root.temperature = ai.temperature;
                        }
                    }
                }
            } catch (e) {
                console.log("[AiChatService] Failed to parse settings.json: " + e);
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
            
            let ai = obj.ai || {};
            if (ai.apiKey !== apiKey || ai.systemInstruction !== systemInstruction || ai.currentModel !== currentModel || ai.temperature !== temperature) {
                ai.apiKey = apiKey;
                ai.systemInstruction = systemInstruction;
                ai.currentModel = currentModel;
                ai.temperature = temperature;
                obj.ai = ai;
                keyFile.setText(JSON.stringify(obj, null, 2));
            }
        } catch (e) {
            console.log("[AiChatService] Failed to write settings.json: " + e);
        }
    }

    onApiKeyChanged: saveSettings()
    onSystemInstructionChanged: saveSettings()
    onCurrentModelChanged: saveSettings()
    onTemperatureChanged: saveSettings()

    function stopGeneration() {
        if (apiProcess.running) {
            root.userInterrupted = true;
            apiProcess.running = false;
        }
    }

    function clearChat() {
        messages.clear();
    }

    function deleteMessage(index) {
        if (index >= 0 && index < messages.count) {
            messages.remove(index);
        }
    }

    function regenerateMessage(index) {
        if (index > 0 && index < messages.count && messages.get(index).role === "assistant") {
            // Cancel current process if running
            if (apiProcess.running) {
                apiProcess.running = false;
            }

            // Remove any messages after this assistant message
            while (messages.count > index + 1) {
                messages.remove(messages.count - 1);
            }

            let lastMsg = messages.get(index);
            lastMsg.content = "";
            lastMsg.isStreaming = true;

            startApiRequest(index);
        }
    }

    function editUserMessage(index, newText) {
        if (index >= 0 && index < messages.count && messages.get(index).role === "user") {
            // Cancel current process if running
            if (apiProcess.running) {
                apiProcess.running = false;
            }

            // Update user message content
            messages.get(index).content = newText;

            let assistantIndex = index + 1;
            if (assistantIndex < messages.count) {
                let assistantMsg = messages.get(assistantIndex);
                assistantMsg.content = "";
                assistantMsg.isStreaming = true;
            } else {
                messages.append({
                    "role": "assistant",
                    "content": "",
                    "isStreaming": true
                });
                assistantIndex = messages.count - 1;
            }

            // Remove any messages after the assistant message
            while (messages.count > assistantIndex + 1) {
                messages.remove(messages.count - 1);
            }

            startApiRequest(assistantIndex);
        }
    }

    function addMessage(role, content) {
        messages.append({
            "role": role,
            "content": content,
            "isStreaming": false
        });
    }

    function sendMessage(text) {
        if (text.trim() === "") return;
        if (!apiKey) {
            addMessage("error", "API Key is not set. Please set it using: /key YOUR_API_KEY");
            return;
        }

        // Add user message
        messages.append({
            "role": "user",
            "content": text,
            "isStreaming": false
        });

        // Add placeholder for streaming assistant response
        messages.append({
            "role": "assistant",
            "content": "",
            "isStreaming": true
        });

        startApiRequest(messages.count - 1);
    }

    function startApiRequest(assistantIndex) {
        root.isStreaming = true;

        let contents = [];
        // Add existing history up to assistantIndex - 1
        for (let i = 0; i < assistantIndex; i++) {
            let msg = messages.get(i);
            if (msg.role === "user") {
                contents.push({
                    "role": "user",
                    "parts": [{"text": msg.content}]
                });
            } else if (msg.role === "assistant") {
                contents.push({
                    "role": "model",
                    "parts": [{"text": msg.content}]
                });
            }
        }

        let payload = {
            "contents": contents,
            "generationConfig": {
                "temperature": root.temperature
            }
        };

        if (root.systemInstruction.trim() !== "") {
            payload["system_instruction"] = {
                "parts": [
                    { "text": root.systemInstruction }
                ]
            };
        }

        apiProcess.command = [
            "curl", "-sN", "-X", "POST",
            "https://generativelanguage.googleapis.com/v1beta/models/" + root.currentModel + ":streamGenerateContent?alt=sse&key=" + root.apiKey,
            "-H", "Content-Type: application/json",
            "-d", JSON.stringify(payload)
        ];
        
        root.accumulatedResponse = "";
        apiProcess.running = true;
    }

    Process {
        id: apiProcess
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.accumulatedResponse += data + "\n";
                let line = data.trim();
                if (line.startsWith("data: ")) {
                    let jsonStr = line.substring(6).trim();
                    if (jsonStr.length === 0) return;
                    try {
                        let json = JSON.parse(jsonStr);
                        if (json.candidates && json.candidates[0] && json.candidates[0].content && json.candidates[0].content.parts && json.candidates[0].content.parts[0]) {
                            let text = json.candidates[0].content.parts[0].text;
                            if (messages.count > 0) {
                                let lastMsg = messages.get(messages.count - 1);
                                if (lastMsg.role === "assistant") {
                                    lastMsg.content += text;
                                    root.messageUpdated();
                                }
                            }
                        }
                    } catch (e) {
                        console.log("[AiChatService] JSON parse error: " + e + " on string: " + jsonStr);
                    }
                } else if (line.indexOf("API_KEY_INVALID") !== -1 || line.indexOf("API key not valid") !== -1 || line.indexOf("INVALID_ARGUMENT") !== -1) {
                    if (messages.count > 0) {
                        let lastMsg = messages.get(messages.count - 1);
                        if (lastMsg.role === "assistant") {
                            lastMsg.content = "Error: Invalid API key! Please verify your Gemini API key and try again.";
                        }
                    }
                }
            }
        }

        onExited: exitCode => {
            root.isStreaming = false;
            if (messages.count > 0) {
                let lastMsg = messages.get(messages.count - 1);
                if (lastMsg.role === "assistant") {
                    lastMsg.isStreaming = false;
                    
                    if (root.userInterrupted) {
                        if (lastMsg.content === "") {
                            lastMsg.content = "Generation stopped.";
                        }
                        root.userInterrupted = false;
                        return;
                    }
                    
                    if (lastMsg.content === "") {
                        try {
                            let cleanText = root.accumulatedResponse.trim();
                            if (cleanText.startsWith("{")) {
                                let json = JSON.parse(cleanText);
                                if (json && json.error && json.error.message) {
                                    lastMsg.content = "Error: " + json.error.message;
                                } else {
                                    lastMsg.content = "Error: Quota exceeded or connection issue.";
                                }
                            } else {
                                lastMsg.content = "Error: " + (cleanText ? cleanText.substring(0, 150) : "Failed to connect to Gemini API.");
                            }
                        } catch (e) {
                            lastMsg.content = "Error: Process exited with code " + exitCode;
                        }
                    }
                }
            }
        }
    }
}
