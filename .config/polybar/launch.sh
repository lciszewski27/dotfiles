#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done
while pgrep -u $UID -x wal >/dev/null; do sleep 0.1; done # this solved the problem for me

# Launch bars
for monitor in $(polybar -m | cut -d: -f1); do
    MONITOR=$monitor polybar bar -q & disown
done