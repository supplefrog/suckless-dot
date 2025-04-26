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
            local commit_hash="" url="" dir="" branch="main"
            local tokens=($entry)

            # Parse the arguments
            for ((i = 0; i < ${#tokens[@]}; i++)); do
                case "${tokens[$i]}" in
                    --commit)
                        commit_hash="${tokens[$((i + 1))]}"
                        ((i++))
                        ;;
                    http*)
                        url="${tokens[$i]}"
                        dir=$(basename "$url" .git)
                        ;;
                esac
            done

            # Ensure that URL is provided
            if [[ -z "$url" ]]; then
                echo "❌ Missing repository URL"
                return 1
            fi

            echo "-> Handling $url (dir: $dir)..."

            # If the directory already exists and is a valid git repo
            if [[ -d "$dir" && -d "$dir/.git" ]]; then
                echo "$dir exists. Pulling..."

                cd "$dir" || { echo "❌ Failed to cd into $dir"; continue; }

                # Handle shallow repos by fetching full history
                if [[ -f .git/shallow ]]; then
                    echo "Shallow clone detected. Unshallowing..."
                    git fetch --unshallow || {
                        echo "⚠️ Failed to unshallow. Falling back to full fetch."
                        git fetch --all
                    }
                else
                    git fetch --all
                fi

                # Checkout specific commit if hash is provided
                if [[ -n "$commit_hash" ]]; then
                    git checkout "$commit_hash" || {
                        echo "❌ Commit hash '$commit_hash' not found."
                        continue
                    }
                else
                    echo "No commit hash provided. Pulling latest changes for the default branch '$branch'..."
                    git checkout "$branch" || {
                        echo "❌ Failed to checkout branch '$branch'."
                        continue
                    }
                fi

                cd - >/dev/null || exit 1

            elif [[ -d "$dir" && ! -d "$dir/.git" ]]; then
                # If the directory exists but isn't a Git repo (empty or corrupted), remove it
                echo "$dir exists but is not a valid Git repo. Removing and re-cloning..."
                rm -rf "$dir"
                git clone "$url" "$dir" || {
                    echo "❌ Failed to clone repository."
                    continue
                }
                cd "$dir" || { echo "❌ Failed to cd into $dir"; continue; }
                
                # Checkout the commit hash if provided
                if [[ -n "$commit_hash" ]]; then
                    git checkout "$commit_hash" || {
                        echo "❌ Commit hash '$commit_hash' not found."
                        continue
                    }
                else
                    git checkout "$branch" || {
                        echo "❌ Failed to checkout branch '$branch'."
                        continue
                    }
                fi

                cd - >/dev/null || exit 1
                echo "✅ Cloned and checked out commit/branch '$commit_hash' into $dir"

            else
                # If directory doesn't exist, perform a fresh clone
                echo "$dir doesn't exist. Cloning..."
                git clone "$url" "$dir" || {
                    echo "❌ Failed to clone repository."
                    continue
                }
                cd "$dir" || { echo "❌ Failed to cd into $dir"; continue; }

                # Checkout the commit hash if provided
                if [[ -n "$commit_hash" ]]; then
                    git checkout "$commit_hash" || {
                        echo "❌ Commit hash '$commit_hash' not found."
                        continue
                    }
                else
                    git checkout "$branch" || {
                        echo "❌ Failed to checkout branch '$branch'."
                        continue
                    }
                fi

                cd - >/dev/null || exit 1
                echo "✅ Cloned and checked out commit/branch '$commit_hash' into $dir"
            fi
        } &
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
