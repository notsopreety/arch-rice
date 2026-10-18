import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"
import ".."

Item {
    id: root

    property bool isConfiguringKey: !AiChatService.apiKey
    property bool showKeyText: false
    property bool showModelSelector: false
    property bool showSystemPrompt: false
    property int historyIndex: -1
    property string historyDraft: ""

    onIsConfiguringKeyChanged: {
        if (isConfiguringKey) {
            keyInput.text = AiChatService.apiKey;
            keyInput.forceActiveFocus();
        } else {
            messageField.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (isConfiguringKey) {
            keyInput.text = AiChatService.apiKey;
            keyInput.forceActiveFocus();
        } else {
            messageField.forceActiveFocus();
        }
    }

    // Capture Escape key to close popups
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (showModelSelector) {
                showModelSelector = false;
                event.accepted = true;
            } else if (showSystemPrompt) {
                showSystemPrompt = false;
                event.accepted = true;
            } else if (isConfiguringKey && AiChatService.apiKey) {
                isConfiguringKey = false;
                event.accepted = true;
            }
        }
    }

    function sendPrompt(text) {
        if (!text || text.trim() === "") return;
        messageField.text = "";
        historyIndex = -1;
        historyDraft = "";
        showModelSelector = false;
        showSystemPrompt = false;
        isConfiguringKey = false;
        AiChatService.sendMessage(text.trim());
    }

    function stepHistory(delta) {
        let hist = AiChatService.promptHistory;
        if (!hist || hist.length === 0) return;
        if (historyIndex === -1) {
            if (delta > 0) return;
            historyDraft = messageField.text;
            historyIndex = hist.length - 1;
        } else {
            let next = historyIndex + delta;
            if (next < 0) return;
            if (next >= hist.length) {
                historyIndex = -1;
                messageField.text = historyDraft;
                messageField.cursorPosition = messageField.text.length;
                return;
            }
            historyIndex = next;
        }
        messageField.text = hist[historyIndex];
        messageField.cursorPosition = messageField.text.length;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * Appearance.effectiveScale

        // ════════════════════════════════════════════════════════
        // 1. TOP TOOLS BAR (Pill Control Surface)
        // ════════════════════════════════════════════════════════
        Rectangle {
            id: toolsBar
            Layout.fillWidth: true
            height: 38 * Appearance.effectiveScale
            radius: Theme.rounding.full
            color: Qt.rgba(255, 255, 255, 0.06)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10 * Appearance.effectiveScale
                anchors.rightMargin: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // ── Model Selector Chip ──
                Rectangle {
                    id: modelChip
                    height: 26 * Appearance.effectiveScale
                    Layout.maximumWidth: Math.max(120 * Appearance.effectiveScale, toolsBar.width - 150 * Appearance.effectiveScale)
                    implicitWidth: Math.min(Layout.maximumWidth, modelChipRow.implicitWidth + 16 * Appearance.effectiveScale)
                    radius: 13 * Appearance.effectiveScale
                    clip: true
                    color: modelChipMouse.containsMouse || showModelSelector ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : Qt.rgba(255, 255, 255, 0.06)
                    border.color: showModelSelector ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    RowLayout {
                        id: modelChipRow
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale

                        DankIcon {
                            name: "wand_stars"
                            size: 13 * Appearance.effectiveScale
                            color: showModelSelector ? Theme.primary : "#c084fc"
                            filled: true
                        }

                        Text {
                            text: {
                                let m = AiChatService.currentModel;
                                let isShort = toolsBar.width < 390 * Appearance.effectiveScale;
                                switch(m) {
                                    case "gemini-2.5-flash": return isShort ? "2.5 Flash" : "Gemini 2.5 Flash";
                                    case "gemini-2.5-pro": return isShort ? "2.5 Pro" : "Gemini 2.5 Pro";
                                    case "gemini-2.5-flash-lite": return isShort ? "Flash Lite" : "Gemini 2.5 Flash Lite";
                                    case "gemini-1.5-flash": return isShort ? "1.5 Flash" : "Gemini 1.5 Flash";
                                    default: return m;
                                }
                            }
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            color: showModelSelector ? Theme.primary : "white"
                            elide: Text.ElideRight
                        }

                        DankIcon {
                            name: "expand_more"
                            size: 14 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.6)
                        }
                    }

                    MouseArea {
                        id: modelChipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showModelSelector = !root.showModelSelector;
                            root.showSystemPrompt = false;
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ── New Chat Button ──
                Rectangle {
                    width: 28 * Appearance.effectiveScale
                    height: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: newChatMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "add_comment"
                        size: 15 * Appearance.effectiveScale
                        color: newChatMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                    }

                    StyledToolTip {
                        text: "New chat"
                        alternativeVisibleCondition: newChatMouse.containsMouse
                    }

                    MouseArea {
                        id: newChatMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiChatService.clearChat();
                            root.showModelSelector = false;
                            root.showSystemPrompt = false;
                            root.isConfiguringKey = false;
                            messageField.forceActiveFocus();
                        }
                    }
                }

                // ── System Prompt / Persona Button ──
                Rectangle {
                    width: 28 * Appearance.effectiveScale
                    height: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: promptMouse.containsMouse || showSystemPrompt ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "assignment"
                        size: 15 * Appearance.effectiveScale
                        color: showSystemPrompt ? Theme.primary : (promptMouse.containsMouse ? "white" : Qt.rgba(255, 255, 255, 0.7))
                    }

                    StyledToolTip {
                        text: "System prompt / instructions"
                        alternativeVisibleCondition: promptMouse.containsMouse
                    }

                    MouseArea {
                        id: promptMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showSystemPrompt = !root.showSystemPrompt;
                            root.showModelSelector = false;
                        }
                    }
                }

                // ── API Key Settings Button ──
                Rectangle {
                    width: 28 * Appearance.effectiveScale
                    height: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: keyBtnMouse.containsMouse || isConfiguringKey ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "key"
                        size: 15 * Appearance.effectiveScale
                        color: isConfiguringKey ? Theme.primary : (keyBtnMouse.containsMouse ? "white" : Qt.rgba(255, 255, 255, 0.7))
                    }

                    StyledToolTip {
                        text: isConfiguringKey ? "Close Key Settings" : "Configure API Key"
                        alternativeVisibleCondition: keyBtnMouse.containsMouse
                    }

                    MouseArea {
                        id: keyBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (isConfiguringKey) {
                                if (AiChatService.apiKey) {
                                    isConfiguringKey = false;
                                }
                            } else {
                                isConfiguringKey = true;
                                showModelSelector = false;
                                showSystemPrompt = false;
                            }
                        }
                    }
                }

                // ── Clear Chat Button ──
                Rectangle {
                    width: 28 * Appearance.effectiveScale
                    height: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: clearBtnMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : "transparent"
                    visible: AiChatService.messages.count > 0

                    DankIcon {
                        anchors.centerIn: parent
                        name: "delete_sweep"
                        size: 16 * Appearance.effectiveScale
                        color: clearBtnMouse.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.7)
                    }

                    StyledToolTip {
                        text: "Clear chat history"
                        alternativeVisibleCondition: clearBtnMouse.containsMouse
                    }

                    MouseArea {
                        id: clearBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiChatService.clearChat();
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════
        // 2. CENTER CHAT AREA SURFACE
        // ════════════════════════════════════════════════════════
        Rectangle {
            id: chatSurface
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.rounding.large
            color: Qt.rgba(0, 0, 0, 0.2)
            border.color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            clip: true

            // ── A. Configure API Key View ──
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 48 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                visible: isConfiguringKey

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56 * Appearance.effectiveScale
                    height: 56 * Appearance.effectiveScale
                    radius: 28 * Appearance.effectiveScale
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
                    border.width: 1

                    DankIcon {
                        anchors.centerIn: parent
                        name: "key"
                        size: 28 * Appearance.effectiveScale
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Gemini API Key Setup"
                        font.family: Theme.font.family
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: "white"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Enter your Google Gemini API key to activate the assistant."
                        font.family: Theme.font.family
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.5)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 42 * Appearance.effectiveScale
                    radius: Theme.rounding.normal
                    color: Qt.rgba(255, 255, 255, 0.06)
                    border.color: keyInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.12)
                    border.width: keyInput.activeFocus ? 1.5 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * Appearance.effectiveScale
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        QQC.TextField {
                            id: keyInput
                            Layout.fillWidth: true
                            placeholderText: "Paste AIzaSy... API key"
                            placeholderTextColor: Qt.rgba(255, 255, 255, 0.35)
                            color: "white"
                            echoMode: root.showKeyText ? TextInput.Normal : TextInput.Password
                            background: null
                            font.family: Theme.font.family
                            font.pixelSize: 12 * Appearance.effectiveScale
                            selectByMouse: true
                        }

                        Rectangle {
                            width: 26 * Appearance.effectiveScale
                            height: 26 * Appearance.effectiveScale
                            radius: 13 * Appearance.effectiveScale
                            color: eyeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                            DankIcon {
                                anchors.centerIn: parent
                                name: root.showKeyText ? "visibility" : "visibility_off"
                                size: 16 * Appearance.effectiveScale
                                color: Qt.rgba(255, 255, 255, 0.7)
                            }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showKeyText = !root.showKeyText
                            }
                        }
                    }
                }

                // Save button
                Rectangle {
                    Layout.fillWidth: true
                    height: 36 * Appearance.effectiveScale
                    radius: 18 * Appearance.effectiveScale
                    color: Theme.primary

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6 * Appearance.effectiveScale

                        DankIcon {
                            name: "check"
                            size: 16 * Appearance.effectiveScale
                            color: Theme.onPrimary
                        }

                        Text {
                            text: "Save & Continue"
                            font.family: Theme.font.family
                            font.pixelSize: 12 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: Theme.onPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AiChatService.apiKey = keyInput.text.trim();
                            if (AiChatService.apiKey) {
                                isConfiguringKey = false;
                            }
                        }
                    }
                }
            }

            // ── B. Empty State with Greeting & Suggestion Chips ──
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 32 * Appearance.effectiveScale
                spacing: 18 * Appearance.effectiveScale
                visible: !isConfiguringKey && AiChatService.messages.count === 0

                // Header Emblem & Greetings
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6 * Appearance.effectiveScale

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 54 * Appearance.effectiveScale
                        height: 54 * Appearance.effectiveScale
                        radius: 27 * Appearance.effectiveScale
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                        border.width: 1

                        DankIcon {
                            anchors.centerIn: parent
                            name: "wand_stars"
                            size: 26 * Appearance.effectiveScale
                            color: Theme.primary
                            filled: true
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "How can I help you today?"
                        font.family: Theme.font.family
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: "white"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Ask questions, generate ideas, or analyze code."
                        font.family: Theme.font.family
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.45)
                    }
                }

                // Suggestion Cards (Responsive 1 or 2 Columns)
                GridLayout {
                    Layout.fillWidth: true
                    columns: root.width >= 460 * Appearance.effectiveScale ? 2 : 1
                    rowSpacing: 8 * Appearance.effectiveScale
                    columnSpacing: 8 * Appearance.effectiveScale

                    Repeater {
                        model: [
                            {
                                icon: "lightbulb",
                                title: "Brainstorm ideas",
                                prompt: "Give me 5 creative ideas for a desktop app built with Quickshell and QtQuick."
                            },
                            {
                                icon: "code",
                                title: "Explain code",
                                prompt: "Explain how async/await works under the hood in modern JavaScript."
                            },
                            {
                                icon: "summarize",
                                title: "Summarize notes",
                                prompt: "Summarize the architectural differences between Wayland and X11."
                            },
                            {
                                icon: "edit_note",
                                title: "Draft message",
                                prompt: "Help me write a concise, professional follow-up message to a colleague."
                            }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: (root.width >= 460 * Appearance.effectiveScale ? 62 : 50) * Appearance.effectiveScale
                            radius: Theme.rounding.normal
                            color: cardMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14) : Qt.rgba(255, 255, 255, 0.06)
                            border.color: cardMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10 * Appearance.effectiveScale
                                spacing: 8 * Appearance.effectiveScale

                                DankIcon {
                                    name: modelData.icon
                                    size: 18 * Appearance.effectiveScale
                                    color: cardMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2 * Appearance.effectiveScale

                                    Text {
                                        text: modelData.title
                                        font.family: Theme.font.family
                                        font.pixelSize: 11 * Appearance.effectiveScale
                                        font.weight: Font.DemiBold
                                        color: cardMouse.containsMouse ? Theme.primary : "white"
                                    }

                                    Text {
                                        text: modelData.prompt
                                        font.family: Theme.font.family
                                        font.pixelSize: 9.5 * Appearance.effectiveScale
                                        color: Qt.rgba(255, 255, 255, 0.4)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendPrompt(modelData.prompt)
                            }
                        }
                    }
                }
            }

            // ── C. Chat Messages ListView ──
            ListView {
                id: chatList
                anchors.fill: parent
                anchors.margins: 10 * Appearance.effectiveScale
                visible: !isConfiguringKey && AiChatService.messages.count > 0
                model: AiChatService.messages
                spacing: 14 * Appearance.effectiveScale
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                QQC.ScrollBar.vertical: QQC.ScrollBar {
                    policy: QQC.ScrollBar.AsNeeded
                }

                delegate: MessageBubble {
                    width: chatList.width - 8 * Appearance.effectiveScale
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

            // ── Floating Scroll-to-Bottom Button ──
            Rectangle {
                id: scrollToBottomBtn
                width: 34 * Appearance.effectiveScale
                height: 34 * Appearance.effectiveScale
                radius: 17 * Appearance.effectiveScale
                color: scrollMouse.containsMouse ? Theme.primary : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.9)
                border.color: Theme.primary
                border.width: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14 * Appearance.effectiveScale
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !chatList.atYEnd && chatList.count > 0 && !isConfiguringKey

                DankIcon {
                    anchors.centerIn: parent
                    name: "arrow_downward"
                    size: 16 * Appearance.effectiveScale
                    color: scrollMouse.containsMouse ? Theme.onPrimary : Theme.primary
                }

                MouseArea {
                    id: scrollMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chatList.positionViewAtEnd()
                }
            }

            // ── Floating Model Selector Sheet ──
            Rectangle {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                radius: Theme.rounding.normal
                color: Qt.rgba(18/255, 22/255, 25/255, 0.96)
                border.color: Qt.rgba(255, 255, 255, 0.12)
                border.width: 1
                visible: root.showModelSelector
                z: 50

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Select AI Model"
                            font.family: Theme.font.family
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "white"
                        }

                        Item { Layout.fillWidth: true }

                        DankIcon {
                            name: "close"
                            size: 18 * Appearance.effectiveScale
                            color: closeModelMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)

                            MouseArea {
                                id: closeModelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showModelSelector = false
                            }
                        }
                    }

                    QQC.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 8 * Appearance.effectiveScale

                            Repeater {
                                model: [
                                    {
                                        id: "gemini-2.5-flash",
                                        name: "Gemini 2.5 Flash",
                                        badge: "Default",
                                        desc: "Next-gen balanced model with fast generation and strong reasoning."
                                    },
                                    {
                                        id: "gemini-2.5-pro",
                                        name: "Gemini 2.5 Pro",
                                        badge: "Reasoning",
                                        desc: "Best performance for complex code, mathematics, and intricate logic."
                                    },
                                    {
                                        id: "gemini-2.5-flash-lite",
                                        name: "Gemini 2.5 Flash Lite",
                                        badge: "Fastest",
                                        desc: "Extremely responsive, lightweight model for quick questions."
                                    },
                                    {
                                        id: "gemini-1.5-flash",
                                        name: "Gemini 1.5 Flash",
                                        badge: "Stable",
                                        desc: "High throughput general purpose model."
                                    }
                                ]

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 52 * Appearance.effectiveScale
                                    radius: Theme.rounding.small
                                    color: (AiChatService.currentModel === modelData.id)
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                                        : (itemHover.hovered ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                    border.color: (AiChatService.currentModel === modelData.id) ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                                    border.width: 1

                                    HoverHandler { id: itemHover }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12 * Appearance.effectiveScale
                                        anchors.rightMargin: 12 * Appearance.effectiveScale
                                        spacing: 8 * Appearance.effectiveScale

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2 * Appearance.effectiveScale

                                            RowLayout {
                                                spacing: 6 * Appearance.effectiveScale

                                                Text {
                                                    text: modelData.name
                                                    font.family: Theme.font.family
                                                    font.pixelSize: 12 * Appearance.effectiveScale
                                                    font.weight: Font.DemiBold
                                                    color: (AiChatService.currentModel === modelData.id) ? Theme.primary : "white"
                                                }

                                                Rectangle {
                                                    height: 16 * Appearance.effectiveScale
                                                    implicitWidth: badgeTxt.implicitWidth + 8 * Appearance.effectiveScale
                                                    radius: 8 * Appearance.effectiveScale
                                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)

                                                    Text {
                                                        id: badgeTxt
                                                        anchors.centerIn: parent
                                                        text: modelData.badge
                                                        font.family: Theme.font.family
                                                        font.pixelSize: 9 * Appearance.effectiveScale
                                                        font.weight: Font.Bold
                                                        color: Theme.primary
                                                    }
                                                }
                                            }

                                            Text {
                                                text: modelData.desc
                                                font.family: Theme.font.family
                                                font.pixelSize: 9.5 * Appearance.effectiveScale
                                                color: Qt.rgba(255, 255, 255, 0.45)
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }

                                        DankIcon {
                                            name: "check"
                                            size: 16 * Appearance.effectiveScale
                                            color: Theme.primary
                                            visible: AiChatService.currentModel === modelData.id
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
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
                }
            }

            // ── Floating System Prompt / Persona Sheet ──
            Rectangle {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                radius: Theme.rounding.normal
                color: Qt.rgba(18/255, 22/255, 25/255, 0.96)
                border.color: Qt.rgba(255, 255, 255, 0.12)
                border.width: 1
                visible: root.showSystemPrompt
                z: 50

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "System Instructions"
                            font.family: Theme.font.family
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: Font.Bold
                            color: "white"
                        }

                        Item { Layout.fillWidth: true }

                        DankIcon {
                            name: "close"
                            size: 18 * Appearance.effectiveScale
                            color: closePromptMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)

                            MouseArea {
                                id: closePromptMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showSystemPrompt = false
                            }
                        }
                    }

                    Text {
                        text: "Define how the assistant should behave and structure its answers."
                        font.family: Theme.font.family
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.45)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.rounding.small
                        color: Qt.rgba(255, 255, 255, 0.06)
                        border.color: systemPromptField.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                        border.width: systemPromptField.activeFocus ? 1.5 : 1

                        QQC.ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10 * Appearance.effectiveScale
                            clip: true

                            QQC.TextArea {
                                id: systemPromptField
                                text: AiChatService.systemInstruction
                                placeholderText: "e.g., You are an expert Arch Linux developer who gives concise, highly technical explanations."
                                placeholderTextColor: Qt.rgba(255, 255, 255, 0.3)
                                color: "white"
                                font.family: Theme.font.family
                                font.pixelSize: 12 * Appearance.effectiveScale
                                wrapMode: Text.Wrap
                                background: null
                                selectByMouse: true
                            }
                        }
                    }

                    // Save Button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36 * Appearance.effectiveScale
                        radius: 18 * Appearance.effectiveScale
                        color: Theme.primary

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6 * Appearance.effectiveScale

                            DankIcon {
                                name: "check"
                                size: 16 * Appearance.effectiveScale
                                color: Theme.onPrimary
                            }

                            Text {
                                text: "Apply Instructions"
                                font.family: Theme.font.family
                                font.pixelSize: 12 * Appearance.effectiveScale
                                font.weight: Font.Bold
                                color: Theme.onPrimary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AiChatService.systemInstruction = systemPromptField.text.trim();
                                root.showSystemPrompt = false;
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════
        // 3. BOTTOM COMPOSER SURFACE
        // ════════════════════════════════════════════════════════
        Rectangle {
            id: composerSurface
            Layout.fillWidth: true
            implicitHeight: composerCol.implicitHeight + 14 * Appearance.effectiveScale
            radius: Theme.rounding.large
            color: Qt.rgba(255, 255, 255, 0.06)
            border.color: messageField.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.12)
            border.width: messageField.activeFocus ? 1.5 : 1
            visible: !isConfiguringKey

            ColumnLayout {
                id: composerCol
                anchors.fill: parent
                anchors.margins: 10 * Appearance.effectiveScale
                spacing: 6 * Appearance.effectiveScale

                // Multi-line Text Area Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    QQC.TextArea {
                        id: messageField
                        Layout.fillWidth: true
                        placeholderText: "Ask Gemini anything... (↑/↓ for history)"
                        placeholderTextColor: Qt.rgba(255, 255, 255, 0.35)
                        color: "white"
                        background: null
                        font.family: Theme.font.family
                        font.pixelSize: 12.5 * Appearance.effectiveScale
                        enabled: !AiChatService.isStreaming
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        implicitHeight: Math.min(120 * Appearance.effectiveScale, Math.max(32 * Appearance.effectiveScale, contentHeight + 8 * Appearance.effectiveScale))

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (event.modifiers & Qt.ShiftModifier) {
                                    event.accepted = false;
                                } else {
                                    event.accepted = true;
                                    root.sendPrompt(messageField.text);
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (messageField.cursorPosition === 0 || messageField.text === "") {
                                    root.stepHistory(-1);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Down) {
                                if (messageField.cursorPosition === messageField.text.length || root.historyIndex !== -1) {
                                    root.stepHistory(1);
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    // Clear Input Button (when text exists)
                    Rectangle {
                        width: 22 * Appearance.effectiveScale
                        height: 22 * Appearance.effectiveScale
                        radius: 11 * Appearance.effectiveScale
                        color: clearInputMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                        visible: messageField.text.length > 0 && !AiChatService.isStreaming

                        DankIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 13 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.7)
                        }

                        MouseArea {
                            id: clearInputMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                messageField.text = "";
                                messageField.forceActiveFocus();
                            }
                        }
                    }

                    // Action Button: Send (Arrow Up) / Stop Generation (Square)
                    Rectangle {
                        width: 32 * Appearance.effectiveScale
                        height: 32 * Appearance.effectiveScale
                        radius: 16 * Appearance.effectiveScale
                        color: {
                            if (AiChatService.isStreaming) return Theme.error;
                            if (messageField.text.trim().length > 0) return Theme.primary;
                            return Qt.rgba(255, 255, 255, 0.08);
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: AiChatService.isStreaming ? "stop" : "arrow_upward"
                            size: 16 * Appearance.effectiveScale
                            color: {
                                if (AiChatService.isStreaming) return "white";
                                if (messageField.text.trim().length > 0) return Theme.onPrimary;
                                return Qt.rgba(255, 255, 255, 0.35);
                            }
                            filled: AiChatService.isStreaming
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: (AiChatService.isStreaming || messageField.text.trim().length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (AiChatService.isStreaming) {
                                    AiChatService.stopGeneration();
                                } else {
                                    root.sendPrompt(messageField.text);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
