pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false
    property int activeTab: 1

    function toggle() {
        visible = !visible;
    }

    function close() {
        visible = false;
    }
}
