import QtQuick
import Quickshell

/*
 * DialogWindow.qml
 *
 * Shared shell for the Bluetooth and Network popovers: a Matugen card anchored
 * under the clicked module, with a header (title + subtitle + close button)
 * and a scrollable content area.
 *
 * Usage:
 *   DialogWindow {
 *       anchorItem: someModule
 *       show: dialogOpen
 *       title: "Bluetooth"
 *       subtitle: "..."
 *       DialogColumn { ... }   // children go into the scrollable column
 *   }
 *
 * Children land in the scrollable `innerColumn`: give them
 * `width: parent.width`.
 */
PopupWindow {
    id: root

    required property Item anchorItem
    property bool show: false
    property string title: ""
    property string subtitle: ""
    property int dialogWidth: 340
    property int contentMaxHeight: 360
    property int padding: 14
    property int spacing: 10

    default property alias content: innerColumn.data

    anchor {
        window: anchorItem.QsWindow.window
        // Slide horizontally only: a top-bar dialog must never flip above the
        // screen edge.
        adjustment: PopupAdjustment.SlideX
        gravity: Edges.Bottom | Edges.Right

        onAnchoring: {
            var pos = anchorItem.QsWindow.contentItem.mapFromItem(
                anchorItem,
                anchorItem.width - root.implicitWidth,
                anchorItem.height + 6
            );
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
    visible: root.anim > 0.01
    grabFocus: root.show

    // Never assign to `show` here: it is bound by the owner
    // (e.g. `show: root.calendarOpen`), and an assignment would destroy that
    // binding so the dialog could never reopen. Emit `dismissed` and let the
    // owner clear its own flag instead.
    signal dismissed()
    onClosed: if (root.show) root.dismissed()

    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

    onShowChanged: root.anim = root.show ? 1 : 0

    Rectangle {
        id: card
        width: root.dialogWidth
        color: Theme.base01
        border.color: Theme.base03
        border.width: 1
        radius: 14
        opacity: root.anim
        scale: 0.96 + root.anim * 0.04
        transformOrigin: Item.Top

        implicitWidth: root.dialogWidth
        implicitHeight: layout.implicitHeight + root.padding * 2

        Column {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.padding
            spacing: root.spacing

            // ── Header ────────────────────────────────────────────
            Item {
                id: header
                width: parent.width
                height: Math.max(titleColumn.implicitHeight, 24)

                Column {
                    id: titleColumn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 32
                    spacing: 1

                    Text {
                        text: root.title
                        color: Theme.base07
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        width: parent.width
                        text: root.subtitle
                        visible: root.subtitle !== ""
                        color: Theme.base05
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 7
                    color: closeMouse.containsMouse ? Theme.base02 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.base06
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.base03
            }

            // ── Scrollable content ────────────────────────────────
            Flickable {
                id: scroller
                width: parent.width
                height: Math.min(innerColumn.implicitHeight, root.contentMaxHeight)
                contentWidth: width
                contentHeight: innerColumn.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: innerColumn
                    width: scroller.width
                    spacing: root.spacing
                }
            }
        }
    }
}
