-- ═══════════════════════════════════════════════════════════════════════════
--  MOTION SPEC — the "bouncy" layer of the design system
--
--  Every animation in the system is defined here, and nowhere else. Keep it
--  that way: one file to tune, one file to revert, one place to look when
--  something feels wrong.
--
--  Design reference: design.md §7 (Motion Spec)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── The curve library ────────────────────────────────────────────────────
--  Spring damping ratio:  ζ = dampening / (2 · √(stiffness · mass))
--    ζ = 1  →  critical damping, settles without overshooting
--    ζ < 1  →  underdamped: the surface wobbles into place
--
--  NOTE: the argument is "dampening", not "damping". The Hyprland 0.56
--        validator only accepts "dampening" — "damping" is silently wrong.
--  Bézier points are (x, y) control points; y > 1 means it overshoots.

-- ζ ≈ 0.30 — two to three visible oscillations. For the base window motion.
hl.curve("cute-wobble", { type = "spring", mass = 1, stiffness = 400, dampening = 12 })

-- ζ ≈ 0.45 — one clear, deliberate bounce. For the accent border and pops.
hl.curve("cute-bounce", { type = "spring", mass = 1, stiffness = 400, dampening = 18 })

-- ζ ≈ 0.69 — a hint of overshoot, settles almost immediately. For drags.
hl.curve("cute-soft",   { type = "spring", mass = 1, stiffness = 300, dampening = 24 })

-- No oscillation — fast and elastic. For anything that must not wobble.
hl.curve("cute-snap",   { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1 } } })

-- ── Named speeds ─────────────────────────────────────────────────────────
--  speed is in deciseconds (1 = 100 ms)
--    snappy  = 2  →  fades, layers
--    settled = 3  →  windows, workspaces, moves
--    instant = 8  →  the accent border, the fastest thing on screen

-- ── Leaf assignment ──────────────────────────────────────────────────────
--  "global" is the parent of every unset leaf, so it is kept conservative
--  (default curve) and everything we care about is set explicitly below.

hl.animation({ leaf = "global",   enabled = true, speed = 4, bezier = "default" })

-- Windows: pop in with a bounce, pop out small and quick.
hl.animation({ leaf = "windows",     enabled = true, speed = 3, spring = "cute-wobble" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, spring = "cute-bounce", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2, bezier = "cute-snap",   style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, spring = "cute-soft" })

-- The accent border is the fastest element on screen: focus has to feel
-- like a direct response to input.
hl.animation({ leaf = "border",     enabled = true, speed = 8, spring = "cute-bounce" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "cute-snap" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 2, bezier = "cute-snap" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2, bezier = "cute-snap" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "cute-snap" })

-- Layer surfaces (Vicinae launcher, Quickshell toasts/bar/power menu). Hyprland
-- applies ONE animation to all layer surfaces — layer rules support
-- no_anim but not a per-namespace curve — so both pop.
hl.animation({ leaf = "layers",    enabled = true, speed = 2, spring = "cute-bounce" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 2, spring = "cute-bounce", style = "popin 92%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "cute-snap" })

-- Workspaces slide horizontally instead of crossfading.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3, spring = "cute-soft", style = "slidefade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2, bezier = "cute-snap" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, spring = "cute-soft" })

-- The scratchpad slides in from the right edge.
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 3, spring = "cute-bounce", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3, spring = "cute-bounce", style = "slide" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "cute-snap",   style = "slide" })
