#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# Move user dotfiles (excluding . and ..)
echo "Copying dotfiles to corresponding directories..."

# Enable dotglob to include hidden files
shopt -s dotglob

# List of directories to copy
for dir in feh dwm st; do
    src="$DOTFILES_DIR/home/e/.de/$dir"
    dest="$HOME/.de/$dir"

    # Loop through files in the source directory
    for file in "$src"/*; do
        filename="$(basename "$file")"
        target="$dest/$filename"

        # If the target file exists, skip it (we don't want to overwrite existing files)
        if [ -e "$target" ]; then
            echo "Skipping existing file: $target"
        else
            # If the target file does not exist, copy it forcefully
            cp -f "$file" "$target"
            echo "Copied: $target"
        fi
    done
done

# Disable dotglob
shopt -u dotglob

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
