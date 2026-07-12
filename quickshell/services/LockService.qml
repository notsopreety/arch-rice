pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool locked: false

    function lock() {
        locked = true;
    }

    function unlock() {
        locked = false;
    }
}
