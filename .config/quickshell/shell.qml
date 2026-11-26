import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Polkit

/*
 * Quickshell bar + session (replaces waybar + dunst + wlogout + hyprlock).
 *
 * Layout:  [updates] [mpris]        [workspaces]        [tray] [matura]
 *          [weather] [bluetooth] [volume] [network] [bell] [clock]
 *
 * Every colour comes from Theme.qml, which Matugen regenerates from the
 * current wallpaper. Launch with `QS_ICON_THEME=Papirus-Dark qs`
 * (or `qs -c default`).
 *
 * This process owns org.freedesktop.Notifications (dunst removed),
 * runs the session lock (SUPER+L calls `qs ipc call lock lock`),
 * the power menu (SUPER+Q calls `qs ipc call power toggle`),
 * and the polkit agent (replacing polkit-gnome).
 */
ShellRoot {
    id: root

    Component.onCompleted: {
        root.settings.watchFiles = true;
        WallpaperState.refresh();
        WallpaperState.restore();
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        onNotification: function(n) { NotifyState.push(n); }
    }

    // ── Session lock ──────────────────────────────────────────
    // Only `lock()` is exposed over IPC on purpose: unlocking must always
    // go through the PAM password prompt on the lock surface.
    WlSessionLock {
        id: sessionLock
        locked: LockState.locked
        surface: Component {
            LockScreen {}
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            LockState.lock();
        }
        function status(): bool {
            return LockState.locked;
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            PowerState.toggle();
        }
        function open(): void {
            PowerState.open = true;
        }
        function close(): void {
            PowerState.open = false;
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            WallpaperState.toggle();
        }
        function apply(path: string): void {
            WallpaperState.apply(path);
        }
        function refresh(): void {
            WallpaperState.refresh();
        }
    }

    // Polkit authentication agent. Lives at root scope (not in a singleton)
    // so its registration completes; the per-screen dialog gets it passed
    // down. Replaces polkit-gnome — only one agent may register.
    PolkitAgent {
        id: polkitAgent
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property var modelData

                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                margins {
                    top: 5
                    left: 8
                    right: 8
                }

                // 5px top margin + 28px bar + 5px wallpaper gap below. Note the
                // exclusive zone is smaller than the panel bottom (33) on
                // purpose: Hyprland adds gaps_out (8) plus the window frame
                // on top of it, so tiled windows land at ~38px and the
                // visible strips above/below the bar match.
                implicitHeight: 28
                color: "transparent"
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: 25
                focusable: false

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                // Explicit anchoring: the left group hugs the left edge,
                // workspaces are centred on the screen, the right group hugs
                // the right edge. No fillWidth distribution that could make
                // a short left group look centred.
                Row {
                    id: leftGroup
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 2
                    spacing: 4

                    UpdatesModule {}
                    MprisModule {}
                }

                Workspaces {
                    id: centerGroup
                    anchors.centerIn: parent
                }

                Row {
                    id: rightGroup
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 2
                    spacing: 4

                    TrayModule {}
                    CountdownModule {}
                    WeatherModule {}
                    BluetoothModule {}
                    AudioModule {}
                    NetworkModule {}
                    BellModule {}
                    ClockModule {}
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // Polkit authentication prompt (centered, one per screen).
            PolkitDialog {
                modelData: modelData
                agent: polkitAgent
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // Desktop background, painted by Quickshell itself.
            WallpaperLayer {
                modelData: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // Wallpaper picker (centered grid, one per screen).
            WallpaperPicker {
                modelData: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // Quickshell session overlay (fullscreen, one per screen).
            Wlogout {
                modelData: modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // ── Notification toasts (top-right, below the bar) ──────
            // Ignore-exclusion overlay: never reserves space, only maps
            // while a toast is alive.
            PanelWindow {
                required property var modelData

                screen: modelData
                anchors {
                    top: true
                    right: true
                }
                margins {
                    top: 38
                    right: 8
                }
                implicitWidth: 360
                implicitHeight: toastList.implicitHeight
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                visible: NotifyState.toasts.length > 0

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-notify"

                Column {
                    id: toastList
                    anchors.right: parent.right
                    width: 360
                    spacing: 8
                    // Fade the whole stack in/out; per-toast entrances would
                    // replay for every toast whenever the model refreshes.
                    opacity: NotifyState.toasts.length > 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Repeater {
                        model: NotifyState.toasts
                        delegate: Rectangle {
                            required property var modelData
                            property var item: modelData
                            property var n: item.n
                            property bool critical: n.urgency === NotificationUrgency.Critical

                            width: 360
                            implicitHeight: toastCol.implicitHeight + 26
                            radius: 14
                            color: Theme.base01
                            border.color: critical ? Theme.m3Error : Theme.base03
                            border.width: critical ? 2 : 1

                            // Urgency accent stripe.
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                width: 3
                                radius: 2
                                color: critical ? Theme.m3Error
                                    : n.urgency === NotificationUrgency.Low ? Theme.base04 : Theme.base07
                            }

                            Column {
                                id: toastCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
                                anchors.topMargin: 10
                                spacing: 4

                                Row {
                                    width: parent.width
                                    spacing: 6

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        smooth: true
                                        source: {
                                            var ic = n.appIcon || n.desktopEntry || "";
                                            if (ic.indexOf("image://") === 0 || ic.indexOf("file://") === 0 ||
                                                ic.charAt(0) === "/") return ic;
                                            return Quickshell.iconPath(ic || "dialog-information", "dialog-information");
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        // Shrinks when the urgency tag is shown so the
                                        // row never overflows; expands into the freed
                                        // space when the tag hides (no dead gap).
                                        width: parent.width - 18 - 24 - 12 - (tagLabel.visible ? 56 : 0)
                                        text: (n.appName || "notification") + " · " + Qt.formatDateTime(new Date(item.ts), "HH:mm")
                                        color: Theme.base05
                                        font.family: Theme.fontUi
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        id: tagLabel
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 50
                                        text: n.urgency === NotificationUrgency.Critical ? "urgent"
                                            : n.urgency === NotificationUrgency.Low ? "quiet" : ""
                                        visible: text !== ""
                                        color: critical ? Theme.m3Error : Theme.base04
                                        font.family: Theme.fontUi
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        text: "✕"
                                        color: toastXMouse.containsMouse ? Theme.base07 : Theme.base05
                                        font.family: Theme.fontUi
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignHCenter

                                        MouseArea {
                                            id: toastXMouse
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotifyState.dismissNotification(item.id)
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: n.summary || ""
                                    visible: text !== ""
                                    color: critical ? Theme.m3Error : Theme.base07
                                    font.family: Theme.fontUi
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    wrapMode: Text.Wrap
                                }

                                Text {
                                    width: parent.width
                                    text: n.body || ""
                                    visible: text !== ""
                                    color: Theme.base06
                                    font.family: Theme.fontUi
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.Wrap
                                    textFormat: Text.RichText
                                }

                                Row {
                                    width: parent.width
                                    spacing: 6
                                    visible: n.actions.length > 0

                                    Repeater {
                                        model: n.actions
                                        delegate: Rectangle {
                                            required property var modelData
                                            property var act: modelData

                                            width: Math.min(actLabel.implicitWidth + 18, 160)
                                            height: 26
                                            radius: 7
                                            color: actMouse.containsMouse ? Theme.base03 : Theme.base02
                                            border.color: Theme.base03
                                            border.width: 1

                                            Text {
                                                id: actLabel
                                                anchors.centerIn: parent
                                                width: parent.width - 18
                                                text: act.text
                                                color: Theme.base07
                                                font.family: Theme.fontUi
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter
                                            }

                                            MouseArea {
                                                id: actMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    act.invoke();
                                                    NotifyState.dismissNotification(item.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Time-to-live progress (critical/sticky ones persist).
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                anchors.bottomMargin: 8
                                height: 2
                                radius: 1
                                color: Theme.base03
                                visible: item.timeout > 0

                                Rectangle {
                                    id: toastProgress
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: parent.height
                                    radius: 1
                                    color: critical ? Theme.m3Error : Theme.base07
                                }

                                NumberAnimation {
                                    target: toastProgress
                                    property: "width"
                                    from: 346 - 28
                                    to: 0
                                    duration: item.timeout
                                    running: item.timeout > 0
                                    onFinished: NotifyState.dismissToast(item.id)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotifyState.dismissNotification(item.id)
                            }

                            // Fallback expiry if the animation never runs.
                            Timer {
                                interval: item.timeout > 0 ? item.timeout + 500 : 0
                                running: item.timeout > 0
                                onTriggered: NotifyState.dismissToast(item.id)
                            }
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            // ── Volume OSD (top-center) ───────────────────────────
            PanelWindow {
                required property var modelData

                screen: modelData
                anchors {
                    top: true
                    left: true
                    right: true
                }
                margins {
                    top: 38
                }
                implicitHeight: 96
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: false
                visible: osdAnim > 0.01 || mediaAnim > 0.01

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-osd"

                property real osdAnim: 0
                property bool active: OsdState.active
                property real mediaAnim: 0
                property bool mediaOn: OsdState.mediaActive
                Behavior on osdAnim { NumberAnimation { duration: 160 } }
                Behavior on mediaAnim { NumberAnimation { duration: 160 } }
                onActiveChanged: osdAnim = active ? 1 : 0
                onMediaOnChanged: mediaAnim = mediaOn ? 1 : 0

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    spacing: 8

                    Rectangle {
                        width: 300
                        height: 40
                        radius: 12
                        color: Theme.base01
                        border.color: Theme.base03
                        border.width: 1
                        opacity: osdAnim
                        visible: osdAnim > 0.01

                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (!OsdState.muted && OsdState.volume <= 0.001) return "󰝟";
                                    if (OsdState.muted) return "󰝟";
                                    if (OsdState.volume < 0.34) return "󰕿";
                                    if (OsdState.volume < 0.67) return "󰖀";
                                    return "󰕾";
                                }
                                color: OsdState.muted ? Theme.base04 : Theme.base06
                                font.family: Theme.fontMono
                                font.pixelSize: 16
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 190
                                height: 6
                                radius: 3
                                color: Theme.base03

                                Rectangle {
                                    width: parent.width * Math.min(OsdState.volume, 1)
                                    height: parent.height
                                    radius: 3
                                    color: OsdState.muted ? Theme.base04 : Theme.base07
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                text: Math.round(OsdState.volume * 100) + "%"
                                color: Theme.base06
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Rectangle {
                        width: 300
                        height: 40
                        radius: 12
                        color: Theme.base01
                        border.color: Theme.base03
                        border.width: 1
                        opacity: mediaAnim
                        visible: mediaAnim > 0.01

                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: OsdState.mediaPlaying ? "" : ""
                                color: Theme.base07
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 240
                                text: (OsdState.mediaTitle || "Unknown title")
                                    + (OsdState.mediaArtist !== "" ? " — " + OsdState.mediaArtist : "")
                                color: Theme.base06
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
