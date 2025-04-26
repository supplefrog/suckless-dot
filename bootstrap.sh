#!/bin/bash

set -euo pipefail

# --- Config ---
DOTFILES_DIR="$HOME/.dotfiles"
REPOS=(
    "git://git.suckless.org/dwm $HOME/.de/dwm"
    "git://git.suckless.org/st  $HOME/.de/st"
    "https://github.com/derf/feh.git $HOME/.de/feh"
    "https://github.com/supplefrog/suckless-dot.git $DOTFILES_DIR"
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
    echo "==> Cloning repositories..."

    # Normalize input into an array
    local entries=()
    if [[ $# -eq 1 ]]; then
        entries+=("$1")
    else
        entries=("$@")
    fi

    for entry in "${entries[@]}"; do
        {
        # If the entry is just a URL, use the repository name as the directory
        if [[ $entry =~ ^https?:// ]]; then
            URL="$entry"
            DIR=$(basename "$URL" .git)
        else
            # If it's an entry like "url dir", split into URL and DIR
            read -r URL DIR <<< "$entry"
            # If DIR is not provided, derive it from the URL
            if [[ -z "$DIR" ]]; then
                DIR=$(basename "$URL" .git)
            fi
        fi

        echo "-> Handling $URL (dir: $DIR)..."

        # If the directory doesn't exist, create it
        if [[ ! -d "$DIR" ]]; then
            echo "Directory $DIR does not exist. Creating it..."
            mkdir -p "$DIR"
        fi

        if [[ -d "$DIR" && -d "$DIR/.git" ]]; then
            # If .git exists, pull the latest changes
            echo "$DIR repo exists. Pulling latest changes..."
            git -C "$DIR" pull --rebase --autostash && echo "Successfully pulled latest changes."
        
        elif [[ -d "$DIR" ]]; then
            # If it doesn't contain .git, reinitialize and pull
            echo "⚠️ $DIR exists but is not a git repo. Reinitializing and pulling..."
            (cd "$DIR" && git init && git remote add origin "$URL" && git pull --rebase --autostash) \
                && echo "Successfully pulled latest changes."

        else
            # If the directory doesn't exist, clone the repository
            echo "Cloning into $DIR..."
            git clone --depth=1 "$URL" "$DIR" && echo "Successfully cloned."
        fi
        } &
    done

    wait
}

# --- Run ---
detect_pkg_mgr
install_essentials
clone_repos "${REPOS[@]}"

# Source install scripts from repo
source "$DOTFILES_DIR/install_deps.sh" || echo "⚠️ install_deps.sh failed, continuing..."
source "$DOTFILES_DIR/install_deps_src.sh" || echo "⚠️ install_deps_src.sh failed, continuing..."
source "$DOTFILES_DIR/install.sh" || echo "⚠️ install.sh failed, continuing..."
