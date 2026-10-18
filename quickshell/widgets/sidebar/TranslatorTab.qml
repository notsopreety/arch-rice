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

    readonly property bool isWide: width >= 560 * Appearance.effectiveScale

    property bool showLangPicker: false
    property bool isTargetPicker: false
    property bool copiedFeedback: false

    Component.onCompleted: {
        TranslatorService.ensureLanguages();
    }

    // Keyboard shortcuts
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (showLangPicker) {
                showLangPicker = false;
                event.accepted = true;
            }
        } else if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            TranslatorService.swap(TranslatorService.detected);
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash && !showLangPicker && !sourceArea.activeFocus) {
            sourceArea.forceActiveFocus();
            event.accepted = true;
        }
    }

    Timer {
        id: copyTimer
        interval: 1800
        onTriggered: root.copiedFeedback = false
    }

    function copyToClipboard(text) {
        if (!text) return;
        Quickshell.clipboardText = text;
        root.copiedFeedback = true;
        copyTimer.restart();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10 * Appearance.effectiveScale

        // ── Connected Language Bar ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 6 * Appearance.effectiveScale

            // Left Tile: "From ⌄"
            Rectangle {
                Layout.fillWidth: true
                height: 50 * Appearance.effectiveScale
                radius: 20 * Appearance.effectiveScale
                color: fromMouse.containsMouse 
                    ? Qt.rgba(255, 255, 255, 0.10)
                    : Qt.rgba(255, 255, 255, 0.06)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * Appearance.effectiveScale
                    spacing: 1 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Text {
                            text: TranslatorService.sourceLanguage === "auto" && TranslatorService.detected ? "Detected" : "From"
                            font.family: Theme.font.family
                            font.pixelSize: 10 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.55)
                        }
                        DankIcon {
                            name: "expand_more"
                            size: 13 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.55)
                        }
                    }

                    Text {
                        text: {
                            if (TranslatorService.sourceLanguage === "auto" && TranslatorService.detected) {
                                return TranslatorService.displayName(TranslatorService.detected);
                            }
                            return TranslatorService.displayName(TranslatorService.sourceLanguage);
                        }
                        font.family: Theme.font.family
                        font.pixelSize: 13 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        color: "white"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: fromMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isTargetPicker = false;
                        root.showLangPicker = true;
                    }
                }
            }

            // Middle: Amber Scalloped Material Shape Swap Button
            Item {
                width: 48 * Appearance.effectiveScale
                height: 48 * Appearance.effectiveScale

                MaterialShape {
                    id: swapShape
                    anchors.centerIn: parent
                    width: 46 * Appearance.effectiveScale
                    height: 46 * Appearance.effectiveScale
                    shape: swapMouse.containsMouse ? "cookie_12" : "cookie_9"
                    color: swapMouse.pressed 
                        ? Theme.tertiary
                        : (swapMouse.containsMouse ? Theme.tertiary : (Theme.tertiaryContainer || "#c98616"))
                    rotation: TranslatorService.swapTurns * 180

                    Behavior on rotation {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "swap_horiz"
                    size: 20 * Appearance.effectiveScale
                    color: Theme.onTertiaryContainer || "#1c1204"
                }

                MouseArea {
                    id: swapMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: TranslatorService.swap(TranslatorService.detected)
                }

                StyledToolTip {
                    text: "Swap languages (Ctrl+Enter)"
                    alternativeVisibleCondition: swapMouse.containsMouse
                }
            }

            // Right Tile: "To ⌄"
            Rectangle {
                Layout.fillWidth: true
                height: 50 * Appearance.effectiveScale
                radius: 20 * Appearance.effectiveScale
                color: toMouse.containsMouse 
                    ? Qt.rgba(255, 255, 255, 0.10)
                    : Qt.rgba(255, 255, 255, 0.06)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10 * Appearance.effectiveScale
                    spacing: 1 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Text {
                            text: "To"
                            font.family: Theme.font.family
                            font.pixelSize: 10 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.55)
                        }
                        DankIcon {
                            name: "expand_more"
                            size: 13 * Appearance.effectiveScale
                            color: Qt.rgba(255, 255, 255, 0.55)
                        }
                    }

                    Text {
                        text: TranslatorService.displayName(TranslatorService.targetLanguage)
                        font.family: Theme.font.family
                        font.pixelSize: 13 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        color: "white"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: toMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isTargetPicker = true;
                        root.showLangPicker = true;
                    }
                }
            }
        }

        // ── Main Panes Layout ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.fill: parent
                columns: root.isWide ? 2 : 1
                rows: root.isWide ? 1 : 2
                rowSpacing: 10 * Appearance.effectiveScale
                columnSpacing: 10 * Appearance.effectiveScale

                // ── Source Card ("Original") ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 22 * Appearance.effectiveScale
                    color: Qt.rgba(255, 255, 255, 0.06)
                    border.color: sourceArea.activeFocus 
                        ? Theme.primary 
                        : Qt.rgba(255, 255, 255, 0.08)
                    border.width: sourceArea.activeFocus ? 1.5 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        // Header: Material Shape badge + "Original" + language
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10 * Appearance.effectiveScale

                            // Morphing shape badge: clover_4 -> sunny on focus!
                            Item {
                                width: 36 * Appearance.effectiveScale
                                height: 36 * Appearance.effectiveScale

                                MaterialShape {
                                    anchors.centerIn: parent
                                    width: 36 * Appearance.effectiveScale
                                    height: 36 * Appearance.effectiveScale
                                    shape: sourceArea.activeFocus ? "sunny" : "clover_4"
                                    color: Qt.rgba(Theme.secondaryContainer.r, Theme.secondaryContainer.g, Theme.secondaryContainer.b, 0.7)
                                }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "edit_note"
                                    size: 19 * Appearance.effectiveScale
                                    color: Theme.onSecondaryContainer || "white"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: "Original"
                                    font.family: Theme.font.family
                                    font.pixelSize: 13 * Appearance.effectiveScale
                                    font.weight: Font.DemiBold
                                    color: "white"
                                }

                                Text {
                                    text: {
                                        if (TranslatorService.sourceLanguage === "auto" && TranslatorService.detected) {
                                            return TranslatorService.displayName(TranslatorService.detected);
                                        }
                                        return TranslatorService.displayName(TranslatorService.sourceLanguage);
                                    }
                                    font.family: Theme.font.family
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.55)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // TTS listen button (if text present)
                            Rectangle {
                                width: 30 * Appearance.effectiveScale
                                height: 30 * Appearance.effectiveScale
                                radius: 15 * Appearance.effectiveScale
                                visible: sourceArea.text.trim().length > 0
                                color: TranslatorService.speakingKey === "source"
                                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                                    : (listenSrcMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent")

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "volume_up"
                                    size: 16 * Appearance.effectiveScale
                                    color: TranslatorService.speakingKey === "source" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                                }

                                MouseArea {
                                    id: listenSrcMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TranslatorService.speak("source", sourceArea.text, TranslatorService.effectiveSource)
                                }

                                StyledToolTip {
                                    text: TranslatorService.speakingKey === "source" ? "Stop" : "Listen"
                                    alternativeVisibleCondition: listenSrcMouse.containsMouse
                                }
                            }
                        }

                        // Text Input Area
                        QQC.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            QQC.TextArea {
                                id: sourceArea
                                text: TranslatorService.inputText
                                placeholderText: "Translate text"
                                placeholderTextColor: Qt.rgba(255, 255, 255, 0.35)
                                font.family: Theme.font.family
                                font.pixelSize: {
                                    let l = text.length;
                                    if (l <= 48) return 17 * Appearance.effectiveScale;
                                    if (l <= 140) return 15 * Appearance.effectiveScale;
                                    return 13 * Appearance.effectiveScale;
                                }
                                color: "white"
                                wrapMode: QQC.TextArea.Wrap
                                selectByMouse: true
                                background: null
                                padding: 0

                                onTextChanged: {
                                    if (TranslatorService.inputText !== text) {
                                        TranslatorService.inputText = text;
                                    }
                                }
                            }
                        }

                        // Transliteration / Phonetic
                        Text {
                            visible: TranslatorService.sourceTransliteration.length > 0
                            text: TranslatorService.sourceTransliteration
                            font.family: Theme.font.family
                            font.pixelSize: 11 * Appearance.effectiveScale
                            font.italic: true
                            color: Qt.rgba(255, 255, 255, 0.5)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Bottom Row: "Ctrl+Enter swaps languages" + Delete button
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8 * Appearance.effectiveScale

                            Text {
                                text: "Ctrl+Enter swaps languages"
                                font.family: Theme.font.family
                                font.pixelSize: 11 * Appearance.effectiveScale
                                color: Qt.rgba(255, 255, 255, 0.35)
                            }

                            Item { Layout.fillWidth: true }

                            // Delete / Clear button with trash can icon
                            Rectangle {
                                width: 30 * Appearance.effectiveScale
                                height: 30 * Appearance.effectiveScale
                                radius: 15 * Appearance.effectiveScale
                                visible: sourceArea.text.length > 0
                                color: deleteMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "delete"
                                    size: 16 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                }

                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        sourceArea.text = "";
                                        sourceArea.forceActiveFocus();
                                    }
                                }

                                StyledToolTip {
                                    text: "Clear text"
                                    alternativeVisibleCondition: deleteMouse.containsMouse
                                }
                            }
                        }
                    }
                }

                // ── Translation Result Hero Card ("Translation") ──
                Rectangle {
                    id: resultCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 22 * Appearance.effectiveScale
                    clip: true

                    color: {
                        if (TranslatorService.error.length > 0) return Theme.errorContainer;
                        if (TranslatorService.translation.length > 0) return Theme.primaryContainer || "#004d65";
                        return Qt.rgba(0, 0, 0, 0.25);
                    }

                    Behavior on color {
                        ColorAnimation { duration: 250 }
                    }

                    // ── Background Masked Scallop Ornament (Organic Material Curve) ──
                    MaterialShape {
                        id: ornamentShape
                        readonly property real ornamentSize: Math.round(Math.max(resultCard.width * 0.9, 240 * Appearance.effectiveScale))
                        width: ornamentSize
                        height: ornamentSize
                        x: resultCard.width - ornamentSize * 0.52
                        y: -ornamentSize * 0.42
                        shape: "cookie_12"
                        color: Qt.rgba(255, 255, 255, 0.08)
                        rotation: TranslatorService.swapTurns * 45

                        Behavior on rotation {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        // Header: White Cookie-7 Shape Badge + "Translation" + language
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10 * Appearance.effectiveScale

                            Item {
                                width: 36 * Appearance.effectiveScale
                                height: 36 * Appearance.effectiveScale

                                MaterialShape {
                                    anchors.centerIn: parent
                                    width: 36 * Appearance.effectiveScale
                                    height: 36 * Appearance.effectiveScale
                                    shape: "cookie_7"
                                    color: "white"
                                }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "translate"
                                    size: 19 * Appearance.effectiveScale
                                    color: resultCard.color
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: "Translation"
                                    font.family: Theme.font.family
                                    font.pixelSize: 13 * Appearance.effectiveScale
                                    font.weight: Font.DemiBold
                                    color: "white"
                                }

                                Text {
                                    text: TranslatorService.busy 
                                        ? "Translating…" 
                                        : (TranslatorService.error.length > 0 ? "Translation error" : TranslatorService.displayName(TranslatorService.targetLanguage))
                                    font.family: Theme.font.family
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.8)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Listen Audio button
                            Rectangle {
                                width: 30 * Appearance.effectiveScale
                                height: 30 * Appearance.effectiveScale
                                radius: 15 * Appearance.effectiveScale
                                visible: TranslatorService.translation.length > 0
                                color: TranslatorService.speakingKey === "target"
                                    ? Qt.rgba(255, 255, 255, 0.3)
                                    : (listenTgtMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "volume_up"
                                    size: 16 * Appearance.effectiveScale
                                    color: "white"
                                }

                                MouseArea {
                                    id: listenTgtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TranslatorService.speak("target", TranslatorService.translation, TranslatorService.targetLanguage)
                                }

                                StyledToolTip {
                                    text: TranslatorService.speakingKey === "target" ? "Stop" : "Listen"
                                    alternativeVisibleCondition: listenTgtMouse.containsMouse
                                }
                            }

                            // Copy button
                            Rectangle {
                                width: 30 * Appearance.effectiveScale
                                height: 30 * Appearance.effectiveScale
                                radius: 15 * Appearance.effectiveScale
                                visible: TranslatorService.translation.length > 0
                                color: copyTgtMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: root.copiedFeedback ? "check" : "content_copy"
                                    size: 16 * Appearance.effectiveScale
                                    color: "white"
                                }

                                MouseArea {
                                    id: copyTgtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.copyToClipboard(TranslatorService.translation)
                                }

                                StyledToolTip {
                                    text: root.copiedFeedback ? "Copied!" : "Copy translation"
                                    alternativeVisibleCondition: copyTgtMouse.containsMouse
                                }
                            }
                        }

                        // ── Empty State: Material Shape SoftBurst + forum icon ──
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: TranslatorService.translation.length === 0 && !TranslatorService.busy && TranslatorService.error.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, 270 * Appearance.effectiveScale)
                                spacing: 10 * Appearance.effectiveScale

                                // Scalloped 12-wave Material Shape Badge
                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 68 * Appearance.effectiveScale
                                    height: 68 * Appearance.effectiveScale

                                    MaterialShape {
                                        anchors.centerIn: parent
                                        width: 68 * Appearance.effectiveScale
                                        height: 68 * Appearance.effectiveScale
                                        shape: "soft_burst"
                                        color: Qt.rgba(255, 255, 255, 0.16)
                                    }

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: "forum"
                                        size: 32 * Appearance.effectiveScale
                                        color: "white"
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Nothing to translate yet"
                                    font.family: Theme.font.family
                                    font.pixelSize: 16 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: "white"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Type or paste text above — press / from anywhere in the tab to start"
                                    font.family: Theme.font.family
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.75)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        // ── Error State ──
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: TranslatorService.error.length > 0 && !TranslatorService.busy

                            ColumnLayout {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, 270 * Appearance.effectiveScale)
                                spacing: 8 * Appearance.effectiveScale

                                Item {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 56 * Appearance.effectiveScale
                                    height: 56 * Appearance.effectiveScale

                                    MaterialShape {
                                        anchors.centerIn: parent
                                        width: 56 * Appearance.effectiveScale
                                        height: 56 * Appearance.effectiveScale
                                        shape: "cookie_9"
                                        color: Qt.rgba(255, 255, 255, 0.16)
                                    }

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: "cloud_off"
                                        size: 26 * Appearance.effectiveScale
                                        color: "white"
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Couldn't translate"
                                    font.family: Theme.font.family
                                    font.pixelSize: 15 * Appearance.effectiveScale
                                    font.weight: Font.Bold
                                    color: "white"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: TranslatorService.error
                                    font.family: Theme.font.family
                                    font.pixelSize: 11 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.8)
                                    wrapMode: Text.Wrap
                                }

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 80 * Appearance.effectiveScale
                                    height: 30 * Appearance.effectiveScale
                                    radius: 15 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.2)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Retry"
                                        font.family: Theme.font.family
                                        font.pixelSize: 12 * Appearance.effectiveScale
                                        font.weight: Font.DemiBold
                                        color: "white"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TranslatorService.retry()
                                    }
                                }
                            }
                        }

                        // ── Active Translation View ──
                        QQC.ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: TranslatorService.translation.length > 0
                            clip: true

                            ColumnLayout {
                                width: parent.width
                                spacing: 8 * Appearance.effectiveScale

                                TextEdit {
                                    text: TranslatorService.translation
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.Wrap
                                    font.family: Theme.font.family
                                    font.pixelSize: {
                                        let l = TranslatorService.translation.length;
                                        if (l <= 48) return 18 * Appearance.effectiveScale;
                                        if (l <= 140) return 15 * Appearance.effectiveScale;
                                        return 13 * Appearance.effectiveScale;
                                    }
                                    color: "white"
                                    Layout.fillWidth: true
                                }

                                // Target transliteration
                                Text {
                                    visible: TranslatorService.transliteration.length > 0
                                    text: TranslatorService.transliteration
                                    font.family: Theme.font.family
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.italic: true
                                    color: Qt.rgba(255, 255, 255, 0.8)
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                // Dictionary details (for single words)
                                ColumnLayout {
                                    visible: TranslatorService.dictionary.length > 0
                                    Layout.fillWidth: true
                                    spacing: 6 * Appearance.effectiveScale

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(255, 255, 255, 0.15)
                                    }

                                    Repeater {
                                        model: TranslatorService.dictionary
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4 * Appearance.effectiveScale

                                            Rectangle {
                                                height: 18 * Appearance.effectiveScale
                                                radius: 4 * Appearance.effectiveScale
                                                color: Qt.rgba(255, 255, 255, 0.2)
                                                width: posLabel.width + 12 * Appearance.effectiveScale

                                                Text {
                                                    id: posLabel
                                                    anchors.centerIn: parent
                                                    text: modelData.pos || ""
                                                    font.family: Theme.font.family
                                                    font.pixelSize: 10 * Appearance.effectiveScale
                                                    font.weight: Font.Bold
                                                    color: "white"
                                                }
                                            }

                                            Flow {
                                                Layout.fillWidth: true
                                                spacing: 4 * Appearance.effectiveScale

                                                Repeater {
                                                    model: modelData.words || []
                                                    Rectangle {
                                                        height: 22 * Appearance.effectiveScale
                                                        radius: 11 * Appearance.effectiveScale
                                                        color: wordMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.12)
                                                        border.color: Qt.rgba(255, 255, 255, 0.15)
                                                        border.width: 1
                                                        width: wordText.width + 12 * Appearance.effectiveScale

                                                        Text {
                                                            id: wordText
                                                            anchors.centerIn: parent
                                                            text: modelData.word || ""
                                                            font.family: Theme.font.family
                                                            font.pixelSize: 11 * Appearance.effectiveScale
                                                            color: "white"
                                                        }

                                                        MouseArea {
                                                            id: wordMouse
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: root.copyToClipboard(modelData.word)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Language Selector Sheet (Overlay) ──
    Rectangle {
        id: langPickerOverlay
        anchors.fill: parent
        radius: 22 * Appearance.effectiveScale
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1
        visible: root.showLangPicker
        z: 100

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14 * Appearance.effectiveScale
            spacing: 10 * Appearance.effectiveScale

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                Item {
                    width: 32 * Appearance.effectiveScale
                    height: 32 * Appearance.effectiveScale

                    MaterialShape {
                        anchors.centerIn: parent
                        width: 32 * Appearance.effectiveScale
                        height: 32 * Appearance.effectiveScale
                        shape: "cookie_9"
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "translate"
                        size: 16 * Appearance.effectiveScale
                        color: Theme.primary
                    }
                }

                Text {
                    text: root.isTargetPicker ? "Select Target Language" : "Select Source Language"
                    font.family: Theme.font.family
                    font.pixelSize: 14 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: "white"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28 * Appearance.effectiveScale
                    height: 28 * Appearance.effectiveScale
                    radius: 14 * Appearance.effectiveScale
                    color: closePickerMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 16 * Appearance.effectiveScale
                        color: "white"
                    }

                    MouseArea {
                        id: closePickerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showLangPicker = false
                    }
                }
            }

            // Search Field
            Rectangle {
                Layout.fillWidth: true
                height: 38 * Appearance.effectiveScale
                radius: 19 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.35)
                border.color: searchField.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8 * Appearance.effectiveScale
                    spacing: 6 * Appearance.effectiveScale

                    DankIcon {
                        name: "search"
                        size: 15 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.4)
                    }

                    QQC.TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search languages..."
                        placeholderTextColor: Qt.rgba(255, 255, 255, 0.35)
                        font.family: Theme.font.family
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: "white"
                        background: null
                        padding: 0
                        selectByMouse: true
                    }

                    DankIcon {
                        visible: searchField.text.length > 0
                        name: "close"
                        size: 14 * Appearance.effectiveScale
                        color: Qt.rgba(255, 255, 255, 0.4)
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchField.text = ""
                        }
                    }
                }
            }

            // Language List
            QQC.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: langList
                    width: parent.width
                    spacing: 3 * Appearance.effectiveScale

                    model: {
                        let query = searchField.text.trim().toLowerCase();
                        let items = [];
                        if (!root.isTargetPicker) {
                            items.push({ code: "auto", name: "Detect language", endonym: "Detect language" });
                        }
                        let all = items.concat(TranslatorService.languages);
                        if (query.length === 0) return all;
                        return all.filter(item => {
                            let endo = (item.endonym || "").toLowerCase();
                            let name = (item.name || "").toLowerCase();
                            let code = (item.code || "").toLowerCase();
                            return endo.includes(query) || name.includes(query) || code.includes(query);
                        });
                    }

                    delegate: Rectangle {
                        width: langList.width
                        height: 40 * Appearance.effectiveScale
                        radius: 10 * Appearance.effectiveScale
                        property bool isSelected: {
                            let curr = root.isTargetPicker ? TranslatorService.targetLanguage : TranslatorService.sourceLanguage;
                            return curr.toLowerCase() === modelData.code.toLowerCase();
                        }
                        color: isSelected 
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                            : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: modelData.endonym || modelData.name || modelData.code
                                    font.family: Theme.font.family
                                    font.pixelSize: 12 * Appearance.effectiveScale
                                    font.weight: isSelected ? Font.Bold : Font.Normal
                                    color: isSelected ? Theme.primary : "white"
                                }
                                Text {
                                    visible: modelData.name && modelData.name !== modelData.endonym
                                    text: modelData.name || ""
                                    font.family: Theme.font.family
                                    font.pixelSize: 10 * Appearance.effectiveScale
                                    color: Qt.rgba(255, 255, 255, 0.45)
                                }
                            }

                            Text {
                                text: modelData.code.toUpperCase()
                                font.family: Theme.font.family
                                font.pixelSize: 10 * Appearance.effectiveScale
                                font.weight: Font.DemiBold
                                color: Qt.rgba(255, 255, 255, 0.35)
                            }

                            DankIcon {
                                visible: isSelected
                                name: "check"
                                size: 14 * Appearance.effectiveScale
                                color: Theme.primary
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.isTargetPicker) {
                                    TranslatorService.setTarget(modelData.code);
                                } else {
                                    TranslatorService.setSource(modelData.code);
                                }
                                root.showLangPicker = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
