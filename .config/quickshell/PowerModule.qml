import QtQuick
import Quickshell

/*
 * Session/power pill. Left click opens the wlogout-style fullscreen overlay
 * (same buttons, keys and commands as ~/.config/wlogout/layout), right click
 * locks straight away.
 */
Pill {
    id: root

    label: "⏻"
    tooltip: "Session — click for power menu (S/R/E/H/L), right-click to lock"

    emphasized: PowerState.open

    onClicked: function(event) {
        if (event.button === Qt.RightButton) {
            PowerState.run("lock");
        } else {
            PowerState.open = true;
        }
    }
}
