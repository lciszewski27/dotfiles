import QtQuick
import Quickshell
import Quickshell.Wayland

/*
 * LockScreen.qml
 *
 * One WlSessionLockSurface per screen, hosting the shared LockContent UI.
 * Instantiated as WlSessionLock.surface in shell.qml.
 */
WlSessionLockSurface {
    id: root

    color: "transparent"

    LockContent {
        anchors.fill: parent
    }
}
