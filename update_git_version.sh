#!/bin/bash

# Check the current installed version of git
git_version=$(git --version | awk '{print $3}')
required_version="2.27"

# Function to compare versions
version_compare() {
    # Arguments: version1, version2
    # Return 1 if version1 > version2, -1 if version1 < version2, 0 if equal
    if [[ "$1" == "$2" ]]; then
        return 0
    fi
    local IFS="."
    local i v1=($1) v2=($2)
    for ((i=0; i < ${#v1[@]} || i < ${#v2[@]}; i++)); do
        if [[ ${v1[i]:-0} -gt ${v2[i]:-0} ]]; then
            return 1
        elif [[ ${v1[i]:-0} -lt ${v2[i]:-0} ]]; then
            return -1
        fi
    done
    return 0
}

# Compare current git version to required version
version_compare "$git_version" "$required_version"
result=$?

# If the installed version is less than the required version (result is -1)
if [ $result -eq -1 ]; then
    echo "Git version is lower than 2.27. Installing Git 2.27..."
    
    # Install required build tools
    sudo apt update
    sudo apt install -y build-essential libcurl4-openssl-dev libexpat1-dev gettext libz-dev

    # Clone Git repository
    cd /tmp
    git clone https://github.com/git/git.git
    cd git

    # Checkout the version 2.27
    git checkout v2.27.0

    # Compile and install
    make prefix=/usr/bin all
    sudo make prefix=/usr/bin install
    
    # Clean up
    rm -rf /tmp/git
    echo "Git 2.27 installed successfully."
else
    echo "Git version is $git_version. No update needed."
fi

