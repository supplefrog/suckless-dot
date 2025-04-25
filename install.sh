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
    
    # Apply patches in a specific order for 'st' repository
    if [[ "$REPO" == *"st"* ]]; then
        for PATCH in st-anysize-20220718-baa9357.diff st-scrollback-ringbuffer-0.9.2.diff st-scrollback-float-0.9.2.diff; do
            if [[ -f "$PATCH" ]]; then
                echo "Applying patch: $PATCH"
                patch -p1 < "$PATCH" -N
            fi
        done
        cp config.def.h config.h
    else
        # Apply patches in alphabetical order for other repositories
        for PATCH in *.diff; do
            if [[ -f "$PATCH" ]]; then
                echo "Applying patch: $PATCH"
                patch -p1 < "$PATCH" -N
            fi
        done
    fi
    
    cp config.def.h config.h || echo "⚠️ cp config.def.h failed, continuing..."
    make clean
    eval "$CMD"
done

echo "✅ Build and install complete!"
