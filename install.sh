#!/bin/bash

set -euo pipefail

# Source functions from an external script
source "$(dirname "$0")/git_sync_utils.sh"
source "$(dirname "$0")/check_package_manager.sh"  # Assuming this is a separate file for package manager checks

# Define repositories
REPO_NAMES=("suckless-dot" "dwm" "st" "feh")
REPO_URLS=(
    "https://github.com/supplefrog/suckless-dot.git"
    "https://git.suckless.org/dwm"
    "https://git.suckless.org/st"
    "https://github.com/derf/feh.git"
)
REPO_DIRS=(
    "$HOME/Downloads/suckless-dot"
    "$HOME/DE/dwm"
    "$HOME/DE/st"
    "$HOME/DE/feh"
)
REPO_BUILDS=(
    ""  # No build for suckless-dot
    "sudo make clean install"
    "sudo make clean install"
    "sudo make clean install"
)

# Ensure required dependencies are installed
check_and_install_packages

# Sync git repositories (handling cloning and integrity checks)
for i in "${!REPO_NAMES[@]}"; do
    sync_git_repo "${REPO_NAMES[i]}" "${REPO_URLS[i]}" "${REPO_DIRS[i]}" "${REPO_BUILDS[i]}"
done

# Move configuration files to their respective locations
echo "Moving configuration files..."
sudo mv -n "$HOME/Downloads/suckless-dot/etc/*" /etc || true
sudo mv -n "$HOME/Downloads/suckless-dot/home/e/*" ~ || true
sudo mv -n "$HOME/Downloads/suckless-dot/usr/bin/*" /usr/bin || true
sudo mv -n "$HOME/Downloads/suckless-dot/usr/share/*" /usr/share || true

# Update font cache
echo "Updating font cache..."
sudo fc-cache -fv

# Replacing vim with nvim
echo "Replacing vim with nvim..."
case $PKG_MGR in
    apt) sudo apt remove -y vim vim-tiny vim-common || true ;;
    dnf|yum) sudo $PKG_MGR remove -y vim || true ;;
    pacman) sudo pacman -Rns --noconfirm vim || true ;;
esac

sudo chmod u+x /usr/bin/nvim-linux-x86_64.appimage
sudo ln -sf /usr/bin/nvim-linux-x86_64.appimage /usr/bin/vim

# Setting executable permission on dwm startup script
echo "Setting executable permission on dwm startup script..."
sudo chmod +x "$HOME/.de/dwm/de.sh"

echo "Installation completed successfully!"
