#!/bin/bash

set -euo pipefail

# Repo variables
REPO_NAMES=("dwm" "st" "feh")
REPO_URLS=(
    "https://git.suckless.org/dwm"
    "https://git.suckless.org/st"
    "https://github.com/derf/feh.git"
)
REPO_DIRS=(
    "$HOME/.de/dwm"
    "$HOME/.de/st"
    "$HOME/.de/feh"
)
REPO_BUILDS=(
    "sudo make clean install"
    "sudo make clean install"
    "sudo make && sudo make install"
)

echo "Installing dependencies..."
source "$(dirname "$0")/install_deps.sh"
source "$(dirname "$0")/install_deps_src.sh"

echo "Copying dot files..."
source "$(dirname "$0")/dot.sh"

# Clone repositories and run integrity checks
for i in "${!REPO_NAMES[@]}"; do
    sync_git_repo "${REPO_NAMES[i]}" "${REPO_URLS[i]}" "${REPO_DIRS[i]}" "${REPO_BUILDS[i]}"
done

echo "Installation Complete!"
