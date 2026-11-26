import QtQuick
import Quickshell

/*
 * Tooltip rendered in its own PopupWindow. Following Quickshell's own
 * src/ui/Tooltip.qml, but with a wrapped text layout so the Go modules'
 * multi-line tables (weather, countdown, updates) display correctly.
 *
 * A PopupWindow is required because a Controls ToolTip inside the 28px panel
 * would be clipped by the panel surface.
 *
 * Width note: Qt's TextMetrics.boundingRect treats "\n" as part of a single
 * line, so measuring tipText directly returns roughly the SUM of all line
 * widths (that's how we got 640px-wide tooltips). Instead we measure with a
 * hidden NoWrap Text, whose implicitWidth is the widest line, and cap it at
 * maxTextWidth. Mono (box-drawing) tooltips never wrap so the tables keep
 * their alignment; normal tooltips wrap at maxTextWidth.
 */
PopupWindow {
    id: popup

    required property Item anchorItem
    required property string tipText
    property bool show: false
    property bool mono: false
    property int delayMs: 200
    property int hangMs: 100
    property int maxTextWidth: 380
    property int padding: 10

    anchor {
        window: anchorItem.QsWindow.window
        // Slide horizontally only: a top-bar tooltip must never flip above
        // the screen edge.
        adjustment: PopupAdjustment.SlideX
        gravity: Edges.Bottom | Edges.Right

        onAnchoring: {
            var pos = anchorItem.QsWindow.contentItem.mapFromItem(
                anchorItem,
                Math.round((anchorItem.width - popup.width) / 2),
                anchorItem.height + 6
            );
            anchor.rect.x = pos.x;
            anchor.rect.y = pos.y;
        }
    }

    color: "transparent"
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    visible: popup.reveal > 0.01

    property bool shown: false
    property real reveal: 0

    onShowChanged: {
        if (popup.show) {
            hideTimer.stop();
            showTimer.restart();
        } else {
            showTimer.stop();
            hideTimer.restart();
        }
    }

    onShownChanged: popup.reveal = popup.shown ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: popup.shown ? 140 : 110
            easing.type: popup.shown ? Easing.OutCubic : Easing.InCubic
        }
    }

    Timer {
        id: showTimer
        interval: popup.delayMs
        onTriggered: if (popup.show) popup.shown = true
    }

    Timer {
        id: hideTimer
        interval: popup.hangMs
        onTriggered: popup.shown = false
    }

    readonly property string textFamily: popup.mono ? Theme.fontMono : Theme.fontUi

    // Hidden natural-size clone: NoWrap Text reports the widest line as
    // implicitWidth and the full block height as implicitHeight.
    Text {
        id: natural
        visible: false
        text: popup.tipText
        font.family: popup.textFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        wrapMode: Text.NoWrap
    }

    readonly property real boxWidth: Math.min(
        Math.max(natural.implicitWidth + popup.padding * 2 + 2, 44),
        popup.maxTextWidth + popup.padding * 2)

    // Only capped text wraps. Short text stays on one line so fractional
    // window sizing can never split e.g. "100%" across two lines.
    readonly property bool needsWrap: !popup.mono && natural.implicitWidth + 2 > popup.maxTextWidth

    // Wrapped height for prose tooltips. Mono tables use the natural height
    // so the box borders stay aligned.
    Text {
        id: wrappedMeasure
        visible: false
        width: popup.boxWidth - popup.padding * 2
        text: popup.tipText
        font.family: popup.textFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }

    Rectangle {
        id: content
        width: popup.width
        height: popup.height
        color: Theme.base01
        border.color: Theme.base03
        border.width: 1
        radius: 10
        opacity: popup.reveal
        scale: 0.96 + popup.reveal * 0.04
        transformOrigin: Item.Top

        implicitWidth: popup.boxWidth
        implicitHeight: (popup.mono || !popup.needsWrap ? natural.implicitHeight : wrappedMeasure.implicitHeight) + popup.padding * 2

        Text {
            id: label
            x: popup.padding
            y: popup.padding
            width: content.width - popup.padding * 2
            height: content.height - popup.padding * 2
            text: popup.tipText
            color: Theme.base06
            font.family: popup.textFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            wrapMode: popup.needsWrap ? Text.Wrap : Text.NoWrap
            elide: popup.mono ? Text.ElideRight : Text.ElideNone
            verticalAlignment: Text.AlignTop
        }
    }
}
