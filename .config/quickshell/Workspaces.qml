import QtQuick
import Quickshell.Hyprland

/*
 * Port of the hyprland/workspaces module: a single pill holding slots 1-5
 * always, plus 6-10 only while Hyprland actually has a workspace in that
 * slot. Click a glyph to activate it (empty slots focus that number so the
 * workspace is created), scroll anywhere on the pill to move e+1 / e-1.
 */
Rectangle {
    id: root

    // Computed in a binding so the row grows when a high-numbered workspace
    // is created and shrinks again when it disappears.
    property var slots: {
        var ids = [1, 2, 3, 4, 5];
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id > 5 && ids.indexOf(list[i].id) < 0) ids.push(list[i].id);
        }
        ids.sort(function(a, b) { return a - b; });
        return ids;
    }

    function workspace(id) {
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) return list[i];
        }
        return null;
    }

    function glyph(id) {
        var glyphs = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"];
        return glyphs[id - 1] || "" + id;
    }

    // Hyprland 0.55+ with a Lua config evaluates IPC dispatch strings as Lua,
    // so the old "workspace 3" form is a syntax error there. Quickshell
    // exposes Hyprland.usingLua for exactly this branch.
    function focusWorkspace(target) {
        if (Hyprland.usingLua) {
            var arg = /^\d+$/.test(target) ? target : "\"" + target + "\"";
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + arg + " })");
        } else {
            Hyprland.dispatch("workspace " + target);
        }
    }

    function scroll(delta) {
        focusWorkspace(delta > 0 ? "e+1" : "e-1");
    }

    implicitWidth: row.implicitWidth + 20
    implicitHeight: Theme.panelHeight
    radius: Theme.pillRadius
    color: Theme.base01

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: root.slots
            delegate: Text {
                required property int modelData

                property int wsId: modelData
                property var ws: root.workspace(wsId)
                property bool isActive: ws !== null && (ws.active || ws.focused)

                text: root.glyph(wsId)
                color: isActive ? Theme.base07 : (ws ? Theme.base06 : Theme.base04)
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.weight: isActive ? Font.Bold : Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (ws) ws.activate();
                        else root.focusWorkspace("" + wsId);
                    }
                }
            }
        }
    }

    WheelHandler {
        onWheel: function(event) {
            root.scroll(event.angleDelta.y);
        }
    }
}
