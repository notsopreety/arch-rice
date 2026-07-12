import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: shellRoot

    LockContext {
        id: lockContext

        onUnlocked: {
            // Unlock the screen before exiting to prevent fallback compositor locks
            lock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: lock

        // Lock the session immediately upon startup
        locked: true

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}
