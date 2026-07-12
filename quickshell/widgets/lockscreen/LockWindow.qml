import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

// Hosts the session lock inside the main shell process.
// LockService.lock() arms it; on unlock the PamContext signals back
// and we call LockService.unlock() to disarm.
Scope {
    id: root

    LockContext {
        id: lockContext

        onUnlocked: {
            LockService.unlock();
        }
    }

    Connections {
        target: LockService
        function onLockedChanged() {
            if (LockService.locked) {
                lockContext.currentText = "";
                lockContext.showFailure = false;
            }
        }
    }

    WlSessionLock {
        id: lock

        // Only lock when LockService says so
        locked: LockService.locked

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}
