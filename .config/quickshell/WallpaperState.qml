pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

/*
 * WallpaperState.qml
 *
 * Wallpaper handling, done entirely by Quickshell (no awww): keeps the file
 * list for ~/Pictures/Wallpapers, publishes `current` for the background
 * layer, persists it to wallpaper.conf, and re-runs matugen with the same
 * flags as ~/.local/bin/theme-chnage.sh for the active GNOME color scheme,
 * followed by a config-only Hyprland reload for the new accent colour.
 */
Singleton {
    id: root

    property bool open: false
    property string current: ""
    property var wallpapers: []
    property bool applying: false

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string confFile: Quickshell.env("HOME") + "/.config/quickshell/wallpaper.conf"

    function toggle() {
        root.open = !root.open;
        if (root.open) root.refresh();
    }

    function refresh() {
        lister.running = true;
    }

    function fullPath(name) {
        return root.dir + "/" + name;
    }

    function isCurrent(name) {
        return root.current !== "" && root.fullPath(name) === root.current;
    }

    function apply(path) {
        if (path === "" || root.applying) return;
        root.applying = true;
        root.current = path;
        saver.command = ["sh", "-c", "printf '%s' '" + path.replace(/'/g, "'\\''") + "' > '" + root.confFile + "'"];
        saver.running = true;
        schemeProbe.running = true;
    }

    function applyName(name) {
        root.apply(root.fullPath(name));
    }

    function restore() {
        loader.running = true;
    }

    Process {
        id: lister
        command: ["ls", "-1", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = [];
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].trim();
                    if (f !== "" && f.match(/\.(png|jpe?g|webp|gif|bmp)$/i)) out.push(f);
                }
                out.sort();
                root.wallpapers = out;
            }
        }
    }

    Process {
        id: loader
        command: ["cat", root.confFile]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim();
                if (p !== "") root.current = p;
            }
        }
    }

    Process {
        id: saver
    }

    // Same matugen invocation as theme-chnage.sh, following the active
    // GNOME color scheme (wallpaper change only — the scheme itself is
    // never flipped here).
    Process {
        id: schemeProbe
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        stdout: StdioCollector {
            onStreamFinished: {
                var dark = text.indexOf("dark") >= 0;
                var mode = dark ? "dark" : "light";
                var prefer = dark ? "value" : "darkness";
                matugen.command = ["matugen", "image", root.current,
                    "-m", mode, "--type", "scheme-vibrant", "--prefer", prefer];
                matugen.running = true;
            }
        }
    }

    Process {
        id: matugen
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: {
            root.applying = false;
            Quickshell.execDetached(["hyprctl", "reload", "config-only"]);
        }
    }
}
