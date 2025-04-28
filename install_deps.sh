#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# List of packages to install
PKG_LIST="epel-release xorg-x11-server-utils xorg-x11-server-devel libcurl-devel libx11-devel libxft-devel libxinerama-devel libxrandr-devel libxcb-devel libXt-devel gcc git make pkg-config dmenu vifm"
PKG_LIST="xorg xorg-dev libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"
PKG_LIST="xorg-server xorg-xinit libcurl-devel imlib2 libx11 libxft libxinerama libxrandr libxcb libxt gcc git make pkg-config dmenu vifm"

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST || echo "Warning: Some packages may have failed to install."
