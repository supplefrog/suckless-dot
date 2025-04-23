
# Detect package manager
PKG_MGR=""
INSTALL_CMD=""
PKG_LIST=""
REPO_CMD=""

if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
    PKG_LIST="xorg xorg-dev xserver-xorg libcurl4-openssl-dev libimlib2-dev libx11-dev libxft-dev libxinerama-dev libxrandr-dev libxcb1-dev libxt-dev gcc git make pkg-config dmenu vifm"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -Syu --noconfirm"
    PKG_LIST="xorg xorg-xinit xorg-server libcurl-compat libimlib2 libx11 libxft libxinerama libxrandr libxcb libxt gcc git make pkgconf dmenu vifm"
    # Ensure yay (AUR helper) is available for Arch-based systems
    if ! command -v yay &> /dev/null; then
        echo "AUR helper (yay) not found. Installing yay..."
        sudo pacman -S --noconfirm yay
    fi
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    INSTALL_CMD="sudo dnf install -y"
    PKG_LIST="xorg-x11-server-Xorg imlib2-devel libcurl-devel libX11-devel libXft-devel libXinerama-devel libXrandr-devel libxcb-devel libXt-devel gcc git make pkgconf dmenu vifm"
    REPO_CMD="sudo dnf install -y epel-release"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    INSTALL_CMD="sudo yum install -y"
    PKG_LIST="xorg-x11-server-Xorg imlib2-devel libcurl-devel libX11-devel libXft-devel libXinerama-devel libXrandr-devel libxcb-devel libXt-devel gcc git make pkgconf dmenu vifm"
    REPO_CMD="sudo yum install -y epel-release"
else
    echo "Unsupported package manager."
    exit 1
fi

echo "Using package manager: $PKG_MGR"

# Ensure EPEL repo is installed for RHEL-based systems (if needed)
if [ -n "$REPO_CMD" ]; then
    echo "Checking for necessary repositories..."
    if ! sudo dnf repolist | grep -q "epel"; then
        echo "EPEL repo missing. Installing..."
        eval "$REPO_CMD"
    fi
fi

echo "Installing required packages..."
$INSTALL_CMD $PKG_LIST
