import QtQuick
import Quickshell

/*
 * Waybar's clock: hover swaps the time for the waybar format-alt date
 * ("%Y年%m月%d日 %H:%M"), left click opens an interactive month calendar,
 * right/middle click opens the date & time settings.
 */
Pill {
    id: root

    property bool calendarOpen: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    label: root.mouseArea.containsMouse
        ? Qt.formatDateTime(clock.date, "yyyy年MM月dd日 HH:mm")
        : Qt.formatDateTime(clock.date, "HH:mm")
    tooltip: ""
    emphasized: root.calendarOpen

    CalendarDialog {
        id: calendar
        anchorItem: root
        show: root.calendarOpen
        onDismissed: root.calendarOpen = false
    }

    onClicked: function(event) {
        if (event.button === Qt.RightButton || event.button === Qt.MiddleButton) {
            Quickshell.execDetached(["gnome-control-center", "datetime"]);
        } else {
            root.calendarOpen = !root.calendarOpen;
        }
    }
}
