import QtQuick
import "../../../services"

QtObject {
    id: root

    readonly property string name: PowerProfiles.getProfileLabel(PowerProfiles.activeProfile)
    readonly property bool toggled: true // Keep it always styled as active since power profile is always in one of the states
    
    readonly property string icon: PowerProfiles.getProfileIcon(PowerProfiles.activeProfile)
    readonly property string iconOff: "eco"
    
    readonly property string statusText: {
        const p = PowerProfiles.activeProfile
        if (p === "power-saver") return "Power saving"
        if (p === "performance") return "Max performance"
        return "Balanced mode"
    }

    readonly property bool hasDetails: false

    // Custom colors matching the old control center
    readonly property color customColorActive: {
        const p = PowerProfiles.activeProfile
        if (p === "power-saver") return Qt.rgba(0.3, 0.69, 0.33, 0.22)
        if (p === "performance") return Qt.rgba(0.96, 0.26, 0.21, 0.22)
        return Qt.rgba(1.0, 0.6, 0.0, 0.18)
    }

    readonly property color customColorActiveHover: {
        const p = PowerProfiles.activeProfile
        if (p === "power-saver") return Qt.rgba(0.3, 0.69, 0.33, 0.32)
        if (p === "performance") return Qt.rgba(0.96, 0.26, 0.21, 0.32)
        return Qt.rgba(1.0, 0.6, 0.0, 0.28)
    }

    readonly property color customBorderColorActive: {
        const p = PowerProfiles.activeProfile
        if (p === "power-saver") return Qt.rgba(0.3, 0.69, 0.33, 0.5)
        if (p === "performance") return Qt.rgba(0.96, 0.26, 0.21, 0.5)
        return Qt.rgba(1.0, 0.6, 0.0, 0.4)
    }

    readonly property color customTextColorActive: {
        const p = PowerProfiles.activeProfile
        if (p === "power-saver") return "#4caf50"
        if (p === "performance") return "#ef5350"
        return "#ff9800"
    }

    readonly property color customIconColor: customTextColorActive

    function action() {
        const profiles = PowerProfiles.availableProfiles
        const current = PowerProfiles.activeProfile
        const idx = profiles.indexOf(current)
        const next = profiles[(idx + 1) % profiles.length]
        PowerProfiles.setProfile(next)
    }
}
