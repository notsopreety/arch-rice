pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false

    signal requestOpen()
    signal requestToggle()

    function open() {
        requestOpen();
    }

    function close() {
        visible = false;
    }

    function toggle() {
        requestToggle();
    }
}
