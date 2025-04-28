#!/bin/bash

set -euo pipefail

# Detect the package manager and set INSTALL_CMD
detect_pkg_mgr

# Set PKG_LIST based on the package manager
case "$PKG_MGR" in
    "apt")
        PKG_LIST="build-essential libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev libcurl4-openssl-dev libimlib2-dev libfreetype6-dev fontconfig"
        ;;
    "dnf" | "yum")
        PKG_LIST="gcc make pkg-config libX11-devel libXft-devel libXinerama-devel libXrandr-devel libxcb-devel libXt-devel libcurl-devel imlib2-devel freetype-devel fontconfig-devel"
        INSTALL_CMD="$PKG_MGR groupinstall 'Development Tools' & $INSTALL_CMD"
        ;;
    "pacman")
        PKG_LIST="base-devel libx11 libxft libxinerama libxrandr libxcb libxt curl imlib2 freetype2 fontconfig"
        ;;
esac

# Append common packages for all package managers
PKG_LIST="$PKG_LIST gcc make pkg-config git dmenu vifm"

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST || echo "Warning: Some packages may have failed to install."
