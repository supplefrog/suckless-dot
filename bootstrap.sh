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

clone_repo() {
    local url="$1" dir="$2" commit_hash="$3" branch="main"

    # If directory exists but isn't a git repo, remove it
    if [[ -d "$dir" && ! -d "$dir/.git" ]]; then
        echo "$dir exists but isn't a valid git repo. Re-cloning..."
        rm -rf "$dir"
    fi

    # Determine depth based on commit_hash presence
    local depth_flag=""
    if [[ -z "$commit_hash" ]]; then
        depth_flag="--depth 1"  # Shallow clone when no commit hash is provided
    fi

    # Clone repo with appropriate depth
    if [[ ! -d "$dir/.git" ]]; then
        echo "Cloning $url into $dir..."
        git clone $depth_flag "$url" "$dir" || { echo "❌ Clone failed"; return; }
    fi

    cd "$dir" || { echo "❌ Failed to cd into $dir"; return; }

    # Fetch all updates and checkout commit/branch
    git fetch --all || { echo "❌ Fetch failed"; return; }

    # If the repository is shallow, try to unshallow it
    if [[ -f .git/shallow ]]; then
        echo "Shallow clone detected. Unshallowing..."
        git fetch --unshallow || { echo "⚠️ Failed to unshallow. Proceeding with shallow fetch."; }
    fi

    # Try checking out the provided commit hash, or the default branch if no commit is specified
    if [[ -n "$commit_hash" ]]; then
        git checkout "$commit_hash" || { echo "❌ Commit hash '$commit_hash' not found"; return; }
    else
        # Automatically detect the default branch
        local default_branch
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        echo "Checking out the default branch '$default_branch'..."
        git checkout "$default_branch" || { echo "❌ Failed to checkout branch '$default_branch'"; return; }
    fi

    cd - >/dev/null
    echo "✅ Handled $dir"
}

clone_repos() {
    echo "==> Handling repositories..."
    local entries=("$@")
    
    for entry in "${entries[@]}"; do
        {
            # Initialize variables
            local commit_hash="" url="" dir="$(pwd)"
            local tokens=($entry)

            # Parse arguments: --commit, url, and dir
            for ((i = 0; i < ${#tokens[@]}; i++)); do
                case "${tokens[$i]}" in
                    --commit) commit_hash="${tokens[$((i + 1))]}"; ((i++)) ;;  # Commit hash comes first
                    *) url="${tokens[$i]}"; dir=$(basename "$url" .git) ;;  # Handle URL
                esac
            done

            # Ensure URL is provided
            if [[ -z "$url" ]]; then
                echo "❌ Missing repository URL"; continue
            fi

            # Call clone_repo function in parallel
            clone_repo "$url" "$dir" "$commit_hash" &
        } 
    done

    # Wait for all background processes to finish
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
