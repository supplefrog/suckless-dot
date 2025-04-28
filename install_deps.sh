#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# Set PKG_LIST based on the package manager
case "$PKG_MGR" in
    "apt")
        PKG_LIST="xorg xorg-dev libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev"
        ;;
    "dnf" | "yum")
        PKG_LIST="epel-release xorg-x11-server-utils xorg-x11-server-devel libcurl-devel libx11-devel libxft-devel libxinerama-devel libxrandr-devel libxcb-devel libXt-devel"
        ;;
    "pacman")
        PKG_LIST="xorg-server xorg-xinit libcurl-devel imlib2 libx11 libxft libxinerama libxrandr libxcb libxt"
        ;;
    *)
        echo "Unsupported package manager: $PKG_MGR"
        exit 1
        ;;
esac

# Append common packages for all package managers
PKG_LIST="$PKG_LIST gcc git make pkg-config dmenu vifm"

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST || echo "Warning: Some packages may have failed to install."
