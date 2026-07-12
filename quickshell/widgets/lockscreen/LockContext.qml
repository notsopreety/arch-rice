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
        console.log("[LockContext] tryUnlock called with password length:", currentText ? currentText.length : 0);
        if (!currentText || currentText.trim() === "") {
            console.log("[LockContext] Empty password, aborting unlock attempt.");
            return;
        }

        root.unlockInProgress = true;
        console.log("[LockContext] Starting PAM authentication...");
        pam.start();
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

            root.unlockInProgress = false;
        }
    }
}
