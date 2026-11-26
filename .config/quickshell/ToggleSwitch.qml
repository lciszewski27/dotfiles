import QtQuick

/*
 * ToggleSwitch.qml
 *
 * Small on/off toggle styled with Matugen colours: base07 track when on,
 * base02 when off.
 *
 *   ToggleSwitch {
 *       checked: Networking.wifiEnabled
 *       onToggled: function(on) { Networking.wifiEnabled = on; }
 *   }
 */
Item {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled(bool on)

    implicitWidth: 40
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.base07 : Theme.base02
        border.color: root.disabled ? Theme.base04 : Theme.base03
        border.width: 1

        Behavior on color { ColorAnimation { duration: 140 } }

        Rectangle {
            id: thumb
            width: parent.height - 6
            height: parent.height - 6
            radius: width / 2
            x: root.checked ? parent.width - width - 3 : 3
            y: 3
            color: Theme.base01

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
