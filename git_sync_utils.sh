sync_git_repo() {
    NAME="$1"
    REPO_URL="$2"
    DEST_DIR="$3"
    BUILD_CMD="$4"  # Optional command to run after pulling
    LAST_BUILD_FILE="$DEST_DIR/.last_build_commit"

    echo "==> Syncing $NAME from $REPO_URL"

    if [ ! -d "$DEST_DIR/.git" ]; then
        echo "$NAME not found. Cloning fresh copy..."
        git clone "$REPO_URL" "$DEST_DIR"
    fi

    cd "$DEST_DIR"

    # Ensure correct remote
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

    LATEST_COMMIT=$(git rev-parse origin/HEAD)

    # For repos with build logic (e.g., dwm/st/feh), avoid rebuild if commit is same
    if [[ -n "$BUILD_CMD" ]]; then
        if [[ -f "$LAST_BUILD_FILE" ]] && grep -q "$LATEST_COMMIT" "$LAST_BUILD_FILE"; then
            echo "$NAME is already built at $LATEST_COMMIT. Skipping rebuild."
            return
        fi

        echo "Checking out latest commit of $NAME..."
        git checkout "$LATEST_COMMIT"

        echo "Running build for $NAME..."
        eval "$BUILD_CMD"

        echo "$LATEST_COMMIT" > "$LAST_BUILD_FILE"
    else
        echo "Checking out latest for $NAME..."
        git checkout "$LATEST_COMMIT"
        git pull --rebase --autostash || echo "Pull failed for $NAME, but repo integrity is OK."
    fi
}
