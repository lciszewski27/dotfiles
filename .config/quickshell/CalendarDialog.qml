import QtQuick
import QtQuick.Controls.Basic as Controls
import Quickshell

/*
 * Interactive month calendar, based on the pattern used by several community
 * Quickshell shells: a PopupWindow anchored under the clock, Qt's MonthGrid +
 * DayOfWeekRow for locale-correct weeks, and Matugen colours for the cells.
 */
PopupWindow {
    id: root

    required property Item anchorItem
    property bool show: false
    property var selectedDate: new Date()

    anchor {
        window: anchorItem.QsWindow.window
        adjustment: PopupAdjustment.SlideX
        gravity: Edges.Bottom | Edges.Right

        onAnchoring: {
            var pos = anchorItem.QsWindow.contentItem.mapFromItem(
                anchorItem,
                anchorItem.width / 2 - root.width / 2,
                anchorItem.height + 6
            );
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    color: "transparent"
    implicitWidth: 330
    implicitHeight: card.implicitHeight
    visible: root.anim > 0.01
    grabFocus: root.show

    // Never assign to `show` here: it is bound by the owner
    // (`show: root.calendarOpen`), and an assignment would destroy that
    // binding so the calendar could never reopen. Emit `dismissed` and let
    // the owner clear its own flag instead.
    signal dismissed()
    onClosed: if (root.show) root.dismissed()

    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

    onShowChanged: {
        if (root.show) {
            root.selectedDate = new Date();
            root.anim = 1;
        } else {
            root.anim = 0;
        }
    }

    Rectangle {
        id: card
        width: root.width
        color: Theme.base01
        border.color: Theme.base03
        border.width: 1
        radius: 14
        opacity: root.anim
        scale: 0.95 + root.anim * 0.05
        transformOrigin: Item.Top

        implicitWidth: 330
        implicitHeight: content.implicitHeight + 20

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // ── Header ────────────────────────────────────────────────────
            Row {
                width: parent.width
                height: 24
                spacing: 4

                Text {
                    id: prev
                    text: "‹"
                    color: Theme.base06
                    font.family: Theme.fontUi
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    width: 24
                    horizontalAlignment: Text.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(-1)
                    }
                }

                Text {
                    width: parent.width - prev.width - next.width - todayButton.width - 12
                    height: parent.height
                    text: Qt.formatDateTime(root.selectedDate, "MMMM yyyy")
                    color: Theme.base07
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: todayButton
                    text: "Today"
                    color: Theme.base06
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    width: 42
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedDate = new Date()
                    }
                }

                Text {
                    id: next
                    text: "›"
                    color: Theme.base06
                    font.family: Theme.fontUi
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    width: 24
                    horizontalAlignment: Text.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shiftMonth(1)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.base03
            }

            Controls.DayOfWeekRow {
                id: weekRow
                width: parent.width
                locale: Qt.locale()
                spacing: 3

                delegate: Text {
                    required property var model
                    width: Math.max(36, (weekRow.width - weekRow.spacing * 6) / 7)
                    text: model.shortName
                    color: Theme.base05
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Controls.MonthGrid {
                id: monthGrid
                width: parent.width
                height: 210
                // Qt's MonthGrid uses 0-based months (the QML warning about
                // "month 12 is out of range [0...11]" came from passing 1..12).
                month: root.selectedDate.getMonth()
                year: root.selectedDate.getFullYear()
                locale: Qt.locale()
                spacing: 3

                delegate: Rectangle {
                    id: cell
                    required property var model
                    property bool selected: model.date.getFullYear() === root.selectedDate.getFullYear() &&
                        model.date.getMonth() === root.selectedDate.getMonth() &&
                        model.date.getDate() === root.selectedDate.getDate()

                    width: Math.max(36, (monthGrid.width - monthGrid.spacing * 6) / 7)
                    height: 30
                    radius: 8
                    color: selected ? Theme.base02 : "transparent"
                    border.width: model.today && !selected ? 1 : 0
                    border.color: Theme.base07
                    opacity: model.month === monthGrid.month ? 1 : 0.35

                    Text {
                        anchors.centerIn: parent
                        text: cell.model.day
                        color: cell.selected || cell.model.today ? Theme.base07 : Theme.base06
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        font.weight: cell.model.today || cell.selected ? Font.Bold : Font.DemiBold
                    }
                }

                onClicked: function(date) {
                    root.selectedDate = date;
                }
            }

            Text {
                width: parent.width
                text: Qt.formatDateTime(root.selectedDate, "dddd, d MMMM yyyy")
                color: Theme.base05
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    function shiftMonth(delta) {
        var d = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth() + delta, 1);
        root.selectedDate = d;
    }
}
