import QtQuick
import Quickshell

/*
 * The panel's shared pill: base01 background, base06/07 text, rounded corners
 * and a Matugen-styled tooltip. The Go modules only produce text + tooltip,
 * so every ported module can render through this one component.
 */
Rectangle {
    id: root

    property string label: ""
    property string tooltip: ""
    property string stateClass: ""
    property string textFont: Theme.fontUi
    property int textSize: 14
    property bool textBold: false
    property bool keepVisible: true
    property bool emphasized: false
    property real glow: 0
    property bool breathing: false
    property alias mouseArea: mouse

    signal clicked(var event)
    signal wheeled(var event)

    implicitWidth: labelText.implicitWidth + 20
    implicitHeight: Theme.panelHeight
    radius: Theme.pillRadius
    color: root.emphasized || mouse.containsMouse ? Theme.base02 : Theme.base01
    visible: root.keepVisible || root.label !== ""

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: glowText
        anchors.centerIn: parent
        text: root.label
        color: Theme.base07
        font.family: root.textFont
        font.pixelSize: root.textSize + 3
        font.weight: Font.DemiBold
        opacity: root.breathing ? 0.35 : root.glow

        SequentialAnimation on opacity {
            running: root.breathing
            loops: Animation.Infinite
            NumberAnimation { from: 0.15; to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.45; to: 0.15; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: {
            if (root.stateClass === "error" || root.stateClass === "many" ||
                root.stateClass === "overdue") return Theme.m3Error;
            if (root.stateClass === "none" || root.stateClass === "empty") return Theme.base04;
            if (root.stateClass === "active" || root.stateClass === "soon" ||
                root.stateClass === "some") return Theme.base07;
            return Theme.base06;
        }
        font.family: root.textFont
        font.pixelSize: root.textSize
        font.weight: root.textBold ? Font.Bold : Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function(m) { root.clicked(m); }
        onWheel: function(w) { root.wheeled(w); }
    }

    TooltipPopup {
        anchorItem: root
        tipText: root.tooltip
        show: mouse.containsMouse && root.tooltip !== ""
        mono: root.tooltip.indexOf("╭") === 0
    }
}
