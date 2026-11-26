hl.on("hyprland.start", function()
  -- One process per exec: compound `&` chains are not a shell here and
  -- a failing entry (e.g. missing swaync) must not kill the rest.
  hl.exec_cmd("vicinae server")
  hl.exec_cmd("QS_ICON_THEME=Papirus-Dark quickshell")
  -- No wallpaper daemon: Quickshell paints the background itself
  -- (WallpaperLayer, restored from ~/.config/quickshell/wallpaper.conf).
  -- hl.exec_cmd("awww-daemon")
  -- Quickshell runs the polkit agent itself (themed prompt in-shell), so the
  -- GNOME agent must stay off: only one agent may register on the bus.
  -- hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  -- NOTE: removed `__NV_DISABLE_EXPLICIT_SYNC=1 rquickshare` from autostart:
  -- explicit-sync is supported on this driver (see `hyprctl systeminfo`) and
  -- disabling it causes flicker; launch rquickshare on demand via Vicinae.
end)
