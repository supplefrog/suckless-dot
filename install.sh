#!/bin/bash

set -euo pipefail

cd ~/Downloads

if [ ! -d "suckless-dot/.git" ]; then
    echo "The 'suckless-dot' folder is missing or corrupt. Re-cloning..."
    rm -rf suckless-dot
    git clone https://github.com/supplefrog/suckless-dot.git
else
    echo "'suckless-dot' folder is valid. Proceeding..."
fi

cd suckless-dot

echo "Moving configuration files..."
sudo mv -n etc/* /etc || true
sudo mv -n home/e/* ~ || true
sudo mv -n usr/* /usr || true

echo "Updating font cache..."
sudo fc-cache -fv

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    INSTALL="sudo apt install -y"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    INSTALL="sudo dnf install -y"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    INSTALL="sudo yum install -y"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL="sudo pacman -Syu --noconfirm"
else
    echo "Unsupported package manager."
    exit 1
fi

echo "Using package manager: $PKG_MGR"

echo "Installing required packages..."
$INSTALL \
    xorg \
    xorg-xinit \
    xorg-xrandr \
    xorg-xdpyinfo \
    xorg-fonts-100dpi \
    xorg-fonts-75dpi \
    xorg-fonts-misc \
    libcurl-devel \
    libX11-devel \
    libXft-devel \
    libXinerama-devel \
    libXrandr-devel \
    libxcb-devel \
    libXt-devel \
    gcc \
    git \
    make \
    pkgconf \
    dmenu \
    vifm

sudo chmod +x update_git_version.sh
./update_git_version.sh

echo "Installing dwm..."
cd ~/de/dwm
make clean install

echo "Installing st..."
cd ~/de/st
make clean install

echo "Installing feh..."
cd ~/de/feh
make && sudo make install

echo "Replacing vim with nvim..."
case $PKG_MGR in
    apt|dnf|yum) sudo $PKG_MGR remove -y vim ;;
    pacman) sudo pacman -Rns --noconfirm vim ;;
esac

sudo chmod u+x nvim-linux-x86_64.appimage
sudo ln -sf /usr/bin/nvim-linux-x86_64.appimage /usr/bin/vim

echo "Setting executable permission on dwm startup script..."
sudo chmod +x ~/de/dwm/de.sh

echo "Installation completed successfully!"
