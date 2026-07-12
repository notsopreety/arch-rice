import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: Network.isWired ? "Ethernet" : "Wi-Fi"
    readonly property bool toggled: Network.wifiEnabled
    
    readonly property string icon: {
        if (Network.isWired) return "lan"
        if (!Network.wifiEnabled) return "wifi_off"
        if (Network.active) {
            const strength = Network.active.strength
            if (strength >= 75) return "wifi"
            if (strength >= 50) return "network_wifi_3_bar"
            if (strength >= 25) return "network_wifi_2_bar"
            return "network_wifi_1_bar"
        }
        return "wifi"
    }
    
    readonly property string iconOff: "wifi_off"
    
    readonly property string statusText: {
        if (Network.isWired) return Network.wiredConnectionName || "Wired"
        if (!Network.wifiEnabled) return "Off"
        if (Network.active) return Network.active.ssid || "Connected"
        return "Disconnected"
    }

    readonly property bool hasDetails: true

    function action() {
        Network.toggleWifi()
    }

    function detailsAction() {
        ControlCenterService.close()
        WifiCenterService.toggle()
    }
}
