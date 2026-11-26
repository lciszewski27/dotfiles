import QtQuick
import Quickshell

/*
 * LockContent.qml
 *
 * The lockscreen UI, rendered inside LockScreen.qml's WlSessionLockSurface
 * (one instance per screen). Kept as a separate Item so it can be previewed
 * in a plain window without engaging the session-lock protocol.
 *
 * Entrance is a staggered fade-and-rise driven by `open`: background and
 * ghost clock first, then clock, date, avatar, greeting and the password
 * pill in sequence.
 *
 * Layout mirrors ~/.config/hypr/hyprlock.conf: big clock up top, avatar +
 * greeting in the middle, password pill below.
 */
Item {
    id: root

    property bool open: false
    property string userName: Quickshell.env("USER") || "user"

    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
    onOpenChanged: anim = open ? 1 : 0

    // Maps anim into a 0..1 window so elements can stagger.
    function stage(from, to) {
        return Math.min(1, Math.max(0, (anim - from) / (to - from)));
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Background: themed near-black with a faint oversized clock ──
    Rectangle {
        anchors.fill: parent
        color: Theme.base08
        opacity: stage(0.0, 0.35)
    }

    Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.base01
        opacity: 0.55 * stage(0.0, 0.4)
        font.family: Theme.fontUi
        font.pixelSize: Math.min(parent.width * 0.22, 420)
        font.weight: Font.Bold
    }

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.base07
            opacity: stage(0.1, 0.45)
            transform: Translate { y: (1 - stage(0.1, 0.5)) * 26 }
            font.family: Theme.fontUi
            font.pixelSize: 110
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.base06
            opacity: stage(0.2, 0.55)
            transform: Translate { y: (1 - stage(0.2, 0.6)) * 24 }
            font.family: Theme.fontUi
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            height: 10
        }

        // Avatar circle with the initial, like the hyprlock logo block.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84
            height: 84
            radius: 42
            color: Theme.base02
            border.color: Theme.base07
            border.width: 2
            opacity: stage(0.3, 0.65)
            scale: 0.8 + 0.2 * stage(0.3, 0.7)
            transformOrigin: Item.Center

            Text {
                anchors.centerIn: parent
                text: root.userName.charAt(0).toUpperCase()
                color: Theme.base07
                font.family: Theme.fontUi
                font.pixelSize: 38
                font.weight: Font.Bold
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Hello, " + root.userName + " ✨"
            color: Theme.base06
            opacity: stage(0.4, 0.75)
            transform: Translate { y: (1 - stage(0.4, 0.75)) * 20 }
            font.family: Theme.fontUi
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        // Password pill, styled after hyprlock's input-field.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 290
            height: 45
            radius: 12
            color: Theme.base01
            border.color: LockState.failMessage !== "" ? Theme.m3Error : Theme.base07
            border.width: 2
            opacity: stage(0.5, 0.9)
            transform: Translate { y: (1 - stage(0.5, 0.9)) * 22 }

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                color: Theme.base06
                font.family: Theme.fontUi
                font.pixelSize: 15
                echoMode: TextInput.Password
                passwordCharacter: "●"
                focus: root.open
                enabled: LockState.pam.responseRequired
                onAccepted: {
                    LockState.submit(text);
                    text = "";
                }
            }

            Text {
                anchors.centerIn: parent
                text: LockState.pam.responseRequired ? (passwordInput.text === "" ? "Password" : "") : "Checking…"
                color: Theme.base04
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.weight: Font.DemiBold
                visible: passwordInput.text === ""
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: passwordInput.forceActiveFocus()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            text: LockState.failMessage
            visible: LockState.failMessage !== ""
            color: Theme.m3Error
            font.family: Theme.fontUi
            font.pixelSize: 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
