#!/bin/bash
# Compiler Tools Installation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

install_compilers() {
    echo -e "${GREEN}Installing compiler tools...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get install -y \
            gcc g++ \
            clang clangd \
            gdb \
            llvm-dev
    elif [ "$OS" = "redhat" ]; then
        yum install -y \
            gcc gcc-c++ \
            clang clang-tools-extra \
            gdb \
            llvm-devel
    fi

    echo -e "${GREEN}✅ Compiler tools installed${NC}"
}

main() {
    detect_os
    install_compilers
}

main "$@"