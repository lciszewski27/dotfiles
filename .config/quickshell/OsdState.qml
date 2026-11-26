pragma Singleton

import QtQuick
import Quickshell

/*
 * OsdState.qml
 *
 * Volume OSD state. AudioModule syncs every Pipewire volume/mute change into
 * this (including changes from media keys or pavucontrol); the OSD overlay
 * in shell.qml shows itself on every ping and hides after 1.5s idle.
 */
Singleton {
    id: root

    property real volume: 0
    property bool muted: false
    property bool active: false

    function sync(v, m) {
        root.volume = v;
        root.muted = m;
        root.ping();
    }

    function ping() {
        root.active = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.active = false
    }

    // ── Media ─────────────────────────────────────────────────
    // Auto-popup is OFF: the MPRIS pill already shows the track, and a popup
    // on every video start is just noise. Flip to true to get the OSD back.
    property bool mediaOsd: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property bool mediaPlaying: false
    property bool mediaActive: false

    function media(title, artist, playing) {
        if (!root.mediaOsd) return;
        root.mediaTitle = title;
        root.mediaArtist = artist;
        root.mediaPlaying = playing;
        root.mediaActive = true;
        mediaHideTimer.restart();
    }

    Timer {
        id: mediaHideTimer
        interval: 2200
        onTriggered: root.mediaActive = false
    }
}
