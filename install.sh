#!/usr/bin/env bash

set -Eeu -o pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# This is a script to set up the dotfiles to my own preferences.  This is set
# up to work on debian, fedora, and MacOS; other operating systems will fail.
# Additionally, it will iteratively update; if files already exist in place,
# it will not re-install or recreate.
#
# Most importantly, this sets up the dotfiles that a user has.

_log() {
    echo " #+ $@" >&2
}

_run() {
    _log "$@"
    "$@"
}

_get() {
    curl -fsSL --proto '=https' --tlsv1.2 "$@"
}

_runRemote() {
    URL="$1"
    shift
    _log "curl \"$URL\" | bash"
    _get "$URL" | bash -s -- "$@"
}

function _alreadyInstalled() {
  _log "NOTE: '$1' already installed, skipping." >&2
}

# First, we're going to ensure that we're on a recognized platform.  This is
# also used later to know what package managers to use.
OS="$(uname -s)"
DIST=""

case "$OS" in
    Linux*)
        DIST="$(cat /etc/os-release | awk -F= '$1=="ID"{print $2}')"
        case "$DIST" in
            debian) ;;
            ubuntu) ;;
            fedora) ;;
            *)
                _log "ERROR: Unrecognized Linux distribution '$DIST'; bailing."
                exit 1
                ;;
        esac
        ;;
    Darwin)
        ;;
    *)
        _log "ERROR: Unrecognized OS '$OS'; bailing."
        exit 1
        ;;
esac

###############################################################################
# Install Dependencies
###############################################################################

if [[ "$OS" == "Linux" && ( "$DIST" == "debian" || "$DIST" == "ubuntu" ) ]]; then
    if ! command -v sudo; then
        _run apt update
        _run apt install -y sudo
    fi
    _run sudo apt update
    _run sudo apt upgrade -y
    _run sudo apt install -y build-essential git vim stow curl zsh
elif [[ "$OS" == "Linux" && "$DIST" == "fedora" ]]; then
    _run sudo dnf update
    _run sudo dnf upgrade -y
    _run sudo dnf groupinstall -y "Development Tools"
    _run sudo dnf install -y cmake vim stow curl zsh
fi

# INSTALL HOMEBREW ------------------------------------------------------------

HAS_BREW=
command -v brew >/dev/null && HAS_BREW=1

if [[ "$OS" == "Darwin" && -z "$HAS_BREW" ]]; then
  NONINTERACTIVE=1 _runRemote "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  brew tap homebrew/autoupdate
  brew autoupdate start --upgrade --cleanup || true
else
  if [[ -n "$HAS_BREW" ]]; then
    _alreadyInstalled "homebrew"
  else
    _log "NOTE: homebrew not installed on linux, skipping."
  fi
fi

# We'll install what we can through homebrew, as homebrew allows for automatic
# updates of installed packages, without having to compile them.  Homebrew
# often also includes the latest versions of the package...

# INSTALL RUSTUP --------------------------------------------------------------

if ! command -v rustup >/dev/null; then
  _run curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --no-modify-path --default-toolchain stable -y
  source "$HOME/.cargo/env"
else
  _alreadyInstalled "rustup"
fi

if ! command -v cargo-binstall >/dev/null; then
  _runRemote  "https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh"
else
  _alreadyInstalled "cargo-binstall"
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
    _run cargo binstall -y fnm
  fi
fi

# INSTALL eza/bat -------------------------------------------------------------

if ! command -v eza >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install eza
  else
    _run cargo binstall -y eza
  fi
else
  _alreadyInstalled "eza"
fi

# Bat can be installed from the OS's package managers because pretty much all
# of them are up-to-date.  However, for Debian/Ubuntu, there is a problem -
# Debian/Ubuntu install them as `batcat`, instead of just `bat`, so we have to
# link for local useage.
if ! command -v bat >/dev/null; then
  if [[ -n "$HAS_BREW" ]]; then
    _run brew install bat
  elif [[ "$OS" == "Linux" && ( "$DIST" == "debian" || "$DIST" == "ubuntu" ) ]]; then
    _run sudo apt install -y bat
    if ! command -v bat; then
      _run mkdir -p ~/.local/bin
      _run ln -s /usr/bin/batcat ~/.local/bin/bat || true
    fi
  elif [[ "$OS" == "Linux" && "$DIST" == "fedora" ]]; then
    _run sudo dnf install -y bat
  else
    _run cargo binstall -y bat
  fi
else
  _alreadyInstalled "bat"
fi

# INSTALL oh-my-zsh -----------------------------------------------------------

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    _runRemote "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" --unattended
    rm -rf "$HOME/.zshrc"
fi

###############################################################################
# STOW
###############################################################################

# Now, we must properly apply our stow links to manage our dotfiles.  Stow
# conceptualizes things as 'packages'.  This repository (the directory the
# file is in) is the 'stow directory', and by default, the directory above
# the 'stow directory' is the 'target directory'.  Essentially, anything
# we want to stow (e.g., `zsh`) will be stored under `./zsh/`, and anything
# within `./zsh/` will be symlinked into the target directory.  So, if there
# is a `./zsh/.zshrc`, a symlink will be created at `../.zshrc` to it when
# we run `stow zsh` _in this directory_.
#
# This is a bit flimsy, and we can't guarantee what the current directory is
# going to be when the script is run, so we'll pass `-D ../` on every
# invocation, which sets the 'stow directory' to `../`.

_stow() {
    _run stow -d "$DIR" "$@"
}

# PACKAGES --------------------------------------------------------------------

_stow zsh
_stow git
_stow tmux
_stow vim
