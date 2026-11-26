import QtQuick
import Quickshell
import Quickshell.Wayland

/*
 * WallpaperLayer.qml
 *
 * The desktop background, painted by Quickshell itself on the Background
 * layer (no wallpaper daemon). Crossfades — with a slight grow — to the new
 * image whenever WallpaperState.current changes.
 *
 * One instance per screen (see shell.qml).
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
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    visible: true
    color: "black"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-background"

    // Image currently (fully) shown; `wanted` tracks WallpaperState.
    property string shown: ""
    property string wanted: WallpaperState.current
    property bool pendingFade: false

    onWantedChanged: {
        if (win.wanted === "" || win.wanted === win.shown) return;
        fade.stop();
        back.opacity = 0;
        back.scale = 1.05;
        back.source = win.wanted;
        if (back.status === Image.Ready) {
            win.pendingFade = false;
            fade.start();
        } else {
            win.pendingFade = true;
        }
    }

    Component.onCompleted: {
        if (win.wanted !== "") {
            front.source = win.wanted;
            win.shown = win.wanted;
        }
    }

    Image {
        id: front
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
    }

    Image {
        id: back
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: true
        opacity: 0
        scale: 1.05
        transformOrigin: Item.Center

        onStatusChanged: {
            if (status === Image.Ready && win.pendingFade) {
                win.pendingFade = false;
                fade.start();
            } else if (status === Image.Error) {
                win.pendingFade = false;
            }
        }
    }

    ParallelAnimation {
        id: fade
        NumberAnimation {
            target: back
            property: "opacity"
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: back
            property: "scale"
            from: 1.05
            to: 1.0
            duration: 600
            easing.type: Easing.OutCubic
        }
        onFinished: {
            front.source = back.source;
            win.shown = back.source.toString().replace(/^file:\/\//, "");
            back.opacity = 0;
        }
    }
}
