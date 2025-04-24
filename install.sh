#!/bin/bash

set -euo pipefail

source "$DOTFILES_DIR/dot.sh"

# Build suckless software
echo "==> Building repositories..."
REPO_DIRS=(
    "$HOME/.de/dwm"
    "$HOME/.de/st"
    "$HOME/.de/feh"
)

BUILD_CMDS=(
    "sudo make clean install"
    "sudo make clean install"
    "sudo make && sudo make install"
)

for i in "${!REPO_DIRS[@]}"; do
    echo "Building: ${REPO_DIRS[$i]}"
    cd "${REPO_DIRS[$i]}"
    eval "${BUILD_CMDS[$i]}"
done

echo "Build and install complete!"
