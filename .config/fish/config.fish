set fish_greeting

if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    zoxide init --cmd cd fish | source

    alias vim=nvim
    set EDITOR nvim

    alias cat='bat'
   
    fzf --fish | source

    # FZF
    function fzf 
      /usr/bin/fzf --preview 'bat --color=always {}'
    end
    alias hi="history | /usr/bin/fzf | sh"  
  

    # EXA
    alias ls='exa' # just replace ls by exa and allow all other exa arguments
    alias l='ls -lbF' #   list, size, type
    alias ll='ls -la' # long, all
    alias llm='ll --sort=modified' # list, long, sort by modification date
    alias la='ls -lbhHigUmuSa' # all list
    alias lx='ls -lbhHigUmuSa@' # all list and extended
    alias tree='exa --tree' # tree view
    alias lS='exa -1' # one column by just names

    set BUN_INSTALL "$HOME/.bun"
    fish_add_path "$BUN_INSTALL/bin"
  
    alias speedtest="npx speed-cloudflare-cli"

    fish_config theme choose rosepine


    source ~/.config/fish/view.fish


end

mise activate fish | source

# pnpm
set -gx PNPM_HOME "/home/lukasz/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
