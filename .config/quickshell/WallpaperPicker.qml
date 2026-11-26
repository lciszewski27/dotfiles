import QtQuick
import Quickshell
import Quickshell.Wayland

/*
 * WallpaperPicker.qml
 *
 * Centered thumbnail grid over ~/Pictures/Wallpapers. Click a wallpaper to
 * apply it (awww + save + matugen via WallpaperState) and close. Opens via
 * `qs ipc call wallpaper toggle` (SUPER+W).
 *
 * Own centered overlay (not DialogWindow — there is no anchor pill for it).
 * One instance per screen (see shell.qml); all bind to WallpaperState.
 */
PanelWindow {
    id: win

    required property var modelData

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Keyboard focus while open so arrows/Enter/Esc work (same requirement
    // as the polkit prompt: layer-shell key delivery needs it). The surface
    // only maps while the picker is open.
    focusable: true
    visible: win.anim > 0.01

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-wallpaper"

    property real anim: 0
    Behavior on anim { NumberAnimation { duration: 160 } }
    property bool opened: WallpaperState.open
    // Keyboard cursor into the grid; starts on the current wallpaper.
    property int selected: 0
    onOpenedChanged: {
        win.anim = win.opened ? 1 : 0;
        if (win.opened) {
            var idx = 0;
            for (var i = 0; i < WallpaperState.wallpapers.length; i++) {
                if (WallpaperState.isCurrent(WallpaperState.wallpapers[i])) {
                    idx = i;
                    break;
                }
            }
            win.selected = idx;
        }
    }

    // Keyboard navigation: arrows move in the 3-column grid, Enter/Space
    // applies, Esc closes.
    Item {
        anchors.fill: parent
        focus: WallpaperState.open
        Keys.onPressed: function(event) {
            var n = WallpaperState.wallpapers.length;
            if (n === 0) return;
            var cols = 3;
            var s = win.selected;
            if (event.key === Qt.Key_Left) s = Math.max(0, s - 1);
            else if (event.key === Qt.Key_Right) s = Math.min(n - 1, s + 1);
            else if (event.key === Qt.Key_Up) s = Math.max(0, s - cols);
            else if (event.key === Qt.Key_Down) s = Math.min(n - 1, s + cols);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                     || event.key === Qt.Key_Space) {
                WallpaperState.applyName(WallpaperState.wallpapers[s]);
                WallpaperState.open = false;
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_Escape) {
                WallpaperState.open = false;
                event.accepted = true;
                return;
            } else {
                return;
            }
            win.selected = s;
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 700
        implicitHeight: Math.min(bodyCol.implicitHeight + 28, 560)
        radius: 14
        color: Theme.base01
        border.color: Theme.base03
        border.width: 1
        opacity: win.anim
        scale: 0.97 + win.anim * 0.03
        transformOrigin: Item.Top

        Column {
            id: bodyCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Row {
                width: parent.width
                spacing: 10

                Column {
                    width: parent.width - 32
                    spacing: 1

                    Text {
                        text: "Wallpaper"
                        color: Theme.base07
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        width: parent.width
                        text: WallpaperState.applying ? "Applying + matugen…" : (WallpaperState.current !== "" ? WallpaperState.current : WallpaperState.dir)
                        color: Theme.base05
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideMiddle
                    }
                }

                Rectangle {
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
                        onClicked: WallpaperState.open = false
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.base03
            }

            Flickable {
                id: scroller
                width: parent.width
                height: Math.min(grid.implicitHeight, 440)
                contentWidth: width
                contentHeight: grid.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                // Explicit wheel scrolling: the delegates' MouseAreas
                // would otherwise swallow wheel events.
                WheelHandler {
                    onWheel: function(event) {
                        var maxY = Math.max(0, scroller.contentHeight - scroller.height);
                        scroller.contentY = Math.min(maxY, Math.max(0, scroller.contentY - event.angleDelta.y));
                    }
                }

                Grid {
                    id: grid
                    width: parent.width
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: WallpaperState.wallpapers
                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            property string name: modelData
                            property bool isCurrent: WallpaperState.isCurrent(name)
                            property bool kbSelected: index === win.selected

                            width: Math.floor((grid.width - 20) / 3)
                            height: 150
                            radius: 10
                            color: (thumbMouse.containsMouse || kbSelected) ? Theme.base02 : "transparent"
                            border.color: isCurrent ? Theme.base07 : (kbSelected ? Theme.base05 : Theme.base03)
                            border.width: (isCurrent || kbSelected) ? 2 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                spacing: 6

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    height: 108
                                    radius: 7
                                    color: Theme.base02
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        smooth: true
                                        mipmap: true
                                        sourceSize.width: 400
                                        source: "file://" + WallpaperState.fullPath(name)
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 7
                                        color: "transparent"
                                        border.color: Theme.base03
                                        border.width: 1
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    text: (isCurrent ? "● " : "") + name
                                    color: isCurrent ? Theme.base07 : Theme.base06
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: thumbMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onContainsMouseChanged: if (containsMouse) win.selected = index
                                onClicked: {
                                    WallpaperState.applyName(name);
                                    WallpaperState.open = false;
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: WallpaperState.wallpapers.length === 0 ? "No images in ~/Pictures/Wallpapers." : ""
                visible: text !== ""
                color: Theme.base04
                font.family: Theme.fontUi
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
