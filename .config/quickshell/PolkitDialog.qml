import QtQuick
import Quickshell
import Quickshell.Wayland

/*
 * PolkitDialog.qml
 *
 * Centered authentication prompt for the current auth flow, styled with the
 * Matugen palette. The PolkitAgent lives at shell root (registration only
 * completes there); each per-screen instance gets it passed in as `agent`.
 */
PanelWindow {
    id: win

    required property var modelData
    required property var agent

    readonly property var flow: agent ? agent.flow : null
    readonly property bool active: win.flow !== null && !win.flow.isCompleted && !win.flow.isCancelled

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 160
    }
    implicitHeight: 240
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    visible: win.anim > 0.01

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-polkit"

    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 160 } }
    onActiveChanged: win.anim = active ? 1 : 0
    // (uses win.active from the header)

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 380
        implicitHeight: authCol.implicitHeight + 28
        radius: 14
        color: Theme.base01
        border.color: Theme.base03
        border.width: 1
        opacity: win.anim
        scale: 0.97 + win.anim * 0.03
        transformOrigin: Item.Top

        Column {
            id: authCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Row {
                width: parent.width
                spacing: 10

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    smooth: true
                    source: {
                        var ic = (win.flow && win.flow.iconName) || "dialog-password";
                        return Quickshell.iconPath(ic, "dialog-password");
                    }
                }

                Column {
                    width: parent.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: "Authentication required"
                        color: Theme.base07
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: win.flow ? (win.flow.actionId || "") : ""
                        color: Theme.base05
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                width: parent.width
                text: win.flow ? (win.flow.message || "") : ""
                visible: text !== ""
                color: Theme.base06
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                width: parent.width
                text: win.flow ? (win.flow.supplementaryMessage || "") : ""
                visible: text !== "" && win.flow && win.flow.supplementaryIsError
                color: Theme.m3Error
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 9
                color: Theme.base02
                border.color: Theme.base03
                border.width: 1

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.base06
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    echoMode: (win.flow && win.flow.responseVisible)
                        ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    focus: win.active
                    enabled: win.flow && win.flow.isResponseRequired
                    onAccepted: {
                        if (win.flow) win.flow.submit(text);
                        text = "";
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: (win.flow && win.flow.inputPrompt) || "Password…"
                    color: Theme.base04
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    visible: passwordInput.text === ""
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    width: 84
                    height: 30
                    radius: 8
                    color: cancelMouse.containsMouse ? Theme.base03 : "transparent"
                    border.color: Theme.base03
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.base06
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (win.flow) win.flow.cancelAuthenticationRequest()
                    }
                }

                Rectangle {
                    width: 84
                    height: 30
                    radius: 8
                    color: Theme.base07

                    Text {
                        anchors.centerIn: parent
                        text: "Submit"
                        color: Theme.base01
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (win.flow) win.flow.submit(passwordInput.text);
                            passwordInput.text = "";
                        }
                    }
                }
            }
        }
    }
}
