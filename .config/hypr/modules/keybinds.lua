local mainMod = "SUPER"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("vicinae toggle"))
-- Quickshell owns the session lock (WlSessionLock + PAM): SUPER+L asks it
-- to lock over IPC. hyprlock stays installed as a fallback.
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("qs ipc call lock lock"))
hl.bind(mainMod .. " + q", hl.dsp.exec_cmd("~/.config/hypr/scripts/wlogout.sh"))

-- Screenshot
hl.bind(mainMod .. " + s",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind(mainMod .. " + SHIFT + s",
    hl.dsp.exec_cmd(
        "~/.config/hypr/scripts/screenshot.sh area"))
hl.bind(mainMod .. " + CTRL + s",
    hl.dsp.exec_cmd(
    "~/.config/hypr/scripts/screenshot.sh window"))

hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace scratchpad"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspace special:scratchpad"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Vim-style focus (no Shift) + move window (with Shift)
hl.bind(mainMod .. " + h", hl.dsp.exec_cmd("hyprctl dispatch movefocus l"))
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("hyprctl dispatch movefocus r"))
hl.bind(mainMod .. " + k", hl.dsp.exec_cmd("hyprctl dispatch movefocus u"))
hl.bind(mainMod .. " + j", hl.dsp.exec_cmd("hyprctl dispatch movefocus d"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness.
-- Volume keys drive Pipewire directly; the Quickshell bar shows its own OSD
-- on every volume/mute change, so the dunst osd.sh popups are not needed.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("sh -c 'pactl set-sink-mute @DEFAULT_SINK@ 0; pactl set-sink-volume @DEFAULT_SINK@ +1%'"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
-- Desktop monitor has no backlight: route through OSD script (brightnessctl
-- when available) instead of calling a missing `light` binary with sudo.
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("/home/lukasz/.config/dunst/osd.sh brightness_up"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("/home/lukasz/.config/dunst/osd.sh brightness_down"),                  { locked = true, repeating = true })

-- Bare Print key also takes a screenshot (in addition to SUPER+S combos)
hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
