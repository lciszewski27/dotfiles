local theme = require("modules/colors")

-- The "cozy" layer of the design system: shadows are tinted with the accent
-- hue instead of pure black. This single change does double duty — it makes
-- the focused window read as a soft neon glow, and it warms every other
-- shadow on screen.
--
-- The colour is derived from the live theme, so it follows the wallpaper.
-- It is only re-read when Hyprland reloads the config, which is why
-- theme-chnage.sh ends with `hyprctl reload config-only`.
local primary = theme.colors["primary"] or "#d9bafa"

hl.config({
  general = {
    gaps_in          = 4,
    gaps_out         = 8,

    border_size      = 2,

    col              = {
      -- The gradient border is the system's signature. It runs
      -- primary -> tertiary, NOT primary -> secondary: under the
      -- scheme-fruit-salad palette primary (#a4c8ff) and secondary
      -- (#a5c8fe) are almost the same colour, which would flatten the
      -- border to a single solid tone. tertiary (#d9bafa) keeps the
      -- gradient clearly visible.
      active_border   = { colors = { theme.colors["primary"], theme.colors["tertiary"] }, angle = 45 },
      -- surface is near-black: inactive borders were invisible, so the
      -- highest surface tone is used to keep window boundaries legible.
      inactive_border = theme.colors["surface_container_highest"],
    },

    resize_on_border = false,

    allow_tearing    = false,

    layout           = "dwindle",
  },

  decoration = {
    -- Cozy layer: soften the corners. 8px read as "sharp utility window";
    -- 16px reads as the same family as the panel pills (20px) and the
    -- notification cards (20px).
    rounding       = 16,
    rounding_power = 2,

    -- Cozy layer: dreamier frost. This is the most expensive change in the
    -- design — if the 144 Hz panel starts dropping frames, drop to
    -- size 12 / passes 2 and it still reads as dreamy.
    blur           = {
      enabled            = true,
      size               = 16,
      passes             = 3,
      noise              = 0.10,
      contrast           = 1.05,
      brightness         = 0.92,
      vibrancy           = 0.25,
      xray               = true,
      ignore_opacity     = true,
      new_optimizations  = true,
      special            = false,
      popups             = true,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
  },
  misc = {
    disable_hyprland_logo = 1,
    disable_splash_rendering = true,
    background_color = "0x000000"
  },
  ecosystem = {
    no_donation_nag = true
  }

})

-- NOTE: every animation leaf lives in modules/motion.lua. Keeping the motion
-- spec in one file is what makes it tunable and revertable in isolation.
