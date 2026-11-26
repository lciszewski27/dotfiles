pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/*
 * NotifyState.qml
 *
 * Session state for the notification center. The single NotificationServer in
 * shell.qml pushes into this; the toast overlay, the bell pill and the
 * history dialog all read from it, so every screen stays in sync.
 *
 * Each item: { n, id, ts, toastAlive, timeout } where `n` is the tracked
 * Notification object. Toasts auto-hide after `timeout` (0 = sticky);
 * everything stays in history until dismissed or closed by the app.
 */
Singleton {
    id: state

    property bool dnd: false
    property int unread: 0
    property var items: []
    property var toasts: []

    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical || n.resident) return 0;
        var t = n.expireTimeout;
        if (t > 0) return Math.min(t, 30000);
        return n.urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    function push(n) {
        n.tracked = true;
        var item = {
            n: n,
            id: n.id,
            ts: Date.now(),
            toastAlive: !state.dnd,
            timeout: state.timeoutFor(n)
        };
        state.items = [item].concat(state.items).slice(0, 30);
        state.unread = state.unread + 1;
        state.refreshToasts();
        n.closed.connect(function() { state.prune(n.id); });
    }

    function prune(id) {
        var kept = [];
        for (var i = 0; i < state.items.length; i++) {
            if (state.items[i].id !== id) kept.push(state.items[i]);
        }
        if (kept.length !== state.items.length) {
            state.items = kept;
            state.refreshToasts();
        }
    }

    // Hide the popup but keep it in history.
    function dismissToast(id) {
        var arr = state.items;
        var changed = false;
        for (var i = 0; i < arr.length; i++) {
            if (arr[i].id === id && arr[i].toastAlive) {
                arr[i].toastAlive = false;
                changed = true;
            }
        }
        if (changed) {
            state.items = arr.slice();
            state.refreshToasts();
        }
    }

    // Dismiss fully (also closes it for the sending app).
    function dismissNotification(id) {
        for (var i = 0; i < state.items.length; i++) {
            if (state.items[i].id === id) state.items[i].n.dismiss();
        }
    }

    function clearHistory() {
        var arr = state.items.slice();
        for (var i = 0; i < arr.length; i++) arr[i].n.dismiss();
        state.unread = 0;
    }

    function markRead() {
        state.unread = 0;
    }

    function refreshToasts() {
        var out = [];
        for (var i = 0; i < state.items.length; i++) {
            if (state.items[i].toastAlive) out.push(state.items[i]);
        }
        state.toasts = out;
    }
}
