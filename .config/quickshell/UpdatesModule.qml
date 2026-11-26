import QtQuick
import Quickshell
import Quickshell.Io
import "Ui.js" as Ui

/*
 * Port of modules/updates/updates.go: checkupdates + yay -Qum +
 * flatpak remote-ls --updates, cached for five minutes, with the same
 * tables, alt summary and none/few/some/many classes.
 */
Pill {
    id: root

    property int ttlMs: 300000
    property int fetchedAt: 0
    property bool fetching: false
    property int pending: 0

    property var pacmanPkgs: []
    property var aurPkgs: []
    property var flatpakPkgs: []
    property bool p0done: false
    property bool p1done: false
    property bool p2done: false

    property var groups: buildGroups()
    property int total: count(groups)

    label: root.total === 0 ? "" : "󰅢  " + root.total
    tooltip: buildTooltip(groups)
    stateClass: severity(total)
    keepVisible: false

    function buildGroups() {
        var result = [];
        if (pacmanPkgs.length > 0) result.push({ title: "󰮯 Pacman", packages: pacmanPkgs });
        if (aurPkgs.length > 0) result.push({ title: "󰣇 AUR", packages: aurPkgs });
        if (flatpakPkgs.length > 0) result.push({ title: "󰏖 Flatpak", packages: flatpakPkgs });
        return result;
    }

    function count(list) {
        var n = 0;
        for (var i = 0; i < list.length; i++) n += list[i].packages.length;
        return n;
    }

    function buildTooltip(list) {
        if (list.length === 0) return "Up to date";
        var parts = [];
        for (var i = 0; i < list.length; i++) {
            parts.push(Ui.drawTable(list[i].title, list[i].packages));
        }
        return parts.join("\n");
    }

    function severity(n) {
        if (n === 0) return "none";
        if (n < 5) return "few";
        if (n < 15) return "some";
        return "many";
    }

    function collect(index, text) {
        if (index === 0) {
            if (p0done) return;
            p0done = true;
            pacmanPkgs = Ui.packageLines(text);
        } else if (index === 1) {
            if (p1done) return;
            p1done = true;
            aurPkgs = Ui.packageLines(text);
        } else {
            if (p2done) return;
            p2done = true;
            flatpakPkgs = Ui.packageLines(text);
        }
        pending--;
        if (pending === 0) {
            fetching = false;
            fetchedAt = new Date().getTime();
        }
    }

    function refresh() {
        if (fetching) return;
        fetching = true;
        pending = 3;
        p0done = false;
        p1done = false;
        p2done = false;
        pacmanProcess.running = true;
        aurProcess.running = true;
        flatpakProcess.running = true;
    }

    Process {
        id: pacmanProcess
        command: ["checkupdates"]
        stdout: StdioCollector { onStreamFinished: root.collect(0, this.text) }
    }

    Process {
        id: aurProcess
        command: ["yay", "-Qum"]
        stdout: StdioCollector { onStreamFinished: root.collect(1, this.text) }
    }

    Process {
        id: flatpakProcess
        command: ["flatpak", "remote-ls", "--updates"]
        stdout: StdioCollector { onStreamFinished: root.collect(2, this.text) }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (new Date().getTime() - root.fetchedAt > root.ttlMs) root.refresh();
        }
    }

    onClicked: Quickshell.execDetached(["ghostty", "-e", "sh", "-c",
        "yay -Syu; flatpak update -y; echo Done - press Enter to close; read"])
}
