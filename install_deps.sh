#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# List of packages to install
PKG_LIST="epel-release xorg xorg-dev xserver-xorg libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST
