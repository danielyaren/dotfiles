# Deduplicate PATH entries
typeset -U path PATH

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Completion styling
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Plugins (Sheldon)
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

# CLI integrations
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Prompt (Starship)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Machine-local overrides and secrets (untracked)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
