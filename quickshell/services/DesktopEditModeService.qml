pragma Singleton
import QtQuick

QtObject {
    property bool isEditing: false

    function toggle() {
        isEditing = !isEditing;
    }
}
