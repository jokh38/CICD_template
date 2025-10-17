#!/bin/bash
# Install Build Tools

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

# Install Conan package manager for C++
print_status "Installing Conan package manager..."
pip3 install --upgrade pip
pip3 install conan

# Install vcpkg (optional C++ package manager)
print_status "Installing vcpkg..."
if [ ! -d "/opt/vcpkg" ]; then
    git clone https://github.com/Microsoft/vcpkg.git /opt/vcpkg
    /opt/vcpkg/bootstrap-vcpkg.sh
    ln -sf /opt/vcpkg/vcpkg /usr/local/bin/vcpkg
else
    print_status "vcpkg already installed"
fi

print_success "Build tools installed successfully"