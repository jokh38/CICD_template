#!/bin/bash
# Build Tools Installation

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

install_build_tools() {
    echo -e "${GREEN}Installing build tools...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get install -y \
            cmake ninja-build \
            meson \
            pkg-config \
            autoconf automake
    elif [ "$OS" = "redhat" ]; then
        yum install -y \
            cmake ninja-build \
            meson \
            pkgconfig autoconf automake
    fi

    echo -e "${GREEN}✅ Build tools installed${NC}"
}

main() {
    detect_os
    install_build_tools
}

main "$@"