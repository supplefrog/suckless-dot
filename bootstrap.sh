#!/bin/bash

detect_pkg_mgr() {
    PKG_MGR=""
    INSTALL_CMD=""
    
    if command -v apt &> /dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="sudo apt install -y"
    elif command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -Syu --noconfirm"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &> /dev/null; then
        PKG_MGR="yum"
        INSTALL_CMD="sudo yum install -y"
    else
        echo "Unsupported package manager."
        exit 1
    fi
}


echo "Installing essential packages (git, curl)..."

# Check and install git if missing
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing Git..."
    $INSTALL_CMD git
fi

# Check and install curl if missing
if ! command -v curl &> /dev/null; then
    echo "Curl not found. Installing Curl..."
    $INSTALL_CMD curl
fi

# Add any other essential package installations here
