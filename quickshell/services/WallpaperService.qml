pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false

    function open() {
        visible = true;
    }

    function close() {
        visible = false;
    }

    function toggle() {
        visible = !visible;
    }
}
