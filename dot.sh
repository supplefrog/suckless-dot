#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# Move configuration files to their respective locations
echo "Moving configuration files..."
sudo mv -n "$HOME/Downloads/suckless-dot/etc/*" /etc || true
sudo mv -n "$HOME/Downloads/suckless-dot/home/e/*" ~ || true
sudo mv -n "$HOME/Downloads/suckless-dot/usr/bin/*" /usr/bin || true
sudo mv -n "$HOME/Downloads/suckless-dot/usr/share/*" /usr/share || true

echo "Setting executable permission on dwm startup script..."
sudo chmod +x "$HOME/.de/dwm/de.sh"

echo "Updating font cache..."
sudo fc-cache -fv

echo "Replacing vim with nvim..."
case $PKG_MGR in
    apt) sudo apt remove -y vim vim-tiny vim-common || true ;;
    dnf|yum) sudo $PKG_MGR remove -y vim || true ;;
    pacman) sudo pacman -Rns --noconfirm vim || true ;;
esac

sudo chmod u+x /usr/bin/nvim-linux-x86_64.appimage
sudo ln -sf /usr/bin/nvim-linux-x86_64.appimage /usr/bin/vim

echo "Installation completed successfully!"
