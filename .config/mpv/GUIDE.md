# mpv setup guide

Modern, full-featured mpv configuration with a cute pastel UI. Works on
Linux (Wayland + NVIDIA) and Windows. This folder is `%APPDATA%\mpv` on
Windows and `~/.config/mpv` on Linux. Everything is in English
(`slang`/`alang=en`, uosc `languages=en`): menus, OSD messages, and all
custom scripts.

## What's installed

| Component | Purpose | Source |
|---|---|---|
| **uosc** | Cute pastel OSD/UI: rounded timeline, menus, controls, seek/volume indicators | [tomasklaen/uosc](https://github.com/tomasklaen/uosc) |
| **thumbfast** | Instant hover thumbnails on the timeline (works with uosc) | [po5/thumbfast](https://github.com/po5/thumbfast) |
| **rtx-vsr.lua** | Automatic NVIDIA RTX Video Super Resolution, Windows only | custom (this setup) |
| **audio-viz.lua** | Pastel music visualizer: Cute / Aurora / Bars (`v` / `V`) | custom (this setup) |
| **FSRCNNX / KrigBilateral / SSim / adaptive-sharpen** | Quality shaders: CNN upscaling, chroma, downscaling, sharpening | [igv](https://github.com/igv/FSRCNN-TensorFlow) + mirrors |
| **Anime4K v4.0.1** | Dedicated anime upscaling/restoration shader set | [bloc97/Anime4K](https://github.com/bloc97/Anime4K) |
| **SimpleHistory** | Watch history: resume videos, browse history lists | [Eisa01/mpv-scripts](https://github.com/Eisa01/mpv-scripts) |
| **playlistmanager** | Advanced playlist management (sort, save, browse) | [jonniek/mpv-playlistmanager](https://github.com/jonniek/mpv-playlistmanager) |
| **autoload** | Auto-adds files from the same folder to the playlist | [mpv-player/mpv](https://github.com/mpv-player/mpv) |
| **webm** | Clip maker / GIF exporter (saves clips of what you watch) | [ekisu/mpv-webm](https://github.com/ekisu/mpv-webm) |
| **ytdl_hook** | Stream playback via yt-dlp (built into mpv) | mpv built-in, settings in `script-opts/ytdl_hook.conf` |

Folders: `scripts\` (Lua addons), `script-opts\` (their settings),
`shaders\` (GPU shaders), `fonts\` (uosc icon fonts + Quicksand UI font).

## Key bindings

Kept from mpv defaults: `f` fullscreen, `q` quit, `j` next subtitle,
`#` next audio track, `9`/`0` volume, `,`/`.` frame step, `z`/`x` subtitle
delay, `1-8` video equalizer.

Added / changed:

| Key | Action |
|---|---|
| Click video / `space` | Pause |
| `right` / `left` | Seek +-5 s (`shift+` = +-30 s) |
| `wheel up/down` | Volume +-5 |
| `shift+wheel up/down` | Seek +-5 s |
| `up` / `down` | Volume +-5 |
| `m` | Mute |
| `[` `]` | Speed -/+ 0.1, `Backspace` reset speed |
| `>` / `<` | Next / previous file (playlist or folder) |
| `Menu` key / right click | uosc context menu |
| `Tab` | Playlist / open file |
| `o` | Open file (browser) |
| `ctrl+v` | Paste URL / path from the clipboard |
| `c` | Chapters |
| `alt+s` / `alt+a` / `alt+d` | Subtitles / audio / video track menus |
| `alt+q` | Stream quality (YouTube etc.) |
| `alt+i` | Show all active key bindings |
| **`alt+1`** | **Shaders: Quality set** (FSRCNNX + Krig + SSim + sharpen) |
| **`alt+2`** | **Shaders: Anime4K v4.0** (anime) |
| **`alt+3`** | **Shaders: off** (plain scalers) |
| **`alt+v`** | **RTX Video Super Resolution on/off (Windows only)** |
| `alt+t` | Motion interpolation on/off |
| `v` | Music visualizer on/off |
| **`V`** | **Music visualizer style: Cute -> Aurora -> Bars** |
| `i` | Playback statistics on/off |
| `` ` `` | Console |
| `s` | Screenshot (`screenshots\` folder) |
| `T` | Stay on top on/off |
| `L` | Loop current file on/off |
| `alt+u` | Audio output device menu |
| `alt+o` | Open config directory |
| `O` (shift+o) | Show current file in directory |
| `W` (shift+w) | Clip maker (webm/GIF; saved next to the video) |
| `h` / `r` | SimpleHistory: history list (all / recent) |
| `ctrl+r` | Resume last/previous video |
| `shift+enter` | Playlist manager |
| `alt+>` / `alt+<` / `alt+esc` | Delete file & next / previous / quit |

All of these are also available in the right-click menu.

## NVIDIA features

- **RTX VSR (AI upscaling)** - Windows only, automatic
  (see `scripts\rtx-vsr.lua`). The scale factor is computed from your
  screen size: e.g. 720p video on a 1080p screen -> 1.5x, 1080p on
  1440p -> 1.3x, 1080p on 4K -> 2x. It is skipped for HDR videos,
  videos bigger than 1440p, and when the video already fills the
  screen. Toggle with `alt+v`; tweak in `script-opts\rtx-vsr.conf`.
  On Linux the script stays idle (no D3D11 backend) and the FSRCNNX
  shader set handles upscaling instead.
- **RTX HDR** (SDR -> HDR) is not enabled because it needs an HDR
  display. If you have one on Windows, add this line to `mpv.conf`:
  `vf-append=d3d11vpp=nvidia-true-hdr`
- Hardware decoding (`d3d11va` on Windows / `nvdec` on Linux, via
  `hwdec=auto-safe`) is on by default; the clip maker uses **NVENC**
  (hardware encoding, works on both OSes).

## Shaders

- Default set (`alt+1`): FSRCNNX x2 CNN upscale + SSimSuperRes + KrigBilateral
  (chroma) + SSimDownscaler + adaptive-sharpen. They only activate when
  actually needed (upscaling/downscaling/4:2:0 chroma), so they cost nothing
  for native-resolution video.
- Anime (`alt+2`): Anime4K v4.0 "Mode A" chain. For more quality change `_M`
  to `_L` variants (e.g. `Anime4K_Restore_CNN_L`) in `input.conf`; for weaker
  GPUs use `_S`.
- Extra shaders in `shaders\`: `AMD_CAS.glsl` (sharpening) and
  `FSRCNNX_x2_8-0-4-1.glsl` (lighter FSRCNNX) - both have menu entries under
  *Shaders* in the right-click menu.

## Other features

- **Thumbnails**: just hover the timeline with the mouse.
- **Resume**: closed videos resume where you left off; full history with `h`.
- **Music visualizer**: music files automatically show a pastel spectrum.
  Three built-in styles:
  - **Cute** (default) - blush/lavender CQT bars + scrolling sonogram,
    exactly centered (500 + 40 + 540 = 1080).
  - **Aurora** - dreamy blue/violet full-height waterfall sonogram.
  - **Bars** - full-height pink frequency bars.
  Toggle with `v`, switch styles with `V`, or click the equalizer button in
  the control bar. When the visualizer is off, embedded/external cover art
  is shown again. Settings (enable, style, custom filter):
  `script-opts\audio-viz.conf` + `scripts\audio-viz.lua`.
- **Cute UI**: soft plum/blush colors, rounded corners (10 px), larger
  controls, always-visible title bar with the artist below the song title,
  and a pink progress bar. All labels and menus are English.
- **Stats / console**: `i` shows playback stats (dropped frames, A/V sync,
  GPU usage), `` ` `` opens the command console.
- **Stay on top / loop**: `T` keeps the window above others, `L` loops the
  current file.
- **UI font / theme**: the interface uses Quicksand (static builds in
  `fonts\`, `Quicksand-Regular/Medium/Bold.ttf` - variable fonts don't
  match mpv's DirectWrite font provider on Windows). The pastel plum/blush
  theme, rounded corners, and opacity live in `script-opts\uosc.conf`
  (`color=`, `opacity=`, `border_radius`, `top_bar`). Change the font with
  `osd-font` in `mpv.conf`.
- **Streaming**: paste a YouTube/stream URL; `[network]` profile buffers and
  reconnects automatically; `alt+q` switches quality; format defaults live
  in `mpv.conf` (`ytdl-format`) + `script-opts\ytdl_hook.conf`.
- **Live/sports low-latency mode**: `mpv --profile=live <URL>`.
- **Screenshots**: `s`, saved to `screenshots\` as `name - 0001.png`.
- **Clips**: play, press `W`, pick a range, export (fast NVENC encoding).
- **Subtitles**: auto-loaded from `sub`/`subs`/`subtitles` folders, timing
  auto-fixed (`sub-fix-timing`), blended into video for HDR; download
  from OpenSubtitles via `alt+s` -> Download.
- **Audio**: gapless album playback, volume up to 200%, embedded cover art
  shown automatically, media keys and drag-and-drop enabled.
- **Discs**: `dvd://`, `bd://`, `cdda://` work out of the box
  (device set in `mpv.conf`).
- **UI language**: English everywhere (`slang`/`alang=en`,
  uosc `languages=en`).

## Notes

- On Linux the config uses Wayland + NVDEC automatically; on Windows it
  switches to D3D11 + D3D11VA (see `[windows]` / `[linux]` profiles in
  `mpv.conf`). The old config forced `gpu-api=d3d11`, which broke Linux -
  that is fixed now.
- `thumbfast` uses `mpv_path=mpv` (PATH lookup). Do not set it to an empty
  value: that overrides thumbfast's default and causes
  `cannot create mpv subprocess` errors.
- `ytdl-format` avoids AV1 because RTX 30-series cannot hardware-decode it;
  VP9/AVC are decoded on the GPU.
- VSR pauses G-Sync while it is upscaling (NVIDIA driver limitation).
- Mouse wheel = volume (as requested); seek moved to `shift+wheel` and the
  arrow keys.

## Updating

```powershell
# uosc
irm https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/windows.ps1 | iex
# anime4k + shaders/scripts: re-download from their GitHub release pages
```

Nothing here is locked in - every file is plain text/`.lua` and safe to edit.
