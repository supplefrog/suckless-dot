#!/bin/bash

set -euo pipefail

# --- Config ---
DOTFILES_DIR="$HOME/.dotfiles"
REPOS=(
    "https://github.com/uint23/sxwm.git" "$HOME/.de/sxwm"
    "https://github.com/derf/feh.git" "$HOME/.de/feh"
    "https://github.com/sergei-grechanik/st-graphics.git" "$HOME/.de/st-graphics"
    "https://github.com/supplefrog/suckless-dot.git" "$DOTFILES_DIR"
)

# --- Functions ---
detect_pkg_mgr() {
    if command -v apt &> /dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="sudo apt install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &> /dev/null; then
        PKG_MGR="yum"
        INSTALL_CMD="sudo yum install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -Syu --noconfirm"
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

  # 1) Parse only the -c <commit> flag
  while getopts "c:" opt; do
    case $opt in
      c) commit=$OPTARG ;;
      *) echo "Usage: sync_repos [-c <commit>] <url> [<dir>] …"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # 2) Ensure at least one repo spec
  if (( $# == 0 )); then
    echo "Error: provide at least one <url> [<dir>]" >&2
    return 1
  fi

  # 3) Loop over each url [+ optional dir]
  while (( $# )); do
    url=$1; shift
    # If next arg doesn't start with http://, https://, ssh://, assume it's a dir
    if [[ $# -gt 0 && ! $1 =~ ^(https?|ssh):// ]]; then
      dir=$1; shift
    else
      dir=""
    fi

    # 4) Dispatch to sync_repo in background for parallelism ⚡
    if [[ -n $commit ]]; then
      sync_repo -c "$commit" "$url" ${dir:+"$dir"} &
    else
      sync_repo "$url" ${dir:+"$dir"} &
    fi
  done

  # 5) Wait for all background jobs to complete ⚡
  wait
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
if [[ $PKG_MGR == "apt" ]]; then
    source "$DOTFILES_DIR/ubuntu_cfg.sh" || echo "⚠️ ubuntu_cfg.sh failed, continuing..."
fi
