#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pkg_manager_utils.sh"

detect_pkg_manager

# Install only essentials to clone the full repo
$INSTALL_CMD git curl

REPO_URL="https://github.com/supplefrog/suckless-dot.git"
CLONE_DIR="$HOME/Downloads/suckless-dot"

if [ ! -d "$CLONE_DIR/.git" ]; then
    echo "Cloning repo..."
    git clone "$REPO_URL" "$CLONE_DIR"
else
    echo "Repo already exists, skipping clone."
fi

cd "$CLONE_DIR"
chmod +x update_deps.sh
./update_deps.sh
