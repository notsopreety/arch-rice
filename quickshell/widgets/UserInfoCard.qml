import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../core"

Card {
    id: root
    
    pad: 8 * Appearance.effectiveScale

    RowLayout {
        anchors.centerIn: parent
        spacing: 10 * Appearance.effectiveScale
        
        // Avatar container
        Rectangle {
            Layout.preferredWidth: 44 * Appearance.effectiveScale
            Layout.preferredHeight: 44 * Appearance.effectiveScale
            radius: width / 2
            color: Theme.primaryContainer
            border.color: Theme.primary
            border.width: 1
            clip: true
            
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: Theme.font.monospace
                font.pixelSize: 22 * Appearance.effectiveScale
                color: Theme.onPrimaryContainerColor
            }
        }
        
        ColumnLayout {
            spacing: 2 * Appearance.effectiveScale
            Layout.fillWidth: true
            
            Text {
                text: "sawmer"
                font.family: Theme.font.family
                font.pixelSize: 14 * Appearance.effectiveScale
                font.weight: Font.Medium
                color: "white"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            RowLayout {
                spacing: 4 * Appearance.effectiveScale
                Layout.fillWidth: true
                
                Text {
                    text: ""
                    font.family: Theme.font.monospace
                    font.pixelSize: 12 * Appearance.effectiveScale
                    color: Theme.primary
                }
                
                Text {
                    text: "on Hyprland"
                    font.family: Theme.font.family
                    font.pixelSize: 10 * Appearance.effectiveScale
                    color: "#e7bdb3"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            
            RowLayout {
                spacing: 4 * Appearance.effectiveScale
                Layout.fillWidth: true
                
                Text {
                    text: "󰄉"
                    font.family: Theme.font.monospace
                    font.pixelSize: 12 * Appearance.effectiveScale
                    color: Theme.primary
                }
                
                Text {
                    text: DgopService.uptime
                    font.family: Theme.font.family
                    font.pixelSize: 10 * Appearance.effectiveScale
                    color: "#e7bdb3"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}
