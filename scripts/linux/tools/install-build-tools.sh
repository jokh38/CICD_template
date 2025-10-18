#!/bin/bash
# Install System Build Tools
#
# This script installs system-level build tools and utilities.
# C++ package managers (Conan, vcpkg) are handled by install-cpp-pkg-managers.sh
# to maintain clear separation between system and user-level installations.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

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