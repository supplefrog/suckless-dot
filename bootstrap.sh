#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/pkg_manager_utils.sh"
source "$(dirname "$0")/git_sync_utils.sh"

install_essential_packages

# Clone repositories and run integrity checks
REPO_NAMES=("suckless-dot" "dwm" "st" "feh")
REPO_URLS=(
    "https://github.com/supplefrog/suckless-dot.git"
    "https://git.suckless.org/dwm"
    "https://git.suckless.org/st"
    "https://github.com/derf/feh.git"
)
REPO_DIRS=(
    "$HOME/Downloads/suckless-dot"
    "$HOME/DE/dwm"
    "$HOME/DE/st"
    "$HOME/DE/feh"
)
REPO_BUILDS=(
    ""  # No build for suckless-dot
    "sudo make clean install"
    "sudo make clean install"
    "sudo make clean install"
)

for i in "${!REPO_NAMES[@]}"; do
    sync_git_repo "${REPO_NAMES[i]}" "${REPO_URLS[i]}" "${REPO_DIRS[i]}" "${REPO_BUILDS[i]}"
done

echo "Running install_deps.sh..."
source "$(dirname "$0")/install_deps.sh"

echo "Running install.sh..."
source "$(dirname "$0")/install.sh"
