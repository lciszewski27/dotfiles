#!/usr/bin/env bash

DIR="$HOME/Pictures/screenshots"
FILE="$DIR/screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

mkdir -p "$DIR"

MODE="$1"

case "$MODE" in
    full)
        grim "$FILE"
        ;;
    area)
        AREA=$(slurp)
        [ -z "$AREA" ] && exit 0
        grim -g "$AREA" "$FILE"
        ;;
    window)
        # Geometry of the currently focused window (the old nested-hyprctl
        # jq filter never evaluated, so this mode always failed).
        AREA=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [ -z "$AREA" ] && AREA=$(slurp)
        [ -z "$AREA" ] && exit 0
        grim -g "$AREA" "$FILE"
        ;;
    *)
        echo "Użycie: $0 {full|area|window}"
        exit 1
        ;;
esac

if [ -f "$FILE" ]; then
    wl-copy --type image/png < "$FILE"
    canberra-gtk-play -i camera-shutter 2>/dev/null &
    notify-send "Zrzut ekranu" "Zapisano i skopiowano do schowka" -i "$FILE" -a "Screenshot"
fi
