# Quickshell bar

A Quickshell port of the Waybar setup in `~/.config/waybar`. It keeps the same
module order, glyphs, interactions and **Matugen-generated colours**: every
colour lives in `Theme.qml`, which Matugen regenerates on each wallpaper change.

## Run it

```sh
QS_ICON_THEME=Papirus-Dark qs   # icon theme env is required: without it all
                                # theme icons render as placeholders
# or
qs                      # uses ~/.config/quickshell/shell.qml
# or
qs -c default
```

To replace Waybar in this Hyprland setup, change the autostart entries in
`~/.config/hypr/modules/exec.lua`:

```lua
-- hl.exec_cmd("waybar")
hl.exec_cmd("QS_ICON_THEME=Papirus-Dark quickshell")
-- hl.exec_cmd("dunst")   -- keep off: quickshell owns org.freedesktop.Notifications
```

then `pkill waybar` and `hyprctl dispatch exec quickshell` for the current
session. Hyprland-side changes already applied for the new modules:

- `keybinds.lua`: the three volume media keys now call `pactl` directly
  (the bar's OSD reacts to the Pipewire change itself, so the dunst
  `osd.sh` popups would only duplicate it); the four `playerctl` media keys
  no longer notify via `osd.sh` (the bar's media OSD fires instead); SUPER+L
  now runs `qs ipc call lock lock` for the Quickshell lockscreen (hyprlock
  stays installed as fallback). Backups in `/tmp/opencode/`.
- dunst's D-Bus auto-activation is masked
  (`~/.local/share/dbus-1/services/org.knopwob.dunst.service` → `/dev/null`)
  so it can't steal the notification bus from under the bar.
- polkit-gnome's autostart in `exec.lua` is commented out — the bar is the
  polkit agent now. If auth prompts ever stop appearing, make sure no other
  agent (polkit-gnome, hyprpolkitagent) is running: two agents can't register.
- Your icon themes were symlinked from legacy `~/.icons/` into
  `~/.local/share/icons/` so XDG-conformant lookups (including Quickshell's)
  find them. Optional: add a blur rule for the new layer-shell namespace
`"quickshell-bar"` next to the existing `namespace = "waybar"` rule in
`~/.config/hypr/modules/rules.lua`.

## Files

| File | Role |
| --- | --- |
| `shell.qml` | Shell root, top layer-shell panel, left/center/right layout |
| `Theme.qml` | **Matugen output** — Base16 + Material 3 colours and fonts |
| `Pill.qml` | Shared pill, tooltip, hover/click/wheel handling |
| `TooltipPopup.qml` | Matugen-styled tooltip in its own popup window (fade/hang timers, screen-safe anchor) |
| `CalendarDialog.qml` | Interactive month calendar popup (Qt `MonthGrid` / `DayOfWeekRow`) |
| `Workspaces.qml` | `hyprland/workspaces` (1–5 always, 6–10 only when used, Chinese numerals, scroll) |
| `MprisModule.qml` | `mpris` (title/artist, player icons, wheel = prev/next) |
| `TrayModule.qml` | `tray` (StatusNotifier items with tooltips) |
| `CountdownModule.qml` | Port of the Go `countdown` module |
| `WeatherModule.qml` | Port of the Go `weather` module |
| `BluetoothModule.qml` | `bluetooth` (label + dialog; click opens, middle toggles power) |
| `BluetoothDialog.qml` | Bluetooth popover: power/scan toggles, device list, connect/pair/forget |
| `AudioModule.qml` | `pulseaudio` + `pulseaudio/slider` via Pipewire (slider inside the pill) |
| `NetworkModule.qml` | `network` via Quickshell.Networking (label + dialog + live speeds) |
| `NetSpeed.qml` | Singleton: per-second up/down rates from `/proc/net/dev` for the tooltip |
| `NetworkDialog.qml` | Network popover: Wi-Fi toggle, wired status, networks, PSK entry |
| `NotifyState.qml` | Singleton session state: notification history, unread count, DND, toasts |
| `OsdState.qml` | Singleton volume/mute state driving the OSD overlay |
| `BellModule.qml` | Notification bell (unread badge) + history dialog with DND + clear-all |
| `LockState.qml` | Singleton: lock flag + PAM authentication (config `login`); unlocks only on PAM success |
| `LockScreen.qml` | Per-screen `WlSessionLockSurface` hosting the lock UI |
| `LockContent.qml` | Lock UI: clock, date, avatar, password pill, error line (previewable standalone) |
| `PolkitDialog.qml` | Centered polkit prompt: action, message, error, password, cancel/submit |
| `PowerModule.qml` | Session/power ⏻ pill (opens overlay, right-click locks) |
| `PowerState.qml` | Singleton: overlay open flag + session actions (mirrors wlogout/layout) |
| `Wlogout.qml` | Fullscreen wlogout-style overlay: dim + frosted blur, 5 PNG-icon buttons, S/R/E/H/L |
| `DialogWindow.qml` | Shared Matugen card shell for the Bluetooth/Network popovers |
| `ToggleSwitch.qml` | Shared on/off toggle used by the dialogs |
| `ClockModule.qml` | `clock` (time normally, full date on hover) + calendar popup |
| `Ui.js` | Pure JS ports of the Go helpers (tables, formats, icon maps) |

## Colours from Matugen

1. Template: `~/.config/matugen/templates/quickshell.qml`
2. Output: `~/.config/quickshell/Theme.qml`
3. Registered in `~/.config/matugen/config.toml`:

```toml
[templates.quickshell]
input_path = '~/.config/matugen/templates/quickshell.qml'
output_path = '~/.config/quickshell/Theme.qml'
```

Regenerate everything with `matugen image <wallpaper>` (or your existing
theme-change script). The panel watches its files, so a regenerated
`Theme.qml` is picked up by hot reload.

Slots used by the panel:

- `base01` — pill background and tooltip/menu background
- `base03` — tooltip and slider trough border
- `base06` — primary text
- `base07` — active workspace, accents and slider highlight
- `m3Error` — errors / overdue / many updates
- `primary`, `surface`, `outline`, … — available for future modules

The Base16 slots use the same one-tone surface lift as the Waybar palette, so
panel, compositor, terminal and notifications stay in the same family.

## Ported Go modules

The modules that used to be provided by `~/.config/waybar/scripts/waybar-modules`
(`~/Projects/Active/go-waybar`) no longer need to be spawned. Their logic was
ported to `Ui.js` + QML:

| Go source | Quickshell equivalent | Behaviour kept |
| --- | --- | --- |
| `modules/weather/weather.go` | `WeatherModule.qml` + `Ui.parseWeather` | wttr.in `?0qnT`, icon map, framed tooltip, 30 min interval |
| `modules/updates/updates.go` | `UpdatesModule.qml` + `Ui.drawTable` | checkupdates / yay / flatpak, 5 min cache, per-manager tables, `none/few/some/many` classes |
| `modules/countdown/countdown.go` | `CountdownModule.qml` + `Ui.applyFormat` | target parsing, all format tokens/presets, status classes, Matura target |
| `utils/ui/table.go` | `Ui.drawTable` | Unicode box-drawing tables with Nerd Font width handling |

Waybar arguments map to properties at the top of each module file, e.g.
`targetText`, `targetLabel`, `formatString` in `CountdownModule.qml` and `city`
in `WeatherModule.qml`.

## Interactions

- Workspaces: slots 1–5 are always visible; 6–10 appear only while a
  workspace occupies them. Click to activate, scroll to move `e+1` / `e-1`.
- MPRIS: click to play/pause, scroll for previous/next
- Bluetooth: left click opens the device dialog (power/scan, connected +
  paired devices, connect/disconnect, pair/forget), middle click toggles
  power, right click opens Bluetooth settings
- Volume: the slider lives inside the same pill as the icon and slides out
  to the right on hover (the icon stays anchored so hover does not flicker).
  Click toggles mute, scroll or drag changes volume by 2% steps, right click
  opens `pavucontrol -t 4`. Pipewire nodes are bound with `PwObjectTracker`
  so writes actually reach the default sink.
- Tray icons sit in the same rounded pill as the other modules; tooltips are
  rendered in a separate popup window so they are never clipped by the thin
  panel surface. Box-drawing (mono) tooltips never wrap; prose tooltips wrap
  at 380px.
- Network: left click opens the network dialog (Wi-Fi toggle, wired status,
  network list with signal strength, connect/disconnect/forget and a password
  prompt for secured networks), middle click opens `nmtui`, right click opens
  Wi-Fi settings. The tooltip ends with a live `↓ / ↑` line sampled every
  second from `/proc/net/dev`
- Notifications: the bar owns `org.freedesktop.Notifications` (dunst must stay
  off — its autostart and D-Bus activation are disabled, see below). Toasts
  slide in top-right with urgency colours, an expiry progress bar and action
  buttons; critical ones stick until dismissed. The bell pill shows the
  unread count — left click opens the history (DND toggle, clear-all, click
  an entry to dismiss it), middle/right click toggles do-not-disturb
- Volume OSD: any Pipewire volume/mute change (bar slider, media keys,
  `pavucontrol`) flashes a top-center pill with icon, bar and percentage
  for 1.5s. Media OSD exists too (track + play/pause on MPRIS changes) but
  is off by default (`mediaOsd` in `OsdState.qml`) — the MPRIS pill already
  shows the track, and a popup on every video start is noise
- Power: left click opens a fullscreen wlogout-style overlay (same five
  buttons, PNG icons, hover style, S/R/E/H/L keybinds and loginctl commands
  as `~/.config/wlogout/layout`), Esc or click-outside cancels, right click
  locks straight away. Layer namespace is `quickshell-wlogout` if you want a
  blur rule for it
- Lockscreen: the bar is also the screen locker (`WlSessionLock` + PAM,
  Matugen-themed like hyprlock — clock, avatar, password pill). SUPER+L runs
  `qs ipc call lock lock`. Unlock needs your user password; PAM failures show
  in the pill and re-arm automatically. Escape hatch: Ctrl+Alt+F3, log in,
  `pkill -x quickshell` — the compositor releases the lock when its client dies
- Polkit: the bar is the authentication agent (themed prompt, replaces
  polkit-gnome, which must stay off — see below). Only one agent may register,
  so if prompts never appear, check no other agent is running
- Clock: the pill shows the time; hovering swaps it for the waybar
  `format-alt` date (`2026年11月26日 00:50`) inside the pill. Left click opens an interactive month calendar (arrows to change
  month, `Today`, click a day to select) using the system locale; right or
  middle click opens date/time settings
- Updates: click opens a terminal running `yay -Syu` and `flatpak update`
- Weather: click opens `v2.wttr.in` in Ghostty

## Differences from Waybar

- The volume slider expands inside the volume pill on hover instead of a
  separate always-visible slider.
- The network context menu is replaced by the network dialog (plus the same
  mouse-button shortcuts for settings/`nmtui`).
- The calendar is an interactive single-month popup instead of Waybar's
  year-popup calendar; the clock shows no sun/moon glyph — hover swaps the
  time for the date inside the pill.
- Hover tooltips use Quickshell's `PopupWindow` pattern so they are not
  clipped by the thin panel and fade in/out smoothly. Width is measured per
  line (a hidden `NoWrap` text) and capped at 380px — `TextMetrics` sums all
  lines and previously produced 640px-wide tooltips.
- Layout is one layer-shell surface per screen, namespace `quickshell-bar`,
  layer `Top`. The panel sits 5px below the top edge and tiled windows start
  5px below the bar, so the wallpaper strips above and below match. (That
  takes `exclusiveZone: 25`, not 33: Hyprland adds `gaps_out` plus the window
  frame on top of the zone.) The left and right groups are anchored to their screen edges and workspaces
  are centred; the 24px pills sit evenly inside the 28px panel.
- All panel text uses a semibold (DemiBold) 14px weight/size; tooltips are
  12px semibold.
