#!/usr/bin/env bash

DRY_RUN="$DRY_RUN"

set -eu -o pipefail

OS="$(uname)"

case "$OS" in
  Linux*)
    DIST="$(cat /etc/os-release | awk -F= '$1=="ID"{print $2}')"
    ;;
  Darwin)
    ;;
  *)
    echo "ERROR: unknown operating system $OS." >&2
    echo "ERROR: cannot initialize unknown operating system." >&2
    echo "ERROR: bailing out." >&2
esac

function _alreadyInstalled() {
  echo "NOTE: $1 already installed, skipping." >&2
}

function _run() {
  echo "$@"
  if [[ -z "$DRY_RUN" ]]; then
    "$@"
  fi
}

# Install Development Dependencies --------------------------------------------

# We'll need `sudo` here...

if [[ "$OS" == "Linux" && ( "$DIST" == "Debian" || "$DIST" == "Ubuntu" ) ]]; then
  _run sudo apt update
  _run sudo apt upgrade -y
  _run sudo apt install -y build-essential git
fi

# INSTALL HOMEBREW ------------------------------------------------------------

HAS_BREW=
command -v brew >/dev/null && HAS_BREW=1

if [[ "$OS" == "Darwin" && -z "$HAS_BREW" ]]; then
  NONINTERACTIVE=1 _run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew tap homebrew/autoupdate
  brew autoupdate start --upgrade --cleanup || true
else
  if [[ -n "$HAS_BREW" ]]; then
    _alreadyInstalled "homebrew"
  else
    echo "NOTE: homebrew not installed on linux, skipping." >&2
  fi
fi

# We'll install what we can through homebrew, as homebrew allows for automatic
# updates of installed packages, without having to compile them.

# INSTALL RUSTUP --------------------------------------------------------------

if ! command -v rustup >/dev/null; then
  _run curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -- \
    --no-modify-path --default-toolchain stable -y
else
  _alreadyInstalled "rustup"
fi

# INSTALL STARSHIP ------------------------------------------------------------

if ! command -v starship >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install starship
  else
    _run cargo install --locked starship
  fi
fi

# INSTALL vim-plug ------------------------------------------------------------

if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
  _run curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  _alreadyInstalled "vim-plug"
fi

# INSTALL fnm -----------------------------------------------------------------

if ! command -v fnm >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install fnm
  else
    _run cargo install --locked fnm
  fi
fi

# INSTALL exa/bat -------------------------------------------------------------

if ! command -v exa >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install exa
  else
    _run cargo install exa
  fi
else
  _alreadyInstalled "exa"
fi

if ! command -v bat >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install bat
  elif [[ "$OS" == "Linux" && ( "$DIST" == "Debian" || "$DIST" == "Ubuntu" ) ]]; then
    _run sudo apt install -y bat
    if ! command -v bat; then
      _run mkdir -p ~/.local/bin
      _run ln -s /usr/bin/batcat ~/.local/bin/bat
    fi
  else
    _run cargo install --locked bat
  fi
else
  _alreadyInstalled "bat"
fi
