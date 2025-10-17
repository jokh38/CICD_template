#!/bin/bash
# Install C++ Package Managers (Conan, vcpkg)

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

# Install vcpkg
print_status "Installing vcpkg..."
if [ ! -d "/opt/vcpkg" ]; then
    git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg
    /opt/vcpkg/bootstrap-vcpkg.sh
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg
    print_success "vcpkg installed successfully"
else
    print_status "vcpkg already installed. Skipping."
fi


# Install Conan
print_status "Installing Conan..."
if command -v pip3 > /dev/null 2>&1; then
    pip3 install --break-system-packages --ignore-installed conan
    print_success "Conan installed successfully"
else
    print_error "pip3 not found, cannot install Conan."
    exit 1
fi

print_success "C++ package managers installed successfully"