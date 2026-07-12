pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Power Profiles Service (power-profiles-daemon)
Singleton {
    id: root
    
    property string activeProfile: "balanced"  // performance, balanced, power-saver
    property var availableProfiles: ["performance", "balanced", "power-saver"]
    property bool isAvailable: false
    
    Component.onCompleted: {
        checkAvailability()
        updateActiveProfile()
    }
    
    function checkAvailability() {
        checkProc.running = true
    }
    
    Process {
        id: checkProc
        command: ["which", "powerprofilesctl"]
        onExited: code => {
            root.isAvailable = code === 0
            if (root.isAvailable) {
                QsServices.Logger.debug("PowerProfiles", "Service available")
                root.updateActiveProfile()
            }
        }
    }
    
    function updateActiveProfile() {
        if (!isAvailable) return
        getProc.running = true
    }
    
    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                let profile = text.trim()
                if (root.activeProfile !== profile) {
                    root.activeProfile = profile
                    QsServices.Logger.info("PowerProfiles", `Active profile: ${root.activeProfile}`)
                }
            }
        }
    }
    
    function setProfile(profile: string) {
        if (!isAvailable) return
        if (!availableProfiles.includes(profile)) return
        
        setProc.exec(["powerprofilesctl", "set", profile])
    }
    
    Process {
        id: setProc
        onExited: code => {
            if (code === 0) {
                root.updateActiveProfile()
            }
        }
    }
    
    function getProfileIcon(profile: string): string {
        switch(profile) {
            case "performance": return "speed"
            case "balanced": return "balance"
            case "power-saver": return "eco"
            default: return "speed"
        }
    }
    
    function getProfileLabel(profile: string): string {
        switch(profile) {
            case "performance": return "Performance"
            case "balanced": return "Balanced"
            case "power-saver": return "Power Saver"
            default: return profile
        }
    }
}
