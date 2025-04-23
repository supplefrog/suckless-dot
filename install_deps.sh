#!/bin/bash

set -euo pipefail

# Source the package manager utilities
source "$(dirname "$0")/pkg_manager_utils.sh"

# List of packages to install
PKG_LIST="xorg xorg-dev xserver-xorg libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"

# Function to install necessary repositories (e.g., for RHEL-based systems)
ensure_repositories() {
    # Check and install repositories (if required)
    if [ -n "$REPO_CMD" ]; then
        echo "Checking for necessary repositories..."
        if ! sudo dnf repolist | grep -q "epel"; then
            echo "EPEL repo missing. Installing..."
            eval "$REPO_CMD"
        fi
    fi
}

# Function to install the required packages
install_packages() {
    echo "Installing required packages..."
    $INSTALL_CMD $PKG_LIST
}

# Main script logic
ensure_repositories
install_packages
