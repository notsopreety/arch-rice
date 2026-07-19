import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"
import ".."
import "MarkdownRenderer.js" as MarkdownRenderer

Item {
    id: root
    property string role: "user"
    property string content: ""
    property bool isStreaming: false
    property int messageIndex: 0
    property bool isEditing: false

    implicitHeight: bubbleCol.implicitHeight + 16 * Appearance.effectiveScale
    width: parent ? parent.width : 300 * Appearance.effectiveScale

    ColumnLayout {
        id: bubbleCol
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Header bar matching the user's design image
        Rectangle {
            Layout.fillWidth: true
            height: 38 * Appearance.effectiveScale
            radius: 8 * Appearance.effectiveScale
            color: Qt.rgba(255, 255, 255, 0.04)
            border.color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12 * Appearance.effectiveScale
                anchors.rightMargin: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // Left side: User or model name & icon
                MaterialSymbol {
                    text: root.role === "user" ? "person" : "smart_toy"
                    iconSize: 14 * Appearance.effectiveScale
                    color: root.role === "user" ? Theme.primary : "#c084fc"
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.role === "user" ? (Quickshell.env("USER") || "sawmer") : "Gemini 2.5 Flash"
                    font.family: Theme.font.family
                    font.pixelSize: 12 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: "white"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Right side action buttons
                // User Actions (Copy, Edit, Delete)
                RowLayout {
                    visible: root.role === "user"
                    spacing: 12

                    // Copy icon
                    Text {
                        text: "󰆏"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: copyUserMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: copyUserMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wl-copy", root.content]);
                                Quickshell.execDetached(["notify-send", "-r", "1020", "-a", "AI Chat", "Clipboard", "Prompt copied!"]);
                            }
                        }
                    }

                    // Edit icon
                    Text {
                        text: "󰏫"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: editUserMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: editUserMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isEditing = true;
                                editArea.text = root.content;
                                Qt.callLater(() => editArea.forceActiveFocus());
                            }
                        }
                    }

                    // Delete icon
                    Text {
                        text: "󰅖"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: deleteUserMouse.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: deleteUserMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AiChatService.deleteMessage(root.messageIndex);
                            }
                        }
                    }
                }

                // AI Actions (Regenerate, Copy, Delete)
                RowLayout {
                    visible: root.role === "assistant" && !root.isStreaming
                    spacing: 12

                    // Regenerate icon
                    Text {
                        text: "󰑐"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: regenAiMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: regenAiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AiChatService.regenerateMessage(root.messageIndex);
                            }
                        }
                    }

                    // Copy icon
                    Text {
                        text: "󰆏"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: copyAiMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: copyAiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["wl-copy", root.content]);
                                Quickshell.execDetached(["notify-send", "-r", "1020", "-a", "AI Chat", "Clipboard", "Response copied!"]);
                            }
                        }
                    }

                    // Delete icon
                    Text {
                        text: "󰅖"
                        font.family: Theme.font.monospace
                        font.pixelSize: 14
                        color: deleteAiMouse.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.5)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MouseArea {
                            id: deleteAiMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AiChatService.deleteMessage(root.messageIndex);
                            }
                        }
                    }
                }
            }
        }

        // Content Area (User = dark rounded card, AI = transparent)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: contentLayout.implicitHeight + 24 * Appearance.effectiveScale
            radius: Theme.rounding.normal
            color: root.role === "user"
                   ? Qt.rgba(255, 255, 255, 0.03)
                   : (root.role === "error"
                      ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                      : "transparent")
            border.color: root.role === "user"
                          ? Qt.rgba(255, 255, 255, 0.04)
                          : (root.role === "error"
                             ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2)
                             : "transparent")
            border.width: root.role === "user" || root.role === "error" ? 1 : 0

            ColumnLayout {
                id: contentLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // View Mode (rendered as blocks to support native code block styling)
                Repeater {
                    model: !root.isEditing ? MarkdownRenderer.parseBlocks(root.content) : []
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        // Text block
                        Text {
                            visible: modelData.type === "text"
                            Layout.fillWidth: true
                            text: visible ? modelData.content : ""
                            font.family: Theme.font.family
                            font.pixelSize: 13 * Appearance.effectiveScale
                            color: "white"
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            textFormat: Text.RichText
                            lineHeight: 1.25
                            onLinkActivated: (link) => Qt.openUrlExternally(link)

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                hoverEnabled: true
                                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }

                        // Code block
                        Rectangle {
                            visible: modelData.type === "code"
                            Layout.fillWidth: true
                            implicitHeight: visible ? (codeCol.implicitHeight + 20 * Appearance.effectiveScale) : 0
                            color: "#16131c"
                            border.color: Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            radius: 8 * Appearance.effectiveScale

                            ColumnLayout {
                                id: codeCol
                                anchors.fill: parent
                                anchors.margins: 10 * Appearance.effectiveScale
                                spacing: 6 * Appearance.effectiveScale

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: visible ? (modelData.lang || "code").toUpperCase() : ""
                                        font.family: Theme.font.family
                                        font.pixelSize: 10 * Appearance.effectiveScale
                                        font.weight: Font.Bold
                                        color: Qt.rgba(255, 255, 255, 0.4)
                                    }

                                    Item { Layout.fillWidth: true }

                                    DankIcon {
                                        name: "content_copy"
                                        size: 14 * Appearance.effectiveScale
                                        color: copyMouse.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.4)
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        MouseArea {
                                            id: copyMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["wl-copy", modelData.code]);
                                                Quickshell.execDetached(["notify-send", "-r", "1020", "-a", "AI Chat", "Clipboard", "Code copied to clipboard!"]);
                                            }
                                        }
                                    }
                                }

                                QQC.ScrollView {
                                    id: codeScroll
                                    Layout.fillWidth: true
                                    implicitHeight: codeTextContainer.implicitHeight + 12 * Appearance.effectiveScale
                                    contentWidth: codeTextContainer.implicitWidth
                                    contentHeight: codeTextContainer.implicitHeight
                                    clip: true
                                    QQC.ScrollBar.horizontal.policy: QQC.ScrollBar.AsNeeded
                                    QQC.ScrollBar.vertical.policy: QQC.ScrollBar.AlwaysOff

                                    // Intercept vertical wheel events and forward them to the chat ListView
                                    WheelHandler {
                                        target: codeScroll.contentItem
                                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                        orientation: Qt.Vertical
                                        onWheel: (event) => {
                                            var view = root.ListView.view;
                                            if (view) {
                                                var newY = view.contentY - event.angleDelta.y * 0.35;
                                                var minY = -view.topMargin;
                                                var maxY = view.contentHeight - view.height + view.bottomMargin;
                                                if (maxY > minY) {
                                                    view.contentY = Math.max(minY, Math.min(newY, maxY));
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        id: codeTextContainer
                                        text: visible ? ("<pre style='margin: 0; padding: 0; border: none; background: transparent; font-family: monospace; font-size: " + Math.round(11 * Appearance.effectiveScale) + "px; color: #cbd5e1;'>" + MarkdownRenderer.highlightCode(modelData.code, modelData.lang) + "</pre>") : ""
                                        textFormat: Text.RichText
                                        font.family: Theme.font.monospace
                                        font.pixelSize: 11 * Appearance.effectiveScale
                                        color: "#cbd5e1"
                                        wrapMode: Text.NoWrap
                                        lineHeight: 1.2
                                    }
                                }
                            }
                        }
                    }
                }

                // Edit Mode
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.isEditing
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(80, editArea.implicitHeight + 16)
                        color: Qt.rgba(0, 0, 0, 0.2)
                        border.color: Theme.primary
                        border.width: 1
                        radius: 8

                        QQC.ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            QQC.TextArea {
                                id: editArea
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                color: "white"
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                placeholderText: "Edit your message..."
                                placeholderTextColor: Qt.rgba(255, 255, 255, 0.3)
                                background: null
                                padding: 0
                                selectByMouse: true

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                        saveEdit();
                                        event.accepted = true;
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.isEditing = false;
                                        event.accepted = true;
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 8

                        // Cancel Button
                        Rectangle {
                            width: 70
                            height: 28
                            radius: 6
                            color: Qt.rgba(255, 255, 255, 0.06)
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "✕"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 10
                                    color: "white"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: "Cancel"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    color: "white"
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isEditing = false;
                                }
                            }
                        }

                        // Save Button
                        Rectangle {
                            width: 60
                            height: 28
                            radius: 6
                            color: Theme.primary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "󰄬"
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 12
                                    color: Theme.background
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: "Save"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.background
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    saveEdit();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function saveEdit() {
        let txt = editArea.text.trim();
        if (txt !== "") {
            AiChatService.editUserMessage(root.messageIndex, txt);
            root.isEditing = false;
        }
    }
}
