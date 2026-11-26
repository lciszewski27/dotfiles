import QtQuick
import Quickshell
import Quickshell.Networking

/*
 * Port of waybar's network module. Left click opens the network dialog,
 * right click opens GNOME Wi-Fi settings, middle click opens nmtui.
 */
Pill {
    id: root

    property bool dialogOpen: false
    property var activeDevice: {
        var devices = Networking.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) return devices[i];
        }
        return null;
    }

    // Keep the speed sampler pinned to the active interface.
    onActiveDeviceChanged: NetSpeed.iface = root.activeDevice ? root.activeDevice.name : ""
    Component.onCompleted: NetSpeed.iface = root.activeDevice ? root.activeDevice.name : ""

    label: {
        if (!root.activeDevice) return "";
        if (root.activeDevice.type === DeviceType.Wifi) return "";
        return "";
    }

    stateClass: root.activeDevice ? "" : "active"

    tooltip: {
        var base;
        if (!root.activeDevice) {
            if (!Networking.wifiHardwareEnabled) base = "No Wi-Fi hardware";
            else if (!Networking.wifiEnabled) base = "Wi-Fi off — click for networks";
            else base = "Disconnected — click for networks";
        } else {
            var net = root.activeDevice.network;
            var name = net ? net.name : root.activeDevice.name;
            var addr = root.activeDevice.address || "";
            base = addr !== "" ? (name || "network") + "\n" + addr : (name || "network");
        }
        return base + "\n↓ " + NetSpeed.downText + "  ↑ " + NetSpeed.upText;
    }

    emphasized: root.dialogOpen

    onClicked: function(event) {
        if (event.button === Qt.RightButton) {
            Quickshell.execDetached(["gnome-control-center", "wifi"]);
        } else if (event.button === Qt.MiddleButton) {
            Quickshell.execDetached(["ghostty", "-e", "nmtui"]);
        } else {
            root.dialogOpen = !root.dialogOpen;
        }
    }

    NetworkDialog {
        anchorItem: root
        show: root.dialogOpen
        onDismissed: root.dialogOpen = false
    }
}
