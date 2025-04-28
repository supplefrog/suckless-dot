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

sync_repos() {
    local commit="" OPTIND=1
    while getopts "c:" o; do [[ $o = c ]] && commit=$OPTARG; done
    shift $((OPTIND-1))
    (( $# )) || { echo "Usage: sync_repos [-c commit] url[:dir]..."; return 1; }
    for spec; do
        # expand "url:dir" into two words or just "url"
        IFS=':' read -r url dir <<<"$spec"
        sync_repo ${commit:+-c $commit} "$url" ${dir:+$dir}
    done
}

sync_repo() {
    local commit="" OPTIND=1

    #Parse only the commit flag
    while getopts "c:" opt; do
        case $opt in
            c) commit=$OPTARG ;;
            *) echo "Usage: sync_repo [-c <commit>] <repo-url> [<directory>]"; return 1 ;;
        esac
    done
    shift $((OPTIND-1))

    # Positional args: URL and optional directory
    local url=$1
    [ -z "$url" ] && { echo "Error: no repository URL provided"; return 1; }
    local dir=${2:-$(basename -s .git "$url")}

    if [ ! -d "$dir/.git" ]; then
        # Fresh clone
        if [ -n "$commit" ]; then
            git clone "$url" "$dir" && \
            (cd "$dir" && git fetch --unshallow 2>/dev/null || true) && \
            (cd "$dir" && git checkout "$commit")
        else
            git clone --depth 1 "$url" "$dir"
        fi
    else
        # Existing repo
        (
            cd "$dir" || exit
            if [ "$(git config --get remote.origin.url)" != "$url" ]; then
                echo "Error: existing repo's origin URL differs"; return 1
            fi
            if [ -n "$commit" ]; then
                if git rev-parse --is-shallow-repository 2>/dev/null | grep -q true; then
                    git fetch --unshallow
                fi
                git fetch origin "$commit"
                git checkout "$commit"
            else
                if git rev-parse --is-shallow-repository 2>/dev/null | grep -q true; then
                    git pull --depth 1
                else
                    git pull
                fi
            fi
        )
    fi
}

# --- Run ---
detect_pkg_mgr
install_essentials
sync_repos "${REPOS[@]}"

# Source install scripts from repo
source "$DOTFILES_DIR/install_deps.sh" || echo "⚠️ install_deps.sh failed, continuing..."
source "$DOTFILES_DIR/install_deps_src.sh" || echo "⚠️ install_deps_src.sh failed, continuing..."
source "$DOTFILES_DIR/install.sh" || echo "⚠️ install.sh failed, continuing..."
