import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"

Item {
    id: root

    readonly property var matugen: Theme
    readonly property bool isActive: ControlCenterService.visible
    readonly property bool isHovered: toggleMouse.containsMouse
    
    implicitWidth: controlCenterIcon.implicitWidth + 8 * Appearance.effectiveScale
    implicitHeight: controlCenterIcon.implicitHeight
    
    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            ControlCenterService.toggle()
        }
    }
    
    // Modern settings icon with rotation effect
    DankIcon {
        id: controlCenterIcon
        anchors.centerIn: parent
        name: "settings"
        size: 18 * Appearance.effectiveScale
        
        color: {
            if (isActive) return matugen.primary
            if (isHovered) return matugen.primary
            return Qt.rgba(1, 1, 1, 0.85)
        }
        
        Behavior on color {
            ColorAnimation { 
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        
        // Smooth rotation when active
        rotation: isActive ? 90 : 0
        
        Behavior on rotation {
            NumberAnimation { 
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        
        // Hover/active scale
        scale: {
            if (toggleMouse.pressed) return 0.9
            if (isHovered || isActive) return 1.1
            return 1.0
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }
    }
}
