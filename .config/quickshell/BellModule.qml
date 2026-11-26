import QtQuick
import Quickshell

/*
 * Notification bell. The single NotificationServer lives in shell.qml and
 * feeds NotifyState; this pill shows the unread count, opens the history
 * dialog, and toggles do-not-disturb.
 */
Pill {
    id: root

    property bool historyOpen: false

    label: NotifyState.dnd ? "󰪑" : (NotifyState.unread > 0 ? "󰂛 " + NotifyState.unread : "󰂚")
    stateClass: NotifyState.dnd ? "none" : (NotifyState.unread > 0 ? "active" : "")

    tooltip: {
        if (NotifyState.dnd) return "Do not disturb on — notifications held in history";
        if (NotifyState.unread > 0) {
            var lines = [];
            var arr = NotifyState.items;
            for (var i = 0; i < Math.min(arr.length, 5); i++) {
                lines.push((arr[i].n.summary || arr[i].n.appName || "notification"));
            }
            return lines.join("\n");
        }
        return "No new notifications";
    }

    emphasized: root.historyOpen

    onClicked: function(event) {
        if (event.button === Qt.RightButton || event.button === Qt.MiddleButton) {
            NotifyState.dnd = !NotifyState.dnd;
        } else {
            if (!root.historyOpen) NotifyState.markRead();
            root.historyOpen = !root.historyOpen;
        }
    }

    DialogWindow {
        anchorItem: root
        show: root.historyOpen
        onDismissed: root.historyOpen = false
        title: "Notifications"
        subtitle: NotifyState.dnd ? "Do not disturb — new ones are held here" : "Recent notifications"
        dialogWidth: 380

        // ── Do not disturb ────────────────────────────────────
        Row {
            width: parent.width
            spacing: 10

            Column {
                width: parent.width - 50
                spacing: 2

                Text {
                    text: "Do not disturb"
                    color: Theme.base07
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                Text {
                    width: parent.width
                    text: NotifyState.dnd ? "Popups held, bell stays quiet" : "Popups appear top-right"
                    color: Theme.base05
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            ToggleSwitch {
                anchors.verticalCenter: parent.verticalCenter
                checked: NotifyState.dnd
                onToggled: function(on) { NotifyState.dnd = on; }
            }
        }

        // ── Clear ─────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 28
            radius: 8
            color: clearMouse.containsMouse ? Theme.base03 : Theme.base02
            visible: NotifyState.items.length > 0

            Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: Theme.base06
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotifyState.clearHistory()
            }
        }

        Text {
            width: parent.width
            text: "Nothing here — you're all caught up."
            visible: NotifyState.items.length === 0
            color: Theme.base04
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
        }

        // ── History ───────────────────────────────────────────
        Repeater {
            model: NotifyState.items
            delegate: Rectangle {
                required property var modelData
                property var item: modelData
                property var n: item.n

                width: parent.width
                height: entryCol.implicitHeight + 16
                radius: 10
                color: histMouse.containsMouse ? Theme.base02 : "transparent"
                border.color: Theme.base03
                border.width: 1

                Column {
                    id: entryCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 2

                    Text {
                        width: parent.width
                        text: (n.summary || n.appName || "notification")
                        color: Theme.base06
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: (n.appName || "") + (n.appName ? " · " : "") + Qt.formatDateTime(new Date(item.ts), "HH:mm")
                        visible: text !== ""
                        color: Theme.base05
                        font.family: Theme.fontUi
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: histMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotifyState.dismissNotification(item.id)
                }
            }
        }
    }
}
