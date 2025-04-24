#!/bin/bash

# Detect package manager and define install command
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

sync_git_repo() {
    NAME="$1"
    REPO_URL="$2"
    DEST_DIR="$3"
    BUILD_CMD="$4"  # Optional command to run after pulling
    LAST_BUILD_FILE="$DEST_DIR/.last_build_commit"
    
    # List of files and directories to exclude (dotfiles and folders)
    EXCLUDE_FILES=(
        "config.def.h"
        "config.h"
        "bg"
        # Add any other files or directories to exclude here
    )

    echo "==> Syncing $NAME from $REPO_URL"

    # Clone repository if it doesn't exist
    if [ ! -d "$DEST_DIR/.git" ]; then
        echo "$NAME not found. Cloning fresh copy..."
        git clone "$REPO_URL" "$DEST_DIR"
    fi

    cd "$DEST_DIR"

    # Enable sparse-checkout
    git sparse-checkout init --cone

    # Add the exclude patterns for dotfiles and directories to sparse-checkout
    for file in "${EXCLUDE_FILES[@]}"; do
        git sparse-checkout set --skip-worktree "$file"
    done

    # Ensure remote URL is correct
    CURRENT_REMOTE=$(git config --get remote.origin.url)
    if [[ "$CURRENT_REMOTE" != "$REPO_URL" ]]; then
        echo "Remote URL mismatch for $NAME. Fixing..."
        git remote set-url origin "$REPO_URL"
    fi

    echo "Fetching latest changes..."
    git fetch origin

    echo "Checking for file corruption..."
    CORRUPT_FILES=$(git fsck --full 2>&1 | grep 'missing blob' | awk '{ print $3 }')
    if [[ -n "$CORRUPT_FILES" ]]; then
        echo "Corrupt or missing files found in $NAME. Attempting to restore..."
        for hash in $CORRUPT_FILES; do
            FILE=$(git rev-list --all --objects | grep "$hash" | awk '{print $2}')
            if [[ -n "$FILE" ]]; then
                echo "Restoring $FILE..."
                git checkout origin/HEAD -- "$FILE"
            fi
        done
    else
        echo "No corruption detected in $NAME."
    fi

    # Fetch latest commit
    LATEST_COMMIT=$(git rev-parse origin/HEAD)

    # Handle build logic (only rebuild if the commit has changed)
    if [[ -n "$BUILD_CMD" ]]; then
        # Check if the commit has been built previously
        if [[ -f "$LAST_BUILD_FILE" ]] && grep -q "$LATEST_COMMIT" "$LAST_BUILD_FILE"; then
            echo "$NAME is already built at $LATEST_COMMIT. Skipping rebuild."
            return
        fi

        echo "Checking out latest commit for $NAME..."
        git checkout "$LATEST_COMMIT"

        echo "Running build for $NAME..."
        eval "$BUILD_CMD"

        # Update the last build commit file
        echo "$LATEST_COMMIT" > "$LAST_BUILD_FILE"
    else
        # Just pull the latest changes without rebuilding
        echo "Pulling latest changes for $NAME..."
        git pull --rebase --autostash || echo "Pull failed for $NAME, but repo integrity is OK."
    fi
}


# Run detection immediately in bootstrap.sh
detect_pkg_mgr

echo "Using package manager: $PKG_MGR"
echo "Installing essential packages (git, curl)..."

if ! command -v git &> /dev/null; then
    echo "Git not found. Installing Git..."
    $INSTALL_CMD git
fi

if ! command -v curl &> /dev/null; then
    echo "Curl not found. Installing Curl..."
    $INSTALL_CMD curl
fi

sync_git_repo "suckless-dot" "https://github.com/supplefrog/suckless-dot.git" "$HOME/Downloads/suckless-dot" ""
source "$(dirname "$0")/install.sh"
