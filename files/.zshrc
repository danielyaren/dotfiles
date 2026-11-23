typeset -U path PATH

export PATH="$HOME/.rd/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias ls='ls -1G'

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
