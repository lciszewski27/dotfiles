import QtQuick
import Quickshell
import Quickshell.Networking

/*
 * Network popover: Wi-Fi toggle, connection status and the Wi-Fi network list
 * with connect/disconnect/forget plus PSK handling. Self-sufficient: it reads
 * the Networking singleton directly, the module only anchors it and binds
 * `show`.
 */
DialogWindow {
    id: dlg

    title: "Network"
    subtitle: {
        if (!Networking.wifiHardwareEnabled && !dlg.wiredDevice) return "No network hardware";
        var c = Networking.connectivity;
        var label = c === NetworkConnectivity.Full ? "Connected"
            : c === NetworkConnectivity.Limited ? "Limited connectivity"
            : c === NetworkConnectivity.Portal ? "Captive portal"
            : c === NetworkConnectivity.None ? "No connectivity" : "Connecting…";
        if (dlg.activeName !== "") return label + " · " + dlg.activeName;
        return label;
    }
    dialogWidth: 380

    property var wifiDevice: findWifi()
    property var wiredDevice: findWired()
    property string activeName: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected && devs[i].network) return devs[i].network.name || devs[i].name;
        }
        return "";
    }
    property var wifiNetworks: {
        if (!dlg.wifiDevice) return [];
        var nets = dlg.wifiDevice.networks.values.slice();
        nets.sort(function(a, b) { return b.signalStrength - a.signalStrength; });
        return nets;
    }
    property var pendingNetwork: null
    property string psk: ""
    property string errorText: ""

    function findWifi() {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    function findWired() {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired) return devs[i];
        }
        return null;
    }

    function needsPsk(net) {
        if (!net || net.connected || net.known) return false;
        var s = net.security;
        return !(s === WifiSecurityType.Open || s === WifiSecurityType.Unknown || s === WifiSecurityType.Owe);
    }

    function join(net) {
        dlg.errorText = "";
        if (!net) return;
        if (net.connected) {
            net.disconnect();
            return;
        }
        if (needsPsk(net)) {
            dlg.pendingNetwork = net;
            dlg.psk = "";
            return;
        }
        net.connect();
    }

    function submitPsk() {
        if (dlg.pendingNetwork) {
            dlg.pendingNetwork.connectWithPsk(dlg.psk);
            dlg.pendingNetwork = null;
            dlg.psk = "";
        }
    }

    onShowChanged: {
        dlg.errorText = "";
        dlg.pendingNetwork = null;
        dlg.psk = "";
        if (dlg.show && dlg.wifiDevice) dlg.wifiDevice.scannerEnabled = true;
    }

    // ── Wi-Fi toggle ──────────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 10

        Column {
            width: parent.width - 50
            spacing: 2

            Text {
                text: "Wi-Fi"
                color: Theme.base07
                font.family: Theme.fontUi
                font.pixelSize: 13
                font.weight: Font.Bold
            }

            Text {
                width: parent.width
                text: !Networking.wifiHardwareEnabled ? "Hardware disabled / no adapter"
                    : !Networking.wifiEnabled ? "Off"
                    : dlg.wifiDevice ? ("On · " + dlg.wifiNetworks.length + " networks") : "On"
                color: Theme.base05
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        ToggleSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            disabled: !Networking.wifiHardwareEnabled
            onToggled: function(on) { Networking.wifiEnabled = on; }
        }
    }

    // ── Wired ─────────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 6
        visible: !!dlg.wiredDevice

        Text {
            text: "Wired"
            color: Theme.base05
            font.family: Theme.fontUi
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: 10
            color: dlg.wiredDevice && dlg.wiredDevice.connected ? Theme.base02 : "transparent"
            border.color: Theme.base03
            border.width: dlg.wiredDevice && dlg.wiredDevice.connected ? 1 : 0

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: Theme.base06
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                }

                Column {
                    width: parent.width - 30 - 70
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: dlg.wiredDevice ? (dlg.wiredDevice.network ? dlg.wiredDevice.network.name : dlg.wiredDevice.name) : ""
                        color: Theme.base06
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: dlg.wiredDevice ? (dlg.wiredDevice.connected ? (dlg.wiredDevice.address || "Connected") : "Disconnected") : ""
                        color: Theme.base05
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 62
                    height: 24
                    radius: 7
                    color: discMouse.containsMouse ? Theme.base03 : Theme.base02
                    border.color: Theme.base03
                    border.width: 1
                    visible: dlg.wiredDevice && dlg.wiredDevice.connected

                    Text {
                        anchors.centerIn: parent
                        text: "Disconnect"
                        color: Theme.base07
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: discMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (dlg.wiredDevice) dlg.wiredDevice.disconnect()
                    }
                }
            }
        }
    }

    // ── Wi-Fi networks ────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: 6
        visible: Networking.wifiHardwareEnabled && Networking.wifiEnabled && !!dlg.wifiDevice

        Text {
            text: "Networks"
            color: Theme.base05
            font.family: Theme.fontUi
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        Text {
            width: parent.width
            text: dlg.wifiNetworks.length === 0 ? "Scanning…" : ""
            visible: text !== ""
            color: Theme.base04
            font.family: Theme.fontUi
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Repeater {
            model: dlg.wifiNetworks
            delegate: Rectangle {
                required property var modelData
                property var net: modelData
                property bool expanded: dlg.pendingNetwork === net

                width: parent.width
                height: expanded ? 96 : 52
                radius: 10
                color: net.connected ? Theme.base02 : (expanded ? Theme.base02 : "transparent")
                border.color: net.connected || expanded ? Theme.base03 : "transparent"
                border.width: 1

                Behavior on height { NumberAnimation { duration: 140 } }

                // Surface connection errors on the failing row.
                Connections {
                    target: net
                    function onConnectionFailed(reason) {
                        dlg.errorText = "Could not connect to " + net.name;
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            text: {
                                var s = net.signalStrength;
                                if (net.connected) return "";
                                if (s >= 0.75) return "▂▄▆";
                                if (s >= 0.5) return "▂▄";
                                if (s > 0.05) return "▂";
                                return "·";
                            }
                            color: net.connected ? Theme.base07 : Theme.base05
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Column {
                            width: parent.width - 26 - 8 - 118
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: net.name || "Hidden network"
                                color: Theme.base06
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: net.connected ? "Connected" + (net.stateChanging ? "…" : "")
                                    : net.stateChanging ? "Connecting…"
                                    : (net.known ? WifiSecurityType.toString(net.security) + " · known" : WifiSecurityType.toString(net.security))
                                color: Theme.base05
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            height: 24
                            radius: 7
                            color: joinMouse.containsMouse ? Theme.base03 : Theme.base02
                            border.color: Theme.base03
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: net.connected ? "Disconnect" : "Connect"
                                color: Theme.base07
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: joinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dlg.join(net)
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 24
                            radius: 7
                            color: forgetMouse.containsMouse ? Theme.base03 : "transparent"
                            border.color: Theme.base03
                            border.width: 1
                            visible: net.known && !net.connected

                            Text {
                                anchors.centerIn: parent
                                text: "Forget"
                                color: Theme.base06
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: forgetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: net.forget()
                            }
                        }
                    }

                    // Password entry for secured unknown networks.
                    Row {
                        width: parent.width
                        spacing: 6
                        visible: expanded

                        Rectangle {
                            width: parent.width - 70
                            height: 30
                            radius: 8
                            color: Theme.base01
                            border.color: Theme.base03
                            border.width: 1

                            TextInput {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.base06
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                echoMode: TextInput.Password
                                focus: expanded
                                onTextChanged: dlg.psk = text
                                onAccepted: dlg.submitPsk()
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password…"
                                color: Theme.base04
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                visible: dlg.psk === ""
                            }
                        }

                        Rectangle {
                            width: 32
                            height: 30
                            radius: 8
                            color: Theme.base07

                            Text {
                                anchors.centerIn: parent
                                text: "→"
                                color: Theme.base01
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dlg.submitPsk()
                            }
                        }

                        Rectangle {
                            width: 26
                            height: 30
                            radius: 8
                            color: "transparent"
                            border.color: Theme.base03
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.base05
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    dlg.pendingNetwork = null;
                                    dlg.psk = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        width: parent.width
        text: dlg.errorText
        visible: dlg.errorText !== ""
        color: Theme.m3Error
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }

    Text {
        width: parent.width
        text: "Right-click the pill for system settings · middle-click opens nmtui."
        color: Theme.base04
        font.family: Theme.fontUi
        font.pixelSize: 11
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }
}
