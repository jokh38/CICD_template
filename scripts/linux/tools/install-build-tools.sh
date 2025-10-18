#!/bin/bash
# Install System Build Tools
#
# This script installs system-level build tools and utilities.
# C++ package managers (Conan, vcpkg) are handled by install-cpp-pkg-managers.sh
# to maintain clear separation between system and user-level installations.

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

# Install CMake
print_status "Installing CMake..."
if ! command -v cmake &> /dev/null; then
    apt-get install -y cmake
else
    print_status "CMake already installed"
fi

# Install Ninja build system
print_status "Installing Ninja build system..."
apt-get install -y ninja-build

# Install Make and other build utilities
print_status "Installing Make and build utilities..."
apt-get install -y \
    make \
    automake \
    autoconf \
    libtool \
    pkg-config

# C++ package managers (Conan, vcpkg) are now handled by install-cpp-pkg-managers.sh
# This script focuses on system build tools only

print_success "Build tools installed successfully"