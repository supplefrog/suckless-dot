#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# List of packages to install
PKG_LIST="epel-release xorg xorg-dev xserver-xorg libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"

for pkg in $PKG_LIST; do
    echo "Checking if $pkg is already installed..."
    
    # Check if the package is already installed
    if dpkg -l | grep -q "^ii\s\+$pkg"; then
        echo "$pkg is already installed, skipping."
    else
        echo "$pkg not found, installing..."
        if ! $INSTALL_CMD "$pkg"; then
            echo "Warning: Failed to install $pkg, continuing..."
        fi
    fi
done
