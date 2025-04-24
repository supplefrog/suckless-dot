#!/bin/bash

set -euo pipefail

# --- Config ---
DOTFILES_REPO="https://github.com/supplefrog/suckless-dot.git"
DOTFILES_DIR="$HOME/.dotfiles"
SUCKLESS_REPOS=(
    "dwm git://git.suckless.org/dwm $HOME/.de/dwm"
    "st  git://git.suckless.org/st  $HOME/.de/st"
    "feh https://github.com/derf/feh.git $HOME/.de/feh"
)

# --- Functions ---
detect_pkg_mgr() {
    if command -v apt &> /dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="sudo apt install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -Syu --noconfirm"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &> /dev/null; then
        PKG_MGR="yum"
        INSTALL_CMD="sudo yum install -y"
    else
        echo "Unsupported package manager."
        exit 1
    fi
}

install_essentials() {
    echo "Installing essential packages (git, curl)..."
    if ! command -v git &> /dev/null; then $INSTALL_CMD git; fi
    if ! command -v curl &> /dev/null; then $INSTALL_CMD curl; fi
}

clone_repos() {
    echo "==> Cloning suckless repositories..."

    for entry in "${SUCKLESS_REPOS[@]}"; do
        read -r NAME URL DIR <<< "$entry"
        echo "-> Handling $NAME..."

        if [[ ! -d "$DIR" ]]; then
            echo "Cloning $NAME into $DIR..."
            git clone --depth=1 "$URL" "$DIR"
        elif [[ -d "$DIR/.git" ]]; then
            echo "$NAME repo exists. Pulling latest changes..."
            git -C "$DIR" pull --rebase --autostash || echo "⚠️ Pull failed for $NAME, continuing."
        else
            echo "⚠️ $DIR exists but is not a git repo. Skipping $NAME."
        fi
    done

    echo "-> Handling dotfiles repo..."
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "Cloning dotfiles..."
        git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"
    elif [[ -d "$DOTFILES_DIR/.git" ]]; then
        echo "Updating dotfiles repo..."
        git -C "$DOTFILES_DIR" pull --rebase --autostash || echo "⚠️ Pull failed for dotfiles, continuing."
    else
        echo "⚠️ $DOTFILES_DIR exists but is not a git repo. Skipping dotfiles."
    fi
}

# --- Run ---
detect_pkg_mgr
install_essentials
clone_repos

# Source install scripts from dotfiles repo
source "$DOTFILES_DIR/install_deps.sh"
source "$DOTFILES_DIR/install_deps_src.sh"
source "$DOTFILES_DIR/install.sh"
