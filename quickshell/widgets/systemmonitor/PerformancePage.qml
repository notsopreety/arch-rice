import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

import "pages"

/**
 * PerformancePage manages sub-navigation for system metrics.
 */
Item {
    id: root
    property int subIndex: 0


    // Reset to Overview (0) when System Monitor closes
    Connections {
        target: GlobalStates
        function onSystemMonitorOpenChanged() {
            if (!GlobalStates.systemMonitorOpen) {
                root.subIndex = 0;
                GlobalStates.performanceSubIndex = 0;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Horizontal Tab Bar (Compact 1-row Card Buttons)
        StyledTabBar {
            Layout.fillWidth: true
            showIcon: true
            iconOnTop: true
            currentTab: GlobalStates.performanceSubIndex
            onTabClicked: (index) => GlobalStates.performanceSubIndex = index
            tabModel: [
                { name: "Overview", icon: "dashboard" },
                { name: "CPU", icon: "monitoring" },
                { name: "GPU", icon: "videogame_asset" },
                { name: "Memory", icon: "memory" },
                { name: "Network", icon: "public" },
                { name: "Disk", icon: "storage" }
            ]
        }
        
        // Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: GlobalStates.performanceSubIndex
            
            OverviewPage {}
            CpuPage {}
            GpuPage {}
            MemoryPage {}
            NetworkPage {}
            DiskPage {}
        }
    }
}
