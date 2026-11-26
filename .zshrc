# ------------------------------------------------------------------------------
# 1. P10K INSTANT PROMPT (Must stay at the top)
# ------------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# 2. CORE EXPORTS & TOOLS (Mise must come before Plugins)
# ------------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH="/home/lukasz/.bun/bin:$PATH"

# Initialize Mise (This ensures 'eza' is in your PATH for the plugin)
eval "$(~/.local/bin/mise activate zsh)"

# ------------------------------------------------------------------------------
# 3. OH-MY-ZSH CONFIGURATION
# ------------------------------------------------------------------------------
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-eza
)

# This sources the plugins listed above
source $ZSH/oh-my-zsh.sh

# ------------------------------------------------------------------------------
# 4. ALIASES & FUNCTIONS
# ------------------------------------------------------------------------------
alias v="nvim"
alias vim="nvim"
alias wttr="curl v2n.wttr.in/Gdansk"
alias speed="cloudflare-speed-cli"
alias zshconf="v ~/.zshrc"
alias reload="source ~/.zshrc"
alias lt="eza --tree --level=2 --icons"
alias ytm="yt-dlp -x --audio-format opus --audio-quality 0 --embed-thumbnail --embed-metadata --add-metadata --convert-thumbnails jpg"

alias z="zeditor"

# Yazi: Change directory on exit
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ------------------------------------------------------------------------------
# 5. ADDITIONAL TOOLS (Zoxide, Carapace)
# ------------------------------------------------------------------------------
eval "$(zoxide init zsh --cmd cd)"

autoload -U compinit && compinit
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

# ── Secrets ────────────────────────────────────────────────────────────
# API keys live in a separate, non-committed file so that .zshrc stays
# safe to publish. Create it with:
#   install -m 600 /dev/null ~/.config/secrets.env
if [ -r "$HOME/.config/secrets.env" ]; then
  source "$HOME/.config/secrets.env"
fi

# ------------------------------------------------------------------------------
# 6. P10K CONFIG (Keep at bottom)
# ------------------------------------------------------------------------------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh



discord-compress() {
    local input="$1"
    local output="${2:-discord_${input}}"
    local target_mb=19.5
    local audio_bitrate=128

    if [[ ! -f "$input" ]]; then
        echo "Błąd: Plik '$input' nie istnieje."
        return 1
    fi

    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprintwrappers=1:nokey=1 "$input")
    local video_bitrate=$(awk -v dur="$duration" -v target="$target_mb" -v ab="$audio_bitrate" 'BEGIN { print int(((target * 8192) / dur) - ab) }')

    echo "Długość: ${duration}s | Wyliczony bitrate wideo: ${video_bitrate}k"

    ffmpeg -y -i "$input" -c:v libx264 -preset slow -b:v "${video_bitrate}k" -pass 1 -an -f null /dev/null && \
    ffmpeg -i "$input" -c:v libx264 -preset slow -b:v "${video_bitrate}k" -pass 2 -c:a aac -b:a "${audio_bitrate}k" "$output"

    rm -f ffmpeg2pass-0.log ffmpeg2pass-0.log.mtree
}
