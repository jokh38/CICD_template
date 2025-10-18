#!/bin/bash
# Install C++ Package Managers (Conan, vcpkg)
#
# This script handles user-level C++ package manager installations.
# Uses --break-system-packages and --ignore-installed flags to prevent
# conflicts with system Python packages and ensure reliable installation.

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Install vcpkg
print_status "Installing vcpkg..."
if [ ! -d "/opt/vcpkg" ]; then
    # Check network connectivity first
    if ! ping -c 1 github.com > /dev/null 2>&1; then
        print_error "Network connectivity required for vcpkg installation"
        exit 1
    fi

    print_status "Cloning vcpkg repository..."
    if git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg; then
        print_status "Bootstrapping vcpkg..."
        if /opt/vcpkg/bootstrap-vcpkg.sh; then
            # Create symbolic link for system-wide access
            ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg
            print_success "vcpkg installed successfully"
        else
            print_error "Failed to bootstrap vcpkg"
            exit 1
        fi
    else
        print_error "Failed to clone vcpkg repository"
        exit 1
    fi
else
    print_status "vcpkg already installed. Skipping."
fi


# Install Conan
print_status "Installing Conan..."
if command -v pip3 > /dev/null 2>&1; then
    # Ensure pip is up to date first
    print_status "Upgrading pip..."
    pip3 install --break-system-packages --ignore-installed --upgrade pip

    # Install Conan with system conflict prevention
    pip3 install --break-system-packages --ignore-installed conan
    print_success "Conan installed successfully"
else
    print_error "pip3 not found, cannot install Conan."
    print_error "Please ensure Python3 and pip3 are installed first."
    exit 1
fi

print_success "C++ package managers installed successfully"