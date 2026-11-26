import QtQuick
import Quickshell
import Quickshell.Wayland

/*
 * Wlogout.qml
 *
 * Quickshell session overlay (replaces wlogout + hyprlock-era power menu):
 * five borderless icon+label buttons in one centered row, icons at
 * 20% growing toward 50% with a bouncy ease on hover, hover fills the button
 * with primary and hides the label, S/R/E/H/L keybinds, Esc/dim-click to
 * cancel. Overlay layer + Ignore exclusion so it never reserves space.
 *
 * One instance per screen (see shell.qml); all bind to PowerState.open.
 * Trigger with `qs ipc call power toggle` (SUPER+Q).
 */
PanelWindow {
    id: win

    required property var modelData

    // Quickshell-owned session icons (migrated from removed ~/.config/wlogout/icons/).
    readonly property string iconDir: "file:///home/lukasz/.config/quickshell/icons/"
    // Idle icon ~20% of the button width, like background-size: 20%.
    readonly property real iconIdle: 76
    readonly property real iconHover: 160

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: PowerState.open
    visible: win.anim > 0.01
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wlogout"

    property bool opened: PowerState.open
    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    onOpenedChanged: win.anim = opened ? 1 : 0

    // Dim surface + frosted blur (see the quickshell-wlogout layer rule):
    // translucent enough for the blurred wallpaper to read through.
    Rectangle {
        anchors.fill: parent
        color: "#1a0e2e"
        opacity: win.anim * 0.6

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: PowerState.open = false
        }
    }

    // Keyboard: Esc cancels, S/R/E/H/L trigger (quickshell-owned session actions).
    Item {
        anchors.fill: parent
        focus: PowerState.open
        Keys.onEscapePressed: PowerState.open = false
        Keys.onPressed: function(event) {
            var key = event.text.toLowerCase();
            if (key === "s") PowerState.run("shutdown");
            else if (key === "r") PowerState.run("reboot");
            else if (key === "e") PowerState.run("logout");
            else if (key === "h") PowerState.run("sleep");
            else if (key === "l") PowerState.run("lock");
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 22
        opacity: win.anim

        Repeater {
            model: [
                { action: "shutdown", icon: "power", label: "Shutdown", key: "s" },
                { action: "reboot", icon: "restart", label: "Reboot", key: "r" },
                { action: "logout", icon: "logout", label: "Logout", key: "e" },
                { action: "sleep", icon: "hibernate", label: "Sleep", key: "h" },
                { action: "lock", icon: "lock", label: "Lock", key: "l" }
            ]
            delegate: Rectangle {
                required property var modelData
                property var entry: modelData

                // Transparent idle box; primary fill on hover (radius 36px,
                // like the wlogout buttons).
                width: 280
                height: 280
                radius: 36
                color: btnMouse.containsMouse ? Theme.base07 : "transparent"

                Behavior on color { ColorAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 54

                    // Fixed square box with aspect-fit content: the set mixes
                    // square (512x512) and portrait (448x512, 384x512) PNGs,
                    // so filling a square would stretch lock/hibernate.
                    // mipmap keeps the downscaled glyphs smooth.
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: btnMouse.containsMouse ? win.iconHover : win.iconIdle
                        height: width

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            source: win.iconDir + entry.icon
                                + (btnMouse.containsMouse ? "-hover" : "") + ".png"
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: entry.label
                        // Hide the label on hover (color: transparent).
                        color: btnMouse.containsMouse ? "transparent" : "#e8e0e8"
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.DemiBold

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: PowerState.run(entry.action)
                }
            }
        }
    }
}
