#!/bin/bash

set -euo pipefail

detect_pkg_mgr

# Move user dotfiles (excluding . and ..)
echo "Copying dotfiles to corresponding directories..."

shopt -s dotglob nullglob

# Function to copy dotfiles
copy_dotfiles() {
    local src="$1"
    local dest="$2"

    for file in "$src"/*; do
        local filename="$(basename "$file")"
        local target="$dest/$filename"

        if [ -d "$file" ]; then
            mkdir -p "$target"
            copy_dotfiles "$file" "$target"
        elif [ ! -e "$target" ]; then
            cp -r "$file" "$target"
            echo "Copied: $target"
        else
            echo "Skipped (already exists): $target"
        fi
    done
}

# Copy files into their respective directories
copy_dotfiles "$DOTFILES_DIR/home/e/.de/feh" "$HOME/.de/feh"
copy_dotfiles "$DOTFILES_DIR/home/e/.de/dwm" "$HOME/.de/dwm"
copy_dotfiles "$DOTFILES_DIR/home/e/.de/st" "$HOME/.de/st"

shopt -u dotglob nullglob

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
