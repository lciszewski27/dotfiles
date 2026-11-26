import QtQuick
import QtQuick.Controls.Basic as Controls
import Quickshell
import Quickshell.Services.Pipewire

/*
 * Port of waybar's pulseaudio + pulseaudio/slider group.
 *
 * The slider lives inside the volume pill itself and slides out to the right
 * of the speaker icon when the pointer enters. The icon stays anchored to the
 * left edge so it remains under the pointer while the pill grows rightwards
 * instead of sliding away and making the hover state flicker.
 */
Item {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property bool ready: Pipewire.ready && !!sink && sink.ready && !!sink.audio
    property real volume: ready ? sink.audio.volume : 0
    property bool muted: ready && sink.audio.muted

    implicitWidth: pill.width
    implicitHeight: Theme.panelHeight

    // Only flash the OSD for real changes, not the initial Pipewire sync.
    property bool osdArmed: false
    Timer {
        interval: 4000
        running: true
        onTriggered: root.osdArmed = true
    }

    onVolumeChanged: if (root.osdArmed) OsdState.sync(root.volume, root.muted)
    onMutedChanged: if (root.osdArmed) OsdState.sync(root.volume, root.muted)

    // Pipewire nodes must be tracked before their volume/mute properties can
    // be written. Without this the default sink stays "unbound" and every
    // write logs "node is not bound".
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    function icon() {
        if (!root.ready) return "󰕾";
        if (root.muted || root.volume <= 0.001) return "󰝟";
        if (root.volume < 0.34) return "󰕿";
        if (root.volume < 0.67) return "󰖀";
        return "󰕾";
    }

    function setVolume(value) {
        if (!root.ready) return;
        root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function adjust(delta) {
        if (!root.ready) return;
        root.setVolume(root.sink.audio.volume + delta);
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        width: 34 + (hover.hovered ? 64 : 0)
        height: Theme.panelHeight
        radius: Theme.pillRadius
        color: hover.hovered ? Theme.base02 : Theme.base01
        clip: true

        Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        Controls.Slider {
            id: slider
            x: 34
            width: Math.max(0, pill.width - 46)
            height: pill.height
            anchors.verticalCenter: parent.verticalCenter
            opacity: hover.hovered ? 1 : 0
            from: 0
            to: 1
            stepSize: 0.02
            value: root.volume

            onMoved: root.setVolume(value)

            Behavior on opacity { NumberAnimation { duration: 120 } }

            background: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.base03

                Rectangle {
                    width: parent.width * slider.visualPosition
                    height: parent.height
                    radius: 2
                    color: root.muted ? Theme.base04 : Theme.base07
                }
            }

            handle: Rectangle {
                x: slider.visualPosition * (slider.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Theme.base07
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon()
            color: root.muted ? Theme.base04 : Theme.base06
            font.family: Theme.fontMono
            font.pixelSize: 15
        }

        HoverHandler { id: hover }

        WheelHandler {
            onWheel: function(event) {
                root.adjust(event.angleDelta.y > 0 ? 0.02 : -0.02);
            }
        }

        MouseArea {
            anchors.left: parent.left
            width: 34
            height: parent.height
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(event) {
                if (event.button === Qt.RightButton) {
                    Quickshell.execDetached(["pavucontrol", "-t", "4"]);
                } else if (root.ready) {
                    root.sink.audio.muted = !root.sink.audio.muted;
                }
            }
        }
    }

    // The slider's declarative value binding is broken by dragging, so keep it
    // in sync with Pipewire afterwards without fighting the drag itself.
    Connections {
        target: root
        function onVolumeChanged() {
            if (!slider.pressed) slider.value = root.volume;
        }
    }

    TooltipPopup {
        anchorItem: pill
        tipText: root.ready
            ? (root.muted ? "Muted · " : "") + Math.round(root.volume * 100) + "%"
            : "Audio"
        show: hover.hovered
    }
}
