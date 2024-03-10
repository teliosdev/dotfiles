HISTFILE=~/.zhistory
HISTSIZE=1000000
SAVEHIST=100000000
setopt autocd beep extendedglob nomatch notify
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# ZSH -------------------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="minimal"
plugins=(git rust tmux)
source "$ZSH/oh-my-zsh.sh"

# ALIASES ---------------------------------------------------------------------

command -v eza >/dev/null && alias ls=eza
command -v bat >/dev/null && alias cat=bat

tmux-here() {
    local AT="${1:-"$(pwd)"}"
    cd "$AT" && tmux new -A -s "$(basename "$AT")"
}

r() {
    cd "$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
}

if ! command -v docker >/dev/null; then
    if command -v podman >/dev/null; then
        alias docker=podman
    fi
fi

export PATH="$HOME/.local/bin:$PATH"

###############################################################################
# TOOLING & SDKS
###############################################################################

# RBENV -----------------------------------------------------------------------

if [[ -d "$HOME/.rbenv" ]]; then
    RBENV="$(command -v rbenv)"
    [[ -f "$RBENV" ]] || RBENV="$HOME/.rbenv/bin/rbenv"
    eval "$($HOME/.rbenv/bin/rbenv init - zsh)"
fi

# RUSTUP/CARGO ----------------------------------------------------------------

if [[ -d "$HOME/.cargo" ]]; then
    source "$HOME/.cargo/env"
fi

# FNM/NVM ---------------------------------------------------------------------

if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd)"
else
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# PNPM ------------------------------------------------------------------------

export PNPM_HOME="$HOME/.local/share/pnpm"
if [[ -d "$PNPM_HOME" ]]; then
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
fi

# SDKMAN ----------------------------------------------------------------------

export SDKMAN_DIR="$HOME/.sdkman"
if [[ -d "$SDKMAN_DIR" ]]; then
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

###############################################################################
# LOCAL IMPORT
###############################################################################

# Because this zshrc is meant to be general, it does not include some
# machine-specific setup.  So, we'll allow machines to specify their own
# specific configurations in a supplementary file.

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
