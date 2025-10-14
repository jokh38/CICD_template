#!/bin/bash
# System Dependencies Installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"

# Source utility functions
if [ -f "$UTILS_DIR/check-deps.sh" ]; then
    source "$UTILS_DIR/check-deps.sh"
else
    echo -e "\033[0;31m[ERROR]\033[0m Utility functions not found: $UTILS_DIR/check-deps.sh"
    exit 1
fi

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

    # Check if system dependencies are already installed
    if check_system_deps; then
        print_success "System dependencies are already installed - skipping"
        exit 0
    fi

    install_system_deps
    echo -e "${GREEN}✅ System dependencies installed${NC}"
}

main "$@"