import QtQuick
import Quickshell
import Quickshell.Bluetooth

/*
 * Bluetooth popover: power + scan toggles and the device list with
 * connect/disconnect and pair/forget actions. Self-sufficient: it reads the
 * Bluetooth singleton directly, the module only anchors it and binds `show`.
 */
DialogWindow {
    id: dlg

    property string filter: ""

    title: "Bluetooth"
    subtitle: {
        var a = Bluetooth.defaultAdapter;
        if (!a) return "No adapter found";
        if (!a.enabled) return "Adapter off";
        return "On";
    }
    dialogWidth: 360

    property var adapter: Bluetooth.defaultAdapter

    // Connected first, then paired, then the rest; filtered by the search box.
    property var shownDevices: {
        var src = dlg.adapter ? dlg.adapter.devices.values : [];
        var out = [];
        var f = dlg.filter.trim().toLowerCase();
        for (var i = 0; i < src.length; i++) {
            var d = src[i];
            var nm = ((d.name || d.deviceName || "") + "").toLowerCase();
            if (f !== "" && nm.indexOf(f) < 0) continue;
            out.push(d);
        }
        out.sort(function(a, b) {
            var score = function(x) { return x.connected ? 0 : (x.paired || x.bonded ? 1 : 2); };
            return score(a) - score(b);
        });
        return out;
    }

    // ── Power + scan ──────────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 10

        Column {
            width: parent.width - 106
            spacing: 2

            Text {
                text: "Adapter"
                color: Theme.base07
                font.family: Theme.fontUi
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Text {
                width: parent.width
                text: {
                    var a = dlg.adapter;
                    if (!a) return "BlueZ not available";
                    if (!a.enabled) return "Off — toggle to enable";
                    var n = dlg.shownDevices.length;
                    if (a.discovering) return "Scanning…";
                    return n === 0 ? "On — no devices nearby" : "On — " + n + " device" + (n === 1 ? "" : "s");
                }
                color: Theme.base05
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        ToggleSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: dlg.adapter ? dlg.adapter.enabled : false
            disabled: !dlg.adapter
            onToggled: function(on) {
                if (dlg.adapter) dlg.adapter.enabled = on;
            }
        }

        Rectangle {
            id: scanBtn
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 22
            radius: 7
            color: scanMouse.containsMouse ? Theme.base02 : Theme.base03
            visible: dlg.adapter && dlg.adapter.enabled
            opacity: visible ? 1 : 0

            Text {
                anchors.centerIn: parent
                text: dlg.adapter && dlg.adapter.discovering ? "Stop" : "Scan"
                color: Theme.base07
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (dlg.adapter) dlg.adapter.discovering = !dlg.adapter.discovering;
                }
            }
        }
    }

    // ── Search ────────────────────────────────────────────────────
    Rectangle {
        width: parent.width
        height: 28
        radius: 8
        color: Theme.base02
        border.color: Theme.base03
        border.width: 1
        visible: dlg.adapter && dlg.adapter.enabled

        TextInput {
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.base06
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: Font.DemiBold
            clip: true
            onTextChanged: dlg.filter = text
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Search devices…"
            color: Theme.base04
            font.family: Theme.fontUi
            font.pixelSize: 12
            visible: searchInput.text === ""
        }
    }

    // ── Device list ───────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 6
        visible: dlg.adapter && dlg.adapter.enabled

        Text {
            width: parent.width
            text: dlg.shownDevices.length === 0 ? "No devices found — try Scan." : ""
            visible: text !== ""
            color: Theme.base04
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Repeater {
            model: dlg.shownDevices
            delegate: Rectangle {
                required property var modelData
                property var device: modelData

                width: parent.width
                height: 52
                radius: 10
                color: device.connected ? Theme.base02 : "transparent"
                border.color: device.connected ? Theme.base03 : "transparent"
                border.width: 1

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // Status dot
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: device.connected ? Theme.base07 : (device.paired || device.bonded ? Theme.base05 : Theme.base03)
                    }

                    Column {
                        width: parent.width - 8 - 8 - 118
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            text: (device.name || device.deviceName || "Unknown device") + (device.batteryAvailable ? " · " + Math.round(device.battery) + "%" : "")
                            color: Theme.base06
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: device.connected ? "Connected"
                                : device.pairing ? "Pairing…"
                                : (device.paired || device.bonded) ? "Paired" : "Nearby"
                            color: Theme.base05
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }

                    // Connect / Disconnect
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 62
                        height: 24
                        radius: 7
                        color: connMouse.containsMouse ? Theme.base03 : Theme.base02
                        border.color: Theme.base03
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: device.connected ? "Disconnect" : "Connect"
                            color: Theme.base07
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: connMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (device.connected) device.disconnect();
                                else device.connect();
                            }
                        }
                    }

                    // Pair / Forget
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 48
                        height: 24
                        radius: 7
                        color: pairMouse.containsMouse ? Theme.base03 : "transparent"
                        border.color: Theme.base03
                        border.width: 1
                        visible: !device.connected

                        Text {
                            anchors.centerIn: parent
                            text: device.pairing ? "Cancel" : ((device.paired || device.bonded) ? "Forget" : "Pair")
                            color: Theme.base06
                            font.family: Theme.fontUi
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: pairMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (device.pairing) device.cancelPair();
                                else if (device.paired || device.bonded) device.forget();
                                else device.pair();
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        width: parent.width
        text: dlg.adapter ? "Right-click the pill for system settings." : "Start bluetooth.service to use Bluetooth."
        color: Theme.base04
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }
}
