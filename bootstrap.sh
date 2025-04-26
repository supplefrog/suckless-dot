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
            local branch="" url="" dir="" full_clone="false"
            local tokens=($entry)

            # Manual parsing to support optional --full flag
            for ((i = 0; i < ${#tokens[@]}; i++)); do
                case "${tokens[$i]}" in
                    --branch)
                        branch="${tokens[$((i + 1))]}"
                        ((i++))
                        ;;
                    --unshallow)
                        full_clone="true"
                        ;;
                    http*)
                        url="${tokens[$i]}"
                        dir=$(basename "$url" .git)
                        ;;
                esac
            done

            if [[ -z "$branch" || -z "$url" ]]; then
                echo "❌ Usage: clone_repos --branch <branch> [--full] <repo_url>"
                return 1
            fi

            echo "-> Handling $url (dir: $dir, branch: $branch)..."

            if [[ -d "$dir" && -d "$dir/.git" ]]; then
                echo "$dir exists. Pulling '$branch'..."

                cd "$dir" || { echo "❌ Failed to cd into $dir"; continue; }

                if git show-ref --verify --quiet "refs/heads/$branch"; then
                    if [[ "$full_clone" == "true" ]]; then
                        git fetch origin "$branch" && git checkout "$branch" && git pull --rebase origin "$branch"
                    else
                        git fetch --depth 1 origin "$branch" && \
                        git checkout "$branch" && \
                        git pull --depth 1 --rebase origin "$branch" || {
                            echo "⚠️ Shallow pull failed, doing full fetch..."
                            git fetch --unshallow && git pull --rebase origin "$branch"
                        }
                    fi
                else
                    git fetch origin "$branch" && git checkout -b "$branch" origin/"$branch"
                fi

                cd - >/dev/null || exit 1

            else
                echo "$dir doesn't exist. Cloning..."

                if [[ "$full_clone" == "true" ]]; then
                    git clone --single-branch --branch "$branch" "$url" "$dir"
                else
                    git clone --depth 1 --single-branch --branch "$branch" "$url" "$dir" || {
                        echo "⚠️ Shallow clone failed. Trying full clone..."
                        git clone --single-branch --branch "$branch" "$url" "$dir"
                    }
                fi
                echo "✅ Cloned $branch into $dir"
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
