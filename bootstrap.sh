#!/bin/bash

set -euo pipefail

# --- Config ---
DOTFILES_DIR="$HOME/.dotfiles"
REPOS=(
    "git://git.suckless.org/dwm $HOME/.de/dwm"
    "git://git.suckless.org/st $HOME/.de/st"
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
    echo "==> Handling repositories..."
    local args=("$@")
    
    local commit_hash="" url="" dir=""

    # Parse arguments properly
    for ((i = 0; i < ${#args[@]}; i++)); do
        case "${args[$i]}" in
            --commit)
                commit_hash="${args[$((i + 1))]}"
                ((i++))
                ;;
            http*)
                url="${args[$i]}"
                dir=$(basename "$url" .git)
                ;;
        esac
    done

    if [[ -z "$url" ]]; then
        echo "❌ Missing repository URL"
        return 1
    fi

    if [[ -z "$commit_hash" ]]; then
        echo "❌ Missing commit hash"
        return 1
    fi

    echo "-> Handling $url (dir: $dir)..."

    if [[ -d "$dir" && -d "$dir/.git" ]]; then
        echo "$dir exists. Pulling and checking out commit '$commit_hash'..."
        cd "$dir" || { echo "❌ Failed to cd into $dir"; return 1; }

        # Handle shallow repos
        if [[ -f .git/shallow ]]; then
            echo "Shallow clone detected. Unshallowing..."
            git fetch --unshallow || {
                echo "⚠️ Failed to unshallow. Falling back to full fetch."
                git fetch --all
            }
        else
            git fetch --all
        fi

        git checkout "$commit_hash" || {
            echo "❌ Commit hash '$commit_hash' not found."
            return 1
        }

        cd - >/dev/null || exit 1

    else
        # If dir exists but isn't a git repo or is empty: nuke it
        if [[ -d "$dir" ]]; then
            echo "$dir exists but is not a valid repo. Removing..."
            rm -rf "$dir"
        fi

        echo "$dir doesn't exist. Cloning..."
        git clone "$url" "$dir" || {
            echo "❌ Failed to clone repository."
            return 1
        }

        cd "$dir" || { echo "❌ Failed to cd into $dir"; return 1; }
        git checkout "$commit_hash" || {
            echo "❌ Commit hash '$commit_hash' not found after clone."
            return 1
        }

        cd - >/dev/null || exit 1
        echo "✅ Cloned and checked out commit '$commit_hash' into $dir"
    fi

    echo "==> Repository operation done."
}

# --- Run ---
detect_pkg_mgr
install_essentials
clone_repos "${REPOS[@]}"

# Source install scripts from repo
source "$DOTFILES_DIR/install_deps.sh" || echo "⚠️ install_deps.sh failed, continuing..."
source "$DOTFILES_DIR/install_deps_src.sh" || echo "⚠️ install_deps_src.sh failed, continuing..."
source "$DOTFILES_DIR/install.sh" || echo "⚠️ install.sh failed, continuing..."
