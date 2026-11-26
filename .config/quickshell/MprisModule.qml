import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "Ui.js" as Ui

/* Port of waybar's mpris module (format, paused format, icons and controls). */
Pill {
    id: root

    property var player: currentPlayer()
    property string playback: player ? MprisPlaybackState.toString(player.playbackState) : "Stopped"

    // Flash the OSD on track/state changes, but not for the initial sync.
    property bool osdArmed: false
    Timer {
        interval: 4000
        running: true
        onTriggered: root.osdArmed = true
    }

    property string mediaSig: player
        ? (playback + "|" + (player.trackTitle || "") + "|" + (player.trackArtist || "")) : ""

    onMediaSigChanged: {
        if (root.osdArmed && root.mediaSig !== "" && root.player) {
            OsdState.media(player.trackTitle || "", player.trackArtist || "", playback);
        }
    }

    function currentPlayer() {
        var players = Mpris.players.values;
        for (var i = 0; i < players.length; i++) {
            if (players[i].trackTitle && players[i].trackTitle !== "") return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }

    function playerIcon() {
        if (!player) return "▶";
        var id = (player.identity || player.desktopEntry || "").toLowerCase();
        if (id.indexOf("firefox") >= 0) return "";
        if (id.indexOf("chromium") >= 0 || id.indexOf("chrome") >= 0) return "";
        if (id.indexOf("mpv") >= 0) return "";
        return "▶";
    }

    label: {
        if (!player || playback === "Stopped") return "";
        var title = Ui.truncate(player.trackTitle || "", 45);
        var artist = Ui.truncate(player.trackArtist || "", 45);
        if (playback === "Paused") return "   " + artist + " — " + title;
        return playerIcon() + "   " + title + " — " + artist;
    }

    tooltip: player
        ? ((player.identity || "player") + " (" + playback + ")\nAlbum: " + (player.trackAlbum || ""))
        : ""

    keepVisible: false

    onClicked: {
        if (root.player) root.player.togglePlaying();
    }

    onWheeled: function(w) {
        if (!root.player) return;
        if (w.angleDelta.y > 0) root.player.previous();
        else root.player.next();
    }
}
