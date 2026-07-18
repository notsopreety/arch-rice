import "../core"
import "../core/functions" as Functions
import "../services"
import "../widgets"
import "../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

/**
 * Polkit authentication panel.
 * Mirroring the 'ii' example's fullscreen overlay style.
 */
Scope {
    id: root

    Loader {
        active: PolkitService.active
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData

                readonly property bool isActive: GlobalStates.activeScreen === modelData
                visible: PolkitService.active && isActive

                // ── Glassmorphism toggle ───────────────────────────────────
                property bool glassmorphism: false
                FileView {
                    id: glassFlag
                    path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
                    Component.onCompleted: { try { glassFlag.reload(); panelWindow.glassmorphism = true; } catch(e) { panelWindow.glassmorphism = false; } }
                    onLoaded: panelWindow.glassmorphism = true
                    onLoadFailed: panelWindow.glassmorphism = false
                }
                // ─────────────────────────────────────────────────────────

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "quickshell:polkit"
                WlrLayershell.keyboardFocus: (PolkitService.active && isActive) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                WlrLayershell.layer: (PolkitService.active && isActive) ? WlrLayer.Overlay : WlrLayer.Background
                exclusionMode: ExclusionMode.Ignore

                // ── Scrim ──
                Rectangle {
                    anchors.fill: parent
                    color: Functions.ColorUtils.applyAlpha(Theme.background, 0.6)
                    opacity: (PolkitService.active && isActive) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: PolkitService.cancel()
                    }
                }

                // ── Auth Dialog ──
                Rectangle {
                    id: dialog
                    anchors.centerIn: parent
                    width: 450 * Appearance.effectiveScale
                    implicitHeight: contentCol.implicitHeight + (40 * Appearance.effectiveScale)
                    radius: Appearance.rounding.card
                    color: panelWindow.glassmorphism
                        ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.35)
                        : Theme.surfaceContainerHigh
                    border.width: panelWindow.glassmorphism ? 1 : 0
                    border.color: panelWindow.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : "transparent"

                    Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }

                    // Glossy top highlight (glass mode only)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        height: parent.height * 0.45
                        radius: parent.radius
                        visible: panelWindow.glassmorphism
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        }
                    }
                    
                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 24 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        // Icon
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "security"
                            iconSize: 32 * Appearance.effectiveScale
                            color: Theme.primary
                        }

                        // Title
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Authentication Required")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                            color: Theme.primary
                        }

                        // Message
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: PolkitService.cleanMessage
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: "white"
                            wrapMode: Text.Wrap
                        }

                        // Password Field Section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8 * Appearance.effectiveScale

                            Rectangle {
                                id: inputContainer
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52 * Appearance.effectiveScale
                                radius: 8 * Appearance.effectiveScale
                                color: "transparent"
                                border.width: passwordInput.activeFocus || PolkitService.failed ? Math.max(1, 2 * Appearance.effectiveScale) : Math.max(1, 1 * Appearance.effectiveScale)
                                border.color: PolkitService.failed ? Theme.error : (passwordInput.activeFocus ? Theme.primary : "white")

                                // Floating Label (Simulated)
                                Rectangle {
                                    x: 12 * Appearance.effectiveScale
                                    y: -8 * Appearance.effectiveScale
                                    width: labelText.width + (8 * Appearance.effectiveScale)
                                    height: 16 * Appearance.effectiveScale
                                    color: panelWindow.glassmorphism
                                        ? Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.35)
                                        : Theme.surfaceContainerHigh
                                    
                                    StyledText {
                                        id: labelText
                                        anchors.centerIn: parent
                                        text: qsTr("Password")
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        font.weight: Font.Medium
                                        color: PolkitService.failed ? Theme.error : (passwordInput.activeFocus ? Theme.primary : "white")
                                    }
                                }

                                TextInput {
                                    id: passwordInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16 * Appearance.effectiveScale
                                    anchors.rightMargin: 16 * Appearance.effectiveScale
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "white"
                                    echoMode: (PolkitService.flow && PolkitService.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                                    selectionColor: Theme.primary
                                    enabled: PolkitService.interactionAvailable
                                    
                                    focus: true
                                    onAccepted: PolkitService.submit(text)
                                    onTextChanged: if (PolkitService.failed) PolkitService.failed = false

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !passwordInput.text && !passwordInput.activeFocus
                                        text: PolkitService.cleanPrompt
                                        color: Functions.ColorUtils.applyAlpha("#ffffff", 0.6)
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                    }
                                }
                            }

                            // Error Message
                            StyledText {
                                Layout.fillWidth: true
                                visible: PolkitService.failed
                                text: qsTr("Authentication failed, please try again")
                                color: Theme.error
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                horizontalAlignment: Text.AlignLeft
                                leftPadding: 4 * Appearance.effectiveScale
                            }
                        }

                        // Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 12 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            Item { Layout.fillWidth: true }

                            RippleButton {
                                Layout.preferredWidth: 100 * Appearance.effectiveScale
                                Layout.preferredHeight: 40 * Appearance.effectiveScale
                                buttonRadius: Appearance.rounding.button
                                buttonText: qsTr("Cancel")
                                colBackground: "transparent"
                                colBackgroundHover: Functions.ColorUtils.applyAlpha(Theme.onSurface, 0.1)
                                colText: "#ffffff"
                                onClicked: PolkitService.cancel()
                            }

                            RippleButton {
                                Layout.preferredWidth: 100 * Appearance.effectiveScale
                                Layout.preferredHeight: 40 * Appearance.effectiveScale
                                buttonRadius: Appearance.rounding.button
                                buttonText: qsTr("OK")
                                colBackground: Theme.primary
                                colText: Theme.onPrimary
                                enabled: PolkitService.interactionAvailable
                                onClicked: PolkitService.submit(passwordInput.text)
                            }
                        }
                    }

                    // Key Handling
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            PolkitService.cancel();
                            event.accepted = true;
                        }
                    }

                    Connections {
                        target: PolkitService
                        function onInteractionAvailableChanged() {
                            if (PolkitService.interactionAvailable) {
                                passwordInput.text = "";
                                passwordInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }
}
