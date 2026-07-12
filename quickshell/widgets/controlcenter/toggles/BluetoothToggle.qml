import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: "Bluetooth"
    readonly property bool toggled: Bluetooth.powered
    
    readonly property string icon: Bluetooth.powered ? (Bluetooth.connected ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled"
    readonly property string iconOff: "bluetooth_disabled"
    
    readonly property string statusText: {
        if (!Bluetooth.powered) return "Off"
        if (Bluetooth.connected) return Bluetooth.deviceName || "Connected"
        return "On"
    }

    readonly property bool hasDetails: true

    function action() {
        Bluetooth.togglePower()
    }

    function detailsAction() {
        ControlCenterService.close()
        BluetoothCenterService.toggle()
    }
}
