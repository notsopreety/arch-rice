import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root
    signal unlocked()
    signal failed()

    // Shared state between monitors
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Clear failure text when the user types
    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (root.unlockInProgress) {
            console.log("[LockContext] Unlock already in progress, ignoring.");
            return;
        }
        console.log("[LockContext] tryUnlock called with password length:", currentText ? currentText.length : 0);
        if (!currentText || currentText.trim() === "") {
            console.log("[LockContext] Empty password, aborting unlock attempt.");
            return;
        }

        root.unlockInProgress = true;
        unlockWatchdog.start();
        console.log("[LockContext] Starting PAM authentication...");
        pam.start();
    }

    // Watchdog: if PAM never signals completion, don't leave the screen stuck locked.
    Timer {
        id: unlockWatchdog
        interval: 15000
        repeat: false
        onTriggered: {
            if (!root.unlockInProgress)
                return;
            console.log("[LockContext] PAM watchdog timeout - no completion signal received.");
            root.unlockInProgress = false;
            root.showFailure = true;
            root.failed();
        }
    }

    PamContext {
        id: pam

        // Points to our password.conf directory relative to this QML file
        configDirectory: Quickshell.shellPath("widgets/lockscreen/pam")
        config: "password.conf"

        onPamMessage: {
            console.log("[LockContext] PAM Message received. responseRequired:", this.responseRequired);
            if (this.responseRequired) {
                this.respond(root.currentText);
            }
        }

        onCompleted: result => {
            console.log("[LockContext] PAM completed. Result:", result, "Success is:", PamResult.Success);
            if (result === PamResult.Success) {
                console.log("[LockContext] PAM success! Unlocking...");
                root.currentText = "";
                root.unlocked();
            } else {
                console.log("[LockContext] PAM failed.");
                root.currentText = "";
                root.showFailure = true;
                root.failed();
            }

            unlockWatchdog.stop();
            root.unlockInProgress = false;
        }
    }
}
