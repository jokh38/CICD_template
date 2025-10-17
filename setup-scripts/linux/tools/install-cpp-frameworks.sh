#!/bin/bash
# Install C++ Testing Frameworks

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

# Install Google Test
print_status "Installing Google Test framework..."
apt-get update > /dev/null 2>&1
apt-get install -y libgtest-dev libgmock-dev

# Build and install Google Test
cd /usr/src/googletest
cmake .
make -j$(nproc)
make install
ldconfig

# Install Catch2 (header-only testing framework)
print_status "Installing Catch2 testing framework..."
if command -v pip3 > /dev/null 2>&1; then
    # Try to install as regular user first, fallback to system install
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" pip3 install --user catch2 2>/dev/null || pip3 install catch2 2>/dev/null || true
    else
        pip3 install --user catch2 2>/dev/null || pip3 install catch2 2>/dev/null || true
    fi
fi

# Install Boost.Test
print_status "Installing Boost libraries (includes Boost.Test)..."
apt-get install -y libboost-all-dev

# Install Doctest (lightweight testing framework)
print_status "Installing Doctest..."
if command -v pip3 > /dev/null 2>&1; then
    # Try to install as regular user first, fallback to system install
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" pip3 install --user doctest 2>/dev/null || pip3 install doctest 2>/dev/null || true
    else
        pip3 install --user doctest 2>/dev/null || pip3 install doctest 2>/dev/null || true
    fi
fi

print_success "C++ testing frameworks installed successfully"