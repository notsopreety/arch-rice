import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import "../../theme"
import "../../services"
import "../../components"

Item {
    id: root

    property bool isConfiguringKey: !AiChatService.apiKey
    property bool showKeyText: false
    property bool showModelSelector: false

    onIsConfiguringKeyChanged: {
        if (isConfiguringKey) {
            keyInput.text = AiChatService.apiKey;
            systemInstructionInput.text = AiChatService.systemInstruction;
            keyInput.forceActiveFocus();
        } else {
            messageField.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (isConfiguringKey) {
            keyInput.text = AiChatService.apiKey;
            systemInstructionInput.text = AiChatService.systemInstruction;
            keyInput.forceActiveFocus();
        }
    }

    // Capture Escape key to close the key configuration page
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (isConfiguringKey && AiChatService.apiKey) {
                isConfiguringKey = false;
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ── Status bar (Centered Key toggle button) ──
        RowLayout {
            Layout.fillWidth: true
            height: 36

            Item { Layout.fillWidth: true }

            // Centered API Key toggle button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Qt.rgba(255, 255, 255, 0.06)
                border.color: Qt.rgba(255, 255, 255, 0.12)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰌆"
                    font.family: Theme.font.monospace
                    font.pixelSize: 15
                    color: isConfiguringKey ? Theme.primary : "white"
                }

                HoverHandler { id: keyHover }
                QQC.ToolTip {
                    visible: keyHover.hovered
                    delay: 200
                    y: -height - 4
                    contentItem: Text {
                        text: isConfiguringKey ? "Close Key Settings" : "Configure API Key"
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.primary
                    }
                    background: Rectangle {
                        color: Theme.surfaceContainer
                        border.color: Theme.outline
                        border.width: 1
                        radius: 8
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isConfiguringKey) {
                            if (AiChatService.apiKey) {
                                isConfiguringKey = false;
                            }
                        } else {
                            isConfiguringKey = true;
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ── Chat Area ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Placeholder / Setup when configuring API key
            Column {
                anchors.centerIn: parent
                spacing: 14
                visible: isConfiguringKey
                width: parent.width - 40

                Text {
                    text: "󰚩"
                    font.family: Theme.font.monospace
                    font.pixelSize: 48
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "AI Assistant Settings"
                    font.family: Theme.font.family
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Configure your Gemini API key and system behavior instructions below."
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    color: Qt.rgba(255, 255, 255, 0.4)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // API Key Section
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "API Key"
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: Theme.rounding.normal
                        color: Qt.rgba(255, 255, 255, 0.05)
                        border.color: Qt.rgba(255, 255, 255, 0.1)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 6
                            spacing: 6

                            QQC.TextField {
                                id: keyInput
                                Layout.fillWidth: true
                                placeholderText: "Paste Gemini API Key..."
                                placeholderTextColor: Qt.rgba(255, 255, 255, 0.3)
                                color: "white"
                                echoMode: root.showKeyText ? TextInput.Normal : TextInput.Password
                                background: null
                                font.family: Theme.font.family
                                font.pixelSize: 13

                                Keys.onEscapePressed: (event) => {
                                    if (AiChatService.apiKey) {
                                        isConfiguringKey = false;
                                        event.accepted = true;
                                    }
                                }
                            }

                            // Eye Icon Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: Qt.rgba(255, 255, 255, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: root.showKeyText ? "󰈈" : "󰈉"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 13
                                    color: Qt.rgba(255, 255, 255, 0.7)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.showKeyText = !root.showKeyText
                                }
                            }
                        }
                    }
                }

                // System Instruction Section
                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "System Instruction"
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Rectangle {
                        width: parent.width
                        height: 100
                        radius: Theme.rounding.normal
                        color: Qt.rgba(255, 255, 255, 0.05)
                        border.color: Qt.rgba(255, 255, 255, 0.1)
                        border.width: 1

                        QQC.ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            QQC.TextArea {
                                id: systemInstructionInput
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                color: "white"
                                wrapMode: Text.Wrap
                                placeholderText: "e.g., You are a helpful assistant..."
                                placeholderTextColor: Qt.rgba(255, 255, 255, 0.3)
                                background: null
                                padding: 0
                                selectByMouse: true
                            }
                        }
                    }
                }

                // Save Button
                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 8
                    color: Theme.primary

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰄬"
                            font.family: Theme.font.monospace
                            font.pixelSize: 15
                            color: Theme.background
                        }
                        Text {
                            text: "Save Settings"
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.background
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiChatService.apiKey = keyInput.text.trim();
                            AiChatService.systemInstruction = systemInstructionInput.text.trim();
                            isConfiguringKey = false;
                        }
                    }
                }
            }

            // Chat messages list
            ListView {
                id: chatList
                anchors.fill: parent
                visible: !isConfiguringKey
                model: AiChatService.messages
                spacing: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Hide scrollbar
                QQC.ScrollBar.vertical: QQC.ScrollBar {
                    policy: QQC.ScrollBar.AlwaysOff
                }

                delegate: MessageBubble {
                    width: chatList.width
                    role: model.role
                    content: model.content
                    isStreaming: model.isStreaming
                    messageIndex: index
                }

                Connections {
                    target: AiChatService
                    function onMessageUpdated() {
                        chatList.positionViewAtEnd();
                    }
                }

                onCountChanged: {
                    Qt.callLater(() => chatList.positionViewAtEnd());
                }
            }

            // Scroll to bottom button floating when scrolled up
            Rectangle {
                id: scrollToBottomBtn
                width: 32
                height: 32
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.7)
                border.color: Qt.rgba(255, 255, 255, 0.12)
                border.width: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !chatList.atYEnd && chatList.count > 0 && !isConfiguringKey

                Text {
                    anchors.centerIn: parent
                    text: "󰁆"
                    font.family: Theme.font.monospace
                    font.pixelSize: 14
                    color: Theme.primary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        chatList.positionViewAtEnd();
                    }
                }
            }

            // Empty chat placeholder (key set but no messages)
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: !isConfiguringKey && AiChatService.messages.count === 0

                Text {
                    text: "󰚩"
                    font.family: Theme.font.monospace
                    font.pixelSize: 48
                    color: Qt.rgba(1, 1, 1, 0.15)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Ask anything...\nType /clear to clear chat"
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.3)
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // ── Command Autocomplete Overlay ──
        Rectangle {
            id: commandPopup
            Layout.fillWidth: true
            implicitHeight: commandCol.implicitHeight + 16
            radius: Theme.rounding.normal
            color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.98)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1
            visible: messageField.text.startsWith("/") && !AiChatService.isStreaming && !isConfiguringKey

            ColumnLayout {
                id: commandCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    text: "Available Commands"
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 4
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 6
                    color: clearMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "/clear"
                            font.family: Theme.font.monospace
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "white"
                        }
                        Text {
                            text: "Clear all messages from chat history"
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.5)
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            messageField.text = "";
                            AiChatService.clearChat();
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 6
                    color: keyMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "/key"
                            font.family: Theme.font.monospace
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: "white"
                        }
                        Text {
                            text: "Open API key settings screen"
                            font.family: Theme.font.family
                            font.pixelSize: 11
                            color: Qt.rgba(1, 1, 1, 0.5)
                        }
                    }

                    MouseArea {
                        id: keyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            messageField.text = "";
                            root.isConfiguringKey = true;
                        }
                    }
                }
            }
        }

        // ── Model Selection Overlay ──
        Rectangle {
            id: modelPopup
            Layout.fillWidth: true
            implicitHeight: modelPopupCol.implicitHeight + 16
            radius: Theme.rounding.normal
            color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.98)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1
            visible: root.showModelSelector && !isConfiguringKey

            ColumnLayout {
                id: modelPopupCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    text: "Select Model"
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 4
                }

                Repeater {
                    model: [
                        { name: "Gemini 3.5 Flash", id: "gemini-3.5-flash" },
                        { name: "Gemini 3.1 Flash Lite", id: "gemini-3.1-flash-lite" },
                        { name: "Gemini 2.5 Flash", id: "gemini-2.5-flash" },
                        { name: "Gemini 2.5 Flash Lite", id: "gemini-2.5-flash-lite" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 6
                        color: modelItemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.name
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                font.weight: AiChatService.currentModel === modelData.id ? Font.Bold : Font.Normal
                                color: AiChatService.currentModel === modelData.id ? Theme.primary : "white"
                            }
                            
                            Item { Layout.fillWidth: true }

                            Text {
                                text: "󰄬"
                                font.family: Theme.font.monospace
                                font.pixelSize: 12
                                color: Theme.primary
                                visible: AiChatService.currentModel === modelData.id
                            }
                        }

                        MouseArea {
                            id: modelItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AiChatService.currentModel = modelData.id;
                                root.showModelSelector = false;
                            }
                        }
                    }
                }
            }
        }

        // ── Input Composer ──
        Rectangle {
            id: promptComposer
            Layout.fillWidth: true
            implicitHeight: composerCol.implicitHeight + 16
            radius: 12
            color: Qt.rgba(30/255, 27/255, 36/255, 0.65)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1
            visible: !isConfiguringKey

            function sendMessageTriggered() {
                root.showModelSelector = false;
                let txt = messageField.text.trim();
                if (txt === "/clear") {
                    messageField.text = "";
                    AiChatService.clearChat();
                } else if (txt === "/key") {
                    messageField.text = "";
                    root.isConfiguringKey = true;
                } else if (txt !== "" && !AiChatService.isStreaming) {
                    messageField.text = "";
                    AiChatService.sendMessage(txt);
                }
            }

            ColumnLayout {
                id: composerCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Top Row: Text Input and Send Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    QQC.TextArea {
                        id: messageField
                        Layout.fillWidth: true
                        placeholderText: "Message the model... \"/\" for commands"
                        placeholderTextColor: Qt.rgba(255, 255, 255, 0.35)
                        color: "white"
                        background: null
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        enabled: !AiChatService.isStreaming
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        topPadding: 6
                        bottomPadding: 6
                        leftPadding: 0
                        rightPadding: 0
                        implicitHeight: Math.min(120, Math.max(30, contentHeight + 12))

                        onTextChanged: {
                            if (text.startsWith("/")) {
                                root.showModelSelector = false;
                            }
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = false;
                                } else {
                                    event.accepted = true;
                                    promptComposer.sendMessageTriggered();
                                }
                            }
                        }
                    }

                    // Send / Stop Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: {
                            if (AiChatService.isStreaming) return "#ef4444" // ChatGPT red
                            return messageField.text.trim() !== "" ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                        }
                        border.color: {
                            if (AiChatService.isStreaming) return "transparent"
                            return messageField.text.trim() !== "" ? Qt.rgba(255, 255, 255, 0.15) : "transparent"
                        }
                        border.width: 1

                        DankIcon {
                            anchors.centerIn: parent
                            name: AiChatService.isStreaming ? "stop" : "arrow_upward"
                            size: 12
                            color: {
                                if (AiChatService.isStreaming) return "white"
                                return messageField.text.trim() !== "" ? "white" : Qt.rgba(255, 255, 255, 0.25)
                            }
                            filled: AiChatService.isStreaming
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: (AiChatService.isStreaming || messageField.text.trim() !== "") ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (AiChatService.isStreaming) {
                                    AiChatService.stopGeneration();
                                } else {
                                    promptComposer.sendMessageTriggered();
                                }
                            }
                        }
                    }
                }

                // Bottom Row: Model Selector, / button, /clear button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Model selector button
                    Rectangle {
                        height: 26
                        implicitWidth: modelRow.implicitWidth + 16
                        radius: 13
                        color: modelHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        RowLayout {
                            id: modelRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰜎"
                                font.family: Theme.font.monospace
                                font.pixelSize: 12
                                color: Qt.rgba(255, 255, 255, 0.7)
                            }
                            Text {
                                text: {
                                    switch(AiChatService.currentModel) {
                                        case "gemini-3.5-flash": return "Gemini 3.5 Flash";
                                        case "gemini-3.1-flash-lite": return "Gemini 3.1 Flash Lite";
                                        case "gemini-2.5-flash": return "Gemini 2.5 Flash";
                                        case "gemini-2.5-flash-lite": return "Gemini 2.5 Flash Lite";
                                        default: return AiChatService.currentModel;
                                    }
                                }
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                color: Qt.rgba(255, 255, 255, 0.8)
                            }
                        }

                        HoverHandler { id: modelHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.showModelSelector = !root.showModelSelector;
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // "/" button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: slashHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "/"
                            font.family: Theme.font.monospace
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Qt.rgba(255, 255, 255, 0.7)
                        }

                        HoverHandler { id: slashHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!messageField.text.startsWith("/")) {
                                    messageField.text = "/" + messageField.text;
                                }
                                messageField.forceActiveFocus();
                            }
                        }
                    }

                    // "/clear" button
                    Rectangle {
                        height: 26
                        implicitWidth: clearText.implicitWidth + 16
                        radius: 13
                        color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "/clear"
                            font.family: Theme.font.monospace
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Qt.rgba(255, 255, 255, 0.8)
                        }

                        HoverHandler { id: clearHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                messageField.text = "";
                                AiChatService.clearChat();
                            }
                        }
                    }
                }
            }
        }
    }
}
