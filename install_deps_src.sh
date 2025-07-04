#!/bin/bash

set -euo pipefail

# Check the current installed version of git
git_version=$(git --version | awk '{print $3}')
required_version="2.27"

# Function to compare versions
# Arguments: version1, version2
# Print 1 if version1 > version2, -1 if version1 < version2, 0 if equal
version_compare() {
    if [[ "$1" == "$2" ]]; then
        echo 0
        return
    fi
    local IFS="."
    local i v1=($1) v2=($2)
    for ((i=0; i < ${#v1[@]} || i < ${#v2[@]}; i++)); do
        if [[ ${v1[i]:-0} -gt ${v2[i]:-0} ]]; then
            echo 1
            return
        elif [[ ${v1[i]:-0} -lt ${v2[i]:-0} ]]; then
            echo -1
            return
        fi
    done
    echo 0
}

# Compare current git version to required version
result=$(version_compare "$git_version" "$required_version")

# If the installed version is less than the required version (result is -1)
if [ "$result" -eq -1 ]; then
    echo "Git version is lower than 2.27. Installing Git 2.27..."

    # Install required build tools
    case "$PKG_MGR" in
        "apt")
            PKG_LIST="libcurl4-openssl-dev libexpat1-dev libz-dev libssl-dev gettext"
            ;;
        "dnf" | "yum")
            PKG_LIST="curl-devel expat-devel zlib-devel openssl-devel gettext"
            ;;
        "pacman")
            PKG_LIST="curl expat zlib openssl gettext"
            ;;
    esac
    $INSTALL_CMD $PKG_LIST

    # Clone Git repository
    cd /tmp
    sync_repo -c b3d7a52fac39193503a0b6728771d1bf6a161464 https://github.com/git/git.git
    cd git
    
    # Compile and install
    make prefix=/usr/bin all
    sudo make prefix=/usr/bin install

    # Clean up
    rm -rf /tmp/git
    echo "Git 2.27 installed successfully."
else
    echo "Git version is $git_version. No update needed."
fi
