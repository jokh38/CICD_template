#!/bin/bash
# Install Compiler Tools

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

# Install GCC and related tools
print_status "Installing GCC compiler tools..."
apt-get install -y \
    gcc \
    g++ \
    gcc-multilib \
    g++-multilib \
    linux-libc-dev

# Remove conflicting clang versions first
print_status "Purging potentially conflicting Clang versions..."
apt-get purge -y clang clang-18 clang-format-18 clang-tidy-18 clang-tools-18 libclang-common-18-dev llvm-18* || true

# Install Clang
print_status "Installing Clang 14 compiler..."
apt-get install -y \
    clang-14 \
    clang-format-14 \
    clang-tidy-14 \
    clang-tools-14 \
    libc++-14-dev \
    libc++abi-14-dev

# Set clang-14 as the default clang
update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 100
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 100
update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-14 100
update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-14 100

# Install additional compiler utilities
print_status "Installing compiler utilities for version 14..."
apt-get install -y \
    lldb-14 \
    lld-14 \
    llvm-14 \
    llvm-14-dev

# Update shared library cache
print_status "Updating shared library cache..."
ldconfig

print_success "Compiler tools installed successfully"