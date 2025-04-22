#!/bin/bash

set -euo pipefail

cd ~/Downloads

echo "Downloading repository..."
curl -L https://github.com/supplefrog/suckless-dot/archive/refs/heads/main.zip -o suckless-dot.zip

echo "Unzipping the repository..."
unzip suckless-dot.zip -d suckless-dot

cd suckless-dot/suckless-dot-main

echo "Moving configuration files..."
sudo mv etc/* /etc
sudo mv home/e/* ~
sudo mv usr/* /usr

echo "Updating font cache..."
sudo fc-cache -fv

echo "Installing required packages..."
sudo yum install -y \
    xorg-x11-server-Xorg \
    xorg-x11-xinit \
    xorg-x11-utils \
    xorg-x11-fonts-100dpi \
    xorg-x11-fonts-75dpi \
    xorg-x11-fonts-misc \
    libcurl-devel \
    libX11-devel \
    libXft-devel \
    libXinerama-devel \
    libXrandr-devel \
    libxcb-devel \
    libXt-devel \
    feh \
    git \
    gcc \
    make \
    pkgconfig

echo "Installing dwm..."
cd ~/de/dwm
make clean install

echo "Installing st..."
cd ~/de/st
make clean install

echo "Installing feh..."
cd ~/de/feh
make && sudo make install

echo "Setting executable permission on dwm startup script..."
sudo chmod +x ~/de/dwm/de.sh

echo "Installation completed successfully!"

