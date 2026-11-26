pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * NetSpeed.qml
 *
 * Live up/down rates for one interface, sampled from /proc/net/dev every
 * second. NetworkModule points `iface` at the connected device; the tooltip
 * reads `downText`/`upText`.
 */
Singleton {
    id: root

    property string iface: ""
    property real downBps: 0
    property real upBps: 0

    readonly property string downText: root.fmt(root.downBps) + "/s"
    readonly property string upText: root.fmt(root.upBps) + "/s"

    property var _prev: null

    function fmt(bps) {
        if (bps < 1024) return Math.round(bps) + " B";
        if (bps < 1048576) return (bps / 1024).toFixed(1) + " KB";
        if (bps < 1073741824) return (bps / 1048576).toFixed(2) + " MB";
        return (bps / 1073741824).toFixed(2) + " GB";
    }

    function parse(text) {
        var lines = text.split("\n");
        var best = { iface: "", rx: 0, tx: 0 };
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^\s*([^:]+):\s*(.*)$/);
            if (!m) continue;
            var name = m[1].trim();
            if (name === "lo") continue;
            var f = m[2].trim().split(/\s+/);
            if (f.length < 10) continue;
            if (root.iface !== "" && name !== root.iface) continue;
            var rx = parseInt(f[0], 10) || 0;
            var tx = parseInt(f[8], 10) || 0;
            if (root.iface !== "") {
                best = { iface: name, rx: rx, tx: tx };
                break;
            }
            // No pinned interface: follow whoever carries the most traffic.
            if (best.iface === "" || rx > best.rx) {
                best = { iface: name, rx: rx, tx: tx };
            }
        }
        return best;
    }

    Process {
        id: reader
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                var cur = root.parse(text);
                if (root._prev && cur.iface !== "" && cur.iface === root._prev.iface) {
                    var dt = poller.interval / 1000;
                    root.downBps = Math.max(0, (cur.rx - root._prev.rx) / dt);
                    root.upBps = Math.max(0, (cur.tx - root._prev.tx) / dt);
                } else {
                    root.downBps = 0;
                    root.upBps = 0;
                }
                root._prev = cur;
            }
        }
    }

    Timer {
        id: poller
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }
}
