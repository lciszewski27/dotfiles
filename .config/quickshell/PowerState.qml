pragma Singleton

import QtQuick
import Quickshell

/*
 * PowerState.qml
 *
 * Single source of truth for the wlogout-style session overlay. Actions and
 * keybinds mirror ~/.config/wlogout/layout exactly (including the
 * loginctl-based lock/logout/sleep commands).
 */
Singleton {
    id: root

    property bool open: false

    function toggle() {
        root.open = !root.open;
    }

    function run(action) {
        root.open = false;
        if (action === "lock") {
            LockState.lock();
        } else if (action === "logout") {
            Quickshell.execDetached(["sh", "-c", "loginctl kill-session $XDG_SESSION_ID"]);
        } else if (action === "sleep") {
            LockState.lock();
            Quickshell.execDetached(["systemctl", "suspend"]);
        } else if (action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }
}
