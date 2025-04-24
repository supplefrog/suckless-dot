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
    REPO="${REPO_DIRS[$i]}"
    CMD="${BUILD_CMDS[$i]}"

    echo "==> Building: $REPO"
    cd "$REPO"
    eval "$CMD"
done

echo "✅ Build and install complete!"
