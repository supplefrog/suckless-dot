#!/bin/bash

# Add current user to needed groups
sudo usermod -aG video,audio,tty,input "$USER"

# Config udev to change tty perms on boot
echo 'KERNEL=="tty1", GROUP="tty", MODE="0660"' | sudo tee /etc/udev/rules.d/99-tty1.rules

# Reload udev rules and apply immediately
sudo udevadm control --reload-rules
sudo udevadm trigger /dev/tty1
echo "✅ User groups and TTY permissions updated. Reboot and select DWM on after entering your log in password."
