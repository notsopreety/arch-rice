import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: window

    readonly property color cBg: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
    readonly property color cCard: Theme.surfaceContainerHigh
    readonly property color cCardBorder: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
    readonly property color cBlue: Theme.primary
    readonly property color cTextPrimary: "#ffffff"
    readonly property color cTextSecondary: "#e2e8f0"
    readonly property color cTextMuted: Qt.rgba(255, 255, 255, 0.4)
    readonly property color cAccent: Theme.primary
    readonly property color cError: Theme.error
    readonly property color cBadgeBorder: Theme.outlineVariant

    readonly property var adapter: Bluetooth.defaultAdapter
    property var allDevices: []
    readonly property var connectedDevices: allDevices.filter(d => d.connected)
    readonly property var pairedDevices: allDevices.filter(d => d.paired && !d.connected)
    readonly property var availableDevices: allDevices.filter(d => {
        if (d.paired) return false
        const name = d.alias || d.name
        if (!name || name.trim() === "") return false
        const macRegex = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/
        if (macRegex.test(name)) return false
        return true
    })

    // Dialog state
    property string activeDialog: ""  // "", "forget", "rename"
    property var selectedDevice: null

    function deviceIcon(icon) {
        if (!icon) return "󰂯"
        if (icon.includes("audio") || icon.includes("headphone") || icon.includes("headset")) return "󰋋"
        if (icon.includes("phone")) return "󰄜"
        if (icon.includes("computer") || icon.includes("laptop")) return "󰌢"
        if (icon.includes("mouse")) return "󰍽"
        if (icon.includes("keyboard")) return "󰌌"
        if (icon.includes("speaker")) return "󰝚"
        if (icon.includes("car")) return "󰀘"
        return "󰂯"
    }

    function deviceDisplayName(device) {
        if (!device) return "Unknown device"
        const name = device.alias || device.name || device.deviceName
        if (name && name.length > 0) return name
        return device.address || "Unknown device"
    }

    function deviceStateText(device) {
        if (!device) return ""
        if (device.pairing) return "Pairing"
        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting"
        case BluetoothDeviceState.Connected:
            return "Connected"
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting"
        default:
            break
        }
        if (device.paired || device.bonded) return "Saved"
        return "Not paired"
    }

    function deviceSubtitle(device) {
        const parts = []
        const stateLabel = deviceStateText(device)
        if (stateLabel.length > 0) parts.push(stateLabel)
        if (device && device.batteryAvailable) parts.push(Math.round(device.battery) + "%")
        return parts.join(" • ")
    }

    Process {
        id: btCmdProc
    }

    function runBtCmd(cmd, address) {
        btCmdProc.exec(["bluetoothctl", cmd, address])
    }

    function handleTap(device) {
        if (!device) return
        if (device.connected) {
            runBtCmd("disconnect", device.address)
        } else if (device.paired) {
            runBtCmd("connect", device.address)
        } else {
            runBtCmd("pair", device.address)
            runBtCmd("trust", device.address)
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell-bluetooth-osd"
    
    WlrLayershell.keyboardFocus: BluetoothCenterService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: BluetoothCenterService.visible

    onVisibleChanged: {
        if (visible) {
            slideInAnim.restart();
            dashContent.forceActiveFocus();
            if (adapter && adapter.enabled) {
                adapter.discovering = true;
            }
        }
    }

    FocusScope {
        id: dashContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (window.activeDialog !== "") window.activeDialog = ""
                else BluetoothCenterService.close();
                event.accepted = true;
            }
        }

        // Transparent backdrop clicking closes the window
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: BluetoothCenterService.close()
            }
        }

        // Floating Card Container positioned under the Bluetooth connectivity pill
        Item {
            id: container
            width: 340
            height: Math.min(560, mainColumn.implicitHeight + 32)
            anchors.right: parent.right
            anchors.rightMargin: 140

            // Slide down animation when opening
            NumberAnimation on y {
                id: slideInAnim
                from: 20
                to: 50
                duration: 250
                easing.type: Easing.OutCubic
            }

            // Matching Drop Shadow
            DropShadow {
                anchors.fill: card
                source: card
                verticalOffset: 16
                radius: 48
                samples: 65
                color: Qt.rgba(0, 0, 0, 0.4)
                transparentBorder: true
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 24
                color: window.cBg
                border.color: window.cCardBorder
                border.width: 1
                clip: true

                ColumnLayout {
                    id: mainColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 0

                    // ═══ HEADER: Bluetooth + Toggle ═══
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8

                        Text {
                            text: "Bluetooth"
                            font.family: "Inter"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            color: window.cTextPrimary
                            Layout.fillWidth: true
                        }

                        // M3 Switch Pill
                        Item {
                            width: 52
                            height: 32

                            Rectangle {
                                id: toggleTrack
                                anchors.fill: parent
                                radius: 16
                                color: adapter?.enabled ? window.cAccent : Qt.rgba(window.cTextMuted.r, window.cTextMuted.g, window.cTextMuted.b, 0.15)
                                border.width: adapter?.enabled ? 0 : 2
                                border.color: adapter?.enabled ? "transparent" : Qt.rgba(window.cTextMuted.r, window.cTextMuted.g, window.cTextMuted.b, 0.4)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Rectangle {
                                id: toggleThumb
                                width: 24
                                height: 24
                                radius: 12
                                anchors.verticalCenter: parent.verticalCenter
                                x: adapter?.enabled ? toggleTrack.width - width - 4 : 4
                                color: adapter?.enabled ? "#ffffff" : Qt.rgba(window.cTextMuted.r, window.cTextMuted.g, window.cTextMuted.b, 0.6)
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Qt.rgba(0, 0, 0, 0.25)
                                    shadowBlur: 0.4
                                    shadowVerticalOffset: 1
                                }

                                // Checkmark icon when ON
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: "Material Design Icons"
                                    font.pixelSize: 14
                                    color: window.cAccent
                                    opacity: adapter?.enabled ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (adapter) adapter.enabled = !adapter.enabled
                            }
                        }
                    }

                    // ═══ Adapter status text ═══
                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 12
                        text: {
                            if (!adapter) return "No adapter"
                            switch (adapter.state) {
                            case BluetoothAdapterState.Enabling: return "Enabling Bluetooth..."
                            case BluetoothAdapterState.Disabling: return "Disabling Bluetooth..."
                            case BluetoothAdapterState.Disabled: return "Bluetooth disabled"
                            case BluetoothAdapterState.Enabled: return connectedDevices.length > 0
                                ? "Connected to " + connectedDevices.length + " device" + (connectedDevices.length > 1 ? "s" : "")
                                : (adapter.discovering ? "Scanning..." : "Bluetooth on")
                            default: return ""
                            }
                        }
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: window.cTextMuted
                        visible: adapter && !adapter.enabled
                    }

                    // ═══ DEVICE NAME CARD ═══
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14
                        color: nameCardArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.06) : window.cCard

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            spacing: 8

                            Text {
                                text: "Device name"
                                font.family: "Inter"
                                font.pixelSize: 14
                                color: window.cTextPrimary
                                Layout.fillWidth: true
                            }

                            Text {
                                text: adapter?.name || ""
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: window.cTextMuted
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "󰅂"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: window.cTextMuted
                            }
                        }

                        MouseArea {
                            id: nameCardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                renameInput.text = adapter?.name || ""
                                activeDialog = "rename"
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 10 }

                    // ═══ CONNECTED DEVICES ═══
                    Repeater {
                        model: connectedDevices

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 68
                            Layout.bottomMargin: connectedDevices.indexOf(modelData) < connectedDevices.length - 1 ? 0 : 6
                            radius: 16
                            color: connCardArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.12) : Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.25)

                            required property var modelData

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                // Icon
                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 20
                                    color: Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: window.deviceIcon(modelData.icon)
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 20
                                        color: window.cAccent
                                    }
                                }

                                // Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: window.deviceDisplayName(modelData)
                                        font.family: "Inter"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: window.cTextPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: window.deviceSubtitle(modelData)
                                        font.family: "Inter"
                                        font.pixelSize: 11
                                        color: window.cAccent
                                    }
                                }

                                // Disconnect button
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: connDisconnectArea.containsMouse ? Qt.rgba(window.cError.r, window.cError.g, window.cError.b, 0.15) : "transparent"
                                    border.width: 1
                                    border.color: window.cError

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰌊"
                                        font.family: "Material Design Icons"
                                        font.pixelSize: 14
                                        color: window.cError
                                    }

                                    MouseArea {
                                        id: connDisconnectArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: runBtCmd("disconnect", modelData.address)
                                    }
                                }
                            }

                            MouseArea {
                                id: connCardArea
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        selectedDevice = modelData
                                        activeDialog = "forget"
                                    }
                                }
                            }
                        }
                    }

                    // ═══ PAIRED DEVICES ═══
                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        Layout.topMargin: connectedDevices.length > 0 ? 6 : 0
                        text: "Paired devices"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: window.cTextSecondary
                        visible: pairedDevices.length > 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: pairedColumn.implicitHeight + 8
                        Layout.bottomMargin: 10
                        radius: 16
                        color: window.cCard
                        visible: pairedDevices.length > 0

                        ColumnLayout {
                            id: pairedColumn
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 0

                            Repeater {
                                model: pairedDevices

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 56
                                    color: pairedArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.05) : "transparent"
                                    radius: 12
                                    scale: pairedArea.containsMouse ? 1.015 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                    required property var modelData

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        Text {
                                            text: window.deviceIcon(modelData.icon)
                                            font.family: "Material Design Icons"
                                            font.pixelSize: 18
                                            color: window.cTextSecondary
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: window.deviceDisplayName(modelData)
                                                font.family: "Inter"
                                                font.pixelSize: 14
                                                color: window.cTextPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: window.deviceSubtitle(modelData)
                                                font.family: "Inter"
                                                font.pixelSize: 11
                                                color: window.cTextMuted
                                            }
                                        }

                                        // Connect button
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 16
                                            color: pairedConnectArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.15) : "transparent"
                                            border.width: 1
                                            border.color: pairedConnectArea.containsMouse ? window.cAccent : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰌘"
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 14
                                                color: window.cAccent
                                            }

                                            MouseArea {
                                                id: pairedConnectArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: runBtCmd("connect", modelData.address)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: pairedArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                selectedDevice = modelData
                                                activeDialog = "forget"
                                            } else {
                                                runBtCmd("connect", modelData.address)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══ AVAILABLE DEVICES ═══
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        Layout.topMargin: pairedDevices.length > 0 || connectedDevices.length > 0 ? 2 : 0
                        spacing: 8

                        Text {
                            text: "AVAILABLE DEVICES"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: window.cTextSecondary
                        }

                        // Premium device count pill
                        Rectangle {
                            visible: availableDevices.length > 0
                            width: deviceCountText.implicitWidth + 12
                            height: 18
                            radius: 9
                            color: Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.15)
                            border.width: 1
                            border.color: Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.3)

                            Text {
                                id: deviceCountText
                                anchors.centerIn: parent
                                text: availableDevices.length
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: window.cAccent
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        // Scanning spinner + stop
                        RowLayout {
                            spacing: 6
                            visible: adapter?.discovering ?? false

                            Text {
                                text: "󰑐"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: window.cAccent
                                RotationAnimation on rotation {
                                    running: adapter?.discovering ?? false
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: "Scanning..."
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: window.cAccent
                            }
                        }

                        // Refresh button (when not scanning)
                        Text {
                            text: "Refresh"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: window.cAccent
                            visible: !(adapter?.discovering ?? false)

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (adapter) adapter.discovering = true
                             }
                         }
                     }

                     // Sleek Indeterminate Progress Bar for Bluetooth discovery
                     Rectangle {
                         Layout.fillWidth: true
                         Layout.preferredHeight: 2
                         Layout.bottomMargin: 6
                         color: "transparent"
                         visible: adapter?.discovering ?? false
                         clip: true

                         Rectangle {
                             id: progressIndicator
                             width: progressIndicator.parent.width * 0.3
                             height: 2
                             color: window.cAccent
                             radius: 1
                             x: 0

                             SequentialAnimation on x {
                                 running: adapter?.discovering ?? false
                                 loops: Animation.Infinite
                                 NumberAnimation {
                                     from: -progressIndicator.width
                                     to: progressIndicator.parent.width
                                     duration: 1200
                                     easing.type: Easing.InOutQuad
                                 }
                             }
                         }
                     }

                    // Available devices list
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: availableDevices.length === 0 ? 140 : Math.min(availColumn.implicitHeight + 8, 260)
                        radius: 16
                        color: window.cCard
                        clip: true

                        Flickable {
                            id: availFlickable
                            anchors.fill: parent
                            anchors.margins: 4
                            contentHeight: availableDevices.length === 0 ? 132 : availColumn.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: availColumn
                                width: parent.width
                                spacing: 0

                                Repeater {
                                    model: availableDevices

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 56
                                        color: availArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.05) : "transparent"
                                        radius: 12
                                        scale: availArea.containsMouse ? 1.015 : 1.0

                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                        required property var modelData

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            Text {
                                                text: window.deviceIcon(modelData.icon)
                                                font.family: "Material Design Icons"
                                                font.pixelSize: 18
                                                color: window.cTextSecondary
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: window.deviceDisplayName(modelData)
                                                    font.family: "Inter"
                                                    font.pixelSize: 14
                                                    color: window.cTextPrimary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: window.deviceSubtitle(modelData)
                                                    font.family: "Inter"
                                                    font.pixelSize: 11
                                                    color: window.cTextMuted
                                                }
                                            }

                                            // Pair button
                                            Rectangle {
                                                width: 32
                                                height: 32
                                                radius: 16
                                                color: availPairArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.15) : "transparent"
                                                border.width: 1
                                                border.color: availPairArea.containsMouse ? window.cAccent : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.pairing ? "󰑐" : "󰌘"
                                                    font.family: "Material Design Icons"
                                                    font.pixelSize: 14
                                                    color: window.cAccent
                                                }

                                                MouseArea {
                                                    id: availPairArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: window.handleTap(modelData)
                                                 }
                                             }
                                         }

                                         MouseArea {
                                             id: availArea
                                             anchors.fill: parent
                                             hoverEnabled: true
                                             cursorShape: Qt.PointingHandCursor
                                             onClicked: window.handleTap(modelData)
                                         }
                                     }
                                 }
                             }
                            // Empty / Scanning state centered perfectly in the frame
                             ColumnLayout {
                                 anchors.centerIn: parent
                                 visible: availableDevices.length === 0
                                 spacing: 8

                                 // Rotating Material Shape when discovering
                                 MaterialShape {
                                     id: materialLoadingShape
                                     width: 40
                                     height: 40
                                     Layout.alignment: Qt.AlignHCenter
                                     visible: adapter?.discovering ?? false
                                     
                                     property var allowedShapes: [
                                         "sunny", "very_sunny", "cookie_4", "cookie_6", "cookie_7", 
                                         "cookie_9", "cookie_12", "clover_4", "clover_8", "soft_burst", 
                                         "puffy_diamond", "flower", "puffy"
                                     ]
                                     
                                     property string activeShape: "cookie_7"
                                     shape: activeShape
                                     color: Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.18)
                                     borderWidth: 0
                                     
                                     function changeToRandomShape() {
                                         var next = activeShape;
                                         while (next === activeShape) {
                                             next = allowedShapes[Math.floor(Math.random() * allowedShapes.length)];
                                         }
                                         activeShape = next;
                                     }

                                     SequentialAnimation on rotation {
                                         running: adapter?.discovering ?? false
                                         loops: Animation.Infinite
                                         
                                         NumberAnimation {
                                             from: 0
                                             to: 720
                                             duration: 2000
                                             easing.type: Easing.InOutQuad
                                         }
                                         
                                         ScriptAction {
                                             script: materialLoadingShape.changeToRandomShape()
                                         }
                                     }
                                 }

                                 // Default Bluetooth icon when not discovering
                                 Text {
                                     Layout.alignment: Qt.AlignHCenter
                                     visible: !(adapter?.discovering ?? false)
                                     text: "󰂲"
                                     font.family: "Material Design Icons"
                                     font.pixelSize: 28
                                     color: Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.18)
                                 }

                                 Text {
                                     Layout.alignment: Qt.AlignHCenter
                                     text: adapter?.discovering ?? false ? "Scanning for devices..." : (adapter?.enabled ? "No devices found" : "Bluetooth disabled")
                                     font.family: "Inter"
                                     font.pixelSize: 12
                                     color: window.cTextMuted
                                     horizontalAlignment: Text.AlignHCenter
                                 }

                                 // Plain and simple Stop Scanning button
                                  Text {
                                      id: stopScanBtn
                                      Layout.alignment: Qt.AlignHCenter
                                      Layout.topMargin: 12
                                      visible: adapter?.discovering ?? false
                                      text: "Stop Scanning"
                                      font.family: "Inter"
                                      font.pixelSize: 12
                                      font.weight: Font.Medium
                                      color: stopScanMouse.containsMouse ? window.cError : window.cTextMuted
                                      
                                      Behavior on color { ColorAnimation { duration: 150 } }

                                      MouseArea {
                                          id: stopScanMouse
                                          anchors.fill: parent
                                          anchors.margins: -8
                                          hoverEnabled: true
                                          cursorShape: Qt.PointingHandCursor
                                          onClicked: if (adapter) adapter.discovering = false
                                      }
                                  }
                              }
                          }
                      }

                     // ═══ SETTINGS ═══
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        Layout.topMargin: 8
                        radius: 10
                        color: settingsArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.05) : "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰒓"
                                font.family: "Material Design Icons"
                                font.pixelSize: 14
                                color: window.cTextMuted
                            }

                            Text {
                                text: "Bluetooth Settings"
                                font.family: "Inter"
                                font.pixelSize: 12
                                color: window.cTextMuted
                            }
                        }

                        MouseArea {
                            id: settingsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["blueman-manager"])
                                BluetoothCenterService.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════════════
    // DIALOGS OVERLAY
    // ═══════════════════════════════════════════

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        visible: activeDialog !== ""
        z: 50
        MouseArea { anchors.fill: parent; onClicked: window.activeDialog = "" }
    }

    // ═══ FORGET/UNPAIR DIALOG ═══
    Rectangle {
        id: forgetDialogCard
        anchors.centerIn: parent
        width: 280
        height: forgetCol.implicitHeight + 40
        radius: 20
        color: window.cCard
        border.color: window.cCardBorder
        border.width: 1
        visible: activeDialog === "forget"
        z: 100
        scale: activeDialog === "forget" ? 1.0 : 0.9
        opacity: activeDialog === "forget" ? 1.0 : 0

        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.8
            shadowVerticalOffset: 8
        }

        ColumnLayout {
            id: forgetCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                text: selectedDevice?.connected ? "Disconnect device?" : "Forget device?"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: window.cTextPrimary
            }

            Text {
                text: {
                    const name = window.deviceDisplayName(selectedDevice)
                    if (selectedDevice?.connected) return `Disconnect from "${name}"?`
                    return `Remove "${name}" from paired devices?`
                }
                font.family: "Inter"
                font.pixelSize: 13
                color: window.cTextSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 18
                    color: forgetCancelArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.08) : "transparent"
                    border.width: 1
                    border.color: window.cCardBorder

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: window.cTextPrimary
                    }

                    MouseArea {
                        id: forgetCancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.activeDialog = ""
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 18
                    color: forgetConfirmArea.containsMouse ? Qt.rgba(window.cError.r, window.cError.g, window.cError.b, 0.8) : window.cError

                    Text {
                        anchors.centerIn: parent
                        text: selectedDevice?.connected ? "Disconnect" : "Forget"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: forgetConfirmArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedDevice) {
                                if (selectedDevice.connected) {
                                    runBtCmd("disconnect", selectedDevice.address)
                                } else {
                                    runBtCmd("remove", selectedDevice.address)
                                }
                            }
                            window.activeDialog = ""
                        }
                    }
                }
            }
        }
    }

    // ═══ RENAME DIALOG ═══
    Rectangle {
        id: renameDialogCard
        anchors.centerIn: parent
        width: 280
        height: renameCol.implicitHeight + 40
        radius: 20
        color: window.cCard
        border.color: window.cCardBorder
        border.width: 1
        visible: activeDialog === "rename"
        z: 100
        scale: activeDialog === "rename" ? 1.0 : 0.9
        opacity: activeDialog === "rename" ? 1.0 : 0

        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        Behavior on opacity { NumberAnimation { duration: 150 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.8
            shadowVerticalOffset: 8
        }

        ColumnLayout {
            id: renameCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                text: "Rename adapter"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: window.cTextPrimary
            }

            Text {
                text: "Set a new name for this device"
                font.family: "Inter"
                font.pixelSize: 12
                color: window.cTextSecondary
            }

            Item {
                id: renameInputWrapper
                Layout.fillWidth: true
                height: 52

                // Outlined container Rectangle
                Rectangle {
                    id: renameInputBg
                    anchors.fill: parent
                    anchors.topMargin: 6
                    radius: 8
                    color: "transparent"
                    border.color: renameInput.activeFocus ? window.cAccent : window.cCardBorder
                    border.width: renameInput.activeFocus ? 2 : 1
                }

                // Floating Label overlapping top border
                Rectangle {
                    x: 12
                    y: 0
                    height: 14
                    width: renameLabelText.implicitWidth + 8
                    color: window.cCard
                    
                    Text {
                        id: renameLabelText
                        anchors.centerIn: parent
                        text: "Name"
                        font.pixelSize: 10
                        font.family: "Inter"
                        font.weight: Font.Medium
                        color: renameInput.activeFocus ? window.cAccent : window.cTextSecondary
                    }
                }

                QQC.TextField {
                    id: renameInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 6
                    placeholderText: "New adapter name"
                    placeholderTextColor: window.cTextMuted
                    color: window.cTextPrimary
                    background: Item {}
                    font.family: "Inter"
                    font.pixelSize: 14

                    onAccepted: {
                        if (text.length > 0 && adapter) {
                            renameProc.exec(["bluetoothctl", "system-alias", text])
                            window.activeDialog = ""
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 18
                    color: renameCancelArea.containsMouse ? Qt.rgba(window.cTextPrimary.r, window.cTextPrimary.g, window.cTextPrimary.b, 0.08) : "transparent"
                    border.width: 1
                    border.color: window.cCardBorder

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: window.cTextPrimary
                    }

                    MouseArea {
                        id: renameCancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.activeDialog = ""
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 18
                    color: renameInput.text.length > 0 ? window.cAccent : Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "Rename"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: renameInput.text.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (renameInput.text.length > 0 && adapter) {
                                renameProc.exec(["bluetoothctl", "system-alias", renameInput.text])
                                window.activeDialog = ""
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══ Process for rename ═══
    Process {
        id: renameProc
        onExited: window.activeDialog = ""
    }

    // ═══ Process for real-time bluetooth monitoring via helper script ═══
    Process {
        id: btHelperProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth_helper.py"]
        running: window.visible && (adapter?.enabled ?? false)
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let line = data.trim();
                if (line.startsWith("[")) {
                    try {
                        let list = JSON.parse(line);
                        window.allDevices = list;
                    } catch (e) {
                        console.error("[BluetoothWindow] Failed to parse JSON from helper:", e);
                    }
                }
            }
        }
    }
}
