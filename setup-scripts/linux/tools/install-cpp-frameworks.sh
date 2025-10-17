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
apt-get install -y libgtest-dev libgmock-dev

# Build and install Google Test
cd /usr/src/googletest
cmake .
make -j$(nproc)
make install
ldconfig

# Install Catch2 (header-only testing framework)
print_status "Installing Catch2 testing framework..."
pip3 install catch2

# Install Boost.Test
print_status "Installing Boost libraries (includes Boost.Test)..."
apt-get install -y libboost-all-dev

# Install Doctest (lightweight testing framework)
print_status "Installing Doctest..."
pip3 install doctest

print_success "C++ testing frameworks installed successfully"