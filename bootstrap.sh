#!/bin/bash

set -euo pipefail

# Detect package manager and define install command
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

# Ensure essential packages are available
install_essentials() {
    echo "Installing essential packages (git, curl)..."

    if ! command -v git &> /dev/null; then
        echo "Git not found. Installing..."
        $INSTALL_CMD git
    fi

    if ! command -v curl &> /dev/null; then
        echo "Curl not found. Installing..."
        $INSTALL_CMD curl
    fi
}

# Clone function (without building yet)
clone_repos() {
    echo "==> Cloning repositories..."

    declare -a REPO_NAMES=("dwm" "st" "feh")
    declare -a REPO_URLS=(
        "git://git.suckless.org/dwm"
        "git://git.suckless.org/st"
        "https://github.com/derf/feh.git"
    )
    declare -a REPO_DIRS=(
        "$HOME/.de/dwm"
        "$HOME/.de/st"
        "$HOME/.de/feh"
    )

    for i in "${!REPO_NAMES[@]}"; do
        NAME="${REPO_NAMES[$i]}"
        URL="${REPO_URLS[$i]}"
        DIR="${REPO_DIRS[$i]}"

        echo "-> Handling $NAME..."

        if [[ ! -d "$DIR" ]]; then
            echo "Cloning $NAME into $DIR..."
            git clone "$URL" "$DIR"
        elif [[ -d "$DIR/.git" ]]; then
            echo "$NAME repo exists. Pulling latest changes..."
            git -C "$DIR" pull --rebase --autostash || echo "⚠️ Failed to pull $NAME, continuing anyway."
        else
            echo "⚠️ $DIR exists but is not a git repo. Skipping $NAME."
        fi
    done

    # Dotfiles repo
    DOTFILES_REPO="https://github.com/supplefrog/suckless-dot.git"
    DOTFILES_DIR="$HOME/Downloads/suckless-dot"

    echo "-> Handling dotfiles repo..."

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        echo "Cloning dotfiles..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    elif [[ -d "$DOTFILES_DIR/.git" ]]; then
        echo "Updating dotfiles repo..."
        git -C "$DOTFILES_DIR" pull --rebase --autostash || echo "⚠️ Failed to pull dotfiles, continuing anyway."
    else
        echo "⚠️ $DOTFILES_DIR exists but is not a git repo. Skipping dotfiles."
    fi
}

# --- MAIN SCRIPT EXECUTION ---
detect_pkg_mgr
install_essentials
clone_repos

# Move dot files and install builds
source "$(dirname "$0")/install_deps.sh"
source "$(dirname "$0")/install_deps_src.sh"
source "$(dirname "$0")/install.sh"
