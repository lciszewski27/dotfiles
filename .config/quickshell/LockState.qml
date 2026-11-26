pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

/*
 * LockState.qml
 *
 * Single source of truth for the session lock. WlSessionLock in shell.qml
 * binds to `locked`; the ⏻ pill, SUPER+L (via `qs ipc call lock lock`) and
 * the sleep action all go through lock(). Authentication runs through one
 * shared PamContext (config "login"); only a PAM Success unlocks.
 *
 * NOTE: only `lock()` is exposed over IPC on purpose — unlocking must always
 * go through the password prompt. If the lock ever misbehaves, switch to a
 * TTY (Ctrl+Alt+F3) and `pkill -x quickshell`; the compositor releases the
 * lock when the client dies.
 */
Singleton {
    id: root

    property bool locked: false
    property string failMessage: ""

    property PamContext pam: PamContext {
        config: "login"

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                root.failMessage = "";
                root.pam.active = false;
                root.locked = false;
            } else {
                root.failMessage = root.pam.message !== "" ? root.pam.message : "Wrong password";
                // Ready for the next attempt.
                root.pam.start();
            }
        }

        onError: function(err) {
            root.failMessage = "Authentication error: " + PamError.toString(err);
        }
    }

    function lock() {
        if (root.locked) return;
        root.failMessage = "";
        root.locked = true;
        root.pam.active = true;
        if (!root.pam.start()) {
            root.failMessage = "Could not start authentication";
            root.locked = false;
            root.pam.active = false;
        }
    }

    function submit(password) {
        if (root.pam.responseRequired) {
            root.failMessage = "";
            root.pam.respond(password);
        }
    }
}
