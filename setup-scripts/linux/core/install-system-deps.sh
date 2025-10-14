#!/bin/bash
# System Dependencies Installation

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        echo -e "${GREEN}Detected Debian/Ubuntu system${NC}"
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
        echo -e "${GREEN}Detected RHEL/CentOS system${NC}"
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

install_system_deps() {
    echo -e "${GREEN}Installing system dependencies...${NC}"

    if [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y \
            build-essential cmake ninja-build \
            clang clang-format clang-tidy \
            gcc g++ gdb \
            libssl-dev libffi-dev \
            curl wget git jq \
            pkg-config autoconf automake \
            libgtest-dev libbenchmark-dev \
            python3 python3-pip python3-venv \
            python3-dev
    elif [ "$OS" = "redhat" ]; then
        yum groupinstall -y "Development Tools"
        yum install -y \
            cmake ninja-build \
            clang clang-tools-extra \
            gcc gcc-c++ gdb \
            openssl-devel libffi-devel \
            curl wget git jq \
            pkgconfig autoconf automake \
            python3 python3-pip python3-devel
    fi
}

main() {
    detect_os
    install_system_deps
    echo -e "${GREEN}✅ System dependencies installed${NC}"
}

main "$@"