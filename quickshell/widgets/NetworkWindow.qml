import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
    readonly property var network: Network
    readonly property color cError: Theme.error
    readonly property color cBadgeBorder: Theme.outlineVariant

    // Network lists
    readonly property var allNetworks: [...network.networks].filter(n => n.ssid && n.ssid.length > 0)
    readonly property var connectedNet: network.active
    readonly property var savedNetworks: allNetworks.filter(n => !n.active && network.savedNetworks.includes(n.ssid))
    readonly property var availableNetworks: allNetworks.filter(n => !n.active && !network.savedNetworks.includes(n.ssid))
        .sort((a, b) => b.strength - a.strength)

    // Dialog state
    property string activeDialog: ""  // "", "password", "qrcode", "modify", "forget", "addNetwork"
    property string dialogSSID: ""
    property string dialogPassword: ""
    property bool wrongPassword: false
    property string pendingConnectSSID: ""
    property string addNetError: ""

    // ═══ Processes ═══
    Process {
        id: qrProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/qr_wifi.py"]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("Network name: ")) {
                    window.dialogSSID = data.substring(14)
                } else if (data.startsWith("Password: ")) {
                    window.dialogPassword = data.substring(10)
                }
            }
        }
        onExited: {
            qrImageTimer.running = true
        }
    }

    Timer {
        id: qrImageTimer
        interval: 200
        onTriggered: {
            qrImage.source = ""
            qrImage.source = "file:///tmp/qr_wifi.png"
        }
    }

    Process {
        id: getPasswordProc
        stdout: SplitParser {
            onRead: data => {
                if (data.length > 0) {
                    window.dialogPassword = data
                }
            }
        }
    }

    Process {
        id: forgetProc
        onExited: {
            network.refreshSavedNetworks()
            window.activeDialog = ""
        }
    }

    Process {
        id: modifyProc
        onExited: {
            window.activeDialog = ""
            if (window.dialogPassword.length > 0) {
                connectProc.exec(["nmcli", "dev", "wifi", "connect", window.dialogSSID, "password", window.dialogPassword])
            }
        }
    }

    Process {
        id: connectProc
        onExited: (code, status) => {
            if (code !== 0 && window.activeDialog === "") {
                window.wrongPassword = true
                window.dialogSSID = pendingConnectSSID
                window.activeDialog = "password"
            }
            pendingConnectSSID = ""
        }
    }

    Process {
        id: addNetProc
        stdout: SplitParser {
            onRead: data => addNetError = data
        }
        onExited: (code, status) => {
            if (code === 0) {
                window.activeDialog = ""
                addNetError = ""
                addSsidInput.text = ""
                addPasswordInput.text = ""
            }
        }
    }

    // ═══ Helper functions ═══
    function signalIcon(strength) {
        if (strength >= 75) return "network_wifi"
        if (strength >= 50) return "network_wifi_3_bar"
        if (strength >= 25) return "network_wifi_2_bar"
        return "network_wifi_1_bar"
    }

    function connectToNetwork(ssid, isSaved) {
        if (isSaved) {
            pendingConnectSSID = ssid
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid])
        } else {
            window.wrongPassword = false
            window.dialogSSID = ssid
            window.dialogPassword = ""
            window.activeDialog = "password"
        }
    }

    function openQRShare() {
        if (!connectedNet) return
        window.activeDialog = "qrcode"
        qrProc.running = true
    }

    function openModifyNetwork(ssid) {
        window.dialogSSID = ssid
        window.dialogPassword = ""
        window.activeDialog = "modify"
        getPasswordProc.exec(["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", ssid])
        modifyPwTimer.start()
    }

    Timer {
        id: modifyPwTimer
        interval: 300
        onTriggered: modifyPwInput.text = window.dialogPassword
    }

    function openForgetNetwork(ssid) {
        window.dialogSSID = ssid
        window.activeDialog = "forget"
    }

    function doForget() {
        forgetProc.exec(["nmcli", "connection", "delete", window.dialogSSID])
    }

    function doModify() {
        const newPw = modifyPwInput.text
        if (newPw.length > 0) {
            window.dialogPassword = newPw
            modifyProc.exec(["nmcli", "connection", "modify", window.dialogSSID, "wifi-sec.psk", newPw])
        }
    }

    function doAddNetwork() {
        const ssid = addSsidInput.text.trim()
        if (ssid.length === 0) return

        addNetError = ""
        const pw = addPasswordInput.text
        if (pw.length > 0) {
            addNetProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", pw])
        } else {
            addNetProc.exec(["nmcli", "dev", "wifi", "connect", ssid])
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
    WlrLayershell.namespace: "quickshell-wifi-osd"
    
    WlrLayershell.keyboardFocus: WifiCenterService.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"
    visible: WifiCenterService.visible

    onVisibleChanged: {
        if (visible) {
            slideInAnim.restart();
            dashContent.forceActiveFocus();
            if (network) {
                network.rescanWifi();
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
                else WifiCenterService.close();
                event.accepted = true;
            }
        }

        // Transparent backdrop clicking closes the window
        Rectangle {
            anchors.fill: parent
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: WifiCenterService.close()
            }
        }

        // Floating Card Container positioned under the Wi-Fi connectivity pill
        Item {
            id: container
            width: 340
            height: Math.min(780, mainColumn.implicitHeight + 32)
            anchors.right: parent.right
            anchors.rightMargin: 200

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

                    // ═══ HEADER: Wi-Fi + Toggle ═══
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 12

                        Text {
                            text: "Wi-Fi"
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
                                color: network.wifiEnabled ? window.cBlue : Qt.rgba(255, 255, 255, 0.12)
                                border.width: network.wifiEnabled ? 0 : 1.5
                                border.color: network.wifiEnabled ? "transparent" : Qt.rgba(255, 255, 255, 0.25)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Rectangle {
                                id: toggleThumb
                                width: 24
                                height: 24
                                radius: 12
                                anchors.verticalCenter: parent.verticalCenter
                                x: network.wifiEnabled ? toggleTrack.width - width - 4 : 4
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                                // Checkmark icon when ON
                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 14
                                    color: window.cBlue
                                    opacity: network.wifiEnabled ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: network.toggleWifi()
                            }
                        }
                    }

                    // ═══ WIRED CONNECTED CARD ═══
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: wiredConnectedRow.implicitHeight + 24
                        Layout.bottomMargin: 16
                        radius: 16
                        color: window.cBlue
                        visible: network.isWired

                        RowLayout {
                            id: wiredConnectedRow
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            DankIcon {
                                name: "lan"
                                size: 22
                                color: "#ffffff"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: network.wiredConnectionName
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Connected via Ethernet"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    color: Qt.rgba(1, 1, 1, 0.7)
                                }
                            }
                        }
                    }

                    // ═══ CONNECTED CARD ═══
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: connectedRow.implicitHeight + 24
                        Layout.bottomMargin: 16
                        radius: 16
                        color: connectedNet ? window.cBlue : window.cCard
                        visible: connectedNet !== null

                        RowLayout {
                            id: connectedRow
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            DankIcon {
                                name: connectedNet ? window.signalIcon(connectedNet.strength) : ""
                                size: 22
                                color: "#ffffff"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 6

                                    Text {
                                        text: connectedNet ? connectedNet.ssid : ""
                                        font.family: "Inter"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        visible: connectedNet && connectedNet.frequency >= 5000
                                        width: badge5g.implicitWidth + 12
                                        height: 20
                                        radius: 6
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.5)
                                        Text {
                                            id: badge5g
                                            anchors.centerIn: parent
                                            text: "5G"
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            color: "#ffffff"
                                        }
                                    }
                                }

                                Text {
                                    text: "Tap to share password"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    color: Qt.rgba(1, 1, 1, 0.7)
                                }
                            }

                            RowLayout {
                                spacing: 6
                                DankIcon {
                                    visible: connectedNet && connectedNet.isSecure
                                    name: "lock"
                                    size: 14
                                    color: Qt.rgba(1, 1, 1, 0.6)
                                }
                                DankIcon {
                                    name: "chevron_right"
                                    size: 16
                                    color: Qt.rgba(1, 1, 1, 0.5)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    window.openModifyNetwork(connectedNet.ssid)
                                } else {
                                    window.openQRShare()
                                }
                            }
                        }
                    }

                    // ═══ SAVED NETWORKS ═══
                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        text: "Saved networks"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: window.cTextSecondary
                        visible: savedNetworks.length > 0
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: savedColumn.implicitHeight + 8
                        Layout.bottomMargin: 16
                        radius: 16
                        color: window.cCard
                        visible: savedNetworks.length > 0

                        ColumnLayout {
                            id: savedColumn
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 0

                            Repeater {
                                model: savedNetworks

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    color: savedArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent"
                                    radius: 12

                                    required property var modelData

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        DankIcon {
                                            name: window.signalIcon(modelData.strength)
                                            size: 18
                                            color: window.cTextPrimary
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Text {
                                                text: modelData.ssid
                                                font.family: "Inter"
                                                font.pixelSize: 14
                                                color: window.cTextPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Rectangle {
                                                visible: Boolean(modelData) && modelData.frequency >= 5000
                                                width: savedBadge5g.implicitWidth + 10
                                                height: 18
                                                radius: 5
                                                color: "transparent"
                                                border.width: 1
                                                border.color: window.cBadgeBorder
                                                Text {
                                                    id: savedBadge5g
                                                    anchors.centerIn: parent
                                                    text: "5G"
                                                    font.family: "Inter"
                                                    font.pixelSize: 9
                                                    font.weight: Font.Medium
                                                    color: window.cTextSecondary
                                                }
                                            }
                                        }

                                        RowLayout {
                                            spacing: 6
                                            DankIcon {
                                                visible: modelData.isSecure
                                                name: "lock"
                                                size: 13
                                                color: window.cTextMuted
                                            }
                                            DankIcon {
                                                name: "chevron_right"
                                                size: 16
                                                color: window.cTextMuted
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: savedArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.RightButton) {
                                                window.openModifyNetwork(modelData.ssid)
                                            } else {
                                                window.connectToNetwork(modelData.ssid, true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ═══ AVAILABLE NETWORKS ═══
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8

                        Text {
                            text: "Available networks"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: window.cTextSecondary
                            Layout.fillWidth: true
                        }

                        // Refresh button with loading spinner
                        RowLayout {
                            spacing: 4
                            visible: !network.scanning

                            Text {
                                text: "Refresh"
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: window.cAccent

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: network.rescanWifi()
                                }
                            }
                        }

                        RowLayout {
                            spacing: 4
                            visible: network.scanning

                            DankIcon {
                                name: "refresh"
                                size: 14
                                color: window.cAccent

                                RotationAnimation on rotation {
                                    running: network.scanning
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: "Scanning"
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: window.cAccent
                            }
                        }
                    }

                    // Sleek Indeterminate Progress Bar for Wi-Fi scanning
                    Rectangle {
                        id: wifiProgressBar
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        Layout.bottomMargin: 6
                        color: "transparent"
                        visible: network.scanning
                        clip: true

                        Rectangle {
                            id: wifiProgressIndicator
                            width: wifiProgressBar.width * 0.3
                            height: 2
                            color: window.cAccent
                            radius: 1
                            x: 0

                            SequentialAnimation on x {
                                running: network.scanning
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: -wifiProgressIndicator.width
                                    to: wifiProgressBar.width
                                    duration: 1200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(availableColumn.implicitHeight + 8, 420)
                        radius: 16
                        color: window.cCard
                        clip: true

                        Flickable {
                            id: availableFlickable
                            anchors.fill: parent
                            anchors.margins: 4
                            contentHeight: availableColumn.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: availableColumn
                                width: parent.width
                                spacing: 0

                                Repeater {
                                    model: availableNetworks

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 52
                                        color: availArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent"
                                        radius: 12

                                        required property var modelData
                                        property bool is5g: Boolean(modelData) && modelData.frequency >= 5000
                                        property bool isSaved: network.savedNetworks.includes(modelData.ssid)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            DankIcon {
                                                name: window.signalIcon(modelData.strength)
                                                size: 18
                                                color: window.cTextPrimary
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Text {
                                                    text: modelData.ssid
                                                    font.family: "Inter"
                                                    font.pixelSize: 14
                                                    color: window.cTextPrimary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Rectangle {
                                                    visible: is5g
                                                    width: availBadge5g.implicitWidth + 10
                                                    height: 18
                                                    radius: 5
                                                    color: "transparent"
                                                    border.width: 1
                                                    border.color: window.cBadgeBorder
                                                    Text {
                                                        id: availBadge5g
                                                        anchors.centerIn: parent
                                                        text: "5G"
                                                        font.family: "Inter"
                                                        font.pixelSize: 9
                                                        font.weight: Font.Medium
                                                        color: window.cTextSecondary
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                spacing: 6
                                                DankIcon {
                                                    visible: modelData.isSecure
                                                    name: "lock"
                                                    size: 13
                                                    color: window.cTextMuted
                                                }
                                                DankIcon {
                                                    name: "chevron_right"
                                                    size: 16
                                                    color: window.cTextMuted
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: availArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.connectToNetwork(modelData.ssid, isSaved)
                                        }
                                    }
                                }

                                // Add network button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48
                                    color: addArea.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent"
                                    radius: 12

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Add network"
                                        font.family: "Inter"
                                        font.pixelSize: 14
                                        color: window.cAccent
                                    }

                                    MouseArea {
                                        id: addArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            window.dialogSSID = ""
                                            window.dialogPassword = ""
                                            window.activeDialog = "addNetwork"
                                            addSsidInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Scrim backdrop for Dialog overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)
            visible: activeDialog !== ""
            z: 50

            MouseArea {
                anchors.fill: parent
                onClicked: window.activeDialog = ""
            }
        }

        // ═══ PASSWORD DIALOG ═══
        Rectangle {
            id: passwordDialogCard
            anchors.centerIn: parent
            width: 300
            height: pwDialogCol.implicitHeight + 40
            radius: 20
            color: window.cCard
            border.color: window.cCardBorder
            border.width: 1
            visible: activeDialog === "password"
            z: 100
            scale: activeDialog === "password" ? 1.0 : 0.9
            opacity: activeDialog === "password" ? 1.0 : 0

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
                id: pwDialogCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "Enter password"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: window.cTextPrimary
                }

                Text {
                    text: window.dialogSSID
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: window.cTextSecondary
                }

                Text {
                    visible: window.wrongPassword
                    text: "Wrong password. Try again."
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: window.cError
                }

                Item {
                    id: pwInputWrapper
                    Layout.fillWidth: true
                    height: 52

                    // Outlined container Rectangle
                    Rectangle {
                        id: pwInputBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: pwInput.activeFocus ? window.cAccent : window.cCardBorder
                        border.width: pwInput.activeFocus ? 2 : 1
                    }

                    // Floating Label overlapping top border
                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: pwLabelText.implicitWidth + 8
                        color: window.cCard
                        
                        Text {
                            id: pwLabelText
                            anchors.centerIn: parent
                            text: "Password"
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.weight: Font.Medium
                            color: pwInput.activeFocus ? window.cAccent : window.cTextSecondary
                        }
                    }

                    QQC.TextField {
                        id: pwInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: pwEyeToggle.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.bottom: parent.bottom
                        placeholderText: "Password"
                        placeholderTextColor: window.cTextMuted
                        echoMode: showPw ? QQC.TextField.Normal : QQC.TextField.Password
                        color: window.cTextPrimary
                        background: Item {}
                        font.family: "Inter"
                        font.pixelSize: 14
                        
                        property bool showPw: false

                        onAccepted: {
                            if (text.length > 0) {
                                window.dialogPassword = text
                                window.wrongPassword = false
                                pendingConnectSSID = window.dialogSSID
                                connectProc.exec(["nmcli", "dev", "wifi", "connect", window.dialogSSID, "password", text])
                                window.activeDialog = ""
                            }
                        }
                    }

                    Rectangle {
                        id: pwEyeToggle
                        width: 28
                        height: 28
                        radius: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        color: pwEyeToggleArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: pwInput.showPw ? "visibility" : "visibility_off"
                            size: 16
                            color: window.cTextSecondary
                        }

                        MouseArea {
                            id: pwEyeToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pwInput.showPw = !pwInput.showPw
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 70
                        height: 36
                        radius: 18
                        color: pwCancelArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
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
                            id: pwCancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.activeDialog = ""
                        }
                    }

                    Rectangle {
                        width: 90
                        height: 36
                        radius: 18
                        color: pwInput.text.length > 0 ? window.cAccent : Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.35)
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#ffffff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: pwInput.text.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                window.dialogPassword = pwInput.text
                                window.wrongPassword = false
                                pendingConnectSSID = window.dialogSSID
                                connectProc.exec(["nmcli", "dev", "wifi", "connect", window.dialogSSID, "password", pwInput.text])
                                window.activeDialog = ""
                            }
                        }
                    }
                }
            }
        }

        // ═══ QR SHARE DIALOG ═══
        Rectangle {
            id: qrDialogCard
            anchors.centerIn: parent
            width: 320
            height: qrCol.implicitHeight + 40
            radius: 20
            color: window.cCard
            border.color: window.cCardBorder
            border.width: 1
            visible: activeDialog === "qrcode"
            z: 100
            scale: activeDialog === "qrcode" ? 1.0 : 0.9
            opacity: activeDialog === "qrcode" ? 1.0 : 0

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
                id: qrCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Text {
                    text: "Share Wi-Fi network"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: window.cTextPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Password: " + window.dialogPassword
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: window.cTextSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 200
                    height: 200
                    radius: 12
                    color: "#ffffff"
                    clip: true

                    Image {
                        id: qrImage
                        anchors.fill: parent
                        anchors.margins: 8
                        fillMode: Image.PreserveAspectFit
                        source: ""
                    }
                }

                Text {
                    text: "To share, scan the QR code above."
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: window.cTextSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 20
                    color: qrDoneArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.8) : window.cAccent

                    Text {
                        anchors.centerIn: parent
                        text: "Done"
                        font.family: "Inter"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: qrDoneArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.activeDialog = ""
                    }
                }
            }
        }

        // ═══ MODIFY NETWORK DIALOG ═══
        Rectangle {
            id: modifyDialogCard
            anchors.centerIn: parent
            width: 300
            height: modifyCol.implicitHeight + 40
            radius: 20
            color: window.cCard
            border.color: window.cCardBorder
            border.width: 1
            visible: activeDialog === "modify"
            z: 100
            scale: activeDialog === "modify" ? 1.0 : 0.9
            opacity: activeDialog === "modify" ? 1.0 : 0

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
                id: modifyCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "Modify network"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: window.cTextPrimary
                }

                Text {
                    text: window.dialogSSID
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: window.cTextSecondary
                }

                Item {
                    id: modifyPwInputWrapper
                    Layout.fillWidth: true
                    height: 52

                    // Outlined container Rectangle
                    Rectangle {
                        id: modifyPwBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: modifyPwInput.activeFocus ? window.cAccent : window.cCardBorder
                        border.width: modifyPwInput.activeFocus ? 2 : 1
                    }

                    // Floating Label overlapping top border
                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: modifyPwLabelText.implicitWidth + 8
                        color: window.cCard
                        
                        Text {
                            id: modifyPwLabelText
                            anchors.centerIn: parent
                            text: "Password"
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.weight: Font.Medium
                            color: modifyPwInput.activeFocus ? window.cAccent : window.cTextSecondary
                        }
                    }

                    QQC.TextField {
                        id: modifyPwInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: modifyPwEyeToggle.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.bottom: parent.bottom
                        placeholderText: "New password"
                        placeholderTextColor: window.cTextMuted
                        echoMode: showPw ? QQC.TextField.Normal : QQC.TextField.Password
                        color: window.cTextPrimary
                        background: Item {}
                        font.family: "Inter"
                        font.pixelSize: 14
                        
                        property bool showPw: false
                    }

                    Rectangle {
                        id: modifyPwEyeToggle
                        width: 28
                        height: 28
                        radius: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        color: modifyPwEyeToggleArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: modifyPwInput.showPw ? "visibility" : "visibility_off"
                            size: 16
                            color: window.cTextSecondary
                        }

                        MouseArea {
                            id: modifyPwEyeToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modifyPwInput.showPw = !modifyPwInput.showPw
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
                        color: modifyForgetArea.containsMouse ? Qt.rgba(window.cError.r, window.cError.g, window.cError.b, 0.15) : "transparent"
                        border.width: 1
                        border.color: window.cError

                        Text {
                            anchors.centerIn: parent
                            text: "Forget network"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: window.cError
                        }

                        MouseArea {
                            id: modifyForgetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.openForgetNetwork(window.dialogSSID)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: modifySaveArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.8) : window.cAccent

                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: modifySaveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.doModify()
                        }
                    }
                }
            }
        }

        // ═══ FORGET CONFIRMATION DIALOG ═══
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
                    text: "Forget network?"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: window.cTextPrimary
                }

                Text {
                    text: `This will remove "${window.dialogSSID}" from saved networks.`
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
                        color: forgetCancelArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
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
                            onClicked: window.activeDialog = "modify"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: forgetConfirmArea.containsMouse ? Qt.rgba(window.cError.r, window.cError.g, window.cError.b, 0.8) : window.cError

                        Text {
                            anchors.centerIn: parent
                            text: "Forget"
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
                            onClicked: window.doForget()
                        }
                    }
                }
            }
        }

        // ═══ ADD NETWORK DIALOG ═══
        Rectangle {
            id: addNetworkDialogCard
            anchors.centerIn: parent
            width: 300
            height: addNetCol.implicitHeight + 40
            radius: 20
            color: window.cCard
            border.color: window.cCardBorder
            border.width: 1
            visible: activeDialog === "addNetwork"
            z: 100
            scale: activeDialog === "addNetwork" ? 1.0 : 0.9
            opacity: activeDialog === "addNetwork" ? 1.0 : 0

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
                id: addNetCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "Add network"
                    font.family: "Inter"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: window.cTextPrimary
                }

                Item {
                    id: addSsidInputWrapper
                    Layout.fillWidth: true
                    height: 52

                    // Outlined container Rectangle
                    Rectangle {
                        id: addSsidBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: addSsidInput.activeFocus ? window.cAccent : window.cCardBorder
                        border.width: addSsidInput.activeFocus ? 2 : 1
                    }

                    // Floating Label overlapping top border
                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: addSsidLabelText.implicitWidth + 8
                        color: window.cCard
                        
                        Text {
                            id: addSsidLabelText
                            anchors.centerIn: parent
                            text: "SSID"
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.weight: Font.Medium
                            color: addSsidInput.activeFocus ? window.cAccent : window.cTextSecondary
                        }
                    }

                    QQC.TextField {
                        id: addSsidInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 6
                        placeholderText: "Network name"
                        placeholderTextColor: window.cTextMuted
                        color: window.cTextPrimary
                        background: Item {}
                        font.family: "Inter"
                        font.pixelSize: 14

                        onAccepted: addPasswordInput.forceActiveFocus()
                    }
                }

                Item {
                    id: addPasswordInputWrapper
                    Layout.fillWidth: true
                    height: 52

                    // Outlined container Rectangle
                    Rectangle {
                        id: addPasswordBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: addPasswordInput.activeFocus ? window.cAccent : window.cCardBorder
                        border.width: addPasswordInput.activeFocus ? 2 : 1
                    }

                    // Floating Label overlapping top border
                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: addPasswordLabelText.implicitWidth + 8
                        color: window.cCard
                        
                        Text {
                            id: addPasswordLabelText
                            anchors.centerIn: parent
                            text: "Password"
                            font.pixelSize: 10
                            font.family: "Inter"
                            font.weight: Font.Medium
                            color: addPasswordInput.activeFocus ? window.cAccent : window.cTextSecondary
                        }
                    }

                    QQC.TextField {
                        id: addPasswordInput
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: addPasswordEyeToggle.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.bottom: parent.bottom
                        placeholderText: "Leave empty for open network"
                        placeholderTextColor: window.cTextMuted
                        echoMode: showPw ? QQC.TextField.Normal : QQC.TextField.Password
                        color: window.cTextPrimary
                        background: Item {}
                        font.family: "Inter"
                        font.pixelSize: 14
                        property bool showPw: false

                        onAccepted: window.doAddNetwork()
                    }

                    Rectangle {
                        id: addPasswordEyeToggle
                        width: 28
                        height: 28
                        radius: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        color: addPasswordEyeToggleArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

                        DankIcon {
                            anchors.centerIn: parent
                            name: addPasswordInput.showPw ? "visibility" : "visibility_off"
                            size: 16
                            color: window.cTextSecondary
                        }

                        MouseArea {
                            id: addPasswordEyeToggleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addPasswordInput.showPw = !addPasswordInput.showPw
                        }
                    }
                }

                Text {
                    visible: window.addNetError.length > 0
                    text: window.addNetError
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: window.cError
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: addNetCancelArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
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
                            id: addNetCancelArea
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
                        color: addSsidInput.text.length > 0
                            ? (addNetConnectArea.containsMouse ? Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.85) : window.cAccent)
                            : Qt.rgba(window.cAccent.r, window.cAccent.g, window.cAccent.b, 0.25)
                        scale: addNetConnectArea.pressed ? 0.97 : 1.0

                        Behavior on scale { NumberAnimation { duration: 80 } }

                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: addSsidInput.text.length > 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.4)
                        }

                        MouseArea {
                            id: addNetConnectArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: addSsidInput.text.length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.doAddNetwork()
                        }
                    }
                }
            }
        }
    }
}
