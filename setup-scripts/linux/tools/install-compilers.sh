#!/bin/bash
# Install Compiler Tools

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

# Install GCC and related tools
print_status "Installing GCC compiler tools..."
apt-get install -y \
    gcc \
    g++ \
    gcc-multilib \
    g++-multilib \
    linux-libc-dev

# Install Clang
print_status "Installing Clang compiler..."
apt-get install -y \
    clang \
    clang-format \
    clang-tidy \
    clang-tools

# Install additional compiler utilities
print_status "Installing compiler utilities..."
apt-get install -y \
    lldb \
    lld \
    llvm \
    llvm-dev

print_success "Compiler tools installed successfully"