import QtQuick
import Quickshell
import Quickshell.Bluetooth

/* Port of waybar's bluetooth module. Left click opens the device dialog,
 * middle click toggles the adapter, right click opens system settings. */
Pill {
    id: root

    property var adapter: Bluetooth.defaultAdapter
    property bool dialogOpen: false

    function connectedList() {
        var result = [];
        if (!Bluetooth.devices) return result;
        var devices = Bluetooth.devices.values;
        for (var i = 0; i < devices.length; i++) {
            if (devices[i].connected) result.push(devices[i]);
        }
        return result;
    }

    label: {
        if (!root.adapter || !root.adapter.enabled) return "󰂲";
        var devices = root.connectedList();
        if (devices.length === 1) return "󰂰 " + (devices[0].name || devices[0].deviceName || "");
        if (devices.length > 1) return "󰂰 " + devices.length;
        return "󰂰";
    }

    tooltip: {
        if (!root.adapter) return "No Bluetooth adapter";
        if (!root.adapter.enabled) return "Bluetooth off — middle-click to enable";
        var devices = root.connectedList();
        if (devices.length === 0) return "No connected device — click for devices";
        var lines = [];
        for (var i = 0; i < devices.length; i++) lines.push(devices[i].name || devices[i].deviceName);
        return lines.join("\n");
    }

    emphasized: root.dialogOpen

    onClicked: function(event) {
        if (event.button === Qt.RightButton) {
            Quickshell.execDetached(["gnome-control-center", "bluetooth"]);
        } else if (event.button === Qt.MiddleButton) {
            if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
        } else {
            root.dialogOpen = !root.dialogOpen;
        }
    }

    BluetoothDialog {
        anchorItem: root
        show: root.dialogOpen
        onDismissed: root.dialogOpen = false
    }
}
