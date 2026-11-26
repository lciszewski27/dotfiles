import QtQuick
import Quickshell
import "Ui.js" as Ui

/*
 * Port of modules/countdown/countdown.go, configured exactly like waybar's
 * custom/countdown: target 2027-05-04 09:00, label Matura, format {total-d}d.
 */
Pill {
    id: root

    property string targetText: "2027-05-04 09:00"
    property string targetLabel: "Matura"
    property string formatString: "{total-d}d"
    property var target: null
    property var span: Ui.splitDuration(0)

    label: "󱆀  " + Ui.applyFormat(Ui.resolveFormat(root.formatString), root.span)
    tooltip: root.target
        ? Ui.countdownTooltip(root.span, root.target, root.targetLabel)
        : "Countdown: invalid target"
    // Same default pill styling as the other modules; only an overdue
    // target keeps the red error state.
    stateClass: root.span.negative ? "overdue" : ""

    function recompute() {
        var now = new Date();
        var parsed = Ui.parseTarget(root.targetText, now);
        if (!parsed) {
            root.target = null;
            root.span = Ui.splitDuration(0);
            return;
        }
        root.target = parsed;
        root.span = Ui.splitDuration((parsed.getTime() - now.getTime()) / 1000);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.recompute()
    }

    onClicked: root.recompute()
}
