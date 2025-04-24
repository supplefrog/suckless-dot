#!/bin/bash

set -euo pipefail

# Define base dotfiles directory
DOTFILES="$HOME/Downloads/suckless-dot"

detect_pkg_mgr

# Move user dotfiles (excluding . and ..)
echo "Copying dotfiles to home directory..."
shopt -s dotglob nullglob
for file in "$DOTFILES/home/e/"*; do
    filename="$(basename "$file")"
    if [ ! -e "$HOME/$filename" ]; then
        cp -r "$file" "$HOME/"
        echo "Copied: $filename"
    else
        echo "Skipped (already exists): $filename"
    fi
done
shopt -u dotglob nullglob

echo "Installing scripts to /usr/bin..."
sudo cp -n "$DOTFILES/usr/bin/"* /usr/bin/

echo "Installing shared files to /usr/share..."
sudo cp -rn "$DOTFILES/usr/share/"* /usr/share/

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

echo "Installation completed successfully!"
