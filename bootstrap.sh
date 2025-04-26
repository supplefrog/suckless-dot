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
    local entries=("$@")

    for entry in "${entries[@]}"; do
        {
            local branch url dir
            branch=""
            url=""
            dir=""
            
            # Parse the entry input
            while [[ "$#" -gt 0 ]]; do
                case "$1" in
                    --branch)
                        branch="$2"
                        shift 2
                        ;;
                    *)
                        url="$1"
                        dir=$(basename "$url" .git)  # Default to the repo name as directory
                        shift
                        ;;
                esac
            done

            # Ensure both branch and URL are provided
            if [[ -z "$branch" || -z "$url" ]]; then
                echo "Usage: clone_repos --branch <branchname> <repo_url>"
                return 1
            fi

            echo "-> Handling $url (dir: $dir, branch: $branch)..."

            # Check if the directory exists and is a git repository
            if [[ -d "$dir" && -d "$dir/.git" ]]; then
                echo "$dir repo exists. Checking branch '$branch'..."

                # Change to the repo directory
                cd "$dir" || { echo "Failed to cd into $dir"; continue; }

                # Check if the branch exists locally
                if git show-ref --verify --quiet "refs/heads/$branch"; then
                    # Pull the latest changes for the specified branch
                    git fetch --depth 1 origin "$branch" && git checkout "$branch" && git pull --depth 1 --rebase origin "$branch"
                    echo "✅ Pulled the latest changes for branch '$branch' in $dir"
                else
                    echo "⚠️ Branch '$branch' does not exist locally. Creating and checking out..."
                    git checkout -b "$branch" origin/"$branch"
                    echo "✅ Created and checked out branch '$branch' in $dir"
                fi

                # Go back to the original directory
                cd - || exit 1

            else
                echo "$dir doesn't exist. Cloning repository..."

                # Clone the repository with the specified branch
                git clone --depth 1 --branch "$branch" "$url" "$dir"
                echo "✅ Successfully cloned $dir and checked out branch '$branch'"
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
