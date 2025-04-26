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
    echo "==> Cloning repositories..."
    local entries=("$@")

    for entry in "${entries[@]}"; do
        {
            local URL DIR BRANCH
            read -r URL DIR BRANCH <<< "$entry"

            # Default to 'master' if no branch is specified
            if [[ -z "$BRANCH" ]]; then
                BRANCH="master"
            fi

            if [[ -z "$DIR" ]]; then
                DIR=$(basename "$URL" .git)
            fi

            echo "-> Handling $URL (dir: $DIR, branch: $BRANCH)..."

            if [[ -d "$DIR" && -d "$DIR/.git" ]]; then
                echo "$DIR repo exists. Pulling latest changes..."

                # Get the commit hash for the specified branch
                local COMMIT_HASH
                COMMIT_HASH=$(git -C "$DIR" rev-parse "$BRANCH")

                # Now use the commit hash for git pull
                if (cd "$DIR" && git fetch && git checkout "$BRANCH" && git pull --rebase origin "$BRANCH"); then
                    echo "✅ Successfully pulled latest from branch '$BRANCH' (commit: $COMMIT_HASH) in $DIR"
                else
                    echo "❌ Pull failed in $DIR"
                fi

            elif [[ -d "$DIR" ]]; then
                echo "⚠️ $DIR exists but is not a git repo. Reinitializing..."
                if (cd "$DIR" && git init && git remote add origin "$URL" && git pull --rebase origin "$BRANCH"); then
                    echo "✅ Reinitialized and pulled: $DIR"
                else
                    echo "❌ Reinit failed in $DIR"
                fi

            else
                echo "Cloning into $DIR..."
                if git clone --branch "$BRANCH" --single-branch "$URL" "$DIR"; then
                    echo "✅ Successfully cloned: $DIR"
                else
                    echo "❌ Clone failed: $URL"
                fi
            fi
        } &
    done

    wait
    echo "==> All repository operations done."
}

# --- Run ---
detect_pkg_mgr
install_essentials
clone_repos "${REPOS[@]}"

# Source install scripts from repo
source "$DOTFILES_DIR/install_deps.sh" || echo "⚠️ install_deps.sh failed, continuing..."
source "$DOTFILES_DIR/install_deps_src.sh" || echo "⚠️ install_deps_src.sh failed, continuing..."
source "$DOTFILES_DIR/install.sh" || echo "⚠️ install.sh failed, continuing..."
