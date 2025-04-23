#!/bin/bash

set -euo pipefail

# Detect package manager
PKG_MGR=""
INSTALL_CMD=""
PKG_LIST=""
REPO_CMD=""

if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
    PKG_LIST="xorg xorg-dev xserver-xorg libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -Syu --noconfirm"
    PKG_LIST="xorg xorg-xinit xorg-server libcurl-compat libimlib2 libx11 libxft libxinerama libxrandr libxcb libxt gcc git make pkgconf dmenu vifm"
    # Ensure yay (AUR helper) is available for Arch-based systems
    if ! command -v yay &> /dev/null; then
        echo "AUR helper (yay) not found. Installing yay..."
        sudo pacman -S --noconfirm yay
    fi
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    INSTALL_CMD="sudo dnf install -y"
    PKG_LIST="xorg-x11-server-Xorg imlib2-devel libcurl-devel libX11-devel libXft-devel libXinerama-devel libXrandr-devel libxcb-devel libXt-devel gcc git make pkgconf dmenu vifm"
    REPO_CMD="sudo dnf install -y epel-release"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    INSTALL_CMD="sudo yum install -y"
    PKG_LIST="xorg-x11-server-Xorg imlib2-devel libcurl-devel libX11-devel libXft-devel libXinerama-devel libXrandr-devel libxcb-devel libXt-devel gcc git make pkgconf dmenu vifm"
    REPO_CMD="sudo yum install -y epel-release"
else
    echo "Unsupported package manager."
    exit 1
fi

echo "Using package manager: $PKG_MGR"

# Ensure EPEL repo is installed for RHEL-based systems (if needed)
if [ -n "$REPO_CMD" ]; then
    echo "Checking for necessary repositories..."
    if ! sudo dnf repolist | grep -q "epel"; then
        echo "EPEL repo missing. Installing..."
        eval "$REPO_CMD"
    fi
fi

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST

REPO_DIR="~/Downloads/suckless-dot"
REPO_URL="https://github.com/supplefrog/suckless-dot.git"

sudo chmod +x update_deps_src.sh
./update_deps_src.sh

check_repo_integrity() {
    cd "$REPO_DIR"
    # Check if it’s a valid git repo
    git rev-parse --is-inside-work-tree &>/dev/null || return 1

    # Check if remote matches expected
    git_remote=$(git config --get remote.origin.url)
    [[ "$git_remote" == "$REPO_URL" ]] || return 1

    # Check for file integrity issues
    git fsck --full &>/dev/null || return 1

    # Check for uncommitted changes (optional, can skip if you allow local edits)
    if ! git diff --quiet || ! git diff --cached --quiet; then
        return 1
    fi

    return 0
}

if [ ! -d "$REPO_DIR/.git" ] || ! check_repo_integrity; then
    echo "The '$REPO_DIR' folder is missing, corrupt, or outdated. Re-cloning..."
    rm -rf "$REPO_DIR"
    git clone "$REPO_URL"
else
    echo "'$REPO_DIR' folder is valid. Proceeding..."
fi

cd "$REPO_DIR"

echo "Moving configuration files..."
sudo mv -n etc/* /etc || true
sudo mv -n home/e/* ~ || true
sudo mv -n usr/bin/* /usr/bin || true
sudo mv -n usr/share/* /usr/share || true

echo "Updating font cache..."
sudo fc-cache -fv

echo "Installing dwm..."
cd ~/de/dwm
sudo make clean install

echo "Installing st..."
cd ~/de/st
sudo make clean install

echo "Installing feh..."
cd ~/de/feh
make && sudo make install

echo "Replacing vim with nvim..."
case $PKG_MGR in
    apt) sudo apt remove -y vim vim-tiny vim-common || true ;;
    dnf|yum) sudo $PKG_MGR remove -y vim || true ;;
    pacman) sudo pacman -Rns --noconfirm vim || true ;;
esac

sudo chmod u+x /usr/bin/nvim-linux-x86_64.appimage
sudo ln -sf /usr/bin/nvim-linux-x86_64.appimage /usr/bin/vim

echo "Setting executable permission on dwm startup script..."
sudo chmod +x ~/de/dwm/de.sh

echo "Installation completed successfully!"
