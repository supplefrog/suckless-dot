#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# Move user dotfiles (excluding . and ..)
echo "Copying dotfiles to corresponding directories..."

# Enable dotglob to include hidden files (dotfiles)
shopt -s dotglob

# Recursively copy all files from ~/.dotfiles/.de to ~/.de, including dotfiles
echo "Copying dotfiles to corresponding directories..."

cp -rf "$DOTFILES_DIR/home/e/"* "$HOME/"

# Disable dotglob to revert to default behavior
shopt -u dotglob

echo "Dot files transferred!"

echo "Installing scripts to /usr/bin..."
sudo cp -n "$DOTFILES_DIR/usr/bin/"* /usr/bin/

echo "Installing shared files to /usr/share..."
sudo cp -rn "$DOTFILES_DIR/usr/share/"* /usr/share/

echo "Setting executable permission on dwm startup script..."
sudo chmod +x "$HOME/.de/dwm/de.sh"

echo "Updating font cache..."
sudo fc-cache -fv

echo "Replacing Vim with Neovim..."
case $PKG_MGR in
    apt) sudo apt remove -y vim vim-tiny vim-common || true ;;
    dnf|yum) sudo $PKG_MGR remove -y vim || true ;;
    pacman) sudo pacman -Rns --noconfirm vim || true ;;
esac

sudo chmod u+x /usr/bin/nvim-linux-x86_64.appimage
sudo ln -sf /usr/bin/nvim-linux-x86_64.appimage /usr/bin/vim

echo "Dot files transfered!"
