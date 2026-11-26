hl.window_rule({
  match = {
    class = "com.mitchellh.ghostty"
  },
  opacity = 0.9
})

-- Dialogs / tools float above tiling
hl.window_rule({
  match = { class = "org.pulseaudio.pavucontrol" },
  float = true,
})
hl.window_rule({
  match = { class = "pavucontrol" },
  float = true,
})
hl.window_rule({
  match = { class = "blueman-manager" },
  float = true,
})
hl.window_rule({
  match = { class = "nm-connection-editor" },
  float = true,
})
hl.window_rule({
  match = { class = "nwg-look" },
  float = true,
})
hl.window_rule({
  match = { class = "xdg-desktop-portal-gtk" },
  float = true,
})
hl.window_rule({
  match = { title = "Picture-in-Picture" },
  float = true,
  pin = true,
})

-- Blur layer-shell surfaces (bar, notifications, power menu)
--
-- no_anim on the bar and the wallpaper is deliberate: the `popin` style on
-- the layersIn animation leaves a layer-shell surface stuck at alpha 0
-- (invisible) when the surface is mapped at startup. The bar is excluded
-- so it cannot be blanked, and the wallpaper is excluded because a 92%
-- scale of a fullscreen image reads as a glitch, not a pop.
hl.layer_rule({
  match = { namespace = "waybar" },
  blur = true,
  ignore_alpha = 0.3,
  no_anim = true,
})
hl.layer_rule({
  match = { namespace = "awww-daemon" },
  no_anim = true,
})
hl.layer_rule({
  match = { namespace = "notifications" },
  blur = true,
  -- Force blur behind the ~90% opaque popup (same frosted effect as the
  -- Ghostty window, which uses ignore_opacity + xray). A low threshold like
  -- 0.3 leaves the surface effectively opaque, i.e. no visible blur.
  ignore_alpha = true,
  xray = true,
})
hl.layer_rule({
  match = { namespace = "logout_dialog" },
  blur = true,
})
hl.layer_rule({
  match = { namespace = "quickshell-wlogout" },
  blur = true,
  -- Frosted blur through the overlay dim (same recipe as notifications).
  ignore_alpha = true,
  xray = true,
})
