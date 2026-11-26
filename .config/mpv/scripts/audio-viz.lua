-- Cute audio visualizer for mpv (music only).
--
-- Settings: script-opts/audio-viz.conf (enable, style, optional custom filter).
--
-- Behavior:
--   * Whenever MUSIC is playing (a file with audio and either no video track or
--     only cover art), a spectrum is shown automatically.
--   * Real videos (movies, clips, streams with a picture) are never replaced.
--   * "v"       = visualizer on/off
--   * "V"       = cycle styles: Cute -> Aurora -> Bars
--   * Turning it off shows the embedded/external cover art again.
--
-- The visualizer is a lavfi-complex graph fed by [aid1]. It is explicitly
-- cleared on start-file/end-file so the next file (including images and
-- videos without audio) always loads cleanly.
--
-- NOTE: mpv exposes this script as "audio_viz" (dash -> underscore).

local mp = require "mp"
local msg = require "mp.msg"
local options = require "mp.options"

local opts = {
    enabled = true,
    style = "cute",
    -- Optional: a full custom lavfi-complex graph. When non-empty it wins
    -- over the built-in styles below. Keep [aid1] as the audio input and
    -- [ao]/[vo] as the outputs, e.g.:
    --   filter=[aid1]asplit[ao][viz];[viz]showcqt=...[vo]
    filter = "",
}
options.read_options(opts, "audio-viz")

-- Built-in styles. All are 1920x1080 so the GPU can scale them to any window.
local styles = {
    cute = {
        label = "Cute",
        filter = "[aid1]asplit[ao][viz];[viz]showcqt=s=1920x1080:fps=60" ..
                 ":bar_h=500:axis_h=40:sono_h=540" ..
                 ":count=6:tc=0.17:text=0:bar_g=1:sono_g=3:bar_t=0.6" ..
                 ":cscheme=1|0.35|0.65|0.95|0.15|0.45[vo]",
    },
    aurora = {
        label = "Aurora",
        filter = "[aid1]asplit[ao][viz];[viz]showcqt=s=1920x1080:fps=30" ..
                 ":bar_h=0:axis_h=0:sono_h=1080" ..
                 ":count=6:tc=0.17:text=0:sono_g=4:sono_v=8" ..
                 ":cscheme=0.05|0.02|0.3|0.2|0.4|1[vo]",
    },
    bars = {
        label = "Bars",
        filter = "[aid1]asplit[ao][viz];[viz]showcqt=s=1920x1080:fps=60" ..
                 ":bar_h=1060:axis_h=20:sono_h=0" ..
                 ":count=6:tc=0.17:text=0:bar_t=0.6" ..
                 ":cscheme=1|0.35|0.65|0.95|0.15|0.45[vo]",
    },
}
local style_order = { "cute", "aurora", "bars" }

if not styles[opts.style] then
    msg.warn("audio visualizer: unknown style '" .. tostring(opts.style) ..
             "', falling back to 'cute'")
    opts.style = "cute"
end

local active = false
local cover_vid = nil -- remembered cover-art track id (reselected when viz turns off)

local function selected_aid()
    local id = mp.get_property_native("current-tracks/audio/id")
    if type(id) == "number" then return id end
    local aid = mp.get_property_native("aid")
    if type(aid) == "number" then return aid end
    return 1
end

local function get_filter()
    local filter = (opts.filter and opts.filter ~= "")
        and opts.filter or styles[opts.style].filter
    -- Use the currently selected audio track (not always track 1).
    local aid = selected_aid()
    return (filter:gsub("%[aid1%]", "[aid" .. aid .. "]"))
end

local function clear()
    if active then
        mp.set_property("lavfi-complex", "")
        -- Restore normal video selection so the next file (especially a real
        -- video) starts with its picture track enabled.
        mp.set_property("vid", "auto")
        active = false
        msg.verbose("audio visualizer: video filter cleared")
    end
end

local function remember_cover()
    -- find the attached-picture track (embedded or external cover art)
    cover_vid = nil
    local tracks = mp.get_property_native("track-list") or {}
    for _, t in ipairs(tracks) do
        if t.type == "video" and t.image then
            cover_vid = t.id
            break
        end
    end
end

local function restore_cover()
    -- turning the viz off orphans the video track selection (mpv quirk),
    -- so explicitly reselect the cover art; without this the screen
    -- would stay black instead of showing the cover again
    if cover_vid ~= nil then
        mp.set_property("vid", cover_vid)
        msg.verbose("audio visualizer: cover art restored (vid=" ..
                    cover_vid .. ")")
    end
end

local function is_music()
    -- Use the full track list (not current-tracks): after restoring cover art
    -- mpv can temporarily report no "current" audio track even though the file
    -- is still music.
    local has_audio, has_real_video = false, false
    local tracks = mp.get_property_native("track-list") or {}
    for _, t in ipairs(tracks) do
        if t.type == "audio" then
            has_audio = true
        elseif t.type == "video" and not t.image then
            has_real_video = true
        end
    end
    return has_audio and not has_real_video
end

local function apply()
    remember_cover()
    if opts.enabled and is_music() then
        -- Setting lavfi-complex automatically hands the video output to the
        -- filter graph (mpv switches vid to no). Do not touch vid manually:
        -- otherwise re-enabling after showing cover art can leave a black VO.
        mp.set_property("lavfi-complex", get_filter())
        active = true
        msg.verbose("audio visualizer: on (" .. opts.style .. ")")
    else
        local was_active = active
        clear()
        -- Only reselect cover art if we actually replaced it. This prevents
        -- stealing video-track selection from normal videos with cover art.
        if was_active then
            restore_cover()
        end
    end
end

local function toggle()
    opts.enabled = not opts.enabled
    if opts.enabled then
        mp.osd_message("Visualizer: ON — " .. styles[opts.style].label, 2.5)
        msg.info("audio visualizer: enabled (" .. opts.style .. ")")
    else
        mp.osd_message("Visualizer: OFF — cover art", 2.5)
        msg.info("audio visualizer: disabled")
    end
    apply()
end

local function cycle_style()
    local current = 1
    for i, name in ipairs(style_order) do
        if name == opts.style then
            current = i
            break
        end
    end
    opts.style = style_order[current % #style_order + 1]
    opts.enabled = true
    apply()
    mp.osd_message("Visualizer style: " .. styles[opts.style].label, 2.5)
    msg.info("audio visualizer: style -> " .. opts.style)
end

local function set_style(name)
    local key = tostring(name or ""):lower()
    if not styles[key] then
        mp.osd_message("Visualizer: unknown style '" .. key .. "'", 2.5)
        return
    end
    opts.style = key
    opts.enabled = true
    apply()
    mp.osd_message("Visualizer style: " .. styles[key].label, 2.5)
end

mp.register_event("file-loaded", apply)   -- tracks are known here
mp.register_event("end-file", clear)      -- clear before the next file starts
mp.register_event("start-file", clear)    -- belt and suspenders

-- Named key bindings, so input.conf can use `script-binding audio_viz/...`.
mp.add_key_binding(nil, "toggle", toggle)
mp.add_key_binding(nil, "cycle-style", cycle_style)

-- Also keep script messages for IPC / other scripts.
mp.register_script_message("toggle", toggle)
mp.register_script_message("cycle-style", cycle_style)
mp.register_script_message("style", set_style)
