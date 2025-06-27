#!/bin/bash

set -euo pipefail

source "$DOTFILES_DIR/dot.sh"

# Build suckless software
echo "==> Building repositories..."
REPO_DIRS=(
    "$HOME/.de/sxwm"
    "$HOME/.de/st-graphics"
    "$HOME/.de/feh"
)

BUILD_CMDS=(
    "sudo make clean install"
    "sudo make clean install"
    "sudo make && sudo make install"
)

pip3 install git+https://github.com/Notenlish/anifetch.git

for i in "${!REPO_DIRS[@]}"; do
    REPO="${REPO_DIRS[$i]}"
    CMD="${BUILD_CMDS[$i]}"
    
    echo "==> Building: $REPO"
    
    cd "$REPO"
    
    for PATCH in *.diff; do
        if [[ -f "$PATCH" ]]; then
            echo "Applying patch: $PATCH"
            patch -p1 < "$PATCH" -N || echo ""
        fi
    done
    
    cp config.def.h config.h || echo "⚠️ cp config.def.h failed, continuing..."
    make clean
    eval "$CMD"
done

echo "✅ Build and install complete!"
