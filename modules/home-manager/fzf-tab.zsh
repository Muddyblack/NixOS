# fzf-tab beauty upgrades - Powerlevel10k style
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}󰀧 No matches found%f'
zstyle ':completion:*:messages' format '%F{yellow}󰋼 %d%f'
zstyle ':completion:*:corrections' format '%F{yellow}󰁨 %d (errors: %e)%f'

bindkey '^t' toggle-fzf-tab

# Progressive Completion: Prefix -> Native List -> FZF
typeset -g _fzf_tab_count=0
function premium-tab() {
  if [[ $LASTWIDGET != "premium-tab" ]]; then
    _fzf_tab_count=1
  else
    (( _fzf_tab_count++ ))
  fi

  if (( _fzf_tab_count == 1 )); then
    # First tab: Just complete the prefix (Classic Zsh)
    disable-fzf-tab
    zle expand-or-complete
    enable-fzf-tab
  elif (( _fzf_tab_count == 2 )); then
    # Second tab: Show the "normal" listing of items
    disable-fzf-tab
    zle list-choices
    enable-fzf-tab
  else
    # Third tab: Open the full premium fzf-tab UI
    zle fzf-tab-complete
    _fzf_tab_count=0 
  fi
}
zle -N premium-tab
bindkey '^I' premium-tab

# Still keep Ctrl+T as a manual override to turn it off completely
bindkey '^t' toggle-fzf-tab

zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-min-height 30
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' print-query ctrl-c

# Enhanced previews with icons and colors
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'

zstyle ':fzf-tab:complete:git-(checkout|add|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
zstyle ':fzf-tab:complete:git-diff:*' fzf-preview 'git diff --color=always $word | delta'

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ''${(P)word}'

zstyle ':fzf-tab:complete:*:*' fzf-preview '([ -f "$realpath" ] && bat --color=always --line-range :500 "$realpath") || ([ -d "$realpath" ] && eza -1 --icons=always --color=always "$realpath")'

# Floating Widget Vibe (Termius/Fig styled)
zstyle ':fzf-tab:*' group-colors $'\e[32m' $'\e[31m' $'\e[35m' $'\e[33m' $'\e[34m' $'\e[36m'

# Using Tokyo Night / Sweet palette
zstyle ':fzf-tab:*' fzf-flags \
  --color=bg+:#292e42,bg:#1a1b26,spinner:#bb9af7,hl:#f7768e \
  --color=fg:#c0caf5,header:#f7768e,info:#7aa2f7,pointer:#bb9af7 \
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7dcfff,hl+:#f7768e \
  --color=gutter:#1a1b26,border:#565f89 \
  --height 60% --layout=reverse-list \
  --border=rounded --margin=1 --padding=1 --info=hidden --header="" \
  --preview-window='right:60%:wrap:border-left' \
  --prompt='  ' --pointer='󰁔' --marker='󰄬 ' \
  --separator='─' --scrollbar='│' \
  --bind='ctrl-/:toggle-preview'
