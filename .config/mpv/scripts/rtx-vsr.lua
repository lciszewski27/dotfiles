-- rtx-vsr.lua - automatic NVIDIA RTX Video Super Resolution (VSR) upscaling
--
-- What it does:
--   Appends the filter  @vsr:d3d11vpp=format=nv12:scaling-mode=nvidia:scale=<f>
--   whenever the running video is smaller than the display and RTX VSR can
--   actually help. The scale factor is computed from the display size, so it
--   always fills the screen correctly (e.g. 1080p video on a 4K screen -> 2.0).
--
-- Requirements (already handled by mpv.conf):
--   gpu-context=d3d11  +  hwdec=d3d11va  +  mpv 0.39 or newer
--
-- Toggle in mpv:  alt+v   (bound in input.conf)
-- Options:        script-opts/rtx-vsr.conf

local mp = require "mp"
local msg = require "mp.msg"
local options = require "mp.options"

local opts = {
    enabled     = true,   -- master switch (in-session toggle: alt+v)
    min_scale   = 1.2,    -- only engage if upscale factor is at least this
    max_scale   = 3.0,    -- upper cap for the driver's scale factor
    min_width   = 480,    -- RTX VSR is unreliable below these input sizes
    min_height  = 360,
    max_width   = 2560,   -- no point above 1440p input
    max_height  = 1440,
    skip_hdr    = true,   -- don't touch HDR (PQ/HLG) videos
    osd_messages = true,
}
options.read_options(opts, "rtx-vsr")

local last_applied = nil   -- scale string currently applied by us
local pending = false

local function osd(text)
    if opts.osd_messages then
        mp.osd_message(text, 2)
    end
end

local function has_vsr()
    return mp.get_property("vf", ""):find("@vsr", 1, true) ~= nil
end

local function remove_vsr()
    if has_vsr() then
        mp.commandv("vf", "remove", "@vsr")
        msg.verbose("VSR filter removed")
    end
    last_applied = nil
end

local function apply_vsr(scale)
    if has_vsr() then
        mp.commandv("vf", "remove", "@vsr")
    end
    mp.commandv("vf", "append",
        "@vsr:d3d11vpp=format=nv12:scaling-mode=nvidia:scale=" .. scale)
    last_applied = scale
    msg.verbose("RTX VSR engaged, scale=" .. scale)
end

local function update()
    pending = false

    if not opts.enabled then
        remove_vsr()
        return
    end

    -- RTX VSR only works through the D3D11 video processor
    if mp.get_property("gpu-context", "") ~= "d3d11" then
        remove_vsr()
        return
    end

    -- skip images (gifs, wallpapers...)
    if mp.get_property_bool("current-tracks/video/image", false) then
        remove_vsr()
        return
    end

    local vw = mp.get_property_number("video-params/w")
    local vh = mp.get_property_number("video-params/h")
    local dw = mp.get_property_number("display-width")
    local dh = mp.get_property_number("display-height")
    if not (vw and vh and dw and dh) then
        remove_vsr()
        return
    end

    -- HDR needs to be handled by the HDR pipeline, not VSR
    if opts.skip_hdr then
        local gamma = mp.get_property("video-params/gamma", "")
        if gamma == "pq" or gamma == "hlg" then
            msg.verbose("HDR video (" .. gamma .. "), VSR skipped")
            remove_vsr()
            return
        end
    end

    if vw < opts.min_width or vh < opts.min_height
        or vw > opts.max_width or vh > opts.max_height then
        remove_vsr()
        return
    end

    local scale = math.max(dw, dh) / math.max(vw, vh)
    scale = math.floor(scale * 10 + 0.5) / 10
    if scale > opts.max_scale then scale = opts.max_scale end
    if scale < opts.min_scale then
        remove_vsr()
        return
    end

    local s = string.format("%.1f", scale)
    if s == last_applied then
        return
    end
    apply_vsr(s)
end

local function schedule_update()
    if pending then return end
    pending = true
    mp.add_timeout(0.15, update)
end

mp.observe_property("video-params", "native", schedule_update)
mp.observe_property("display-width", "native", schedule_update)
mp.observe_property("display-height", "native", schedule_update)
mp.observe_property("current-tracks/video", "native", schedule_update)

local function toggle()
    opts.enabled = not opts.enabled
    if opts.enabled then
        last_applied = nil
        update()
        if last_applied then
            osd("RTX VSR: ON  (scale " .. last_applied .. ")")
        else
            osd("RTX VSR: ON  (not applicable to this video)")
        end
    else
        remove_vsr()
        osd("RTX VSR: OFF")
    end
end

mp.register_script_message("toggle", toggle)
