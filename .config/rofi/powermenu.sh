chosen=$(printf "  Power Off\n  Restart\n Log Out\n  Lock" | rofi -dmenu -i -theme-str '@import "power.rasi"')

case "$chosen" in
	"  Power Off") poweroff ;;
	"  Restart") reboot ;;
	"  Log Out") bspc quit ;;
	"  Lock") betterlockscreen -l dim ;;
	*) exit 1 ;;
esac
